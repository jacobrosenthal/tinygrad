#!/usr/bin/env python3
"""The interloper scenario the prefix-state snapshots exist for:
  A1: long conversation A, turn 1 (a ~2.2K-token prompt)      -> cold prefill, expected in:0
  B : a short, unrelated request (a title-gen / sub-agent / other-session stand-in)
  A2: conversation A, turn 2 (A1 + its reply + a new message)  -> BEFORE: in:0 (B evicted A's state, full reprocess)
                                                                  AFTER:  snapshot of A restored, in:~A1-length
Reads the server's own `in:` numbers from the log file given as argv[2] (the client can't see them otherwise).
Usage: python3 test_interloper.py <base_url> <server_log_path>"""
import json, pathlib, re, subprocess, sys, time, urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8099/v1"
LOG = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else None
HERE = pathlib.Path(__file__).parent
LONG = (HERE.parent / "claimed-benchmark-20260824" / "prompts" / "prefill.txt").read_text()

def post(messages, max_tokens=60):
  body = {"model": "x", "messages": messages, "max_tokens": max_tokens, "temperature": 0, "stream": False}
  req = urllib.request.Request(BASE.rstrip("/") + "/chat/completions", data=json.dumps(body).encode(),
                                headers={"Content-Type": "application/json"})
  t0 = time.perf_counter()
  with urllib.request.urlopen(req, timeout=600) as r: d = json.loads(r.read())
  return d, time.perf_counter() - t0

def last_in_line() -> str:
  if LOG is None or not LOG.exists(): return "(no log)"
  ansi = re.compile(r"\x1b\[[0-9;]*m")
  lines = [ansi.sub("", l) for l in LOG.read_text(errors="replace").splitlines() if "/v1/chat/completions" in l]
  return lines[-1].strip() if lines else "(no completion lines yet)"

a1 = [{"role": "user", "content": LONG}]
d, t = post(a1); r1 = d["choices"][0]["message"]["content"]
print(f"A1 wall={t:.2f}s usage={d.get('usage')}\n   {last_in_line()}")

b = [{"role": "user", "content": "Give this chat a short title: the user asked about the weather in Lisbon."}]
d, t = post(b)
print(f"B  wall={t:.2f}s usage={d.get('usage')}\n   {last_in_line()}")

a2 = a1 + [{"role": "assistant", "content": r1}, {"role": "user", "content": "Now say only the word READY."}]
d, t = post(a2)
print(f"A2 wall={t:.2f}s usage={d.get('usage')}\n   {last_in_line()}")
