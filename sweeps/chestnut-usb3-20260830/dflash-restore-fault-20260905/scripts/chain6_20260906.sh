#!/bin/bash
# Sixth sequential chain: waits for chain5 (by PID), then (1) the fused-selector correctness test on the device and (2) its throughput
# sweep (perf_sweep_sel3.sh), both on the gemv-spillfree tree.
#   WAIT_PID=<chain5 pid> TREE=/home/jacob/z/worktrees/gemv-spillfree bash chain6_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain6.log"
SEL=$TOP/sweeps/chestnut-usb3-20260830/dflash-selector-20260906; mkdir -p $SEL/logs
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chain6 start: waiting for pid ${WAIT_PID:-none}; TREE=$TREE"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "chain5 exited"
exec 9>/tmp/chestnut-sweep.lock; flock 9
log "1/2 fused selector correctness test"; TL="$SEL/logs/$(date +%Y%m%d-%H%M%S)-test-select-fused.log"
(cd / && DEV=USB+AMD:LLVM PYTHONPATH=$TREE PYTHONUNBUFFERED=1 timeout 1500 $TOP/.venv/bin/python3 $SEL/scripts/test_select_fused.py 5 5 > "$TL" 2>&1); rc=$?
log "1/2 done rc=$rc: $(grep -E "trials bit-match|Error|error" "$TL" | tail -2 | tr '\n' ' ')"
rm -f /tmp/am_usb:*.lock; flock -u 9
log "2/2 fused selector throughput"; TREE=$TREE RESTORES=2 REQS=8 bash "$SEL/scripts/perf_sweep_sel3.sh" >> "$CL" 2>&1
log "2/2 done: $(ls -t $SEL/logs/*-fsel-summary.txt | head -1)"
log "CHAIN6 DONE"
