#!/bin/bash
# Seventh sequential chain: waits for chain6 (by PID), then validates the standalone scratch-regrowth repro (repro-scratch-regrow/repro.py):
#   a. fork tree, AMD_SCRATCH_KEEP_OLD=0 (upstream behaviour), assert mode        -> expect "scratch moved" assertion to PASS (prints bases)
#   b. fork tree, AMD_SCRATCH_KEEP_OLD=0, --fault                                  -> expect GCVM fault / hang report (timeout 900 s)
#   c. fork tree, AMD_SCRATCH_KEEP_OLD=1 (fix 1), --fault                          -> expect clean completion
#   d. upstream master tree (~/z/tinygrad-master), --fault                          -> expect the fault (if master drives this dock's firmware)
#   WAIT_PID=<chain6 pid> bash chain7_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain7.log"
RD=$TOP/sweeps/chestnut-usb3-20260830/repro-scratch-regrow; mkdir -p $RD/logs; PY=$TOP/.venv/bin/python3
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
killpy(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q "repro.py" && kill -9 "$p" 2>/dev/null; done; }
run(){ # name tree extra-env args...
  local name=$1 tree=$2 extra=$3; shift 3; local L="$RD/logs/$(date +%Y%m%d-%H%M%S)-$name.log"
  log "run $name: tree=$tree env[$extra] args[$*]"
  (cd / && env $extra DEV=USB+AMD:LLVM WAVEDUMP=1 PYTHONPATH=$tree PYTHONUNBUFFERED=1 timeout -s KILL 900 $PY $RD/repro.py "$@" > "$L" 2>&1); rc=$?
  killpy; rm -f /tmp/am_usb:*.lock; sleep 5
  log "  rc=$rc  $(grep -aE "graph captured|after a kernel|assert|Assertion|GCVM|hang report|replay returned|Error" "$L" | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-140 | head -6 | tr '\n' ' | ')"
}
log "chain7 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "chain6 exited"
exec 9>/tmp/chestnut-sweep.lock; flock 9
run a-fork-keepold0-assert $TOP "AMD_SCRATCH_KEEP_OLD=0"
run b-fork-keepold0-fault  $TOP "AMD_SCRATCH_KEEP_OLD=0" --fault
run c-fork-keepold1-fault  $TOP "AMD_SCRATCH_KEEP_OLD=1" --fault
run d-master-fault /home/jacob/z/tinygrad-master "" --fault
flock -u 9
log "CHAIN7 DONE"
