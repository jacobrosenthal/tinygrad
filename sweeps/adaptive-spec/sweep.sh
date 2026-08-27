#!/usr/bin/env bash
# Adaptive-spec MEASUREMENT sweep (decides whether/how to build adaptive-K).
#
# Measures decode tok/s + draft acceptance for the 27B at several MTP_K / MAX_T,
# on a CODE prompt (expected high acceptance) and a PROSE prompt (expected lower)
# -- the spread between them is exactly what an adaptive controller would exploit.
#
# Reads the answer that gates the design:
#   * acceptance ~90%+ at K=3  -> K is UNDER-drafting; the win is HIGHER K
#     (the MAX_T=12/16 rows test whether the fused kernel is even stable there).
#   * acceptance splits by content (code high / prose low) -> adaptive DOWN on
#     hard content saves wasted draft compute (a safe win inside K<=3).
#
# RUN IN A FREE GPU WINDOW -- it loads the full 27B per config, so the production
# server must be stopped first (24GB won't hold two):
#   sudo systemctl stop tinygrad-server-splizard
#   bash sweeps/adaptive-spec/sweep.sh
#   sudo systemctl start tinygrad-server-splizard
set -u
FORK=/home/j/tinygrad-qwen38-fork
PY=$FORK/.venv/bin/python3
MODEL=${MODEL:-/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf}
BENCH=/home/j/rocm-bench/bench.py
PORT=8091
LOG=/tmp/spec-sweep; mkdir -p "$LOG"
GEN=${GEN:-400}   # tokens to generate per bench

CODE='Write a Rust function `parse_iso8601(s: &str) -> Option<(i32,u8,u8,u8,u8,u8)>` that parses a timestamp like 2026-08-27T14:03:59Z into (year,month,day,hour,min,sec) with no external crates. Include 3 unit tests.'
PROSE='Explain, in three short paragraphs, the practical tradeoffs between optimism and pessimism as default life strategies, with a concrete example of each.'

# each: "MTP MTP_K MAX_T label"   (MTP=0 disables spec decode = bare baseline)
CONFIGS=(
  # bare-no-spec (MTP=0) dropped: it OOM'd at 98304 (full-precision KV) and was only needed as the
  # tok/step denominator, which the serve.py acceptance patch now reports directly per config.
  "1 1 8  K1"
  "1 2 8  K2"
  "1 3 8  K3-default"
  "1 5 12 K5-exp"
  "1 7 16 K7-exp"
)

bench_tps() {  # $1 base_url  $2 prompt  -> per-stream tok/s (blank on fail)
  $PY "$BENCH" --base-url "$1" --model m --concurrency 1 --max-tokens "$GEN" \
      --temperature 0 --prompt "$2" 2>/dev/null | awk '$1==1 && $2==1 {print $5}'
}

kill_server() {  # $1 pid -- SIGTERM, then SIGKILL after a 5s grace, then reap
  kill "$1" 2>/dev/null; for _ in 1 2 3 4 5; do kill -0 "$1" 2>/dev/null || break; sleep 1; done
  kill -9 "$1" 2>/dev/null; wait "$1" 2>/dev/null
}
free_gpu() {  # DEV=AMD:LLVM grabs the PCI device directly; release is async after kill, so a fixed
              # sleep races ("Device or resource busy" / "AMD:0 does not exist"). Poll until actually free.
  local i vram busy
  for i in $(seq 1 45); do
    busy=0
    ss -ltn 2>/dev/null | grep -qE ":$PORT " && busy=1
    pgrep -f 'tinygrad\.llm\.cli' >/dev/null 2>&1 && busy=1
    vram=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -1); [ -z "$vram" ] && vram=0
    # +5s settle: the process is gone but the LLM_CACHE flock on cache.db releases a beat later;
    # launching immediately raced it (BlockingIOError Errno 11) and killed K3/K5/K7 last run.
    if [ "$busy" = 0 ] && [ "$vram" -lt 1000000000 ]; then sleep 5; return 0; fi
    sleep 1
  done
  echo "  (warn: gpu still busy after 45s: vram=$vram busy=$busy)" >&2
}

printf "%-14s %10s %10s %10s %12s\n" "config" "code_tps" "prose_tps" "accept" "tok/step"
printf '%.0s-' {1..62}; echo
free_gpu  # clear any stray server before starting
for cfg in "${CONFIGS[@]}"; do
  read -r mtp k mt label <<<"$cfg"
  slog="$LOG/$label.log"
  # DEV=AMD:LLVM (working LLVM backend; bare AMD backend fails to compile) + LLM_CACHE=1, and
  # max_context 98304 to match production's cached kernel shapes (8192 forces a full fresh recompile).
  MTP=$mtp MTP_K=$k MAX_T=$mt DEBUG=1 DEV=AMD:LLVM LLM_CACHE=1 "$PY" -m tinygrad.llm.cli \
      --model "$MODEL" --mmproj none --max_context 98304 \
      --host 127.0.0.1 --serve $PORT >"$slog" 2>&1 &
  pid=$!
  # wait until loaded + API answers. 720s: configs with MAX_T!=8 / MTP_K!=production compile fresh spec kernels.
  ready=""
  for _ in $(seq 1 240); do
    curl -s "http://127.0.0.1:$PORT/v1/models" >/dev/null 2>&1 && { ready=1; break; }
    kill -0 $pid 2>/dev/null || break   # server died during load
    sleep 3
  done
  if [ -z "$ready" ]; then
    printf "%-14s %10s %10s %10s %12s\n" "$label" "LOADFAIL" "-" "-" "-"
    kill_server $pid; free_gpu; continue
  fi
  ct=$(bench_tps "http://127.0.0.1:$PORT" "$CODE")
  pt=$(bench_tps "http://127.0.0.1:$PORT" "$PROSE")
  # serve.py log_stats (patched) prints per request:  accept: 0.NN (X.XX tok/step)
  acc=$(grep -oE 'accept:[ ]*[0-9.]+' "$slog" | tail -1 | grep -oE '[0-9.]+$')
  tps=$(grep -oE '\([0-9.]+ tok/step\)' "$slog" | tail -1 | grep -oE '[0-9.]+')
  kill_server $pid
  printf "%-14s %10s %10s %10s %12s\n" "$label" "${ct:-FAIL}" "${pt:-FAIL}" "${acc:-n/a}" "${tps:-n/a}"
  free_gpu
done
echo
echo "logs per config: $LOG/<label>.log   (grep 'mtp accept' for the full acceptance trace)"
echo "reminder: restart production ->  sudo systemctl start tinygrad-server-splizard"
