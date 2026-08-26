#!/usr/bin/env bash
set -uo pipefail
# Redo of tiny_greedy/tiny_old_default (hard set), after discovering the first attempt was silently
# served by a leftover llama-server that hard_chain.sh failed to kill (port 8099 was already
# occupied, so the readiness check found llama-server answering and never actually waited for
# tinygrad). Fix: verify the PID that owns port 8099 is the PID we just launched, not just that
# something answers there.
D=/home/j/tinygrad-qwen38-fork/sweeps/sampling-sweep-20260825
PORT=8099; URL=http://127.0.0.1:$PORT/v1
cd /home/j/tinygrad-qwen38-fork && source .venv/bin/activate

start() {
  env DEV=AMD:LLVM MTP=1 LLM_CACHE=1 PYTHONUNBUFFERED=1 python3 -m tinygrad.llm.cli --model /home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf \
    --mmproj none --max_context 16384 --serve $PORT > $D/logs/quality_tiny_redo_nofilter.server.log 2>&1 &
  PID=$!
  for _ in $(seq 1 360); do
    owner=$(ss -tlnp 2>/dev/null | awk -v p=":$PORT" '$4 ~ p {print $NF}' | grep -o 'pid=[0-9]*' | cut -d= -f2)
    if [ "$owner" = "$PID" ] && curl -sf $URL/models >/dev/null 2>&1; then return 0; fi
    kill -0 $PID 2>/dev/null || { echo "server died (pid=$PID)"; tail -15 $D/logs/quality_tiny_redo_nofilter.server.log; return 1; }
    sleep 5
  done
  echo "server not ready after 30min (pid=$PID, port owner=$owner)"; return 1
}
stop() { kill $PID 2>/dev/null; sleep 6; kill -9 $PID 2>/dev/null; pkill -9 -f "[t]inygrad.llm.cli"; sleep 4; }

start || exit 1
for arm in greedy old_default; do echo "=== tiny arm=$arm ==="; PROBE_SET=hard python3 $D/quality_probe.py $URL $arm 12288 tiny_; done
stop
echo "=== REDO COMPLETE ==="
