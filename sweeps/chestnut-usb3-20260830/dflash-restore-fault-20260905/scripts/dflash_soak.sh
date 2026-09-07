#!/bin/bash
# Validate the HCQ core acquire fix: DFlash XCTX=0, SPIN_MS=0 (high fault rate), 100 fresh cache_prompt:false requests.
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
LOG="$SD/dflash-soak.log"; RES="$SD/dflash-soak-result.txt"; : > "$LOG"; : > "$RES"
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
echo "DFlash SOAK XCTX=0 SPIN_MS=0 (HCQ core acquire fix) $(date +%T)" | tee -a "$RES"
cd /home/jacob/z/tinygrad
WAVEDUMP=1 AMD_USB_SPIN_MS=0 DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0 DEV=USB+AMD:LLVM LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 \
  PYTHONUNBUFFERED=1 "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
  --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
srv=$!; t0=$(date +%s); ok=0
while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
  curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
  kill -0 $srv 2>/dev/null || { echo "PROC DIED in warmup"|tee -a "$RES"; sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -aiE "Error|Traceback"|tail -3|tee -a "$RES"; break; }
  grep -qaE "hang report|FAULTMAP" "$LOG" && { echo "FAULTED warmup"|tee -a "$RES"; break; }
  sleep 10
done
if [ "$ok" = 1 ]; then
  echo "SERVED $(date +%T)"|tee -a "$RES"
  good=0; fault=0
  for i in $(seq 1 100); do
    curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 || { echo "server died at req $i"|tee -a "$RES"; fault=1; break; }
    r=$(curl -s -m30 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
      -d '{"model":"m","messages":[{"role":"user","content":"Write a Python function that merges two sorted lists into one sorted list, with a short explanation."}],"max_tokens":24,"temperature":0,"cache_prompt":false}' 2>/dev/null)
    echo "$r" | grep -q '"content"' && good=$((good+1))
    grep -qa "hang report for AMD" "$LOG" && { echo "FAULT at req $i"|tee -a "$RES"; fault=1; break; }
    [ $((i % 25)) -eq 0 ] && echo "  ...$i done, $good ok, no fault $(date +%T)"|tee -a "$RES"
  done
  echo "SOAK RESULT: good=$good fault=$fault (fault=0 across 100 => core fix validated)"|tee -a "$RES"
fi
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
echo "DONE $(date +%T)"|tee -a "$RES"
