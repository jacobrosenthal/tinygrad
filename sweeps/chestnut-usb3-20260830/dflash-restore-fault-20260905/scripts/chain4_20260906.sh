#!/bin/bash
# Fourth sequential chain: waits for chain3 (by PID), then the block-8 selector legs (perf_sweep_sel2.sh: K=5 at MAX_T=12, K=7 at MAX_T=16).
#   WAIT_PID=<chain3 pid> bash chain4_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain4.log"
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chain4 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "chain3 exited"
log "1/1 block-8 selector legs"; RESTORES=2 REQS=8 bash "$S/perf_sweep_sel2.sh" >> "$CL" 2>&1
log "1/1 done: $(ls -t $LOGD/*-perfsel2-summary.txt | head -1)"
log "CHAIN4 DONE"
