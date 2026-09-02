# Title: F2 bulk OUT silently drops the first ~1KiB of each armed transfer (host race against DMA_START)

## Summary

Pipelined copyin over the 0xF2 engine silently corrupts data: the first ~1KiB
(2 sectors) of each freshly armed BULK OUT transfer is dropped outright. No
error is surfaced anywhere — the transfer "succeeds", the bytes are just gone.
For tinygrad this means ~0.05-0.36% of every byte written to the GPU,
including model weights, on affected hosts. The model still loads and produces
fluent text; it is just quietly wrong.

Seen on: tiny chestnut (shipping fw `ed4e39b7`), Intel TB4/xHCI host
(Dell XPS 9315, i7-1250U), USB 3.2 gen2 10 Gbit/s, RX 7900 XTX.

## Evidence it's a drop, not a reorder/delay

- Corruption is always the *front* of a 256KB chunk, ~1KiB, chunk-aligned.
- A sentinel written into the first 1KiB of the wire image never arrives: a
  GPU-side poll on it hangs forever, while a sentinel at the *tail* of the
  same transfer lands fine. The front bytes are consumed, not late.
- The rate varies run to run (0.05-0.36% of total bytes ≈ some chunks lose
  the full 1KiB, some lose nothing) — i.e. a timing race, not a fixed
  header-eat.

## Root cause (as far as we can tell)

The F2 handler in `handmade/src/main.c` programs the engine and acks
immediately:

```c
REG_NVME_CTRL_STATUS = NVME_CTRL_DMA_START | ...;
REG_NVME_CMD_PARAM   = slot_sel;
usb_send_zlp();          // host is released before the engine is capturing
```

The ZLP completes the control transfer, the host fires its bulk OUT
immediately, and on a fast host the first sectors arrive before the engine's
capture path is live — they fall on the floor. Nothing in firmware can poll
for readiness: as PR #72 notes, the engine has no firmware-visible
ready/completion status.

This looks like the same failure shape as the Flash-DMA "stale first byte"
worked around in PR #83, one layer down.

## Repro

tinygrad master, chestnut on a fast xHCI host:

```
USB_COPYIN_GUARD=0 SIZE=64000000 GMMU=0 PYTHONPATH=. DEV=USB+AMD \
  python3 test/external/external_test_usb_asm24.py
```

(with uniform-random test data and a byte-compare; randn-cast-to-uchar test
data hides it — dropped bytes often coincide with expected values.)

## Host-side workaround (what we run now)

Reserve a guard region at the front of each bounce window so the dropped
bytes land in dead space: payload at `window+1024`, SDMA copies from the
offset, plus strict drain-before-rearm ordering. Costs 0.4% of wire
bandwidth; ~780 MB/s sustained on the 10 Gbit link. Happy to share the diff
(it lives in a tinygrad fork).

## Firmware fix (bench-validated)

The drop is a re-arm race: re-arming the engine while the *previous* transfer
is still draining loses the first ~2 sectors. Register 0xC450 reads 2 while a
bulk DMA is active and 0 when idle (stock firmware never polls it). Poll it
idle before arming the next transfer:

```c
      uint8_t num_slots = REG_USB_SETUP_WIDX_H;
      if (num_slots == 0) num_slots = 1;
+     /* drain the previous bulk DMA before re-arming; re-arming mid-drain drops
+        the first ~2 sectors. C450: 2=active, 0=idle. bounded so it can't wedge. */
+     { uint16_t g = 0; while ((XDATA_REG8V(0xC450) & 0x02) && ++g) ; }
      /* DMA_INIT sequence for SRAM DMA */
      REG_NVME_DOORBELL = 0x0;
      ...
```

It exits immediately in the common case (engine already drained), so no
throughput cost — copyin held ~530 MB/s, same as before, more consistent.

Validated on a chestnut: uniform-random tinygrad Tensor roundtrip,
`USB_COPYIN_GUARD=0`, 50x64MiB = 0 corrupt bytes (was corrupt on ~39/40 runs).

NOTE: an earlier attempt — a fixed settle *after* DMA_START, before the ZLP —
did NOT work (no effect: there is already ample USB scheduling delay before the
bulk data arrives, so the drop is not arm-readiness, it is the previous
transfer's drain). Only the pre-arm idle poll fixes it.
