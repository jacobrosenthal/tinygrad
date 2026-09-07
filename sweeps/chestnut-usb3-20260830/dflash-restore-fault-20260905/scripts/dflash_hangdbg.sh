#!/bin/bash
# HANG_DEBUG DFlash XCTX=0: name the faulting kernel via per-kernel progress signals.
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
LOG="$SD/dflash-hangdbg.log"; RES="$SD/dflash-hangdbg-result.txt"; : > "$LOG"; : > "$RES"
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
echo "dflash HANG_DEBUG XCTX=0 $(date +%T)" | tee -a "$RES"
cd /home/jacob/z/tinygrad
HANG_DEBUG=1 DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0 DEV=USB+AMD:LLVM LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 \
  PYTHONUNBUFFERED=1 "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
  --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
srv=$!; t0=$(date +%s); ok=0
while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
  curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
  kill -0 $srv 2>/dev/null || { echo "PROC DIED in warmup"|tee -a "$RES"; break; }
  grep -qaE "Device hang detected|FAULTMAP" "$LOG" && { echo "FAULTED in warmup"|tee -a "$RES"; break; }
  sleep 10
done
if [ "$ok" = 1 ]; then
  echo "SERVED $(date +%T)"|tee -a "$RES"
  curl -s -m120 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
    -d '{"model":"m","messages":[{"role":"user","content":"Write a Python function that merges two sorted lists."}],"max_tokens":80,"temperature":0}' >/dev/null 2>&1
fi
sleep 2
echo "=== HANG REPORT (which kernel) ===" | tee -a "$RES"
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -aiE "hang report|hung|kernel|last (completed|signal)|progress|stuck at|FAULTMAP|fault_va|E_|gemv|attn_|silumul|gdn_|r_[0-9]|conv" | tail -30 | tee -a "$RES"
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
echo "DONE $(date +%T)"|tee -a "$RES"
