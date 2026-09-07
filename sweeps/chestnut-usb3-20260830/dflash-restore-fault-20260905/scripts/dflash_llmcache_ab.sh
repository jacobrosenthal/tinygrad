#!/bin/bash
# A/B: does the LLM-cache RESTORE trigger the DFlash first-decode-step fault?  Fault-prone config (serialize OFF, spin 0),
# fresh server per run. Sequence: LLM_CACHE=0 x2 (full warmup each, no restore), then LLM_CACHE=1 x2 (restore).
# Expected under the restore hypothesis: 0-runs clean, 1-runs fault on request 1. Records whether each run restored.
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
LOG="$SD/dflash-llmcache-ab.log"; RES="$SD/dflash-llmcache-ab-result.txt"; : > "$LOG"; : > "$RES"
killsrv(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
   "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
   "Explain and implement a red-black tree insertion in Python, step by step."
   "Write a long Python tutorial on dynamic programming with three worked examples.")
echo "LLM_CACHE A/B (serialize OFF, spin 0, USB_VERIFY_WRITES=2) $(date +%T)" | tee -a "$RES"
for CFG in 0 0 1 1; do
  echo "=== RUN LLM_CACHE=$CFG $(date +%T) ===" | tee -a "$RES"
  killsrv; sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
  cd /home/jacob/z/tinygrad; before=$(grep -ac "llm cache: loaded" "$LOG")
  WAVEDUMP=1 USB_VERIFY_WRITES=2 HCQ_USB_SERIALIZE=0 AMD_USB_SPIN_MS=0 DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0 \
    DEV=USB+AMD:LLVM LLM_CACHE=$CFG MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 \
    "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
    --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
  srv=$!; t0=$(date +%s); ok=0
  while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
    curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
    kill -0 $srv 2>/dev/null || { echo "PROC DIED in warmup"|tee -a "$RES"; break; }
    sleep 10
  done
  [ "$ok" = 0 ] && continue
  restored=$(( $(grep -ac "llm cache: loaded" "$LOG") - before ))
  echo "SERVED LLM_CACHE=$CFG restored=$restored startup=$(( $(date +%s)-t0 ))s $(date +%T)"|tee -a "$RES"
  for i in 0 1 2 3; do
    kill -0 $srv 2>/dev/null || { echo "server down after req $i (faulted)"|tee -a "$RES"; break; }
    curl -s -m200 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
      -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$i]}\"}],\"max_tokens\":500,\"temperature\":0}" >/dev/null 2>&1
    gen=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "gen:" | tail -1 | grep -oE "gen: *[0-9]+ tok/s")
    echo "LLM_CACHE=$CFG req $((i+1)) $(date +%T) $gen"|tee -a "$RES"
    grep -qa "hang report for AMD" "$LOG" && { echo "FAULT LLM_CACHE=$CFG restored=$restored req $((i+1))"|tee -a "$RES"; sleep 60; break; }
  done
done
echo "=== SUMMARY ==="|tee -a "$RES"; grep -E "SERVED|FAULT" "$RES"
killsrv; echo "DONE $(date +%T)"|tee -a "$RES"
