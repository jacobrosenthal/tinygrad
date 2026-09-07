#!/bin/bash
# After chainK5: the draft-vocab sweep (rerun with the cwd fix) then the levers sweep (dv2), both on the gemv-spillfree tree via PYTHONPATH.
#   WAIT_PID=<chainK5 pid> bash chainK6_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; B=$TOP/sweeps/chestnut-usb3-20260830; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chainK6.log"
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chainK6 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 20; done
log "1/2 draft vocab sweep (cwd fix)"; RESTORES=1 REQS=8 bash "$B/draft-vocab-20260906/perf_sweep_dv.sh" >> "$CL" 2>&1; log "1/2 done: $(ls -t $B/draft-vocab-20260906/logs/*-dv-summary.txt | head -1)"
log "2/2 levers sweep (dv2)"; RESTORES=1 REQS=8 bash "$B/draft-vocab-20260906/perf_sweep_dv2.sh" >> "$CL" 2>&1; log "2/2 done: $(ls -t $B/draft-vocab-20260906/logs/*-dv2-summary.txt | head -1)"
log "CHAINK6 DONE"
