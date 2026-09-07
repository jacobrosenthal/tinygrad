# Standalone check of the hang-report VRAM reader path (same attribute walk as hcq.py _read_va), GPU alive.
import numpy as np
from tinygrad import Tensor, Device
dev = Device["AMD"]; assert dev.is_usb()
adev = getattr(getattr(dev, "iface", None), "dev_impl", None) or getattr(dev, "dev_impl", None)
print("adev:", type(adev).__name__, "large_bar:", getattr(adev, "large_bar", None))
a = np.arange(65536, dtype=np.uint8)  # 64 KiB, > one 4 KiB page, non-trivial pattern
t = Tensor(a, device="AMD").realize(); dev.synchronize()
hb = t.uop.buffer._buf  # HCQBuffer
m = getattr(hb, "meta", None); m = getattr(m, "mapping", m)
print("meta:", type(getattr(hb, "meta", None)).__name__, "->", type(m).__name__, "paddrs:", getattr(m, "paddrs", None)[:3] if hasattr(m, "paddrs") else None)
def read_va(buf, n):
  mm = getattr(buf, "meta", None); mm = getattr(mm, "mapping", mm)
  off, out = buf.va_addr - mm.va_addr, b""
  for paddr, psize in mm.paddrs:
    if off >= psize: off -= psize; continue
    take, p = min(psize - off, n - len(out)), paddr + off; off = 0
    out += bytes(adev.vram.view(p, take)[:]) if getattr(adev, "large_bar", False) else adev._read_vram(p, (take + 3) & ~3)
    if len(out) >= n: break
  return out[:n]
got = read_va(hb, a.size)
print("readback matches:", got == a.tobytes(), "| first 16:", got[:16].hex(), "| via numpy:", bool(np.array_equal(t.numpy(), a)))
