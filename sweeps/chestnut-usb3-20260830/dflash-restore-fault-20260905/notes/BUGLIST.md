# tinygrad fork — bug list (accurate as of 2026-09-05, post upstream-rebase)

Branch `amd-qwen-on-master`: our 28 commits rebased onto upstream master (479e077ec), 3 copyin
commits dropped, adaptive-wait re-added. Validated: imports OK, USB smoke test OK, MTP baseline
**80 tok/s @ 3.08 tok/step, coherent** (up from prior 75 @ 2.83), on `performance` governor
(PPD now masked so it stays pinned). Dock currently on ed4e39b handmade firmware (no C450) USB3.

## RESOLVED — USB copyin corruption  [FIXED UPSTREAM]
- Was: intermittent GCVM_L2_PROTECTION_FAULT wild write / device hang; garbage read from a recently
  copied-in buffer -> wild OOB write. Chased into firmware (C450 idle-wait) but that was the wrong layer.
- ROOT CAUSE + FIX: upstream tinygrad `#17969` (stale-sentinel: SDMA polled a 4B sentinel that could
  already match old copyout/copyin data -> copied stale bytes before the real data landed) + `#17972`
  (one-byte tear-proof drain fence). Our fork's copyin commits (e1dfe3e30/0105fa1be/9c58a2f85) were
  superseded and dropped in the rebase.
- PROVEN: repro.py (sweeps/chestnut-usb3-20260830/repro-f2-corruption) clean on upstream master +
  stock/no-C450 firmware; MTP decode coherent at 80 tok/s over USB. C450 firmware is now unnecessary.

## ACTIVE — DFlash decode wild-write  [SEPARATE BUG, base DFlash path]
- Symptom: DFlash spec-decode faults on the first decode request (SERVES/warms up clean, faults on
  the request). "hang report ... signal not set to N, but N-1" + GCVM_L2_PROTECTION_FAULT.
- **Not copyin** (copyin is fixed; MTP on the same main-forward + KV path is clean at 80@3.08).
- **Not XCTX-specific**: XCTX=0 AND XCTX=16 both fault identically (faultmap_events=139 each). So it's
  in the BASE DFlash decode path, not the cross-step buffer code.
- FAULTMAP evidence (2026-09-05, first fault): fault_va=0x2000cc1c4000, **rw=1 (WRITE)**, cid=8,
  permission fault; overrun-src = a **12KB (0x3000) block**, wild write lands **~70MB (0x42fd000)
  past its end**. 12KB ≈ a (1, K+1=4, dflash.dim=1536) half tensor = a drafter intermediate.
- So: a kernel in the DFlash drafter/decode path computes a garbage WRITE index into a small buffer.
  The DFlashLayer attention (dflash.py:75-107) uses fixed int rope positions + standard tensor ops
  (no obvious computed-index store). Candidates to examine next: the main-forward dflash_hs snapshots
  + fuse + output(dh) lm_head gemv (amd_gemv custom kernel), token_embd(block) gather, pick(out,j_last).
- **ROI note (from sweeps/qwen38-x-ecosystem + splizard retraction):** even bug-free, DFlash XCTX=0
  measured 68@2.53 < MTP; only non-fixed XCTX>0 might marginally beat MTP (~76 vs 75-77). The research
  ranked GDN-aware imatrix quant #1 (highest payoff, no fork code) and a TRAINED DFlash2/DSpark drafter
  #2 (not our current impl). So deep-fixing our current DFlash impl is low-ROI vs those levers.

## Commit-cleanup notes (for "which commits to keep")
- Drop/keep-off: the DFlash-XCTX WIP commit (4b5c43f7e) — dflash decode faults; keep behind a
  default-off flag if kept at all.
- The sweeps research docs live on branch `chestnut-sweeps-docs` (qwen38-x-ecosystem-20260904,
  qwen38-speedup-research-20260904, docs/development/qwen38-mtp-fork-splizard.md).

## DFlash wild-write — NEW EVIDENCE (2026-09-05, non-perturbing hang_report)
- **Deterministic, first decode step.** Both XCTX=0 and XCTX=16 fault at var_vals={'start_pos': 29};
  the request was a 29-token prompt (in: 0+29), temp=0 -> the fault is the FIRST decode step, every run.
  Reliable on-demand repro (not a random timing roll).
- Wild WRITE cid=8 rw=1; overrun region VARIES (132MB KV block @ XCTX=0 vs 12KB buffer @ XCTX=16) ->
  garbage write ADDRESS, consistent TRIGGER (DFlash first decode step). MTP first step (same prompt) clean.
- HANG_DEBUG (per-kernel GPU progress signal) avoids it -> consistent with a missing GPU-side
  producer->consumer dependency that the extra serialization papers over.
- Instrumentation available: SQTT is already wired (SQ_THREAD_TRACE_*, SQTT_INST_PC per-wave PC trace to
  VRAM via GPU packets; enable via VIZ>=2 or SQTT env). Post-hang wave-PC / VM-fault regs readable over the
  FTDI debug port (research in progress). cid=8 gfx11 GC-VM client decode: TBD (research).
- NEXT: use SQTT / post-hang wave-PC to name the faulting kernel at the first decode step, then find the
  missing dep (likely a DFlash drafter kernel reading a snapshot/ctx before its producer, or attn KV write
  with a bad position specific to the DFlash chunk shape).

## DFlash — ROI REVERSAL (2026-09-05): clean DFlash BEATS MTP
- A DFlash XCTX=0 request that did NOT fault ran **82 tok/s @ 3.33 tok/step** — BEATS MTP's 80@3.08.
- The earlier "67@2.63 < MTP" number was under HANG_DEBUG (perturbed/serialized); UNPERTURBED DFlash is faster.
- The fault is INTERMITTENT, not deterministic: a short 40-token request was clean; longer requests fault.
  start_pos=29 (first decode step) is just the earliest step it CAN fire.
- => Fixing the intermittent wild-write makes DFlash a real win over MTP. cid=8=TCP shader VMEM store with
  garbage address; producer->consumer visibility hazard (serialization hides it).
- WAVEDUMP instrumentation added (ip.py _dump_hung_waves, env WAVEDUMP=1): post-hang SQ wave-grid scan via
  SQ_IND_INDEX/DATA over USB -> resident-wave PC/TRAPSTS/HW_ID, zero perturbation. Need a fault to trigger it
  (looping long requests).

## DFlash wild-write — "FIXED" claim DISPROVEN (see below), STILL OPEN
- CONFIRMED (holds): debug-port wave dump proves faulting shader = attn KV-writer (cid=8 TCP store), garbage
  write address ~start_pos scale; first decode step; MTP clean on same path.
- DISPROVEN mechanism #1 (sp_t cross-queue copy): sp_t = `sp.cat(nt,nk).contiguous()` is ALL-COMPUTE (E kernels),
  NOT an SDMA copy. The "build sp_t as one compute kernel" fix was reverted; it changed nothing real. The 74-clean
  run was per-instance luck (see memory validate-heisenbug-fixes-across-many-fresh-runs) — a fresh compare faulted req#1.
- DISPROVEN mechanism #2 (same-queue serialize, hcq.py e0faf3771 keep self-dep on USB): server2 STILL faulted with
  serialize active (cid=8, start_pos=25, first request). Costs ~13% tok/s. Now env-gated HCQ_USB_SERIALIZE (default 1).
- Garbage start_pos VARIES per fault (381k, 565k positions) — NOT a consistent stale value; a genuinely garbage index.
- OPEN QUESTION the register dump answers: is the garbage in a uniform SGPR (sp_p[0]/kvh base) or a per-lane VGPR
  (start_pos-derived offset)? That names the true producer. Hunt running: HCQ_USB_SERIALIZE=0 + AMD_USB_SPIN_MS=0,
  WAVEDUMP=1, long requests, restart until _dump_hung_waves prints SGPRs/VGPRs of the faulting wave.
- Perf when it does NOT fault: XCTX=0 ~72-82 tok/s @ 2.96-3.33 (>= MTP 80@3.08) — so a real fix makes DFlash a win.

## USB transport follow-ups (from external nusb/USB4 dev, 2026-09-05)
- **copyin ~300MB/s -> ~600MB/s**: our `_copyin` (ops_amd.py:663) is confirmed canonical (512K ASMedia SRAM = our 2x256KB bounce windows, sentinel-poll + drain fence per chunk). Bottleneck is per-256KB submission+poll overhead. External nusb impl hits ~600MB/s (up to 4GB) by using >=8MB USB bulk submissions and letting the controller stream through SRAM in HW. LOW PRIORITY for us (weights load once) but real; 10G-USB3 users would see ~800MB/s.
- **handmade USB4 @ 20G** (doubles the link): mode bit "0=10G, set 1=20G" must be sent to trigger the downstream query chain. Works on Linux ASMedia host (ASM4242); macOS rejects it (Apple 10G-only). Explains stock=USB4/TB4 vs handmade=USB3-only. In USB4 mode GPU enumerates native-PCIe amdgpu (DEV=AMD). USE AS WILD-WRITE TESTBED: if the KV-writer fault vanishes on native-PCIe, it's USB-HCQ-transport-coupled; if it persists, it's pure GPU-side index math. Missing: sleep/reconnect power-mgmt path (bench-only).

## DFlash wild-write — ROOT CAUSE FOUND (2026-09-05 evening): firmware F0 stream-write ARM RACE drops host->GPU dwords
- Chain: garbage start_pos in attn KV-writer <- sp_t E-kernel reads its arg <- per-call var patch is a host->GPU dword write
  over USB (`_apply_var_vals`: q_sints go to the bound graph's hw_page, mv_sints to kernargs; `_submit` writes 4 ring dwords)
  <- each is `USBMMIOInterface.__setitem__` = `pcie_mem_write` = 0xF0-mode1 control + bulk OUT <- firmware
  `handle_usb_control` 0xF0 handler does `dma_dwords=0` + re-targets ADDR UNCONDITIONALLY, and `int0_isr` services
  CONTROL before BULK_DATA. Host bulk_write returns on the USB HW ACK (before the 8051 ISR), so the NEXT control (next patch
  or the doorbell) can run first -> the ACKed dword is dropped (audit Finding #3) or misdirected. = the F2/C450 race, on F0.
- Explains everything: intermittent (ISR-vs-control timing), per-instance variance, first decode step (fresh graph slot =
  uninitialized garbage), garbage VARIES, ANY host delay hides it (HANG_DEBUG, spin), serialize (GPU-side) can't fix it,
  MTP rarer (fewer changed vars/step), not XCTX-specific, copyin unaffected (F2 path already fixed).
- FIX (firmware): asm2464pd-firmware branch `fix-f0-arm-race` (on top of fix-f2-arm-race): drain in-flight OUT data before
  the 0xF0 reset. Compiled (9161B). NOT YET FLASHED (needs dock idle + unplug/replug).
- DETECTOR/DEFENSE (tinygrad): `usb_verify_write` (support/hcq.py, USB_VERIFY_WRITES=1 default): every host->GPU dword is
  read back and rewritten on mismatch; each drop is LOGGED+COUNTED ("usb: DROPPED host->GPU write"). Covers q_sints, mv_sints,
  ring dwords (_submit), hw_page upload (bind). A logged drop = direct proof, no fault needed. Guards stock firmware.
- VALIDATION PLAN: (1) detector run on UNFIXED firmware -> expect DROPPED lines (proof). (2) flash fix -> expect 0 drops AND
  0 faults across many fresh servers under the fault-prone config (serialize OFF, spin 0). (3) measure verify cost in tok/s.
- UPDATE: F2 (C450) firmware fix DROPPED from the flash candidate — superseded by upstream tinygrad's host-side copyin
  sentinel/drain-fence (#17969/#17972; repro proven clean on master firmware without C450, which is what the dock runs now).
  `fix-f0-arm-race` rebased: = master (ed4e39b, current dock fw) + ONE commit (6f000bd, the F0 drain). 9120B. Clean A/B:
  the only delta vs the running dock firmware is the F0 fix. F0 is a DIFFERENT engine (PCIe PIO stream via 0x7000) than F2
  (C412/C450 SRAM DMA); upstream's fence covers only the copyin path — kernarg/ring writes had no fence at all.
- AFTER validation: flip HCQ_USB_SERIALIZE default to 0 (it was a wrong-mechanism workaround costing ~13% tok/s).
- DETECTOR RESULT (inline USB_VERIFY_WRITES=1, unfixed fw): 4 reqs, 0 drops, 0 faults, 58-71 tok/s (vs ~72-82 unfenced).
  As anticipated the inline readback IS a delay before the next control -> the ISR wins -> race can't fire. => inline mode
  is a DEFENSE (~15-20% cost), not a detector. Adding USB_VERIFY_WRITES=2 (deferred: verify the previous submit's writes
  at the next submit, timing untouched) as the non-perturbing detector.
- 2026-09-05 late: PER-CALL host->GPU writes EXONERATED for the fault (deferred verify: 0 drops across all submits, "all
  landed" at fault time, 2 faulting instances). hw_page packet streams intact at fault (42k dwords, 0 mismatch). Build-time
  kernarg constant slots: check had a dict/list bug (0 checked) -> fixed, rerunning. cyrozap notes: the 8051 is 1T @ ~114 MHz
  -> ISR latency sub-us vs ~30-100us host control spacing -> the F0 ISR-order drop is essentially impossible unless the MCU
  blocks; consistent with 0 drops. Firmware F0 fix (2 commits on fix-f0-arm-race) = real latent race, NOT this bug's cause.
- PATTERN (3/3 sweeps tonight): the COLD-COMPILE instance (run 1, CACHE MISS, ~9 min build) runs clean; the WARM-CACHE
  instance (run 2, ~2.5 min build) FAULTS ON REQUEST 1 at the same point (timeline 37990 vs 37986). Per-instance variance
  may just be cold-vs-warm compile: different build timing and/or allocation order (compile-time temporaries shift the VA
  layout). Test: force cold (LLM_CACHE=0 / cleared compile cache) vs warm back-to-back.
- TRIGGER FOUND (2026-09-05 ~21:20): the fault hits instances that RESTORE from the LLM cache (log: "llm cache: loaded
  warmed-up model from .../f520608d0b15e154.pkl", startup ~113 s) on their FIRST decode step; freshly-warmed instances
  (full ~9.5 min warmup, which then SAVES the cache) run clean. 4/4 tonight. The cache key hashes the CONTENT of every
  tinygrad/**/*.py (cache.py _cache_key) => any source edit between launches forces a warmup (clean); a relaunch with no
  edits restores (fault). That is the entire "per-instance variance" / "VA-layout-dependent" history.
- Why restore differs: CapturedJit pickles its linear program; `linear` is a lazy cached_property, so a restored instance
  rebuilds the HCQ graphs AND uploads ~800 kernel binaries over USB back-to-back at its first decode call, then replays.
  Candidates: (a) kernel code corrupted in that upload burst (F2 re-arm race; the C450 fw fix was dropped from the flash
  candidate); (b) restored buffer set/layout (by-value small buffers, empty big ones, different allocation order).
  Hang report now diffs: constant kernarg slots, every kernel's code image in VRAM vs uploaded bytes, the sp_p block, and
  prints per-kernel code/kernarg/img-size (to map WAVEDUMP PCs). Run 3 of the current detector = restore => verdict.
- NOTE TO SELF: do not edit tinygrad sources while a restore-dependent run is in flight (it silently becomes a warmup run).
- 21:38 restore-fault #3 (full diagnostics): constant kernarg slots 0 mismatch (468/945/1884/1817 checked), hw_page intact,
  per-call writes landed. The FAULTING KERNEL IS NOT attn_prep: attn code=0x20001e35a000+0x3000, but every halted wave has
  PC 0x20001e73c2xx = gemv_q5k_5120_6144_t10_r2_u2_w128_g640_res (q5_K GEMV 5120->6144, T=10 = DFlash chunk width, _res
  epilogue), kernargs 0x200005abe520 = k[20]. Earlier "attn KV-writer" attribution was never checked against a code map.
- GEMV stores are `global_store_b32 v1, v0, s[8:9]` (SGPR base + 32-bit VGPR offset); s[8:9]=0x2000148f9d00 (sane y) in all
  waves; fault VA - base = 0xA1ED9300 (2.7 GB) => garbage ROW INDEX; two faults in this layout differ by exactly 4*N (one t
  step). row0 = (wg*WAVES+wave)*R from hardware IDs only => sane code cannot produce it.
- ALL halted PCs are within the FIRST 1024 BYTES of the image (+0x220..+0x39c) = "the first ~2 sectors" the F2 re-arm race
  drops. Hypothesis: the gemv's code image is corrupted in its first 1KB by the back-to-back upload burst of the restore path.
  Code-image-in-VRAM diff (via paddr reader) running now (warmup run 1 -> restore run 2). Firmware candidate rebuilt as
  fix-f0-f2-arm-race = C450 (F2) + both F0 fixes.
- 22:00 restore-fault #4 (5/5 restores fault; a 3-min reproducer). TRAPSTS=0x10000100 = MEM_VIOL (bit 8) + UTC_ERROR (bit 28)
  on every halted gemv wave => they ARE the faulting waves (own translation error), parked at scattered PCs inside the
  first 1 KB where the GOOD image has no stores => junk code in the first ~2 sectors (stale SRAM window content). Code
  readback failed on meta type (PCIAllocationMeta.mapping) -> fixed; next cycle (warmup+restore) gives the byte-level diff.
  Host-side guard drafted (scratchpad copyin-guard.patch.md): poll C450 idle before each F2 arm + verify program uploads.
- 22:24 NEGATIVE RESULT: repro-f2-rearm/repro.py (800 x 8-16 KiB uploads, synchronize between, unfixed fw ed4e39b7):
  0/800 corrupted back-to-back (5.0 s) and 0/800 at GAP=10 ms. The plain copyin path does NOT lose the head of small
  transfers. Reader (paddr walk via dev.iface.dev_impl, large_bar) verified live: 64 KiB round-trip matches.
- CORRECTION: the resident gemv waves are BYSTANDERS. After a GCVM fault the VMID's translations are poisoned, so every
  wave touching memory afterwards shows UTC_ERROR|MEM_VIOL; wave residency at halt != fault origin. FAULTMAP geometry
  identifies the writer: overrun-src 0x2000aa000000 size 0xa00000 = 10 MiB = one layer's KV cache (4 x 8204 x ~300 B);
  fault +198 MB past it = KV write at position ~690k => attn_prep with garbage start_pos (the ORIGINAL attribution).
- Decisive readback this cycle: "sp_p of k[j] attn_prep ... [start_pos, n_tok, n_keep] = ...; kernels touching it: [...]"
  (works now). Garbage => producer E-kernel / ordering on the first replay of a RESTORED graph (restored-by-value arena
  content is garbage until the producer runs; a warmup instance's buffer already holds sane values, hiding a missing
  dep). Sane => attn's read path (scalar load / K$ / pointer).
- 22:37 restore-fault #7 VERDICT (reader working): kernel code images 163 verified / 0 corrupted (copyin corruption DEAD);
  sp_p block @0x200014800000 = (29, 10, 5) SANE at fault time; producer k[0] precedes attn k[8]; NO per-call slot carries
  start_pos (packet syms = timeline signal addr/values only; kernarg syms = 2 input pointers) although var_vals has it =>
  the captured decode graph has no symbolic dependence on start_pos. Leading hypothesis: first replay of a RESTORED graph,
  attn reads the block before k[0]'s store is visible and sees the pickled warmup-time arena content (garbage-as-int
  ~690k); warmup instances read a stale-but-sane value in the same race. Next: identify k[0] and how position flows.
- 23:46 ROOT CAUSE PROVEN: tinygrad AMD scratch regrowth (_ensure_has_local_memory -> _realloc frees the old scratch) vs the
  scratch base baked into graph packets at exec. Restore links graphs lazily => early graphs baked with the 80M scratch at
  0x2000b4000000, later regrown to 100M@0x2000bc000000 (80M freed); fault VA 0x2000b82ad000 inside the freed range; all four
  pending graphs flagged STALE. Fix afb30dc45: keep old scratch buffers mapped (AMD_SCRATCH_KEEP_OLD=1). Validation running.
