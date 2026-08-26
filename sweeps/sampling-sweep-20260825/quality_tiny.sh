#!/usr/bin/env bash
# quality_probe.py arms on the Splizard fork. top_p/top_k are server-fixed there, so the three
# unfiltered arms share one server and qwen_rec gets a second start with --top-p 0.95 --top-k 20.
# --max_context 16384 so an 8K thinking budget fits (production runs 131072; the 4096 sweep caches
# do not apply, so each start is a cold build, ~10 min). Appends to the same quality_results.csv
# with the arm names prefixed "tiny_".
set -uo pipefail
D=/home/j/tinygrad-qwen38-fork/sweeps/sampling-sweep-20260825
PORT=8099; URL=http://127.0.0.1:$PORT/v1
PROBE=${PROBE:-quality_probe.py}                    # quality_probe.py (easy set) or quality_probe_hard.py
ARMS_NOFILTER=${ARMS_NOFILTER:-"greedy old_default server_default"}
MAXTOK=${MAXTOK:-8192}
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate

start() {  # $1 = log name, rest = extra cli flags
  local name=$1; shift
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=1 PYTHONUNBUFFERED=1 python3 -m tinygrad.llm.cli --model /home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf \
    --mmproj none --max_context 16384 --serve $PORT "$@" > $D/logs/quality_tiny_$name.server.log 2>&1 &
  PID=$!
  for _ in $(seq 1 360); do curl -sf $URL/models >/dev/null 2>&1 && return 0; kill -0 $PID 2>/dev/null || { echo "server died"; tail -5 $D/logs/quality_tiny_$name.server.log; return 1; }; sleep 5; done
  echo "server not ready"; return 1
}
stop() { kill $PID 2>/dev/null; sleep 6; kill -9 $PID 2>/dev/null; pkill -9 -f "[t]inygrad.llm.cli"; sleep 4; }

start nofilter || exit 1
for arm in $ARMS_NOFILTER; do echo "=== tiny arm=$arm ==="; python3 $D/$PROBE $URL $arm $MAXTOK tiny_; done
stop
start qwenrec --top-p 0.95 --top-k 20 || exit 1
echo "=== tiny arm=qwen_rec ==="; python3 $D/$PROBE $URL qwen_rec $MAXTOK tiny_
stop
echo "=== TINY PROBE DONE ($PROBE) ==="
