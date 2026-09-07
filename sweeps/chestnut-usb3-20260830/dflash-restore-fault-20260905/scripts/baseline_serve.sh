#!/bin/bash
# Clean MTP baseline on the rebased branch: serve (warmup excluded from timing) + a real coding request -> gen tok/s + accept.
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
LOG="$SD/baseline-serve.log"; RES="$SD/baseline-serve-result.txt"; : > "$LOG"; : > "$RES"
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
sleep 3
echo "baseline-serve: branch=$(cd /home/jacob/z/tinygrad && git rev-parse --abbrev-ref HEAD)@$(cd /home/jacob/z/tinygrad && git rev-parse --short HEAD) MTP K=3 ctx=8192 $(date +%T)" | tee -a "$RES"
cd /home/jacob/z/tinygrad
DEV=USB+AMD:LLVM LLM_CACHE=1 ATTN_QT=8 MTP_K=3 PYTHONUNBUFFERED=1 "$PY" -m tinygrad.llm.cli --model "$MODEL" \
  --mmproj none --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
srv=$!; t0=$(date +%s); ok=0
while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
  curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
  kill -0 $srv 2>/dev/null || { echo "PROC DIED"|tee -a "$RES"; sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -aiE "Error|Traceback|hang"|tail -4|tee -a "$RES"; break; }
  grep -qaE "Device hang detected|FAULTMAP" "$LOG" && { echo "FAULTED(warmup)"|tee -a "$RES"; break; }
  sleep 10
done
if [ "$ok" = 1 ]; then
  echo "SERVED $(date +%T)"|tee -a "$RES"
  RESP=$(curl -s -m180 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
    -d '{"model":"m","messages":[{"role":"user","content":"Write a Python function that merges two sorted lists into one sorted list, with a short explanation."}],"max_tokens":200,"temperature":0}')
  echo "$RESP" | "$PY" -c "import sys,json
try:
 d=json.load(sys.stdin); t=d['choices'][0]['message'].get('content') or ''
 u=d.get('usage',{})
 print('OUTPUT[:200]:', repr(t[:200]))
 print('COHERENT' if sum(c.isalnum() or c.isspace() for c in t[:250])>180 and len(t)>40 else 'GIBBERISH/EMPTY')
 print('usage:', json.dumps(u))
except Exception as e: print('REQUEST PARSE FAIL:', e)" | tee -a "$RES"
  echo "--- server perf line ---" | tee -a "$RES"
  sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -aE "/v1/chat/completions" | tail -2 | tee -a "$RES"
fi
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
echo "DONE $(date +%T)"|tee -a "$RES"
