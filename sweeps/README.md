# Sweeps — benchmark & investigation archive

Each `sweeps/<name>-<date>/` is one self-contained investigation: a `run_*.sh`
that drives the servers, a `results.csv` (or logs), and often a `README.md` with
the reasoning. **Check this index before running a new benchmark — the answer
may already be here.** All numbers are the AMD RX 7900 XTX (gfx1100), 27B, unless
noted; the fork is served with `DEV=AMD:LLVM LLM_CACHE=1`.

## Index

| sweep | date | question | model | headline result |
|---|---|---|---|---|
| [qwen38-mtp-fork](qwen38-mtp-fork-20260824/) | 08-24 | Bring the fork up at all — which renderer/env? | UD-Q4_K_XL | `DEV=AMD:LLVM` (AMDLLVMRenderer) is **required**; comgr/HIP path fails. First success ~30.7 tok/s. |
| [claimed-benchmark](claimed-benchmark-20260824/) | 08-24 | Fork vs upstream tinygrad vs llama.cpp (verify a claim) | UD-Q4_K_XL | fork MTP-on **73 code / 58 prose**; upstream dense 28/28; llama.cpp 30/25. Fork ~2.6× upstream. |
| [kv-quant](kv-quant-20260825/) | 08-25 | Does KV-cache quant cost tok/s or quality? | UD-Q4_K_XL | Fork 4-bit KV **57.6** vs f32 46.4 prose tok/s — quant is *faster* here. llama.cpp q4/q8/f16 ~all equal. |
| [sampling-sweep](sampling-sweep-20260825/) | 08-25 | temp / top-p / top-k effect on tok/s + quality | UD-Q4_K_XL | Basis for the production `temperature: 0.6` (~+7% decode via MTP acceptance, no quality loss). 47 legs. |
| [agent-cache-reuse](agent-cache-reuse-20260825/) | 08-25 | Does prefix-cache reuse survive prompt edits? | UD-Q4_K_XL | Append reuses ~13.7k tokens (11s); an *edit* invalidates → 0 reuse (39s). Reuse is append-only. |
| [llm-cache](llm-cache-20260825/) | 08-25 | Does the compiled-kernel cache save/load correctly? | UD-Q4_K_XL | Save (run1) then load (run2) verified — the `LLM_CACHE` kernel cache persists across restarts. |
| [prefix-snapshots](prefix-snapshots-20260825/) | 08-25 | Prefix-state snapshot correctness (layered / interloper / reuse) | UD-Q4_K_XL | Test scripts for the production prefix-snapshot feature (recurrent-state checkpoints). |
| [adaptive-spec](adaptive-spec/) | 08-27 | Is adaptive-K speculative decode worth building? | UD-Q4_K_XL | **K=3 is the kernel ceiling** (`attn_decode_mq` asserts `T≤QT=8`). Prose K2→K3 flat, code still gains → build **adaptive-down**, not up. |
| [pre-chestnut-baseline](pre-chestnut-baseline-20260830/) | 08-30 | "Before" snapshot on the M8 + DEG1 OCuLink (PCIe 4.0 x4) | UD-Q4_K_XL | prose 52-53 / code 70-73 tok/s, accept 0.35-0.37 / 0.62-0.66. Paired with the sweep below. |
| [chestnut-usb3](chestnut-usb3-20260830/) | 08-30 | Does moving the 7900 XTX to a tiny chestnut (USB3) cost throughput? | UD-Q4_K_XL | **No — it wins.** At matched `performance` governor: prose 54-58 vs 52-53, code 75-84 vs 70-73 tok/s, over a ~6x narrower link. Found and fixed a **silent copyin data-corruption bug**; full firmware round-trip tooling in `extra/usbgpu/`. |

## Cross-cutting lessons (carried into config/production)

- **`DEV=AMD:LLVM` is mandatory** for the fork's custom kernels — the default
  `AMD` (comgr/HIP-C++) backend can't compile the raw-LLVM-IR kernels
  (`qwen38-mtp-fork`).
- **4-bit KV quant is a win, not a tax** on this card (`kv-quant`) — it's the
  default and frees VRAM; disabling it (`KV_QUANT=0`) is *slower*. Note the
  fork's KV buffer is fixed at `kv_maxc`, so the **MTP=0 / no-quant path OOMs**
  on 24 GB regardless of `--max_context`.
- **MTP (K=3) roughly doubles decode** over dense (73 vs ~28–30 tok/s), and it's
  capped at K=3 by the fused-decode `QT=8` bound (`adaptive-spec`).
- **A prefix snapshot doubles KV cost** (`vram-budget.md`) — KV is 19,200 bytes/token and a
  resident snapshot is a full second copy, so on 24 GB the max context that keeps 1 snapshot is
  **112K (`114688`)**, not the model's 262K. Per-request compute transients are small (~0.2 GB,
  prefill chunked at T=256); the snapshot is the expensive dynamic allocation. Set in the
  chestnut unit + Hermes config.
- **Trust the wire, not the CLI timer** — per-step benchmark lines from the CLI
  are MTP-chunk-unaware and print bogus tok/s; only aggregate / server-log
  numbers are real (`qwen38-mtp-fork` note; see the inference-metrics memory).
- **Prefix reuse is append-only** (`agent-cache-reuse`) — edits mid-prompt drop
  the whole cached prefix.
- **The interconnect is nearly free for decode, expensive for cold start**
  (`chestnut-usb3`) — a 10 Gbit/s USB3 link matches PCIe 4.0 x4 on tok/s once
  weights are resident, but costs ~50 s to upload 16.35 GiB. Judge a dock by
  load time, not throughput.
- **`DEV=USB+AMD` needs a udev rule**, nothing else — no amdgpu, no kernel
  module, no thunderbolt auth, no BIOS changes. The GPU never appears in
  `lspci`; tinygrad tunnels PCIe TLPs over USB and does its own BAR setup.
- **Install `jinja2` before any cross-host comparison** (`chestnut-usb3`) —
  without it `cli.py` silently falls back to a *different* chat template, so
  the numbers look fine and are not comparable.
- **`KV_QUANT` is missing from `cache.py:_ENV_KEYS`** — toggling it against a
  warm `LLM_CACHE` silently reuses kernels compiled for the other setting.
  Re-check `kv-quant`'s conclusions if any leg there reused a warm cache, and
  use `LLM_CACHE=0` when sweeping that flag.

## TODO / experiment backlog (from 2026-08-31 ecosystem survey)

Ideas from surveying community Qwen3.8-27B work. None are blockers; ranked by payoff-per-effort.
We don't need the released artifacts (most are CUDA-only) — the point is to port the *concepts*
into the fork or make our own weights.

- [ ] **Workload-tuned imatrix quant.** The "50 tok/s @ 256K on 24 GB" result (HN 49331607) is a
  quant recipe, not hardware: bulk low-bit + Q5/Q6 for imatrix-sensitive tensors + Q8_0 lm_head,
  calibrated on real user traffic. Needs zero fork changes — llama.cpp `imatrix` + `llama-quantize`
  emit a GGUF the fork already loads. v1: generic calibration mix (agentic coding + chat +
  multilingual, unsloth v3's recipe). v2: re-quant on real traffic from Hermes's
  `~/.hermes/state.db` `messages` table once it has accumulated (~1 day old as of writing, ~6 KB
  of text — need a few MB; the M8's history is gone unless a backup of its state.db turns up).
  Target ~4.5-5 bpw (more bits than UD-Q4_K_XL where they matter, fewer where they don't) —
  NOT the IQ3 class: `newquants-20260828` showed AD-IQ3_S decodes no faster here (52/74 tok/s),
  and Jacob judged its output quality bad in real use. Note UD-Q4_K_XL is already an
  imatrix-calibrated blend (unsloth Dynamic v3); the delta is our calibration data + bit budget,
  so expect a marginal win, not a step change. (2026-09-01: Jacob doesn't need context headroom
  — compaction is fine at 98K, and ctxprobe showed raising the cap costs ~0 tok/s anyway, it's
  just reserved VRAM — so this item is purely quality-at-same-size now. Rank it below the
  speed items above unless quality complaints show up.)
- [ ] **Decode tok/s vs KV occupancy** (never measured — `ctxprobe` varied the *cap*, which
  costs ~0; this is the *fill*). Feed growing prompts, measure gen tok/s at ~10/30/60/90K depth
  on the fork. Purpose: settles the optimal context size / Hermes compaction economy. Hermes
  compacts at ~75% of declared context down to ~50%, so at cap 98K the steady-state zone is
  ~49-74K — sweep THAT range. Model: per cycle, summarize prefills the sampled middle turns
  (NO prefix-cache hit — see the audit below: it's a bare user-role prompt, a different
  prefix; bounded by input sampling) + rebuild prefills ~49K from scratch (~82 s at
  600 tok/s; prefix reuse is append-only). 2026-09-01: in real use compaction fires ~every
  20 min (window fills at prefill speed, not just gen speed), so the overhead is live —
  **decision: raise `--max_context` to 114688 (112K) with the SAME Q4_K_XL** (see
  `sweeps/vram-budget.md`; 131072 was tried first but caused snapshot-pause churn at the 23.77GB
  ceiling — a prefix snapshot doubles KV cost, so 112K is the max that keeps 1 snapshot resident)
  (original 131072 note: fits +0.55 GB KV;
  cache-safe: max_context is in the LLM_CACHE key AND filename, so revert = warm start).
  Window grows ~32K→~50K ≈ compaction every ~31 min. Hermes `context_length` bumped to match.
  NOT via Q3 — permanent quality tax to relieve a recoverable cost is backwards — amortized over the ~25K-token window ≈ 3-8 ms per
  conversation token, vs ~12 ms per *generated* token at 85 tok/s. Key structural fact: with
  ratio-based trigger/floor, T_compact ∝ cap and window ∝ cap, so **amortized overhead is
  independent of the cap** — cap only moves the depth zone (bigger cap = deeper zone = slower
  decode, strictly worse for tok/s; its only benefits are rarer interruptions and less summary
  loss). The real knobs are the trigger/floor *fractions* (overhead ∝ (f_t+f_f)/(f_t−f_f)) if
  Hermes exposes them, and whether the summarize leg actually gets the cache hit (verify in the
  journal when a real compaction fires). 2026-09-01 research verdict on "run to 200K, compact
  back to 50K" (25K fixed prompt + 25K keep): don't. (a) Context rot is universal — Chroma
  measured all 18 frontier models (incl. Qwen3) degrading with input length, distractor
  accumulation compounding it; (b) Qwen3-family RULER falls ~96%→77% from 4K→128K, so a
  75-150K working zone is measurably dumber than 50-75K; (c) LoCoBench-Agent (arXiv
  2511.13998) found 128K-window models with good compaction *beat* 1M-window models on
  multi-session retention — "compression preserving semantic relationships and reference
  chains" beats raw capacity; (d) [RETRACTED 2026-09-01: VRAM is NOT the blocker — the arch
  is hybrid, `full_attention_interval=4`, so only ~16 of 65 layers grow KV (~17 KB/token at
  4-bit): 98K cap ≈ 1.7 GB KV, peak 17.98/24 GB observed, even 196K adds only ~1.7 GB].
  The lever with headroom is summary QUALITY at compaction (structured: task
  state, decisions+rationale, tool results, constraints — LoCoBench compacts at 60% keeping
  first-2/last-3 turns verbatim), not window size. 2026-09-01 code audit of Hermes's live
  compactor (`agent/context_compressor.py`; NOT `trajectory_compressor.py`, an offline batch
  tool): already does all of it — 75% trigger (raise-only floor for <512K windows, cannot go
  lower), head = system + first 3 msgs verbatim, tail = 20% of threshold (~15K) verbatim,
  cheap tool-output prune before the LLM call, structured summary (Goal/Progress/Decisions/
  verbatim Constraints/Resolved-with-answers/Pending-marked-STALE/latest user ask verbatim),
  ITERATIVE summary updates across compactions, truncated summaries rejected. Caveat for the
  economy model: the summarize call is a bare user-role prompt (no system prompt) to the aux
  endpoint = our own server → different prefix, NO cache hit; bounded by input sampling.
  Nothing to tune here. Real compaction
  events, once they start firing, show up as ~90K prefills in the server journal and as
  `compacted=1` rows + timestamps in `~/.hermes/state.db` — the empirical graph accumulates
  on its own.
- [ ] **Restricted MTP draft vocab** (syv-ai/qwen38-27b-rtx3090, +10 tok/s on a 3090): calibrate
  ~40k tokens from our own outputs, have the MTP head score only those. Shrinks the draft
  lm_head gemv — worth more here than on PCIe boxes since the USB path is dispatch-latency-bound.
- [ ] **Int4 GPTQ-calibrated lm_head** (same repo): quantize the 150k-vocab lm_head harder than
  the body; self-made weight + one dequant path in `tinygrad/llm/kernels/`.
- [ ] **Adaptive-down speculation** — the open item from `adaptive-spec` (K=3 is the kernel
  ceiling; drop K when accept is low, don't raise it).
- [ ] **Stock-firmware llama.cpp MTP**: llama.cpp merged `draft-mtp` spec decode (PR #22673);
  `--spec-type draft-mtp --spec-draft-n-max 2` measures +40-85% on 24 GB cards
  (github.com/sudoingX/qwen38-mtp). Would close most of the llama.cpp↔fork gap (tg 32.7 → ~50?)
  next time the dock is in stock mode. Gotchas: gains vanish under ~400-token generations;
  temp >1.0 inverts gains (echoes our accept-0.00 anomaly — a lead if it recurs).
- [ ] **Watch EXL3/QTIP** (turboderp/exllamav3): trellis quantization, best quality-per-bit,
  CUDA-only with ROCm "on the to-do list". Only interesting for us as a concept port (trellis
  decode inside gemv = serious kernel project) or if we ever want 262K context in 24 GB.
- [ ] **Split-KV verify attention** (syv-ai repo): optimizes the batched MTP verify step. Low
  priority — our K=3 verify is small and decode is already DRAM-bound.
- [ ] **Fix the copyin race in FIRMWARE, not just the host guard.** Root cause found in
  `tinygrad/asm2464pd-firmware` `handmade/src/main.c` (~line 250): the 0xF2 handler programs
  the bulk DMA engine (DMA_INIT + NVME_CTRL_DMA_START) and `usb_send_zlp()` acks IMMEDIATELY
  — no engine-idle check before reprogramming, no ready check before the bulk data lands. The
  8051 never touches data bytes (pure hw DMA), so the front-of-window drop is an unsynchronized
  re-arm race; our USB_COPYIN_GUARD just points the race at sacrificial bytes (0.4% bandwidth).
  Proper fix: poll engine idle/complete in the F2 handler before re-arm, ZLP only when armed —
  upstreamable, fixes every chestnut. Alt: F2 IN status read for cheap drain checks; or
  host-only, arm once per large region (sector count is 15-bit ≈ 16 MB, engine takes slot
  ranges) to eliminate most re-arms. Test loop is cheap: build handmade fw (repo has emulator
  + tests), flash over USB in custom mode, `USB_COPYIN_GUARD=0 SIZE=64000000 GMMU=0 DEV=USB+AMD
  python3 test/external/external_test_usb_asm24.py` reproduces in one run; debug-port
  bootloader is the recovery net. Value is upstream-goodness — the guard already works locally.
  RESOLVED 2026-09-02: fixed in firmware and validated. Root cause is a re-arm
  RACE, not arm-readiness: the 0xF2 engine drops the first ~2 sectors when
  re-armed while the previous transfer is still draining. Fix polls C450
  (2=active/0=idle, which stock never checks) idle before arming — 3-line diff,
  `asm2464pd-firmware` branch `fix-f2-arm-race` (squashed to one commit; image
  `fw-backup/tiny-fix-f2-arm-race-*.bin`, dock now runs it). Validated
  USB_COPYIN_GUARD=0, 50x64MiB = 0 corrupt (was ~39/40). THROUGHPUT-NEUTRAL
  (~530 MB/s both; the old 780 was CPU-boost-dependent host dispatch, not fw).
  An earlier post-DMA_START settle did NOT work (ample USB delay already exists).
  Consequently the host-side USB_COPYIN_GUARD was moved off the production branch
  to branch `usb-copyin-guard` (revert c23409c79) — firmware is now the fix.
  Repro dir: fw-backup/iterate-fw-test.sh drives rebuild/flash/reset/test.
  STATUS 2026-09-01: fix written and built — `~/z/asm2464pd-firmware` branch `fix-f2-arm-race`
  (commit 4f5f88ac): no engine ready/status exists (upstream PR #72 confirms), so the F2 handler
  now holds the ZLP through 128 real XDATA reads of 0xCE89 (volatile — non-volatile XDATA_REG8
  got elided to an empty djnz spin) after DMA_START, before the host's bulk data can arrive.
  Built image staged: `chestnut-usb3-20260830/fw-backup/tiny-fix-f2-arm-race-4f5f88ac.bin`
  (product string 'custom 4f5f88ac-CLEAN'). NOT yet flashed. Test plan (server must be stopped;
  pair with the pending 131K restart): (1) repro corruption at guard=0 on ed4e39b7, (2) flash via
  e4 (`chestnut-fw.sh`-style, custom mode — then chip reset: debug-port `debug.py -r -n` if FTDI
  attached, else replug USB-C), (3) re-test guard=0 expecting 0 bad; tune F2_ARM_SETTLE_READS
  up if dirty / down if clean (each read is an XDATA-bus cycle; 128 reads/chunk could cost a few
  % bandwidth — MEASURE vs the guard's 0.4%), (4) only ship guard=0 if fw-fixed AND not slower.

## Tooling (sweeps root)

- `replay.py` — replays recorded requests (`serve.py --record-requests DIR`) for
  deterministic re-benchmarking.
- `tokcache_test.py` — token-cache unit check.

## Elsewhere / not in this dir

- **nt-loads A/B** (nontemporal L2-bypass weight loads) lives on branch
  `perf-nt-loads` (`sweeps/nt-loads/ab.sh`), kept off production: **null result,
  −0.3%** (within noise) on the 27B — decode is DRAM-bandwidth-bound, so the
  L2-bypass hint buys nothing. Don't merge unless re-testing on other hardware.
- **Upstream re-comparison caveat:** current `~/tinygrad` `master` dropped Q3_K
  (ggml type 11), so it can no longer load UD-Q4_K_XL — re-running
  `claimed-benchmark`'s upstream leg against the UD model now fails. Use a pure
  Q4_K_M model (e.g. `bartowski-Q4_K_M`) for a fresh upstream number.
