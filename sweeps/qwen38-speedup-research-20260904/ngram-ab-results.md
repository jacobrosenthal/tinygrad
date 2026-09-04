# n-gram / prompt-lookup drafting — A/B result (2026-09-04)

Wired NgramProposer into `Transformer._generate_spec` behind `NGRAM_DRAFT` (commit b15834867).
Same-dock warm A/B, Qwen3.8-27B UD-Q4_K_XL over the chestnut, 800 tok, temp 0.6, dev .venv:

| task  | baseline (NGRAM=0) | NGRAM=1      | Δ      | n-gram % of steps |
|-------|--------------------|--------------|--------|-------------------|
| prose | 56, 56 tok/s       | 47, 50 tok/s | −12%   | 3–5%              |
| code  | 76, 76 tok/s       | 65, 66 tok/s | −14%   | 13–14%            |
| echo  | 69, 69 tok/s       | 61, 65 tok/s | −9%    | 16–22%            |

accept/tok-step was ~unchanged (e.g. echo 2.56 baseline vs 2.6–2.8 n-gram): the lookup drafts do
NOT land more tokens than MTP. Lossless (verify guarantees), just slower.

## Why it lost (both must be fixed for n-gram to pay off)
1. **K=3 draft cap.** Our fused MTP verify allows only K drafts with `2K+1 <= MAX_T=8`, i.e. K<=3.
   n-gram's entire advantage is proposing LONG exact runs on a match (llama.cpp `ngram-simple` uses
   n_max 7–16 → 3.3x). Capped at 3 it proposes no more tokens than MTP, so there's zero throughput
   gain to offset its cost.
2. **Per-step Python overhead.** `extend`+`propose` run every decode step (~2080 for 800 tok); the
   dict-indexing and suffix search add latency the ~15 ms/step decode budget can't absorb — hence a
   loss even on prose where it barely fires.

## What would make it a win (the real, bigger item)
- A **wide exact-match verify path**: on a confident n-gram match, verify 8–16 drafts in ONE target
  pass, decoupled from the QT=8 fused-MTP bound (a separate verify kernel/jit that isn't the MTP
  chained-draft path). This is where the field's 3.3x comes from.
- Move the proposer **off the per-step hot path**: a C-speed suffix automaton, or only probe when a
  cheap heuristic says a long match is likely, or amortize indexing.

Kept `ngram_draft.py` + the wiring flag-gated OFF (one None-check/step cost) as the scaffold for that.

## Takeaway
The "free" n-gram win doesn't exist under our K=3 fused verify — it needs the wide-verify kernel work
first. Lower priority than lever #2 (lower-bpw quant: raises the single-stream ceiling 56→~77 with no
per-step overhead and no kernel rewrite). Re-ranking accordingly.

---

## MAX_T / QT depth sweep (2026-09-04) — can we lift the K=3 cap?

Made `attn_decode_mq`'s query-tile configurable (`ATTN_QT`, commit cdddd2188) and swept it with matching
`MAX_T`/`MTP_K`, same dock, 800 tok, temp 0.6:

| MAX_T/QT / K | result |
|---|---|
| 8 / 3 (baseline) | prose 55–57, code 69–77, echo 69–70 tok/s ✓ |
| 16 / 7 | **CompileError: local memory (76288 B) exceeds** (RDNA3 LDS = 64 KB) |
| 32 / 15 | **CompileError: local memory (135424 B) exceeds** |
| 16/7 + ngram, 32/15 + ngram | same LDS-exceed failures |

**Finding: K=3 is a hardware LDS wall, not a soft cap.** The flash-decode kernel holds per-query-row
attention state in shared memory; its LDS footprint scales with `QT*G`, and QT=8 already sits near the
64 KB RDNA3 budget. QT=16 → 74 KB, QT=32 → 132 KB — neither compiles. So `assert T <= QT` with QT=8 is
the kernel *fitting the GPU*, and every spec-decode idea that wants more than 3 drafts/pass (deeper MTP,
wide-verify n-gram, DFlash2 blocks) is blocked by the same wall.

**Lifting it = a real kernel rewrite** (smaller KV tiles + more passes, or an accumulator layout that
doesn't keep all QT rows resident in LDS) — days of work, uncertain payoff (MTP accept decays with
depth; wide n-gram only helps echo turns). **Poor ROI vs lever #2 (lower-bpw quant)**, which lifts the
single-stream ceiling 56→~77 on every turn with no kernel work and no LDS wall.

## Re-ranked
1. **Lower-bpw quant (#2)** — guaranteed ceiling lift, no kernel work. DO THIS.
2. **Lower-LDS flash-decode kernel rewrite** — the real unlock for all spec-decode depth, but it's a
   rewrite; revisit only if #2 isn't enough and there's appetite for kernel work.
3. n-gram wide-verify — blocked on #2-of-this-list (needs the LDS rewrite to exceed K=3).
