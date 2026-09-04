# Qwen3.8-27B + USB-eGPU ecosystem — X/Twitter deep dive (2026-09-04)

First real X/Twitter sweep (previous "Twitter" surveys were secondhand web links; this one used the
`xapi` MCP server = the official X API `search_posts_all` / `get_users_posts`). ~9 queries across
quants, MTP/spec-decode, DFlash2/DSpark, AMD 7900 XTX numbers, tinygrad/chestnut, ASM2464PD.
Date window mostly 2026-08-05 → 09-04. All post links are real deeplinks; engagement noted where it
matters. **Caveat:** the Qwen3.8 tag is heavily astroturfed — voxel-garden hype posts, "22 billion
tok/s" fraud claims, and Grok auto-replies were filtered out; below leans on verifiable technical posts.

Everything here is framed the way Jacob wants it: **not "go download these," but "which concepts do we
port into the fork or bake into our own weights."**

---

## 0. TL;DR — what actually matters for us

1. **Architecture-aware quantization is the real quant story, and it's exactly our imatrix TODO.**
   The community converged on protecting the **Gated-DeltaNet (GDN) state tensors** at high precision
   and compressing everything else. EmperoAI's "Ridge" (Q8_0 state tensors + Q4_K GDN mixers, MTP +
   vision intact, 27B→11.7 GiB / 3.7bpw) is the marquee example. This is precisely the
   "protect the imatrix-sensitive layers" idea in our `sweeps/README.md` backlog — now with a proven
   recipe to copy.
2. **"High acceptance != faster," and spec-decode *hurts* under concurrency** — the field independently
   reproduced both of our own findings (`measure-concurrency-scaling`, the MTP-off-under-load result).
3. **DFlash2 / DSpark are the new drafters** displacing plain native-MTP for single-stream speed; we
   already have `dflash.py`. Worth revisiting given the Kimi-K3 draft collection + TorchSpec recipes
   are now open.
4. **tiny corp's own numbers: 46 tok/s on 7900 XTX, no spec decode** (their merged RDNA3 kernels).
   Our fork does ~57 prose / ~73 code *with* MTP — we're ahead of upstream tinygrad on this model.
5. Our copyin work has a public analogue: tiny corp announced "**AMD GPU on USB3 chestnut copies 2.5×
   faster on master**" (Aug 21) — same problem space we've been optimizing.

---

## 1. The model, as the field describes it

- Dense **27B, Apache-2.0**, native vision (images + hour-long video), released ~Aug 14 2026.
- **Hybrid attention: 64 layers = 16× repeat of [3× Gated DeltaNet + 1× Gated Attention]** → 48 GDN +
  16 attention. "75% of the stack is DeltaNet (linear attn)." (@choblin29,
  https://x.com/choblin29/status/2088291984054337713)
- **262K native context, extensible to 1M.** Thinking toggleable per request, `reasoning_effort`
  (xhigh default), `preserve_thinking`. (@victormustar,
  https://x.com/victormustar/status/2088192245098746188)
- Native **multi-step MTP** head in the weights.
- **Terminal-Bench 73.0**, "near-Opus agentic coding on consumer hardware" (@ABHI__YADAV_001,
  https://x.com/ABHI__YADAV_001/status/2090777333351514118).
- **Why our KV is cheap** (validates the `max_context` work): with GDN on 48/64 layers, only the 16
  attention layers carry a growing KV cache — "256K KV at Q4 ≈ 4.25 GB" (@pulpmatrix,
  https://x.com/pulpmatrix/status/2091067052647948537). This is the architectural reason our
  112K-with-snapshot budget is even feasible on 24 GB.
- Adoption: **unsloth GGUF ~9.06M downloads vs base 4.72M** (@krushalkalkani,
  https://x.com/krushalkalkani/status/2094388557142020407) — unsloth is the default distribution;
  the model dwarfs GLM-5.3 and the giant MoEs in download heat.
- QwenDevs' own community roundup (GGUF/MLX/AWQ/NVFP4 + faster-inference approaches), 572 likes:
  https://x.com/QwenDevs/status/2093175583286968499

## 2. Quantization — architecture-aware is the play (our imatrix TODO, solved by example)

**EmperoAI "Ridge" — the recipe to steal** (1047 likes):
> "27B → 11.7 GiB. Qwen3.8-27B-Ridge-3.7bpw. GDN-aware, not a flat 2-bit dump: **state tensors stay
> Q8_0, Gated-DeltaNet mixers at Q4_K.** Native MTP + full vision tower intact. Runs in llama.cpp,
> Ollama, LM Studio."
> https://x.com/EmperoAI/status/2088638789824508095

Corroboration + a 3.7bpw Ridge running vision on a 16 GB Colab T4 "while keeping the sensitive
Gated-DeltaNet layers protected" (@0x0SojalSec, https://x.com/0x0SojalSec/status/2092352689745387645;
@Oluwaphilemon1, https://x.com/Oluwaphilemon1/status/2092420848397205719).

Other quant lines seen:
- **unsloth UD-Q4_K_XL** (what we serve) — the imatrix-calibrated dynamic blend, Q4_K_M ≈ 17.1–17.4 GB.
- **bartowski** imatrix GGUFs, Q4_K_M 17.77 GB (@m_newhaus, https://x.com/m_newhaus/status/2089382748947714343).
- **Escha W2 (2-bit)** ported to stock gfx1100, full 262K ctx in ~20.7 GB, ~26 tok/s (@Chromadera,
  https://x.com/Chromadera/status/2095559169734561864).
- QAT `q2_0`, NVFP4 / NVFP4-mixed, AWQ, MLX 4-bit all present.

**Port implication (updates the imatrix backlog item):** adopt the **GDN-aware mixed-precision idea
explicitly** — keep GDN state tensors at Q8_0, spend the bit budget there, compress attention/FFN
harder. Calibrate the imatrix on a **broad, diverse corpus, NOT Hermes traffic** (Hermes is one
task/domain and would overfit the quant — Jacob's call, 2026-09-04). The architecture-aware
tensor-type map is the win here, not workload-specific calibration. Bake it into our own GGUF
(llama.cpp imatrix + custom tensor-type map); the fork already loads GGUF. Scaffolded in
`sweeps/qwen38-gdn-quant-20260904`.

## 3. Speculative decode: MTP vs DFlash2 vs DSpark vs EAGLE-3

The spec-decode field moved fast in the last ~2 weeks and **independently reproduced our own results:**

- **"High acceptance ≠ faster; each architecture has its own drawbacks"** — TorchSpec team on the
  Kimi-K3 draft models (@dogacel0, https://x.com/dogacel0/status/2095547144174280732). This is our
  MTP/DFlash2 experience verbatim.
- **MTP hurts under concurrency** (our `measure-concurrency-scaling` lesson):
  - @UKKelvinLee: MTP ON 59.6 tok/s single / 149.9 @ 8-conc; MTP OFF 59.1 / **383.2 @ 8-conc** →
    "speculative decoding 2.6× slower under load, zero single-stream gain."
    https://x.com/UKKelvinLee/status/2093242447815917826
  - @piximlight0707 (7900 XTX, ROCm 7.2 HIP): np=1 36.1→55.0 (+52%), np=4 98.2→111.2 (+13%),
    **np=8 124.5→118.7 (−5%)**. https://x.com/piximlight0707/status/2091475765498101830
- **The new drafters:**
  - **Kimi K3 Draft Collection** — lightseekorg released 3 draft models (**EAGLE-3, DFlash2, DSpark**)
    trained with TorchSpec + vLLM on GB200, recipes open-sourced (verified acct, 53 likes):
    https://x.com/lightseekorg/status/2095535393257226562 (vLLM boosted it:
    https://x.com/vllm_project/status/2095674903987159358).
  - **DSpark > native MTP**: Jetson AGX Thor, same NVFP4/SGLang/262K — MTP 27.4 → **DSpark 36.1 tok/s
    (+32%)**, "lossless spec decode" (@Matthewrogers,
    https://x.com/Matthewrogers/status/2092983298582630718).
  - **DFlash2 for Qwen3.8-27B** specifically: an experimental DFlash2 drafter (@xu_paco = a Qwen/infra
    dev, https://x.com/xu_paco/status/2095742146808836257); @MiaAI_lab's EXL3 3.5bpw + DFlash2 on one
    4090 hitting 130–150 tok/s short-context, re-verified (@Oluwaphilemon1,
    https://x.com/Oluwaphilemon1/status/2095655375932399727).
  - DFlash2 is a **memory tradeoff** and "the draft model isn't free" (@yume_arasaki,
    https://x.com/yume_arasaki/status/2095741180755751326); "UD_Q4_K_M with dflash2 outperforms
    [native] with lower VRAM occupancy" (@matt_belliveau,
    https://x.com/matt_belliveau/status/2095682076779467245).
  - Native **MTP head doubles as a 239 MB plug-in drafter** for quants lacking one — 30→64 tok/s on
    M4 Max (@KalenuikMatthew, https://x.com/KalenuikMatthew/status/2089023145311453299).
  - vLLM benchmarked MTP/EAGLE-3/DFlash/DSpark on **AMD MI300X/MI355X** (@shariqriazzz,
    https://x.com/shariqriazzz/status/2093331012680106468) — direct AMD spec-decode comparison worth
    reading for our kernel choices.
- llama.cpp exposes this as `--spec-type draft-mtp` / `--spec-type draft-dflash --spec-draft-n-max N`.

**Port implication:** we already have `dflash.py` + native MTP (K≤3, capped by the fused-decode QT=8
bound per `adaptive-spec`). Two concrete items: (a) evaluate a **DFlash2/DSpark-style trained drafter**
for our RDNA3 path — the recipes are now open (TorchSpec) and DSpark shows +32% over MTP lossless;
(b) our production already effectively confirms "MTP off scales better under load," which is why the
3-worker Hermes batch is the right operating point. Keep native MTP for single-stream/low-conc, and
treat a trained drafter as the next spec-decode experiment above adaptive-K.

## 4. AMD 7900 XTX / gfx1100 field numbers (cross-compare to ours)

Ours (this fork, serving UD-Q4_K_XL, 112K, perf governor): **~57 prose / ~73 code tok/s with MTP**,
live Hermes traffic 85–99 tok/s at high accept.

| source | setup | tok/s | notes |
|---|---|---|---|
| **@__tinygrad__** (official) | 7900 XTX, tinygrad RDNA3 kernels, **no spec decode** | **46** | our fork + MTP beats this — https://x.com/__tinygrad__/status/2091774832736346486 |
| @sudoingX repo (AMD reference) | 7900 XTX, MTP flag A/B | 30.7 → **43.9** (+43%); Win/Vulkan 41.0 → **85.4** (2.1×) | https://x.com/sudoingX/status/2094673741125140658 |
| @piximlight0707 | 7900 XTX, ROCm 7.2 HIP, MTP | np1 36→55, np8 −5% | concurrency curve (§3) |
| @fordp3p3 | 7900 XTX, Q4_K_M, llama.cpp | 34.5 @ 304W | 0.114 tok/s/W, beats his 2×3090 |
| @ayuma_x | 7900 XTX **over OCuLink** (EVO-X2), 4bit+MTP n-max=2 | 46–54, 43.5 @ 36k ctx | our chestnut/USB path is the comparison point |
| @dheeraj1997 (BridgeSpec) | 7900 XTX, Win11, single-stream agentic | 120.7 | open source |
| @Apodex_AI / hipfire | gfx1100, MQ4R, 400-tok decode, no vision/MTP | 226 | hipfire kernel path |
| @Bitcopath | 7900 XTX, llama.cpp, MTP | 34 → 60 | **262K ctx "device-lost fire," 192K stable, 135k prefill in 6.5 min** — mirrors our KV-ceiling MMU-fault work |

Takeaways: our MTP-on numbers are competitive with the llama.cpp/ROCm field and clearly ahead of the
stock tinygrad RDNA3 kernels; the OCuLink 7900 XTX row (@ayuma_x 46–54) is the closest external analog
to our chestnut setup and roughly matches, consistent with our own "chestnut beats OCuLink at matched
governor" finding. Bitcopath's 262K device-lost / 192K-stable independently corroborates our context
ceiling + MAX_T pad work.

## 5. tinygrad / chestnut / USB-eGPU — our exact stack, in public

tiny corp (@__tinygrad__) recent, directly relevant:
- **Aug 24:** "merged high performance kernels for RDNA3 Qwen 3.8 27B… 46 tok/s on 7900XTX, no spec
  decode." https://x.com/__tinygrad__/status/2091774832736346486
- **Aug 21:** "AMD GPU on USB3 chestnut, copies from host now **2.5× faster on master**."
  https://x.com/__tinygrad__/status/2090897368988438622  (our copyin batching/guard work is the same
  surface area — worth diffing master's copyin against ours before any upstream attempt).
- chestnut = **$249 USB4 eGPU**, ASM2464PD-based, open-source unbrickable firmware + FTDI debug, 225W
  buck/boost, native USB3+USB4; TB5 cable "on par with Apple's highest-quality cables."
- **George's PR stance (matters if we ever upstream):** they now *close* AI-oneshotted feature PRs
  because validation cost lands on them; "judgement and taste are the moats." Our copyin/firmware work
  must go up as minimal, measured, human-authored diffs with hardware evidence — which is why we kept
  the reproducers and the byte-identical squashes.
  https://x.com/__tinygrad__/status/2093050035122610207

Ecosystem:
- @subhashdasyam thread: RTX 3090 on a chestnut → **Linux can't see it; the custom tinygrad USB
  firmware is a direct USB transport, not a USB4 PCIe tunnel, and the USB path supports AMD GPUs, not
  the 3090.** They used the FTDI DEBUG port to restore stock-derived ASM2464PD firmware — exactly our
  firmware round-trip tooling. https://x.com/subhashdasyam/status/2094878125977211038
- @LoveMHz posted the ASM2464PD USB4/TB-to-PCIe bridge datasheet:
  https://x.com/LoveMHz/status/2088367606503796801 (cross-check vs our `extra/usbgpu/` datasheets).
- USB4 eGPU effective bandwidth ~3–5 GB/s (PCIe 3.0/4.0 x4 after overhead); "data movement takes the
  hit, compute fine once resident" — the field's version of our "interconnect nearly free for decode,
  expensive for cold start" lesson.
- comma-4 / openpilot in-car eGPU + Turing Motors E2E driving on tinygrad eGPU; @repressionnap porting
  the TinyGPU kernel extension to macOS to drive an R9700 over eGPU outside tinygrad.

## 6. Ranked TODO deltas for our fork (from this sweep)

1. **GDN-aware imatrix / our own quant** (was: generic workload-tuned imatrix). Adopt Ridge's recipe —
   GDN state tensors Q8_0, mixers Q4_K, attention/FFN harder — with a **diverse** calibration corpus
   (NOT Hermes; single-task overfits). Proven to hold quality at 3.7bpw; better-targeted than flat.
2. **Trained drafter (DFlash2/DSpark-style) for the RDNA3 path.** Recipes open (TorchSpec + K3 draft
   collection); DSpark showed +32% over native MTP, lossless. Rank above adaptive-K.
3. **Diff tinygrad master's copyin vs our batching/guard** — they shipped a "2.5× faster USB3 copy";
   confirm we're not behind, and see if our drain-before-arm ordering is upstreamable as a minimal fix.
4. **No action needed but confirmed:** MTP-off-scales-better-under-load and high-acceptance≠faster are
   now externally corroborated — our 3-worker Hermes operating point and MTP-for-single-stream policy
   are correct.

## Accounts worth following (technical, non-spam)
`@__tinygrad__` (tiny corp), `@EmperoAI` (Ridge/GDN-aware quant), `@MiaAI_lab` (DFlash2/EXL3 configs),
`@lightseekorg` + `@dogacel0` (TorchSpec / K3 drafters), `@sudoingX` (AMD 7900 XTX A/B repo),
`@piximlight0707` (ROCm concurrency benchmarks), `@xu_paco` (Qwen infra), `@subhashdasyam` (chestnut
RE), `@LoveMHz` (ASM2464PD hardware), `@victormustar` / `@QwenDevs` (model/quant news).

---

# Part 2 — full sweep + "is anyone beating us?" (2026-09-04, recent-first)

Second, larger pass (~10 more queries, recency-sorted through 2026-09-04) to answer Jacob's direct
question and catch the last few days. Credits: fine, plenty left.

## Are we being beaten? — honest verdict

**Our number to beat:** 7900 XTX over the chestnut *USB* dock, UD-Q4_K_XL, MTP, **serving production**
(vision + 112K ctx + prefix snapshots + concurrent Hermes) → ~57 prose / ~73 code single-stream,
**85–99 tok/s on live Hermes traffic** at high accept.

**On raw single-stream dense-27B tok/s, we are NOT the outright record — but every higher number is
on native-PCIe desktop and/or a short vanity bench, usually without our production surface.** The
apples-to-apples picture on **7900 XTX / gfx1100**:

| who | number | why it's not really beating us |
|---|---|---|
| @sudoingX repo | Win/Vulkan **85.4** (from 41, +flag) | native PCIe desktop, single-stream, no vision/snapshots/USB |
| @dheeraj1997 BridgeSpec | **120.7** single-stream agentic | custom Windows runtime, native PCIe, short bench |
| @Apodex_AI hipfire | **226** (MQ4R, 400-tok decode) | custom kernel, **no MTP/vision**, 400-token vanity decode |
| @ayuma_x (**OCuLink** 7900 XTX) | **46–54** (4bit+MTP) | our closest hardware analog (external GPU) — **we match/beat it** |
| tiny corp official tinygrad | **46** (no spec decode) | stock tinygrad kernels — **we beat with MTP** |
| @fordp3p3 / @piximlight | 34.5 / 55 (np1) | plain llama.cpp — comparable/below us |

@daaximus said the quiet part out loud: most "100+ tok/s" posts are "short story input … processing
nonsense"; on real 86k-context repo work the RTX 5000 Blackwell drops far below the headline
(https://x.com/daaximus/status/2092095742122856721).

**Verdict:** in our actual niche — *a 7900 XTX driven over USB, serving production Qwen3.8-27B with
vision, 112K context, prefix snapshots, and real concurrency* — **nobody in the sweep is
demonstrably beating us.** The only comparable external-GPU number (OCuLink, 46–54) we match/beat,
and we're competitive with native-PCIe llama.cpp while doing far more. We are **not** the record for
a bare desktop 7900 XTX doing 400-token greedy decode — nor do we care to be; that's not our workload.

## The competitive landscape shifted this week (watch these)

- **Qwen3.8-Flash-Next (125B MoE, 6B active) is the new darling** — but it's the wrong tool for our
  24 GB card: on a 7900 XTX it's **18.8 tok/s** (Vault_Dweller, MTP wouldn't help — accept 0.58–0.63
  under the 0.7 bar). It needs 96–128 GB unified memory / multi-3090 / DGX Spark to shine. Dense-27B
  remains our sweet spot. (https://x.com/Vault_Dweller31/status/2095608724157010337)
- **DGX Spark / Mac are where the flashy numbers live:** Mirai "uzu" 105 tok/s on M5 Max (news
  trend); DFlash2 on SGLang/NVFP4 hitting 112 tok/s on RTX 4500 Blackwell; @MiaAI_lab EXL3 3.5bpw +
  DFlash2 on a single 4090 = **130–150 tok/s short-ctx / 113–125 cold E2E** (pongphat verified). These
  are the credible single-GPU leaders — all NVIDIA, none over USB, none our production surface.
- **Cerebras serves Qwen3.8-27B at ~1500 tok/s** (cloud, not local) — irrelevant to local but sets
  the "instant" bar users now expect.
- **Cloud-vs-local debate is loud** (news trend "developers shift toward cloud agents") — our
  privacy/cost story is the counter, and Hermes one-click local (Nous shipped it this week) is
  pulling people toward exactly our setup.

## New quant research (updates the GDN experiment)
- **NVFP4 W4A4 on *all* 496 layers including GDN** (2026-09-04): claims the GDN recurrent layers can
  drop to 4-bit without the instability that kept them 8–16bit → 17.5 GiB
  (https://x.com/NewsTongueX/status/2095724966931013932). This **contradicts Ridge's "keep GDN Q8"**
  — so our `qwen38-gdn-quant-20260904` experiment now has a real A/B to settle (gdn-hi vs gdn-lo).
- KV math confirmed again: 262K KV ≈ 16 GiB fp16 / ~4 GiB q4_0 on the 16 attention layers; that's why
  Q4 weights + q4_0 KV fit 24 GB (cozybearlog, https://x.com/cozybearlog/status/2095543053444583605).
- llama.cpp PR #28297: AVX-VNNI wasn't enabled on MSVC Windows builds for Qwen3.8-27B Q8_0 — a free
  CPU-side speedup for Windows users (not us, but shows the perf surface is still being mined).

## #3 confirmed: we are AHEAD of tinygrad master on copyin
`origin/master`'s `_copyin` is still the **old single-ring, arm-then-read-fence** version — **no
`USB_COPYIN_GROUP` batching and no drain-before-arm** (the exact ordering we proved hangs on large
transfers). tiny corp's "2.5× faster USB3 copy" (Aug 21) was a *different* optimization; the
large-copyin **hang fix and the arm-race ordering fix are still ours alone** and are genuinely
upstreamable as minimal, measured diffs (which fits George's "human, taste, hardware-evidence" PR
bar). Action: the drain-before-arm ordering is the cleanest candidate to offer upstream.

## Updated ranked backlog
1. **GDN-aware imatrix quant, our own weights** — scaffolded in `sweeps/qwen38-gdn-quant-20260904`
   (recipe written). Settles Ridge (GDN→Q8) vs W4-everywhere. Calibrate on a **diverse** corpus, NOT
   Hermes (single-task overfits). Needs a Q8/BF16 base + diverse calib + a GPU-free window.
   **Highest payoff, no fork code changes.**
2. **Trained DFlash2/DSpark drafter for the RDNA3 path** — recipes open (TorchSpec/K3); DSpark +32%
   over MTP lossless. Above adaptive-K. (There's already a `build_dflash2/` llama.cpp tree locally.)
3. **Offer drain-before-arm copyin ordering upstream** — we're ahead of master; minimal human diff.
4. **Confirmed, no action:** MTP-off-scales-better-under-load and high-acceptance≠faster are now
   triply corroborated; Flash-Next is not worth chasing on 24 GB (18.8 tok/s on 7900 XTX).
