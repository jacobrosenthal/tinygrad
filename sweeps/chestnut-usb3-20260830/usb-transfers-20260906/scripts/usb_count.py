#!/usr/bin/env python3
"""Per-request USB transfer counts from a server log written with LIBUSB_DEBUG=4 (count_transfers.sh). libusb logs every submitted
transfer as "[libusb_submit_transfer]"; control transfers additionally log "[libusb_control_transfer]" (sync), bulk ones
"[libusb_bulk_transfer]"/"[do_sync_bulk_transfer]". Requests are delimited by "=== REQUEST i DONE"; the server's "gen:" line gives
out tokens and tok/step, so transfers per decode step = submits / (out / tok_per_step)."""
import sys, re
lines = open(sys.argv[1], errors="replace").read().split("\n")
start = next((i for i, l in enumerate(lines) if l.startswith("=== REQUESTS START")), 0)
req, cnt, gen = 0, {"submit": 0, "control": 0, "bulk": 0}, None
print(f"{'req':>3s} {'submits':>8s} {'control':>8s} {'bulk':>6s} {'out':>4s} {'tok/step':>8s} {'steps':>6s} {'xfers/step':>10s} {'gen tok/s':>9s}")
for l in lines[start + 1:]:
  if "libusb_submit_transfer" in l: cnt["submit"] += 1
  if "libusb_control_transfer" in l: cnt["control"] += 1
  if "libusb_bulk_transfer" in l or "do_sync_bulk_transfer" in l: cnt["bulk"] += 1
  if "gen:" in l and "tok/step" in l:
    l2 = re.sub(r"\x1b\[[0-9;]*m", "", l)
    m = re.search(r"gen:\s*(\d+) tok/s.*?\(([\d.]+) tok/step\).*?out:\s*(\d+)", l2)
    if m: gen = (int(m.group(1)), float(m.group(2)), int(m.group(3)))
  if l.startswith("=== REQUEST"):
    if gen:
      steps = gen[2] / gen[1] if gen[1] else 0
      print(f"{req:3d} {cnt['submit']:8d} {cnt['control']:8d} {cnt['bulk']:6d} {gen[2]:4d} {gen[1]:8.2f} {steps:6.0f} {cnt['submit'] / steps if steps else 0:10.1f} {gen[0]:9d}")
    else: print(f"{req:3d} {cnt['submit']:8d} {cnt['control']:8d} {cnt['bulk']:6d}  (no gen line)")
    req += 1; cnt = {"submit": 0, "control": 0, "bulk": 0}; gen = None
print("note: request counts include the prefill and the response copyouts; the decode share = (xfers/step) x steps, compare requests of different lengths")
