# MTP restricted draft vocabulary (MTP_DRAFT_VOCAB) — 2026-09-06, on KFD

Why: the KFD per-step profile (usb4-kfd-20260906) shows the 1.02 GB q6k lm_head read once per sequential MTP draft (3x at K=3) =
3.56 ms of a 35 ms step, at 878 GB/s (bandwidth-perfect, just too many bytes). syv-ai reported +10 tok/s on a 3090 from a
restricted draft vocab. Implementation (branch gemv-spillfree 5bb4696c5/78e4f28ee): `MTP_DRAFT_VOCAB=N` makes the draft passes use
a row-prefix slice of the head's raw ggml bytes (first N BPE ids, so draft ids need no remap; zero-copy view, cache-restore safe);
the verify still scores the full vocab, so acceptance stays exact — a draft outside the slice is simply rejected.

## Runs
| when | config | result |
|---|---|---|
| queued (chainK2 after chainK) | `perf_sweep_dv.sh`: K=3 x N in {0, 32k, 64k, 128k}, K=5 x 64k; 8 prompts x 500 tok greedy, KFD | pending. Expect ~ -2.6 ms/step at 64k (-7%) if acceptance holds |
| 10:18-10:33 (chainK2) | first run | INVALID: all legs identical to dv0 (82.2, same per-request numbers) — the generated script kept perf_sweep.sh's `cd "$TOP"`, and with the serving checkout as cwd `python -m tinygrad.llm.cli` imports the MAIN tree ahead of PYTHONPATH (cwd is sys.path[0]), so the worktree code (draft vocab, GEMV_TG) never ran. Fixed (`cd /`); rerun + levers sweep queued as chainK6. The fused-selector KFD sweep is unaffected (its script already used `cd /`). |
| 10:38-10:54 (chainK6, cwd fixed, gemv-spillfree tree 8a10c30f2) | `perf_sweep_dv.sh`, KFD, restored instances, 8 x 500 tok greedy (logs/20260906-103804-dv-summary.txt) | k3-dv0 **82.8** (74-93, 2.82 tok/step) / k3-dv32k 87.4 (2.67) / **k3-dv64k 89.6** (84-95, 2.81) / k3-dv128k 87.5 (2.83) / k5-dv64k 84.1 (76-101, 3.14). **MTP_DRAFT_VOCAB=65536: +8% at K=3 with acceptance unchanged** (2.81 vs 2.82 tok/step); 32k already loses acceptance (2.67), 128k saves fewer bytes. K=5 with dv64k reaches 84.1 (first request 101 tok/s) but still trails K=3. |
| 10:54-11:08 (chainK6) | `perf_sweep_dv2.sh` levers (logs/20260906-105447-dv2-summary.txt) | k3-tg16-old 82.2 vs dv0/TG-default 82.8 (GEMV_TG: +0.7%, noise at K=3); k3-fa (FAST_ARGMAX) 82.1 (no gain: the argmax reduce is ~1%); k3-dv64k-fa 89.2 (= dv64k); k4-dv64k-fa 87.1 (78-100, 2.99). Verdict: ship MTP_DRAFT_VOCAB=65536 (+8%); GEMV_TG and FAST_ARGMAX are neutral at K=3 (keep TG for K>=5, argmax off). |
