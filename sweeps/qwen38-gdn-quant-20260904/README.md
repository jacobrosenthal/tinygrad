# GDN-aware imatrix quant experiment — Qwen3.8-27B (setup 2026-09-04)

Goal: build **our own** Qwen3.8-27B GGUF that is quantized *architecture-aware* — protect the
Gated-DeltaNet tensors — using a **broad, diverse imatrix calibration set**. Top-ranked item from the
X ecosystem sweep (`sweeps/qwen38-x-ecosystem-20260904`). The heavy compute is **not run yet**: it
needs a high-precision base and a GPU-free window (the chestnut server is live).

> **Calibration caveat (2026-09-04):** do NOT calibrate the imatrix on Hermes traffic. Hermes is one
> task/domain, so calibrating on it overfits the quant to that narrow distribution and hurts general
> quality. Use a diverse multi-domain corpus. The valuable, non-overfitting idea here is the
> **architecture-aware tensor-type map**, not workload-specific calibration.

## Why (two competing philosophies from the field — we test both)

1. **Ridge / EmperoAI (popular):** keep **GDN state tensors at Q8_0**, GDN mixers at Q4_K, compress
   attention/FFN harder. 27B→11.7 GiB @ 3.7bpw, quality holds, MTP+vision intact.
   (https://x.com/EmperoAI/status/2088638789824508095)
2. **NVFP4 W4A4-everywhere (new research, 2026-09-04):** claims **all 496 linear layers including the
   GDN recurrent layers go to 4-bit** (previously kept 8-16bit) → 17.5 GiB.
   (https://x.com/NewsTongueX/status/2095724966931013932)

They disagree on whether GDN *must* stay high-precision. Our A/B settles it: `gdn-hi` (Ridge-style,
GDN→Q8_0) vs `gdn-lo` (GDN→Q4_K like the rest), **same diverse imatrix**, measure quality + tok/s.

## Prerequisites (not yet satisfied)
- **A high-precision base GGUF** for imatrix: BF16 (~51 GB) or at least Q8_0 (~28 GB) from
  `unsloth/Qwen3.8-27B-GGUF`. We only have `Qwen3.8-27B-UD-Q4_K_XL.gguf` (17.5 GB) locally; imatrix on
  the Q4 is a weak fallback (measures activations on already-lossy weights).
- **A diverse calibration corpus** (NOT Hermes). Use a standard community set:
  - bartowski's `calibration_datav3.txt` (general multi-domain — the de-facto imatrix corpus), or
  - llama.cpp's `groups_merged.txt` / wikitext, ideally augmented with code + math + a little
    multilingual so the imatrix covers the model's real capability surface.
  Fetch to `sweeps/qwen38-gdn-quant-20260904/calib_diverse.txt` (gitignored).
- **A GPU-free window.** `llama-imatrix` on a 27B wants the GPU; running it steals VRAM/compute from
  the live chestnut server. Run when the Hermes batch is idle, or on CPU (slow; pin `-t` to spare
  cores so the server's dispatch latency holds).

## Recipe (recipe.sh)
```bash
LCPP=/home/jacob/z/llama.cpp/build/bin           # has llama-imatrix, llama-quantize, llama-gguf
BASE=/home/jacob/models/Qwen3.8-27B-Q8_0.gguf    # <-- download first (see prereqs)
CAL=sweeps/qwen38-gdn-quant-20260904/calib_diverse.txt   # <-- diverse set, NOT Hermes
OUT=/home/jacob/models

# 1. Inspect tensor names to build the GDN type-map (names vary by converter):
$LCPP/llama-gguf $BASE r | grep -iE 'ssm|delta|conv|state|dt_|a_proj|b_proj|in_proj|out_proj|norm' | sort -u
#   -> identify Gated-DeltaNet tensors (linear-attn conv/state/gate/dt) vs full-attn (attn_*) vs ffn_*.

# 2. imatrix on the DIVERSE corpus (add -ngl 99 only when the GPU is free):
$LCPP/llama-imatrix -m $BASE -f $CAL -o $OUT/qwen38-diverse.imatrix --chunks 400   # -ngl 99 if GPU free

# 3a. gdn-hi (Ridge-style): GDN tensors Q8_0, everything else Q4_K, lm_head/embd Q6_K.
$LCPP/llama-quantize --imatrix $OUT/qwen38-diverse.imatrix \
  --tensor-type ssm:Q8_0 --tensor-type delta:Q8_0 --tensor-type conv:Q8_0 \
  --tensor-type dt:Q8_0 --tensor-type token_embd:Q6_K --tensor-type output:Q6_K \
  $BASE $OUT/Qwen3.8-27B-gdnHI.gguf Q4_K_M

# 3b. gdn-lo (W4-everywhere): no GDN override — straight imatrix Q4_K_M A/B baseline.
$LCPP/llama-quantize --imatrix $OUT/qwen38-diverse.imatrix \
  $BASE $OUT/Qwen3.8-27B-gdnLO.gguf Q4_K_M
```
(Adjust `--tensor-type` substrings to the actual GDN tensor names from step 1.)

## Validation (reuse the existing harness — do not reinvent)
Serve each candidate and run `sweeps/chestnut-usb3-20260830/run_sweep_v3.sh` (3×{prose,code}, 800
tok, temp 0.6, server-log tok/s) plus a quality spot-check, vs the production UD-Q4_K_XL baseline
(prose ~57 / code ~73 tok/s). Success = equal-or-better quality at equal-or-smaller size. GDN-HI is
expected to win quality per Ridge; if GDN-LO matches, the W4-everywhere claim holds and we save bits.

## Status
- [x] Recipe written; tooling verified (`llama-imatrix`, `llama-quantize`, `llama-gguf` all built).
- [ ] Fetch a **diverse** calibration corpus (bartowski calibration_datav3 or equivalent) — NOT Hermes.
- [ ] Download Q8_0/BF16 base.
- [ ] Run imatrix + both quants (GPU-free window).
- [ ] A/B validate on the chestnut harness; pick the winner; optionally serve it.
