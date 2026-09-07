#!/bin/bash
# Fifth sequential chain: waits for chain4 (by PID), then the exactness matrix (MTP K=1 reference vs K=3, K=5, DFlash block 6).
#   WAIT_PID=<chain4 pid> TREE=<tree> bash chain5_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain5.log"
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chain5 start: waiting for pid ${WAIT_PID:-none}; TREE=${TREE:-$TOP}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "chain4 exited"
log "1/1 exactness matrix (K=1 ref)"; TREE=${TREE:-$TOP} REQS=8 bash "$TOP/sweeps/chestnut-usb3-20260830/bitexact-20260906/scripts/bitexact.sh" >> "$CL" 2>&1
log "1/1 done: $(ls -t $TOP/sweeps/chestnut-usb3-20260830/bitexact-20260906/logs/*-bitexact-summary.txt | head -1)"
log "CHAIN5 DONE"
