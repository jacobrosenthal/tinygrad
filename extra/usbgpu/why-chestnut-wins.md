# Why the chestnut (USB3) beats OCuLink — the two setup findings

Companion to [`README.md`](README.md) (operating guide) and
[`sweeps/chestnut-usb3-20260830/`](../../sweeps/chestnut-usb3-20260830/) (measurements).
Written 2026-09-01. Headline result being explained: prose 54-58 vs 52-53, code 75-84 vs
70-73 tok/s, prefill ~746 vs ~529 tok/s peak — over a link ~6x narrower, on a 9W laptop
chip vs a 45W NUC.

## Finding 1: the USB path spends its narrow lane on almost nothing

The two setups move data in fundamentally different ways.

**M8 + OCuLink (KFDIface, kernel amdgpu):** buffers get real CPU mappings. Host RAM is
mmap'd and mapped into the GPU's address space via KFD ioctls; VRAM BARs are mmap'd back.
"Filling" GPU-visible memory is a plain memcpy into mapped pages; bulk transfers ride SDMA
at PCIe 4.0 x4 speeds (multi-GB/s).

**Chestnut (USBIface, `tinygrad/runtime/ops_amd.py:975`):** there is **no CPU mapping at
all** (`has_cpu_mapping=False`), and `alloc()` forces every buffer into VRAM
(`force_devmem=True` — the code notes VRAM writes beat SRAM writes on this path). Every
host→GPU byte streams through two alternating 256KB SRAM bounce windows via the 0xF2
engine (~780 MB/s with the `USB_COPYIN_GUARD` fix; this is exactly the path the guard
patched). GPU→host readback goes through 0xF0 streaming reads. Completion signals live in
VRAM *deliberately* — GPU signal writes to the shared SYS region collide with the 0xF2
stream mid-flight, so they are read back over 0xF0 instead.

The consequence is a design philosophy: **never let the wire carry anything that matters
per-token.** Weights, KV, activations, signals all stay resident in VRAM. What crosses USB
at decode time is token IDs in, sampled tokens and doorbell pokes out — kilobytes. The JIT
batches whole decode-step command buffers into single submissions, so one token step is a
handful of USB round trips instead of hundreds. That is why a 10 Gbit/s link ties a
64 Gbit/s one on tok/s: the architecture reduced the link's job to control traffic.

Where the narrow lane DOES show: bulk transfers only. Weight load (~51 s for 16.35 GiB)
and prefix-snapshot save/restore (2.32 GB ≈ 9 s over 0xF0, ~250 MB/s — background,
overlapped with serving; on the M8's mapped path this was sub-second). At
`--max_context 131072` snapshots grow to ~2.9 GB / ~11-12 s each.

## Finding 2: the host tuning that mattered was CPU governor — and it's matched; the GPU knob moved into tinygrad

The M8's `gpu-power-tuning.service` did **two separate things** that are easy to conflate:

1. **CPU governor → performance** (its own comments called this the "MTP dispatch fix").
   This is the part that actually moves tok/s: the USB path is host-dispatch-latency-bound
   (~800 µs per USB round trip vs 4.6 µs of kernel time), and under `powersave` the cores
   read the wait as idle and park at 400-500 MHz. Dispatch is a single-threaded sprint, not
   a marathon — which is why a 2-P-core 9 W i7-1250U at forced `performance` beats a 45 W
   H-class Ryzen at `powersave`, and still edges it at matched governors. **Both hosts were
   at `performance` for the final sweep numbers**, so the chestnut's win is not a governor
   mismatch artifact. On the XPS this job belongs to `cpu-performance-tuning.service`
   (repo root).

2. **GPU `power_dpm_force_performance_level = high`** — this one was for the 7900 XTX, but
   it is an **amdgpu sysfs knob**, so it only exists where the kernel driver binds. On the
   M8/OCuLink the card sat on the host PCI bus under amdgpu and the write worked. On the
   chestnut the GPU never appears on the host PCI bus, amdgpu never binds, and the file
   does not exist — tinygrad's AM driver does its own SMU init and sets the card's
   performance state itself (`AM_POWER_LIMIT` in the service unit is the optional cap).

Historical scar tissue worth keeping: the M8 unit hard-failed when its GPU sysfs write
didn't land, and the server unit's `Requires=` on it meant the server never started. Hence
the standing rule in both current unit files: **`Wants=`, never `Requires=`, and every GPU
write is best-effort.**

## One-line summary

The migration swapped a wider pipe and a bigger CPU for a smarter protocol and a
faster-waking core — and won on every number except the one-time ~51 s weight load.
