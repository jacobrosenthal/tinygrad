#!/usr/bin/env python3
"""Prefix reuse on a hybrid (GDN) model, judged against a genuinely cold reference for every case.
The earlier test used prompts whose <think> blocks came out empty, which hid a real bug: relabelling the generated state as the
client's rendering of the reply is unsound once the model actually reasons. So here every turn 1 makes the model think, and every
turn 2 is run twice: once cold (cache_prompt=false, llama.cpp's field) as ground truth, once through the reuse path. temperature 0:
content AND reasoning of the two must be byte-identical, and the reuse path must log a large `in:`.
  case 1  plain chat:      A1 (reasoned answer) -> A2 (client sends content only)      expect in: == len(A1 prompt) - 1
  case 2  tool-call turn:  T1 (assistant returns a tool call) -> T2 (+ tool result)     expect in: == len(T1 prompt) - 1
  case 3  interloper:      A1 -> short unrelated request -> A2                          expect 'restored snapshot' then in: as case 1
Usage: python3 test_reuse_v2.py <base_url> <server_log_path>"""
import json, pathlib, re, sys, time, urllib.request

BASE, LOG = sys.argv[1], pathlib.Path(sys.argv[2])
LONG = (pathlib.Path(__file__).parent.parent / "claimed-benchmark-20260824" / "prompts" / "prefill.txt").read_text()
ANSI = re.compile(r"\x1b\[[0-9;]*m")
TOOLS = [{"type": "function", "function": {"name": "get_weather", "description": "Current weather for a city",
          "parameters": {"type": "object", "properties": {"city": {"type": "string"}}, "required": ["city"]}}}]

def post(messages, max_tokens=700, cold=False, tools=None):
  body = {"model": "x", "messages": messages, "max_tokens": max_tokens, "temperature": 0, "stream": False}
  if cold: body["cache_prompt"] = False
  if tools: body["tools"] = tools
  req = urllib.request.Request(BASE.rstrip("/") + "/chat/completions", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
  t0 = time.perf_counter()
  with urllib.request.urlopen(req, timeout=900) as r: d = json.loads(r.read())
  return d["choices"][0]["message"], d["usage"]["prompt_tokens"], time.perf_counter() - t0

def last_line():
  lines = [ANSI.sub("", l) for l in LOG.read_text(errors="replace").splitlines() if "/v1/chat/completions" in l]
  return re.sub(r"\s+-- +", " | ", lines[-1]).strip() if lines else "(none)"

def same(a, b):
  return (a.get("content") or "") == (b.get("content") or "") and (a.get("reasoning_content") or "") == (b.get("reasoning_content") or "")

def in_of(line):
  m = re.search(r"in:\s*(\d+)\s*\+", line); return int(m.group(1)) if m else -1

ok = True
def check(name, cond, detail=""):
  global ok; ok &= bool(cond); print(f"  [{'PASS' if cond else 'FAIL'}] {name} {detail}")

# ---- case 1: plain chat with real reasoning
print("== case 1: plain chat ==")
a1 = [{"role": "user", "content": LONG + "\n\nThen: a bat and a ball cost $1.10 total; the bat costs $1.00 more than the ball. What does the ball cost? Think it through, then answer in one sentence."}]
m1, p1, t = post(a1); print(f"  A1 {t:5.1f}s reasoning={len(m1.get('reasoning_content') or '')} chars content={m1.get('content')!r:.60}")
check("A1 actually reasoned", len(m1.get("reasoning_content") or "") > 50)
a2 = a1 + [{"role": "assistant", "content": m1["content"]}, {"role": "user", "content": "Now the same puzzle with $2.20 total and a $2.00 difference. One sentence."}]
ref, _, t = post(a2, cold=True); print(f"  A2 cold {t:5.1f}s  {last_line()}")
m1b, _, _ = post(a1, cold=True)  # rebuild the turn-1 state (cold, deterministic) so the reuse path has something to resume from
check("A1 deterministic", same(m1, m1b))
got, _, t = post(a2); line = last_line(); print(f"  A2 warm {t:5.1f}s  {line}")
check("A2 resumed from the prompt-end checkpoint", in_of(line) == p1 - 1, f"(in: {in_of(line)}, expected {p1 - 1})")
check("A2 warm == A2 cold (content + reasoning)", same(ref, got))

# ---- case 2: tool-call turn
print("== case 2: tool-call turn ==")
t1 = [{"role": "user", "content": LONG + "\n\nFinally: what is the weather in Lisbon right now? Use the tool."}]
mt, pt, t = post(t1, tools=TOOLS, cold=True); calls = mt.get("tool_calls") or []
print(f"  T1 {t:5.1f}s tool_calls={[c['function']['name'] for c in calls]}")
check("T1 returned a tool call", bool(calls))
if calls:
  t2 = t1 + [{"role": "assistant", "content": mt.get("content"), "tool_calls": calls},
             {"role": "tool", "tool_call_id": calls[0]["id"], "content": json.dumps({"city": "Lisbon", "temp_c": 24, "sky": "clear"})}]
  ref2, _, t = post(t2, cold=True, tools=TOOLS); print(f"  T2 cold {t:5.1f}s  {last_line()}")
  post(t1, tools=TOOLS, cold=True)  # rebuild the turn-1 state
  got2, _, t = post(t2, tools=TOOLS); line = last_line(); print(f"  T2 warm {t:5.1f}s  {line}")
  check("T2 resumed from the prompt-end checkpoint", in_of(line) == pt - 1, f"(in: {in_of(line)}, expected {pt - 1})")
  check("T2 warm == T2 cold", same(ref2, got2))

# ---- case 3: interloper between A1 and A2
print("== case 3: interloper ==")
post(a1, cold=True)  # turn-1 state again
post([{"role": "user", "content": "Title this chat in three words: the user asked about Lisbon weather."}], max_tokens=60)
print(f"  B  {last_line()}")
got3, _, t = post(a2); line = last_line(); print(f"  A2 after interloper {t:5.1f}s  {line}")
check("snapshot restored", "restored snapshot" in line)
check("A2 resumed from the checkpoint after restore", in_of(line) == p1 - 1, f"(in: {in_of(line)}, expected {p1 - 1})")
check("A2 after interloper == A2 cold", same(ref, got3))
print("ALL PASS" if ok else "SOME FAILED")
