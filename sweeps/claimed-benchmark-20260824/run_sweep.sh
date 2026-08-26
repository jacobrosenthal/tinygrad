#!/usr/bin/env bash
set -uo pipefail
# Reproduces the retweeted "prefill / prose / code" comparison as closely as we can,
# across every engine/config we care about, all on the same UD-Q4_K_XL quant, same
# port (one at a time), same prompts, same client-side measurement method:
#   - prefill leg: long prompt (~1900 words), max_tokens=10 -> wall time ~= prefill time
#   - prose/code legs: short prompt, max_tokens=700 -> wall time ~= mostly decode time
# tok/s = tokens / wall_s from each response's own `usage` field (OpenAI-compatible on
# both engines), so this works identically for llama.cpp and tinygrad without needing
# to parse either engine's stdout log format.
#
# SAFETY (2026-08-24 incident): an earlier version of this script killed only the
# tracked leader PID between legs. tinygrad's kernel-compile step spawns a
# multiprocessing.Pool of worker processes that do NOT reliably die with a SIGKILL
# of their parent -- they leaked across legs, stacked up on this box's 13GB of RAM,
# and eventually wedged the AMDGPU driver's own memory-eviction path badly enough
# to hang the whole machine (kernel hung-task trace in amdgpu_cs_bo_validate ->
# ttm_bo_evict -> try_to_free_pages; ~15 min of "under memory pressure" journald
# spam; SSH dropped; required a hard REISUB reboot to recover). Every run_leg now
# (a) kills by pattern, catching worker children, not just the one PID, and
# (b) hard-aborts the whole sweep if system RAM doesn't actually clear between legs,
# rather than warning and barreling ahead into the same failure mode.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$DIR/results.csv"
LOGDIR="$DIR/logs"
PORT=8099
BASEURL="http://127.0.0.1:$PORT/v1"
mkdir -p "$LOGDIR"
[ -f "$CSV" ] || echo "leg,task,wall_s,prompt_tokens,completion_tokens,prefill_tok_s,gen_tok_s,content_preview" > "$CSV"

# cap the kernel-compile worker pool -- 12 cores on a 13GB box is too tight to let
# tinygrad default to NUM_CPU_THREADS workers during comgr/LLVM compilation.
export PARALLEL=4

wait_ready() {
  local pid="$1"
  for _ in $(seq 1 360); do
    curl -sf "$BASEURL/models" >/dev/null 2>&1 && return 0
    # bail immediately if the server process already died instead of polling
    # the full 30 minutes for a corpse (observed: a real crash inside the
    # process took the full timeout to notice)
    kill -0 "$pid" 2>/dev/null || { echo "process $pid died during warmup"; return 1; }
    sleep 5
  done
  return 1
}

ram_available_gb() {
  free -m | awk '/^Mem:/{printf "%.2f", $7/1024}'
}

wait_ram_clear() {
  # require at least 6GB available (of 13GB total) before starting the next leg's
  # model load -- this is the check that was missing during the 2026-08-24 incident.
  for _ in $(seq 1 60); do
    avail=$(ram_available_gb)
    awk -v a="$avail" 'BEGIN{exit !(a>=6)}' && { echo "RAM clear: ${avail}GB available"; return 0; }
    sleep 3
  done
  echo "FATAL: RAM never cleared (last reading: ${avail}GB available, need >=6GB)." >&2
  echo "Aborting the sweep rather than repeat the 2026-08-24 OOM/hang incident." >&2
  return 1
}

CUR_PID=""
CUR_KILLPAT=""
cleanup_on_interrupt() {
  echo "=== interrupted, cleaning up current leg (pid=$CUR_PID pattern=$CUR_KILLPAT) ==="
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
  pkill -9 -f "$killpat" 2>/dev/null   # catches multiprocessing.spawn/resource_tracker children the SIGKILL above missed
  CUR_PID=""; CUR_KILLPAT=""
  wait_ram_clear || exit 1
}

MODEL_XL=/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf

# leg 1: Splizard fork, MTP=1
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate
run_leg "fork_mtp1" "tinygrad-qwen38-fork/.venv/bin/python3" \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"

# leg 2: Splizard fork, MTP=0 (isolate the MTP effect on identical code/quant)
run_leg "fork_mtp0" "tinygrad-qwen38-fork/.venv/bin/python3" \
  env DEV=AMD:LLVM MTP=0 LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"

# leg 3: official tinygrad PR track, dense only (no MTP exists there yet)
deactivate 2>/dev/null
cd /home/j/tinygrad && source .venv/bin/activate
run_leg "official_dense" "tinygrad/.venv/bin/python3" \
  env DEV=AMD LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

# leg 4: llama.cpp, Vulkan RADV, MTP n=3, q8 KV (matches the retweet's stated llama.cpp config exactly)
# -- llama-server is a single C++ binary, no python multiprocessing children to worry about.
cd /home/j/llama.cpp
run_leg "llamacpp_mtp3_q8kv" "build/bin/llama-server" \
  ./build/bin/llama-server \
  -m "$MODEL_XL" --host 127.0.0.1 --port "$PORT" \
  --device Vulkan1 -sm none --load-mode none \
  -c 4096 -ngl all -fa on -b 2048 -ub 512 \
  --cache-type-k q8_0 --cache-type-v q8_0 \
  --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 \
  --parallel 1

# leg 5: llama.cpp, our own standard config (q4 KV, matches llama-server.service) -- extra
# data point beyond the retweet's own comparison, same quant file for parity with the rest
run_leg "llamacpp_mtp3_q4kv" "build/bin/llama-server" \
  ./build/bin/llama-server \
  -m "$MODEL_XL" --host 127.0.0.1 --port "$PORT" \
  --device Vulkan1 -sm none --load-mode none \
  -c 4096 -ngl all -fa on -b 2048 -ub 512 \
  --cache-type-k q4_0 --cache-type-v q4_0 \
  --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 \
  --parallel 1

echo "=== SWEEP COMPLETE ==="
cat "$CSV"
