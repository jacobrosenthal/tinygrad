#!/usr/bin/env bash
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$DIR/results.csv"
LOGDIR="$DIR/logs"
PORT=8099
BASEURL="http://127.0.0.1:$PORT/v1"
MODEL=/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
mkdir -p "$LOGDIR"
echo "cache_reuse_setting,mode,prompt_tokens,cache_n,wall_s" > "$CSV"

wait_ready() {
  local pid="$1"
  for _ in $(seq 1 120); do
    curl -sf "$BASEURL/models" >/dev/null 2>&1 && return 0
    kill -0 "$pid" 2>/dev/null || return 1
    sleep 2
  done
  return 1
}

run_config() {
  local tag="$1" cache_reuse="$2"
  local logfile="$LOGDIR/${tag}.server.log"
  echo "=== [$tag] starting (--cache-reuse $cache_reuse) ==="
  ./build/bin/llama-server -m "$MODEL" --host 127.0.0.1 --port "$PORT" \
    --device Vulkan1 -sm none --load-mode none -c 65536 -ngl all -fa on -b 2048 -ub 512 \
    --cache-type-k q4_0 --cache-type-v q4_0 --cache-reuse "$cache_reuse" \
    --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 --parallel 1 \
    > "$logfile" 2>&1 &
  local pid=$!
  if ! wait_ready "$pid"; then echo "FAILED to start"; tail -30 "$logfile"; kill -9 "$pid" 2>/dev/null; return 1; fi
  echo "=== [$tag] ready, pid=$pid ==="

  for mode in append edited; do
    out=$(python3 "$DIR/bench.py" "$BASEURL" "$mode" 2>&1)
    echo "$out"
    line=$(echo "$out" | grep "^RESULT," | sed "s/^RESULT,/$cache_reuse,/")
    echo "$line" >> "$CSV"
    curl -sf -X POST "http://127.0.0.1:$PORT/slots/0?action=erase" >/dev/null 2>&1
  done

  kill "$pid" 2>/dev/null
  for _ in 1 2 3 4 5 6 7 8; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
  kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  sleep 3
}

cd /home/j/llama.cpp
run_config "reuse_off" 0
run_config "reuse_256" 256

echo "=== DONE ==="
cat "$CSV"
