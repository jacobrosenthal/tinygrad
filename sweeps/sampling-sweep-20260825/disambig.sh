#!/usr/bin/env bash
set -uo pipefail
# Disambiguation sweep (2026-08-25, splizard fork only): the main sweep had t=0.6, t=1.0 and
# t=1.0+top_p+top_k, which can't separate top-k from top-p or say whether the filter cost depends
# on temperature. Four legs fill that in, plus a greedy (t=0) control -- the 08-24 claimed-benchmark
# fork_mtp1 leg ran at t=0 and got 57.6/72.9 prose/code tok/s. Each generation task runs twice so
# the noise floor is visible in the CSV. LLM_CACHE=1: the sampling flags are in the cache key now,
# so this also leaves warm caches behind for reruns; it does not affect the measured tok/s.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$DIR/results.csv"
LOGDIR="$DIR/logs"
PORT=8099
BASEURL="http://127.0.0.1:$PORT/v1"
mkdir -p "$LOGDIR"
[ -f "$CSV" ] || echo "leg,task,temp,top_p,top_k,wall_s,prompt_tokens,completion_tokens,prefill_tok_s,gen_tok_s,content_preview" > "$CSV"

export PARALLEL=4

wait_ready() {
  local pid="$1"
  for _ in $(seq 1 360); do
    curl -sf "$BASEURL/models" >/dev/null 2>&1 && return 0
    kill -0 "$pid" 2>/dev/null || { echo "process $pid died during warmup"; return 1; }
    sleep 5
  done
  return 1
}

ram_available_gb() { free -m | awk '/^Mem:/{printf "%.2f", $7/1024}'; }

wait_ram_clear() {
  for _ in $(seq 1 60); do
    avail=$(ram_available_gb)
    awk -v a="$avail" 'BEGIN{exit !(a>=6)}' && { echo "RAM clear: ${avail}GB available"; return 0; }
    sleep 3
  done
  echo "FATAL: RAM never cleared (last: ${avail}GB, need >=6GB)." >&2
  return 1
}

CUR_PID=""; CUR_KILLPAT=""
cleanup_on_interrupt() {
  echo "=== interrupted, cleaning up (pid=$CUR_PID pattern=$CUR_KILLPAT) ==="
  [ -n "$CUR_PID" ] && kill -9 "$CUR_PID" 2>/dev/null
  [ -n "$CUR_KILLPAT" ] && pkill -9 -f "$CUR_KILLPAT" 2>/dev/null
  exit 130
}
trap cleanup_on_interrupt INT TERM

run_leg() {
  local leg="$1" killpat="$2" temp="$3" top_p="$4" top_k="$5"; shift 5
  local logfile="$LOGDIR/${leg}.server.log"
  echo "=== [$leg] starting (temp=$temp top_p=$top_p top_k=$top_k): $* ==="
  "$@" > "$logfile" 2>&1 &
  local pid=$!
  CUR_PID="$pid"; CUR_KILLPAT="$killpat"
  if ! wait_ready "$pid"; then
    echo "=== [$leg] FAILED to become ready ==="
    tail -30 "$logfile"
    kill -9 "$pid" 2>/dev/null; pkill -9 -f "$killpat" 2>/dev/null; wait "$pid" 2>/dev/null
    wait_ram_clear || exit 1
    return 1
  fi
  echo "=== [$leg] ready, pid=$pid ==="

  local n=0
  for task in prefill prose code prose code; do
    n=$((n+1))
    mt=700; [ "$task" = "prefill" ] && mt=10
    echo "=== [$leg] task=$task ==="
    out=$(python3 "$DIR/send_request.py" "$BASEURL" "$DIR/prompts/${task}.txt" "$mt" "$temp" "$top_p" "$top_k" 2>&1)
    echo "$out" | tee "$LOGDIR/${leg}.${task}.$n.json"
    pt=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('prompt_tokens') or 0)" 2>/dev/null || echo 0)
    ct=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('completion_tokens') or 0)" 2>/dev/null || echo 0)
    ws=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('wall_s') or 0)" 2>/dev/null || echo 0)
    cp=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print((d.get('content_preview') or '').replace(chr(10),' ').replace(',',';'))" 2>/dev/null || echo "")
    prefill_tps=$(python3 -c "print(round($pt/$ws,2) if $ws>0 else 0)" 2>/dev/null || echo 0)
    gen_tps=$(python3 -c "print(round($ct/$ws,2) if $ws>0 else 0)" 2>/dev/null || echo 0)
    echo "$leg,$task,$temp,$top_p,$top_k,$ws,$pt,$ct,$prefill_tps,$gen_tps,\"$cp\"" >> "$CSV"
  done

  echo "=== [$leg] stopping pid=$pid (and any $killpat workers) ==="
  kill "$pid" 2>/dev/null
  for _ in 1 2 3 4 5 6 7 8; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
  kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  pkill -9 -f "$killpat" 2>/dev/null
  CUR_PID=""; CUR_KILLPAT=""
  wait_ram_clear || exit 1
}

MODEL_XL=/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
KP="tinygrad-qwen38-fork/.venv/bin/python3"
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate

run_leg "fork_t00" "$KP" 0.0 1.0 0 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=1 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"

run_leg "fork_t10_k20" "$KP" 1.0 1.0 20 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=1 python3 -m tinygrad.llm.cli --top-k 20 \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"

run_leg "fork_t10_p95" "$KP" 1.0 0.95 0 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=1 python3 -m tinygrad.llm.cli --top-p 0.95 \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"

run_leg "fork_t06_p95_k20" "$KP" 0.6 0.95 20 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=1 python3 -m tinygrad.llm.cli --top-p 0.95 --top-k 20 \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

echo "=== DISAMBIG COMPLETE ==="
