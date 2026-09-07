#!/usr/bin/env python3
# Summarize a perf_sweep.sh summary file into a per-config table (restored runs only): mean/min gen tok/s and mean tok/step.
import re, sys, glob, os, statistics as st
d = os.path.dirname(os.path.abspath(__file__)) + "/../logs"
f = sys.argv[1] if len(sys.argv) > 1 else sorted(glob.glob(d + "/*-perf-summary.txt"), key=os.path.getmtime)[-1]
rows, cfg = {}, None
for line in open(f):
  m = re.match(r"(\S+) run (\d+) \((warmup|restore), startup (\d+)s\): faults=(\d)", line)
  if not m: continue
  name, run, kind, startup, faults = m.group(1), int(m.group(2)), m.group(3), int(m.group(4)), int(m.group(5))
  gens = [int(x) for x in re.findall(r"(\d+) tok/s(?!tep)", line)]; steps = [float(x) for x in re.findall(r"\(([\d.]+) tok/step\)", line)]
  rows.setdefault(name, []).append((kind, startup, faults, gens, steps))
print(f"{os.path.basename(f)}\n{'config':12s} {'runs':>4s} {'faults':>6s} {'req/run':>7s} {'mean tok/s':>10s} {'min':>4s} {'max':>4s} {'tok/step':>8s} {'req1 tok/s':>10s} {'restore s':>9s}")
for name, rs in rows.items():
  rest = [r for r in rs if r[0] == "restore"] or rs
  gens = [g for r in rest for g in r[3]]; steps = [s for r in rest for s in r[4]]; req1 = [r[3][0] for r in rest if r[3]]
  print(f"{name:12s} {len(rest):4d} {sum(r[2] for r in rs):6d} {min(len(r[3]) for r in rest):7d} {st.mean(gens) if gens else 0:10.1f} "
        f"{min(gens) if gens else 0:4d} {max(gens) if gens else 0:4d} {st.mean(steps) if steps else 0:8.2f} {st.mean(req1) if req1 else 0:10.1f} "
        f"{st.mean([r[1] for r in rest]):9.0f}")
