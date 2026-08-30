#!/usr/bin/env bash
# Post-Chestnut sweep: same shape as pre-chestnut-baseline-20260830 (3 trials x {prose, code},
# 800 max_tokens, temperature 0.6), driven against an already-running server.
#
# Start the server first (cold compile is ~9 min on a fresh LLM_CACHE key):
#   DEV=USB+AMD:LLVM GMMU=0 LLM_CACHE=1 PYTHONUNBUFFERED=1 .venv/bin/python3 -m tinygrad.llm.cli \
#     --model ~/models/Qwen3.8-27B-UD-Q4_K_XL.gguf --mmproj none --repeat-penalty 1.15 \
#     --max_context 98304 --host 127.0.0.1 --serve 8080 > sweeps/chestnut-usb3-20260830/server.log 2>&1 &
set -u
cd "$(dirname "$0")"

BASE_URL=${BASE_URL:-http://127.0.0.1:8080/v1}
SERVER_LOG=${SERVER_LOG:-$PWD/server.log}
MAX_TOKENS=${MAX_TOKENS:-800}
TRIALS=${TRIALS:-3}
OUT=${OUT:-results.json}

echo "[" > "$OUT"
first=1
for trial in $(seq 1 "$TRIALS"); do
  for task in prose code; do
    echo "trial $trial / $task ..." >&2
    rec=$(./send_request.py "$BASE_URL" "prompts/$task.txt" "$MAX_TOKENS" \
            --server-log "$SERVER_LOG" --task "$task" --trial "$trial")
    echo "  $rec" >&2
    [ $first -eq 1 ] || echo "," >> "$OUT"
    printf '  %s' "$rec" >> "$OUT"
    first=0
  done
done
printf '\n]\n' >> "$OUT"
echo "wrote $OUT" >&2
