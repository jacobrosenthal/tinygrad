# Bit-exactness gate for the speculative verify path — 2026-09-06

Why: greedy speculative decoding must reproduce the plain greedy sequence token for token (the verify accepts exactly the tokens the
target would have produced). Two groups reported divergence bugs in their spec paths this month (thc1006's deterministic greedy
divergence; vLLM #40914 stale-KV under cudagraphs), and llama.cpp's DFlash2 has a Vulkan acceptance bug. Every throughput number we
publish assumes our verify is exact; this checks it before more tuning (ranked #3 in sweeps/qwen38-research-20260906).

What `scripts/bitexact.sh` does: three servers in sequence on port 8082 (lock held), same tree, same model, `--repeat-penalty 1.0`,
temperature 0, 8 prompts x 400 tokens: `plain` (MTP=0: one token per step, T=1 gemvs), `mtp-k3`, `dflash-b6` (block 6, no selector,
XCTX=0). `scripts/bitexact_compare.py <outputs dir>` prints per request EXACT or the first divergent character with context, and a
verdict per config. Outputs are kept under logs/outputs-<ts>/.

Caveat: MTP=0 also changes the chunk width of the plain decoder (T=1 vs T up to 7), so the T>1 gemv/attention kernels are part of
what is being tested: a divergence can be a spec bug OR a T>1 numerics bug; the first divergent token + logits would tell which.

## Runs
| when | tree | result |
|---|---|---|
| queued (chain2, after the GEMV_TG sweep) | serving checkout | pending |
| 05:10-05:29 (chain2, gemv-spillfree tree 321fd040f) | plain / mtp-k3 / dflash-b6 | `plain` (MTP=0) did not start: the generic non-fused decode path OOMs at 8K context during warmup (`Allocation of 17.00 MB failed on AMD. Used: 23.68 GB`, generic E_* kernels at 17.6 GB and climbing) — the fork's fused path assumes spec decode. mtp-k3 vs dflash-b6 (both greedy, penalty 1.0): **0/8 identical**, diverging after 100-750 chars at semantically-equivalent choices ("array" vs "list", "Key" vs "Core") = near-tie flips, i.e. either T-dependent numerics or a verify/KV bug; undecidable without a same-path reference |
| queued (chain5, after chain4) | mtp-k1 (reference) / mtp-k3 / mtp-k5 / dflash-b6 | pending: if K=1/3/5 agree and DFlash differs -> DFlash verify/KV bug; if K=1/3/5 disagree -> chunk-width-dependent numerics in the fused kernels (KV quant per chunk?) |
| 08:04-08:34 (chain5, gemv-spillfree tree c9a53aa96) | mtp-k1 (ref) / mtp-k3 / mtp-k5 / dflash-b6, greedy, penalty 1.0, 8 x 400 tok | **0/8 identical for every pair** (K=1 vs K=3, K=1 vs K=5, K=3 vs K=5, DFlash vs any). Divergence points: req1 at char 15 (token ~4) for K=3, K=5 AND DFlash, all three choosing the SAME alternative ("me to implement four") against K=1 ("implementations of"); req0 (char 267) and req6 (char 184) likewise identical across the three wide configs vs K=1. So the wide-chunk paths agree with each other and K=1 (chunks of T<=3) is the odd one out: this is chunk-width-dependent NUMERICS in the fused kernels (a T-dependent reduction order somewhere: attention KV-split, GDN chunk scan, or the XP/R gemv variants at T<=2), not a verify/KV bug. K=3 vs K=5 also diverge later (T 7 vs 11 variants). Verdict: outputs are chunk-width dependent at the near-tie level; "bit-exact vs a narrower chunk" cannot be the gate. Next: a direct logits test (same prefix, next-token logits from a T=1 vs T=4 vs T=8 forward, bitwise per layer) to name the kernel; making it T-invariant would make spec decode exactly reproduce plain greedy. |
| 11:12-11:20 (by hand + background, KFD, LLM_CACHE=0, prompt fed through the decode path in 8-token chunks) | `chunk_numerics.py` seq-4 / chunk-4 / seq-8 / chunk-8 (logs/numerics-20260906-111201/, compare-*.txt) | **Chunk-width dependence is rounding-level at its source and amplified by depth.** Blocks 0-3 bitwise identical; block 4 (GDN) differs by max 3e-8 (rel 1e-9, i.e. 1 ulp) on 3555/5120 values; block 5 2e-6; block 6 1e-3; ~5e-4 relative through the middle; 4e-3 (T=4) / 1.2e-2 (T=8) relative by block 54-62; last block 1.6e-2 / 4.9e-2. Logits: max abs diff 0.49 (T=4) / 0.37 (T=8) with the top-1 unchanged (margins 2.8 / 2.2). Same picture for T=8 vs T=1. So the fused GDN path has a T-dependent reduction order somewhere in the conv/norm/step kernels worth 1 ulp, and the 64-layer network amplifies it to ~1% of the logits, which flips near-ties after 30-200 tokens. Not a verify/KV bug; a bit-exact-across-chunk-widths gate would need identical reduction orders in the GDN conv/norm for T=1 vs T>1 (possible, low value). Practical gate: agreement statistics between K configs on the same prompts, not bitwise text. |
