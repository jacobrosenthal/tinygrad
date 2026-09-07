#!/bin/bash
# After chainK3: re-validate the scratch repro (now with free_cache) + the upstream unittest via python -m unittest (pytest is not installed), on KFD.
#   WAIT_PID=<chainK3 pid> bash chainK4_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; B=$TOP/sweeps/chestnut-usb3-20260830; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chainK4.log"
PY=$TOP/.venv/bin/python3; RD=$B/repro-scratch-regrow; M=/home/jacob/z/tinygrad-master
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
killpy(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -qE "repro.py|test_scratch_regrow" && kill -9 "$p" 2>/dev/null; done; }
log "chainK4 start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 20; done
exec 9>/tmp/chestnut-sweep.lock; flock 9
run(){ local name=$1 tree=$2 extra=$3; shift 3; local L="$RD/logs/$(date +%Y%m%d-%H%M%S)-$name.log"; log "run $name: tree=$tree env[$extra] args[$*]"
  (cd / && env $extra DEV=KFD+AMD:LLVM PYTHONPATH=$tree PYTHONUNBUFFERED=1 timeout -s KILL 600 $PY $RD/repro.py "$@" > "$L" 2>&1); rc=$?; killpy; sleep 3
  log "  rc=$rc  $(grep -aE "graph captured|after a kernel|assert|Assertion|GCVM|hang report|replay returned|Error|fault" "$L" | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-140 | head -6 | tr '\n' ' | ')"; }
run a-fork-keepold0-assert $TOP "AMD_SCRATCH_KEEP_OLD=0"
run b-fork-keepold0-fault  $TOP "AMD_SCRATCH_KEEP_OLD=0" --fault
run c-fork-keepold1-fault  $TOP "AMD_SCRATCH_KEEP_OLD=1" --fault
run d-master-fault $M "" --fault
for leg in fixed reverted; do
  if [ $leg = fixed ]; then T=$M; else T=/home/jacob/z/worktrees/scratch-reverted; git -C $M worktree add -q -f $T 479e077ec 2>/dev/null || true; cp $M/test/test_scratch_regrow.py $T/test/; fi
  L="$RD/logs/$(date +%Y%m%d-%H%M%S)-unittest-$leg.log"; log "run unittest-$leg: $(git -C $T log --oneline -1 | cut -c1-50)"
  (cd $T && DEV=KFD+AMD:LLVM PYTHONPATH=$T PYTHONUNBUFFERED=1 timeout -s KILL 600 $PY -m unittest -v test.test_scratch_regrow > "$L" 2>&1); rc=$?; killpy; sleep 3
  log "  rc=$rc  $(grep -aE "^test_|OK|FAILED|Error|GCVM|fault|skipped|Ran " "$L" | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-140 | tail -4 | tr '\n' ' | ')"
done
flock -u 9; log "CHAINK4 DONE"
