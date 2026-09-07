#!/bin/bash
exec 9>/tmp/chestnut-sweep.lock; flock -n 9 || { echo "another sweep holds /tmp/chestnut-sweep.lock; refusing to run concurrently"; exit 1; }
# Bit-exactness gate for the speculative verify path: greedy (temperature 0) outputs of the PLAIN decoder (MTP=0, one token per step,
# T=1 gemvs) vs MTP K=3 vs DFlash2 block 6, same prompts, 400 tokens. Speculative decoding with greedy verify must reproduce the plain
# greedy sequence exactly; a divergence = a verify/KV/positions bug (two groups found such bugs in their spec paths: thc1006, vLLM
# #40914 stale-KV cudagraph). Outputs -> logs/outputs/<cfg>.reqI.json; compare with scripts/bitexact_compare.py.
#   RUNS=1 REQS=8 bash bitexact.sh          # one restored/warm instance per config
N=${REQS:-8}
TOP=/home/jacob/z/tinygrad; PY=$TOP/.venv/bin/python3; TREE=${TREE:-$TOP}
LOGD=$TOP/sweeps/chestnut-usb3-20260830/bitexact-20260906/logs; OUTD=$LOGD/outputs-$(date +%Y%m%d-%H%M%S); mkdir -p "$LOGD" "$OUTD"
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf; DFLASH=/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf
SUM="$LOGD/$(date +%Y%m%d-%H%M%S)-bitexact-summary.txt"
killsrv(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
   "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
   "Explain and implement a red-black tree insertion in Python, step by step."
   "Write a long Python tutorial on dynamic programming with three worked examples."
   "Implement Dijkstra, A*, and topological sort in Python with complexity notes."
   "Write a detailed explanation of Python generators, coroutines, and asyncio with code."
   "Summarize the causes of the French Revolution in five paragraphs, then list ten key dates."
   "Write a 600-word short story about a lighthouse keeper who finds a message in a bottle.")
# MTP=0 (the generic non-fused decode path) OOMs at 8K context on 24 GB (05:10 run: 23.68 GB used during warmup), so the reference is
# the NARROWEST spec chunk instead: MTP K=1. If verify is exact and the fused kernels are chunk-width independent, K=1/3/5 and DFlash
# must produce identical greedy text; which ones differ localizes the problem (T-dependent numerics vs a verify/KV bug).
CFGS=(${CFGS_OVERRIDE:-"mtp-k1|MTP_K=1" "mtp-k3|MTP_K=3" "mtp-k5|MTP_K=5" "dflash-b6|DFLASH=$DFLASH DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0"})
echo "bitexact $(date +%T): fw=$(lsusb 2>/dev/null | grep -oE 'tiny custom [0-9a-f]+-[A-Z]+' | head -1) tree=$(git -C $TREE rev-parse --short HEAD) reqs=$N outputs=$OUTD" | tee -a "$SUM"
for cfg in "${CFGS[@]}"; do
  name=${cfg%%|*}; extra=${cfg#*|}
  if [ -n "$ONLY" ] && ! echo "$name" | grep -qE "$ONLY"; then continue; fi
  LOG="$LOGD/$(date +%Y%m%d-%H%M%S)-bitexact-$name.log"
  killsrv; sleep 3; rm -f /tmp/am_usb:*.lock; cd /
  env $extra PYTHONPATH=$TREE WAVEDUMP=1 LLM_CACHE=1 DEV=USB+AMD:LLVM MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 \
    "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.0 --max_context 8192 --host 127.0.0.1 --serve 8082 >> "$LOG" 2>&1 &
  srv=$!; t0=$(date +%s); ok=0
  while [ $(( $(date +%s)-t0 )) -lt 1200 ]; do curl -s -m3 localhost:8082/v1/models 2>/dev/null | grep -q "\"object\"\|\"data\"" && { ok=1; break; }; kill -0 $srv 2>/dev/null || break; sleep 10; done
  [ "$ok" = 0 ] && { echo "$name: server did not come up" | tee -a "$SUM"; continue; }
  kind=$(grep -qa "llm cache: loaded" "$LOG" && echo restore || echo warmup); gens=()
  for i in $(seq 0 $((N-1))); do
    kill -0 $srv 2>/dev/null || { echo "$name: server died before req $i" | tee -a "$SUM"; break; }
    curl -s -m600 http://127.0.0.1:8082/v1/chat/completions -H 'Content-Type: application/json' \
      -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$((i % 8))]}\"}],\"max_tokens\":400,\"temperature\":0}" > "$OUTD/$name.req$i.json" 2>/dev/null
    gens+=("$(sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -a "gen:" | tail -1 | grep -oE "gen: *[0-9]+ tok/s" | sed -E 's/gen: *//')")
  done
  echo "$name ($kind, startup $(( $(date +%s)-t0 ))s): ${gens[*]}" | tee -a "$SUM"
done
killsrv; echo "DONE $(date +%T)" | tee -a "$SUM"
"$PY" "$TOP/sweeps/chestnut-usb3-20260830/bitexact-20260906/scripts/bitexact_compare.py" "$OUTD" | tee -a "$SUM"
