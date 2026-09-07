# DFlash2 candidate selector, fused in-graph — 2026-09-06

Context (dflash-restore-fault-20260905 README, "Selector sweeps"): the selector is what gives the published DFlash2 acceptance
(4.8-5.0 tok/step on the z-lab numbers); ours ran WITHOUT it (argmax drafts: 2.46-2.92 tok/step, 62 tok/s, below MTP K=3's 75).
The existing implementation (`DFLASH_EAGER_SEL=1`: dflash.select_gpu in its own TinyJit + host `.tolist()` + host-built chunk) proved
the acceptance (block 8, K=7: 3.52 tok/step) but costs ~150 kernel launches per step at USB round-trip prices: 4-5 tok/s, and
950-1180 s restores (compiling hundreds of tiny kernels).

## Fix (branch gemv-spillfree, c9a53aa96): tinygrad/llm/dflash_sel.py
Two fixed-shape custom HIP kernels, JIT-stable inside forward_spec, replacing the argmax drafts (`DFLASH_SEL=1`, default; 0 = argmax):
- `dflash_topk` (grid K, 256 threads): each thread keeps a sorted local top-16 over its strided slice of the 248k vocab; 16 rounds of a
  workgroup argmax (ties -> lowest id) emit vals/ids. 40 VGPRs.
- `dflash_walk` (1 workgroup): sequential over the K positions: gate = pred[prev] * hp[t]; score_j = logit_j + succ[cand_j] . gate;
  argmax of 16; prev = chosen. The codebooks (rank 256) are read straight from their Q4_K bytes (one 144 B block per token row;
  in-kernel dequant), so no 2 x 254 MB float tables. hp = sel_proj(dh) comes from the attached gemv. 124 VGPRs.
Both compile clean offline for gfx1100 (compile_probe path). load_dflash keeps the raw codebook tensors; DFLASH_SEL is in the cache key.

## Tests
| when | what | result |
|---|---|---|
| 08:34 (chain6) | `scripts/test_select_fused.py 5 5`: fused kernels vs a numpy reference (dequantized tables, same walk) on random logits/hiddens + the real codebooks; three-way with select_gpu (logs/*-test-select-fused.log) | **5/5 trials bit-match** the float reference; the gemv-hp (quantized activations) path and select_gpu pick the same 5 tokens in every trial. Kernels compile in 1.2 s on device |
| queued (chain6) | `scripts/perf_sweep_sel3.sh`: dflash-b6-fsel (K=5), dflash-b8-k7-fsel-t16, dflash-b8-k7-fsel-x16-t16, dflash-b6-argmax control; restored instances, 8 x 500 tok greedy | pending. Target: block 8 + selector at ~3.5 tok/step with the per-step cost of the argmax path (62 tok/s @ 2.46) => ~85-90 tok/s |
| 08:34-09:11 (chain6, stopped after the block-8 leg to free the dock for the USB4/KFD experiment) | `perf_sweep_sel3.sh`, restored instances, 8 x 500 tok greedy (logs/20260906-083438-fsel-summary.txt) | dflash-b6-fsel **66.4 tok/s** (60-75, 2.53 tok/step, req1 75 @ 3.01) vs b6 argmax 62.8 (+6%); dflash-b8-k7-fsel-t16 **62.5** (54-75, 2.72 tok/step, req1 75 @ 3.52). Restores 192-205 s (eager selector: 950-1180 s at 4-5 tok/s). The selector works and costs nothing visible, but block 8's 15-token verify eats its acceptance gain; both stay below MTP K=3 (75). Not run: x16 variant, argmax control (re-queue on whichever transport is live). |

Verdict so far: DFlash2 on this stack tops out at ~66 tok/s vs MTP K=3's 75 on USB3; its extra acceptance (2.5-3.5 tok/step) does not cover the drafter + wider-verify cost per step. Re-evaluate after the USB4/KFD move (per-step USB overhead shrinks, which favours the wider chunks).

## 10:00-10:17 on KFD (perf_sweep_sel3_kfd.sh, restored instances, 8 x 500 tok greedy, logs/20260906-100012-fsel-summary.txt)
| config | mean tok/s | min-max | tok/step | req1 | restore s |
|---|---|---|---|---|---|
| dflash-b6-fsel (block 6, K=5, selector) | 72.0 | 65-83 | 2.53 | 83 | 79 |
| dflash-b8-k7-fsel-t16 (block 8, selector) | 67.0 | 58-82 | 2.72 | 82 | 94 |
| dflash-b8-k7-fsel-x16-t16 (block 8, selector, XCTX=16) | **74.4** | 68-89 | 3.18 | 89 | 88 |
| dflash-b6-argmax (control) | 70.6 | 65-83 | 2.46 | 83 | 81 |
| mtp-k3 (KFD, same day) | **82.2** | 73-92 | 2.82 | 92 | 73 |

Best DFlash on KFD is block 8 + selector + XCTX=16 at 74.4, still 10% under MTP K=3. The selector adds +2% over argmax at block 6
(72.0 vs 70.6) and XCTX=16 adds +11% at block 8 (74.4 vs 67.0: acceptance 3.18 vs 2.72). The drafter's own cost (5 layers at
T=8 + the 248k head over K rows) plus the ALU-bound 15-token verify is what MTP does not pay. Verdict: DFlash2 as shipped does not
beat the native MTP head on a 7900 XTX; the fused selector and the XCTX path are kept (DFLASH_SEL default) for a retrained /
smaller drafter later.
