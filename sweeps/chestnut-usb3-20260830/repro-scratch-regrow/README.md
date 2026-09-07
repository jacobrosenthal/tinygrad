# AMD/HCQ: graphs bake the scratch base, scratch regrowth frees it

Affects `tinygrad/runtime/ops_amd.py` (any AMD device; observed over USB on a 7900 XTX, gfx1100).

- `AMDProgram.__init__` calls `AMDDevice._ensure_has_local_memory(private_segment_size)`. When a program needs a larger
  private segment than any seen before, it does `self.scratch, ok = self._realloc(old, new_size)`: the old scratch buffer is
  freed and a new one allocated at a new VA; `tmpring_size` is recomputed.
- `AMDComputeQueue.exec` writes `prg.dev.scratch.va_addr` into `COMPUTE_DISPATCH_SCRATCH_BASE_LO/HI` and
  `prg.dev.tmpring_size` into `COMPUTE_TMPRING_SIZE` as packets. For an HCQGraph these packets are built once (bound
  hw_page) and replayed.
- Therefore: any graph built before a later regrowth keeps spilling into the freed old scratch. Symptom:
  `GCVM_L2_PROTECTION_FAULT` (write, client TCP) at `old_scratch + wave_offset`, the exact VA varying with which wave spills.

Trigger in practice: a program with a larger private segment compiled after a graph was captured. Hit here by the LLM-cache
restore path, which links the captured graphs lazily in order at the first decode call: graph 1 is baked with the initial
scratch, a heavier-spilling kernel in a later graph regrows it. A normally warmed-up process creates every program before
capture, so the scratch is already final when graphs are built — which is why it looked like an intermittent, per-instance
"wild write". Spilling kernel here: a T=10 q5_K gemv with 195 scratch ops.

Repro: `repro.py` (upstream API only: `Tensor.custom_kernel` with a `PROGRAM(sink, LINEAR, SOURCE)` carrying hand-written LLVM IR,
so the private segment is under control: a `[n x i32]` alloca with volatile accesses, 260 B/thread for n=64, 2052 B for n=512).

    DEV=AMD python3 repro.py            # 1. jit a 260 B-private kernel (3 calls: capture + replay)  -> graph holds scratch A
                                        # 2. run a 2052 B-private kernel once                       -> scratch B, A freed
                                        # prints both bases and asserts A != B
    DEV=AMD python3 repro.py --fault    # 3. replays the jit: GCVM_L2_PROTECTION_FAULT (write) inside A, device hang

Expected output (7900 XTX, gfx1100, over USB; same code path on KFD/PCI):

    graph captured with scratch 0x2000b4000000 (48 MiB), tmpring 0x...
    after a kernel with a larger private segment: scratch 0x2000b8000000 (384 MiB), tmpring 0x...
    the graph still dispatches with COMPUTE_DISPATCH_SCRATCH_BASE=0x2000b4000000, which _ensure_has_local_memory freed
    replaying the graph (expect GCVM_L2_PROTECTION_FAULT / device hang) ...
    <hang report: GCVM_L2_PROTECTION_FAULT ... write ... VA inside 0x2000b4000000+48M>

With fix 1 (`AMD_SCRATCH_KEEP_OLD=1`, this fork's default) `--fault` completes and prints the replay result.

Fixes:
1. Do not free the old scratch on regrowth (keep it mapped): stale baked bases stay valid, and each graph's own (smaller)
   tmpring keeps its waves inside their buffer. Cost bounded by the sum of previous sizes (<= 2x the final size with
   geometric growth). Implemented in this fork behind `AMD_SCRATCH_KEEP_OLD=1` (default on).
2. Reserve the scratch VA range once and grow the physical mapping in place (base never changes).
3. Patch the baked `COMPUTE_DISPATCH_SCRATCH_BASE`/`COMPUTE_TMPRING_SIZE` of live graphs on regrowth.

Validation (this fork, restored instances = the reproducing config), 2026-09-05: without the fix 9/9 restored instances fault on
request 1; hang report of the last one: all four pending graphs `baked scratch base 0x2000b4000000 (+80M) STALE`, device scratch
0x2000bc000000+100M, fault VA 0x2000b82ad000 inside the freed 80M range. With `AMD_SCRATCH_KEEP_OLD=1`: 3/3 restored instances x 8
long requests, 0 faults (same regrowth sequence, old buffers kept).

Log: `../dflash-restore-fault-20260905/` (chronological investigation, hang reports, wave dumps, ISA).

## 2026-09-06 10:00 first on-device validation (KFD over the USB4 tunnel; logs/)
All four legs printed the two bases (48 MiB at A -> 384 MiB at B, tmpring 0x41200 -> 0x201200) and asserted A != B — but the
`--fault` replays RETURNED `[0, 2, 4, 6]` on the fork with the old buffer freed AND on upstream master: no fault. Reason: the HCQ
allocator is an LRUAllocator; `_realloc`'s `free` parks the old scratch in the cache still mapped, and it is only unmapped when the
cache is released (memory pressure -> `free_cache()`, or reuse of the block by a same-size allocation). That is exactly why the
production fault needed a tight-memory restore to show up. Both repro.py and the unittest now call `dev.allocator.free_cache()`
after the regrowth (upstream commit amended to d1a6e5321); re-validation queued (chainK4).

## 2026-09-06 10:35-10:50 KFD validation, resolved: `repro_bound.py` / the unittest reproduce it deterministically
- The TinyJit form does NOT reproduce on any driver in this tree: hcq2 rebuilds the dispatch packets on every replay (`exec` runs per
  call, verified by counting), so the base is re-read from the device each time. Baked bases exist where a command stream is built once
  and re-submitted: a **bound queue** (`q.bind(dev)` caches the packet bytes) and the USB path (bound hw_page, packets patched in place).
- With a bound queue on KFD (repro_bound.py): after the regrowth + `free_cache()`, victim buffers allocated on the freed range receive
  the re-submitted queue's spills: **4096 corrupted words** (one wave, 64 lanes x 260 B) in the victim sitting at the old base — fork
  with AMD_SCRATCH_KEEP_OLD=0 and upstream master 479e077ec alike; **0** with the fix (fork default, upstream branch). A GCVM fault
  instead of corruption needs the range unmapped and unreused, which is what happened in production (memory-tight restore).
- Upstream package: branch `upstream-scratch-keep-old` in ~/z/tinygrad-master, commit **eec5fcb97** (6-line fix +
  test/test_scratch_regrow.py in the bound-queue form: passes with the fix in 1.2 s, fails without it with the corrupted-words assert).

## 2026-09-06 17:40 single-file form: `repro_scratch_uaf.py`
Self-contained (embeds the IR, no import of repro.py), no unittest: `cd / && DEV=KFD+AMD:LLVM PYTHONPATH=<tree> python3 repro_scratch_uaf.py`.
Exit 1 + "USE AFTER FREE" when the corruption is observed, exit 0 with the fix. Run from the tinygrad-master venv on KFD:
- 479e077ec (upstream master): `corrupted words per victim: [0 x12, 4096]` -> exit 1
- eec5fcb97 (upstream-scratch-keep-old): all zeros -> exit 0
The PR keeps the unittest (test/test_scratch_regrow.py, one commit with the ops_amd.py fix); this script is the hand-runnable form.
