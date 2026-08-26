#!/usr/bin/env bash
set -uo pipefail
# KV-cache-quant comparison on llama.cpp: q4_0 (current production config) vs q8_0 vs f16,
# same model/quant/prompts/MTP config throughout -- only --cache-type-k/v changes.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$DIR/results_llamacpp.csv"
LOGDIR="$DIR/logs"
PORT=8099
BASEURL="http://127.0.0.1:$PORT/v1"
MODEL=/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
mkdir -p "$LOGDIR"
[ -f "$CSV" ] || echo "leg,task,wall_s,prompt_tokens,completion_tokens,prefill_tok_s,gen_tok_s,vram_gb" > "$CSV"

vram_gb() { cat /sys/bus/pci/devices/0000:03:00.0/mem_info_vram_used | awk '{printf "%.2f", $1/1024/1024/1024}'; }

wait_ready() {
  local pid="$1"
  for _ in $(seq 1 120); do
    curl -sf "$BASEURL/models" >/dev/null 2>&1 && return 0
    kill -0 "$pid" 2>/dev/null || { echo "process $pid died during warmup"; return 1; }
    sleep 2
  done
  return 1
}

run_leg() {
  local leg="$1"; shift
  local logfile="$LOGDIR/${leg}.server.log"
  echo "=== [$leg] starting ==="
  "$@" > "$logfile" 2>&1 &
  local pid=$!
  if ! wait_ready "$pid"; then
    echo "=== [$leg] FAILED to become ready ==="; tail -30 "$logfile"
    kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; return 1
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
  sleep 3
}

run_leg "q4_0" ./build/bin/llama-server -m "$MODEL" --host 127.0.0.1 --port "$PORT" \
  --device Vulkan1 -sm none --load-mode none -c 65536 -ngl all -fa on -b 2048 -ub 512 \
  --cache-type-k q4_0 --cache-type-v q4_0 --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 --parallel 1

run_leg "q8_0" ./build/bin/llama-server -m "$MODEL" --host 127.0.0.1 --port "$PORT" \
  --device Vulkan1 -sm none --load-mode none -c 65536 -ngl all -fa on -b 2048 -ub 512 \
  --cache-type-k q8_0 --cache-type-v q8_0 --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 --parallel 1

run_leg "f16" ./build/bin/llama-server -m "$MODEL" --host 127.0.0.1 --port "$PORT" \
  --device Vulkan1 -sm none --load-mode none -c 65536 -ngl all -fa on -b 2048 -ub 512 \
  --cache-type-k f16 --cache-type-v f16 --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 --parallel 1

echo "=== DONE ==="; cat "$CSV"
