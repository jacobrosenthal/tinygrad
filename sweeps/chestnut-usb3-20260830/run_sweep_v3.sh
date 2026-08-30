#!/usr/bin/env bash
# Post-Chestnut sweep run with the BASELINE'S OWN HARNESS, unmodified.
#
# Uses ~/z/llama.cpp/sweeps/newquants-20260828/send_request.py (the v3 script that produced
# pre-chestnut-baseline-20260830) and that sweep's own prompts/{prose,code}.txt, so the request
# body, sampling and response parsing are byte-identical to the "before" run. 3 trials x
# {prose, code}, 800 max_tokens, temperature 0.6 (v3's default, taken by omitting argv[5]).
#
# The v3 script itself is purely client-side. The baseline's server_prefill_tok_s /
# server_gen_tok_s / server_accept_rate came from the server's own stderr log line ("trust the
# wire"), so this runner brackets each call with the server.log offset and merges those in
# without touching the harness.
set -u
cd "$(dirname "$0")"

V3=${V3:-/home/jacob/z/llama.cpp/sweeps/newquants-20260828/send_request.py}
PROMPTS=${PROMPTS:-/home/jacob/z/llama.cpp/sweeps/newquants-20260828/prompts}
BASE_URL=${BASE_URL:-http://127.0.0.1:8080/v1}
SERVER_LOG=${SERVER_LOG:-$PWD/server.log}
MAX_TOKENS=${MAX_TOKENS:-800}
TRIALS=${TRIALS:-3}
OUT=${OUT:-results.json}

[ -f "$V3" ] || { echo "missing baseline harness: $V3" >&2; exit 1; }

echo "[" > "$OUT"
first=1
for trial in $(seq 1 "$TRIALS"); do
  for task in prose code; do
    echo "trial $trial / $task ..." >&2
    off=$(stat -c %s "$SERVER_LOG" 2>/dev/null || echo 0)
    raw=$(python3 "$V3" "$BASE_URL" "$PROMPTS/$task.txt" "$MAX_TOKENS")
    sleep 0.3  # let the server flush its stderr line
    rec=$(SERVER_LOG="$SERVER_LOG" OFF="$off" TASK="$task" TRIAL="$trial" RAW="$raw" python3 - <<'PY'
import json, os, re
raw = json.loads(os.environ['RAW'])
rec = {"trial": int(os.environ['TRIAL']), "task": os.environ['TASK']}
rec.update(raw)
try:
  with open(os.environ['SERVER_LOG'], 'rb') as f:
    f.seek(int(os.environ['OFF'])); t = re.sub(r'\x1b\[[0-9;]*m', '', f.read().decode('utf-8', 'replace'))
  if (m := re.findall(r'prefill:\s*(\d+(?:\.\d+)?)\s*tok/s', t)): rec['server_prefill_tok_s'] = float(m[-1])
  if (m := re.findall(r'gen:\s*(\d+(?:\.\d+)?)\s*tok/s', t)):     rec['server_gen_tok_s'] = float(m[-1])
  if (m := re.findall(r'accept:\s*(\d+\.\d+)', t)):               rec['server_accept_rate'] = float(m[-1])
  if (m := re.findall(r'accept:\s*\d+\.\d+\s*\(([\d.]+) tok/step\)', t)): rec['server_tok_per_step'] = float(m[-1])
except OSError: pass
rec.pop('content_preview', None)  # keep results.json diffable; full text is in the server log
print(json.dumps(rec))
PY
)
    echo "  $rec" >&2
    [ $first -eq 1 ] || echo "," >> "$OUT"
    printf '  %s' "$rec" >> "$OUT"
    first=0
  done
done
printf '\n]\n' >> "$OUT"
echo "wrote $OUT" >&2
