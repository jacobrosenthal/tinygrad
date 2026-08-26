#!/usr/bin/env bash
# Smoke test for the --top-p/--top-k/--temperature CLI flags + cache key (2026-08-25). Two starts:
# 1st builds the JITs and saves a cache under extra='top_p=0.95 top_k=20'; 2nd must load it.
set -uo pipefail
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate
D=sweeps/sampling-sweep-20260825; PORT=8099
for run in 1 2; do
  echo "=== start $run ==="
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=1 PYTHONUNBUFFERED=1 python3 -m tinygrad.llm.cli --model /home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf \
    --mmproj none --max_context 4096 --temperature 1.0 --top-p 0.95 --top-k 20 --serve $PORT > $D/logs/flag_smoke_$run.log 2>&1 &
  pid=$!; t0=$(date +%s)
  until curl -sf http://127.0.0.1:$PORT/v1/models >/dev/null 2>&1; do kill -0 $pid 2>/dev/null || { echo "died"; tail -5 $D/logs/flag_smoke_$run.log; exit 1; }; sleep 5; done
  echo "ready after $(( $(date +%s) - t0 ))s; cache line: $(grep -o 'llm cache[^|]*' $D/logs/flag_smoke_$run.log | head -2 | tr '\n' ' ')"
  python3 $D/send_request.py http://127.0.0.1:$PORT/v1 $D/prompts/code.txt 120 1.0 0.5 5   # deliberately different p/k: expect the 'ignored' note
  grep -o "note: request top_p.*" $D/logs/flag_smoke_$run.log | head -1
  kill $pid; sleep 6; kill -9 $pid 2>/dev/null; pkill -9 -f "[t]inygrad.llm.cli"; sleep 4
done
ls -la ~/.cache/tinygrad/llm/ 2>/dev/null | tail -3
echo "=== SMOKE DONE ==="
