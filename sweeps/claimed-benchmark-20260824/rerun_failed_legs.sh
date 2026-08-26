#!/usr/bin/env bash
set -uo pipefail
# Follow-up for the two legs that failed in run_sweep.sh's first pass, appending to
# the same results.csv rather than re-running everything (fork_mtp1 already
# succeeded; llamacpp legs run independently and don't share these constraints):
#
#   fork_mtp0:      hit a real VRAM ceiling at max_context=4096 (the dense/no-MTP
#                   path in this fork peaks higher than the MTP path does) ->
#                   retry at max_context=2560 (still >= the ~2222 tokens the
#                   prefill prompt needs, just less preallocated headroom).
#   official_dense: mainline tinygrad's GGUF loader can't read UD-Q4_K_XL at all
#                   (Q3_K/type-11 unsupported, documented separately) -> retry
#                   against bartowski's plain Q4_K_M instead, the same file
#                   tinygrad-server.service already uses, at the original 4096.
#
# Same safety machinery as run_sweep.sh (pattern-kill, RAM-clear gate, interrupt
# trap, fast warmup-death detection) -- see that script/the incident note in
# docs/development/qwen38-mtp-fork-splizard.md for why all of this exists.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$DIR/results.csv"
LOGDIR="$DIR/logs"
PORT=8099
BASEURL="http://127.0.0.1:$PORT/v1"
mkdir -p "$LOGDIR"
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
  echo "FATAL: RAM never cleared (last reading: ${avail}GB available, need >=6GB)." >&2
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
  local leg="$1" killpat="$2"; shift 2
  local logfile="$LOGDIR/${leg}.server.log"
  echo "=== [$leg] starting: $* ==="
  "$@" > "$logfile" 2>&1 &
  local pid=$!
  CUR_PID="$pid"; CUR_KILLPAT="$killpat"
  if ! wait_ready "$pid"; then
    echo "=== [$leg] FAILED to become ready ==="
    tail -30 "$logfile"
    kill -9 "$pid" 2>/dev/null
    pkill -9 -f "$killpat" 2>/dev/null
    wait "$pid" 2>/dev/null
    wait_ram_clear || exit 1
    return 1
  fi
  echo "=== [$leg] ready, pid=$pid ==="

  for task in prefill prose code; do
    mt=700; [ "$task" = "prefill" ] && mt=10
    echo "=== [$leg] task=$task ==="
    out=$(python3 "$DIR/send_request.py" "$BASEURL" "$DIR/prompts/${task}.txt" "$mt" 2>&1)
    echo "$out" | tee "$LOGDIR/${leg}.${task}.json"
    pt=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('prompt_tokens') or 0)" 2>/dev/null || echo 0)
    ct=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('completion_tokens') or 0)" 2>/dev/null || echo 0)
    ws=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('wall_s') or 0)" 2>/dev/null || echo 0)
    cp=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print((d.get('content_preview') or '').replace(chr(10),' ').replace(',',';'))" 2>/dev/null || echo "")
    prefill_tps=$(python3 -c "print(round($pt/$ws,2) if $ws>0 else 0)" 2>/dev/null || echo 0)
    gen_tps=$(python3 -c "print(round($ct/$ws,2) if $ws>0 else 0)" 2>/dev/null || echo 0)
    echo "$leg,$task,$ws,$pt,$ct,$prefill_tps,$gen_tps,\"$cp\"" >> "$CSV"
  done

  echo "=== [$leg] stopping pid=$pid (and any $killpat workers) ==="
  kill "$pid" 2>/dev/null
  for _ in 1 2 3 4 5 6 7 8; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
  kill -9 "$pid" 2>/dev/null
  wait "$pid" 2>/dev/null
  pkill -9 -f "$killpat" 2>/dev/null
  CUR_PID=""; CUR_KILLPAT=""
  wait_ram_clear || exit 1
}

MODEL_XL=/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
MODEL_BARTOWSKI=/home/j/models/Qwen3.8-27B-bartowski-Q4_K_M.gguf

# fork_mtp0 retry: smaller max_context to fit under the dense path's VRAM ceiling
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate
run_leg "fork_mtp0" "tinygrad-qwen38-fork/.venv/bin/python3" \
  env DEV=AMD:LLVM MTP=0 LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --mmproj none --max_context 2560 --serve "$PORT"
deactivate 2>/dev/null

# official_dense retry: bartowski Q4_K_M instead of UD-Q4_K_XL (mainline can't load
# UD's Q3_K blocks at all -- separate, permanent limitation, not a VRAM issue)
cd /home/j/tinygrad && source .venv/bin/activate
run_leg "official_dense" "tinygrad/.venv/bin/python3" \
  env DEV=AMD LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_BARTOWSKI" --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

echo "=== RERUN COMPLETE ==="
cat "$CSV"
