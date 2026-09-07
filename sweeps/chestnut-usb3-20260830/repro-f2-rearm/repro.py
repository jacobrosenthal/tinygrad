#!/usr/bin/env python3
# Back-to-back small copyins over the USB bridge (ASM2464) can lose the head of a transfer.
# Uploads N random 8-16 KiB buffers, one transfer each with a device synchronize in between (what loading a
# kernel binary does), then reads every buffer back and reports the ones that differ and where.
#   python3 repro.py            # unfixed firmware: some transfers differ, always within bytes [0, 1024)
#   GAP=0.01 python3 repro.py   # 10 ms between uploads: 0 differ
import os, sys, time
import numpy as np
from tinygrad import Tensor, Device

N, LO, HI, GAP = int(os.getenv("N", 800)), int(os.getenv("LO", 8192)), int(os.getenv("HI", 16384)), float(os.getenv("GAP", 0))
dev = Device["AMD"]
assert dev.is_usb(), "run on the USB-attached AMD device"
rng = np.random.default_rng(0)
srcs = [rng.integers(0, 256, int(rng.integers(LO, HI)) & ~3, dtype=np.uint8) for _ in range(N)]

ts = []
t0 = time.perf_counter()
for a in srcs:
  ts.append(Tensor(a, device="AMD").realize())
  dev.synchronize()
  if GAP: time.sleep(GAP)
up = time.perf_counter() - t0

bad = []
for i, (a, t) in enumerate(zip(srcs, ts)):
  b = t.numpy()
  if not np.array_equal(a, b):
    d = np.flatnonzero(a != b)
    bad.append((i, a.size, int(d[0]), int(d[-1]), int(d.size)))

print(f"{len(bad)}/{N} transfers differ (sizes {LO}-{HI} B, gap {GAP} s, {up:.1f} s upload)")
for i, sz, lo, hi, n in bad[:20]: print(f"  #{i} size {sz}: bytes [{lo}, {hi}] differ ({n} bytes)")
sys.exit(1 if bad else 0)
