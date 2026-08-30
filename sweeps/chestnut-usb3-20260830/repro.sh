#!/usr/bin/env bash
# Try to reproduce accept=0.00 in the exact config the sweeps used: LLM_CACHE=1, DEBUG=0, 800 max_tokens.
set -u
cd /home/jacob/z/tinygrad
L=sweeps/chestnut-usb3-20260830/srv-repro.log
for pid in $(pgrep -f 'llm[.]cli --model'); do kill $pid 2>/dev/null; done; sleep 8
env DEV=USB+AMD:LLVM GMMU=0 LLM_CACHE=1 PYTHONUNBUFFERED=1 .venv/bin/python3 -m tinygrad.llm.cli \
  --model /home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf --mmproj none --repeat-penalty 1.15 \
  --max_context 98304 --host 127.0.0.1 --serve 8080 > $L 2>&1 &
SRV=$!
SEND=/home/jacob/z/llama.cpp/sweeps/newquants-20260828/send_request.py
for i in $(seq 1 150); do
  r=$(python3 $SEND http://127.0.0.1:8080/v1 sweeps/chestnut-usb3-20260830/prompts/prose.txt 8 2>&1)
  case "$r" in *'"error"'*) sleep 10;; *) break;; esac
done
grep -aiE "llm cache" $L | head -2
cd sweeps/chestnut-usb3-20260830
OUT=results-repro.json ./run_sweep_v3.sh 2>&1 | tail -8
echo "--- accept lines ---"
grep -aoE 'accept:[ ]*[0-9.]+ \([0-9.]+ tok/step\)' srv-repro.log | tail -7
kill $SRV 2>/dev/null
