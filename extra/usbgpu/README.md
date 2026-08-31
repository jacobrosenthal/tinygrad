# tiny chestnut dock — operating notes

Everything needed to run an RX 7900 XTX on a **tiny chestnut** dock (comma.ai, $249,
ASMedia ASM2464PD bridge) from a Linux host, and to switch it between its two firmwares.

Written against a Dell XPS 9315 (i7-1250U, Thunderbolt 4) on 2026-08-30. Measurements and
sweep data: [`sweeps/chestnut-usb3-20260830/`](../../sweeps/chestnut-usb3-20260830/).

## The two modes

The dock's firmware decides what the GPU *is* to the host. You get one or the other, never both.

| | **tiny custom** (as shipped) | **stock ASMedia** |
|---|---|---|
| USB id | `3801:0001` "custom `<githash>`" | none on USB — PCI only |
| host sees | a vendor-class USB 3.2 device | PCIe bridges `1b21:2463`, then the GPU |
| GPU on `lspci` | **no** | yes (`1002:744c`) |
| `amdgpu` binds | **no** | yes |
| driver | tinygrad's userspace AM driver over libusb | kernel `amdgpu` |
| run it with | `DEV=USB+AMD:LLVM` | `DEV=AMD:LLVM`, or llama.cpp / ROCm / Vulkan |
| link here | USB 3.2 Gen2x1, 10 Gbit/s, ~780 MB/s copyin | USB4 tunnel, trained **PCIe 1.0 x1 = 2 Gbit/s** |
| measured | **~50 tok/s** Qwen3.8-27B (MTP on) | **32.7 tok/s** decode, 592 prefill (llama.cpp Vulkan) |

In custom firmware the GPU never touches the host PCI bus — tinygrad tunnels PCIe TLPs over USB
vendor requests and does its own bus walk and BAR assignment. That is the whole point: it
sidesteps eGPU enumeration entirely, which is why it is the more *reliable* of the two here.

**Decode is not interconnect-bound.** Both modes land near the same throughput as an OCuLink
PCIe 4.0 x4 setup despite links 6x and 32x narrower, because once weights are resident in VRAM
decode is DRAM-bandwidth-bound inside the GPU. The link governs *cold-start load time*
(~50 s to push 16.35 GiB over USB3), not tok/s.

## First-time setup

```bash
sudo cp extra/usbgpu/99-tinygrad-usbgpu.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=usb
pip install pyftdi            # only needed for the DEBUG port
```

tinygrad ships **no udev rule**; without one `USB3.__init__` fails with
`libusb_open: Access denied (insufficient permissions)`. The rules file covers every id the dock
can present: tiny custom, the older TinyEnclosure, ASMedia bootloader/stock, and the Gopod rebrand.

That is the *only* host-side setup. No `amdgpu`, no kernel module, no Thunderbolt authorization,
no BIOS changes, no `pci=realloc`, no IOMMU work, and **no need to connect the dock before boot** —
in custom-firmware mode there is no host PCIe hotplug involved at all.

Also install `jinja2` into whatever venv runs `tinygrad.llm.cli`. Without it `cli.py` silently
falls back to a *different* chat template, so results look fine and are not comparable across
hosts.

## Switching firmware

```bash
extra/usbgpu/chestnut-fw.sh status     # which mode, GPU present, what's usable
extra/usbgpu/chestnut-fw.sh backup     # dump the 2 MB flash first
extra/usbgpu/chestnut-fw.sh to-stock   # -> USB4/PCIe (llama.cpp, ROCm, Vulkan)
extra/usbgpu/chestnut-fw.sh to-tiny    # -> USB3 (tinygrad DEV=USB+AMD:LLVM)
```

**The swap is not symmetric.** Flashing only works while the dock presents a USB interface — the
tool pokes the SPI flash via `0xE4`/`0xE5` XDATA vendor requests over libusb. That holds in custom
mode and in stock USB *3.2* mode, but **not** in stock USB4 mode, where `lsusb` shows nothing.

So `to-stock` is one command; `to-tiny` needs the dock out of USB4 first:

- **DEBUG port (reliable):** connect a second USB-C from the host to the board's `DEBUG USB`
  connector, then `extra/usbgpu/debug.py -b -n`. The onboard FT230X pulses RESET with BOOTLOADER
  asserted and the dock reappears as `174c:2463 ASMedia AS2462`, ready to flash. **Both cables are
  required** — the FTDI only drives GPIOs, the main USB-C carries the flash data.
- **A plain USB 3.x hub:** USB4 cannot negotiate through one, so the chip falls back to USB 3.2
  mass-storage mode and reappears on USB.

**What does *not* work** (all tested on the XPS 9315): deauthorizing the Thunderbolt device,
`modprobe -r thunderbolt`, and power-cycling the dock. The ASM2464PD does not fall back to USB 3.2
on a bare USB4 port — it simply stops enumerating.

After any flash, the controller must reboot and the host must renegotiate the connector.
No cables need moving: reset the chip (`debug.py -r -n` over the DEBUG port), then

the reliable sequence is physical, and the order matters -- **power first, USB last**:
unplug the main USB-C, PSU off ~10 s, PSU on ~5 s, then plug the USB-C back in. The 480 Mb/s
state comes from the chip attaching before the board is fully powered, or re-attaching without
a genuine unplug.

`sudo rtcwake -m mem -s 15` (a 15 s s2idle nap) is the software-only fallback: it recovered
SuperSpeed once from a warm post-flash state but failed repeatedly against the cold post-reboot
480 state -- worth one try, not a fix. Lesser measures never work: root-port `disable` cycling,
a UCSI/PD reset, and thunderbolt unload all leave the TB4 port's SS-lane mux stale.

When checking the speed, read the DOCK's own sysfs entry -- `cat /sys/bus/usb/devices/*/speed`
also matches the usb4 root hub, which always says 10000:

```bash
d=$(grep -l 3801 /sys/bus/usb/devices/*/idVendor | head -1); cat ${d%idVendor}speed
``` The controller runs
the old firmware from RAM until then, and switching the dock's ATX PSU is *not* enough — it stays
powered over USB VBUS.

## Hardware notes

- **Power.** The dock supplies 150 W on its 8-pin DC OUT plus 75 W on the slot (225 W from
  DC-in). That is not enough for a 7900 XTX (2x 8-pin, ~355 W TBP), so feed the card from the ATX
  PSU directly.
- **No DIP switches or jumpers.** PCIe power is software-gated: the custom firmware boots with the
  rails off and tinygrad turns them on (vendor request `0xF3`), then checks `LTSSM == 0x78`.
- **Status LED:** blue = PCIe powered down, green = link up, red = link down.
- **Firmware is `ed4e39b7`** on shipping units, which *is* `tinygrad/asm2464pd-firmware` master
  HEAD ("usb: RX serdes tuning", #82, 2026-08-08). There is no newer release.
- **Flash layout:** `[4B LE length][body][0xA5][checksum][crc32]` at offset `0x100`, for both
  firmwares. `e4_flash.py` preserves the `0x000-0x0FF` config area (VID/PID/strings) across a
  write. Flash is Macronix 2 MB (`JEDEC c22815`); only the first ~12 KB is used by tiny firmware,
  ~98 KB by stock.

## Troubleshooting

| symptom | cause |
|---|---|
| `libusb_open: Access denied` | udev rule missing — see setup above |
| Dock enumerates at **USB 2.0, 480 Mb/s**, `usb2-portN: Cannot enable. Maybe the USB cable is bad?` | Not a cable fault. The ASM runs on USB VBUS and enumerates with the dock PSU **off**. Power the dock, re-seat the cable, it comes up at 10 Gbit/s. |
| Stock mode: ASMedia bridges on `lspci` but **no GPU** | **Check the PSU switch is on ( `|` not `O` ).** The `cannot fit 0x100000` bridge-window message is a warning and appears on successful enumerations too — it is not the cause. |
| Newly flashed firmware not running | Unplug/replug the main USB-C. PSU cycling does not reset the controller. |
| `TypeError: FallbackTemplate.render() got an unexpected keyword argument 'enable_thinking'` | `jinja2` not installed in the venv |
| `failed to render Ops.CUSTOM` | `AMD_GEMV=0`, or `:LLVM` missing from `DEV`. The fork's kernels need `DEV=USB+AMD:LLVM`. |
| `MemoryError ... 23.30 GB` at startup | `KV_QUANT=0`; the no-quant path OOMs on 24 GB regardless of `--max_context` |
| Decode ~26 tok/s with `accept 0.00` | Unexplained anomaly seen once, never reproduced across seven runs. Capture the server log if it recurs — see the sweep README. |
| Slow decode generally | Check the CPU governor. The USB path is host-dispatch-latency bound (~800 us per USB round trip vs 4.6 us per kernel) and `powersave` parks the cores at 400-500 MHz. Use `cpu-performance-tuning.service` in the repo root. |

## A patched upstream bug lives in this tree

`USB_COPYIN_GUARD` in `tinygrad/runtime/ops_amd.py` (commit `7843ccead`) fixes a **silent data
corruption bug** in upstream's pipelined copyin: it dropped the first 1 KiB of every 256 KB bounce
window, ~0.1% of every byte written to the GPU, including model weights. Upstream is unaware; their
CI cannot see it because the test data is `randn` cast to `uchar` (dropped bytes often coincide
with expected ones) and no x86/TB4 host is in their runner pool.

**If you rebase or check out another branch, carry that commit.** Without it the model still
produces fluent text — it is just quietly wrong. Verify with:

```bash
SIZE=64000000 GMMU=0 PYTHONPATH=. DEV=USB+AMD python3 test/external/external_test_usb_asm24.py
```

`USB_SAFE_COPYIN=1` is the always-safe fallback (serializes copyin, ~250 MB/s vs ~780 MB/s).

## Files here

| file | what |
|---|---|
| `chestnut-fw.sh` | switch firmware; `status` / `backup` / `to-stock` / `to-tiny` |
| `99-tinygrad-usbgpu.rules` | udev rules for every id the dock presents |
| `debug.py` | FTDI debug port: `-b` bootloader, `-r` reset, `-p` provision EEPROM, `-n` no UART read |
| `patch.py` | flashes tinygrad-patched *stock* firmware onto a third-party ASM2464PD dock (not needed for a chestnut, which ships pre-flashed) |
| `scan_pci.py` | manual PCIe bus walk over USB — **stale**, uses a removed `ASM24Controller` API |
| `../../sweeps/chestnut-usb3-20260830/fw-backup/` | 2 MB flash backup, extracted restore image, parameterised flasher, stock blob |
