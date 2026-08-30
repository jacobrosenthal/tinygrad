#!/usr/bin/env bash
# Isolate whether LLM_CACHE or DEBUG is what makes serve's MTP accept rate collapse to 0.00.
#
# Observed so far:
#   LLM_CACHE=1 DEBUG=0 -> accept 0.00, 26 tok/s   (every sweep run)
#   LLM_CACHE=0 DEBUG=1 -> accept 0.45, 53 tok/s   (matches the OCuLink baseline)
# This fills in the other two cells of the 2x2.
set -u
cd /home/jacob/z/tinygrad
SEND=/home/jacob/z/llama.cpp/sweeps/newquants-20260828/send_request.py
PROMPT=sweeps/chestnut-usb3-20260830/prompts/prose.txt
OUT=sweeps/chestnut-usb3-20260830/isolate_cache.txt
: > "$OUT"

stop_servers() {  # kill by pid, never pkill -f: the pattern would match this script's own cmdline
  for pid in $(pgrep -f 'llm[.]cli --model' 2>/dev/null); do
    [ "$pid" = "$$" ] && continue
    kill "$pid" 2>/dev/null
  done
  sleep 8
}

run_cfg() {
  local name=$1 cache=$2 dbg=$3
  local L=sweeps/chestnut-usb3-20260830/srv-$name.log
  stop_servers
  env DEV=USB+AMD:LLVM GMMU=0 LLM_CACHE=$cache DEBUG=$dbg PYTHONUNBUFFERED=1 .venv/bin/python3 -m tinygrad.llm.cli \
    --model /home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf --mmproj none --repeat-penalty 1.15 \
    --max_context 98304 --host 127.0.0.1 --serve 8080 > "$L" 2>&1 &
  local pid=$!
  for i in $(seq 1 150); do
    r=$(python3 "$SEND" http://127.0.0.1:8080/v1 "$PROMPT" 8 2>&1)
    case "$r" in *'"error"'*) sleep 10;; *) break;; esac
  done
  local out; out=$(python3 "$SEND" http://127.0.0.1:8080/v1 "$PROMPT" 400)
  {
    echo "=== LLM_CACHE=$cache DEBUG=$dbg ==="
    echo "  client: $(echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("%.2fs, %d tok -> %.1f tok/s" % (d["wall_s"], d["completion_tokens"], d["completion_tokens"]/d["wall_s"]))' 2>/dev/null || echo "$out")"
    echo "  server: $(grep -aoE 'accept:[ ]*[0-9.]+ \([0-9.]+ tok/step\)' "$L" | tail -1)"
    echo "  cache:  $(grep -aiE 'llm cache|cache (hit|miss|load|sav)' "$L" | tail -2 | tr '\n' ' ')"
  } | tee -a "$OUT"
  kill $pid 2>/dev/null
  sleep 8
}

run_cfg cache1dbg1 1 1
run_cfg cache0dbg0 0 0
stop_servers
echo "--- summary ---"; cat "$OUT"
