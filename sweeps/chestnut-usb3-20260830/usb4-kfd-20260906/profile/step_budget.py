#!/usr/bin/env python3
"""Per-decode-step time budget from a tinygrad PROFILE=1 trace. Decode steps are HCQ graphs (ProfileGraphEvent: ents = kernels with
st_id/en_id into sigs = device timestamps in us). A spec step = a run of graphs starting with the smallest graph (the 32-kernel one
here). Prints wall / device-busy / gap per step, the between-graph and within-graph gaps, and the top kernels and families.
  python3 step_budget.py <profile.pkl> [first-graph-kernel-count=32]"""
import sys, pickle, collections, statistics as st
evs = pickle.load(open(sys.argv[1], "rb"))
G = [e for e in evs if type(e).__name__ == "ProfileGraphEvent" and e.ents and e.ents[0].device.startswith("AMD")]
first_n = int(sys.argv[2]) if len(sys.argv) > 2 else min(len(g.ents) for g in G[-40:])
def kernels(g):  # [(name, st, en)] in us
  out = []
  for en in g.ents:
    s, e = float(g.sigs[en.st_id]), float(g.sigs[en.en_id])
    if s > 0 and e > 0: out.append((en.name, s, e))
  return out
G.sort(key=lambda g: min(float(g.sigs[e.st_id]) for e in g.ents if float(g.sigs[e.st_id]) > 0))
starts = [i for i, g in enumerate(G) if len(g.ents) == first_n]
steps = [G[starts[i]:starts[i + 1]] for i in range(len(starts) - 1)]
steps = [s for s in steps if len(s) >= 2][3:]  # steady state
print(f"{len(G)} AMD graphs; {len(steps)} steps analysed; graphs/step {collections.Counter(len(s) for s in steps).most_common(2)}; kernels/step {sum(len(g.ents) for g in steps[0])}")
walls, busy, between, within, per_k, cnt = [], [], [], [], collections.defaultdict(float), collections.Counter()
for s, nxt in zip(steps, steps[1:]):
  ks = [kernels(g) for g in s]; flat = [k for g in ks for k in g]
  w = kernels(nxt[0])[0][1] - flat[0][1]; walls.append(w)
  ivs = sorted((a, b) for _, a, b in flat); tot, cs, ce = 0.0, None, None
  for a, b in ivs:
    if ce is None or a > ce:
      if ce is not None: tot += ce - cs
      cs, ce = a, b
    else: ce = max(ce, b)
  tot += ce - cs; busy.append(tot)
  between.append(sum(ks[i + 1][0][1] - ks[i][-1][2] for i in range(len(ks) - 1)) + (kernels(nxt[0])[0][1] - ks[-1][-1][2]))
  within.append(sum(max(0.0, g[i + 1][1] - g[i][2]) for g in ks for i in range(len(g) - 1)))
  for n, a, b in flat: per_k[n] += b - a; cnt[n] += 1
n = len(walls); W = st.mean(walls)
print(f"wall/step {W/1e3:.2f} ms (min {min(walls)/1e3:.2f}, max {max(walls)/1e3:.2f}) | device busy {st.mean(busy)/1e3:.2f} ms | idle {(W-st.mean(busy))/1e3:.2f} ms = between-graph {st.mean(between)/1e3:.2f} + within-graph kernel gaps {st.mean(within)/1e3:.2f}")
print(f"graphs per step: " + ", ".join(f"{len(g.ents)}k" for g in steps[0]))
fam = collections.defaultdict(float)
for name, t in per_k.items():
  f = name.split("_")[0]; f = "gemv_multi" if name.startswith("gemv_multi") else f
  fam[f] += t / n
print("by family (ms/step, share of wall): " + ", ".join(f"{k} {v/1e3:.2f} ({100*v/W:.0f}%)" for k, v in sorted(fam.items(), key=lambda kv: -kv[1])[:12]))
# bytes per gemv call from the kernel name (weights only): gemv_<fmt>_<N>_<K>_t.. / gemv_multi_<fmt><N>_<fmt><N>.._<K>_t..
from tinygrad.llm.amd_gemv import FORMATS
BB = {f["name"]: f["bb"] for f in FORMATS.values()}
import re
def wbytes(name):
  if name.startswith("gemv_multi_"):
    m = re.match(r"gemv_multi_((?:[a-z0-9_]+?\d+_)+?)(\d+)_t", name)
    if not m: return 0
    segs, K = m.group(1).rstrip("_").split("_"), int(m.group(2)); tot = 0
    i = 0
    while i < len(segs):
      seg = segs[i]
      if seg == "q8": seg = "q8_" + segs[i + 1]; i += 1      # q8_0<N> splits on the underscore
      f = max((n for n in BB if seg.startswith(n)), key=len); tot += int(seg[len(f):]) * K // 256 * BB[f]; i += 1
    return tot
  m = re.match(r"gemv_([a-z0-9_]+?)_(\d+)_(\d+)_t", name)
  return int(m.group(2)) * int(m.group(3)) // 256 * BB[m.group(1)] if m and m.group(1) in BB else 0
tot_bytes = sum(wbytes(nm) * c for nm, c in cnt.items()) / n
print(f"weight bytes streamed per step: {tot_bytes/1e9:.2f} GB -> {tot_bytes/1e9/(W/1e6):.0f} GB/s over the wall step, {tot_bytes/1e9/((fam.get("gemv",0)+fam.get("gemv_multi",0))/1e6):.0f} GB/s over gemv time")
print("\ntop kernels (ms/step, share, calls/step, achieved GB/s):")
for name, t in sorted(per_k.items(), key=lambda kv: -kv[1])[:24]:
  b = wbytes(name); print(f"  {t/n/1e3:7.3f} ms {100*t/n/W:5.1f}%  x{cnt[name]/n:4.2f}  {(b*cnt[name]/t*1e6/1e9 if b and t else 0):5.0f} GB/s  {name[:100]}")
