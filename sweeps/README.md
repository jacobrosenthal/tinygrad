# Sweeps — benchmark & investigation archive

Each `sweeps/<name>-<date>/` is one self-contained investigation: a `run_*.sh`
that drives the servers, a `results.csv` (or logs), and often a `README.md` with
the reasoning. **Check this index before running a new benchmark — the answer
may already be here.** All numbers are the AMD RX 7900 XTX (gfx1100), 27B, unless
noted; the fork is served with `DEV=AMD:LLVM LLM_CACHE=1`.

## Index

- `chestnut-usb3-20260830/dflash-restore-fault-20260905/` — the DFlash first-decode-step GCVM fault: trigger = LLM-cache RESTORE
  (6/6 restores fault on req 1, 0/6 warmups; any source edit turns the next launch into a warmup). Full chronological test log,
  hang reports, wave dumps, ISA, negatives (per-call writes, kernargs, hw_page, small-copyin repro all clean). See its README.
- `chestnut-usb3-20260830/repro-f2-rearm/` — 800 back-to-back 8-16 KiB uploads: 0/800 corrupted on ed4e39b7 (regression control).
- `chestnut-usb3-20260830/repro-scratch-regrow/` — UPSTREAM package for the scratch use-after-free: `repro.py` (custom_kernel + hand
  LLVM IR, 260 B -> 2052 B private segment, jit replay after regrowth) and the note. Clean commit to cherry-pick: **eec5fcb97** (validated on KFD 09-06 10:50: the bound-queue unittest fails without the fix with 4096 corrupted words on the freed range and passes with it; the TinyJit form does not reproduce because hcq2 rebuilds packets per replay) on
  branch `upstream-scratch-keep-old` in ~/z/tinygrad-master (6-line fix in `_ensure_has_local_memory` + `test/test_scratch_regrow.py`).
  
- `chestnut-usb3-20260830/gemv-spillfree-20260906/` — OFFLINE register-pressure probe of the batched gemv (clang -> LLVM -> gfx1100
  ELF notes, no GPU): only the K4 formats spill (q5k 5120x6144 from T=7: 31/145/201 VGPRs at T=7/10/12), i.e. already in the
  production K=3 chunk. Fix on branch `gemv-spillfree` (token-grouped x staging, `GEMV_TG`): 0 spills to T=10. On-device sweep queued.
- `chestnut-usb3-20260830/usb4-kfd-20260906/` — **DONE 09-06 09:36: KFD over the USB4 tunnel = 92 tok/s vs 82 USB3 (+12%), weights load
  in 6 s (3 GB/s), server up in 59 s.** The tunnel dropped every time on 09-05 and at 09:17 (runtime PM: "lost during suspend");
  fixed with amdgpu.runpm=0 + udev rules pinning the TB host/root ports/GPU power/control=on (etc/); KFD's dead topology nodes after
  hot-unplugs (EINVAL on /dev/kfd) need a reboot or amdgpu reload (the AMD card is taken off seat0 so rmmod works). DEV string is
  `KFD+AMD:LLVM`. PROFILE: the 35 ms step is 100% GPU busy, 84% gemv, 20.65 GB/step (lm_head read 3x for the MTP drafts),
  705 GB/s average; the 5120x6144 out-proj class runs at 423 GB/s (spill/VGPRs). Plan for the remaining ms in the README.
- `chestnut-usb3-20260830/draft-vocab-20260906/` — **MTP_DRAFT_VOCAB=65536: 89.6 tok/s vs 82.8 on KFD (+8%), acceptance unchanged**
  (the K=3 draft passes read a 64k-row prefix of the lm_head instead of 248k; branch gemv-spillfree). 32k loses acceptance, 128k saves
  less. Levers sweep: GEMV_TG and FAST_ARGMAX neutral at K=3. New production candidate: KFD + dv64k + penalty 1.0 = ~90 tok/s.
- (superseded) `usb4-kfd-20260906` plan for the #1 comms option: flash the shipped USB4 firmware back, run the GPU as a
  native PCIe device under amdgpu/KFD (`DEV=AMD:KFD`); journal proves it worked on this host on 09-05 15:40-16:06. Needs the user
  (flash + replug). Expected 80 -> 120-145 tok/s.
- `chestnut-usb3-20260830/bitexact-20260906/` — greedy bit-exactness gate: plain (MTP=0) vs MTP K=3 vs DFlash block 6 on 8 prompts x
  400 tokens. Queued behind the GEMV_TG sweep (chain2).
- `chestnut-usb3-20260830/usb-transfers-20260906/` — MEASURED: **~540 libusb submits per decode step** (MTP K=3; 2.5x the code-derived
  190-240); logging did not change tok/s. USB traffic is the dominant per-step cost: the case for USB4/KFD and for one-graph-per-step.
- `chestnut-usb3-20260830/gemv-spillfree-20260906/` on-device: GEMV_TG=4 default = K=3 74.7 -> 75.2 (noise), K=5 67.2 -> 70.4 (+4.8%).
  Merge candidate. K=5 still trails K=3 (per-step cost at T=11 dominates).
- `chestnut-usb3-20260830/dflash-restore-fault-20260905/` selector sweeps: the eager tinygrad-op selector (DFLASH_EAGER_SEL) runs at
  4-5 tok/s (~150 launches/step, 950-1180 s restores) but PROVES the acceptance: block 8 + K=7 + selector 3.52 tok/step (argmax
  drafts 2.46-2.92). Block 8 needs MAX_T=16 (fine at 8K ctx). Without selector DFlash (62) loses to MTP K=3 (75).
- `chestnut-usb3-20260830/dflash-selector-20260906/` — the fix: selector as two custom kernels inside the spec graph (branch
  gemv-spillfree c9a53aa96, `DFLASH_SEL=1`), codebooks read from Q4_K bytes. Correctness test + throughput sweep queued (chain6).
- `chestnut-usb3-20260830/bitexact-20260906/` RESOLVED: every K / DFlash pair diverges (0/8 identical) because the fused GDN path
  differs by 1 ulp between T=1 and T>1 at block 4 and the 64-layer stack amplifies it to ~1% of the logits (top-1 stable, near-ties
  flip after 30-200 tokens). Not a verify/KV bug; MTP=0's generic path OOMs at 8K ctx. Gate = agreement statistics, not bitwise text.
- `chestnut-usb3-20260830/dflash-restore-fault-20260905/` sampling sweep (09-06 01:01-01:49, README "Sampling sweep"): official
  thinking settings (temp 1.0/top_p .95/top_k 20) 61 tok/s vs greedy 75 (-18%) through acceptance; temp 0.6 + top_p/top_k 66 (-12%);
  the sampler RNG is seeded identically per process (restores are not independent samples). Rerun of the collision-lost legs
  (02:16-02:43): production's `--repeat-penalty 1.15` costs ~4.5% (71.0 vs 74.2 tok/s at temp 0.6, 2.67 vs 2.85 tok/step);
  temp 0.6 + penalty 1.0 = greedy within noise. Deploy decision: drop or lower the penalty.

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
- [x] DONE 09-06 (MTP_DRAFT_VOCAB=65536: +8% on KFD, acceptance unchanged; merged) — **Restricted MTP draft vocab** (syv-ai/qwen38-27b-rtx3090, +10 tok/s on a 3090): calibrate
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
- [x] **FIXED 2026-09-02: large-copyin SDMA hang.** Large single
  copyins (a ~2.3GB prefix-snapshot restore = ~9000 chunks) hang DURING serving with `GPU failed
  to drain USB copyin chunk N (10s)` — reproduced 2026-09-02 by a 900-line-disassembly review
  prompt and by deep-context Hermes turns. Root cause (analysis, unvalidated): the drain's
  fence-read control-IN (0xE4) interleaves with an in-flight F2 bulk transfer and abandons it
  (`ops_amd.py:707` warns of exactly this; firmware PR #73), so a chunk's sentinel never lands and
  the GPU POLL_EQ spins forever. NOT ring overflow — the queue ring grows to fit (`ops_amd.py:408`).
  Startup weight-load is immune (hundreds of SMALL per-tensor copyins, ~800 chunks each). Candidate
  fix: wait for BOTH windows' inflight F2 before any wait_drain fence read (code only waits one
  window today, ~line 705), or move the fence to the 0xF0 read path. WORKAROUND SHIPPED:
  `USB_SAFE_COPYIN=1` in the chestnut unit (serialized copyin, no drain step; ~250 vs 530 MB/s on
  load + snapshot-restore only, tok/s unaffected). Needs a device-window — each test hangs the GPU
  (FTDI-reset to recover); validate against the 900-line reproducer AND the corruption repro. RESOLVED: reproduced deterministically (2GB=8192-chunk
  copyin hangs at chunk 7199, SDMA_QUEUE_HANG(55), read_ptr stalls mid-ring; 1GB/4096 chunks is
  fine) -- it is the SDMA engine choking on an oversized single ring, NOT the fence/F2 race. Fix
  (`ops_amd.py` _copyin): cap each SDMA ring at USB_COPYIN_GROUP=4096 chunks and fully drain
  between groups; seq/windows carry across. Validated: 2GB+3GB no longer hang, 1.5/2/3GB random
  roundtrips = 0 corruption, ~640 MB/s (throughput preserved, even improved). USB_SAFE_COPYIN
  workaround removed from the chestnut unit; fast path restored.
- [x] SHELVED 2026-09-06 (not needed: the 'wild write' was the host-side scratch use-after-free; 0/800 corruptions and 0 dropped dwords on the current firmware; branches fix-f0-arm-race / fix-f0-f2-arm-race kept unflashed) — **Fix the copyin race in FIRMWARE, not just the host guard.** Root cause found in
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

## Re-audit after the scratch-regrowth root cause (2026-09-05, see chestnut-usb3-20260830/dflash-restore-fault-20260905)
The "wild write" was tinygrad's AMD scratch buffer being freed/reallocated on regrowth while graphs keep the old base baked
in. It fires whenever a graph is built BEFORE a heavier-spilling kernel is compiled (LLM-cache restore, a new spec width,
a new chunk shape, XCTX). Fault-motivated items re-judged against that:
- [ ] REVERT `e0faf3771` HCQ same-queue serialize (~13% tok/s) and default `USB_VERIFY_WRITES=0` (`c9df7365f`, 15-20%):
  both targeted mechanisms now disproven (0 dropped host->GPU writes in ~1e5 verified). Keep deferred verify as a detector.
- [ ] REMOVE the attn_prep parking guard (`70bb76cea`, debug only).
- [ ] RE-TEST DFlash XCTX>0 (`4b5c43f7e` was shelved for "dflash decode faults" = this bug; XCTX=16 measured slightly faster).
- [ ] RE-TEST wide speculative verify (larger MTP_K / MAX_T): the 2026-09-04 "device hang" that gated it matches this trigger
  (new T variants compiled after the base graphs). Also K=4-5 within MAX_T=12 with ATTN_QT=8.
- [ ] KEEP `4218a224b` (KV/rope pad by MAX_T): the 08-26 "MMU fault at start_pos 98301" may have been scratch, but a chunk at
  the ceiling does overrun; slack rows are free. Annotate, do not revert.
- Independent, untouched: adaptive spin `1f3d594dc` (perf), hang hardening `bfa54552b`, all diagnostics, the copyin/C450
  work (data-only repro, genuinely copyin), the F0 firmware fixes (latent, never observed).
- Measurement plan (restored instances = the once-faulting config): DFlash XCTX=0/16 vs MTP K=3/4/5, 8 long requests each,
  logs under dflash-restore-fault-20260905/logs via restore_cycle.sh (never truncates).

## Sweeps + implementation backlog toward the ceiling (2026-09-06, after the scratch fix)
Sampling (official Qwen3.8 card: thinking temp 1.0 / top_p 0.95 / top_k 20 / min_p 0 / presence 0 / repetition 1.0;
instruct 0.7 / 0.80 / 20 / presence 1.5. Production: client temp 0.6, no top_p/top_k, `--repeat-penalty 1.15`):
- [ ] **Repeat-penalty 1.15 vs 1.0 at temp 0.6** — never swept; the card says 1.0; a repetition penalty reshapes the verify
  row away from the drafter's distribution (costs acceptance) and hurts code/structured output. `perf_sweep2.sh`.
- [ ] **Official thinking settings (1.0/0.95/20) vs 0.6/0.95/20 vs 0.6-bare** with MTP AND DFlash — the 08-25 sweep was MTP
  only; DFlash's acceptance-vs-temperature curve is unmeasured and likely steeper (block drafts + exact verification).
- [ ] **Instruct settings (0.7/0.80/20, presence 1.5)** as the non-thinking row; the card warns presence>0 can mix languages.
- [ ] **Benchmark protocol:** report two rows always — greedy (temp 0, what tok/s tables like llama-bench use) and the
  production sampling row. Our sweeps so far are greedy => optimistic for every drafter.
Other sweeps (each restored-instance, `restore_cycle.sh`/`perf_sweep.sh` style, logs never truncated):
- [ ] DFlash: XCTX {0,16,32}, DFLASH_BLOCK {4,6,8}, p_min; MTP_K with adaptive-down; ATTN_QT; JIT_BATCH_SIZE (graphs per step);
  AMD_USB_SPIN_MS; context depth 8K/32K/64K/114K; concurrency 1-4 (knee ~3 measured before); GDN-aware imatrix quant.
Implementation / refactor (per-step budget first — measure before building):
- [x] DONE 09-06 (GEMV_TG, merged dfe59dd70; +4.8% at K=5, neutral at K=3) — **Spill-free gemv configs for T>=9.** The t10/t11 variants spill to scratch (private segment up to 524 B/thread, 195
  scratch ops in the q5_K o_proj) = VRAM round trips per spilled value. That is the likely reason MTP K=4/5 and DFlash T=10
  gain tok/step but lose tok/s (K=5: 3.73 tok/step, 69-75 tok/s). Retune gemv_config (R/U/XP) per T to fit registers.
- [x] MOOT on KFD 09-06 (the 35 ms step is 100% device-busy; USB3 launch gaps were ~3 ms) — **One graph per decode step.** A step is 4 graphs (64/128/256/323 calls) = 4 doorbells + 4 timeline waits over USB
  (~0.5 ms each); JIT_BATCH_SIZE / graph_split.
- [x] DONE 09-06 (fused in-graph selector, DFLASH_SEL; DFlash still loses to MTP K=3: 74.4 vs 82.2 on KFD) — **DFlash selector on GPU** (`sel_pred/sel_succ ... .numpy()` are host round trips inside the step).
- [ ] **Restore path: create all programs before linking graphs** (also makes the scratch final before any base is baked;
  belt-and-braces on top of AMD_SCRATCH_KEEP_OLD). **Upstream:** grow the scratch mapping in place.
- [ ] Adaptive-down speculation; fused GDN step/conv; long-context flatness (attn_pfd chunk count vs merge cost).

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

- [x] DONE 09-06 (usb4-kfd-20260906 profile: 35 ms = 29.3 gemv + 1.9 attn + 1.4 gdn + 2.9 small kernels; 20.65 GB/step) — **Per-step time budget (measure first).** Instrument one decode step end to end and attribute it:
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
- [x] DONE 09-06 (profile/gemv_bandwidth.txt: 705 GB/s average; out-proj class 423) — **Achieved GB/s per GEMV.** For every gemv/gemv_multi variant in the decode graph (T=1..12, q4_K/q5_K/q6_K/
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
