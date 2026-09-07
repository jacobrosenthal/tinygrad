#!/bin/bash
# After the long-context variants sweep: the ATTN_LW=16 load-wave kernel (gemv-spillfree worktree 78d91a5b4+): (1) correctness = the
# chunk-8 numerics rows must be bitwise identical to the serving tree's (same math, same reduction order), (2) the long-context sweep.
S=$(cd "$(dirname "$0")" && pwd); TOP=/home/jacob/z/tinygrad; B=$TOP/sweeps/chestnut-usb3-20260830; LOGD=$S/../logs; CL="$LOGD/$(date +%Y%m%d-%H%M%S)-chainL.log"
PY=$TOP/.venv/bin/python3; W=/home/jacob/z/worktrees/gemv-spillfree; BX=$B/bitexact-20260906; K=$B/usb4-kfd-20260906
log(){ echo "$(date +%T) $*" | tee -a "$CL"; }
log "chainL start: waiting for the variants sweep"
while pgrep -f "longctx_variants.sh|longctx_sweep.sh" >/dev/null; do sleep 30; done
exec 9>/tmp/chestnut-sweep.lock; flock 9
REF=$(ls -td $BX/logs/numerics-* | head -1); OUT=$BX/logs/numerics-lw16-$(date +%Y%m%d-%H%M%S); mkdir -p $OUT
log "1/2 correctness: chunk-8 with ATTN_LW=16 (worktree) vs $REF/chunk-8.npz"
(cd / && ATTN_LW=16 PYTHONPATH=$W MTP_K=3 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 LLM_CACHE=0 DEV=KFD+AMD:LLVM PYTHONUNBUFFERED=1 timeout -s KILL 900 $PY $BX/scripts/chunk_numerics.py chunk $OUT/chunk-8.npz 8 > $OUT/chunk-8.log 2>&1); log "  rc=$?"
$PY - "$REF/chunk-8.npz" "$OUT/chunk-8.npz" <<'PY' 2>&1 | tee -a "$CL"
import sys, numpy as np
a, b = np.load(sys.argv[1]), np.load(sys.argv[2]); A, B = a["blocks"], b["blocks"]
diff = [i for i in range(A.shape[0]) if not np.array_equal(A[i], B[i])]
print("ATTN_LW=16 vs serving tree: blocks differing:", len(diff), "of", A.shape[0], "| logits max |d|:", float(np.abs(a["logits"] - b["logits"]).max()), "| VERDICT:", "BITWISE IDENTICAL" if not diff else f"DIFFERS from block {diff[0]}")
PY
flock -u 9
log "2/2 long-context sweep with ATTN_LW=16 (worktree)"; (cd / && ATTN_LW=16 PYTHONPATH=$W bash $K/longctx/longctx_sweep.sh 2>&1 | grep -E "words=|did not|DONE" | tee -a "$CL")
log "CHAINL DONE"
