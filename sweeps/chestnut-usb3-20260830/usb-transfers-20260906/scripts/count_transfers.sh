#!/bin/bash
exec 9>/tmp/chestnut-sweep.lock; flock -n 9 || { echo "another sweep holds /tmp/chestnut-sweep.lock; refusing to run concurrently"; exit 1; }
# Count USB transfers per decode step. The hcq2 runtime issues libusb calls from compiled programs (usb_stream/usb_bulk UOps call
# libusb_control_transfer / libusb_bulk_transfer through function pointers), so a Python-level wrapper cannot see them; libusb's own
# debug log can: LIBUSB_DEBUG=4 makes libusb print one "libusb_submit_transfer" line per transfer to stderr (sync transfers go through
# submit too). The server's per-request "gen:" line lands in the same stderr, so usb_count.py splits the log per request and divides by
# the step count (out tokens / tok-per-step). Logging slows the server (that is fine: we want counts, not tok/s here).
#   REQS=4 bash count_transfers.sh                     # MTP K=3 (production config), 4 long prompts
N=${REQS:-4}
TOP=/home/jacob/z/tinygrad; PY=$TOP/.venv/bin/python3; TREE=${TREE:-$TOP}
LOGD=$TOP/sweeps/chestnut-usb3-20260830/usb-transfers-20260906/logs; mkdir -p "$LOGD"
MODEL=/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf
LOG="$LOGD/$(date +%Y%m%d-%H%M%S)-usbdebug-${CFG:-mtp-k3}.log"
killsrv(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 "$p" 2>/dev/null; done; }
P=("Write a Python merge sort with comments and complexity analysis, then explain stability."
   "Implement quicksort, binary search, BFS and DFS in Python with detailed comments."
   "Explain and implement a red-black tree insertion in Python, step by step."
   "Write a long Python tutorial on dynamic programming with three worked examples.")
killsrv; sleep 3; rm -f /tmp/am_usb:*.lock; cd /
env ${EXTRA:-MTP_K=3} PYTHONPATH=$TREE LIBUSB_DEBUG=4 LLM_CACHE=1 DEV=USB+AMD:LLVM MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 \
  "$PY" -m tinygrad.llm.cli --model "$MODEL" --mmproj none --repeat-penalty 1.15 --max_context 8192 --host 127.0.0.1 --serve 8082 >> "$LOG" 2>&1 &
srv=$!; t0=$(date +%s); ok=0
while [ $(( $(date +%s)-t0 )) -lt 1500 ]; do curl -s -m3 localhost:8082/v1/models 2>/dev/null | grep -q "\"object\"\|\"data\"" && { ok=1; break; }; kill -0 $srv 2>/dev/null || break; sleep 10; done
[ "$ok" = 0 ] && { echo "server did not come up (see $LOG)"; killsrv; exit 1; }
echo "=== REQUESTS START $(date +%T)" >> "$LOG"
for i in $(seq 0 $((N-1))); do
  curl -s -m600 http://127.0.0.1:8082/v1/chat/completions -H 'Content-Type: application/json' \
    -d "{\"model\":\"m\",\"messages\":[{\"role\":\"user\",\"content\":\"${P[$((i % 4))]}\"}],\"max_tokens\":300,\"temperature\":0}" >/dev/null 2>&1
  echo "=== REQUEST $i DONE $(date +%T)" >> "$LOG"
done
killsrv
"$PY" "$TOP/sweeps/chestnut-usb3-20260830/usb-transfers-20260906/scripts/usb_count.py" "$LOG" | tee "$LOG.summary.txt"
