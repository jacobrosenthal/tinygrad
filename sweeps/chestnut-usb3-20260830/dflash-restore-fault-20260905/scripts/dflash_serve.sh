#!/bin/bash
# DFlash timing on the rebased branch + fixed copyin. Same harness as baseline_serve (serve warmup excluded, real
# prompt -> gen tok/s + accept). XCTX arg selects cross-step context window (16 = the config meant to beat MTP;
# 0 = in-chunk only). Compare against MTP baseline 80 tok/s @ 3.08.
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
XCTX=${1:-16}
LOG="$SD/dflash-x${XCTX}.log"; RES="$SD/dflash-x${XCTX}-result.txt"; : > "$LOG"; : > "$RES"
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
echo "dflash-serve XCTX=$XCTX: branch=$(cd /home/jacob/z/tinygrad && git rev-parse --short HEAD) ctx=8192 gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor) $(date +%T)" | tee -a "$RES"
cd /home/jacob/z/tinygrad
DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=$XCTX DEV=USB+AMD:LLVM LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 \
  PYTHONUNBUFFERED=1 "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
  --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
srv=$!; t0=$(date +%s); ok=0
while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
  curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
  kill -0 $srv 2>/dev/null || { echo "PROC DIED"|tee -a "$RES"; sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -aiE "Error|Traceback|hang|FAULTMAP"|tail -5|tee -a "$RES"; break; }
  grep -qaE "Device hang detected|FAULTMAP" "$LOG" && { echo "FAULTED(warmup)"|tee -a "$RES"; sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -aiE "FAULTMAP|hang"|tail -4|tee -a "$RES"; break; }
  sleep 10
done
if [ "$ok" = 1 ]; then
  echo "SERVED $(date +%T)"|tee -a "$RES"
  RESP=$(curl -s -m180 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
    -d '{"model":"m","messages":[{"role":"user","content":"Write a Python function that merges two sorted lists into one sorted list, with a short explanation."}],"max_tokens":200,"temperature":0}')
  echo "$RESP" | "$PY" -c "import sys,json
try:
 d=json.load(sys.stdin); t=d['choices'][0]['message'].get('content') or ''
 print('OUTPUT[:180]:', repr(t[:180]))
 print('COHERENT' if sum(c.isalnum() or c.isspace() for c in t[:250])>180 and len(t)>40 else 'GIBBERISH/EMPTY')
except Exception as e: print('REQUEST PARSE FAIL:', e)" | tee -a "$RES"
  echo "--- server perf line ---" | tee -a "$RES"
  sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -aE "/v1/chat/completions" | tail -2 | tee -a "$RES"
  echo "faultmap_events=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -acE 'FAULTMAP|Device hang')"|tee -a "$RES"
fi
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
echo "DONE $(date +%T)"|tee -a "$RES"
