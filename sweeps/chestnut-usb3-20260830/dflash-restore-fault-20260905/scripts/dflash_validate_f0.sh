#!/bin/bash
# POST-FLASH VALIDATION of the F0 arm-race firmware fix. Same fault-prone config as the detector (serialize OFF, spin 0,
# USB_VERIFY_WRITES=1 so any residual drop is still logged), across N FRESH server instances (per-instance variance is the trap).
# PASS = 0 "DROPPED" lines AND 0 faults across all runs. Also records tok/s (verify-fence cost). Usage: dflash_validate_f0.sh [N=6]
N=${1:-6}
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
LOG="$SD/dflash-validate-f0.log"; RES="$SD/dflash-validate-f0-result.txt"; : > "$LOG"; : > "$RES"
killsrv(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
   "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
   "Explain and implement a red-black tree insertion in Python, step by step."
   "Write a long Python tutorial on dynamic programming with three worked examples."
   "Implement Dijkstra, A*, and topological sort in Python with complexity notes."
   "Write a detailed explanation of Python generators, coroutines, and asyncio with code."
   "Implement an LRU cache, a trie, and a min-heap in Python with tests."
   "Explain transformer attention and implement scaled dot-product attention in numpy.")
fw=$(lsusb 2>/dev/null | grep -oE "tiny custom [0-9a-f]+-[A-Z]+" | head -1)
echo "VALIDATE F0 fix: firmware='$fw' N=$N fresh servers (serialize OFF, spin 0, USB_VERIFY_WRITES=1) $(date +%T)" | tee -a "$RES"
faults=0
for RUN in $(seq 1 $N); do
  echo "=== RESTART $RUN $(date +%T) ===" | tee -a "$RES"
  killsrv; sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
  cd /home/jacob/z/tinygrad
  WAVEDUMP=1 USB_VERIFY_WRITES=1 HCQ_USB_SERIALIZE=0 AMD_USB_SPIN_MS=0 DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0 \
    DEV=USB+AMD:LLVM LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 \
    "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
    --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
  srv=$!; t0=$(date +%s); ok=0
  while [ $(( $(date +%s)-t0 )) -lt 700 ]; do
    curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
    kill -0 $srv 2>/dev/null || { echo "PROC DIED in warmup (run $RUN)"|tee -a "$RES"; break; }
    sleep 10
  done
  [ "$ok" = 0 ] && continue
  echo "SERVED run $RUN $(date +%T)  drops-so-far=$(grep -ac 'DROPPED host->GPU' "$LOG")"|tee -a "$RES"
  for i in $(seq 0 7); do
    kill -0 $srv 2>/dev/null || { echo "server down run $RUN after req $i (faulted)"|tee -a "$RES"; faults=$((faults+1)); break; }
    curl -s -m200 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
      -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$i]}\"}],\"max_tokens\":500,\"temperature\":0}" >/dev/null 2>&1
    gen=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "gen:" | tail -1 | grep -oE "gen: *[0-9]+ tok/s|accept: [0-9.]+ \([0-9.]+ tok/step\)" | tr '\n' ' ')
    echo "run $RUN req $((i+1)) $(date +%T)  drops=$(grep -ac 'DROPPED host->GPU' "$LOG")  $gen"|tee -a "$RES"
    grep -qa "hang report for AMD\|GCVM_L2_PROTECTION_FAULT_STATUS.*'cid': 8" "$LOG" && { echo "FAULT run $RUN req $((i+1))"|tee -a "$RES"; faults=$((faults+1)); break; }
  done
done
echo "=== SUMMARY firmware='$fw' ==="|tee -a "$RES"
echo "runs=$N faults=$faults DROPPED-writes=$(grep -ac 'DROPPED host->GPU' "$LOG")"|tee -a "$RES"
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "DROPPED host->GPU" | head -10 | tee -a "$RES"
killsrv
echo "DONE $(date +%T)"|tee -a "$RES"
