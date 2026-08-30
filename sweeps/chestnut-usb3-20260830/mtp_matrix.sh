#!/usr/bin/env bash
# Localize why MTP accepts 0 drafts on the USB path.
#
# Every leg runs LLM_CACHE=0. KV_QUANT is a real knob (amd_gemv.py:1141) but is NOT in _ENV_KEYS,
# so with the cache on, toggling it would silently reuse a stale entry. Disabling the cache removes
# that confound; the other knobs (MTP_K, AMD_GEMV, AMD_CHUNK) are in the key,
# see tinygrad/llm/cache.py:_ENV_KEYS), then `--benchmark`, which prints
# "N tokens in X ms: Y tok/s (mtp accepted a/n drafts)" from cli.py:288.
#
# Reading it: a/n == 0 means every draft was rejected (the bug). Any nonzero a identifies the leg
# whose disabled feature was responsible.
set -u
cd /home/jacob/z/tinygrad

MODEL=${MODEL:-/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf}
N=${N:-200}
OUT=${OUT:-sweeps/chestnut-usb3-20260830/mtp_matrix.txt}
: > "$OUT"

run_leg() {
  local name="$1"; shift
  echo "=== $name ===" | tee -a "$OUT"
  local t0=$SECONDS
  env DEV=USB+AMD:LLVM GMMU=0 LLM_CACHE=0 PYTHONUNBUFFERED=1 "$@" \
    .venv/bin/python3 -m tinygrad.llm.cli --model "$MODEL" --mmproj none \
    --repeat-penalty 1.15 --max_context 98304 --benchmark "$N" \
    > "sweeps/chestnut-usb3-20260830/mtp-$name.log" 2>&1
  local rc=$?
  # the summary line, plus any accept trace cli.py emits at DEBUG>=1
  grep -E "tokens in .* tok/s|mtp accept" "sweeps/chestnut-usb3-20260830/mtp-$name.log" | tail -3 | tee -a "$OUT"
  echo "  (exit $rc, $((SECONDS-t0))s)" | tee -a "$OUT"
  echo | tee -a "$OUT"
}

# control: current defaults, should reproduce accept 0 through the benchmark path (not just serve)
run_leg control
# the fork's custom raw-LLVM-IR gemv/WMMA kernels off -> stock tinygrad kernels
run_leg nogemv AMD_GEMV=0
# fused chunked decode off, custom gemv still on
run_leg nochunk AMD_CHUNK=0
# shortest possible draft chain
run_leg k1 MTP_K=1
# 4-bit KV quant off (the fork's default is on; a bad KV read would break verification)
run_leg nokvquant KV_QUANT=0

echo "--- summary ---" | tee -a "$OUT"
grep -E "^===|mtp accepted|tok/s" "$OUT" | tee -a /dev/null
