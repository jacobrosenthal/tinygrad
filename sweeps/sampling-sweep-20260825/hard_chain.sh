#!/usr/bin/env bash
# Hard-set quality probe: llama.cpp (3 arms) then the Splizard fork (2 unfiltered arms + qwen_rec).
# A script file on purpose: the previous inline `bash -c` chain was killed by another job's
# `pkill -f "[l]lama-server -m"` because its own argv contained that string. Kills by PID only.
set -uo pipefail
D=/home/j/tinygrad-qwen38-fork/sweeps/sampling-sweep-20260825
cd /home/j/llama.cpp && ./build/bin/llama-server -m /home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf --host 127.0.0.1 --port 8099 \
  --device Vulkan1 -sm none --load-mode none -c 16384 -ngl all -fa on -b 2048 -ub 512 --cache-type-k q4_0 --cache-type-v q4_0 \
  --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.0 --parallel 1 > $D/logs/quality_hard_llama.server.log 2>&1 &
LP=$!
for _ in $(seq 1 100); do curl -sf http://127.0.0.1:8099/health >/dev/null 2>&1 && break; kill -0 $LP 2>/dev/null || { echo "llama-server died"; exit 1; }; sleep 3; done
cd $D
for arm in greedy old_default qwen_rec; do echo "=== llama HARD arm=$arm ==="; PROBE_SET=hard python3 quality_probe.py http://127.0.0.1:8099/v1 $arm 12288; done
echo "=== LLAMA HARD DONE ==="
kill $LP; sleep 8; kill -9 $LP 2>/dev/null; sleep 3
PROBE_SET=hard ARMS_NOFILTER="greedy old_default" MAXTOK=12288 bash quality_tiny.sh
echo "=== ALL HARD DONE ==="
