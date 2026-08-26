#!/usr/bin/env python3
"""Simulate an agent workload's specific failure mode for plain prefix caching: the tool
list (skills) changes slightly between turns -- Hermes's own logs show this really happens
("check_fn ... returned False; dependent tools will be unavailable this turn"), so a tool
can legitimately vanish/appear turn to turn based on runtime conditions, not just get
appended to. That edits content EARLY in the prompt (inside the system message) while the
conversation TAIL (what's actually being asked) stays byte-identical -- exactly the case
plain longest-common-prefix caching can't recover from, but --cache-reuse's anywhere-in-cache
chunk matching (via KV shifting) is specifically designed for.

Usage: python3 bench.py <base_url> <mode>
  mode=append : turn2 = turn1 + reply + new user msg (pure append, tests baseline --cache-prompt)
  mode=edited : turn2 = [system with one tool added near the start] + turn1's rest + reply + new msg
"""
import json, sys, time, urllib.request, copy, pathlib

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8099/v1"
MODE = sys.argv[2] if len(sys.argv) > 2 else "append"

SKILLS_PATH = pathlib.Path(__file__).parent / "skills_system_prompt.txt"
with open(SKILLS_PATH) as f: SKILLS_TEXT = f.read()

def post(messages, max_tokens=200):
    body = {"model": "x", "messages": messages, "max_tokens": max_tokens, "temperature": 0, "stream": False}
    req = urllib.request.Request(BASE.rstrip("/") + "/chat/completions", data=json.dumps(body).encode(),
                                  headers={"Content-Type": "application/json"})
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=300) as r: d = json.loads(r.read())
    return d, time.perf_counter() - t0

def edited_skills_text():
    # insert one new tool definition right after the opening line -- shifts everything after
    # it in the system message by a few dozen tokens without touching the conversation tail
    marker = "You have access to the following functions:\n\n"
    idx = SKILLS_TEXT.index(marker) + len(marker)
    new_tool = ('{"type": "function", "function": {"name": "newly_enabled_tool", '
                '"description": "A tool that just became available this turn because its requirements check passed.", '
                '"parameters": {"type": "object", "properties": {"x": {"type": "string"}}}}},\n')
    return SKILLS_TEXT[:idx] + new_tool + SKILLS_TEXT[idx:]

turn1_messages = [
    {"role": "system", "content": SKILLS_TEXT},
    {"role": "user", "content": "Search my files for anything mentioning 'quarterly report' and summarize what you find."},
]
print(f"=== turn 1 (mode={MODE}) ===")
d1, t1 = post(turn1_messages)
usage1 = d1.get("usage", {})
cache1 = d1.get("timings", {}).get("cache_n", "?")
print(f"wall={t1:.2f}s prompt_tokens={usage1.get('prompt_tokens')} cache_n={cache1}")
reply1 = d1["choices"][0]["message"]["content"]

if MODE == "append":
    turn2_system = SKILLS_TEXT
else:
    turn2_system = edited_skills_text()

turn2_messages = [{"role": "system", "content": turn2_system}] + turn1_messages[1:] + [
    {"role": "assistant", "content": reply1},
    {"role": "user", "content": "Also check if there's anything from last quarter specifically."},
]
print(f"=== turn 2 (mode={MODE}) ===")
d2, t2 = post(turn2_messages)
usage2 = d2.get("usage", {})
cache2 = d2.get("timings", {}).get("cache_n", "?")
prompt_ms = d2.get("timings", {}).get("prompt_ms", "?")
print(f"wall={t2:.2f}s prompt_tokens={usage2.get('prompt_tokens')} cache_n={cache2} prompt_ms={prompt_ms}")
print(f"RESULT,{MODE},{usage2.get('prompt_tokens')},{cache2},{t2:.3f}")
