# Needed from upstream tinygrad: L2-acquire on cross-queue copy→compute edges over USB

**Status:** root-caused with hardware evidence; deferred to upstream (or a later dedicated change). The LLM-layer
mitigation (build `sp_t` on the compute queue) is *not* sufficient — the race persists intermittently, confirming it
is a general HCQ coherence gap, not a single-buffer bug.

## Symptom
Intermittent `GCVM_L2_PROTECTION_FAULT` (rw=1 write, **cid=8 = TCP**) → CP hang, during LLM decode on the AMD RX 7900
XTX (gfx1100) driven over USB (`DEV=USB+AMD`, tinygrad's own AM driver). Fires readily under DFlash spec-decode (denser
graph); MTP mostly avoids it by timing. `hang report`: "signal is not set to N, but N-4". The wild store lands ~100-170MB
past a KV-cache block (a garbage position index).

## Root cause (proven via a post-hang debug-port wave dump)
Added `WAVEDUMP` (post-hang `SQ_IND_INDEX`/`SQ_IND_DATA` wave scan over the FTDI/MMIO path, zero perturbation — see
`tinygrad/runtime/support/am/ip.py:_dump_hung_waves`): the resident faulting waves cluster at one kernel PC = the
attention KV-writer. It reads `start_pos` from a small buffer (`sp_t`) that is **assembled by an SDMA copy on the copy
queue** (`cat`+`contiguous`). The HCQ graph makes the consuming **compute** kernel *wait* on the copy queue's completion
signal (`runtime/graph/hcq.py` ~line 173: `for sig,val in sync_signals+deps: enqueue_queue.wait(sig,val)` then
`exec`), but issues **no cache-acquire / L2-invalidate between the wait and the exec**. The only `memory_barrier()`
(HDP flush + `acquire_mem`) is at graph **kickoff** (hcq.py ~164), not per cross-queue edge.

Over the **non-coherent USB link**, an SDMA write can land in VRAM/MC while the compute unit still holds a stale L2
line, so waiting for "copy done" is insufficient — the compute kernel reads the stale value → garbage `start_pos` →
wild KV store. This is the same *class* as the recently-fixed copyin stale-sentinel/tearing bugs (#17969/#17972), one
layer up: intra-graph cross-queue visibility rather than the host→VRAM copyin path.

Any SDMA-produced buffer read by a compute kernel is latently exposed; `sp_t` is just the one DFlash hits first.

## Proposed fix (upstreamable, minimal, measured)
After a compute queue `wait`s on a **cross-queue copy** signal, emit an `acquire_mem` (GL2+GL1 invalidate) before the
dependent kernel's `exec`. Gate on `dev.is_usb()` (or the non-coherent-interconnect case) so coherent PCIe pays no cost.
Location: the enqueue loop in `HCQGraph.__init__`/`_enqueue` around hcq.py:173, when `sync_signals`/`opt_deps` include a
copy-queue signal. `AMDComputeQueue.acquire_mem(gl2=1, gl1=1, ...)` already exists (`ops_amd.py:104`).

Validate with the DFlash decode fault-hunt (`AMD_USB_SPIN_MS=0`, many fresh requests) — currently faults on ~request 1
on a fresh server; the fix should survive an extended soak with 0 faults. Keep the diff minimal + hardware-evidenced
(fits tiny corp's PR bar).

## Artifacts in-tree (this fork)
- `tinygrad/runtime/support/am/ip.py`: `_dump_hung_waves` (WAVEDUMP=1) + `FAULTMAP` fault-region dump — keep as tools.
- `tinygrad/llm/amd_gemv.py:start_pos_tensor`: builds `sp_t` as one compute-queue elementwise kernel (partial
  mitigation; leave or revert — it does not fully fix the race).
