#!/bin/bash
# KFD/USB4 chain (dock tunneled, DEV=KFD+AMD:LLVM). Waits for the profile run (by PID) then, one at a time under the sweep lock:
#  1. MTP K=3/4/5 sweep on KFD (perf_sweep_kfd.sh)          2. scratch repro validation (repro.py, fork keep-old=0 assert + fault, keep-old=1 fault; master)
#  3. upstream unittest fixed vs reverted                    4. DFlash fused-selector legs on KFD (perf_sweep_sel3_kfd.sh)
#  5. chunk-width numerics (chunk_numerics.py seq/chunk)     6. tunnel soak log every 60 s throughout (tb-soak.log)
#   WAIT_PID=<pid> bash chainK_20260906.sh
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; B=$TOP/sweeps/chestnut-usb3-20260830; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chainK.log"
PY=$TOP/.venv/bin/python3; KD=$B/usb4-kfd-20260906; RD=$B/repro-scratch-regrow; M=/home/jacob/z/tinygrad-master; TREE=/home/jacob/z/worktrees/gemv-spillfree
export DEVSTR=KFD+AMD:LLVM
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
killpy(){ for p in $(ls /proc 2>/dev/null|grep -E '^[0-9]+$'); do [ "$(cat /proc/$p/comm 2>/dev/null)" = python3 ] && tr '\0' ' ' </proc/$p/cmdline 2>/dev/null|grep -qE "tinygrad.llm.cli|repro.py|test_scratch_regrow|chunk_numerics" && kill -9 "$p" 2>/dev/null; done; }
# tunnel soak logger (background, whole chain)
( while true; do echo "$(date +%T) tb=$(ls /sys/bus/thunderbolt/devices/ 2>/dev/null | grep -c '^0-3$') gpu=$([ -d /sys/bus/pci/devices/0000:57:00.0 ] && cat /sys/bus/pci/devices/0000:57:00.0/power/runtime_status || echo gone) kfd_nodes=$(ls /sys/class/kfd/kfd/topology/nodes/ | wc -l)"; sleep 60; done >> "$KD/logs/$(date +%Y%m%d-%H%M%S)-tb-soak.log" ) & SOAK=$!
log "chainK start: waiting for pid ${WAIT_PID:-none}"
while [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; do sleep 20; done
log "1/5 MTP K=3/4/5 on KFD"; RESTORES=1 REQS=8 bash "$KD/perf_sweep_kfd.sh" >> "$CL" 2>&1; log "1/5 done: $(ls -t $KD/logs/*-perf-summary.txt | head -1)"
exec 9>/tmp/chestnut-sweep.lock; flock 9
run(){ local name=$1 tree=$2 extra=$3; shift 3; local L="$RD/logs/$(date +%Y%m%d-%H%M%S)-$name.log"; log "run $name: tree=$tree env[$extra] args[$*]"
  (cd / && env $extra DEV=KFD+AMD:LLVM PYTHONPATH=$tree PYTHONUNBUFFERED=1 timeout -s KILL 600 $PY $RD/repro.py "$@" > "$L" 2>&1); rc=$?; killpy; sleep 3
  log "  rc=$rc  $(grep -aE "graph captured|after a kernel|assert|Assertion|GCVM|hang report|replay returned|Error|fault" "$L" | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-140 | head -6 | tr '\n' ' | ')"; }
log "2/5 scratch repro validation"; mkdir -p $RD/logs
run a-fork-keepold0-assert $TOP "AMD_SCRATCH_KEEP_OLD=0"
run b-fork-keepold0-fault  $TOP "AMD_SCRATCH_KEEP_OLD=0" --fault
run c-fork-keepold1-fault  $TOP "AMD_SCRATCH_KEEP_OLD=1" --fault
run d-master-fault $M "" --fault
log "3/5 upstream unittest fixed vs reverted"
for leg in fixed reverted; do
  if [ $leg = fixed ]; then T=$M; else T=/home/jacob/z/worktrees/scratch-reverted; git -C $M worktree add -q -f $T 479e077ec 2>/dev/null || true; cp $M/test/test_scratch_regrow.py $T/test/; fi
  L="$RD/logs/$(date +%Y%m%d-%H%M%S)-unittest-$leg.log"; log "run unittest-$leg: $(git -C $T log --oneline -1 | cut -c1-50)"
  (cd $T && DEV=KFD+AMD:LLVM PYTHONPATH=$T PYTHONUNBUFFERED=1 timeout -s KILL 600 $PY -m pytest -x -q test/test_scratch_regrow.py > "$L" 2>&1); rc=$?; killpy; sleep 3
  log "  rc=$rc  $(grep -aE "passed|failed|error|GCVM|fault|skipped" "$L" | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-140 | tail -3 | tr '\n' ' | ')"
done
flock -u 9
log "4/5 DFlash fused selector on KFD"; TREE=$TREE RESTORES=1 REQS=8 bash "$B/dflash-selector-20260906/scripts/perf_sweep_sel3_kfd.sh" >> "$CL" 2>&1; log "4/5 done: $(ls -t $B/dflash-selector-20260906/logs/*-fsel-summary.txt | head -1)"
log "5/5 chunk-width numerics"; BX=$B/bitexact-20260906; OUT=$BX/logs/numerics-$(date +%Y%m%d-%H%M%S); mkdir -p $OUT
exec 9>/tmp/chestnut-sweep.lock; flock 9
for v in "seq 4" "chunk 4" "chunk 8" "seq 8"; do set -- $v; name=$1-$2
  (cd / && MTP_K=3 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 LLM_CACHE=1 DEV=KFD+AMD:LLVM PYTHONUNBUFFERED=1 timeout -s KILL 1500 $PY $BX/scripts/chunk_numerics.py $1 $OUT/$name.npz $2 > $OUT/$name.log 2>&1); rc=$?; killpy; sleep 3
  log "  $name rc=$rc $(grep -aE "top1|saved|Error" $OUT/$name.log | sed 's/\x1b\[[0-9;]*m//g' | tail -2 | cut -c1-120 | tr '\n' ' | ')"
done
flock -u 9
log "compare T=1 vs T=4:"; $PY $BX/scripts/compare_numerics.py $OUT/seq-4.npz $OUT/chunk-4.npz 2>&1 | tee -a "$CL" | tail -4
log "compare T=1 vs T=8:"; $PY $BX/scripts/compare_numerics.py $OUT/seq-8.npz $OUT/chunk-8.npz 2>&1 | tee -a "$CL" | tail -4
kill $SOAK 2>/dev/null; log "CHAINK DONE"
