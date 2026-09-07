#!/usr/bin/env python3
"""Compare the greedy outputs saved by bitexact.sh: for every request, the speculative configs' text (reasoning + answer) against the
plain decoder's. Reports the first divergent character offset and the matching prefix length per request, then a verdict per config.
  python3 bitexact_compare.py <outputs dir>"""
import sys, os, json, glob, collections

d = sys.argv[1]
def text(f):
  j = json.load(open(f)); m = j["choices"][0]["message"]
  return (m.get("reasoning_content") or "") + "\x1e" + (m.get("content") or ""), j.get("usage", {}).get("completion_tokens")
runs = collections.defaultdict(dict)
for f in glob.glob(os.path.join(d, "*.req*.json")):
  try: cfg, req = os.path.basename(f).rsplit(".req", 1); runs[cfg][int(req.split(".")[0])] = text(f)
  except Exception as e: print(f"{f}: unreadable ({e})")
REF = os.environ.get("REF", "mtp-k1")
ref = runs.pop(REF, None)
if ref is None: print(f"no {REF} outputs (set REF=<config>)"); sys.exit(1)
print(f"reference: {REF}")
for cfg, outs in sorted(runs.items()):
  exact = 0; rows = []
  for i in sorted(ref):
    if i not in outs: rows.append(f"  req{i}: missing"); continue
    a, na = ref[i]; b, nb = outs[i]
    if a == b: exact += 1; rows.append(f"  req{i}: EXACT ({na} tok)"); continue
    k = next((k for k, (x, y) in enumerate(zip(a, b)) if x != y), min(len(a), len(b)))
    rows.append(f"  req{i}: diverges at char {k}/{len(a)} (plain {na} tok, {cfg} {nb} tok): plain[..]={a[max(0,k-30):k+20]!r} vs {b[max(0,k-30):k+20]!r}")
  print(f"{cfg}: {exact}/{len(ref)} requests bit-exact vs {REF} greedy" + ("" if exact == len(ref) else "  <-- NOT EXACT"))
  print("\n".join(rows))
