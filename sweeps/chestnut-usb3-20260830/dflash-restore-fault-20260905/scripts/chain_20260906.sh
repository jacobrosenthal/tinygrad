#!/bin/bash
# Sequential rerun chain after the 01:00 collision. Waits for the running sampling sweep (by PID, not by a DONE line), then:
#   1. DFlash XCTX=0/16 legs (perf_sweep.sh ONLY=dflash)   2. the sampling legs the collision lost (perf_sweep2.sh ONLY=...)
#   3. selector/block sweep (perf_sweep_sel.sh).  Each script holds /tmp/chestnut-sweep.lock; the chain runs them one at a time.
#   WAIT_PID=616519 bash chain_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain.log"
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chain start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "sampling sweep pid ${WAIT_PID:-none} exited; last summary: $(ls -t $LOGD/*-sampling-summary.txt | head -1)"
# perf_sweep2.sh could not be edited while it was running (bash reads scripts incrementally): add the lock + ONLY filter now
if ! grep -q flock "$S/perf_sweep2.sh"; then
  python3 "$S/patch_perf_sweep2.py" "$S/perf_sweep2.sh" && bash -n "$S/perf_sweep2.sh" && log "perf_sweep2.sh: added lock + ONLY filter" || log "perf_sweep2.sh EDIT FAILED"
fi
log "1/3 dflash legs"; ONLY=dflash RESTORES=2 REQS=8 bash "$S/perf_sweep.sh" >> "$CL" 2>&1; log "1/3 done: $(ls -t $LOGD/*-perf-summary.txt | head -1)"
log "2/3 lost sampling legs"; ONLY='rp1.15-prod|mtp-t0.6-rp1.0|mtp-t1.0-official' RESTORES=1 REQS=6 bash "$S/perf_sweep2.sh" >> "$CL" 2>&1; log "2/3 done: $(ls -t $LOGD/*-sampling-summary.txt | head -1)"
log "3/3 selector sweep"; RESTORES=2 REQS=8 bash "$S/perf_sweep_sel.sh" >> "$CL" 2>&1; log "3/3 done: $(ls -t $LOGD/*-perfsel-summary.txt | head -1)"
log "CHAIN DONE"
