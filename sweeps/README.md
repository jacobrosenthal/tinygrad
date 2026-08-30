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
| [chestnut-usb3](chestnut-usb3-20260830/) | 08-30 | Does moving the 7900 XTX to a tiny chestnut (USB3) cost throughput? | UD-Q4_K_XL | **No — parity.** Within ~5% of the OCuLink baseline on wall time, same accept rates, over a ~6x narrower link. Found and fixed a **silent copyin data-corruption bug**. |

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
