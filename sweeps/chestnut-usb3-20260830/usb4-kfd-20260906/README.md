# USB4 / Thunderbolt tunnel: run the chestnut GPU as a native PCIe device (KFD) — experiment plan, 2026-09-06

Ranked #1 in sweeps/qwen38-research-20260906 (comms option C): every decode step today costs ~190-240 USB3 transfers (each MMIO dword
write = 0xF0 control + bulk OUT; each signal read = control + bulk IN) at 75-150 us = 15-25 ms of a ~37 ms step. Through a USB4/TB
tunnel the GPU is a plain PCIe device: MMIO ~1.5 us, DMA ~2.5-3 GB/s. Expected decode: 80 -> 120-145 tok/s (removes the USB round trips;
the remaining gap is Python + 4 graph launches per step). It also removes the whole F0/F2 firmware corruption class (no ASM firmware in
the data path at all).

## Evidence this works on THIS host (journal, 2026-09-05)
- 15:40:17 the dock (shipped firmware) enumerated as a TB device (`thunderbolt 0-3: new device found, vendor=0x1ca device=0xd666`),
  bolt name "USB4 NVMe SSD Pro Enclosure" (Gopod), policy iommu, authorized; PCIe tunnel 00:07.0 -> 53/54:00.0 ASM switch -> 55/56:00.0
  Navi31 switch -> `57:00.0 [1002:744c]`; iommu group 18; "2.000 Gb/s available PCIe bandwidth, limited by 2.5 GT/s PCIe x1 link at
  0000:53:00.0" (link came up Gen1 x1 at first: see step 4).
- 15:58-16:06 several replug cycles: amdgpu init every time (`SMU is initialized successfully`, `kfd kfd: amdgpu: added device 1002:744c`,
  MES rings up); one cycle hit `Fatal error during GPU init` (SMU 0xFFFFFFFF) and the next replug recovered. An abrupt disconnect
  later wedged MES teardown (pm_runtime_work hog): always stop the server before unplugging.
- 16:07:00 the dock re-enumerated as `3801:0001` = the handmade USB3 firmware it runs now (ed4e39b7). So the shipped USB4 firmware was
  on the dock until 16:07 yesterday; nothing else needs to be built.

## What the user has to do (flash + replug; ~10 minutes)
1. Stop everything on the dock: `sudo systemctl stop tinygrad-server-chestnut`; make sure no sweep holds it (`flock -n /tmp/chestnut-sweep.lock true`).
2. Flash the shipped USB4 firmware back (repo ~/z/asm2464pd-firmware; `fw_tinygrad.bin` = the 98016 B image the dock shipped with,
   commit ff507f2 "tinygrad firmware", contains the USB4 router DROM; this is what extra/usbgpu/patch.py produces from AS_USB4_240417):
       cd ~/z/asm2464pd-firmware && ./ftdi_debug.py -bn && ./flash.py fw_tinygrad.bin && ./ftdi_debug.py -rn
   (`-b` = reset to bootloader, `-n` = don't read debug output, `-r` = reset). Keep the handmade image to flash back:
   the handmade build is in the same repo (`handmade/`, branch fix-f0-f2-arm-race is the one with the C450+F0 fixes, not yet flashed).
3. Plug the dock into the laptop's USB4/TB port (not a USB3-only port). Check:
       boltctl list                      # "USB4 NVMe SSD Pro Enclosure" status: connected/authorized
       lspci -nn | grep -E "1002:744c|1b21|174c"
       journalctl -k -b | grep -E "kfd|amdgpu.*Initialized|57:00.0"
4. Link speed: `sudo lspci -vv -s 57:00.0 | grep LnkSta` and `cat /sys/class/drm/card*/device/pp_dpm_pcie`. The 15:40 log shows the
   upstream ASM switch link at 2.5 GT/s x1 at enumeration; a TB tunnel is fixed at ~2.5-3 GB/s regardless, but if amdgpu reports
   Gen1 in pp_dpm_pcie set `options amdgpu pcie_gen_cap=0x00070007` in /etc/modprobe.d/amdgpu.conf (currently 0) and reload.
5. Benchmark (same tree, same model, same flags; only DEV changes):
       cd /home/jacob/z/tinygrad && MTP_K=3 DEV=AMD:KFD LLM_CACHE=1 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 \
         .venv/bin/python3 -m tinygrad.llm.cli --model /home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf --mmproj none \
         --repeat-penalty 1.15 --max_context 8192 --host 127.0.0.1 --serve 8082
   then the same 8-prompt loop as `sweeps/chestnut-usb3-20260830/dflash-restore-fault-20260905/scripts/perf_sweep.sh` (copy it and
   change `DEV=USB+AMD:LLVM` to `DEV=AMD:KFD` on the env line; the script is in use by the sweep chain, do not edit it in place).
   Baseline to beat: mtp-k3 74.9 tok/s mean / 82 first request (USB3, 09-06 00:xx).
   Also time a 1 GB copyin (`Tensor.empty(1<<30, dtype=uint8).contiguous().realize()` from a numpy source) for the load path.
6. Fallback: flash the handmade image back the same way (`./flash.py <handmade .bin>`); the USB3 serving path is unchanged.

## Caveats
- amdgpu + KFD own the device: the AM driver path (`DEV=AMD:PCI`/`USB`) is not used; IOMMU stays on (the device is "untrusted"
  in bolt; DMA is remapped — fine for KFD, blocks the physical-address AM PCIIface).
- No suspend/resume with the tunnel up; stop the server before unplugging (MES teardown wedged once).
- The `USB_COPYIN_GUARD`/F2 corruption fixes are USB-only code; nothing to port.
- Production unit change if it wins: `DEV=AMD:KFD` in tinygrad-server-chestnut.service (frozen venv already has the KFD runtime).

## 2026-09-06 09:17 first attempt: the TUNNEL is the problem, not amdgpu
Flashed fw_tinygrad.bin (dock in ROM bootloader 174c:2463 after `-b`; flash.py must be rerun once it re-enumerates), plugged into the
USB4 port: thunderbolt 0-3 found the Gopod router at 09:17:28, PCIe switch + Navi31 enumerated at 57:00.0, amdgpu started (VRAM
24560M) — and at 09:17:31 the TB device disconnected (config-space read timeouts, WARNING ctl.c:1113 during tb_scan_port); amdgpu's
teardown then hit "MES failed to respond to REMOVE_QUEUE"; the dock re-enumerated 20 s later as USB3 (add1:0001) on the same port.
Correction to the research note ("worked on this host"): the journal since 08-30 shows every tunnel session was short:
09-05 15:40-15:42, 15:43-15:45, 15:49-15:58 (9 min: amdgpu + KFD up in 2 s, two runtime-PM "SMU is resuming" cycles, then
"0:3: failed to reach state TB_PORT_UP ... lost during suspend, disconnecting"), 15:58-15:59, 15:59-16:00, 16:06 (1 s, 9 s); the
handmade USB3 firmware was flashed at 16:07 right after. So: the link drops on runtime suspend/resume and sometimes at enumeration.
Host side: TB host 00:0d.2 and root ports 00:07.0/1 are `auto` + suspended, amdgpu runpm=-1 (auto), no pcie_port_pm/aspm params.
Next test: `sudo bash tb_hold.sh` (pins the TB host, root ports, TB domain and the GPU to power/control=on) BEFORE plugging in;
watch whether the session survives past 2 min; if it does, benchmark. If it still drops at enumeration: other port / other cable /
`thunderbolt.dyndbg` for the link-training error; kernel params `pcie_port_pm=off pcie_aspm=off amdgpu.runpm=0` as the next step.

## 09:30-09:37 SECOND ATTEMPT (after reboot with runpm=0 + udev pins): tunnel stable, KFD works, **92 tok/s**
Reboot at 09:30 with the dock in the USB4 port: tunnel up at 09:30:59, KFD topology back to one node (the five dead nodes from
hot-unplugs were what made `/dev/kfd` open fail with EINVAL before), `/dev/kfd` opens, GPU pinned active. The production unit
(DEV=USB) crash-loops in this mode (no USB device) -> stop it. `DEV=AMD:KFD` is the wrong syntax in this tree (renderer 'KFD'):
use **`DEV=KFD+AMD:LLVM`**. Weight load: 16.34 GB in 6.0 s (3 GB/s; USB3: ~50 s). Server up in 59 s (kernel cache warm; the LLM
cache key includes DEV so a fresh entry is built, but the compiled kernels are shared with the USB tree).
| prompt (merge sort, 500 tok, greedy, MTP K=3) | USB3 (09-06 00:xx) | KFD (09:36) |
|---|---|---|
| gen tok/s | 82 | **92** (+12%) x3 identical |
| tok/step | 3.08 | 3.20 |
| ms/step | 37.6 | 34.8 |
So the USB3 round trips cost only ~3 ms of the 37 ms step, not the 15-25 ms the code-derived model predicted: the ~540 transfers per
step are pipelined and the step is dominated by GPU kernel time + host graph-launch gaps. The remaining budget (35 ms vs 17 ms of pure
weight streaming) is now the target: per-step attribution (item 12) before any more transport work. Tunnel: 6+ min without a drop
(previous record 9 min); soak continues during the sweeps below. Log: logs/*-kfd-first-bench.log.

## 09:41 per-step time budget on KFD (PROFILE=1, MTP K=3, 300-token benchmark; profile/step_budget.py on profile/*-kfd-mtpk3-bench300.pkl)
- A step = 5 HCQ graphs (32 + 64 + 128 + 256 + 231 = **711 kernels**). **Device busy 35.0 ms = the whole step** (server-measured 34.8):
  no host gaps left to remove on this transport; USB3 was adding ~3 ms of launch latency, nothing more.
- By family (ms/step): gemv_multi 15.4 + gemv 13.9 = **29.3 (84%)**, attention 1.9, GDN 1.4, rmsnorm_quant 1.25 (144 calls of ~9 us:
  launch-bound), reductions/elementwise/silu ~1.2.
- **Weight bytes per step: 20.65 GB** (16 GB model + the 1.02 GB q6k lm_head read 3x for the K=3 sequential MTP drafts at T=1
  + once for the verify) = 705 GB/s over gemv time, 590 GB/s over the step; peak 960. The lm_head draft passes are the single biggest
  item: 3.56 ms/step at 878 GB/s (bandwidth-perfect, just too many bytes).
- Achieved GB/s per gemv variant: the big ffn/attn gemvs 640-790 GB/s (67-82% of peak); the q5k 5120x6144 out-proj at T=7 runs at
  **267 GB/s** (the register-spilling kernel; 12 calls/step, 1.0 ms) and 587 at T=4: the gemv-spillfree fix is worth ~0.7 ms/step here.
- Levers, in order: (1) restricted MTP draft vocab (draft the 3 passes over the first-N token ids only: a prefix slice of the head's raw
  bytes, no remap; verify stays full-vocab, so still exact): ~2.5 ms/step (-7%); (2) merge gemv-spillfree: ~0.7 ms; (3) fuse the ~300 tiny
  kernels/step (rmsnorm_quant, silu_mul, reductions) into their neighbours: ~2 ms; (4) gemv variants below 700 GB/s: ~1.5 ms.
  Together ~7 ms of 35 -> ~115 tok/s at the current 3.2 tok/step, before any acceptance work.

### Achieved bandwidth per gemv variant (profile/gemv_bandwidth.txt) and the small kernels
- gemv total 29.28 ms/step for 20.65 GB = 705 GB/s. lm_head q6k 865 GB/s (16.5% of gemv time); ffn gate/up multis 700-790; ffn down
  q5k 700, iq4xs 628 (LUT decode is ALU-heavier, 583 at T=7); GDN in-proj multis 665-690.
- Laggards: the 5120x6144 out-proj class — q5k **423 GB/s average** (267 at T=7 = the spilling kernel, 533-563 at T=5/6 from VGPR-limited
  occupancy), q6k 604. Small N (5120 rows) + T>=5 register pressure. GEMV_TG (gemv-spillfree) targets exactly this; ~0.7 ms/step.
- Small kernels: 322 launches/step = 2.93 ms: rmsnorm_quant 144 x 8.7 us = 1.25 ms (one workgroup per row, latency-bound; ~4 us is
  reachable), the vocab argmax for sampling `r_2_32_4_970` 6 x 58 us = 0.35 ms (a 1 MB reduction that should take ~8 us: custom kernel),
  attn_prep/merge 0.46, silu_mul_quant 0.45.
- Wider verify is ALU-bound on these gemvs (dot work scales with T while bytes do not): the iq4xs/q5k variants drop from ~740 to
  ~600 GB/s between T=4 and T=7. That is the structural reason K=5 and DFlash block 8 do not pay on RDNA3.
Realistic path at K=3: draft vocab (-3 GB) + TG (+eff on the out-proj) -> gemv ~24.5 ms -> ~30 ms/step -> ~107 tok/s; then rmsnorm/argmax/
attn_prep fusion (-1.5 ms) -> ~28.5 ms -> ~112; the rest is bytes (quant) or acceptance (selector, drafter).

## 09:41-09:59 8-prompt sweep on KFD (perf_sweep_kfd.sh, restored instances, greedy, logs/20260906-094144-perf-summary.txt)
| config | KFD mean tok/s | min-max | tok/step | req1 | USB3 mean (09-06) | gain |
|---|---|---|---|---|---|---|
| mtp-k3 | **82.2** | 73-92 | 2.82 | 92 | 74.9 | +10% |
| mtp-k4 | 79.6 | 71-88 | 3.13 | 88 | 73.2 | +9% |
| mtp-k5 | 72.6 | 63-81 | 3.21 | 81 | 67.2 | +8% |
| dflash-x0 (block 6, argmax) | 68.5 | 64-79 | 2.46 | 79 | 62.8 | +9% |
| dflash-x16 | 66.5 | 61-81 | 2.92 | 81 | 61.8 | +8% |
Uniform +8-10% across configs (the removed USB launch latency); the ranking is unchanged: K=3 stays best, the wider verifies remain
ALU-bound. Restores 73-84 s (USB3: 165-200 s).

## Production recommendation (11:15, pending the user's deploy)
Measured on KFD, restored instances, 8 long prompts x 500 tok greedy: MTP K=3 82.2-82.8 tok/s; with `MTP_DRAFT_VOCAB=65536`
(branch gemv-spillfree) **89.6**; USB3 baseline 74.9. Plus `--repeat-penalty 1.0` instead of 1.15 (+4.5% measured on USB3 at temp
0.6). Unit changes: `Environment=DEV=KFD+AMD:LLVM`, `Environment=MTP_DRAFT_VOCAB=65536`, penalty flag; frozen venv reinstalled from
the serving branch after merging gemv-spillfree (the GEMV_TG default, fused selector, draft vocab, FAST_ARGMAX are all env-gated or
measured neutral). Expected production: ~90 tok/s greedy-equivalent vs 75 today (+20%), restarts ~70 s instead of ~200 s.
Keep: udev rules + amdgpu runpm=0 (installed 09:30), the dock in the USB4 port, stop the server before unplugging.

## 11:17-11:35 confirmation from the MERGED serving tree (dfe59dd70) on KFD
- `ONLY=mtp-k3 MTP_DRAFT_VOCAB=65536 perf_sweep_kfd.sh` (8 prompts x 500 tok greedy, restored): **90.1 tok/s** (84-96, 2.81 tok/step,
  req1 96, restore 69 s) — logs/20260906-111708-perf-summary.txt. USB3 today: 74.9.
- Production config check: `--max_context 114688` (the unit's 112K) + `MTP_DRAFT_VOCAB=65536` + `--repeat-penalty 1.0` on KFD: server up
  in 71 s (fresh cache entry), merge-sort prompt **102 tok/s** at 3.22 tok/step, twice (logs/*-kfd-ctx112k.log). No OOM at 112K.
Deploy (the user's explicit act, see memory chestnut-serve-deploy-workflow): reinstall the frozen venv from dfe59dd70, verify the import from
a neutral cwd, install etc/tinygrad-server-chestnut.service.d/kfd.conf plus `Environment=MTP_DRAFT_VOCAB=65536` and change
`--repeat-penalty 1.15` to `1.0` in the unit, `systemctl daemon-reload && systemctl restart tinygrad-server-chestnut`.

## 11:23-11:32 long-context decode flatness (longctx/longctx_sweep.sh: production candidate config, 112K ctx, KFD; logs/*-longctx-summary.txt)
| prompt tokens | prefill tok/s | gen tok/s | tok/step | ms/step |
|---|---|---|---|---|
| 74 | 142 | 86 | 2.75 | 32 |
| 1.8K | 858 | 82 | 2.62 | 32 |
| 6.9K | 816 | 76 | 2.61 | 34 |
| 27.6K | 555 | 57 | 2.35 | 41 |
| 55K | 371 | 46 | 2.44 | 53 |
| 103K | 257 | 39 | 2.77 | 71 |
(lighthouse paragraph repeated; its acceptance is lower than the code prompts'.) Decode is NOT flat: +39 ms/step at 103K = the
attention decode over the quantized KV, which is ~1.8 GB per step (16 attention layers x 103K x ~1.1 KB) = 1.9 ms at 960 GB/s, so
the kernel runs at ~5% of bandwidth at long context: latency/occupancy-bound (attn_pfd chunks of 256 positions -> ~400 chunks x 4 KV
heads per layer, then a 400-way merge per row). Prefill falls from 858 to 257 tok/s at 100K (quadratic attention). For Hermes-style
50-100K contexts this is the production-relevant lever now: 46-39 tok/s instead of 90. Next: profile a 55K-token decode
(PROFILE=1 benchmark with BENCH_PROMPT_FILE) to attribute the 39 ms between attn_pfd and attn_merge_mq.
Why the attention decode is slow at long context (amd_prefill._attn_pf_src): one workgroup per (KV head x 256-position chunk x query
block); LDS per workgroup at QT=8 (48 query rows with the qjl copy): qbuf 2x48x256 = 24.5 KB + Ks/KJs 8 KB + Vt 8 KB + Ps 3 KB ~ 44 KB
-> one workgroup of NWAVE=6 waves per CU (64 KB LDS), so every 16-position tile's KV load -> dequant -> WMMA chain is exposed
latency with ~6 waves to hide it. At 103K that is ~400 chunks x 4 heads = 1600 workgroups per layer at ~73 us each. Levers, cheapest
first: ATTN_QT=4 (LDS ~30 KB -> 2 workgroups/CU, 2 query blocks so 2x KV reads but still ~10% of bandwidth), AMD_ATTN_MQ_CH (chunk
size: fewer, longer chunks = fewer merges), then in-kernel double-buffering of the next tile's K/V loads and more waves per workgroup.

### 11:35 decode-only budget at 55K context (profile/*ctx55k*.pkl, PROFILE=1 benchmark, dv64k; prefill graphs filtered out)
device busy **53.3 ms/step**: gemv 26.3 (the lm_head draft passes are now 0.95 ms x3 with MTP_DRAFT_VOCAB=65536, was 3.56), **attention
23.3** (attn_pfd 21.7 ms over 19 calls = 1.14 ms per layer for 55K positions = 60 MB of quantized KV per layer -> **53 GB/s, 5.5% of
peak**; attn_merge_mq 1.26), gdn 1.4, rmsnorm 1.2, small 1.2. So at 55K the attention decode costs as much as the whole 16 GB of
weights. Fix target: attn_pfd's per-tile latency chain at 1 workgroup / 6 waves per CU.
Kernel change under test (worktree gemv-spillfree 36569af86, `ATTN_LW`, default 16): attn_pfd's workgroup grows from the 6 compute
waves (192 threads) to 16 waves (512) — the extra waves only fetch+dequantize the 16-position tile (one round instead of three) and
skip the compute phase and epilogue. Same LDS (46720 B), VGPRs 228 -> 196, the prefill kernel attn_pf is untouched. The math and
reduction order are identical, so the chunk-8 numerics rows must be bitwise equal to the serving tree's (chainL checks that before
timing). Queued after the QT=4 / CH=128/512 variants sweep.

### 11:40-12:47 attention variants at long context (longctx/longctx_variants.sh; logs/*-longctx-variants.out)
| prompt tokens | CH=256 (baseline) | CH=512 | CH=128 |
|---|---|---|---|
| 74 | 86 | 81 | 79 |
| 1.8K | 82 | 81 | 84 |
| 6.9K | 76 | 76 | 82 |
| 27.6K | 57 | 61 | 54 |
| 55K | 46 | 53 | 51 |
| 103K | 39 | 39 | 37 |
Chunk size is not the lever (differences are within acceptance noise, 2.3-2.8 tok/step). ATTN_QT=4 did not start (see below): the
per-tile latency inside attn_pfd is what remains -> ATTN_LW (chainL).
ATTN_QT=4 aborts at kernel build: `assert D == 256 and NR % 16 == 0` — NR = QT x G = 4 x 6 = 24 query rows is not a whole WMMA row
tile (16); only QT=8 (48 rows) or QT=16 (96, LDS overflow) fit this head ratio. Halving LDS would need padding rows, not just QT.
Result (chainL, 12:47-12:58): ATTN_LW=16 is bitwise identical (0/64 blocks differ) but SLOWER at long context: 52 / 41 / 34 tok/s
at 28K / 55K / 103K vs 57 / 46 / 39 (same acceptance per row). More waves per workgroup cost more than the one-round fetch gains
(two barriers per tile across 16 waves; the compute waves still wait for the slowest load). Default reverted to off (knob kept).
Per-tile arithmetic at 55K: 860 workgroups/layer over 48 CUs at 1 WG/CU = 18 sequential WGs x 16 tiles -> 3.9 us per 16-position
tile = about two dependent global-memory latencies. The fix has to overlap tile t+1's fetch with tile t's WMMA/softmax
(register double-buffering inside the compute waves), or halve LDS to fit 2 workgroups per CU (Q rows out of LDS: 128 VGPRs, too many).
Result (13:00-13:12, worktree 8c6c34659): ATTN_PF=1 (register double-buffered tile fetch, 256 VGPRs, 0 spills) is bitwise identical
and exactly as fast as before: 57 / 46 / 38 tok/s at 28K / 55K / 103K. So the per-tile cost is NOT global-load latency: with one
6-wave workgroup per CU (1.5 waves per SIMD) the dependent chains of the compute itself (16 chained WMMAs for the scores, the
per-row softmax with DPP reductions/read_lane/expf, 8 chained PV WMMAs) run with no other wave to fill the pipeline. The lever is
occupancy: fit 2 workgroups per CU by taking the Q rows (qbuf, 24.5 KB of the 46.7 KB LDS) out of LDS — for the chunked kernel the
A operands can come straight from the (L1/L2-resident, 12 KB) global qq/sqq rows (`ATTN_QG`, next).
Result (13:15-13:25, worktree bffdc38a8, `ATTN_QG=1`): bitwise identical (0/64 blocks), LDS 46720 -> 20864 B, and at long context
**58 / 49 / 42 tok/s at 28K / 55K / 103K** vs 57 / 46 / 39 (+2 / +7 / +8%); short context unchanged (88 / 82 / 79). Less than the
occupancy arithmetic promised (3 workgroups per CU by LDS), so something else still serializes: candidates are the partial-output
traffic (48 KB of scattered f32 stores per workgroup = ~41 MB per layer at 55K, 70% of the KV bytes) and the barrier cadence per tile.
Next: profile at 55K with QG=1 to split attn_pfd vs merge, then cut the partials (online-softmax over several chunks per workgroup).
Profile at 55K with QG=1 (13:26): device busy 50.9 ms/step (was 53.3); attn_pfd 19.2 ms (was 21.7) = 1.01 ms per layer for 60 MB
= 59 GB/s; merge 1.25. Arithmetic: WMMA work ~0.22 ms/layer, LDS traffic ~0.09 ms, per-wave dependent-chain latency ~0.1 ms even at
1 workgroup/CU — none of these reach 1 ms; the 3 rounds of global loads per tile (~2 us each) do (~0.6 ms/layer). So the loads ARE
the cost and the ATTN_PF prefetch did not overlap them — suspect the compiler placed s_waitcnt right after the loads (register
pressure at 256 VGPRs). Checking the ISA, and testing PF+QG together (QG freed VGPRs).
ISA findings on the prefetch (profile/attn_pfd_pf1_qg1*.s): (1) the release fence in BAR() makes LLVM emit `s_waitcnt vmcnt(0)
lgkmcnt(0)` before every s_barrier, so a prefetch issued before the barrier is drained on the spot (why ATTN_PF v1 was neutral);
(2) predicated loads (`if (pos < pend)`) are waited at their merge; (3) Q rows read from global (ATTN_QG) force vmcnt(0) drains
inside the score loop (vmcnt is in-order). Prefetch v2 (worktree 8ad5…): issued after the barrier, unconditional clamped loads:
with QG=0 the 12 loads of tile t+1 stay in flight across the whole compute phase. On-device test queued (PF=1 with QG=0 and QG=1).
Chunk size with QG=1 (13:26-13:49): CH=512 -> 63 / 54 / 41 tok/s at 28K / 55K / 103K, CH=1024 -> 58 / 53 / 41 (QG CH=256: 58 / 49 /
42). Within acceptance noise again; chunk size stays 256.
Result (14:14-14:36, prefetch v2 = worktree a88a6c7b4): bitwise identical, and STILL no gain: PF+QG0 57 / 47 / 39, PF+QG1 58 / 48 / 40
at 28K / 55K / 103K (QG alone 58 / 49 / 42). With the loads verifiably in flight across the compute, the per-tile cost is not global
latency either. Remaining suspect: LDS bank conflicts — the K/KJ tile rows have a 256 B stride (LQ = D), so the 16 lanes of a WMMA
B-operand fetch (ds_read_b128 at l16*256 + ks*16) all hit the same 4 banks: 16-way conflicts on every one of the 32 B-fetches per tile
per wave; the transposed V stores are 4-way. Fix: pad the row stride to 272 B (`ATTN_LQPAD`).
LQ was already D+16 = 272 B (rows padded), so the B-operand bank-conflict theory is out too. Rather than guess further: timing
ablations of attn_pfd (worktree 4eeae6dbb, `ATTN_ABL`, wrong results by design): 1 = no score WMMAs, 2 = no softmax, 3 = no PV
WMMAs, 4 = no dequant/LDS stores (loads kept alive), 5 = no global loads (constants). Running each at the 55K prompt with a fresh
compile (LLM_CACHE=0: the pickled graphs would otherwise replay the old binary; ATTN_ABL is deliberately not in the cache key).
### 14:39-15:00 attention ablations at 55K (worktree 4eeae6dbb, QG=1, PF=0; logs/*-attn-ablations-55k.out; ms/step = tok/step / tok/s)
| ablation | gen tok/s | tok/step | ms/step | saved |
|---|---|---|---|---|
| 0 baseline | 49 | 2.44 | 49.8 | - |
| 1 no score WMMAs | 44 | 1.76 | 40.0 | 9.8 |
| 2 no softmax | 43 | 1.78 | 41.4 | 8.4 |
| 3 no PV WMMAs | 45 | 1.78 | 39.6 | 10.2 |
| 4 no dequant / LDS stores (loads kept) | 26 | 1.00 | 38.5 | **11.3** |
| 5 no global loads (constants) | 41 | 1.92 | 46.8 | 3.0 |
(the ablated kernels produce garbage, hence the acceptance changes; ms/step is the comparable number.) The attention is ~20 ms of
the 50 ms step here. The global loads cost only 3 ms — consistent with the neutral prefetch. The dequant/LDS-store phase is the
largest single item (11 ms): per lane per position it does 16 data-dependent LDS codebook lookups (cbk8_s/cbv_s) plus 8 scattered
f16 V stores and 2 K stores, three positions per wave per tile. Each compute phase is ~9-10 ms and they overlap with each other
only partially (3 workgroups per CU, LDS-bound). Next split: ABL=6 keeps the stores but replaces the codebook lookups with arithmetic.
| 6 codebook lookups -> arithmetic (stores kept) | 42 | 2.00 | 47.6 | 2.2 |
So the LDS stores are ~9 of the 11 ms. Cause found in the address pattern: the transposed V tile store `Vt[(lane*8+i)*16 + pp]` has a
lane stride of 8 rows x 32 B = 256 B, so all 32 lanes of a wave write the same LDS bank: 32-way conflicts on each of the 8 ds_write_b16
per position, 3 positions per wave per tile, 6 waves sharing the LDS -> ~1.8 us of serialized LDS cycles per tile, i.e. the whole
mystery. Fix (worktree, `VT(r)` row offset = r*32 B + 16 B per 8 rows): stores spread over 8 bank groups (4-way), PV fragment reads
stay 16 B-aligned. Bitwise check + full long-context sweep running.

## 15:30-15:42 RESULT: transposed-V LDS padding (worktree 01e206981) — bitwise identical, **63 / 55 / 49 tok/s at 28K / 55K / 103K**
vs 57 / 46 / 39 at the start of the day (+11 / +20 / +26%); short context unchanged (89). The prefill attention kernel shares the
layout and got faster too: the 103K-token request's wall time fell from 362 s to 292 s. LDS 21376 B (QG on). Sequence that got here:
occupancy (QG, +8%), load prefetch (verified in the ISA, neutral), ablations (loads 3 ms, LDS phase 11 ms), codebook-lookup ablation
(2 ms), then the address math: 8 f16 stores per lane per position with a 256 B lane stride = one bank for the whole wave.
Merged into the serving branch (attention: QG default on, Vt pad always, PF/LW/ABL default off).

## 15:42-15:54 merged serving tree 701360b93 confirmed on KFD
8-prompt short-context sweep (K=3, dv64k, restored): **91.1 tok/s** mean (85-97, req1 97). Production 112K config: 89 tok/s on the
74-token prompt, **49 tok/s at 103K** (was 39). Production recommendation updated: deploy from 701360b93 with the KFD drop-in
(DEV=KFD+AMD:LLVM, MTP_DRAFT_VOCAB=65536) and --repeat-penalty 1.0; expected ~91 short / ~55 at 55K / ~49 at 103K vs 75 / 46 / 39 today.

### 15:54-16:10 ablation round 2 on the fixed kernel (Vt pad + QG), 55K (logs/*-attn-ablations2-55k.out)
| ablation | tok/s | tok/step | ms/step | saved |
|---|---|---|---|---|
| 0 baseline | 55 | 2.44 | 44.4 | - |
| 1 no score WMMAs | 49 | 1.76 | 35.9 | 8.5 |
| 3 no PV WMMAs | 45 | 1.78 | 39.6 | 4.8 |
| 4 no dequant / LDS stores | 25 | 1.00 | 40.0 | 4.4 |
| 5 no global loads | 47 | 1.92 | 40.9 | 3.5 |
The LDS-store phase went from 11.3 to 4.4 ms. Attention is now ~15 of the 44 ms step at 55K; the score phase (8.5 ms: 32 WMMAs
per wave per tile + the B-operand LDS reads + the Q rows fetched from global each k-step under QG) is the largest remaining piece.
Next test: QG=0 (Q rows in LDS again) on the fixed kernel, since the V fix changed what the occupancy trade buys.
