#!/bin/bash
# After chainK: the MTP restricted-draft-vocab sweep on KFD (gemv-spillfree tree; also carries GEMV_TG + fused selector).
#   WAIT_PID=<chainK pid> bash chainK2_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; B=$TOP/sweeps/chestnut-usb3-20260830; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chainK2.log"
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chainK2 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 20; done
log "1/1 draft vocab sweep"; RESTORES=1 REQS=8 bash "$B/draft-vocab-20260906/perf_sweep_dv.sh" >> "$CL" 2>&1; log "1/1 done: $(ls -t $B/draft-vocab-20260906/logs/*-dv-summary.txt | head -1)"
log "CHAINK2 DONE"
