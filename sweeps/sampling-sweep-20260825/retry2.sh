#!/usr/bin/env bash
set -uo pipefail
# Second retry (2026-08-25), the two *_qwen_recommended legs only. The first retry's
# fork_qwen_recommended still hung: Tensor.topk() is sort()+slice, i.e. a full bitonic sort of the
# ~152K vocab that expanded to ~1300 kernels and took 273s just to schedule one warmup graph
# ("scheduled 1475 kernels in 272891 ms"). _apply_top_pk now uses k rounds of max()+mask-out
# instead (see model.py in both repos). The plain leg from the first retry was killed because it
# had imported the old code 16s before the fix landed. Appends to the same results.csv.
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
  local logfile="$LOGDIR/${leg}.retry2.server.log"
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

  for task in prefill prose code; do
    mt=700; [ "$task" = "prefill" ] && mt=10
    echo "=== [$leg] task=$task ==="
    out=$(python3 "$DIR/send_request.py" "$BASEURL" "$DIR/prompts/${task}.txt" "$mt" "$temp" "$top_p" "$top_k" 2>&1)
    echo "$out" | tee "$LOGDIR/${leg}.retry2.${task}.json"
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
MODEL_REG=/home/j/models/Qwen3.8-27B-Q4_0.gguf

cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate
run_leg "fork_qwen_recommended" "tinygrad-qwen38-fork/.venv/bin/python3" 1.0 0.95 20 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=0 python3 -m tinygrad.llm.cli --top-p 0.95 --top-k 20 \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

cd /home/j/tinygrad && source .venv/bin/activate
run_leg "plain_qwen_recommended" "tinygrad/.venv/bin/python3" 1.0 0.95 20 \
  env DEV=AMD LLM_CACHE=0 python3 -m tinygrad.llm.cli --top-p 0.95 --top-k 20 \
  --model "$MODEL_REG" --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

echo "=== RETRY COMPLETE ==="
cat "$CSV"
