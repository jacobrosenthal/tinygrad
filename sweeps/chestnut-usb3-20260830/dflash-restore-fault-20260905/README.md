# DFlash first-decode-step GCVM fault — investigation log (2026-09-05)

Symptom: with the DFlash2 drafter (`DFLASH=... DFLASH_BLOCK=6 DFLASH_NOSEL=1 DFLASH_XCTX=0`, Qwen3.8-27B UD-Q4_K_XL over
the chestnut USB3 dock, dock firmware `ed4e39b7` = master, no C450), some server instances fault on their FIRST request
(`GCVM_L2_PROTECTION_FAULT`, cid 8, write; hang report "signal not set to 37990, but 37986"); others run clean for
hundreds of requests. MTP on the same path: clean (80 tok/s @ 3.08 tok/step).

**Trigger (established 21:20, 6/6 vs 0/6): instances that RESTORE from the LLM cache (`llm cache: loaded warmed-up model
from ~/.cache/tinygrad/llm/f520608d0b15e154.pkl`, ~2.5 min startup) fault on request 1; instances that do a full warmup
(~9.5 min, `llm cache: stale ... reloading`, which then SAVES the cache) never fault.** The cache key hashes the content of
every `tinygrad/**/*.py`, so any source edit between launches turns the next launch into a warmup. That is the entire
"per-instance variance" / "VA-layout-dependent" history, including every "fix validated" moment (see log).

Rule learned the hard way: never edit tinygrad sources while a restore-dependent run is in flight, and never truncate logs.

## Chronological test log (all times 2026-09-05, local)

| time | test (script / config) | instance kind | result | files |
|---|---|---|---|---|
| 16:23 | baseline MTP K=3 ctx 8192, amd-qwen-on-master@1f3d594dc, governor powersave | warmup | 80 tok/s @ 3.08 | logs/baseline-mtp-* |
| 16:33 | baseline serve (same) | warmup | 80 tok/s @ 3.08, coherent output | logs/baseline-serve-* |
| 17:03 | DFlash XCTX=0 | (after edits) | 1 hang report (fault) | logs/dflash-x0.log |
| 17:09 | DFlash XCTX=0 with HANG_DEBUG=1 ("which kernel") | warmup (HANG_DEBUG is in the cache key) | no fault -> misread as "serialization hides it" | logs/dflash-hangdbg-* |
| 18:46 | DFlash-vs-MTP timing, XCTX=0 and XCTX=16 | restore | both fault (IH faultmap events 9274 / 9302) | logs/dflash-compare-*, cmp-x.log |
| 18:57 | soak XCTX=0 SPIN_MS=0 after "HCQ core acquire fix" | warmup (after the edit) | 100/100 clean -> misread as "core fix validated" | logs/dflash-soak-* |
| 19:23 | multi-server soak, 2 fresh servers x 60 | server1 warmup, server2 restore | server1 60/60 clean; server2 fault on req 1 | logs/dflash-multisoak-* |
| 19:46 | WAVEDUMP hunt, serialize ON (hcq e0faf3771) | warmup | 8 clean | logs/dflash-wavedump-* |
| 20:00 | WAVEDUMP hunt, serialize OFF, SPIN_MS=0 | run1 warmup / run2 restore | run1 8 clean; run2 fault req 1 + SGPR/VGPR dump | logs/dflash-wavedump2-* |
| 20:23 | inline write-verify detector USB_VERIFY_WRITES=1 | warmup | 8 clean, 0 drops, 57-71 tok/s (fence costs ~15-20%) | logs/dflash-dropdetect-* |
| 20:37 | deferred write-verify USB_VERIFY_WRITES=2 | run1 warmup / run2 restore | run1 8 clean; run2 fault req 1, 0 drops, "all landed" | task-outputs |
| 21:12 | + build-time kernarg/hw_page diff | run1 warmup / run2 restore | fault: hw_page 42k dwords intact; kernarg check had dict bug | task-outputs |
| 21:35 | (fixed check) run 3 | restore | fault: kernarg slots 468/945/1884/1817 all match; hw_page intact; code check failed (no cpu_view) | task-outputs |
| 21:46 | + VRAM reader v1 | run1 warmup / run2 restore | fault: reader failed (meta type) | task-outputs |
| 22:04 | + VRAM reader v2 | run1 warmup / run2 restore | fault: reader failed (dev_impl path) | task-outputs |
| 22:22 | reader test on live GPU (scripts/test_readva.py) | - | 64 KiB round-trip matches (large BAR, PCIAllocationMeta.mapping) | task-outputs |
| 22:23 | repro-f2-rearm/repro.py, 800 x 8-16 KiB uploads, synchronize between, unfixed fw | - | 0/800 corrupted back-to-back; 0/800 at GAP=10 ms (NEGATIVE) | logs/repro-rearm-* |
| 22:22 | + VRAM reader v3 (verified) cycle | run1 warmup / run2 restore | pending at time of writing | logs/dflash-dropdetect2.log |

## What each readback ruled in / out

- Per-call host->GPU dword writes (kernarg syms, packet syms, ring): all landed at every fault (deferred verify, 0 drops).
- Build-time constant kernarg slots (468-1884 per graph) and the bound hw_page packet streams (up to 17.8k dwords): intact.
- Kernel code images: could not be read until 22:22 (reader path); next report has them.
- FAULTMAP geometry: overrun-src `0x2000aa000000` size `0xa00000` = 10 MiB = one layer's KV cache (4 heads x 8204 x ~300 B);
  fault ~198 MB past its end => a KV write at position ~690k => the attn KV-writer (`attn_prep`) with garbage `start_pos`.
- WAVEDUMP: resident waves at halt are `gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res` with TRAPSTS MEM_VIOL|UTC_ERROR, PCs in
  its first 1 KiB. Misread twice (first as attn, then as the gemv being the writer): after a VM fault the VMID's translations
  are poisoned, so every resident wave shows UTC_ERROR; residency != origin. The FAULTMAP identifies the writer.
- No kernel in the pending graphs takes `start_pos` as a kernel argument (only `inp_0_0`/`inp_1_0` buffer pointers are
  patched per call) although `var_vals={'start_pos': 29}` is passed: start_pos enters via the packet stream (symbolic
  dispatch sizes) or was baked at capture. The 22:22 cycle's report lists packet syms and the `[start_pos, n_tok, n_keep]`
  block attn reads, plus which kernels touch it.
- Firmware F0 stream-write race (0xF0 handler resets an in-flight stream; int0_isr serves CONTROL before BULK_DATA) and the
  missing per-TLP latch handshake: real latent races, fixed on `asm2464pd-firmware` branches `fix-f0-arm-race` (master+F0)
  and `fix-f0-f2-arm-race` (C450+F0), compiled, NOT flashed. Not the cause of this fault (all host writes verified landed;
  the 8051 is 1T @ ~114 MHz, ISR latency sub-us vs 30-100 us between host controls).

## Restore path (tinygrad/llm/cache.py, engine/jit.py) — why only restored instances

CapturedJit pickles its linear program; `linear` is a lazy cached_property, so a restored instance rebuilds the HCQ graphs
(and uploads all ~800 kernel binaries) at the first decode call and replays immediately. Buffers <=16 MB not reachable
from the model (jit intermediates, incl. the memory-planned arenas holding tiny blocks such as `[start_pos,n_tok,n_keep]`)
are restored BY VALUE with warmup-time contents; >16 MB buffers are restored EMPTY (new addresses). A warmup instance's
arenas hold sane values from the eager runs before capture. A consumer that reads a block before its producer has written
it on the first replay is therefore harmless on warmup instances and fatal on restored ones.

## Files
- `logs/` every log and result file of the day (never truncated again: new runs use `scripts/restore_cycle.sh`).
- `task-outputs/` background-task summaries (grep'd hang-report excerpts; the full reports are in the logs when not truncated).
- `isa/` `attn_prep_*` and `gemv_res_t10_*` ELFs from the compile cache + `llvm-objdump-20 --mcpu=gfx1100` listings.
- `notes/BUGLIST.md` the running bug list (chronological, with reversals); `notes/copyin-guard.patch.md` host-side copyin
  guard plan (C450 poll, verified uploads, leading sentinel); `notes/upstream-hcq-usb-coherence.md`; `notes/ceiling-todo.md`.
- `scripts/` the hunt/detector/validate/A-B scripts as run.
- `asm-docs/` text extracted from the ASM2464PD/PDX datasheets, reference schematics and the MP tool manual (PDFs in
  `~/z/asm2464pd-firmware/`). Datasheets contain no register map; PD vs PDX differs by pin-mux functions + PCIe switch.
- Related: `../repro-f2-rearm/` (regression control, negative), tinygrad commits `85296d116` (WAVEDUMP registers),
  `c9df7365f` (write-verify fences) + uncommitted hang-report readbacks in `tinygrad/runtime/support/hcq.py`.

## 22:37 verdict (restore-fault #7, full readbacks; logs/2222-restore-cycle-dropdetect2.log)
- Kernel code images: 163 verified, 0 corrupted (23+31+36+73 over the four pending graphs). Copyin/code corruption: DEAD.
- `[start_pos, n_tok, n_keep]` block @0x200014800000 = (29, 10, 5) at fault time: SANE. Its producer ran in the previous
  graph (37986, completed, hence not listed) behind the timeline wait; every kernel touching it in the pending graphs is a
  consumer (gdn_step k[0], attn_prep k[8], attn_pfd, attn_merge, gdn_conv). "Read before the store lands": DEAD.
- Per-call patched values: only timeline signal addresses/values and two input pointers. Constant kernarg slots and hw_page
  streams intact (again).
- Open lead: fault VA = first 10 MiB (KV) block base + 209,489,920 B = 19.98 x 10 MiB, i.e. where layer ~20's KV block would
  sit if the 24 KV caches were contiguous (as in the warmup process); in the restored process they are re-created empty
  and allocated separately (one 10 MiB block below a 290 MB gap). A device address from the OLD layout surviving the
  restore as data? Next cycle prints every kernel's buffer-argument VAs and the map of all >=4 MiB blocks.

## 22:50 pickle analysis (notes: pickle-walk)
- Scanned f520608d0b15e154.pkl (398 MB) for 8-byte values in the device VA range: 1118 hits, 134 page-aligned. pickletools walk:
  all inside by-value buffer payloads (491,520 B BYTEARRAY8 = a T=10 fp32 intermediate; float bit patterns) or inside compiled
  kernel binaries (BINBYTES after the LLVM IR string of each kernel). No pointer tables. "Stale device pointer as data": DEAD.
- The captured linear pickles each kernel's IR source AND compiled lib; restore re-creates AMDProgram from the pickled lib.
- `E_3` (producer of the [start_pos, n_tok, n_keep] block) takes two POINTER args: start_pos enters the graph as a tiny
  input TENSOR (`inp_1_0`, used by exactly one kernel), not as a kernel scalar; the `start_pos` var_vals entry is unused
  by these graphs. Its per-step value is a 4-byte host copyin; the block read (29,10,5) at fault time, so this path is fine.

## 22:58 fault #8 with the address map (logs/20260905-224309-restore-cycle.log)
- fault_va=0x2000b8292000 (varies per instance: b67c3000, b67c9000, b8292000 — a garbage OFFSET, not a stale pointer).
- 22 x 10 MiB blocks = the attention layers' KV caches, scattered (0x200033000000, 0x200089800000, ... 0x2000aa000000 = the
  LAST layer's). The only buffer base within 2 GB below the fault is that last KV cache: attn_prep k[121] (cache arg) and
  attn_pfd k[122]. Delta = +226.6 MiB. => the writer stores relative to the last layer's KV cache with a garbage offset.
  A same-size garbage write from any OTHER layer lands inside neighbouring mapped blocks (silent corruption), which is why
  the fault surfaces at the top layer. All 32 attn_prep kernels read the same sane [start_pos,n_tok,n_keep]=(29,10,5).
- Loaded attn_prep ISA variant: image 0x26e8 = isa/attn_prep_*_c722d5ae|dc921509 (scalar `s_load_b32 s29, s[28:29], null`).
- Pickle scan: device-VA-looking values are float/code bit patterns inside by-value payloads; no pointer tables.

## 23:05 experiment: park instead of store (tinygrad/llm/amd_prefill.py attn_prep, DEBUG guard)
`if ((u32)start_pos >= MAXC) for(;;) asm volatile("s_sleep 127" :: "s"(sp_p[0]), "s"(tok), "s"(wg_id), "s"(sp_p[1]),
"s"(start_pos), "s"(0xdb9))` — a wild position now parks the workgroup with its values pinned in SGPRs (no VM fault, so no
VMID poisoning); the hang report's timeout path now runs the wave dump (s0..s63). If the restore instance HANGS: the dump
shows the exact bad start_pos/tok/wg the kernel computed. If it FAULTS anyway: the writer is not attn_prep's position path.
If it runs CLEAN: the guard changed the codegen/timing (note and revisit). Cycle: RUNS=2 (warmup + restore).

## 23:30 ROOT CAUSE (code): lazily regrown scratch vs scratch base baked into graphs
- `AMDDevice._ensure_has_local_memory(private_segment_size)` (ops_amd.py ~1151) is called from every AMDProgram.__init__; when a
  program needs a larger private segment it REALLOCATES `self.scratch` (`self._realloc(old, size)`: new VA, old freed) and
  recomputes `tmpring_size`.
- `AMDComputeQueue.exec` bakes `prg.dev.scratch.va_addr` (COMPUTE_DISPATCH_SCRATCH_BASE) and `prg.dev.tmpring_size` into the
  graph's packet stream at GRAPH BUILD time. A graph built before a later regrowth keeps spilling into the freed old scratch.
- Warmup instances: all programs are created by the eager runs before capture => scratch already final when graphs are baked.
  Restored instances: graphs are linked lazily, in order, at the first decode call; graph 1 is baked with the small scratch,
  a later graph's heavier kernel regrows it => graph 1's spills go to freed memory => GCVM write fault at old_scratch + wave
  offset (varies by wave: +199.8 / +226.6 MiB into the freed range = the 290 MB gap below 0x2000bc000000).
- Spilling kernel = the T=10 (DFlash chunk width) `gemv_*_t10_*` variants (195 scratch ops in gemv_q5k_5120_6144_t10_res); the
  resident faulting waves were exactly that kernel. MTP's t6 variants barely spill => MTP clean. DFlash-only, restore-only.
- The attn_prep parking guard (23:20 cycle) was present (s_sleep 127 in the loaded image) and never fired: attn exonerated.
- Fix (fork, immediate): never free an old scratch buffer on regrowth (keep it mapped; baked bases stay valid; cost <= 2x final
  scratch). Fix (upstream proposal): reserve the scratch VA once and grow the mapping in place, or patch live graphs' baked
  scratch base/tmpring on regrowth. Upstream repro: capture a JIT with a spilling kernel, then compile a heavier-spilling kernel
  (scratch regrows), replay the first JIT => spills hit freed memory.

## 23:46 PROOF (cycle 20260905-233219, AMD_SCRATCH_KEEP_OLD=0, SCRATCH_DEBUG=1; restore instance, fault on request 1)
- Restored process, first decode call, scratch regrowth while graphs were being linked (old buffer freed each time):
  24M@0x200001000000 -> 42M@0x2000ac000000 -> 60M@0x2000b0000000 -> 80M@0x2000b4000000 -> 100M@0x2000bc000000.
- Hang report: all four pending graphs baked with scratch base 0x2000b4000000 (+80M, tmpring 0x6a200) => STALE (device's
  current scratch is 0x2000bc000000+100M). Fault VA 0x2000b82ad000 is INSIDE the freed 80M range [0x2000b4000000,
  0x2000b9000000). Earlier faults (0x2000b67c3000, 0x2000b67e4000, 0x2000b8292000) fall in the same freed ranges.
- Conclusion: the GCVM write fault is a spilling kernel (T=10 gemv) writing scratch through a graph's stale baked scratch
  base into freed memory. Firmware, copyin, drafter and attention are not involved.
- Cycle B (AMD_SCRATCH_KEEP_OLD=1): 3 restored instances x 8 requests — result appended below when done.

## 23:59 FIX VALIDATED (cycle 20260905-234743, AMD_SCRATCH_KEEP_OLD=1): 3 restored instances x 8 long requests, 0 faults
Same fault-prone config (serialize OFF, spin 0, DFlash XCTX=0) that faulted on request 1 in 9/9 restored instances tonight.
Regrowth sequence identical (24->42->60->80->100 MB) but every old buffer kept mapped; the graphs' baked bases stay valid.

## 00:05 cleanup after the fix
- Reverted the HCQ same-queue serialize workaround (was ~13% tok/s), defaulted USB_VERIFY_WRITES=0 (was 15-20%), removed the
  attn_prep parking guard, added DFLASH_XCTX/DFLASH_BLOCK/DFLASH_NOSEL/MAX_T/ATTN_QT/NGRAM_DRAFT to the LLM-cache key (a restore
  under a different value would replay graphs captured for another). Diagnostics (hang-report readbacks, WAVEDUMP, FAULTMAP,
  SCRATCH_DEBUG) stay; they cost nothing unless something faults.
- Next: scripts/perf_sweep.sh on RESTORED instances — MTP K=3/4/5, DFlash XCTX=0/16 — the throughput question that started this.

## 00:43-01:30 sweep port collision (invalid rows)
The X API MCP connector (`@xdevplatform/xurl mcp https://api.x.com/mcp`, started 00:43 when the xapi tools were probed) listens
on 127.0.0.1:8080 — the same port the benchmark servers AND the production unit use. From then on every server launch saw an
instant HTTP answer on :8080, the readiness check passed at 0 s, the tinygrad server could not bind, and the summary picked up
stale `gen:` lines: mtp-k5 run 2, dflash-x0, dflash-x16 and the first sampling legs are INVALID. Sweep scripts now use :8082
and require tinygrad's JSON on /v1/models. Operational note: xurl on :8080 blocks the production server too.

## 01:00 sweep collision (invalid rows, reruns queued)
A waiter for the selector sweep keyed on the previous (poisoned) sampling summary's DONE line and started at 01:00 while the
DFlash legs were still running; both scripts' killsrv killed each other's servers: dflash-x16 run 2 + all perfsel legs
("server did not come up") are invalid, and the sampling sweep's first legs may be. Fix: sweep scripts now take an exclusive
flock on /tmp/chestnut-sweep.lock (refuse to run concurrently); chained reruns wait on the running script's PID, not a DONE line.

## Sampling sweep (perf_sweep2.sh, 01:01-01:49, port 8082, valid legs only; 6 long prompts x 500 tok, restored instances)
`python3 scripts/perf_table.py logs/20260906-010104-sampling-summary.txt`; outputs in logs/sampling-outputs/<leg>.runN.reqI.json.

| leg (server flags / request temp) | runs | mean tok/s | min-max | tok/step | still thinking at 500 tok |
|---|---|---|---|---|---|
| mtp-t1.0-official (rp 1.0, top_p .95, top_k 20 / 1.0) | 1 | 61.3 | 49-73 | 2.67 | 2/6 |
| mtp-t0.6-p95k20 (rp 1.0, top_p .95, top_k 20 / 0.6) | 2 | 65.8 | 54-72 | 2.87 | 4/12 |
| mtp-t0.7-instruct (rp 1.0, top_p .8, top_k 20, presence 1.5 / 0.7) | 1 | 62.0 | 54-68 | 2.77 | 2/12 |
| dflash-t0.6-rp1.0 (block 6, no selector / 0.6) | 1 | 66.3 | 54-76 | 2.60 | 2/12 |
| dflash-t1.0-official (block 6, no selector / 1.0) | 1 | 61.0 | 53-70 | 2.48 | 1/12 |
| greedy reference (perf sweep, mtp-k3, temp 0) | 2 | 74.9 | 67-82 | 2.82 | - |

Notes: the official "thinking" settings (temp 1.0) cost ~18% vs greedy through acceptance (0.36-0.75 per request); temp 0.6 with
top_p/top_k ~12%. The two restored instances of mtp-t0.6-p95k20 produced IDENTICAL per-request numbers: the sampler RNG is seeded
the same in every process (fine for throughput rows, but "restores" are not independent samples of sampling variance).
LOST to the 01:00 collision and queued for rerun (chain step 2/3): mtp-t0.6-rp1.15-prod (production's exact settings),
mtp-t0.6-rp1.0, and mtp-t1.0-official run 0.

## DFlash XCTX legs, rerun after the collision (perf_sweep.sh ONLY=dflash, 01:49-02:16, port 8082, clean; logs/20260906-014939-perf-summary.txt)
| config (block 6, no selector, greedy, 8 long prompts x 500 tok) | restored runs | faults | mean tok/s | min-max | tok/step | req1 |
|---|---|---|---|---|---|---|
| dflash-x0 | 2 (+warmup) | 0 | 62.8 | 59-72 | 2.46 | 71 |
| dflash-x16 | 2 (+warmup) | 0 | 61.8 | 56-75 | 2.92 | 75 |
| mtp-k3 (00:xx, reference) | 2 | 0 | 74.9 | 67-82 | 2.82 | 82 |

XCTX=16 lifts acceptance (2.92 vs 2.46 tok/step; 3.73 on the first request) but the extra context per draft costs as much as it gains:
mean tok/s equal within noise. Both DFlash legs are ~16% below MTP K=3 WITHOUT the selector; the selector/block sweep (chain step 3)
is the number that decides DFlash. Restores are 3/3 + 2/2 fault-free (scratch fix holds under DFLASH_XCTX=16 too).

## Sampling legs lost to the collision, rerun (perf_sweep2.sh ONLY=..., 02:16-02:43, clean; logs/20260906-021607-sampling-summary.txt)
| leg (MTP K=3; server flags / request temp) | runs | mean tok/s | min-max | tok/step | still thinking at 500 tok |
|---|---|---|---|---|---|
| mtp-t0.6-rp1.15-prod (= production: --repeat-penalty 1.15 / 0.6) | 2 | 71.0 | 60-77 | 2.67 | 1/12 |
| mtp-t0.6-rp1.0 (--repeat-penalty 1.0 / 0.6) | 2 | 74.2 | 62-80 | 2.85 | 1/12 |
| mtp-t1.0-official (rp 1.0, top_p .95, top_k 20 / 1.0) | 2 | 62.0 | 54-71 | 2.68 | 4/12 |
| greedy reference (mtp-k3, temp 0) | 2 | 74.9 | 67-82 | 2.82 | - |

Production's `--repeat-penalty 1.15` costs ~4.5% (2.67 vs 2.85 tok/step: the penalty reshapes the target distribution away from the
MTP head's drafts). Temp 0.6 with repeat-penalty 1.0 is within noise of greedy. Qwen's card recommends repetition penalty 1.0 (and
presence penalty 1.5 only for the instruct preset, which measured 62 tok/s). Same prompts show the same thinking-budget behaviour
(1/12 unfinished at 500 tokens for both 0.6 legs). Production change (drop the penalty, or lower it) is a deploy decision.

## 02:44 selector sweep: the block-8 legs cannot start at MAX_T=12
`dflash-b8-sel` / `dflash-b8-nosel` die at load: `AssertionError: dflash K=7 needs 2K+1 <= MAX_T=12` (block 8 = 7 drafts; the fused
verify chunk is K+1 committed + K drafts = 15 tokens). Only `dflash-b6-sel` (K=5) runs in this sweep. Block 8 needs MAX_T=16
(kernels up to T=15; the 09-04 "MAX_T=16 overflowed 24 GB" was at 112K context, our sweeps run 8192) or K=5 drafts from the block-8
drafter (`MTP_K=5`). Both queued as perf_sweep_sel2.sh (chain4, after chain3).

## Selector sweeps (perf_sweep_sel.sh 02:44-03:45, perf_sweep_sel2.sh 05:38-, logs/*-perfsel*-summary.txt)
| config | MAX_T | mean tok/s | tok/step (req1) | startup warmup / restore |
|---|---|---|---|---|
| dflash-b6-sel (block 6, K=5, DFLASH_EAGER_SEL=1) | 12 | **5** | 2.4-3.0 (3.01) | 1335 s / 952 s |
| dflash-b8-k5-sel (block 8, K=5, selector) | 12 | **5** | same numbers as b6-sel | 1343 s / 953 s |
| dflash-b8-k7-sel-t16 (block 8, K=7, selector) | 16 | **4** | 2.7-2.8 (3.52) | 1761 s / 1181 s |
| dflash-x0 / x16 (block 6, no selector) | 12 | 62.8 / 61.8 | 2.46 / 2.92 | 588 / 195 s |
| mtp-k3 | 12 | 74.9 | 2.82 | 165 s |

The selector as implemented (`select_gpu` in its own TinyJit + host `.tolist()`, model.py DFLASH_EAGER_SEL) is ~15x too slow: 5 tok/s.
Restore startup grows from 195 s to 950-1180 s = the selector JIT compiles hundreds of kernels (the per-position walk is unrolled:
topk over the 248k vocab + gather + matvec + argmax + masked sums, x T positions); ~150 tiny launches per step at USB round-trip
cost (~0.5-1 ms each) = 75-150 ms/step. The acceptance side works: block 8 + K=7 + selector reaches 3.52 tok/step on the first
request (vs 2.92 best without it), which would be ~85-90 tok/s if the selector cost nothing. MAX_T=16 itself is fine at 8K context
(no OOM; the 09-04 overflow was at 112K). b6-sel and b8-k5-sel produce identical numbers (block 8 with 5 drafts = block 6).
NEXT: the selector must be ONE kernel inside the spec graph (custom HIP: per-position top-16 over the vocab + the greedy codebook
walk), not a tinygrad-op JIT. Until then DFLASH_EAGER_SEL stays off; DFlash without selector (62 tok/s) loses to MTP K=3 (75).

### perf_sweep_sel2.sh finished (05:38-08:04, logs/20260906-053754-perfsel2-summary.txt)
| config | MAX_T | mean tok/s | min-max | tok/step | req1 | restore s |
|---|---|---|---|---|---|---|
| dflash-b8-k5-sel (eager selector) | 12 | 4.9 | 4-5 | 2.53 | 5 | 953 |
| dflash-b8-k7-sel-t16 (eager selector) | 16 | 3.9 | 3-4 | 2.72 | 4 | 1179 |
| dflash-b8-k7-nosel-t16 (argmax drafts) | 16 | 55.2 | 50-62 | 2.59 | 62 | 214 |
| mtp-k3-t16 (control) | 16 | 74.8 | 67-82 | 2.82 | 82 | 165 |

MAX_T=16 alone changes nothing for K=3 (74.8 vs 74.9): the T=13-15 kernels are compiled but unused. Block 8 with argmax drafts is
WORSE than block 6 (55.2 vs 62.8): the 15-token verify costs more than its acceptance gain (2.59 vs 2.46 tok/step). So block 8 only
pays with the selector's acceptance (3.52 tok/step on req 1) at an argmax-like per-step cost -> the fused selector (chain6).
