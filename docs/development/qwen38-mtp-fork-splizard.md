# Qwen3.8-27B MTP speculative decode — Splizard's fork (unmerged, 2026-08-24)

Companion to `rdna3-fast-kernels-egpu.md` (the official merged PR track). This
tracks a *third-party, unmerged* fork claiming MTP spec decode on top of
custom RDNA3 kernels, sourced from a retweet on tinygrad's own account.

**The fork's code lives in `~/tinygrad-qwen38-fork/`, not here** — it's a
genuinely separate repo (github.com/Splizard/tinygrad-qwen38, `fork: false`
on GitHub, its own history), not a branch we can track alongside the official
`tinygrad/tinygrad` clone this directory tracks. Keeping the two clones
separate avoids entangling an upstream-tracking clone with a diverged,
unreviewed third-party one. This doc and `sweeps/qwen38-mtp-fork-20260824/`
are where the *results* of testing it live.

## The claim

Retweeted numbers (tinygrad custom kernels, q4 KV, MTP_K=3, vs. llama.cpp
Vulkan RADV q8 KV MTP n=3): prose 71 vs 48.5 tok/s (1.46×), code 100 vs 64.6
tok/s (1.55×), prefill 835 vs 704 tok/s (1.19×).

## Verifying the source (same discipline as the official-PR track)

1. Checked tinygrad master for a matching commit — the only new commit was
   `9b0c656` (#17701), which turned out to be three unrelated shell-script
   tweaks for an MI350X Llama-3.1-8B benchmark. **Not this work.**
2. User provided the actual source: `github.com/Splizard/tinygrad-qwen38`,
   branch `amd-gemv-qwen38`. Repo metadata: `fork: false`, 0 stars, created
   and pushed within the same 2-minute window on 2026-08-24 — i.e. a fresh,
   unreviewed, single-author branch, not upstream tinygrad.
3. Read `MTP_PLAN.md` in the repo: detailed, technically coherent dev notes
   referencing real GGUF internals (`blk.64.nextn.eh_proj.weight`, the actual
   `qwen3_next_mtp.py` vLLM reference), tinygrad's actual JIT/UOp mechanics,
   and a `.claude/projects` memory-file path — strongly suggests this was
   built with an AI coding agent doing the same kind of exploratory kernel
   work as today's session. Concluded: **real, substantial engineering, not
   spam** — but a plan doc with an "Expected: ~70-75 tok/s" *projection*, not
   a confirmed final result; unclear if the retweeted numbers came from
   exactly this state of the code.

Real commits found once cloned: `c21c5dde5` (custom AMD gfx1100 kernels,
chunked prefill) and `bfd2bbffb` (MTP spec decode, quantized KV, llm cache,
vision input) on top of tinygrad master.

## Getting it running: five issues, four trivial, one real

1. **VRAM contention** — `tinygrad-server.service` was still holding ~16GB.
   Our mistake, not the fork's. `sudo systemctl stop tinygrad-server.service`
   fixed it.
2. **`ModuleNotFoundError: numpy`** — the fork added vision-input support
   (`tinygrad/llm/vision.py`) which imports numpy; not a dependency of the
   official PR track. `pip install numpy`.
3. **`AssertionError: deepstack layers are not supported`** — `cli.py`'s
   `find_mmproj()` auto-globs any `mmproj*.gguf` sitting next to the model
   file. `~/models/mmproj-Qwen3VL-8B-Instruct-F16.gguf` (from unrelated
   earlier work on a different model) got auto-attached and crashed, since
   it's for a different vision architecture entirely. Fixed with
   `--mmproj none`.
4. **`FileNotFoundError: clang`** — `tinygrad/llm/amd_gemv.py`'s
   `hip_to_ir()` shells out to a `clang` binary directly (`AMD_GEMV_CLANG`
   env var override available), unlike the official PR's kernels which go
   through `libamd_comgr` via ctypes. `sudo apt-get install -y clang`.
5. **The real bug: `tinygrad.device.CompileError: compile failed`,
   underlying diagnostic showed LLVM IR text being parsed as C++**
   (`; Function Attrs: ...`, `attributes #1 = {...}` — unmistakable `.ll`
   syntax hitting a C++ frontend, "unknown type name 'Function'" etc.).
   Root cause: `amd_gemv.py`'s own docstring says `hip_to_ir()`'s output
   ("HIP C++ compiled to LLVM IR by the system clang") is meant to be
   "handed to tinygrad's own AMD LLVM compiler" — i.e. `AMDLLVMRenderer`
   (`tinygrad/renderer/llvmir.py`, llvmlite-based, parses `.ll` text
   directly, no comgr involved). But **`Compiled._select_renderer()` picks
   one renderer for the whole device**, trying `[HIPRenderer, AMDLLVMRenderer,
   HIPCCRenderer]` in order and using the first one whose compiler inits
   successfully. Since we have `libamd-comgr2` installed (needed for the
   *official* PR's kernels, see the other doc's trap #2), `HIPRenderer`
   wins that race on our box — so the fork's raw LLVM IR text ends up
   handed to `HIPCompiler`/`compile_hip()`, which only knows how to compile
   HIP C++ or raw GCN assembly, not LLVM IR text. The fork author's own
   machine almost certainly doesn't have comgr installed at all (their
   docstring says "no ROCm needed"), so `HIPRenderer` fails to init there and
   it falls through to `AMDLLVMRenderer` automatically — this isn't a bug in
   their code, it's that **the official PR and this fork want opposite
   renderers, and our box is tuned for the official one.**

   **Fix: force the renderer explicitly instead of relying on
   auto-selection** — `DEV=AMD:LLVM` (the modern equivalent of the
   deprecated `AMD_LLVM=1`). No code changes needed, zero risk of silently
   wrong output from a guessed patch to someone else's WIP compiler
   plumbing. This is the flag needed *only* for this fork; the official PR
   track should keep using plain `DEV=AMD` (which correctly wants
   `HIPRenderer`).

## Result

`DEV=AMD:LLVM MTP=1`, UD-Q4_K_XL (Unsloth Dynamic, works here because this
fork's `gguf.py` added Q3_K/type-11 support the official tinygrad loader
lacks — see the other doc's trap #4):

```
20 tokens in 652.4 ms: 30.66 tok/s (mtp accepted 15/5 drafts)
```

That's the trustworthy number. The per-step lines the CLI prints in between
are **not** reliable for this path — several show physically-impossible
spikes like `0.01 ms, 78591.64 tok/s, 0.00 GB/s` because the benchmark
harness's per-iteration `Timing` wrapper was written assuming exactly one
token per `generate()` step (true for dense decode); MTP yields multiple
tokens per step on an accepted draft, and the naive stopwatch misattributes
that burst as an absurd single-step rate. A second harness bug, distinct
from the compile issue above, worth knowing if these numbers ever get quoted
elsewhere.

**30.66 tok/s is *slower* than our own clean dense-decode baseline from the
official PR track today (35.18 tok/s, IQ4_XS, see the other doc)** — nowhere
near the retweeted 71-100 tok/s. Caveats before treating that as a real
verdict on the work: only 20 tokens sampled (noisy), the CLI's default
benchmark prompt is a degenerate greedy self-continuation
(`"2020202020..."`) rather than real prose/code, which may behave
atypically for draft acceptance, and we're on the same LLVM-compile path the
retweeted numbers presumably used too (so that's probably not the gap).

See `sweeps/qwen38-mtp-fork-20260824/results.csv` and same-dir `logs/` for
the full run history including every failed attempt above.

## Incident: the sweep script hung the whole machine (2026-08-24, ~18:46-19:01 UTC)

While running `sweeps/claimed-benchmark-20260824/run_sweep.sh` (5 sequential
engine legs, each loading an 18GB model), the box became unresponsive and had
to be hard-reset via REISUB. Confirmed via `journalctl -b -2`:

- A kernel hung-task trace stuck deep in the AMDGPU/TTM memory-eviction path
  (`amdgpu_cs_bo_validate` → `ttm_bo_evict` → `try_to_free_pages` →
  `__alloc_pages_slowpath`), with "Future hung task reports are suppressed"
  (multiple processes wedged, not just one).
- ~15 minutes of `systemd-journald: Under memory pressure, flushing caches.`
  (18:46-19:01), SSH connections timing out and dropping throughout.

Root cause: `run_leg`'s cleanup only did `kill -9 "$pid"` on the one tracked
leader PID. tinygrad's kernel-compile step spawns a
`multiprocessing.Pool` of worker processes (visible as separate
`multiprocessing.spawn`/`resource_tracker` PIDs) that **do not reliably die
when their parent is SIGKILLed**. Across several legs' worth of retries
(this script needed two earlier fix-and-relaunch cycles today, for the
`wait_ready` timeout and the VRAM-clear check — see the results.csv/logs
history), leaked workers stacked up on a box with only **13GB total RAM**
until something gave.

Fix applied (now in `run_sweep.sh`): kill by pattern
(`pkill -9 -f "<venv path>/bin/python3"`) in addition to the tracked PID, so
orphaned workers actually die; `PARALLEL=4` caps the compile pool's peak
memory footprint instead of defaulting to all 12 cores; `wait_ram_clear()`
requires ≥6GB *available* system RAM (not just low GPU VRAM) between every
leg and **hard-aborts the whole sweep** (not just a warning) if it never
clears — repeating the incident was judged worse than an incomplete sweep.

Re-run after the fix, with explicit sign-off, and it worked cleanly (see
results below) — RAM never dropped below ~7.5GB available at any point,
vs. the ~13GB total that hung the box before.

## Results: reproducing the retweet's own comparison

All legs on identical hardware, same `UD-Q4_K_XL.gguf` quant (except
`official_dense`, forced onto `bartowski-Q4_K_M.gguf` — mainline's loader
can't read `UD-Q4_K_XL` at all, see trap #4), same three real prompts
(`sweeps/claimed-benchmark-20260824/prompts/`: a ~2200-token prefill probe,
a 400-word-story prompt, an LRU-cache-with-tests coding prompt), same
client-side measurement (`tokens / wall_s` from each response's own OpenAI
`usage` field — engine-agnostic, no log-scraping):

| Engine | Prefill tok/s | Prose gen tok/s | Code gen tok/s |
|---|---|---|---|
| **Fork, MTP=1** (`DEV=AMD:LLVM`) | **488.84** | **57.64** | **72.9** |
| llama.cpp + MTP n=3, q8 KV (retweet's exact config) | 301.38 | 24.87 | 29.35 |
| llama.cpp + MTP n=3, q4 KV (our usual config) | 301.58 | 24.54 | 31.19 |
| Official tinygrad PR track, dense (`~/tinygrad`, no MTP) | 111.53 | 27.84 | 27.75 |
| Fork, MTP=0 (dense-only, isolated) | — structurally blocked, see below — |

Retweet's own claimed ratios: prefill 1.19×, prose 1.46×, code 1.55×
(fork+MTP vs. llama.cpp+MTP). **Ours came in bigger**: prefill 1.62×, prose
2.32-2.35×, code 2.34-2.48× — our absolute numbers are lower across the
board (expected: eGPU/OCuLink, not whatever native setup the retweet used),
but the fork's *relative* edge over llama.cpp holds up and exceeds the
claim, not just approximately matches it.

**The cleanest read on what MTP itself is worth**: fork+MTP vs.
`official_dense` (same tinygrad lineage, mainline has no MTP at all) —
prose 57.64 vs 27.84 (2.07×), code 72.9 vs 27.75 (2.63×). Since both sides
share the same kernel family minus MTP, this is a more direct signal than
the llama.cpp comparison that MTP is doing real, substantial work here on
natural prose/code — a sharp contrast to the earlier degenerate
self-decode-prompt test (30.66 tok/s, *slower* than dense), which was
clearly an artifact of that prompt's repetitiveness breaking draft
acceptance, not representative of real usage.

**`fork_mtp0` (isolated dense-only, fork's own kernels minus MTP) could not
be measured** — it hit a hard, structural VRAM ceiling
(`Used: 23.86 GB`, on a 25.75GB card) that **did not budge when
`max_context` was cut from 4096 to 2560** (a 40% reduction), meaning
context size isn't the lever — the dense/no-MTP code path in this fork has
a peak footprint that's essentially fixed near the card's ceiling,
regardless of quant (`UD-Q4_K_XL` and `bartowski-Q4_K_M` are both ~17.5-
17.8GB, tried both). This is a real limitation of the fork's current dense
path on a 24GB-class card, not a config problem we could tune around
cheaply — noted here rather than chased further. Means we can't fully
attribute the fork's total speedup between "faster kernels generally" and
"MTP specifically," though the `official_dense` comparison above is
strong circumstantial evidence MTP is the larger contributor.

**Also notable**: mainline's prefill (111.53) is far behind both the fork
(488.84) and even llama.cpp (301.38) — almost certainly because the fork's
"adaptive prefill chunk sizes" work (explicitly called out as fork-only in
`MTP_PLAN.md`) hasn't reached the official merged PR yet.

## Open TODOs

- [x] Same-fork, same-quant `MTP=0` run for a true isolated A/B — attempted
      at two context sizes (4096, 2560), both hit the same ~23.86GB VRAM
      ceiling regardless. Not obtainable on this 24GB card as currently
      built; see "Results" above. Would need either a smaller quant with
      real headroom to spare or an upstream fix to the dense path's memory
      footprint.
- [x] Re-run with real prose/code prompts instead of the degenerate
      self-decode default — done, see "Results" above. Confirms the low
      throughput on the degenerate prompt was prompt-specific, not
      representative: real prose/code hit 57.64/72.9 tok/s vs. 30.66 on
      the repetitive self-decode default.
- [x] Larger sample size — 700-token generations for prose/code (vs. 20
      tokens before), single-shot rather than a 30-step benchmark loop but
      a real end-to-end request each.
- [ ] Depth-sweep test (still open, carried over from the official-PR
      doc): none of today's testing — official or fork — has checked
      throughput at real deep context (32K+). Everything here is shallow
      (≤2560 tokens).
- [ ] Multi-turn benchmark leg (2026-08-25, prompted by SemiAnalysis'
      "AgentX InferenceXv3" newsletter piece on agentic serving
      benchmarks: https://newsletter.semianalysis.com/p/agentx-inferencexv3-does-cuda-moat).
      Its core methodology critique — fixed single-shot 8K-1K benchmarks
      "miss 70+ critical optimizations" that only surface under realistic
      multi-turn load — matches our own experience exactly: the prefix-cache-reuse
      bug and the missing-`tools=` bug (both fixed 2026-08-25, see git log
      on `tinygrad/llm/serve.py`) were invisible to the single-shot
      prefill/prose/code sweep above and only showed up against real,
      multi-turn, tool-using Hermes traffic. Worth adding a scripted N-turn
      conversation leg to the sweep (not ad-hoc live chat) that reports
      TTFT (time to first token, separate from steady-state decode speed)
      and per-turn cache-hit ratio, for both this fork and llama.cpp.
## Prefix-cache reuse across turns (2026-08-25)

> **Superseded — see "Correction: the recache was unsound" below.** The
> `_recache_for_next_turn` approach described here was removed the same day;
> kept as written because the *diagnosis* (BPE boundary tokens, `tools=`
> branch of the template) is still right, only the fix was wrong.

The fork already ships the machinery for this — `Transformer.get_start_pos()` /
`_cached_tokens` / `_reusable_prefix_len()` in `model.py` — but it never
actually found a match in practice. Qwen3.8 is a hybrid SSM/attention
architecture (`has_recurrent_block=True`, GatedDeltaNet layers), so
`get_start_pos` takes a strict path requiring the *entire* cached prefix to
match the new prompt byte-for-byte (recurrent state can't be partially
rewound the way plain KV-cache attention can). Two independent bugs broke
that exact match on every real second turn:

1. `_cached_tokens` was left holding `generate()`'s own raw output tokens,
   which (a) include the model's `<think>` block even though a normal
   OpenAI-compatible client only sends the visible `content` back next turn,
   and (b) can legally retokenize to different ids once more text follows
   them (BPE merges are decided over the whole string — e.g. the role
   header's trailing newline and the reply's own leading newline can merge
   into a token that never existed while the string still ended there).
2. The fix for #1 (re-render `messages + [reply]` right after responding and
   cache *that* tokenization) initially omitted `tools=body.get("tools")` —
   the chat template renders a completely different system prompt depending
   on whether `tools` is present, so every real tool-using conversation
   mismatched at token index 3, every turn, even after fixing #1.

Fix lives entirely in `tinygrad/llm/serve.py` (`_recache_for_next_turn`,
committed `26548078e`, not yet pushed upstream). Verified against real
Hermes agent traffic (20K+ token tool-using system prompt): turn 2 went from
`in:0 +20829` (full cold reprocess, ~62s) to `in:20817 +12` (~9.5s, almost
entirely decode time for the new reply).

**Speculative-decode (MTP) interaction, checked separately**: a SemiAnalysis
piece on agentic serving (see TODO below) warned that vLLM has had bugs where
repeated-turn caching silently loses EAGLE/speculative-decode draft state.
Measured our own MTP accept-rate across a cache-hit boundary to rule this out
— cold turn (`in:0`) ran 0.58→0.66→0.63→0.64 accept rate (~2.75-2.98
tok/step); the following cache-hit turn (`in:37+24`) ran
0.69→0.72→0.73→0.68 (~3.05-3.18 tok/step). No degradation; if anything
slightly higher. Makes sense in hindsight: the MTP module's KV/state buffers
are the same persistent, position-indexed buffers as the main model's, so
resuming from a cached position doesn't leave them stale.

Separately found and fixed while debugging this: neither tinygrad service
bound to `0.0.0.0` (both defaulted to `cli.py`'s `--host 127.0.0.1`, unlike
`llama-server.service` which already did) — added `--host 0.0.0.0` to all
three service files. Also found the actual root cause of one apparent
cache-reuse failure that turned out not to be a code bug at all: Hermes
fires an "Auxiliary title_generation" call against the same endpoint at the
start of every new conversation, on its own thread — it queues behind the
main request, times out, retries a couple of times, and each retry
(correctly, per the fix's own logic) overwrites the single shared cache slot
right before the real next turn arrives. Fixed via `~/.hermes/config.yaml`
(`auxiliary: title_generation: enabled: false`), not in our code — see "Open
TODOs" below for the more durable fix (per-conversation keyed cache) if a
similar collision recurs from some other source.

## Prefix-state snapshots: surviving interleaved requests (2026-08-25)

Follow-on to the cache-reuse fix above. The model holds ONE decode state, so
any request that doesn't extend the cached conversation evicts it — and on
this hybrid model the recurrent blocks need an exact full-prefix match, so
there's no partial reuse to fall back on: the long conversation's next turn
reprocesses everything. Hermes's title-gen call was the first instance (fixed
at the source, in Hermes's config), but the class is open-ended: a second
session, a delegated sub-agent, a memory-recall query, any monitoring probe.

**Design, and the dead end first.** The obvious approach — per-conversation
KV/state buffers, swap which one the model uses per request — does not work
here: `TinyJit` only treats tensors passed as *call arguments* as replaceable
inputs (`_prepare_jit_inputs` is deliberately shallow "to avoid grabbing
model weights"), and the state buffers (`cache_kv`, `conv_state`,
`recurrent_state`) are never arguments — they're captured by identity into
the compiled graphs. Re-pointing `self.cache_kv` at another buffer leaves the
compiled kernels writing to the original. What *does* work is copying
contents: `clone()` the buffers out, `assign()` back into the same buffers
later (the fork's own `_set_positions` already relies on assign preserving
JIT identity for the RoPE tables). So: **snapshot/restore, not multi-slot.**

Implementation (`26548078e`'s successor commit, `model.py` +
`serve.py`): `Transformer.state_tensors()` lists every in-place-mutated
buffer (16 attention KV caches, 48 SSM conv+recurrent states, the MTP
block's KV cache); `snapshot_state()`/`restore_state()` clone/assign them
along with `_cached_tokens`. `serve.py`'s `_pick_prefix_state` runs before
every text request: if the request extends a *saved* conversation better
than the live one, restore it (saving the live one into the freed slot if it
is itself ≥ `PREFIX_SNAPSHOT_MIN`=1024 tokens and unrelated — so two long
conversations alternating, agent ↔ sub-agent, swap through one slot); if the
request is unrelated and would evict a long live conversation, save it
first. `PREFIX_SNAPSHOTS` (default 1) caps saved slots; a `MemoryError`
during a snapshot disables the feature for the process rather than failing
the request.

**Cost**: a snapshot is a full copy of the state — sized from the GGUF
header (64 blocks, `full_attention_interval=4` → 16 attn + 48 SSM, +1 MTP
attn): 17 × 78.6MB quantized KV + 48 × 3.1MB recurrent ≈ **1.5GB at
max_context 65536**, 0.24GB at 4096 (measured, matches). Against ~5.4GB free
at 65536 with the model loaded, one slot plus a transient copy during a swap
peaks ~3GB. Copy time is milliseconds on-GPU.

**Verified** (`sweeps/prefix-snapshots-20260825/test_interloper.py`,
max_context 4096): A1 (2212 tok) cold → B (26-tok interloper) logs `saved
snapshot (2217 tok, 0.24 GB)` → A2 logs `restored snapshot (2217 tok)` /
`in: 2217 + 17`, 0.94s vs 4.92s. Then the strong check: at temperature 0,
A2's `content` **and** `reasoning_content` after interloper+restore are
byte-identical to A2 with no interloper at all, and the answer is right. VRAM
flat (17.78GB) across three repeated save/restore cycles — no leak.

Two things this deliberately does **not** cover, both logged as TODOs below:
compaction (the primary conversation itself changing shape — no saved copy
of the old one helps; needs mid-prefill checkpoints), and the case where a
new request is a *prefix* of the cached state rather than an extension
(the strict recurrent rule recomputes it cold; correct, just not optimal).

## Warm-start cache, and merging upstream's 2026-08-25 commits

**Startup time, and what the limiter actually was.** Every restart at
`max_context 65536` took ~9 minutes. Measured from one startup's journal:
254 JIT graphs missed tinygrad's schedule cache = **458s of single-threaded
Python graph tracing**, vs 1.2s for the 40 that hit; LLVM kernel compile was
~144s and already parallel; load average 1.35 on 12 cores the whole time.
Not compute — one Python thread redoing identical work every start. The
fork's designed answer is `LLM_CACHE` (pickle the warmed-up model, captured
JITs included), which we had disabled on day one because every load crashed:
`TypeError: Tensor.realize() missing 1 required positional argument: 'self'`
— `cache.py` filtered the transient state buffers on `is_realized`, which is
false for all of them after an unpickle, then called `Tensor.realize()` with
no arguments. A fork bug in fork-only code (upstream tinygrad has no LLM
cache), not a missing flag: `LLM_CACHE` defaults to 1 and `=0` was our
workaround. Verified at 4096: save leg ~8 min, **load leg ready in 35s**.

**Upstream moved the same day** (`e1eca014f`, `4c5e3808b` — see
`git log upstream/amd-gemv-qwen38`): the identical cache fix (plus zeroing
the recurrent state unconditionally on load — better than the guard alone,
which leaned on the `start_pos==0` reset), a multi-query flash-decoding path
(`AMD_ATTN_MQ=1` default; author measures 87→57 ms/step at 65k on this
card), SIGTERM/SIGINT device drain in `cli.py` (the "teardown with kernels in
flight wedges MES" hang class — relevant after our REISUB), and a
recurrent-state *prefill checkpoint* solving the same turn-2 bug as our
`4b8793b7b` from the other side (resume from the previous prompt's end
instead of re-rendering the reply). Our branch `prefix-state-snapshots` is
rebased onto `4c5e3808b` (= `origin-github/amd-gemv-qwen38`, the user's
fork, synced to upstream); our own `cache.py` guard was dropped as
superseded. What remains on top, and why each still earns its place:

1. `4b8793b7b` exact-match recache — tried first, his checkpoint is the
   fallback. Also the only path that passes `tools=` through.
2. `fa54ec95a` prefix-state snapshots — nothing upstream covers interleaved
   requests; `restore_state` now also clears his `_ckpt_tokens`, since a
   restored KV cache no longer holds the positions his checkpoint assumes.
3. `c776a68b1` one cache file per (model, max_context, extra) — his file
   name keyed on the model path only, so a 4096 test run evicted the 65536
   production entry (a miss = another full warmup) on every switch.
4. `710fe8e85` replay `warmup()` after a cache load — the first request
   after a load paid ~12s (A1 17.7s vs 4.9s; buffer allocation / kernel
   loads); on a captured model warmup just replays, so the cost moves to
   startup.

**Layered test on the merged code** (`sweeps/prefix-snapshots-20260825/
test_layered.py`, 4096): exact match `in: 2217 +26` ✓; interloper →
`restored snapshot`, `in: 2217 +26` ✓, output byte-identical ✓; **his
checkpoint fallback did not fire** on an edited reply (`in: 0 +2248`).
Almost certainly the BPE-boundary effect from `4b8793b7b`'s message: his
checkpoint tokens end at the generation prompt (`…assistant\n<think>\n`), and
in the next request that trailing `\n` merges with the reply's leading
newline into a different token, so `tokens[:len(ck)] == ck` fails on the
last token. In thinking mode (Qwen3.8's default) that is the common case.
Worth reporting upstream; until then our recache is what carries turn-2
reuse here. (Also noticed, not ours: his `_warmup` returns early for
non-MTP models with `_warming` still `True`, so `_save_checkpoint` would
never run there. Not our config.)

Process notes: the cache key hashes mtimes of every `tinygrad/*.py`, so
**any source edit costs one full warmup**; for one rename-only test
iteration the mtime was restored with `touch -d` to reuse the pickle — fine
for a test, never for production. And a `replace_all` rename of
`state_tensors()` silently rewrote upstream's `_state_tensors()` calls too
(substring), which the layered test caught on its first request; the method
is now `snapshot_tensors` and the audit greps for both spellings.

## Correction: the recache was unsound; the real fix (2026-08-25, later)

The first real Hermes session on the merged build showed every turn cold
(`in: 0 +32435`, `in: 0 +34260`, … ~100s each). Turn 1 was a tool call, and
the recache had rendered it as a 4-token empty assistant message — no
`tool_calls` in the replay. Digging into why exposed the real problem:
**relabelling the generated state as the client's rendering of the reply is
wrong whenever the model reasons.** What is physically in the cache after a
turn is prompt + `<think>…</think>` + answer; the client sends back the
answer without the think block, which is *shorter*, so on a "match" the next
turn's tokens were written over the middle of the model's own reasoning and
its visible answer fell out of context. The earlier byte-identical
verification could not see this: those prompts produced empty think blocks,
so both sequences coincided. On Hermes it never matched (tool calls), so
nothing was corrupted there — just nothing was reused.

The sound design is the one his `e1eca014f` pointed at, fixed and extended
(branch `prefix-state-snapshots`, 5 commits on `4c5e3808b`, old history on
`backup/prefix-state-snapshots-v1`):

1. **His prompt-end checkpoint, taken one token early** (`8bd6444e6`). His
   version never matched here because the checkpoint included the prompt's
   last token, the `\n` after `<think>`, which merges with the answer's first
   token next turn. The tokenizer splits on special tokens, so everything up
   to `<|im_end|>` re-tokenizes identically; excluding that one token makes
   the checkpoint match for *any* reply shape (reasoning stripped or kept,
   tool call + result, edited reply), at the cost of one extra 1-token
   prefill chunk. Resuming from it re-prefills only the client's rendering of
   the reply + the new message — the ~1.8K tokens we saw per Hermes turn
   instead of 34K.
2. **Snapshots carry the checkpoint** (`18d10fa8b`): a conversation comes back
   extending its previous *prompt*, not its generated sequence, so a restored
   snapshot is matched and resumed on its checkpoint.
3. `miss: live@i/n ckpt@j/m` in the log when nothing was reused, and
   `cache_prompt=false` (llama.cpp's field) to force a cold run (`9e66c743d`)
   — the latter makes correctness testable on a running server.

**Verified** (`sweeps/prefix-snapshots-20260825/test_reuse_v2.py`, 4096,
temperature 0, every case compared against a cold `cache_prompt=false`
reference of the same request): plain chat with 1,373 chars of real
reasoning → `in: 2256 +47` (= prompt−1), content **and** reasoning
identical; tool call → tool result → `in: 2484 +70`, identical; interloper →
`restored snapshot`, `in: 2256 +47`, identical. ALL PASS.

Lesson recorded: a reuse scheme has to be verified with prompts that make
the model actually reason, against a cold reference — not with trivial
prompts and not against itself.

## KV cache quantization: default (k4v4+qjl) vs f32 (2026-08-25)

Prompted by the same "should we relax quantization now that we're fast"
question that got asked about llama.cpp's `--cache-type-k/v` (see that
repo's playbook doc for the llama.cpp side — short version: no measurable
speed difference there across q4_0/q8_0/f16, pure VRAM-fit lever). Expected
the same story here. Got the opposite result.

This fork's `KV_QUANT` default isn't a simple block quant like llama.cpp's
q4_0 — it's a custom scheme (`amd_gemv.py`'s `KVQuant` class): 4-bit keys and
values plus a "QJL" random-projection residual (Walsh-Hadamard rotation +
1-bit sign residual), ~6.8x smaller than f32 per the code's own docstring,
with no q8-equivalent middle setting (`KV_KBITS`/`KV_VBITS` only go up to 4;
the only other option is `KV_QUANT=0`, full f32 — a much bigger jump than
llama.cpp's q4→q8→f16 ladder).

Same prompts as the claimed-benchmark sweep, `max_context=4096` (deliberately
small — back-of-envelope byte math predicted full f32 KV at the production
65536 context would push total VRAM past this 24GB card; not worth risking
another OOM incident just to get a same-context comparison). Script + raw
data: `sweeps/kv-quant-20260825/` (`run_tinygrad.sh`, `results_tinygrad.csv`).

| config | prefill tok/s | prose gen tok/s | VRAM |
|---|---|---|---|
| default (k4v4+qjl) | 480.66 | 57.58 | 17.33GB |
| f32 (`KV_QUANT=0`) | **33.41** | 46.40 | 17.28GB |

**Prefill is ~14x slower with unquantized KV.** Decode is only ~19% slower.
VRAM is within noise at this small context (the fit argument would only show
up at real 65536-context scale). Root cause, found in `model.py`'s
`_attention`:
```python
if residual is not None and self._n_fused(x) and self._fused_ok(): return self._attention_fused(x, start_pos, residual, n_tok)
assert self.kv_quant is None, "the quantized kv cache is only readable by the fused attention kernel"
```
The fork's fast hand-written AMD kernels were built *around* the quantized
KV format specifically. `KV_QUANT=0` doesn't just widen the numbers stored —
it takes prefill off the fast fused-kernel path and onto a slow generic
fallback. So the general "quantized KV only helps fit, not speed" reasoning
(true for llama.cpp, confirmed above) is **wrong for this fork specifically**,
for an implementation reason rather than a bandwidth one: here, quantization
is a prerequisite for the fast kernel path existing at all, not just a
memory-format choice. **Conclusion: do not relax KV quantization on this
fork** — it costs an order of magnitude on prefill for no benefit at current
context sizes. If more headroom for quality is ever wanted here, the real
lever would be a *new*, better-designed quant scheme with a fused-kernel
path of its own (see the "implement more quant cache stuff" idea below),
not just turning quantization off.

- [ ] Two follow-on ideas from the same article, not urgent but worth
      revisiting if real usage grows past what we've tested:
      (a) our `_recache_for_next_turn` fix re-tokenizes the *entire*
      growing prefix from scratch every turn (cheap at ~20-60K tokens,
      but O(n) per turn) — the article notes production engines instead
      write/tokenize only the *newly generated* range per turn. Worth
      profiling if conversations regularly approach the 65536 ceiling.
      (b) ~~the cache is a single global slot~~ — **done 2026-08-25**, see
      "Prefix-state snapshots" above: interleaved requests of any size no
      longer evict a long conversation's state (saved before eviction,
      restored on return, byte-identical output verified).
- [ ] Mid-prefill checkpoints for the *compaction* case (phase 2 of the
      snapshot work). When the harness compresses history (Hermes:
      `compression: enabled, threshold 0.5`), the new prompt diverges from
      everything cached at the first rewritten token, and on this hybrid
      model that means a full cold reprocess — no saved copy of the *old*
      conversation helps. Fix: take snapshots *during* prefill at fixed
      positions (every N tokens, and at the end of the system/skills prompt,
      which Hermes's `protect_first_n` keeps intact through compaction), key
      them by their token prefix, and let `_pick_prefix_state` choose the
      longest checkpoint that is a prefix of the new request. Same
      machinery as above — only *when* snapshots are taken changes. To keep
      several affordable, copy only positions `[0, P)` of each KV plane
      (`KVQuant.offsets()` gives the planar layout) instead of the whole
      `max_context` buffer; the 48 recurrent states (~150MB, fixed size)
      then dominate per checkpoint, so ~10 checkpoints ≈ 2GB.
- [ ] Prefix-of-cache requests: a request whose tokens are a strict prefix
      of the cached state (e.g. a client re-sending an earlier turn, or the
      A1-after-A2 pattern in the test) is recomputed cold under the strict
      recurrent rule. Correct but wasteful; a checkpoint at that position
      (same phase-2 machinery) would serve it.

## Sampling: matching Qwen's recommended profile (2026-08-25, evening)

Qwen's published thinking-mode sampling recommendation for this model is
`temperature=1.0, top_p=0.95, top_k=20, min_p=0`. Two gaps here:

1. `serve.py` defaulted `temperature` to 0.6 when the client sends none —
   and Hermes sends none. Changed the default to 1.0. Per-request
   `temperature` still wins.
2. The fork sampled with temperature only: `_sample`/`_sample_rows` are a
   Gumbel-max over the raw logits, no top-p/top-k anywhere. Added them.

### Design: top_p/top_k are server-fixed, not per-request

`temperature` is a `Tensor` input precisely so the JIT graph doesn't
recompile per request. `top_k` can't be: it's a Python `int` that shapes
the graph. So `--top-p`/`--top-k` are CLI flags read once at load (they
started life as `TOP_P`/`TOP_K` env vars during the sweep; moved to flags
the same evening so nothing sampling-related is hardcoded or ambient in
the repo — `--temperature` likewise replaces the default that was baked
into `serve.py`). They are baked into every sampling site (`forward`, the
4 `_sample_rows` calls in `forward_spec`) and are part of the warm-start
cache key, so a cache captured at k=0 can't be replayed for a k=20 start.
Defaults `1.0`/`0` are exact no-ops (the filter early-returns), so a
server started without them is byte-for-byte the old behaviour — and
hits the same cache file as before. `serve.py` logs a one-line note when a
request asks for different values than the server was started with,
rather than silently ignoring the fields. Same flags ported to the plain
`~/tinygrad` repo.

### Three attempts to make it not hang

- **v1: `Tensor.sort` over the full vocab for top_p.** Compiled, then the
  server never came up; the sweep's 30-minute startup timeout killed it.
- **v2: `Tensor.topk(k)` "instead".** Same hang. Reading `mixin/op.py`:
  `topk()` *is* `sort()` + slice, and `sort()` is a bitonic sort — the
  248,320-wide vocab padded to 2^18 with 18 stages, each substage a
  split/cat/flip on an 18-dimensional `(2,2,…,2)` view. Instantiated at 4-5
  sampling sites per spec graph, it expanded to ~1300 kernels. The retry
  log has the number: `scheduled 1475 kernels in 272891.98 ms` — **4.5
  minutes to schedule one warmup graph** (a normal graph is ~173 kernels in
  ~3s), and warmup schedules several. Scheduler cost, not GPU time.
- **v3 (current): iterative argmax.** `k` rounds of `max(-1)` + mask-out
  give the `k` largest values, descending, in ~2k trivial O(V) kernels.
  top_p is then the nucleus over those candidates. With top_p but no
  top_k the candidate set is capped at 64 (`_TOP_P_ONLY_CANDIDATES`) — an
  approximation for flat distributions, and a path Qwen's profile never
  takes since it always pairs the two.

### The threshold bug the numbers caught

The first nucleus threshold was `where(excl_cum < p, vals, -inf).max()` —
which always returns position 0 (the largest logit), so only the top token
ever survived. My numpy "reference" reproduced the same mistake, so the
check passed with `kept=1`; the *count* was what gave it away (20 near-flat
candidates at p=0.95 should keep ~19). The nucleus is a descending prefix,
so its threshold is the **smallest** kept value:
`where(excl_cum < p, vals, +inf).min()`. Re-validated against an
independently written reference on `Transformer._apply_top_pk` itself
(CPU backend, T=7, V=151936 gaussian logits):

| top_p | top_k | kept/row | reference | |
|---|---|---|---|---|
| 0.95 | 20 | 19 | 19 | ✓ |
| 1.0 | 20 | 20 | 20 | ✓ |
| 0.5 | 20 | 8-9 | 8-9 | ✓ |
| 0.95 | 0 | 60 | 112,469 | expected: gaussian logits are maximally flat, the true nucleus is 74% of the vocab; that's the 64-candidate cap doing its documented approximation |

### Plain `~/tinygrad` + `Qwen3.8-27B-Q4_0.gguf`: every request died

Not a sampling bug. `KeyError: 248320` in `_decode` — the vocab and the
output head are both exactly 248,320, so the model sampled id `n`, one past
the end. tinygrad's `argmax` is `n - max(m * arange(n..1))`: an all-False
`m` (a NaN in the logits) returns `n`. That file is the only candidate with
GGML type 3 (Q4_1) tensors, the likely bad dequant. Two fixes: ported the
fork's decode guard (`_tok2bytes.get`, unknown id ⇒ stop token) to the
plain repo's `cli.py` — the fork had this hardening, the plain repo didn't
— and moved the plain legs to `bartowski-Q4_K_M` (Q4_K/Q5_K/Q6_K/Q8_0/Q4_0
only, all of which the plain loader compiled in the 08-24 `official_dense`
run; the UD files are out — they carry Q3_K, "GGML type '11' is not
supported!", confirmed by live reproduction after I'd wrongly "corrected"
the service file's comment on the strength of one old log).

Sweep: `sweeps/sampling-sweep-20260825/` (`run_sweep.sh`, `retry*.sh`,
`results.csv`). UD-Q4_K_XL everywhere except the plain legs (bartowski
Q4_K_M), `max_context=4096`, 700-token generations:

| leg | temp / top_p / top_k | prefill s | prose tok/s | code tok/s |
|---|---|---|---|---|
| fork_temp06 (old default) | 0.6 / – / – | 6.46 | 43.1 | 66.5 |
| fork_temp10 | 1.0 / – / – | 6.48 | 39.6 | 62.7 |
| fork_qwen_recommended | 1.0 / 0.95 / 20 | 6.55 | 36.1 | 54.5 |
| llamacpp_old_defaults | 0.6 / – / – | 7.36 | 24.0 | 25.8 |
| llamacpp_qwen_recommended | 1.0 / 0.95 / 20 | 7.33 | 23.6 | 26.7 |
| plain_temp10_bart | 1.0 / – / – | 20.2 | 27.9 | 27.8 |
| plain_qwen_recommended_bart | 1.0 / 0.95 / 20 | 20.3 | 26.8 | 26.7 |
| fork_mtp0 | — | OOM at 23.85 GB | | |

The full Qwen profile costs the fork 16-18% decode — temperature alone is
~7% (a flatter distribution means the MTP drafts get accepted less often;
llama.cpp's spec-decode shows the same shape) and the filter adds ~40
small kernels per sampling site per step. llama.cpp and plain tinygrad
lose ~zero: their sampling is cheap next to their slower decode. Even so
the fork stays 1.4-2x ahead of both. `fork_mtp0` OOM'd at 23.85GB,
identical to 08-24 — a real VRAM ceiling for the dense-only path on this
card, not a leaked-process artefact. Empty `content_preview` on several
legs (every engine) is 700 tokens spent inside `<think>`; the
`completion_tokens` column is the generation count.

**Not yet decided: whether production should run the full profile.** The
hang, the threshold bug, and the plain-repo NaN were all found *because*
the change went through the sweep first rather than straight into the
service file; `tinygrad-server-splizard.service` still runs without
`TOP_P`/`TOP_K` (= the old temperature-only sampling, now at temp 1.0).
Turning it on is `--top-p 0.95 --top-k 20` on the unit's `ExecStart`, at
the measured ~17% decode cost (`--temperature` is 1.0 by default; 0.6 buys
back ~7% decode on this fork via better MTP draft acceptance).

### Disambiguation: which knob costs what (`disambig.sh`, same evening)

Four more fork-only legs, each generation task run twice. The rep-1 prose
number in every sweep carries a ~3 s one-off: prose is the first request
after the 2,212-token prefill task, and `_pick_prefix_state` clones the
whole live state before evicting a conversation ≥1,024 tokens. Code never
pays it (it follows the 757-token prose state). Read prose from rep 2.

| config | temp | top_p | top_k | code tok/s | prose tok/s (rep1 / rep2) |
|---|---|---|---|---|---|
| greedy | 0.0 | – | – | 67.0 / 67.4 | 43.6 / 54.0 |
| old default | 0.6 | – | – | 66.5 | 43.1 / – |
| Qwen temp | 1.0 | – | – | 62.7 | 39.6 / – |
| top-k only | 1.0 | – | 20 | 56.4 / 54.6 | 36.2 / 41.6 |
| top-p only (64-candidate path) | 1.0 | 0.95 | – | 42.6 / 45.1 | 27.8 / 33.3 |
| Qwen full profile | 1.0 | 0.95 | 20 | 54.5 | 36.1 / – |
| full profile at 0.6 | 0.6 | 0.95 | 20 | 58.3 / 56.8 | 37.1 / 45.2 |

- Temperature 0 → 0.6 is free; 0.6 → 1.0 costs ~6% (MTP drafts accepted
  less often from a flatter distribution).
- top-k=20 costs ~11%; adding top-p to it is free; top-p *alone* costs
  30% because it runs 64 candidate rounds instead of 20.
- One cost model fits all of it: **~0.1 ms per generated token per
  candidate round**, on a ~16 ms/token base, independent of temperature
  (20 rounds: +2.1 ms; 64: +6.7 ms → predicts 44, measured 42.6-45.1).
  The rounds are spread over the ~5 sampling sites of the spec-decode
  graph; fusing them into one kernel is the obvious follow-up if the
  profile ever goes to production.
- Never run top-p without top-k here; Qwen's own pairing is the cheap one.

Open question: the 08-24 `fork_mtp1` leg (same greedy config, same
prompts, code before the upstream merge) measured 72.9 code / 57.6 prose vs
67.2 / 54.0 today, ~8% slower. Candidates: upstream's `e1eca014f`
(multi-query flash decoding, prefill-state checkpoint), our
snapshot/checkpoint commits, or day-to-day variance. A worktree A/B at
`4c5e3808b` vs HEAD with `disambig.sh`'s `fork_t00` leg would settle it.

## DFlash2 study, and the 03:02 reboot (2026-08-26)

Prompted by an online 7900 XTX config (`-ctk turbo4`, `--kv-unified`, `--fit on`, dflash `--draft-max 15`). Verified
against our llama.cpp build (`7900xtx-research`): `--kv-unified`, `--fit`, `--no-context-shift`, `--prio` exist;
`--draft-max` was renamed `--spec-draft-n-max`; `turbo4` KV types are a separate unmerged fork (no `turbo` in our
ggml). DFlash **1** was already in our tree; DFlash **2** (conv + selector, the `z-lab/Qwen3.8-27B-DFlash2-GGUF`
drafter) needed PR #27342, test-merged cleanly on scratch branch `test-dflash2-merge`, built in `build_dflash2/`.
Drafter at `~/models/dflash2-drafter/Qwen3.8-27B-DFlash2-Q4_K_M.gguf` (1.1 GB). Sweep dir:
`~/llama.cpp/sweeps/dflash2-20260826/` (`bench_results.csv`, `bench.py`, `ctxbench.py`).

llama.cpp, UD-Q4_K_XL, greedy, 300 tokens, tok/s (single runs):

| task | no spec | own MTP K=3 | DFlash2 K=3 | K=5 | K=7 |
|---|---|---|---|---|---|
| code | 17.3 | **36.5** | 33.7 | 32.0 | 31.1 |
| reasoning | 25.8 | 45.7 | 38.2 | **49.5** | 47.7 |
| prose | 26.1 | 30.9 | 29.5 | 27.6 | 53.7 (suspect, rerun) |
| math | 26.0 | 44.6 | 41.1 | 45.7 | **55.4** |

- Both llama unit files already run `--spec-type draft-mtp --spec-draft-n-max 3` (and so did every sweep leg):
  the "no spec" column is not production. First-ever confirmed AMD/Vulkan DFlash2 numbers as far as we could find;
  every public benchmark is NVIDIA.
- **Not worth porting to the fork.** `dflash.py` here is an abandoned stub (MTP_PLAN.md: "far more work to
  reverse-engineer. Skip."; `inject_kv` keeps one row instead of the 2048-token ring, selector is a numpy loop).
  The fused decode kernel takes `MAX_T=8` chunks -> `2K+1 <= 8` -> K <= 3, and at K=3 the GGUF's own MTP beats
  DFlash2 on every task. DFlash2 only wins at K>=5 on reasoning/math, never on code, and its 5-layer drafter costs
  several MTP passes per step. Same-harness best-vs-best stays llama ~24-27 vs fork ~43-67 tok/s (temp 0.6/1.0).
- Open: an A/B of production llama flags (q4_0 KV cache, `-b 2048 -ub 512`, temperature) explaining the 26 vs
  36 tok/s gap, and decode-vs-context-depth curves for both engines (1K/16K/48K/96K) - `safe_chain*.sh`.

**Reboot post-mortem.** A `setsid nohup script & $!` off-by-one pid made a waiter fire immediately, overlapping a
tinygrad model load (KFD userptr pins host RAM) with a live llama-server on the 13.7 GB box. SIGKILLing tinygrad
mid-load did not return the pinned memory; the OOM killer found only ~1 GB of anonymous memory to blame and killed
hermes-gateway, dbus, the user systemd instance, networkd; the box went down 03:02:28 and rebooted. Two aggravators:
(1) Claude Code runs at `oom_score_adj -900` and every child inherits it, so the model servers it launches are
near-immune to the OOM killer - benchmark launches now set `echo 800 > /proc/self/oom_score_adj` before exec;
(2) `tinygrad-server-splizard.service` never starts at boot: `gpu-power-tuning.service` has `After=multi-user.target`
while splizard is `After=`/`Requires=` it and `WantedBy=multi-user.target` -> ordering cycle, job deleted (fix: make
gpu-power-tuning `After=sysinit.target`). Rules now baked into the sweep scripts: one script, sequential, never a
second waiter; every launch guarded (no other model server, VRAM < 2 GB, >= 10 GB RAM available); readiness = the
launched pid owns the port.

### Decode vs context depth, both engines (2026-08-26, `sweeps/dflash2-20260826/ctx_results.csv`)

Production flags on both (llama: q4_0 KV, `-b 2048 -ub 512`, draft-mtp K=3, `-c 131072`; fork: MTP, KV_QUANT, 131072),
temperature 0.6, 300-token answers, one run per cell. `ctxbench.py` measures prefill from time-to-first-token and
decode from first to last streamed chunk.

| prompt tokens | llama decode tok/s | fork decode tok/s | fork/llama | llama prefill tok/s | fork prefill tok/s |
|---|---|---|---|---|---|
| 770 / 728 | 35.4 | 67.0 | 1.9x | 177 | 211 |
| 10.9K | 34.9 | 61.6 | 1.8x | 445 | 388 |
| 32.6K | 31.0 | 52.1 | 1.7x | 444 | 345 |
| 65.1K | 27.0 | 38.7 | 1.4x | 373 | 262 |

The fork decays faster with depth but leads everywhere measured; llama's prefill is faster past ~10K (65K prompt:
2.9 min to first token vs 4.1 min on the fork). Short-context A/B on llama (greedy, 300 tokens): the q4_0 KV cache
is +7-27% faster than f16 on Vulkan, `-b/-ub` make no difference, temperature 0.6 costs ~20% on prose only
(MTP acceptance). Same binary and flags measure 31-52 tok/s here vs 24-27 in the 2026-08-25 sweep harness
(700-token answers) - unexplained, flagged. Sampling decision: servers keep their defaults (fork 1.0, llama 0.8
+ its top-k 40/top-p 0.95/min-p 0.05); Hermes sends `temperature: 0.6` via `custom_providers[].extra_body`.

### Tail-width prefill chunks: tried and reverted (2026-08-26)

Hypothesis: a short turn's new tokens pay for a full 256-wide padded chunk (72 tokens -> 1.5 s). Implemented 64/128-wide
tail chunks in `_generate_spec` (own captured jits, warmed up, cached); outputs byte-identical to the 256-only path. Result:
no change - 57 tokens 2.35 s vs 2.31 s TTFT, 72 tokens 47 vs 52 tok/s. The cost per chunk pass is ~0.55-0.65 s regardless
of width (2212 tok = 10 passes / 5.4 s, 728 = 4 / 2.5 s, 57 = 2 / 2.3 s with ~1 s first-pass setup). A 256-token chunk is
~18 ms of weight streaming, so the pass is launch-latency-bound: the captured prefill graph is 1437 kernels (~0.4 ms each).
Levers are kernel count per chunk (fusion) or per-launch latency (this box drives the GPU over PCIe 4.0 x4 through a
switch: NucBox M8 OCuLink -> DEG1), not chunk width. Also seen: the ~3 s prefix-snapshot clone lands on the request
*after* a >=1024-token conversation, which is most of the TTFT noise in short benchmarks.

### DFlash2 K=7 retraction (2026-08-26, later)

The K=7 "warm-up" (0.32 -> 0.9 acceptance, 66-70 tok/s on new prompts) was state corruption: on our Vulkan build of
PR #27342, the first request after server start matches MTP's greedy output exactly, and every later request is
degenerate ("I\n\nI\n\nI...", "Include a brief docstring. Include a brief docstring...") and non-deterministic across two
identical greedy runs (`sweeps/dflash2-20260826/lossless_k7*_*.txt`). Repetition drafts trivially, hence the acceptance.
Speed numbers from any DFlash2 K=7 server after its first request are invalid. MTP vs no-spec diverge only at near-tie
tokens (numeric noise of batched verify), which is the normal llama.cpp behaviour. DFlash2 stays off; K=5 text check pending.
K=5 text check: coherent output, diverges from no-spec only at near-tie tokens like MTP (proseA at the same character, 378),
but 32-34 tok/s vs MTP's 39. Final: DFlash2 (PR #27342) on this Vulkan build is correct-but-slower at K<=5 and broken at
K=7; MTP remains the llama.cpp drafter. `build_dflash2/` kept for re-testing when the PR lands upstream.
Bus test (llama, 33K prefill at 489 tok/s): GPU busy mean 81%, 84% of samples >= 76%, GTT 104 MB -> llama's long prefill
is compute-bound; an x16 slot buys <= ~20% there. The fork's chunked prefill is measured separately (`forkbus.sh`).

### Per-request tokenization and snapshot cooldown (2026-08-26, late)

`serve.py` re-tokenized the whole rendered prompt every request: `prep` 3 ms at 72 tokens, 283 ms at 11K, 850 ms at 33K,
1.7 s at 65K. `SimpleTokenizer.encode` tokenizes the text between special tokens independently, so pieces are now memoized
(`_encode_piece`, 8 M chars bound, pieces < 32 chars not cached). CPU test (`sweeps/tokcache_test.py`, 120-turn synthetic
chat, ids asserted equal to the uncached encoder): 31.6K tokens 44 ms vs 873 ms, 61K 55 ms vs 1,682 ms, 120K 87 ms vs
3,206 ms. Snapshots: a `MemoryError` in `_pick_prefix_state` used to set `max_snapshots = 0` for the life of the process;
it now drops the saved slots and pauses snapshots for `PREFIX_SNAPSHOT_PAUSE_S` (600 s), then retries.

### Host-side request overhead removed; snapshot tiers; periodic checkpoints (2026-08-26, afternoon)

cProfile of a 2202-token prefill (`sweeps/dflash2-20260826/profile7c.out`): 6.4 of 11.4 s in `_apply_map_to_tensors`.
Every `Tensor.realize` walks all live Tensors (~250K in this process), so any fresh Tensor on the request path costs
~0.2 s of Python. Three commits remove them: prefill chunks are slices of one prompt buffer written by a direct copy
(`582d28b42`, `741f61e90`), checkpoints move by device-to-device `Buffer.copy_from` (`741f61e90`), one realized
temperature tensor per value (`345fb79d4`). Per 256-token chunk host time 195 -> 6 ms; 2202-token request + 20 tokens
5.68 -> 3.67 s; 63-token request 1.82 -> 0.95 s; greedy tokens identical throughout. GPU time per chunk is ~0.26 s
(six graphs, ~50 TFLOPS sustained), so prefill is now ~900 tok/s here vs ~400 in the morning.

`1cda11be6`: snapshots are raw Buffers moved by SDMA copies; `--host-snapshots N --host-snapshot-gb G` (default off,
~2.2 GB per snapshot at 98304) keeps evicted states in pinned host buffers and restores them on a prefix match
(host restore == VRAM restore, `test8v2.log`); `--checkpoints 3 --checkpoint-every 4096` takes recurrent-state
checkpoints during prefill so a mid-conversation divergence resumes from the nearest one (`test9.log`: 10.55 -> 6.84 s).
Known: a continuation resumed after generated tokens can differ at near-ties from a cold prefill of the same tokens
(decode vs prefill kernels), like llama.cpp's MTP vs no-spec. Startup after a SIGKILLed server can fail with KFD EAGAIN
for a while; the harness retries (`test8.sh`).
