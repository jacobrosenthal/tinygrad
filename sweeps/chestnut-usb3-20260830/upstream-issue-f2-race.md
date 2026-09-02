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

## Proposed firmware fix (untested-upstream, works on the bench)

Since there is no ready bit to poll, hold the ZLP through a hardware-timed
settle after DMA_START — the same idiom stock firmware uses on the CE00 path
("read CE89 ~128 times"):

```c
REG_NVME_CTRL_STATUS = NVME_CTRL_DMA_START | (bulk_in ? 0 : NVME_CTRL_WRITE_DIR);
REG_NVME_CMD_PARAM   = slot_sel;
{ uint8_t s; for (s = 0; s < 128; s++) (void)(*(__xdata volatile uint8_t *)0xCE89); }
usb_send_zlp();
```

Note the volatile cast: plain `XDATA_REG8` reads get elided by SDCC and the
loop collapses to an empty `djnz` spin. The right count is an empirical
question (it trades per-arm latency against margin); 128 XDATA reads is a
starting point, not a measurement.

If someone knows an actual ready/valid bit for this engine, that would beat
the settle — the docs and PR #72 suggest there isn't one.
