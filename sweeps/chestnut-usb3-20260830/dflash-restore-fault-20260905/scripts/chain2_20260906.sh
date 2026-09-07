#!/bin/bash
# Second sequential chain: waits for chain_20260906.sh (by PID) to finish its three sweeps, then
#   1. the on-device GEMV_TG sweep (gemv-spillfree worktree via PYTHONPATH)   2. the bit-exactness gate on the serving tree.
#   WAIT_PID=<chain pid> TREE=<gemv-spillfree worktree> bash chain2_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain2.log"
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chain2 start: waiting for pid ${WAIT_PID:-none}; TREE=$TREE"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "chain 1 exited"
log "1/2 GEMV_TG sweep"; TREE=$TREE RESTORES=2 REQS=8 bash "$TOP/sweeps/chestnut-usb3-20260830/gemv-spillfree-20260906/scripts/perf_sweep_tg.sh" >> "$CL" 2>&1
log "1/2 done: $(ls -t $TOP/sweeps/chestnut-usb3-20260830/gemv-spillfree-20260906/logs/*-tg-summary.txt | head -1)"
log "2/2 bit-exactness gate"; REQS=8 bash "$TOP/sweeps/chestnut-usb3-20260830/bitexact-20260906/scripts/bitexact.sh" >> "$CL" 2>&1
log "2/2 done: $(ls -t $TOP/sweeps/chestnut-usb3-20260830/bitexact-20260906/logs/*-bitexact-summary.txt | head -1)"
log "CHAIN2 DONE"
