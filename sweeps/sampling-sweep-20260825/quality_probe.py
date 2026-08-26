#!/usr/bin/env python3
"""Does the recommended sampling profile change *quality* rather than speed? Ten short problems with
checkable answers, a generous thinking budget, several sampling arms. Per run we record: was the final
answer right, did it finish (stop) or hit the token cap (length), how many tokens it used, wall time, and
a repetition score (the most-repeated 12-gram in reasoning+content) -- greedy decoding on thinking models
is known for loops that never reach an answer, which a capped tok/s benchmark cannot see.

Usage: quality_probe.py <base_url> <arm> [max_tokens]   (arm: greedy | old_default | qwen_rec | server_default)
Appends one CSV row per problem to quality_results.csv next to this file."""
import sys, os, json, time, re, csv, pathlib, urllib.request
from collections import Counter

BASE, ARM = sys.argv[1], sys.argv[2]
MAX_TOKENS = int(sys.argv[3]) if len(sys.argv) > 3 else 8192
PREFIX = sys.argv[4] if len(sys.argv) > 4 else ""  # engine tag for the CSV's arm column, e.g. "tiny_"
ARMS = {
  "greedy":         {"temperature": 0.0},
  "old_default":    {"temperature": 0.6, "top_p": 1.0, "top_k": 0, "min_p": 0.0},
  "qwen_rec":       {"temperature": 1.0, "top_p": 0.95, "top_k": 20, "min_p": 0.0, "presence_penalty": 0.0},
  "server_default": {},  # whatever the server does when a request sends nothing
}
PROBLEMS = [  # (prompt, regex the final answer must contain)
  ("What is the sum of all positive integers up to 200 that are divisible by 3 or 5? Give the number.", r"\b9368\b"),
  ("A train leaves at 9:15 and travels 210 km at 84 km/h, with one 20-minute stop. At what time does it arrive? Answer as HH:MM.", r"12:05"),
  ("How many trailing zeros does 125! have?", r"\b31\b"),
  ("What is the remainder when 7^100 is divided by 13?", r"\b9\b"),
  ("In how many ways can 8 people be seated around a round table if two particular people must sit next to each other? (Rotations are the same seating.)", r"\b1440\b"),
  ("What is the smallest positive integer that leaves remainder 2 when divided by 3, remainder 3 when divided by 5, and remainder 2 when divided by 7?", r"\b23\b"),
  ("A rectangle's length is 3 more than twice its width and its perimeter is 48. What is its area?", r"\b119\b"),
  ("How many prime numbers are there below 100? Give the count.", r"\b25\b"),
  ("If f(x) = 3x^2 - 2x + 1, what is f(f(2))?", r"\b226\b"),
  ("Write 0.1875 as a fraction in lowest terms.", r"3\s*/\s*16|\\frac\{3\}\{16\}"),  # greedy arm ran before the LaTeX form was accepted: its 0 on this row is a false negative
]
# PROBE_SET=hard: counting / number-theory problems that force long enumeration -- the regime where the
# community reports greedy/low-temperature thinking degenerating into loops. Keys were computed, not recalled.
# The reply must end with "Answer: <number>"; the last such line is compared exactly (falls back to the last
# integer in the content), so a right number buried in a wrong final answer does not score.
HARD = [
  ("How many positive integers less than 1000 have digits that sum to 15?", "73"),
  ("How many ordered pairs of positive integers (a, b) satisfy a + b = 1000 with neither a nor b containing the digit 0?", "738"),
  ("Find the sum of all three-digit numbers that are divisible by 7 and whose digits are all odd.", "10150"),
  ("What is the 100th prime number?", "541"),
  ("How many 5-card poker hands from a standard 52-card deck contain exactly two pairs (two cards of one rank, two of a second rank, and one card of a third rank)?", "123552"),
  ("What is the smallest positive integer n such that n! ends in exactly 100 zeros?", "405"),
  ("What is the last digit of 3^2025 when it is written in base 7?", "6"),
  ("How many integers from 1 to 10000 inclusive have no two adjacent digits equal?", "7380"),
]
HARD_MODE = os.environ.get("PROBE_SET") == "hard"
if HARD_MODE: PROBLEMS = [(p + " Finish your reply with a line of the form 'Answer: <number>'.", k) for p, k in HARD]

def hard_correct(content, key):
  m = re.findall(r"Answer:?\s*\**\s*\$?\\?(?:boxed\{)?\s*([0-9][0-9,]*)", content)
  if not m: m = re.findall(r"\d[\d,]*", content)
  return bool(m) and m[-1].replace(",", "") == key

def chat(prompt):
  body = {"model": "x", "messages": [{"role": "user", "content": prompt}], "max_tokens": MAX_TOKENS, "stream": False, **ARMS[ARM]}
  req = urllib.request.Request(BASE.rstrip("/") + "/chat/completions", data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
  t0 = time.perf_counter()
  with urllib.request.urlopen(req, timeout=3600) as r: d = json.loads(r.read())
  return d, time.perf_counter() - t0

def repetition(text, n=12):
  toks = text.split()
  if len(toks) < n: return 0
  return max(Counter(tuple(toks[i:i+n]) for i in range(len(toks) - n + 1)).values())

out = pathlib.Path(__file__).parent / ("quality_results_hard.csv" if HARD_MODE else "quality_results.csv")
new = not out.exists()
with out.open("a", newline="") as f:
  w = csv.writer(f)
  if new: w.writerow(["arm", "problem", "correct", "finish", "completion_tokens", "reasoning_chars", "content_chars", "max_12gram_repeats", "wall_s"])
  for i, (prompt, pattern) in enumerate(PROBLEMS):
    d, dt = chat(prompt)
    ch = d["choices"][0]; msg = ch["message"]
    content, reasoning = msg.get("content") or "", msg.get("reasoning_content") or msg.get("reasoning") or ""
    correct = hard_correct(content, pattern) if HARD_MODE else bool(re.search(pattern, content))
    rep = repetition(reasoning + "\n" + content)
    row = [PREFIX + ARM, i, int(correct), ch.get("finish_reason"), d.get("usage", {}).get("completion_tokens"), len(reasoning), len(content), rep, round(dt, 1)]
    w.writerow(row); f.flush()
    print(",".join(map(str, row)), "|", content.strip().replace("\n", " ")[:70], flush=True)
