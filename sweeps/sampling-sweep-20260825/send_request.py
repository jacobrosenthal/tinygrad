#!/usr/bin/env python3
"""POST one chat completion to an OpenAI-compatible /v1 endpoint, print wall time + token usage as JSON.
Works against both llama.cpp and tinygrad's serve.py. Sampling params are exposed as CLI args
(temp/top_p/top_k) so the same script drives both legs of the sampling-settings sweep -- tinygrad's
fork ignores top_p/top_k (not implemented in its JIT sampling kernels, see model.py _sample/_sample_rows)
so those args are no-ops there, but harmless to always send."""
import sys, json, time, urllib.request

def main():
  base_url, prompt_file, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])
  temp = float(sys.argv[4]) if len(sys.argv) > 4 else 0.0
  top_p = float(sys.argv[5]) if len(sys.argv) > 5 else 1.0
  top_k = int(sys.argv[6]) if len(sys.argv) > 6 else 0
  api_key = sys.argv[7] if len(sys.argv) > 7 else None
  prompt = open(prompt_file).read()
  body = {"model": "x", "messages": [{"role": "user", "content": prompt}], "max_tokens": max_tokens,
          "temperature": temp, "top_p": top_p, "top_k": top_k, "stream": False}
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
