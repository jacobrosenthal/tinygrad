#!/usr/bin/env python3
"""POST one chat completion to an OpenAI-compatible /v1 endpoint, print wall time + token usage as JSON.
Works against both llama.cpp and tinygrad's serve.py -- both return `usage.prompt_tokens`/`completion_tokens`
on a non-streaming request, so this script is engine-agnostic."""
import sys, json, time, urllib.request

def main():
  base_url, prompt_file, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])
  api_key = sys.argv[4] if len(sys.argv) > 4 else None
  prompt = open(prompt_file).read()
  body = {"model": "x", "messages": [{"role": "user", "content": prompt}], "max_tokens": max_tokens,
          "temperature": 0, "stream": False}
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
  content = (data.get("choices", [{}])[0].get("message", {}).get("content", "") or "")
  print(json.dumps({"wall_s": round(t1 - t0, 3), "prompt_tokens": usage.get("prompt_tokens"),
                     "completion_tokens": usage.get("completion_tokens"), "content_preview": content[:80]}))

if __name__ == "__main__": main()
