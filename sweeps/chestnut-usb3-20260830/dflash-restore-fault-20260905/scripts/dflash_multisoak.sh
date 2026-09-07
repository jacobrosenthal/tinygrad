#!/bin/bash
# Rule out per-instance luck: 2 more FRESH server instances, each 60 fresh requests under SPIN_MS=0. Any fault = not fixed.
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
RES="$SD/dflash-multisoak-result.txt"; : > "$RES"
killtg(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
echo "MULTI-SERVER SOAK (2 fresh servers x 60 req, SPIN_MS=0, HCQ core fix) $(date +%T)"|tee -a "$RES"
for s in 1 2; do
  LOG="$SD/multisoak-s$s.log"; : > "$LOG"
  killtg; sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
  cd /home/jacob/z/tinygrad
  AMD_USB_SPIN_MS=0 DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0 DEV=USB+AMD:LLVM LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 \
    PYTHONUNBUFFERED=1 "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
    --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
  srv=$!; t0=$(date +%s); ok=0
  while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
    curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
    kill -0 $srv 2>/dev/null || { echo "server$s: PROC DIED warmup"|tee -a "$RES"; break; }
    grep -qaE "hang report|FAULTMAP" "$LOG" && { echo "server$s: FAULTED warmup"|tee -a "$RES"; break; }
    sleep 10
  done
  [ "$ok" != 1 ] && continue
  good=0; fault=0
  for i in $(seq 1 60); do
    curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 || { fault=1; break; }
    r=$(curl -s -m30 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
      -d '{"model":"m","messages":[{"role":"user","content":"Write a Python function that merges two sorted lists into one sorted list."}],"max_tokens":20,"temperature":0,"cache_prompt":false}' 2>/dev/null)
    echo "$r" | grep -q '"content"' && good=$((good+1))
    grep -qa "hang report for AMD" "$LOG" && { fault=1; break; }
  done
  nf=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -acE "hang report for AMD")
  echo "server$s: good=$good hang_reports=$nf $(date +%T)"|tee -a "$RES"
  killtg
done
echo "MULTISOAK DONE $(date +%T)"|tee -a "$RES"
