#!/bin/bash
# Decode tok/s vs prompt length on KFD with the production candidate (112K context, MTP K=3, MTP_DRAFT_VOCAB=65536, penalty 1.0).
# Prompts: a paragraph repeated to ~N tokens (the server log's "in: 0 + N" gives the real count), 300 output tokens, greedy.
exec 9>/tmp/chestnut-sweep.lock; flock -n 9 || { echo "sweep lock held"; exit 1; }
TOP=/home/jacob/z/tinygrad; K=$TOP/sweeps/chestnut-usb3-20260830/usb4-kfd-20260906; L=$K/logs/$(date +%Y%m%d-%H%M%S)-longctx.log; SUM=$K/logs/$(date +%Y%m%d-%H%M%S)-longctx-summary.txt
killsrv(){ for p in $(ls /proc|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q tinygrad.llm.cli && kill -9 $p; done; }
killsrv; sleep 2
(cd / && env ${PYTHONPATH:+PYTHONPATH=$PYTHONPATH} ${ATTN_LW:+ATTN_LW=$ATTN_LW} MTP_K=3 MTP_DRAFT_VOCAB=65536 DEV=KFD+AMD:LLVM LLM_CACHE=${LLM_CACHE:-1} MAX_T=12 ATTN_QT=${ATTN_QT:-8} NGRAM_DRAFT=0 PYTHONUNBUFFERED=1 $TOP/.venv/bin/python3 -m tinygrad.llm.cli --model /home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf --mmproj none --repeat-penalty 1.0 --max_context 114688 --host 127.0.0.1 --serve 8082 >> $L 2>&1 &)
t0=$(date +%s); until curl -s -m3 localhost:8082/v1/models 2>/dev/null | grep -q '"object"\|"data"'; do sleep 10; [ $(( $(date +%s)-t0 )) -gt 1500 ] && { echo "server did not come up" | tee -a $SUM; killsrv; exit 1; }; done
echo "longctx $(date +%T): ATTN_QT=${ATTN_QT:-8} CH=${AMD_ATTN_MQ_CH:-256} server up in $(( $(date +%s)-t0 ))s" | tee -a $SUM
PARA="The lighthouse keeper climbed the spiral stairs every evening at dusk, counting the one hundred and twelve steps as he had for thirty years, and lit the great lamp whose beam swept the dark water for the fishing boats returning from the banks. "
for words in ${LONGCTX_WORDS:-20 1500 6000 24000 48000 90000}; do
  n=$(( (words + 40) / 41 )); prompt=""; for i in $(seq 1 $n); do prompt+="$PARA"; done
  prompt+="Summarize the story above in three sentences, then continue it with one paragraph."
  python3 -c "import json,sys; print(json.dumps({'model':'m','messages':[{'role':'user','content':sys.stdin.read()}],'max_tokens':300,'temperature':0}))" <<< "$prompt" > /tmp/longctx-req.json
  ts=$(date +%s); curl -s -m1800 http://127.0.0.1:8082/v1/chat/completions -H 'Content-Type: application/json' -d @/tmp/longctx-req.json > /dev/null 2>&1; dt=$(( $(date +%s)-ts ))
  line=$(sed 's/\x1b\[[0-9;]*m//g' $L | grep -a "gen:" | tail -1 | grep -oE "in:.*tok/step\)" | sed -E 's/ -- /  /g')
  echo "words=$words wall=${dt}s | $line" | tee -a $SUM
done
killsrv; echo "DONE $(date +%T)" | tee -a $SUM
