# ASM2464PD chip notes — architecture, DMA engines, and the sustained-copyin wedge

Reference gathered 2026-09-02 from the RE'd firmware (`asm2464pd-firmware/handmade/src/registers.h`,
2534 lines), the community RE (cyrozap/usb-to-pcie-re, AleksaBjelogrlic/ASM2464PD-RE), and the
public R02 datasheet (pinout/electrical only — no register/programming info; ASMedia keeps that
under deep NDA, which is why the register map was reverse-engineered from scratch).

## The chip

USB4/Thunderbolt-3 Gen3 x2 (40 Gbps) ↔ PCIe Gen4 x4 NVMe bridge. Internally:
- **8051-compatible core**, ~100-114 MHz, 1T. XDATA is 64 KB with hardware *windows* into a larger
  internal SRAM. `DPX` (SFR 0x93) bit0 switches MOVX to the PCIe-switch PHY register plane;
  `PSBANK/FMAP` (SFR 0x96) low 2 bits page CODE banks. SPI ROM holds the RAM code.
- **Internal SRAM ~6-8 MB**, seen by the 8051 only through 4 KB windows: `0x7000` (bulk-OUT/flash
  landing buffer), `0x8000` and `0xF000` (both window PCI `0x00200000`, the ~6 MB data buffer the
  GPU bus-masters from), `0xA000` (PCI `0x00820000`, queues). The F2 DMA path uses a **512 KB**
  slice of this — exactly why tinygrad's copyin uses two 256 KB bounce windows (the whole slice).
- The **8051 never touches bulk data bytes** — it programs DMA engines with 32-bit PCI addresses;
  hardware moves the data. Host → EP 0x02 bulk-OUT → 0x7000 → SRAM `0x200000` → GPU over PCIe.

**Block diagram** (from the unlocked ASM2464PDX datasheet, `ASM2464PDX-datasheet-unlocked.pdf` §3):
the data path is **USB2/USB3.2 Device Controller → Protocol Converter → "Virtual NVMe Host System"
→ SRAM → Device Router / Lane Adapter → PCIe Upstream P2P Bridge → GPU**. The USB side presents
as a *virtual NVMe host* — which is why the DMA registers are NVMe-shaped (C4xx queues/slots/
sectors, CExx SCSI) and why the 0xF2 copyin programs an "NVMe" engine even though there's no real
NVMe device. The CPU block is the 8051 with `Program ROM` (boot), `Program RAM` (RAM code from SPI),
and `XDATA` (shared with Program RAM). Other blocks: USB4 PHY Gen3 x2, USB4/USB3.2 PCS, TMU, SSCG,
SPI master (flash), 2×I2C, UART, GPIO. The sustained-copyin wedge lives somewhere in the
Virtual-NVMe-Host / Protocol-Converter DMA state (see the accumulation analysis below).

## The two DMA engines

**(a) C4xx NVMe-style engine — used by the 0xF2 vendor request (our copyin path).**
Arm sequence (`main.c` F2 handler): drain `C450` → `C42A=0` → `C422/C423` sector size → `C414/C415`
slot range → `C426/C427` sector count → `C412 = DMA_START (|WRITE_DIR)` → `C429` slot → ZLP; data
then flows on the bulk endpoints. **Key limitation: no completion signal.** The only in-flight
visibility is **`C450` (2 = bulk DMA active, 0 = idle)** — which is exactly what our corruption fix
polls before re-arming ("re-arming mid-drain drops the first ~2 sectors").

**(b) CE00-CE9F SCSI/bulk engine — the MSC WRITE path.** `CE00=0x03` DMAs one 512 B sector
0x7000→SRAM@`CE76-79`, poll →0x00. Not our path, but its cleanup requirements are the tell (below).

## The sustained-copyin wedge — analysis

**Symptom:** a single copyin > ~7000 chunks (a 2 GB+ prefix-snapshot restore) hard-locks the
controller — control *and* bulk transfers both die, only an FTDI reset recovers. The GPU's
`SDMA_QUEUE_HANG` is downstream (the dock stopped delivering, so the SDMA polls a sentinel forever).

**Why it wedges (leads from the register map):** several DMA registers are **saturating/accumulating
counters that must be cleared between transfers**, and are the prime suspects for state that piles
up over ~10000 back-to-back arms:
- `CE66` tag count (bits 0-4, saturates at 31), `CE67` queue status (bits 0-3, saturates at 15).
- `CE40-CE43` (tinygrad clears after >16 KB writes), `CE6E/CE6F` DMA status (cleared per chunk).
- The `0x7000` buffer **locks** after a C4xx DMA (reads 0x55) and needs `C42A=0x01` to unlock.
- `B298` bit2 is a **DMA_RESET** strobe; the firmware's own SET_CONFIG recovery pulses it to "clear
  wedged DMA state" — evidence the hardware genuinely accumulates a wedgeable state.

**Why my first firmware attempt (`f2_rearm`, ported from the closed PR #73) FAILED:** it reset the
USB **endpoint** state machine each arm (`90E3=0x02` ACK/re-arm, `9096` EP_READY, `90A0` strobe).
That desyncs the bulk endpoint's arm/ack handshake — so it wedged on the *first* copyin, not after
10000. Wrong subsystem: the accumulation is in the **DMA engine** (C4xx/CExx counters), not the
endpoint. PR #73 was closed unmerged, consistent with this.

**A properly-scoped firmware fix** (future device-window work): instrument `CE66/CE67` (and the
C4xx queue/tag state) as the hang approaches to find which one saturates, then clear exactly that
between F2 arms — the DMA-engine analogue of what tinygrad already does for the CE00 path
(`CE40-43`, `CE6E/6F`). Do NOT touch the endpoint registers.

**Why the shipped host-side fix works and is legitimate** (`ops_amd.py`, cap the SDMA ring at 4096
chunks + full drain between groups): the full drain lets the controller's DMA state complete and
settle each group before the next, so no counter reaches saturation. It's not just a band-aid — it
respects the same "clear state between transfers" contract the firmware itself documents, just from
the host side. Validated: 3 GB copyins, 0 corruption, ~640 MB/s.

## Root-cause investigation of the sustained-copyin hang (2026-09-02, exhaustive)

Direct on-hardware investigation, in order:

1. **Register probing during a large copyin** (read C4xx/CExx/USB/PCIe via 0xE4 while streaming):
   nothing accumulates. C450 steady at 2/0 (active/idle), C451 fluctuates 0x1b-0x1f, all engine
   state healthy through 10000 chunks. **Rules out a saturating-counter cause.**
2. **Full register scan AT the hang** (0xE4 control reads still answer even when bulk is wedged):
   C4B3 0x2e-0x3e→0x1E, C451 0x1b-0x1f→0x0F, B296 (PCIe) COMPLETE clears — but these are the
   NVMe queue *draining* after the host stalls (aftermath), and B296 is the downstream GPU-stuck
   symptom, not the trigger.
3. **UART firmware trace** (FT230X debug port, /dev/ttyUSB0 @ 921600): the firmware prints NOTHING
   at the hang, and a trace on the C450 drain spin shows it never runs long. The firmware arms each
   F2 transfer normally, then goes silent because the *host* stops (blocked in wait_drain on the GPU).
4. **The decisive structural fact** (`main.c`): the F2 copyin data path has **no 8051 involvement
   per chunk**. `handle_usb_bulk_data` is only the F0/PCIe path; for F2 the firmware just *arms* the
   C4xx engine and the hardware DMAs USB→SRAM autonomously. So there is no firmware hot-path to fix.
5. **Firmware experiments, all failed** (each hangs within 1-2 runs): `f2_rearm` from PR #73
   (endpoint reset — wrong subsystem, broke it), post-drain `F2_SETTLE` at 256 AND 4000 reads
   (no effect — they run at arm-time, but the drop is inside the hardware transfer *after* arming).

**Conclusion:** the hang is a **hardware DMA reliability limit** of the C4xx "Virtual NVMe Host"
engine under sustained back-to-back arming — it occasionally never writes a chunk (data+sentinel)
to SRAM, with **no completion signal** (there is no real NVMe device to complete, so the CQ is
unused; C450 idle is not a data-committed signal). The 8051 cannot intervene because it is not in
the per-chunk data path. Stock ASMedia firmware sustains multi-GB DMA only because its reliable
path is the **CE00 engine with the 8051 polling each sector's completion** (`CE00=0x03`→poll 0) —
8051 *in* the loop, ~4x slower. So the firmware's only options are fast-unreliable (current C4xx)
or slow-reliable (CE00-style, ~250 MB/s like USB_SAFE_COPYIN).

**Stock's DMA-completion mechanism (found by disassembling stock `ghidra.c`, 2026-09-02) — the
signal PR #72 said didn't exist:** stock's fast arm-and-forget DMA is matched by a hardware
completion INTERRUPT, `C806` bit5 -> `CEF3` bit3 (bulk-DMA-done) / `CEF2` bit7 (NVMe-cmd-done),
W1C, consumed in `usb_master_handler` which retires the descriptor against the PCIe queue-index
registers. Stock also pulses `B298` bit2 (DMA reset) + clears `CE40-43` per command batch and
programs `CE80-83` buffer watermarks for backpressure.

**But replicating it did NOT fix the F2 hang** (all tested on hardware): our F2 path leaves `CEF3`
bit3 stuck set (never retired) -- yet W1C-clearing it per arm (confirmed effective: CEF3 0x08->0x00)
still hangs; the `B298` reset pulse breaks the GPU PCIe tunnel (SMU timeout); `CE80-83` is the CE00
engine's buffer, not the C4xx F2 path; and `C806` bit5 never even fires in our config (the
completion interrupt isn't wired up). So the drop survives correct completion bookkeeping -- it is
in the raw C4xx hardware DMA under sustained load, and stock is reliable only via its full
8051-in-the-loop NVMe-queue+ISR machinery (the slow path, ~250 MB/s).

**Therefore the host-side ring-batching (`ops_amd.py`, cap the ring + full drain between groups) is
the OPTIMAL fix — fast AND reliable** — and beats every firmware option. This is a determination
from full evidence, not an unexplored gap. The only untried firmware path (reimplement F2 on the
CE00 per-sector 8051-driven path) would be strictly worse than what's shipped, so it's not worth
building. External reference: stock images at `canmi21/ASM2464PD` + station-drivers; disassemble
with `smx-smx/ASMTool` + `cyrozap/ghidra-asmedia-8051` if the CE00 sequence is ever wanted.

## Recovery / operational facts learned today
- FTDI `debug.py -rn` (chip reset) recovers a wedged dock most of the time; sometimes needs several
  tries or the `-b` bootloader path; a hard wedge (device fully off the bus) needs a physical
  power-cycle. The dock got fragile after dozens of reset/flash cycles in one session.
- e4 flash (`e4_flash.py`) fails `Bulk OUT` when the bulk endpoint is wedged — reset first.
