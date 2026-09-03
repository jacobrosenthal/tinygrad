# Large-copyin SDMA hang reproducer (fixed by capping the ring at USB_COPYIN_GROUP chunks).
# Before the fix: a single copyin > ~7000 chunks (2GB) hangs the SDMA engine
#   RuntimeError: GPU failed to drain USB copyin chunk N (10s, hung GPU?)  +  SDMA_QUEUE_HANG(55)
# 1GB (4096 chunks) is fine; the fix batches the ring into 4096-chunk groups.
# Run against the source tree (PYTHONPATH=.) so edits to ops_amd.py take effect:
#   DEV=USB+AMD PYTHONPATH=. .venv/bin/python hang_repro.py
# To reproduce the OLD hang: USB_COPYIN_GROUP=100000 (one giant ring again).
import os, time, numpy as np
from tinygrad import Tensor, Device

for mb in [1024, 2048, 3000]:
    a = np.frombuffer(os.urandom(mb << 20), np.uint8)  # random, so it also checks correctness
    t = time.perf_counter()
    b = Tensor(a, device="AMD").numpy()
    dt = time.perf_counter() - t
    bad = int((a != b).sum())
    print(f"{mb} MB: {bad} corrupted, {mb/dt:.0f} MB/s ({'OK' if bad==0 else 'CORRUPT'})", flush=True)
