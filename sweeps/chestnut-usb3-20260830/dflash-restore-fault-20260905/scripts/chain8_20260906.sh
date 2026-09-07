#!/bin/bash
# Eighth chain: after chain7, run the upstream-style unittest (test/test_scratch_regrow.py on the upstream-scratch-keep-old branch) on the dock:
#   with the fix (branch HEAD) -> expect PASS; with the fix reverted in a temp worktree -> expect the GCVM fault (timeout).
#   WAIT_PID=<chain7 pid> bash chain8_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chain8.log"
RD=$TOP/sweeps/chestnut-usb3-20260830/repro-scratch-regrow; M=/home/jacob/z/tinygrad-master; PY=$TOP/.venv/bin/python3
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
killpy(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -q "test_scratch_regrow" && kill -9 "$p" 2>/dev/null; done; }
log "chain8 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 30; done
log "chain7 exited"
exec 9>/tmp/chestnut-sweep.lock; flock 9
for leg in fixed reverted; do
  if [ $leg = fixed ]; then TREE=$M; else
    TREE=/home/jacob/z/worktrees/scratch-reverted; git -C $M worktree add -q -f $TREE 479e077ec 2>/dev/null || true
    cp $M/test/test_scratch_regrow.py $TREE/test/; fi
  L="$RD/logs/$(date +%Y%m%d-%H%M%S)-unittest-$leg.log"; log "run $leg: tree=$TREE ($(git -C $TREE log --oneline -1 | cut -c1-60))"
  (cd $TREE && DEV=USB+AMD:LLVM PYTHONPATH=$TREE PYTHONUNBUFFERED=1 timeout -s KILL 900 $PY -m pytest -x -q test/test_scratch_regrow.py > "$L" 2>&1); rc=$?
  killpy; rm -f /tmp/am_usb:*.lock; sleep 5
  log "  rc=$rc  $(grep -aE "passed|failed|error|GCVM|hang report|skipped" "$L" | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-140 | tail -3 | tr '\n' ' | ')"
done
flock -u 9
log "CHAIN8 DONE"
