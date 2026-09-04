# How to up our tok/s — speedup research + implementable kernel levers (2026-09-04)

Deep research pass (X + papers/repos) answering "how do we go faster, text-only, on the 7900 XTX
over the chestnut USB dock." Grounded in **our own kernels** (`tinygrad/llm/amd_gemv.py`,
`amd_prefill.py`, `dflash.py`, `model.py`) so the recommendations are real targets, not generic.

## The frame: we are already at the single-stream memory-bound ceiling

Single-stream decode reads every weight byte once per token, so **tok/s ≈ mem_bandwidth / model_bytes**
(field consensus; @bountyAIhunter did the exact math: 5090 @ 1792 GB/s ÷ 17.0 GB Q4 = 105 tok/s
ceiling — https://x.com/bountyAIhunter/status/2090057258423971911). For us:

> **7900 XTX = 960 GB/s ÷ ~17 GB (Q4_K) ≈ 56 tok/s single-stream ceiling.**

Our ~57 prose is **already at that ceiling** — `amd_gemv.py` streams weights at DRAM bandwidth via
fused `v_dot4_i32_iu8` (dequant fused into the dot, no separate unpack pass), so the GEMV itself is
essentially optimal. Our ~73 code comes from MTP accepting >1 token/weight-read. **So there is no
"tune the GEMV" win left.** Only two physical levers remain:

- **(A) read fewer bytes/token** → lower-bpw (and text-only) weights raise the ceiling.
- **(B) emit >1 token per weight-read** → better speculative decode (more accepted tokens/step).

Everything below is one of those two.

## What we already have (don't rebuild these)
- **DFlash2 block-diffusion drafter** — `dflash.py` implements it (GroupedConv two-tap, non-causal
  block attention, top-k candidate selector; GGUF `general.architecture = dflash`). This is the
  field's current best lossless drafter (z-lab, arXiv 2602.06036). We're **not behind** here.
- **MTP** native head (K≤3, capped by the fused-decode `QT=8` bound per `adaptive-spec`).
- **Bandwidth-optimal fused-dequant GEMV** for q4k/q6k/q8_0/iq4nl (`v_dot4_i32_iu8`).
- **GDN / linear-attention kernel** (`gated_delta_prefill` + SSMConfig). We hit 57 tok/s, not the
  10-15 tok/s some AMD users get with unfused DeltaNet kernels (@abzi_ai) — our GDN path is healthy.

## Ranked implementable levers (ROI × fit-with-tinygrad)

### 1. N-gram / prompt-lookup speculative decode — HIGHEST ROI, we DON'T have it
**Lever B, nearly free.** No draft model: keep a rolling map of n-grams from the prompt + generated
context; when the last few tokens match, propose the recorded continuation as draft tokens; verify
with the model (reuse our existing MTP/DFlash verify path). Zero regression on free-form (unmatched →
falls back to normal decode), and it composes *on top of* DFlash2/MTP.
- **Why it's huge for us specifically:** our workload is agentic coding (Hermes) — full of repeated
  spans, patches, echoed file contents. That's exactly where lookup wins:
  - @johnc2k, single 3090, `--spec-type draft-mtp,ngram-simple`: **70 → 230 tok/s (3.3×)** on
    output-echoes-input, zero free-form regression (https://x.com/johnc2k/status/2091141427719778802).
  - LoopSpec (n-gram + DFlash2 + adaptive gate): **64 → 229 tok/s** at 255K on exact-copy
    (https://x.com/shipfrontierai/status/2093731134114856966).
  - @farleythecoder "zero-weight prompt-lookup" on Apple: **+41–83%** on reusable-context workloads.
- **tinygrad implementation:** pure host-side draft proposal + our existing verify kernel. Maintain a
  suffix→continuation table over the KV'd context; propose the longest match each step; feed as the
  draft block to verify. **Batch all lookups before the decode step** (kysstalol: serialized lookups
  become the bottleneck — https://x.com/kysstalol/status/2094668280506273940). Gate it (only when a
  match ≥ threshold) so free-form prose isn't slowed.
- **Expected:** little/no gain on prose, but **2–3× on code/agentic/tool-echo** turns — the bulk of
  Hermes traffic. Small, self-contained, no new weights.

### 2. Lower-bpw quant — raises the single-stream ceiling
**Lever A.** We're at the Q4 ceiling (~56); dropping to a good **~3.5 bpw** takes model bytes ~17 → ~12.5
GB, so the ceiling rises to **960/12.5 ≈ 77 tok/s** single-stream — before any spec-decode.
(Correction 2026-09-04: the served UD-Q4_K_XL GGUF has **zero vision tensors** — confirmed, no
`v.blk`/`mm.`/`merger`; vision in llama.cpp lives in a separate `mmproj-*.gguf` we never load. So
we're *already* text-only and there is NO vision VRAM to reclaim by "text-only" quantizing — the win
here is purely the lower bpw. Qwen3.8 image+video share one ViT+projector, so they can only be
dropped/kept together, and only via the mmproj file, which is already out of our path.)
- Field proof low-bpw holds quality *and* is faster: MiaAI_lab **EXL3 3.5bpw** on a 4090 = 130–150
  tok/s; Ridge **3.7bpw** GDN-aware holds quality. New research even puts NVFP4 **W4A4 on all layers
  incl. GDN** at 17.5 GiB (NewsTongueX).
- **tinygrad implementation:** the GDN-aware GGUF from `sweeps/qwen38-gdn-quant-20260904` (GDN state
  tensors Q8_0, rest Q4_K/IQ4) but **text-only** (strip vision), diverse calibration (NOT Hermes).
  `amd_gemv.py` already loads q4k/q6k/q8_0/iq4nl, so a mixed IQ4/Q4_K/Q8_0 GGUF loads as-is — this is
  mostly a quantize-and-serve, not a kernel change. If we want sub-4bpw beyond IQ4, that needs a new
  GEMV format (trellis/EXL3-style) — bigger lift, defer.
- **Expected:** single-stream ceiling ~56 → ~70–77; plus VRAM headroom → bigger MTP/DFlash trees or
  more concurrent slots.

### 3. Tune / de-limit our DFlash2 — we have it but it's throttled
`dflash.py:66` notes *"keep the last fused target row as a single context K/V (full 4k draft cache
hangs the GPU)."* That's a workaround that likely caps our accepted-tokens/step below the field's
DFlash2 numbers (they report accept length ~3–5, up to 3.4× e2e).
- **Targets:** (a) fix the draft-cache-hangs-GPU limitation so DFlash2 keeps a real draft KV window
  (this is the same "large USB copyin / GPU-hang" family we already understand — worth a focused look);
  (b) sweep DFlash2 block size / `num_speculative_tokens` (field uses 7) and the selector top-k;
  (c) consider a **DSpark-style acceptance-probability head** — DSpark adds a per-token accept-prob
  prediction to build better draft trees, +32% over MTP lossless (Matthewrogers). Our selector could
  learn/estimate accept-prob to prune the tree.
- Refs: z-lab/dflash (github), incoai & z-lab `Qwen3.8-27B-DFlash2` (HF; GGUF drafter exists to
  compare against ours), LMSYS "DFlash and Spec V2" blog. llama.cpp merged it as PR #27342.

### 4. GDN decode-step kernel fusion (FlashQLA-style) — check, then maybe fuse
Qwen's own **FlashQLA** fused GDN kernels get **2–3× forward** over the FLA Triton kernels via
operator fusion + gate-driven context parallelism + warp-specialized fused kernels
(https://qwen.ai/blog?id=flashqla; `fla-org/flash-linear-attention`; GDN-2 arXiv 2605.22791; NVIDIA
cuDNN GDN-2 support). Our `gated_delta_prefill` handles prefill; the **decode-step recurrent update**
(per-token state update over the 48 GDN layers) is the thing to profile. If it's not fully fused
(LayerNormGated fused, small headdim path), fusing it removes per-step overhead. Only worth it if a
profile shows the GDN decode step is a non-trivial slice of our per-token time — likely secondary to
levers 1–3 since we're already at the GEMV ceiling, but it's the one pure-kernel win with a known
recipe.

### 5. EAGLE-3 trained drafter — highest ceiling, longest lead
EAGLE-3 (arXiv 2503.01840): direct token prediction + multi-layer feature fusion + "training-time
test" (feed draft output back into draft input during training → robust to its own errors); scaling
law = more training data → more speedup, up to **6.5×**. Open training framework: **SpecForge**
(arXiv 2603.18567). Bigger than DFlash2 for peak accept, but needs a training run. Our DFlash2 already
captures most of the lossless spec-decode benefit, so this is a "later, if we want the last 30%" item.

## Suggested order of attack
1. **N-gram lookup drafting** (small, free, 2–3× on our actual code/agentic traffic) — do first.
2. **Text-only ~3.5bpw GDN-aware quant** (ceiling 56→~77, frees VRAM) — the `qwen38-gdn-quant` job,
   text-only, once a GPU-free window exists.
3. **De-limit + tune DFlash2** (fix the draft-cache cap, sweep block/top-k, maybe DSpark accept-head).
4. Profile the **GDN decode step**; fuse if it's a real slice.
5. **EAGLE-3 / SpecForge** only if we still want more after 1–4.

## Sources
X: @bountyAIhunter (bandwidth math), @johnc2k / @shipfrontierai / @farleythecoder (n-gram lookup),
@yume_arasaki / @analogalok / @stretchcloud / @vincentzed_cuda (DFlash2 mechanism + numbers),
@Matthewrogers (DSpark), @pupposandro (Lucebox R9700 227 tok/s w/ DFlash2), @abzi_ai (AMD DeltaNet
kernel pain), @sudoingX (AMD A/B repo). Papers/repos: DFlash arXiv 2602.06036 + z-lab/dflash;
EAGLE-3 arXiv 2503.01840; SpecForge arXiv 2603.18567; GDN-2 arXiv 2605.22791; FlashQLA
(qwen.ai/blog?id=flashqla) + fla-org/flash-linear-attention; Tencent AngelSpec (full-stack spec
decode). MindStudio/HackerNoon DFlash2 explainers; LMSYS DFlash/Spec-V2 blog.
