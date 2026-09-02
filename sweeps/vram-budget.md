# VRAM budget & max_context sizing — Qwen3.8-27B on the 24 GB RX 7900 XTX

Why `--max_context` is set to **114688 (112K)** and not higher. Derived 2026-09-02 from the
model dims, the KV/snapshot allocation code, and a full trace of per-request (transient)
allocations. Numbers are GiB (2^30) — that is what the server log prints (`Used: X GB`), verified
against the 17.559 GB weight file showing as `16.34 GB`.

## The ceiling

The AM driver takes the card's `vram_size` (24 GiB) minus a 64 MiB reserve, a 32 MiB boot
region, and page tables (`tinygrad/runtime/support/am/amdev.py:225,354,391`) → ~23.9 GiB
nominal. Empirically a 3 MB allocation failed at `Used: 23.77` (the last ~130 MiB is lost to
reserve/fragmentation), so the **practical ceiling is 23.77 GiB**.

## What is persistent vs per-request

Persistent (allocated once at startup, lives for the whole run):

- **Weights:** 16.35 GiB (constant).
- **KV cache:** 16 full-attention layers (of 65 blocks; `full_attention_interval=4`, so blocks
  where `(i+1)%4==0`) × 4 KV heads × `kv_maxc` × **300 bytes/pos** = **19,200 bytes/token**.
  300 = the k4+qjl / v4 quant layout (`amd_gemv.py:KVQuant`, `cache_bytes = hkv·maxc·bytes_per_pos`).
  `kv_maxc = max_context + MAX_T(8)`. The full buffer is allocated up front regardless of fill.
- **Recurrent state:** 49 GatedDeltaNet blocks' conv_state + recurrent_state, constant ~0.16 GiB
  (does NOT scale with context).
- **Dequant weight pool + framework + page tables:** ~2.4 GiB (fixed).

Base (everything persistent except KV) ≈ **19.08 GiB** including one resident snapshot's fixed
part; see the fitted equation below.

Per-request TRANSIENT (freed after each forward) — traced through the serve/model code:

- **Prefill is chunked at `PREFILL_T = 256`** (`amd_gemv.py:533`, `model.py:838`), so activations
  scale with T=256, NOT prompt length. A 130K prompt is ~510 chunks. Peak live activations
  ~0.2 GiB (dominated by two `256×17408×4` FFN gemm outputs; memory-planned + gc'd per block,
  `model.py:646-650`).
- **Prefill logits: last token only** (`model.py:541,652`) = `1×vocab×4` ≈ 0.6 MB. It avoids the
  `256×vocab` (155 MB) matrix on purpose.
- **Attention is flash-tiled** (`amd_prefill.py:304`) — no `T²×context` score matrix.
- **Decode/MTP (K=3):** verify batch capped at `2K+1=7` tokens; logits `((2K+1)+K)·vocab·4` ≈ 6 MB;
  all spec-decode buffers < 10 MB.
- **Peak compute transient ≈ 0.2 GiB.** Serving itself is cheap; it is NOT the constraint.

## The snapshot is the expensive dynamic allocation

A prefix snapshot (`model.py:936-957`, `serve.py`) is a **full copy of the KV cache + recurrent
state ≈ KV(ctx) + 0.6 GiB**. So **one resident snapshot doubles the KV cost → 2×KV(ctx)**. That
is what made 131K fail.

Save/restore can momentarily allocate a *second* copy (`serve.py:157-171` appends
`model.snapshot_state()` before evicting the old slot). When that does not fit, the server
degrades **gracefully** — `prefix snapshots paused 600s: Allocation of N MB failed` — and keeps
serving; it does not crash. `PREFIX_SNAPSHOTS` default = 1 resident (extras go to host RAM via
`--host-snapshots`, not VRAM).

## The budget equation and the 112K answer

    weights 16.35 + fixed ~2.7  = 19.08  base
    + 2·KV(ctx)                          [live KV + 1 resident snapshot]
    + 0.2                                [peak compute transient]
    ≤ 23.77  (practical ceiling)

Fitted against the empirical anchors (98K ran for days safely; 131K = `Used 23.77`, OOM churn):

| max_context | KV(ctx) | steady w/ 1 snapshot | serving margin | verdict |
|---|---|---|---|---|
| 98,304 | 1.76 | 22.60 | 1.17 | safe; snapshots never rebuild |
| 106,496 (104K) | 1.90 | 22.89 | 0.88 | safe, conservative |
| **114,688 (112K)** | **2.05** | **23.18** | **~0.4** | **max — serving safe; rare graceful snapshot rebuild** |
| 131,072 (128K) | 2.34 | 23.77 | ~0 | constant snapshot churn — DO NOT USE |

**Set to 114688 (112K).** Serving never OOMs there (compute transient ~0.2 GiB ≪ 0.4 GiB
margin). Only the optional snapshot swap can occasionally pause+rebuild under pressure, which is
graceful. For zero snapshot churn instead, stay ~98-104K. Above 112K the steady 1-snapshot
footprint eats the fragmentation margin and serving itself becomes fragile.

Because each token costs KV **twice** (live + snapshot), context is expensive on 24 GB: 112K is
only +17% over 98K. Getting meaningfully more context would require a smaller KV quant (k2/v2),
disabling prefix snapshots (loses the multi-turn speedup), or a bigger card.

## Keep in sync

`--max_context` lives in three places — change all together:
1. `tinygrad-server-chestnut.service` (`--max_context`)
2. Hermes `~/.hermes/config.yaml` (`models.qwen-27b.context_length`)
3. this doc's table

Each change is a fresh `LLM_CACHE` namespace → one ~9-min cold compile on next restart.
