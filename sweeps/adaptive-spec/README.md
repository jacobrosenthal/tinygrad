# Adaptive speculative decoding — investigation

Prompted by a llama.cpp-fork result (Qwen3.8-27B: bare 14 → fixed DFlash n=3
41.6 → **adaptive 65.6 tps** at ~96% draft acceptance). Question: worth building
adaptive-K into this tinygrad/MTP fork?

## What the source says (read 2026-08-27)

- MTP spec-decode here is **lossless** and **already tracks acceptance**
  (`self._mtp_accept`, `DEBUG>=1` prints `mtp accept N/M = rate (tok/step)`).
- A "candidates" trick (`cands = [... for L in range(K+1)]` in `forward_spec`)
  already handles variable *acceptance* inside a static JIT graph, and
  `_spec_jits` is keyed per chunk-length T — so multi-shape capture exists.
- **But K is coupled across a step**: it verifies K drafts from the input chunk,
  produces K new drafts, and the chunk-transition length is `L+1+K`. Consecutive
  steps are locked to the same K. True adaptive-K therefore needs `forward_spec`
  split into **K_verify** (previous step's draft count) and **K_draft** (the
  policy's next count) — a real change to the lossless-critical path, not a flag.
- **Ceiling is K≤3** (`2K+1 <= MAX_T`, `MAX_T=8`). The fork's win-direction (draft
  *further*, higher K) needs raising `MAX_T` — a fused-gemv batch change with
  kernel-correctness risk. The sweep's `K5/K7` rows test whether it's even stable.

## Step 1 — MEASURE FIRST (`sweep.sh`)

Do not build the controller blind. Run the sweep in a free GPU window (it loads
the full 27B per config, so stop the production server first):

```
sudo systemctl stop tinygrad-server-splizard
bash sweeps/adaptive-spec/sweep.sh
sudo systemctl start tinygrad-server-splizard
```

It measures decode tok/s (code + prose prompts) and draft acceptance at
MTP_K ∈ {1,2,3} (+ experimental K5/K7 with raised MAX_T).

## Step 2 — decide from the numbers

- **Acceptance ~90%+ at K=3, and K5/K7 load & go faster** → K is under-drafting;
  build toward **higher K** (raise MAX_T, then adaptive pushes K up on code).
  Biggest payoff, biggest effort (kernel).
- **Acceptance splits (code high / prose low), K5/K7 unstable or no faster** →
  build **adaptive-down**: keep K≤3, drop K on low-acceptance turns to stop
  wasting draft compute. Smaller, safe win.
- **K3 already ~= bare and acceptance low** → not worth it on this workload; stop.

## Step 3 — implement (only after Step 2 justifies it)

Sketch, env-gated (`ADAPTIVE_K=1`) so production stays fixed-K:
- key `_spec_jits` by `(T, K)` (both K_verify and K_draft),
- split `forward_spec`'s single `K` into verify/draft counts,
- in `generate`, keep a windowed acceptance EMA and set the next K from it
  (threshold ladder to start; optimal-draft-length formula later),
- the loop's local K must track the draft count that produced the current chunk
  (the verify/transition side), independent of the next draft count.

Bench each candidate with `/home/j/rocm-bench/bench.py` vs the fixed-K baseline;
verify **losslessness** explicitly (greedy output must be byte-identical to
fixed-K at temperature 0) before trusting any speedup.
