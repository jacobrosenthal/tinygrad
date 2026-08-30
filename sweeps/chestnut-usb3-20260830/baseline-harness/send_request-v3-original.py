#!/usr/bin/env python3
"""POST one chat completion to an OpenAI-compatible /v1 endpoint, print wall time + token usage as JSON.
Works against both llama.cpp and tinygrad's serve.py -- both return `usage.prompt_tokens`/`completion_tokens`
on a non-streaming request, so this script is engine-agnostic.

v2 (2026-08-28): also reads `message.reasoning_content` and `finish_reason`. The original version only
read `message.content`, which is silently empty on a reasoning model whenever the response is truncated
mid-thought (finish_reason=length with the whole token budget spent on chain-of-thought) -- that made
every llama.cpp prose/code leg in this sweep (and in the older claimed-benchmark-20260824 sweep) look
like it produced nothing, when actually it just never got a real answer within max_tokens."""
import sys, json, time, urllib.request

def main():
  # v3 (2026-08-28): temperature defaults to 0.6 now, not 0. Greedy decoding (temp=0) on this
  # reasoning model gets stuck looping in chain-of-thought and never emits a stop token or
  # transitions to a final answer -- confirmed directly: same prompt, temp=0 -> content_len=0,
  # finish_reason=length even at max_tokens=3000; temp=0.6 -> a real, complete answer. This
  # was silently poisoning every llama.cpp leg in this sweep AND in claimed-benchmark-20260824
  # (both hardcoded temp=0) -- their empty content_preview wasn't "no output", it was this.
  # 0.6 matches the production Hermes setting (custom_providers.extra_body), already measured
  # with no quality loss and ~7% faster decode via better MTP acceptance (sampling-sweep-20260825).
  base_url, prompt_file, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])
  api_key = sys.argv[4] if len(sys.argv) > 4 else None
  temperature = float(sys.argv[5]) if len(sys.argv) > 5 else 0.6
  prompt = open(prompt_file).read()
  body = {"model": "x", "messages": [{"role": "user", "content": prompt}], "max_tokens": max_tokens,
          "temperature": temperature, "stream": False}
  headers = {"Content-Type": "application/json"}
  if api_key: headers["Authorization"] = f"Bearer {api_key}"
  req = urllib.request.Request(base_url.rstrip("/") + "/chat/completions", data=json.dumps(body).encode(), headers=headers)
  t0 = time.perf_counter()
  try:
    with urllib.request.urlopen(req, timeout=600) as resp:
      data = json.loads(resp.read())
  except Exception as e:
    print(json.dumps({"error": str(e)}))
    return
  t1 = time.perf_counter()
  usage = data.get("usage", {})
  choice = (data.get("choices") or [{}])[0]
  msg = choice.get("message", {}) or {}
  content = msg.get("content") or ""
  reasoning = msg.get("reasoning_content") or ""
  print(json.dumps({
    "wall_s": round(t1 - t0, 3),
    "prompt_tokens": usage.get("prompt_tokens"),
    "completion_tokens": usage.get("completion_tokens"),
    "finish_reason": choice.get("finish_reason"),
    "content_len": len(content),
    "reasoning_len": len(reasoning),
    "content_preview": content[:200],
    "truncated_in_reasoning": bool(reasoning) and not content,
  }))

if __name__ == "__main__": main()
