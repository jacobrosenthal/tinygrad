#!/usr/bin/env python3
"""Replay recorded requests (serve.py --record-requests) against a server, in order, and report per turn: prompt tokens,
cached-prefix tokens (usage.prompt_tokens_details.cached_tokens), time to first token, decode tok/s, wall.
usage: replay.py <base_url> <trace.jsonl> [--max N] [--interleave other.jsonl --every K]
--interleave replays one request of a second trace after every K requests of the first (a sub-agent burst / second
session), which is what evicts the live prefix cache; the report shows what that costs and whether snapshots recover it."""
import sys, json, time, argparse, urllib.request, csv, pathlib
ap = argparse.ArgumentParser(); ap.add_argument("base"); ap.add_argument("trace"); ap.add_argument("--max", type=int, default=0)
ap.add_argument("--interleave", default=""); ap.add_argument("--every", type=int, default=4); ap.add_argument("--out", default="")
ap.add_argument("--max-tokens", type=int, default=0, help="cap completion length (0 = as recorded)")
a = ap.parse_args()
def load(p): return [json.loads(l) for l in open(p) if l.strip()]
main = [r for r in load(a.trace) if r["path"].endswith("/chat/completions")]
other = [r for r in load(a.interleave) if r["path"].endswith("/chat/completions")] if a.interleave else []
if a.max: main = main[:a.max]
def send(body):
  body = dict(body); body["stream"] = True; body["stream_options"] = {"include_usage": True}
  if a.max_tokens: body["max_tokens"] = a.max_tokens
  req = urllib.request.Request(a.base.rstrip("/") + "/v1/chat/completions", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
  t0 = time.perf_counter(); t_first = t_last = None; n = 0; usage = {}
  with urllib.request.urlopen(req, timeout=3600) as r:
    for line in r:
      line = line.decode().strip()
      if not line.startswith("data:") or line == "data: [DONE]": continue
      try: d = json.loads(line[5:])
      except Exception: continue
      if d.get("usage"): usage = d["usage"]
      ch = d.get("choices") or []
      delta = (ch[0].get("delta") or {}) if ch else {}
      if delta.get("content") or delta.get("reasoning_content") or delta.get("reasoning") or delta.get("tool_calls"):
        now = time.perf_counter(); t_first = t_first or now; t_last = now; n += 1
  ct = usage.get("completion_tokens", n); pt = usage.get("prompt_tokens"); cached = (usage.get("prompt_tokens_details") or {}).get("cached_tokens")
  ttft = (t_first - t0) if t_first else None; dec = ct / (t_last - t_first) if (t_first and t_last and t_last > t_first and ct) else None
  return pt, cached, ct, ttft, dec, time.perf_counter() - t0
out = pathlib.Path(a.out) if a.out else pathlib.Path(a.trace).with_suffix(".replay.csv")
with out.open("w", newline="") as f:
  w = csv.writer(f); w.writerow(["i", "trace", "prompt_tokens", "cached_tokens", "new_tokens", "completion_tokens", "ttft_s", "decode_tok_s", "wall_s"])
  j = 0
  for i, r in enumerate(main):
    for tag, body in [("main", r["body"])] + ([("other", other[j % len(other)]["body"])] if other and i and i % a.every == 0 else []):
      pt, cached, ct, ttft, dec, wall = send(body)
      if tag == "other": j += 1
      row = [i, tag, pt, cached, (pt - cached) if (pt is not None and cached is not None) else None, ct, round(ttft, 2) if ttft else None, round(dec, 1) if dec else None, round(wall, 2)]
      w.writerow(row); f.flush(); print(",".join(map(str, row)), flush=True)
print("wrote", out)
