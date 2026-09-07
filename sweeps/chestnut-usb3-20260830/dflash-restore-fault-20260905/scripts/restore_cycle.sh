#!/bin/bash
exec 9>/tmp/chestnut-sweep.lock; flock -n 9 || { echo "another sweep holds /tmp/chestnut-sweep.lock; refusing to run concurrently"; exit 1; }
# Warmup -> restore cycle for the DFlash first-decode-step fault. NEVER truncates: every launch writes new timestamped files
# under sweeps/chestnut-usb3-20260830/dflash-restore-fault-20260905/logs/. Run 1 = full warmup (saves the LLM cache), runs 2..N =
# restore (reproduce the fault, ~3 min each). Do not edit tinygrad/**/*.py between run 1's cache save and the restores.
#   RUNS=3 REQS=8 bash restore_cycle.sh            # default: 1 warmup + 2 restores, 8 long requests each
N=${RUNS:-3}; R=${REQS:-8}
TOP=/home/jacob/z/tinygrad; PY=$TOP/.venv/bin/python3
LOGD=$TOP/sweeps/chestnut-usb3-20260830/dflash-restore-fault-20260905/logs; mkdir -p "$LOGD"
TS=$(date +%Y%m%d-%H%M%S); LOG="$LOGD/$TS-restore-cycle.log"; RES="$LOGD/$TS-restore-cycle-result.txt"
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf; DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
killsrv(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
   "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
   "Explain and implement a red-black tree insertion in Python, step by step."
   "Write a long Python tutorial on dynamic programming with three worked examples."
   "Implement Dijkstra, A*, and topological sort in Python with complexity notes."
   "Write a detailed explanation of Python generators, coroutines, and asyncio with code."
   "Implement an LRU cache, a trie, and a min-heap in Python with tests."
   "Explain transformer attention and implement scaled dot-product attention in numpy.")
{ echo "restore cycle $TS: RUNS=$N REQS=$R fw=$(lsusb 2>/dev/null | grep -oE 'tiny custom [0-9a-f]+-[A-Z]+' | head -1) tinygrad=$(git -C $TOP rev-parse --short HEAD) dirty=$(git -C $TOP status --short | grep -c '^ M')";
  echo "env: WAVEDUMP=1 USB_VERIFY_WRITES=${USB_VERIFY_WRITES:-2} HCQ_USB_SERIALIZE=${HCQ_USB_SERIALIZE:-0} AMD_USB_SPIN_MS=${AMD_USB_SPIN_MS:-0} LLM_CACHE=${LLM_CACHE:-1} DFLASH_XCTX=0 DFLASH_BLOCK=6 DFLASH_NOSEL=1"; } | tee -a "$RES"
for RUN in $(seq 1 $N); do
  echo "=== RESTART $RUN $(date +%T) ===" | tee -a "$RES"
  killsrv; sleep 3; rm -f /tmp/am_usb:*.lock 2>/dev/null
  cd "$TOP"; before=$(grep -ac "llm cache: loaded" "$LOG" 2>/dev/null)
  WAVEDUMP=1 USB_VERIFY_WRITES=${USB_VERIFY_WRITES:-2} HCQ_USB_SERIALIZE=${HCQ_USB_SERIALIZE:-0} AMD_USB_SPIN_MS=${AMD_USB_SPIN_MS:-0} LLM_CACHE=${LLM_CACHE:-1} \
    DFLASH="$DFLASH" DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0 DEV=USB+AMD:LLVM MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 \
    "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 --max_context 8192 --host 127.0.0.1 --serve 8082 >> "$LOG" 2>&1 &
  srv=$!; t0=$(date +%s); ok=0
  while [ $(( $(date +%s)-t0 )) -lt 900 ]; do
    curl -s -m3 localhost:8082/v1/models 2>/dev/null | grep -q "\"object\"\|\"data\"" && { ok=1; break; }
    kill -0 $srv 2>/dev/null || { echo "PROC DIED in warmup (run $RUN)"|tee -a "$RES"; break; }
    sleep 10
  done
  [ "$ok" = 0 ] && continue
  kind=$([ $(( $(grep -ac "llm cache: loaded" "$LOG") - before )) -gt 0 ] && echo restore || echo warmup)
  echo "SERVED run $RUN kind=$kind startup=$(( $(date +%s)-t0 ))s $(date +%T)"|tee -a "$RES"
  for i in $(seq 0 $((R-1))); do
    kill -0 $srv 2>/dev/null || { echo "server down run $RUN after req $i"|tee -a "$RES"; break; }
    curl -s -m200 http://127.0.0.1:8082/v1/chat/completions -H 'Content-Type: application/json' \
      -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$((i % 8))]}\"}],\"max_tokens\":500,\"temperature\":0}" >/dev/null 2>&1
    gen=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "gen:" | tail -1 | grep -oE "gen: *[0-9]+ tok/s")
    echo "run $RUN ($kind) req $((i+1)) $(date +%T) drops=$(grep -ac 'DROPPED host->GPU' "$LOG") $gen"|tee -a "$RES"
    grep -qa "hang report for AMD" "$LOG" && { echo "FAULT run $RUN ($kind) req $((i+1))"|tee -a "$RES"; sleep 90; break; }
  done
done
echo "=== SUMMARY ==="|tee -a "$RES"; grep -E "SERVED|FAULT" "$RES"
killsrv; echo "DONE $(date +%T)"|tee -a "$RES"
