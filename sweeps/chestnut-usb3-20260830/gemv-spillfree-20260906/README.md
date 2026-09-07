# Spill-free batched gemv for wide speculative verify (T >= 5) — 2026-09-06

Backlog item "Spill-free gemv configs for T>=9" (sweeps/README.md): the K=4/5 MTP and DFlash T=10 kernels spill to scratch, which
is the suspected reason wider verify did not pay (K=3 74.9 tok/s, K=4 73.2, K=5 67 on 08-06 restores). This directory holds an
OFFLINE register-pressure probe (no GPU: clang -> LLVM IR -> AMDLLVMCompiler gfx1100 -> ELF notes) and the fix on branch
`gemv-spillfree` (worktree at /home/jacob/z/worktrees/gemv-spillfree, so the serving checkout's LLM cache stays valid while the
01:49 sweep chain runs; the on-device sweep imports it via PYTHONPATH).

## Tests (chronological; logs/ has every probe output)

| when | what | result |
|---|---|---|
| 01:52 | `compile_probe.py q5k:5120:6144:res T=10` (probe sanity vs the on-device ELF from the 09-05 hang report) | identical: 256 VGPR, 145 spilled, 424 B scratch, 80 SGPR |
| 01:53 | knob sweep T=8..12 x R=1,2 x U=1,2 x XP=0, six shapes (logs/*-probe-knobs.log) | ONLY q5k spills at R2U2 (67/115/145/177/201 at T8..12); q6k 15/29 at T11/12; iq4nl, iq3s never. U=1 removes every spill (q5k T10 R2U1 = 214 VGPR) but halves the unroll |
| 01:56 | token-grouped x staging, GEMV_TG=2..5 vs old (logs/*-probe-tg*.log) | q5k T8/10/12: 256+67 / 256+145 / 256+201 -> 211/0, 247/0, 256+23. q4k 5120x17408 T10: 193 -> 150 (TG4) / 116 (TG2). q6k: 0 -> 2 spills at T10, 29 -> 46 at T12 (worse) => group only q4k/q5k |
| 01:59 | threshold probe T=4..7 (logs/*-probe-tg-threshold.log) | q5k 5120x6144 spills already at T=7 (31) with 255 VGPR at T=6; grouped: 201 at T7, 183 at T6. q4k 5120x6144: 253 -> 185 at T7 |

| 02:09 | the 8 production fused multi-gemvs (GDN in-proj, attn q/k/v, ffn gate/up; `compile_probe.py multi`, logs/*-probe-multi.log) old vs default | no spills in either (q6k+q5k / q6k+q6k ffn at T12: 2 / 4); grouping lowers VGPRs where a K4 segment is present: GDN in-proj T7 173 -> 146, T10 215 -> 178; attn q4k/q6k/q8 T10 239 -> 201; ffn q6k+q5k T10 236 -> 172 (occupancy 6-7 -> 8-10 waves/SIMD) |

T=7 is the production MTP K=3 chunk (up to K+1 committed + K drafts), so the q5k o_proj-class gemvs spill in production today, not only
at K>=4. Single-gemv shapes in production: q5k/q4k 5120x6144 (+res; out-proj), q4k/q5k/q6k/iq4nl/iq4xs/iq3s 5120x17408 (+res; ffn
down, per-layer UD mix), q6k 5120x10240, q6k 248320x5120 (lm_head; 117-195 VGPRs, never spills).

## Fix (branch gemv-spillfree, 321fd040f)
`_seg_body` stages the x slices TG tokens at a time when `_tg(T, fmt) < T` (dots for a group run before the next group's loads); the
weights still stream once per T tokens. Default: TG=4 for q4k/q5k at T>=5, other formats unchanged; `GEMV_TG=<n>` overrides
(>= T restores the old code). Kernel names carry `_tg<N>`; `GEMV_TG` is in the LLM cache key.

## On-device (queued behind the 01:49 chain: dflash legs -> lost sampling legs -> selector sweep)
`scripts/perf_sweep_tg.sh`: mtp-k3 and mtp-k5 x GEMV_TG in {default(4), 2, 16(old)} on restored instances, 8 long prompts, port 8082,
PYTHONPATH=the gemv-spillfree worktree. Success = K=3 tok/s up (q5k T=7 no longer spills) and K=4/5 closing on K=3's tok/s.

## On-device (perf_sweep_tg.sh, 03:45-05:10, restored instances, 8 long prompts x 500 tok greedy, logs/20260906-034548-tg-summary.txt)
| config | GEMV_TG | mean tok/s | min-max | tok/step | req1 |
|---|---|---|---|---|---|
| MTP K=3 | 16 (old code) | 74.7 | 67-82 | 2.82 | 82 |
| MTP K=3 | 4 (new default) | 75.2 | 67-83 | 2.82 | 83 |
| MTP K=3 | 2 | 74.5 | 67-82 | 2.82 | 82 |
| MTP K=5 | 16 (old code) | 67.2 | 58-76 | 3.21 | 76 |
| MTP K=5 | 4 (new default) | 70.4 | 61-80 | 3.21 | 80 |
| MTP K=5 | 2 | 69.8 | 60-79 | 3.21 | 79 |

K=3 (T<=7): +0.7%, within noise — the q5k T=7 spill (31 VGPRs) is a small share of the step. K=5 (T<=11): +4.8% (67.2 -> 70.4);
the spill was real but not the whole K=5 gap: at 3.21 tok/step K=5 still trails K=3 (75.2), so the remaining per-step cost at T=11
(attention verify, the ~540 USB transfers/step measured in ../usb-transfers-20260906) dominates. TG=4 beats TG=2 at both K.
Decision: merge `gemv-spillfree` (321fd040f) into the serving branch — no downside at K=3, +4.8% at K=5, needed for any wider verify.

MERGED into the serving branch amd-qwen-on-master at dfe59dd70 (11:22) together with the fused DFlash selector (DFLASH_SEL, default on
but DFlash itself is off), MTP_DRAFT_VOCAB (default 0; production candidate 65536) and FAST_ARGMAX (default 0). On KFD GEMV_TG is
neutral at K=3 (82.2 vs 82.8) and worth +4.8% at K=5; the q5k out-proj at T=7 no longer spills.
