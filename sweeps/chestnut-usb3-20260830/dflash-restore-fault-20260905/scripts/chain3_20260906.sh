#!/bin/bash
# Third sequential chain: waits for chain2 (by PID), then measures USB transfers per decode step (LIBUSB_DEBUG=4).
#   WAIT_PID=<chain2 pid> bash chain3_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain3.log"
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chain3 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "chain2 exited"
log "1/1 USB transfers per step (mtp-k3)"; REQS=4 bash "$TOP/sweeps/chestnut-usb3-20260830/usb-transfers-20260906/scripts/count_transfers.sh" >> "$CL" 2>&1
log "1/1 done: $(ls -t $TOP/sweeps/chestnut-usb3-20260830/usb-transfers-20260906/logs/*.summary.txt 2>/dev/null | head -1)"
log "CHAIN3 DONE"
