#!/usr/bin/env bash
set -uo pipefail
# KV-cache-quant comparison on the Splizard fork: current default (KV_KBITS=4 KV_VBITS=4
# KV_QJL=1, ~6.8x smaller than f32 per the code's own docstring) vs KV_QUANT=0 (full f32).
# max_context=4096 deliberately small: byte math from amd_gemv.py's KVQuant class predicts
# f32 KV at the production 65536 context would push total VRAM past this 24GB card (the
# 2026-08-24 OOM/hang incident is exactly the failure mode we're avoiding by not testing that).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$DIR/results_tinygrad.csv"
LOGDIR="$DIR/logs"
PORT=8099
BASEURL="http://127.0.0.1:$PORT/v1"
MODEL=/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
mkdir -p "$LOGDIR"
[ -f "$CSV" ] || echo "leg,task,wall_s,prompt_tokens,completion_tokens,prefill_tok_s,gen_tok_s,vram_gb" > "$CSV"
export PARALLEL=4

vram_gb() { cat /sys/bus/pci/devices/0000:03:00.0/mem_info_vram_used | awk '{printf "%.2f", $1/1024/1024/1024}'; }
ram_available_gb() { free -m | awk '/^Mem:/{printf "%.2f", $7/1024}'; }
wait_ram_clear() {
  for _ in $(seq 1 60); do
    avail=$(ram_available_gb)
    awk -v a="$avail" 'BEGIN{exit !(a>=6)}' && { echo "RAM clear: ${avail}GB"; return 0; }
    sleep 3
  done
  echo "FATAL: RAM never cleared (${avail}GB avail)" >&2; return 1
}

wait_ready() {
  local pid="$1"
  for _ in $(seq 1 240); do
    curl -sf "$BASEURL/models" >/dev/null 2>&1 && return 0
    kill -0 "$pid" 2>/dev/null || { echo "process $pid died during warmup"; return 1; }
    sleep 5
  done
  return 1
}

CUR_PID=""; CUR_KILLPAT="tinygrad-qwen38-fork/.venv/bin/python3"
cleanup_on_interrupt() {
  [ -n "$CUR_PID" ] && kill -9 "$CUR_PID" 2>/dev/null
  pkill -9 -f "$CUR_KILLPAT" 2>/dev/null
  exit 130
}
trap cleanup_on_interrupt INT TERM

run_leg() {
  local leg="$1"; shift
  local logfile="$LOGDIR/${leg}.server.log"
  echo "=== [$leg] starting: $* ==="
  "$@" > "$logfile" 2>&1 &
  local pid=$!
  CUR_PID="$pid"
  if ! wait_ready "$pid"; then
    echo "=== [$leg] FAILED to become ready ==="; tail -40 "$logfile"
    kill -9 "$pid" 2>/dev/null; pkill -9 -f "$CUR_KILLPAT" 2>/dev/null; wait "$pid" 2>/dev/null
    wait_ram_clear || exit 1
    return 1
  fi
  echo "=== [$leg] ready, pid=$pid, vram=$(vram_gb)GB ==="
  for task in prefill prose; do
    mt=10; [ "$task" = "prose" ] && mt=400
    out=$(python3 "$DIR/send_request.py" "$BASEURL" "$DIR/${task}.txt" "$mt" 2>&1)
    echo "[$leg/$task] $out"
    pt=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('prompt_tokens') or 0)" 2>/dev/null || echo 0)
    ct=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('completion_tokens') or 0)" 2>/dev/null || echo 0)
    ws=$(echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('wall_s') or 0)" 2>/dev/null || echo 0)
    prefill_tps=$(python3 -c "print(round($pt/$ws,2) if $ws>0 else 0)" 2>/dev/null || echo 0)
    gen_tps=$(python3 -c "print(round($ct/$ws,2) if $ws>0 else 0)" 2>/dev/null || echo 0)
    echo "$leg,$task,$ws,$pt,$ct,$prefill_tps,$gen_tps,$(vram_gb)" >> "$CSV"
  done
  kill "$pid" 2>/dev/null
  for _ in 1 2 3 4 5 6 7 8; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
  kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  pkill -9 -f "$CUR_KILLPAT" 2>/dev/null
  CUR_PID=""
  wait_ram_clear || exit 1
}

cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate

run_leg "default_k4v4qjl" env DEV=AMD:LLVM LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL" --mmproj none --max_context 4096 --serve "$PORT"

run_leg "f32_nokvquant" env DEV=AMD:LLVM LLM_CACHE=0 KV_QUANT=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL" --mmproj none --max_context 4096 --serve "$PORT"

echo "=== DONE ==="; cat "$CSV"
