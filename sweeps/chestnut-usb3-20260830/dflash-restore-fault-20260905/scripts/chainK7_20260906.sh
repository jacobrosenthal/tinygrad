#!/bin/bash
# After chainK6: chunk-width numerics with LLM_CACHE=0 and no warmup (chainK5 OOMed at 23.85 GB with the warmed graphs resident).
#   WAIT_PID=<chainK4 pid> bash chainK7_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; B=$TOP/sweeps/chestnut-usb3-20260830; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chainK7.log"
PY=$TOP/.venv/bin/python3; BX=$B/bitexact-20260906; OUT=$BX/logs/numerics-$(date +%Y%m%d-%H%M%S); mkdir -p $OUT
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
killpy(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q "chunk_numerics" && kill -9 "$p" 2>/dev/null; done; }
log "chainK7 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 20; done
exec 9>/tmp/chestnut-sweep.lock; flock 9
for v in "seq 4" "chunk 4" "chunk 8" "seq 8"; do set -- $v; name=$1-$2
  (cd / && MTP_K=3 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 LLM_CACHE=0 DEV=KFD+AMD:LLVM PYTHONUNBUFFERED=1 timeout -s KILL 1500 $PY $BX/scripts/chunk_numerics.py $1 $OUT/$name.npz $2 > $OUT/$name.log 2>&1); rc=$?; killpy; sleep 3
  log "  $name rc=$rc $(grep -aE "top1|saved|Error" $OUT/$name.log | sed 's/\x1b\[[0-9;]*m//g' | tail -2 | cut -c1-120 | tr '\n' ' | ')"
done
flock -u 9
log "compare T=1 vs T=4:"; $PY $BX/scripts/compare_numerics.py $OUT/seq-4.npz $OUT/chunk-4.npz 2>&1 | tee -a "$CL" | tail -5
log "compare T=1 vs T=8:"; $PY $BX/scripts/compare_numerics.py $OUT/seq-8.npz $OUT/chunk-8.npz 2>&1 | tee -a "$CL" | tail -5
log "CHAINK5 DONE"
