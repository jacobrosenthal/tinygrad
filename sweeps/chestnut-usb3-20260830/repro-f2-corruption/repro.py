# ASM2464PD dock on a fast xHCI host, GPU free. copyin corrupts the front of each
# 256KB chunk: a good host prints nothing, affected hosts print on ~39/40 runs
# (timing race, so loop it).
#   python3 -m venv .venv
#   .venv/bin/pip install numpy git+https://github.com/tinygrad/tinygrad
#   DEV=USB+AMD .venv/bin/python repro.py
# It's a host-timing race (host outruns the DMA engine's arm), so it's
# host-dependent, not card-dependent. Reproduced on an Intel Alder Lake-P
# TB4 USB controller, dock on a Thunderbolt-C port at 10 Gbit (governor
# powersave -- governor is NOT required). A native-USB3/hub or non-TB4 host
# may be too slow to trip it. If it won't reproduce, crank the count:
#   RUNS=200 MB=256 python3 repro.py
import os, numpy as np
from tinygrad import Tensor

RUNS, MB = int(os.getenv("RUNS", 40)), int(os.getenv("MB", 64))
for i in range(RUNS):
    a = np.frombuffer(os.urandom(MB << 20), np.uint8)  # uniform bytes: randn-cast data hides drops
    b = Tensor(a, device="AMD").numpy()                # upload to GPU, read back
    d = np.where(a != b)[0]                            # byte positions that changed
    if len(d):
        o = d[0]
        print(f"run {i}: {len(d)} bad bytes, first @ {o}: sent {a[o]} != got {b[o]}")
