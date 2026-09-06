# Research sweep 2026-09-06 — Qwen3.8-27B on the chestnut (7900 XTX over USB)

Context: after the scratch-regrowth fix (dflash-restore-fault-20260905) the fork is at MTP K=3 ~75 tok/s mean over 8 long
prompts (82 on request 1 @ 3.2 tok/step), bandwidth ceiling ~185 tok/s at 3 tok/step; ~57% of a step is non-weight time
(USB round trips, 4 graph submissions, host Python). This doc collects what to try next: arXiv, X/HN, Hugging Face, and the
comms/USB4 big picture. Each section is a subagent report (web-searched 2026-09-06; X API connector was down, X via web).

## arXiv (21 searches, ~40 abstracts)

### 1. Speculative decoding for hybrid/GDN models, drafters, verification
1. 2609.04098 (Sep 3 2026) "Why Gated DeltaNet Survives 4-Bit Quantization: NVFP4 W4A4 for the Recurrent Half of a Hybrid 27B
   LLM" — W4A4 on all 496 linears of Qwen3.8-27B incl. GDN decay/write gates: 5-task avg −0.52 vs BF16 (noise), RULER to 64K
   intact, 17.5 GiB, +14–19% prefill; 11% gate-GEMM error collapses to ~2% output error. => GDN projections/gates are NOT
   sensitive; quantize them like the rest (informs our GDN-aware imatrix item: no need to keep GDN high precision).
2. 2608.20961 (Aug 21 2026) TreeWY: speculative verification for GDN hybrids — gated delta rule as a tree-structured WY transform:
   all draft-node outputs from one triangular solve, only the accepted state reconstructed (pseudo-value matrix ~128x smaller
   than a state). vLLM/B200: 2.2–3x lower peak memory, up to 1.40x throughput. => at batch 1 the win is ONE kernel per GDN layer
   for K drafts (fewer launches/round trips) and tree verify without K state snapshots.
3. 2607.16673 (Jul 18 2026) SpecLA: speculative decoding for linear-attention models — chain/tree verify kernels + compact factors
   to recover the accepted state + confidence pruning + EAGLE-style drafter; 1.70x on GDN-1.3B. => closest batch-1 recipe for
   GDN; port the compact-factor state recovery with TreeWY.
4. 2605.01106 (May 2026) Component-aware self-speculative decoding in hybrids — the linear-attention subgraph as a free drafter:
   alpha=0.038 at k=2 on Qwen3.5 (vs 0.68 Falcon-H1). => NEGATIVE: do not build GDN-only self-speculation for Qwen3.8.
5. 2607.05147 (Jul 2026) DSpark (DeepSeek) — semi-AR parallel drafter (parallel backbone + tiny sequential intra-block module) +
   confidence-scheduled per-request verification length; +60–85% per-user tok/s vs MTP-1 in DeepSeek-V4 production. => the
   sequential fix-up module attacks DFlash2 suffix decay past position 3; the confidence-scheduled K is a day of host work.
6. 2607.07409 (Jul 2026) DeLS-Spec — frozen DFlash drafter + independently trained lightweight local next-token head, mixed
   logits; better speedup/accepted length than DFlash on Qwen3. => cheapest DFlash2 upgrade (no block-drafter retraining).
7. 2606.01813 CaDDTree (Jun 2026) + 2608.20375 GRAFT (Jun 2026) — candidate trees from DFlash per-position marginals; CaDDTree
   picks node budget per round (unimodal, no offline search); GRAFT adds distilled edge scoring: 2.13–6.36x e2e, <0.5 ms/round.
   => verify is bandwidth-bound so tree nodes are near-free in weight bytes; needs GDN tree verify (#2/#3). Chain-only,
   CaDDTree reduces to adaptive K.
8. 2603.03251 (Mar 2026, Kumar/Dao/May) Speculative Speculative Decoding (Saguaro) — draft for predicted verification outcomes
   while verify is in flight; +30% over tuned SD. => our idle time is USB round trips: pre-draft the top-1/2 predicted
   accept-points during the host sync to hide ~ms per step.
9. 2509.18362 FastMTP + 2603.23911 MTP-D (Mar 2026) — fine-tune the native MTP head (position-shared weights, self-distilled
   data): 2.03x avg, +82% over vanilla MTP; MTP-D +7.5% acceptance, looped 1-head extension +220%. => cheapest lift for our
   K=3 MTP baseline (3.08 tok/step): self-distill on our traffic-style prompts, fine-tune only the MTP head.
10. 2605.02888 SpecKV (May 2026) — per-step gamma from draft entropy/confidence via a tiny MLP: +56% tokens/step vs fixed
    gamma=4, 0.34 ms/decision; optimal gamma shifts under INT8/NF4 targets. => trivially portable; our quantized target changes
    the acceptance curve.
Also: 2605.20104 Graft — training-free n-gram grafting into freed draft-tree slots, +21.8% over EAGLE-3 (fits NGRAM_DRAFT for
repetitive agent traffic); 2604.26412 KVShot — hidden-state-only drafters decay at long range, target-KV reuse helps acceptance.

### 2. Launch/host overhead, single-submission decode
11. 2512.22219 MPK (Dec 2025) mega-kernelized tensor programs (SM-level task graph, in-kernel scheduler, 1.2–6.7x latency);
    2605.11581 Ada-MK (May 2026) compile-time scheduling: +23.6% vs TRT-LLM, +50.2% vs vLLM batch-1, launch overhead measured at
    14.6% of decode; 2606.09682 AutoMegaKernel (Jun 2026) persistent cooperative kernel, W8A16 beats CUDA-graphed cuBLAS bf16 at
    batch 1 (5090, 1.19–1.23x); 2508.08192 (Meta, Aug 2025) +8–12% from removing CPU–GPU sync points in spec decode.
    => our ~12 x 0.5 ms round trips ≈ 6 ms of a step: device-side scheduling, on-GPU verify/sample, ONE submission per step is
    the biggest non-drafter lever; tinygrad's fused-graph exec is the natural host.

### 3. KV/state compression for long context on 24 GB
12. 2608.27513 DAMP (Aug 2026) decay-aware mixed-precision GDN/KDA state quantization: 9.9 bits/value, −69% state storage, 2.01x
    kernel, <=10.9% TPOT on Qwen3.6-35B; 2608.30386 dasc (Aug 2026) compresses GDN state checkpoints 2.63x, TTFT −42.6%.
    => batch-1 state traffic is small vs weights; the win is cheap per-turn state checkpoints for agent prefix reuse.
13. 2511.18643 Kitty (Nov 2025) 2-bit KV with dynamic channel-wise 4-bit boost (~8x KV memory, 2.1–4.1x throughput);
    2504.19874 TurboQuant (ICLR 2026) PolarQuant + 1-bit QJL residual (~3 bits, 6x memory, up to 8x faster attention);
    2605.08317 RDKV (May 2026) joint eviction+quant, 97.8% LongBench acc at 2.48% retention, 4.5x decode at 128K.
    => only 16 attention layers, but 128K KV still competes with weights; 2–3-bit KV makes 128K fit next to a 4-bit model.

### 4. Weight quantization
14. 2609.02652 (Sep 2 2026) Leech-lattice decoder for batch-1 GEMV: QTIP trellis kernel reads 2.40x fewer bytes and runs 2.27x
    faster than lattice VQ at equal bandwidth fraction; 2-bit quality cost still large at 4B; 2505.22988 YAQA + 2607.07964
    KronQ — Kronecker-factored full-model-KL Hessian adaptive rounding, quantizer-independent, ~30% KL reduction.
    => with #1 (GDN robust), a 3–3.5 bpw trellis + YAQA rounding cuts weight bytes ~25% => single-token ceiling ~60→~75 tok/s
    and frees VRAM for KV; needs a trellis GEMV for RDNA3 (ExLlamaV3 has no ROCm).

### 5. Training drafters cheaply (all on Qwen3-4B/8B DFlash)
15. DFlash (2602.06036): 5-layer drafter, block 16, KV-injection from 5 target layers, ~800K samples (Nemotron post-training v2 +
    CodeAlpaca), 6 epochs. DFlare (2606.02091) layer-wise fusion + 2.4M samples: +5–11%. Spec-AUF (2607.01893) accept-until-fail
    CE truncation: 2.40→2.61 emitted (+8.75%), no inference change. D-PACE (2605.18810) per-position CE weights, +2.3% train
    cost. Draft-OPD (2605.29343) on-policy distillation from rejection points: +13% over DFlash, +23% over EAGLE-3. SlimSpec
    (2605.10453) low-rank draft LM head, 4–5x faster head, +8–9% e2e (matters for a 150K-vocab drafter on 24 GB).
    => all loss/data changes applicable to DFlash2 training; expect stacking +15–25% accepted length.

### Try first (ranked by the agent)
1. Retrain DFlash2 with Spec-AUF + D-PACE + one Draft-OPD pass (+ DeLS-Spec local head): +15–25% tok/step (3.33→~4), zero
   inference change; low-medium effort (~1–3 rented GPU-days).
2. Single-submission decode step (on-device verify+sample, device-side scheduling; TreeWY-style GDN chain verify): recovers most
   of the ~6 ms/step of USB round trips => +25–35% at any tok/step; high effort.
3. Confidence-scheduled K (DSpark/SpecKV/CaDDTree) on MTP and DFlash2: +10–20% at near-zero effort; plus FastMTP/MTP-D
   fine-tune of the native MTP head (few GPU-hours).
4. 4-bit GDN everywhere + 3–3.5 bpw trellis with YAQA rounding: +~20% ceiling and 3–5 GB VRAM back; medium-high effort
   (RDNA3 trellis GEMV, Hessian sketch).
5. Long-context pack: 2–3-bit KV (Kitty/TurboQuant) + dasc/DAMP state checkpoints + Graft n-gram grafting: 128K agent sessions
   on 24 GB with prefix reuse; medium effort, mostly capability.
