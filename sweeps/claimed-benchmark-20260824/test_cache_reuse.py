#!/usr/bin/env python3
"""Controlled 2-turn test: send turn 1, then send turn2 = turn1's messages + the model's own reply
+ one new user message. If the fork's prefix-cache (get_start_pos/_cached_tokens) works, the server
log for turn 2 should report a large `in:<cached>` count. We only control the message content here,
we can't see the `in:` number directly (it only goes to the service's own log), so this script just
issues the requests -- read the journal after running it."""
import json, sys, time, urllib.request

BASE = "http://127.0.0.1:8080/v1"

def post(messages, max_tokens=60):
    body = {"model": "x", "messages": messages, "max_tokens": max_tokens, "temperature": 0, "stream": False}
    req = urllib.request.Request(BASE + "/chat/completions", data=json.dumps(body).encode(),
                                  headers={"Content-Type": "application/json"})
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=300) as resp:
        data = json.loads(resp.read())
    t1 = time.perf_counter()
    return data, t1 - t0

turn1_messages = [
    {"role": "user", "content": "Say exactly the sentence: The quick brown fox jumps over the lazy dog. Nothing else."}
]
print("=== turn 1 ===")
data1, dt1 = post(turn1_messages)
reply1 = data1["choices"][0]["message"]["content"]
print(f"wall={dt1:.2f}s usage={data1.get('usage')} reply={reply1!r}")

turn2_messages = turn1_messages + [
    {"role": "assistant", "content": reply1},
    {"role": "user", "content": "Now say exactly: Pack my box with five dozen liquor jugs. Nothing else."},
]
print("=== turn 2 (should reuse turn 1's prefix if caching works) ===")
data2, dt2 = post(turn2_messages)
reply2 = data2["choices"][0]["message"]["content"]
print(f"wall={dt2:.2f}s usage={data2.get('usage')} reply={reply2!r}")
