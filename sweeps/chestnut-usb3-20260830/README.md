# Chestnut USB3 bring-up + post-move sweep (2026-08-30)

The "after" half of [`pre-chestnut-baseline-20260830`](../pre-chestnut-baseline-20260830/):
the RX 7900 XTX moves off the GMKtec M8's internal OCuLink port and into a
**tiny chestnut** dock, driven over USB3 from a different host.

**Read the bring-up notes below before trusting any number in this directory.**
Upstream's pipelined copyin silently corrupts data on this host; it was diagnosed
and fixed here (`USB_COPYIN_GUARD`, see "The fix"). Every measurement in this
directory is taken with that fix in place and copyin verified byte-clean.

## Hardware / topology

|  | baseline ("before") | this sweep ("after") |
|---|---|---|
| host | GMKtec M8, Ryzen 5 PRO 6650H, user `j` | Dell XPS 9315, **Intel i7-1250U**, 30 GB RAM, user `jacob` |
| link | internal OCuLink, PCIe 4.0 x4 (~64 Gbit/s) | chestnut, **USB 3.2 Gen2x1 (10 Gbit/s)** |
| interface | `DEV=AMD:LLVM` (KFD / amdgpu) | `DEV=USB+AMD:LLVM` (AM userspace driver over libusb) |
| GPU | RX 7900 XTX (gfx1100, `1002:744c`) | same card |

**The host changed too.** This is not an interconnect-only A/B — the CPU, RAM and
OS install are all different. Any delta is host + interconnect combined. Said
plainly here because the baseline README framed it as an interconnect comparison.

### Link facts (measured, not from spec sheets)

- USB negotiated **SuperSpeed Plus Gen 2x1, 10 Gbit/s**, `rx_lanes=1 tx_lanes=1`,
  on `0000:00:0d.0` — the Alder Lake TB4 controller's USB path.
- Gen2x2 (20 Gbit/s) is **not** reachable here: USB4/TB4 ports don't tunnel
  Gen2x2, and this laptop has no native non-TB USB controller. 10 Gbit/s is the
  ceiling on this host.
- The chestnut's *internal* PCIe link is **Gen3 x2** (firmware pins it there for
  signal margin; the ASM2464PD completer saturates ~1.68 GB/s either way). The
  "PCIe Gen4 x4" in comma's marketing is the slot wiring, not the negotiated link.
- The GPU never appears on the host PCI bus. `lspci` and `boltctl` show nothing:
  tinygrad tunnels PCIe TLPs over USB vendor control transfers and does its own
  bus walk and BAR assignment.
- `BAR0 = 32 GiB` after tinygrad's own ReBAR walk (`System.pci_setup_usb_bars`),
  so we are **not** on the 256 MB small-BAR path that disables P2P. Host BIOS
  ReBAR settings are irrelevant in this mode.

## Bring-up: what was actually needed

Answering the question this started as — "do I need switches or drivers?":

- **No DIP switches, no jumpers.** Configuration is entirely firmware/software.
  PCIe power is software-gated: the custom firmware boots with the rails *off*
  and tinygrad turns them on (vendor request `0xF3`), then checks `LTSSM == 0x78`.
- **No drivers.** No amdgpu, no kernel module, no thunderbolt authorization, no
  BIOS changes, no `pci=realloc`, no IOMMU work, and **no need to connect before
  boot** — there is no host-side PCIe hotplug involved at all.
- **One thing was needed:** a udev rule for libusb access. tinygrad ships none.
  Installed at `/etc/udev/rules.d/99-tinygrad-usbgpu.rules` covering `3801:0001`
  (comma VID, chestnut custom firmware) and `add1:0001` (older patched stock
  ASM2464PD), `MODE=0660 GROUP=plugdev TAG+=uaccess`.
- **Power:** the chestnut supplies 150 W on its 8-pin DC OUT plus 75 W on the
  slot (225 W total from DC-in). That is not enough for a 7900 XTX (2x 8-pin,
  ~355 W TBP), so the card is fed from the ATX PSU directly — a MONTECH Century
  II 1050W ATX 3.1 Gold. Power was ruled out as a cause of the bug below.

### Gotcha: cold, bus-powered enumeration looks broken

With the USB cable in but the dock's PSU off, the ASM2464PD enumerates on USB
*bus power alone* at **USB 2.0 high-speed (480 Mb/s)**, and the kernel logs
`usb2-port2: Cannot enable. Maybe the USB cable is bad?`. This is not a cable
fault. Power the dock, re-seat the cable, and it comes up at 10 Gbit/s. The
stock 1 m cable is fine.

## The bug: pipelined copyin corrupts the front of every window

`AMDAllocator._copyin` (`tinygrad/runtime/ops_amd.py`) has a pipelined fast path
over the ASM controller's `0xF2` engine: ~256 KB chunks stream into two
alternating SRAM bounce windows, each chunk's wire image ends in a 4-byte
sentinel, and a prebuilt SDMA ring polls that sentinel before copying the window
to VRAM. It was added in `756e82e05` (PR #17628) and `3082956a1` (PR #17663).

**It silently corrupts data on this host.**

### Evidence

| test | result |
|---|---|
| `testValidateCopies`, 64 MB | 120,839 / 64,000,000 bad (0.189%) |
| reproducibility | every run, 1 MB / 8 MB / 64 MB, 0.05–0.36% |
| direction | **copyin only** — 4 successive copyouts of the same buffer are byte-identical |
| what the bad bytes are | not stale window data, not zeros, not the source — ~4/1024 matches = chance |
| **location** | **exclusively the first 1024 bytes of each 0x40000 chunk**, 22 of 31 chunks; chunk 0 always clean |
| GPU power dependence | none — 27525 / 26530 / 28553 bad at default / `AM_POWER_LIMIT=100` / `=60` |
| serialized fallback | **0 bad**, every size, every run |

### What it is not

- **Not power.** Flat error rate across a 4x power-limit range, and the GPU is
  idle during a copy test. The PSU is a 1050 W Gold unit that ran a week on a
  DEG1 dock.
- **Not the cable or the link.** The serialized fallback pushes data through the
  *identical* transport — `USBMMIOInterface.__setitem__` -> `scsi_write` -> the
  same `0xF2` engine and the same SRAM windows — and is byte-perfect. Same PHY,
  same bursts.
- **Not stale firmware.** Our unit reports `custom ed4e39b7-CLEAN`, which *is*
  `tinygrad/asm2464pd-firmware` master HEAD ("usb: RX serdes tuning", #82,
  2026-08-08). Nothing newer exists. Shipping units all run this.
- **Not a firmware data-path fault in isolation.** 15 rounds of "write 256 KB via
  the `0xF2` engine, read the window's first 1 KiB back over XDATA (`0xE4`)"
  came back clean 15/15. The corruption needs the *concurrency* of the real
  path — SDMA reading one window while the host arms the other.

### What it is

A synchronization defect: the `0xF2` engine's completion indication does not
guarantee the **front** of the window has landed. Corroborating evidence from the
firmware repo:

- **PR #73** "init F2 DMA before each transfer" (closed **unmerged**):
  *"Interrupted bulk transfers can leave the DMA in a bad state, causing the next
  F2 transfer to fail."*
- **PR #72** "recover abandoned F2 DMA transfers" (closed **unmerged**):
  *"TODO: find F2 completion ISR and use that instead."*
- **PR #83** (open) documents the same failure shape on the chip's *Flash* DMA:
  *"Flash DMA can expose a **stale first byte** even after its busy indicators
  clear. This produces sparse, varying verification mismatches."* Different
  engine, same 8051, same symptom class.

### Why upstream has not seen it

- `testValidateCopies` fills its buffer with `Tensor.randn(dtype='uchar')` —
  normal floats cast to bytes, so most values are 0/1/2. Stale-window bytes
  frequently *equal* the expected bytes against data that low-entropy.
- The only USB GPU CI runners are `[self-hosted, macOS]` and
  `[self-hosted, Linux, comma4]` (Snapdragon). **No x86 / Intel TB4 xHCI host is
  covered.**

Neither `756e82e05` nor `3082956a1` has been reverted or patched, and no
corruption report exists in tinygrad or firmware issues, on X, HN, or egpu.io.
Not filed upstream — kept local per this sweep's scope.

### The fix (`USB_COPYIN_GUARD`, default 1024)

Two changes to the pipelined path in `tinygrad/runtime/ops_amd.py`, arrived at by experiment:

1. **Drain before arming.** The original armed the F2 engine for a window *before* confirming that
   window's previous occupant (seq-2) had drained to VRAM, and deliberately flew the `0xE4` fence
   read inside the F2 round trip ("arm and fence read fly in one round-trip window"). Reordering to
   drain-then-arm, with the fence read kept out of the F2 transfer, **halved** the error rate
   (0.171% -> 0.092%). This matches asm2464pd-firmware PR #73: *"Interrupted bulk transfers can
   leave the DMA in a bad state."* Necessary, not sufficient.

2. **A front guard region.** `GUARD` bytes (default 1024) are reserved at the front of each window;
   payload starts at `GUARD`, and `CHUNK` shrinks to `0x40000 - GUARD - 4`. This moves payload clear
   of the bytes the engine drops.

**What the guard experiment established about the mechanism:** a *second sentinel placed inside the
guard* (at `GUARD-4`, polled by SDMA before the copy) **never satisfies** -- the copy hangs and
`wait_drain` times out. So the dropped prefix is not arriving late; those bytes are never written
with our data at all. The engine reports completion for a transfer whose first ~1KiB it silently
discarded. That is why polling cannot rescue it and only relocation works, and it is the same shape
as PR #83's Flash-DMA *"stale first byte even after its busy indicators clear."*

Measured, 64 MB `testValidateCopies`:

| configuration | correctness | copyin |
|---|---|---|
| legacy layout (`USB_COPYIN_GUARD=0`, original ordering) | 0.171% corrupt | ~925 MB/s |
| ordering fix only (`USB_COPYIN_GUARD=0`) | 0.041-0.092% corrupt | ~760 MB/s |
| serialized fallback (`USB_SAFE_COPYIN=1`) | clean | ~250 MB/s |
| **guard + ordering (default)** | **clean** | **~780 MB/s** |

Validation with **uniform random bytes** (stronger than the upstream test, which fills with
`Tensor.randn(dtype='uchar')` -- mostly 0/1/2, where dropped bytes often coincidentally match):

```
3 trials x {1000003, 8000000, 64000000, 200000000} bytes
TOTAL: 0 bad / 819000009 bytes (0.82 GB)
```

`test/external/external_test_usb_asm24.py` 3/3 OK and `test/test_tiny.py` 21/21 OK on defaults.

Knobs: `USB_COPYIN_GUARD` (bytes, default 1024; 0 restores the corrupting layout for A/B) and
`USB_SAFE_COPYIN=1` (serialize copyin entirely -- the always-safe escape hatch).

**Caveat:** 1024 is the observed size of the dropped prefix on this host, not a value read out of
the firmware. If a host drops more, the guard must grow. It is env-tunable for that reason.

## Gotcha: install jinja2, or the sweep is silently not comparable

`tinygrad.llm.cli` only uses the **model's own** chat template when `jinja2` is importable
(`cli.py:242`, `except ImportError` -> `FallbackTemplate`). A fresh venv does not have it, and
tinygrad does not depend on it. Without jinja2 every request here died with:

```
TypeError: FallbackTemplate.render() got an unexpected keyword argument 'enable_thinking'
```

because `serve.py:290` passes `enable_thinking` / `reasoning_effort`, which `FallbackTemplate.render`
did not accept. Fixed locally by giving that signature `**kwargs` so the fallback degrades instead of
500-ing on every request.

The crash was the lucky outcome. Had the signatures matched, the server would have quietly served a
**different prompt format** from the baseline run (which had jinja2 and used the Qwen template), and
the sweep would have produced plausible-looking but incomparable numbers. `pip install jinja2` into
the venv is a prerequisite for any comparison against `pre-chestnut-baseline-20260830`.

## Harness

`send_request.py` here is a v3-equivalent rewrite, because the original lives at
`~/llama.cpp/sweeps/newquants-20260828/send_request.py` on the M8 and is not on this host. It keeps
the v3 behaviour the baseline depended on: temperature 0.6, `reasoning_content` captured separately,
and prefill/gen tok/s and MTP accept rate read from the **server's own stderr log line** rather than
derived client-side.

**Comparability caveat, read before diffing against the baseline:** the baseline's `prose.txt` and
`code.txt` are also only on the M8. The prompts in `prompts/` here were written fresh to match their
*shape and size* (~55 and ~71 tokens vs the baseline's 57 and 72), not their text. Decode tok/s is
largely prompt-insensitive so those numbers compare reasonably; **prefill tok/s is strongly
prompt-size dependent and should be treated as indicative only** until the sweep is re-run with the
baseline's actual prompt files.

## Results: parity with the OCuLink baseline

Final numbers are `results-repro.json` (3 trials x {prose, code}, 800 max_tokens, temperature 0.6),
produced by `run_sweep_v3.sh`, which calls the **baseline's own**
`~/z/llama.cpp/sweeps/newquants-20260828/send_request.py` unmodified against that sweep's own
`prompts/{prose,code}.txt`. `prompt_tokens` comes back 57 / 72, matching the baseline exactly.

| | baseline (M8 + DEG1, PCIe 4.0 x4) | Chestnut (USB3, 10 Gbit/s, XPS 9315) |
|---|---|---|
| prose wall, 800 tok | 15.73 / 16.09 / 16.22 s | 16.02 / 16.34 / 17.30 s |
| code wall, 800 tok | 11.79 / 12.13 / 12.17 s | 11.49 / 12.46 / 12.62 s |
| prose accept | 0.35-0.37 | 0.32-0.37 |
| code accept | 0.62-0.66 | 0.62-0.74 |

**Within ~5% on wall time, with accept rates landing on top of the baseline** -- on a ~6x narrower
link (10 Gbit/s USB3 vs PCIe 4.0 x4) and a weaker host CPU (i7-1250U vs Ryzen 5 PRO 6650H). The
baseline README's hypothesis holds: once weights are resident in VRAM the interconnect governs
cold-start load time, not steady-state decode.

Cold start is where the link shows: ~50 s to upload the 16.35 GiB of weights over USB
(`llm cache: uploaded weights in 50826 ms`), against a `LLM_CACHE` unpickle of under 1 s.

### Unexplained: an earlier run measured accept 0.00 / 26 tok/s

`results.json`, `results-myharness.json` and `results-myprompts.json` were captured earlier the same
day and all show `accept 0.00` and 26 tok/s -- the dense rate, i.e. speculative decode contributing
nothing. **This was never root-caused and did not reproduce.** Seven consecutive healthy runs
followed, including in the identical configuration (`LLM_CACHE=1`, `DEBUG=0`, 800 max_tokens, v3
harness, same prompts, same server flags).

Hypotheses tested and **rejected**, each by measurement:

| hypothesis | verdict |
|---|---|
| USB path / interconnect breaks MTP | rejected -- 0.44-0.96 accept via `--benchmark` over USB |
| upstream issue #17780 | rejected -- its `failed to render Ops.CUSTOM` is just what `AMD_GEMV=0` produces |
| temperature-dependent sampling | rejected -- 0.87 accept at 0.6 (serve's exact value), 0.92 at 0.0 |
| prompt length / multi-chunk prefill | rejected -- 0.44 accept with the real 48-token prose prompt |
| `LLM_CACHE` | rejected -- healthy at `LLM_CACHE=1`, both cold-compile and cache-load |
| `DEBUG` masking it | rejected -- healthy at `DEBUG=0` |
| GPU power | rejected -- flat error behaviour across `AM_POWER_LIMIT` 60 W / 100 W / default |

The acceptance test (`model.py:1151`) is `while L < K and res[n_keep - 1 + L] == drafts[L]` -- plain
Python over two `.tolist()` results, so it is not a GPU-sync artifact. Independent Gumbel-max draws
cannot yield *identically* zero agreement across 4800 tokens by chance, so something structural was
wrong at the time. If it recurs, the tell is decode near 26 tok/s instead of ~50; keep the server log.

