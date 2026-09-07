#!/bin/bash
# WAVEDUMP the intermittent DFlash fault: serve DFlash XCTX=0 with WAVEDUMP=1, send LONG requests in a loop until it
# faults (the fault handler then scans the SQ wave grid -> resident-wave PCs). Don't kill the server until fault/exhausted.
SD=/tmp/claude-1001/-home-jacob-z-tinygrad/bbbf3962-a9cf-4c32-800a-58c69b1ea8de/scratchpad
PY=/home/jacob/z/tinygrad/.venv/bin/python3
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
LOG="$SD/dflash-wavedump.log"; RES="$SD/dflash-wavedump-result.txt"; : > "$LOG"; : > "$RES"
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
echo "dflash WAVEDUMP XCTX=0 (loop until fault) $(date +%T)" | tee -a "$RES"
cd /home/jacob/z/tinygrad
WAVEDUMP=1 AMD_USB_SPIN_MS=0 DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0 DEV=USB+AMD:LLVM LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 \
  PYTHONUNBUFFERED=1 "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 \
  --max_context 8192 --host 127.0.0.1 --serve 8080 >> "$LOG" 2>&1 &
srv=$!; t0=$(date +%s); ok=0
while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
  curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 && { ok=1; break; }
  kill -0 $srv 2>/dev/null || { echo "PROC DIED in warmup"|tee -a "$RES"; break; }
  sleep 10
done
if [ "$ok" = 1 ]; then
  echo "SERVED $(date +%T)"|tee -a "$RES"
  P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
     "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
     "Explain and implement a red-black tree insertion in Python, step by step."
     "Write a long Python tutorial on dynamic programming with three worked examples."
     "Implement Dijkstra, A*, and topological sort in Python with complexity notes."
     "Write a detailed explanation of Python generators, coroutines, and asyncio with code."
     "Implement an LRU cache, a trie, and a min-heap in Python with tests."
     "Explain transformer attention and implement scaled dot-product attention in numpy.")
  for i in $(seq 0 7); do
    curl -s -m3 localhost:8080/v1/models >/dev/null 2>&1 || { echo "server down after req $i (faulted)"|tee -a "$RES"; break; }
    echo "req $((i+1)) $(date +%T)"|tee -a "$RES"
    curl -s -m200 http://127.0.0.1:8080/v1/chat/completions -H 'Content-Type: application/json' \
      -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$i]}\"}],\"max_tokens\":500,\"temperature\":0}" >/dev/null 2>&1
    grep -qa "WAVEDUMP done\|hang report for AMD" "$LOG" && { echo "FAULT+WAVEDUMP hit on req $((i+1))"|tee -a "$RES"; break; }
  done
  # let the wavedump (thousands of MMIO reads over USB) finish printing
  t1=$(date +%s); while [ $(( $(date +%s)-t1 )) -lt 150 ]; do grep -qa "WAVEDUMP done" "$LOG" 2>/dev/null && break; kill -0 $srv 2>/dev/null || break; sleep 5; done
fi
echo "=== WAVEDUMP + FAULTMAP + hang report ==="|tee -a "$RES"
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -aE "WAVEDUMP|WAVE se|FAULTMAP|GCVM_L2_PROTECTION|hang report|var_vals" | head -80 | tee -a "$RES"
for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done
echo "DONE $(date +%T)"|tee -a "$RES"
