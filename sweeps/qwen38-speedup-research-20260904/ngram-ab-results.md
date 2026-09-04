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
