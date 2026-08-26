#!/usr/bin/env bash
set -uo pipefail
# Sampling-settings sweep: does bumping temperature to Qwen's published thinking-mode
# recommendation (temp=1.0, top_p=0.95, top_k=20) change speed/output vs our old defaults
# (temp=0.6, no top_p/top_k)? tinygrad's fork only supports the temperature axis (top_p/top_k
# aren't implemented in its JIT-compiled sampling kernels -- see model.py _sample/_sample_rows),
# llama.cpp supports the full profile.
#
# Reuses the run_leg/wait_ready/wait_ram_clear pattern from ../claimed-benchmark-20260824/run_sweep.sh,
# including its safety fix: tinygrad's kernel-compile multiprocessing.Pool workers don't reliably die
# with a SIGKILL of the parent, so every leg kills by pattern and hard-aborts if RAM doesn't clear
# between legs (see that script's 2026-08-24 incident note).
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
  echo "FATAL: RAM never cleared (last: ${avail}GB, need >=6GB). Aborting rather than risk the 2026-08-24 hang." >&2
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

  for task in prefill prose code; do
    mt=700; [ "$task" = "prefill" ] && mt=10
    echo "=== [$leg] task=$task ==="
    out=$(python3 "$DIR/send_request.py" "$BASEURL" "$DIR/prompts/${task}.txt" "$mt" "$temp" "$top_p" "$top_k" 2>&1)
    echo "$out" | tee "$LOGDIR/${leg}.${task}.json"
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

# legs 1-3: splizard fork. top_p/top_k are server-fixed env vars now (see model.py _apply_top_pk,
# added 2026-08-25) -- legs 1-2 stay temp-only for a clean before/after, leg 3 is the first real
# test of top_p/top_k support at all, matching Qwen's recommended thinking-mode profile.
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate
run_leg "fork_temp06" "tinygrad-qwen38-fork/.venv/bin/python3" 0.6 1.0 0 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"

run_leg "fork_temp10" "tinygrad-qwen38-fork/.venv/bin/python3" 1.0 1.0 0 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"

run_leg "fork_qwen_recommended" "tinygrad-qwen38-fork/.venv/bin/python3" 1.0 0.95 20 \
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=0 python3 -m tinygrad.llm.cli --top-p 0.95 --top-k 20 \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

# legs 4-5: plain tinygrad (no MTP fork). CONFIRMED (2026-08-25, live reproduction, not just the
# service-file comment) that this loader cannot handle the UD-quant file: ValueError: GGML type
# '11' is not supported! -- an earlier attempt in this same session to "correct" that comment based
# on an old log was itself wrong (the old log's success doesn't reproduce today). Using the regular
# (non-abliterated) plain Q4_0 quant instead -- basic GGML type, not a mixed-type Dynamic quant.
MODEL_REG=/home/j/models/Qwen3.8-27B-Q4_0.gguf
cd /home/j/tinygrad && source .venv/bin/activate
run_leg "plain_temp10" "tinygrad/.venv/bin/python3" 1.0 1.0 0 \
  env DEV=AMD LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_REG" --max_context 4096 --serve "$PORT"

run_leg "plain_qwen_recommended" "tinygrad/.venv/bin/python3" 1.0 0.95 20 \
  env DEV=AMD LLM_CACHE=0 python3 -m tinygrad.llm.cli --top-p 0.95 --top-k 20 \
  --model "$MODEL_REG" --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

# legs 6-7: llama.cpp, full sampling profile (old-style baseline vs Qwen's recommended thinking-mode)
cd /home/j/llama.cpp
run_leg "llamacpp_old_defaults" "build/bin/llama-server" 0.6 1.0 0 \
  ./build/bin/llama-server \
  -m "$MODEL_XL" --host 127.0.0.1 --port "$PORT" \
  --device Vulkan1 -sm none --load-mode none \
  -c 4096 -ngl all -fa on -b 2048 -ub 512 \
  --cache-type-k q4_0 --cache-type-v q4_0 \
  --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 \
  --parallel 1

run_leg "llamacpp_qwen_recommended" "build/bin/llama-server" 1.0 0.95 20 \
  ./build/bin/llama-server \
  -m "$MODEL_XL" --host 127.0.0.1 --port "$PORT" \
  --device Vulkan1 -sm none --load-mode none \
  -c 4096 -ngl all -fa on -b 2048 -ub 512 \
  --cache-type-k q4_0 --cache-type-v q4_0 \
  --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 \
  --parallel 1

# leg 8 (last): re-run fork_mtp0 (Splizard fork, MTP off) -- claimed-benchmark-20260824 never got
# a real result for this leg, it OOM'd (MemoryError: Allocation of 10.00 MB failed on AMD. Used:
# 23.86 GB) even though that script already had the leaked-worker pkill fix. Same temp/top_p/top_k
# as fork_temp10 (MTP on) above, so this is a clean MTP on/off comparison, not a sampling test.
# Placed last deliberately: if it OOMs again, it doesn't take any other leg down with it.
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate
run_leg "fork_mtp0" "tinygrad-qwen38-fork/.venv/bin/python3" 1.0 1.0 0 \
  env DEV=AMD:LLVM MTP=0 LLM_CACHE=0 python3 -m tinygrad.llm.cli \
  --model "$MODEL_XL" --mmproj none --max_context 4096 --serve "$PORT"
deactivate 2>/dev/null

echo "=== SWEEP COMPLETE ==="
cat "$CSV"
