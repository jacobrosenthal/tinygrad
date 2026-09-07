#!/bin/bash
exec 9>/tmp/chestnut-sweep.lock; flock -n 9 || { echo "another sweep holds /tmp/chestnut-sweep.lock; refusing to run concurrently"; exit 1; }
# Sampling sweep on RESTORED instances: tok/s + accept (and output text saved for a quality look) under real sampling settings.
# Legs = server config (top_p/top_k/penalties are server-fixed flags -> one server per leg) x request temperature.
# Official Qwen3.8 card: thinking temp 1.0 / top_p 0.95 / top_k 20 / min_p 0 / presence 0 / repetition 1.0;
# instruct 0.7 / 0.80 / 20 / presence 1.5. Production today: temp 0.6 (client), no top_p/top_k, --repeat-penalty 1.15.
#   RESTORES=1 REQS=6 bash perf_sweep2.sh
R=${RESTORES:-1}; N=${REQS:-6}
TOP=/home/jacob/z/tinygrad; PY=$TOP/.venv/bin/python3
LOGD=$TOP/sweeps/chestnut-usb3-20260830/dflash-restore-fault-20260905/logs; OUTD=$LOGD/sampling-outputs; mkdir -p "$LOGD" "$OUTD"
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf; DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
SUM="$LOGD/$(date +%Y%m%d-%H%M%S)-sampling-summary.txt"
killsrv(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
   "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
   "Write a long Python tutorial on dynamic programming with three worked examples."
   "Explain transformer attention and implement scaled dot-product attention in numpy."
   "Write a 600-word short story about a lighthouse keeper who finds a message in a bottle."
   "Summarize the causes of the French Revolution in five paragraphs, then list ten key dates.")
# name | env | server flags | request temperature
LEGS=("mtp-t0.6-rp1.15-prod|MTP_K=3|--repeat-penalty 1.15|0.6"
      "mtp-t0.6-rp1.0|MTP_K=3|--repeat-penalty 1.0|0.6"
      "mtp-t1.0-official|MTP_K=3|--repeat-penalty 1.0 --top-p 0.95 --top-k 20|1.0"
      "mtp-t0.6-p95k20|MTP_K=3|--repeat-penalty 1.0 --top-p 0.95 --top-k 20|0.6"
      "mtp-t0.7-instruct|MTP_K=3|--repeat-penalty 1.0 --top-p 0.8 --top-k 20 --presence-penalty 1.5|0.7"
      "dflash-t0.6-rp1.0|DFLASH=$DFLASH DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0|--repeat-penalty 1.0|0.6"
      "dflash-t1.0-official|DFLASH=$DFLASH DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0|--repeat-penalty 1.0 --top-p 0.95 --top-k 20|1.0")
echo "sampling sweep $(date +%T): fw=$(lsusb 2>/dev/null | grep -oE 'tiny custom [0-9a-f]+-[A-Z]+' | head -1) tinygrad=$(git -C $TOP rev-parse --short HEAD) restores=$R reqs=$N" | tee -a "$SUM"
for leg in "${LEGS[@]}"; do
  IFS='|' read -r name extra flags temp <<< "$leg"
  if [ -n "$ONLY" ] && ! echo "$name" | grep -qE "$ONLY"; then continue; fi
  LOG="$LOGD/$(date +%Y%m%d-%H%M%S)-sampling-$name.log"
  echo "=== $name: env[$extra] flags[$flags] temperature=$temp ===" | tee -a "$SUM"
  for RUN in $(seq 0 $R); do   # run 0 = warmup (saves the cache for this env), 1..R = restores (server flags do not change the cache key)
    killsrv; sleep 3; rm -f /tmp/am_usb:*.lock; cd "$TOP"; before=$(grep -ac "llm cache: loaded" "$LOG" 2>/dev/null)
    env $extra WAVEDUMP=1 LLM_CACHE=1 DEV=USB+AMD:LLVM MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 \
      "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none $flags --max_context 8192 --host 127.0.0.1 --serve 8082 >> "$LOG" 2>&1 &
    srv=$!; t0=$(date +%s); ok=0
    while [ $(( $(date +%s)-t0 )) -lt 900 ]; do curl -s -m3 localhost:8082/v1/models 2>/dev/null | grep -q "\"object\"\|\"data\"" && { ok=1; break; }; kill -0 $srv 2>/dev/null || break; sleep 10; done
    [ "$ok" = 0 ] && { echo "$name run $RUN: server did not come up" | tee -a "$SUM"; continue; }
    kind=$([ $(( $(grep -ac "llm cache: loaded" "$LOG") - before )) -gt 0 ] && echo restore || echo warmup)
    gens=(); faults=0
    for i in $(seq 0 $((N-1))); do
      kill -0 $srv 2>/dev/null || { faults=1; break; }
      curl -s -m240 http://127.0.0.1:8082/v1/chat/completions -H 'Content-Type: application/json' \
        -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$((i % 6))]}\"}],\"max_tokens\":500,\"temperature\":$temp}" \
        > "$OUTD/$name.run$RUN.req$i.json" 2>/dev/null
      g=$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "gen:" | tail -1 | grep -oE "gen: *[0-9]+ tok/s.*tok/step\)" | sed -E 's/gen: *//; s/ -- /  /')
      gens+=("$g"); grep -qa "hang report for AMD" "$LOG" && { faults=1; break; }
    done
    echo "$name run $RUN ($kind, startup $(( $(date +%s)-t0 ))s): faults=$faults | ${gens[*]}" | tee -a "$SUM"
  done
done
killsrv; echo "DONE $(date +%T)" | tee -a "$SUM"
