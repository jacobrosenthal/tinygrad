#!/usr/bin/env python3
"""Layered prefix reuse after merging upstream e1eca014f (recurrent-state prefill checkpoint) with our
recache (26548078e-successor) and prefix-state snapshots:
  1. exact-match path (ours):    A1 -> A2 with the reply sent back verbatim      -> in: ~len(A1+reply)
  2. checkpoint fallback (theirs): A1 -> A2' with the reply sent back EDITED       -> in: len(A1 prompt) (resumed from the
                                   prompt-end checkpoint; only the edited reply + new message prefilled)
  3. snapshot path (ours):        A1 -> interloper B -> A2 verbatim               -> "restored snapshot", in: ~len(A1+reply)
  4. correctness: at temperature 0, A2's content in (1) and (3) must be identical.
Usage: python3 test_layered.py <base_url> <server_log_path>"""
import json, pathlib, re, sys, time, urllib.request

BASE, LOG = sys.argv[1], pathlib.Path(sys.argv[2])
LONG = (pathlib.Path(__file__).parent.parent / "claimed-benchmark-20260824" / "prompts" / "prefill.txt").read_text()
ANSI = re.compile(r"\x1b\[[0-9;]*m")

def post(messages, max_tokens=120):
  body = {"model": "x", "messages": messages, "max_tokens": max_tokens, "temperature": 0, "stream": False}
  req = urllib.request.Request(BASE.rstrip("/") + "/chat/completions", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
  t0 = time.perf_counter()
  with urllib.request.urlopen(req, timeout=600) as r: d = json.loads(r.read())
  return d["choices"][0]["message"], time.perf_counter() - t0

def last_line():
  lines = [ANSI.sub("", l) for l in LOG.read_text(errors="replace").splitlines() if "/v1/chat/completions" in l]
  return re.sub(r"\s+", " ", lines[-1]) if lines else "(none)"

q = "In one sentence, what was Section 1 about? Then the word READY."
a1 = [{"role": "user", "content": LONG}]
m, t = post(a1); r1 = m["content"]; print(f"A1   {t:5.2f}s  {last_line()}")

m, t = post(a1 + [{"role": "assistant", "content": r1}, {"role": "user", "content": q}]); c_exact = m["content"]
print(f"A2   {t:5.2f}s  {last_line()}   <- (1) exact match, expect in: > 2200")

m, t = post(a1); assert m["content"] == r1
m, t = post(a1 + [{"role": "assistant", "content": r1 + " (edited by client)"}, {"role": "user", "content": q}])
print(f"A2'  {t:5.2f}s  {last_line()}   <- (2) edited reply: expect their checkpoint, in: == A1 prompt length (2212)")

m, t = post(a1); assert m["content"] == r1
post([{"role": "user", "content": "Title this chat: user asked about Lisbon weather."}], 40)
print(f"B    ----   {last_line()}   <- expect 'saved snapshot'")
m, t = post(a1 + [{"role": "assistant", "content": r1}, {"role": "user", "content": q}]); c_snap = m["content"]
print(f"A2   {t:5.2f}s  {last_line()}   <- (3) after interloper: expect 'restored snapshot', in: > 2200")
print(f"(4) content identical exact vs after-snapshot: {c_exact == c_snap}\n    {c_exact!r}")
