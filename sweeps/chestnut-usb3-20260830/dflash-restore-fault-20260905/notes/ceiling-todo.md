## TODO — reaching the bandwidth-bound decode ceiling (2026-09-05)

Trigger: an RTX 5090 in an OCuLink eGPU dock serving Qwen3.8-27B at ~200 tok/s flat from 32K to 128K context
(NInfer, NVFP4 + MTP3; llama.cpp Q5_K_M on the same box: 114 -> 72 tok/s). Decode is memory-bound, so the link
(OCuLink 8 GB/s there, USB3 10 Gb/s here) is irrelevant to decode; only the runtime's per-step overhead and the
long-context attention path matter. The arithmetic for both boxes:

| box | HBM/GDDR BW | weight bytes | single-token ceiling | tok/step | multi-token ceiling | measured | efficiency |
|---|---|---|---|---|---|---|---|
| RTX 5090, NVFP4 | ~1.8 TB/s | ~14 GB | ~128 tok/s | ~2.5-3 (MTP3) | ~320-380 | 200 | ~55-60% |
| 7900 XTX, UD-Q4_K_XL (chestnut) | 0.96 TB/s | ~16 GB | ~60 tok/s | 3.08 (MTP) | ~185 | 80 | ~43% |

So ~57% of our step time is NOT weight streaming. Every item below attacks that gap or the numerator; ranked.

- [ ] **Per-step time budget (measure first).** Instrument one decode step end to end and attribute it:
  GPU kernel time (sum of kernel durations from PROFILE=1 / the VIZ trace), host waits on GPU signals over USB
  (count and duration of `AMDSignal._sleep` polls; ~12 sync points/step at ~0.5 ms each was the last estimate,
  the adaptive spin `AMD_USB_SPIN_MS` bought +13%), and host Python (`forward_spec` bookkeeping, tokenizer,
  sampling, the DFlash selector's `.numpy()` round trips). Output: a 3-bar budget per step at T=1 and at the
  spec width. Nothing else on this list should be prioritized before this number exists.
- [ ] **One graph submission per decode step, zero mid-step host round trips.** The MTP path already keeps the
  accept count on the GPU (`forward_spec`: "no Python branch"); DFlash's candidate selector goes to the host
  (`sel_pred/sel_succ ... .numpy()`). Target: main forward + draft + sample + accept + next-chunk build in ONE
  captured graph, one doorbell, one wait. Each removed sync point is ~0.5 ms of a ~37 ms step (~1.3%);
  removing 10 of 12 is worth ~+15%.
- [ ] **Achieved GB/s per GEMV.** For every gemv/gemv_multi variant in the decode graph (T=1..12, q4_K/q5_K/q6_K/
  iq4_xs), compute weight-bytes / kernel-time from the trace; anything under ~80% of 960 GB/s is a kernel
  problem (tile config `gemv_config`: R/U/WG/n_wg per (type, N, K, T)), not a bandwidth one. The DFlash-only
  T=10 variants (`_t10_`) were never tuned separately from the MTP T=6 ones. Also count non-gemv kernel time
  (GDN conv/step, attn_prep/pfd/merge, norms, E_* glue): the "everything else" bar of the budget above.
- [ ] **Shrink weight bytes — every GB is ~6% of decode.** Bandwidth-bound means bytes/step is the ceiling
  itself: UD-Q4_K_XL ~16 GB -> a GDN-aware ~14 GB imatrix quant (see the imatrix item above and
  `qwen38-gdn-quant-20260904`) is +14% ceiling; an EXL3/QTIP-class ~3.5 bpw at ~12 GB would be +33% — IF
  quality holds (AD-IQ3_S did NOT: no faster here and worse output). Measure tok/s AND quality per candidate.
- [ ] **tok/step: MTP_K and DFlash block sweep for acceptance x step cost.** Ceiling scales linearly with
  accepted tokens/step. NInfer gets ~2.5-3 with MTP3; we get 3.08 (MTP) and 3.33 (DFlash XCTX=0, when it does
  not fault — see the restore-path bug). Sweep K / DFLASH_BLOCK / p_min against the per-step cost from the
  budget; wire "adaptive-down speculation" (existing item) so low-acceptance regions do not pay the verify width.
- [ ] **Long-context flatness sweep.** We benchmark ~25-token prompts. Measure decode tok/s at 8K/32K/64K/114K
  KV fill (the "decode vs KV occupancy" item above, never done). The quantized KV (k4+qjl / v4, ~6.8x smaller)
  plus chunked flash-decode (`attn_pfd` CH=256 + `attn_merge_mq`) should hold near-flat like NInfer's
  213 -> 202; find the knee and which kernel bends it (attn_pfd chunk count vs merge cost).
- [ ] **Prefill throughput at 4K-32K.** Theirs: 3.9k tok/s (tensor cores) vs llama.cpp 1.5k. Ours is compute
  bound on the 7900 XTX (123 TFLOPS fp16) and gated by the packed-weight GEMM path + chunk size (PREFILL_T=256,
  AMD_CHUNK); measure tok/s vs prompt length, confirm the GEMM (not gemv) path engages for T > MAX_T, and that
  the USB link carries only tokens (weights/KV stay resident). Long agent contexts are prefill-heavy.
- [ ] **Turn the diagnostic fences back off once the restore-path bug is fixed.** `USB_VERIFY_WRITES=1` (inline
  readback of every host->GPU dword) costs ~15-20% (57-61 vs 72-82 tok/s) and `HCQ_USB_SERIALIZE=1` ~13%;
  both were investigation-era defenses, not fixes. Default them off (or deferred-detect only) and re-measure
  the MTP/DFlash baselines so the ceiling comparison above uses unfenced numbers.
- [ ] **Reference numbers to beat, kept honest.** 5090/NInfer: 158 (1K) / 213 (32K) / 202 (128K) tok/s decode,
  3,904 tok/s prefill at 128K; not apples-to-apples (NVFP4 vs Q5_K_M, MTP3). Our target from the arithmetic:
  ~120-150 tok/s on the chestnut at 3 tok/step (65-80% efficiency) before touching weight size or tok/step.

