#!/bin/bash
# Clean DFlash-vs-MTP timing now that the wild-write is fixed. Production-matched (default AMD_USB_SPIN_MS, no WAVEDUMP).
# For XCTX in {0,16}: fresh serve, one fresh 200-tok coding request -> gen tok/s + accept + coherence + fault count.
# Compare to MTP baseline 80 tok/s @ 3.08 (same harness, baseline_serve).
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
RES="$SD/dflash-compare-result.txt"; : > "$RES"
killtg(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
echo "DFlash-vs-MTP clean timing (MTP baseline: 80 tok/s @ 3.08). $(date +%T)" | tee -a "$RES"
run(){ # $1=xctx
  local xctx="$1" LOG="$SD/cmp-x$xctx.log"; : > "$LOG"
  killtg; sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
  cd /home/jacob/z/tinygrad
  DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=$xctx DEV=USB+AMD:LLVM LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 \
    PYTHONUNBUFFERED=1 "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
    --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
  local srv=$! t0=$(date +%s) ok=0
  while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
    curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
    kill -0 $srv 2>/dev/null || { echo "XCTX=$xctx: PROC DIED"|tee -a "$RES"; sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -aiE "Error|Traceback"|tail -3|tee -a "$RES"; return; }
    grep -qaE "hang report|FAULTMAP" "$LOG" && { echo "XCTX=$xctx: FAULTED(warmup)"|tee -a "$RES"; return; }
    sleep 10
  done
  [ "$ok" != 1 ] && { echo "XCTX=$xctx: NEVER SERVED"|tee -a "$RES"; return; }
  local RESP=$(curl -s -m180 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
    -d '{"model":"m","messages":[{"role":"user","content":"Write a Python function that merges two sorted lists into one sorted list, with a short explanation."}],"max_tokens":200,"temperature":0,"cache_prompt":false}')
  local coh=$(echo "$RESP" | "$PY" -c "import sys,json
try:
 d=json.load(sys.stdin); t=d['choices'][0]['message'].get('content') or ''
 print('COHERENT' if len(t)>40 and sum(c.isalnum() or c.isspace() for c in t[:250])>180 else 'GIBBERISH', repr(t[:60]))
except Exception as e: print('PARSEFAIL',e)")
  local perf=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -aE "/v1/chat/completions"|tail -1)
  local nf=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG"|grep -acE "hang report|FAULTMAP")
  echo "XCTX=$xctx: $coh | faults=$nf | $perf" | tee -a "$RES"
  killtg
}
run 0
run 16
killtg; echo "DONE $(date +%T)"|tee -a "$RES"
