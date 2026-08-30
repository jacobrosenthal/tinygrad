#!/usr/bin/env python3
"""POST one chat completion to an OpenAI-compatible /v1 endpoint and emit one JSON line.

v3-equivalent of the harness used for `pre-chestnut-baseline-20260830` (which lived in
~/llama.cpp/sweeps/newquants-20260828/ on the M8 and is not on this host):

  - temperature defaults to 0.6, matching the production service, NOT the temperature=0 of the
    older copies in sweeps/*-20260825/ (those are the ones the baseline README warns about)
  - captures `reasoning_content` separately from `content`, and flags truncation inside reasoning
  - reads prefill / gen tok/s and MTP accept rate from the SERVER's own stderr log line rather than
    deriving them client-side. Per this repo's standing "trust the wire" rule, the client's
    wall-clock view spans prep+prefill+decode and is not a decode tok/s figure.

Usage: send_request.py BASE_URL PROMPT_FILE MAX_TOKENS [--server-log PATH] [--temperature T] [--api-key K]
"""
import sys, json, time, re, argparse, urllib.request

ANSI = re.compile(r'\x1b\[[0-9;]*m')

def parse_server_tail(text):
  """Pull the server's own numbers out of the log region produced by this request."""
  t = ANSI.sub('', text)
  out = {}
  # serve.py: "prefill:NNNN tok/s", "gen:NNNN tok/s", "accept:N.NN (N.NN tok/step)"
  if (m := re.findall(r'prefill:\s*(\d+(?:\.\d+)?)\s*tok/s', t)): out['server_prefill_tok_s'] = float(m[-1])
  if (m := re.findall(r'gen:\s*(\d+(?:\.\d+)?)\s*tok/s', t)):     out['server_gen_tok_s'] = float(m[-1])
  if (m := re.findall(r'accept:\s*(\d+\.\d+)', t)):               out['server_accept_rate'] = float(m[-1])
  if (m := re.findall(r'accept:\s*\d+\.\d+\s*\(([\d.]+) tok/step\)', t)): out['server_tok_per_step'] = float(m[-1])
  return out

def main():
  ap = argparse.ArgumentParser()
  ap.add_argument('base_url'); ap.add_argument('prompt_file'); ap.add_argument('max_tokens', type=int)
  ap.add_argument('--server-log'); ap.add_argument('--temperature', type=float, default=0.6)
  ap.add_argument('--api-key'); ap.add_argument('--task', default=''); ap.add_argument('--trial', type=int, default=0)
  a = ap.parse_args()

  prompt = open(a.prompt_file).read()
  # note where the server log ends before we ask, so we only read back OUR request's lines
  log_start = 0
  if a.server_log:
    try: log_start = open(a.server_log, 'rb').seek(0, 2) or open(a.server_log, 'rb').seek(0, 2)
    except OSError: log_start = 0
    with open(a.server_log, 'rb') as f: f.seek(0, 2); log_start = f.tell()

  body = {"model": "x", "messages": [{"role": "user", "content": prompt}],
          "max_tokens": a.max_tokens, "temperature": a.temperature, "stream": False}
  headers = {"Content-Type": "application/json"}
  if a.api_key: headers["Authorization"] = f"Bearer {a.api_key}"
  req = urllib.request.Request(a.base_url.rstrip('/') + '/chat/completions',
                               data=json.dumps(body).encode(), headers=headers)
  t0 = time.perf_counter()
  try:
    with urllib.request.urlopen(req, timeout=1800) as resp: data = json.loads(resp.read())
  except Exception as e:
    print(json.dumps({"task": a.task, "trial": a.trial, "error": str(e)})); return 1
  wall = time.perf_counter() - t0

  ch = (data.get('choices') or [{}])[0]
  msg = ch.get('message', {}) or {}
  content = msg.get('content') or ''
  reasoning = msg.get('reasoning_content') or ''
  usage = data.get('usage', {}) or {}
  rec = {"trial": a.trial, "task": a.task, "wall_s": round(wall, 3),
         "prompt_tokens": usage.get('prompt_tokens'), "completion_tokens": usage.get('completion_tokens'),
         "finish_reason": ch.get('finish_reason'), "content_len": len(content), "reasoning_len": len(reasoning),
         # v3's exact definition (baseline-harness/send_request-v3-original.py): reasoning present, no answer
         "truncated_in_reasoning": bool(reasoning) and not content}
  if (ds := (usage.get('decode_seconds'))) is not None: rec['decode_seconds'] = ds
  if (pd := (usage.get('prompt_tokens_details') or {}).get('cached_tokens')) is not None: rec['cached_tokens'] = pd

  if a.server_log:
    time.sleep(0.3)  # let the server flush its stderr line
    with open(a.server_log, 'rb') as f:
      f.seek(log_start); rec.update(parse_server_tail(f.read().decode('utf-8', 'replace')))
  print(json.dumps(rec))
  return 0

if __name__ == '__main__': sys.exit(main())
