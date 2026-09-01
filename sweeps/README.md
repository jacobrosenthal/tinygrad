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
