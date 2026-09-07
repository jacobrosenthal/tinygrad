#!/bin/bash
exec 9>/tmp/chestnut-sweep.lock; flock -n 9 || { echo "another sweep holds /tmp/chestnut-sweep.lock; refusing to run concurrently"; exit 1; }
# Selector sweep, part 2: the block-8 drafter legs that perf_sweep_sel.sh could not start (block 8 = 7 drafts, verify chunk 15 > MAX_T 12).
# Each config carries its own MAX_T (third field). MAX_T=16 compiles gemv variants up to T=15 (the old q5k spills 200+ VGPRs there;
# the gemv-spillfree tree can be selected with TREE=<worktree>). Same protocol: warmup + R restores x REQS long prompts, port 8082.
#   RESTORES=2 REQS=8 bash perf_sweep_sel2.sh
R=${RESTORES:-2}; N=${REQS:-8}
TOP=/home/jacob/z/tinygrad; PY=$TOP/.venv/bin/python3; TREE=${TREE:-$TOP}
LOGD=$TOP/sweeps/chestnut-usb3-20260830/dflash-restore-fault-20260905/logs; mkdir -p "$LOGD"
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf; DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
SUM="$LOGD/$(date +%Y%m%d-%H%M%S)-perfsel2-summary.txt"
killsrv(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
   "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
   "Explain and implement a red-black tree insertion in Python, step by step."
   "Write a long Python tutorial on dynamic programming with three worked examples."
   "Implement Dijkstra, A*, and topological sort in Python with complexity notes."
   "Write a detailed explanation of Python generators, coroutines, and asyncio with code."
   "Implement an LRU cache, a trie, and a min-heap in Python with tests."
   "Explain transformer attention and implement scaled dot-product attention in numpy.")
# name | extra env | MAX_T
CFGS=("dflash-b8-k5-sel|DFLASH=$DFLASH DFLASH_BLOCK=8 MTP_K=5 DFLASH_EAGER_SEL=1 DFLASH_XCTX=0|12"
      "dflash-b8-k7-sel-t16|DFLASH=$DFLASH DFLASH_BLOCK=8 DFLASH_EAGER_SEL=1 DFLASH_XCTX=0|16"
      "dflash-b8-k7-nosel-t16|DFLASH=$DFLASH DFLASH_BLOCK=8 DFLASH_EAGER_SEL=0 DFLASH_XCTX=0|16"
      "mtp-k3-t16|MTP_K=3|16")
echo "perfsel2 $(date +%T): fw=$(lsusb 2>/dev/null | grep -oE 'tiny custom [0-9a-f]+-[A-Z]+' | head -1) tree=$(git -C $TREE rev-parse --short HEAD) restores=$R reqs=$N" | tee -a "$SUM"
for cfg in "${CFGS[@]}"; do
  IFS='|' read -r name extra maxt <<< "$cfg"
  if [ -n "$ONLY" ] && ! echo "$name" | grep -qE "$ONLY"; then continue; fi
  LOG="$LOGD/$(date +%Y%m%d-%H%M%S)-perfsel2-$name.log"
  echo "=== $name: $extra MAX_T=$maxt ===" | tee -a "$SUM"
  for RUN in $(seq 0 $R); do   # run 0 = warmup (saves cache), 1..R = restores
    killsrv; sleep 3; rm -f /tmp/am_usb:*.lock; cd /; before=$(grep -ac "llm cache: loaded" "$LOG" 2>/dev/null)
    env $extra PYTHONPATH=$TREE WAVEDUMP=1 LLM_CACHE=1 DEV=USB+AMD:LLVM MAX_T=$maxt ATTN_QT=8 NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 \
      "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 --max_context 8192 --host 127.0.0.1 --serve 8082 >> "$LOG" 2>&1 &
    srv=$!; t0=$(date +%s); ok=0
    while [ $(( $(date +%s)-t0 )) -lt 1500 ]; do curl -s -m3 localhost:8082/v1/models 2>/dev/null | grep -q "\"object\"\|\"data\"" && { ok=1; break; }; kill -0 $srv 2>/dev/null || break; sleep 10; done
    [ "$ok" = 0 ] && { echo "$name run $RUN: server did not come up ($(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -aE "Error|error" | tail -1 | cut -c1-120))" | tee -a "$SUM"; continue; }
    kind=$([ $(( $(grep -ac "llm cache: loaded" "$LOG") - before )) -gt 0 ] && echo restore || echo warmup)
    gens=(); faults=0
    for i in $(seq 0 $((N-1))); do
      kill -0 $srv 2>/dev/null || { faults=1; break; }
      curl -s -m200 http://127.0.0.1:8082/v1/chat/completions -H 'Content-Type: application/json' \
        -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$((i % 8))]}\"}],\"max_tokens\":500,\"temperature\":0}" >/dev/null 2>&1
      g=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "gen:" | tail -1 | grep -oE "gen: *[0-9]+ tok/s.*tok/step\)" | sed -E 's/gen: *//; s/ -- /  /')
      gens+=("$g"); grep -qa "hang report for AMD" "$LOG" && { faults=1; break; }
    done
    echo "$name run $RUN ($kind, startup $(( $(date +%s)-t0 ))s): faults=$faults | ${gens[*]}" | tee -a "$SUM"
  done
done
killsrv; echo "DONE $(date +%T)" | tee -a "$SUM"
