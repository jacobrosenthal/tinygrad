# Plan: MTP speculative decoding for Qwen3.8-27B (tinygrad, AMD gfx1100 custom kernels)

Baseline: branch `amd-gemv-qwen38`, commit `c21c5dd`. Decode 53.5 tok/s (18.7 ms/token), chunked T<=8 prefill ~250 tok/s.
Memory/notes: `~/.claude/projects/-home-quentin-tinygrad/memory/qwen38-decode-optimization.md`.

## Decision: use the GGUF's nextn (MTP) layer, not the DFlash2 draft model

- `blk.64.*` in every Qwen3.8-27B GGUF is a full-attention + FFN layer (`qwen35.nextn_predict_layers = 1`), plus
  `blk.64.nextn.eh_proj.weight` (K=10240 -> N=5120), `nextn.enorm`, `nextn.hnorm`, `nextn.shared_head_norm` (all RMSNorm(5120)).
  Its `attn_q` is [5120 -> 12288] = per-head interleaved (q | gate), exactly like the main attention layers (e.g. `blk.3`), so the
  existing `TransformerBlock` class and the fused `attn_decode` kernel work unchanged.
- `dflash2-incoai-Q4_K_M.gguf` is a DFlash2 block-diffusion draft (non-causal attention over target hidden states of 5 layers,
  selectors, conv projections) — far more work to reverse-engineer. Skip.
- MTP math (vLLM `qwen3_next_mtp.py`): for main-model hidden h_i (output of the last main layer, BEFORE output_norm) at position i and the
  token t_{i+1} that follows it:
  `x = eh_proj(cat([enorm(embed(t_{i+1})), hnorm(h_i)]))` (embeds first, hidden second) -> `x = layer(x, pos=i)` (own KV cache)
  -> `logits = output(shared_head_norm(x))` (shared lm_head). argmax = draft for position i+2.
- Weight sizes (UD-Q3_K_XL): ~350 MB for blk.64 + 875 MB output head -> ~1.5 ms per draft at bandwidth.

## Algorithm (K=1 draft, lossless "sample-then-compare", works with temperature > 0)

State: committed position p (caches/states hold tokens < p). Uncommitted accepted tokens U (1 or 2 tokens). Draft d.
Each step:
1. Main forward on chunk = U + [d], T = len(U)+1 (so T in {2,3}), `n_tok = T`, `n_keep = len(U)` (only U is committed to
   GDN/conv state; attention KV for the extra row is written but harmlessly overwritten next step since start_pos only advances n_keep).
   Sample tokens for ALL T rows (Gumbel argmax per row, as in `forward`): `out[T]`. Keep the last-layer hidden `x[1,T,D]`.
2. `accept = out[n_keep-1] == chunk[n_keep]` (i.e. == d).
3. MTP forward over the same T rows: hidden rows = x, next tokens
   `next[j] = chunk[j+1] if j < n_keep-1 else out[j]`, start_pos = p, `n_tok = T`, `n_keep_mtp = n_keep + accept` (GPU scalar),
   draft = `mtp_out[n_keep_mtp - 1]`. Everything (accept, n_keep_mtp, draft select) is computed on GPU inside one JIT; the
   kernels read n_keep from the sp tensor so no Python branch is needed inside the JIT.
4. Python syncs once: reads `out` (T ints) + `draft`. If accepted: emit d and out[T-1]; U = [d, out[T-1]]; else emit out[n_keep-1];
   U = [out[n_keep-1]]. p += len(U_old). Next chunk = U + [draft].
Prefill: same `forward_spec` with T=8 padded chunks, `n_keep = n_tok` (everything commits), next tokens = chunk[1..] + [out[n_tok-1]];
the MTP KV cache must be filled during prefill too. Draft from the last prefill chunk is the first decode draft.
JIT captures: T=8 (prefill), T=2, T=3 (decode) -> three TinyJit instances keyed on T.

Expected: ~20.5-22 ms main (T=2/3) + ~2.5 ms MTP per step; acceptance ~0.7 -> ~1.7 tokens per ~24 ms -> ~70-75 tok/s.
Later: chain MTP recursively for K=2 (T up to 4), in-kernel state snapshot to avoid the T=3 re-process.

## Code changes

### `tinygrad/llm/amd_gemv.py`
1. `start_pos_tensor(start_pos, device, n_tok=1, n_keep=None)` -> 3-element int32 tensor `[start_pos, n_tok, n_keep]`
   (n_keep default = n_tok). n_keep may be an int, a UOp variable, or a GPU int32 Tensor (for the MTP pass: `n_keep + accept`);
   cache key must include `id()` of a Tensor. Simplest plumbing: `new_forward(n_keep=None)` stores a module-global that
   `start_pos_tensor` uses (called at the start of the main pass and again before the MTP pass).
2. `_gdn_conv_src`: new conv state uses `nk = sp_p[2]` instead of `n` (`win[nk + i]`); conv_out still over all T.
3. `_gdn_step_src`: `nk = readfirstlane(sp_p[2])`; recurrence loop `tt < n` unchanged, but write `srow[i] = s[i]` inside the loop
   when `tt + 1 == nk` (uniform branch) and delete the post-loop store. nk == 0 -> state untouched.
4. `_attn_src`: no change (KV rows for rejected tokens are overwritten by the next step).
5. `linear_decode` / rmsnorm kernels already take T rows; `eh_proj` has K=10240 (%1024 == 0) so it goes through the gemv path.

### `tinygrad/llm/model.py`
1. `from_gguf`: `num_blocks = block_count - nextn_predict_layers` (already). Rename keys `blk.{num_blocks}.X` ->
   `mtp.X` with `nextn.` stripped (`mtp.eh_proj.weight`, `mtp.enorm.weight`, `mtp.hnorm.weight`, `mtp.shared_head_norm.weight`,
   `mtp.attn_q...`, `mtp.ffn_norm` from post_attention_norm) in BOTH `state_dict` and `raw` (so `amd_gemv.attach` finds them under the
   attribute path `mtp.*`). Create `model.mtp = MTPModule(config)` holding `blk = TransformerBlock(config)`, `eh_proj = Linear(2*dim, dim)`,
   `enorm/hnorm/shared_head_norm = nn.RMSNorm(dim)`. Realize its raw weights like the others. Gate with `getenv("MTP", 1)` and the
   presence of the keys. Call `model.mtp.blk._init_state(probe)` with the rest.
2. `Transformer.forward_spec(chunk[1,T] int32, start_pos, temperature, n_tok, n_keep) -> (out[T] int32, draft[1] int32)`:
   `amd_gemv.new_forward(n_keep)`; embed; all blocks with n_tok; `logits = output(output_norm(x))` over all T rows
   (`_tokens` routes T rows to the gemv); per-row Gumbel argmax -> `out`. Then accept/next-token tensors with symbolic ops
   (`Tensor.arange(T) < n_keep-1` -> where(chunk shifted, out); `accept = (n_keep < n_tok) & (out[n_keep-1:n_keep] == chunk[0, n_keep:n_keep+1])`);
   `amd_gemv.new_forward(n_keep + accept.int())`; MTP forward; `draft = mtp_out[n_keep_mtp-1]`. Return both.
   Keep the existing `forward`/`generate` path untouched (AMD_CHUNK etc.) for MTP=0.
3. `generate()` spec branch when `hasattr(self, "mtp")`: build each chunk as `Tensor([[...]], dtype=int32)` (pad to 8 for prefill);
   `_cached_tokens = tokens[:p]` (p = committed position, NOT len-1); keep a per-T dict of TinyJit(forward_spec);
   `get_start_pos` unchanged (uses len(_cached_tokens)).
4. `warmup()` must also go through the spec path so all three JITs get captured (2 calls each).

### Verification
- Greedy (temperature 0) output with MTP=1 must equal MTP=0 output token-for-token for a ~200 token generation
  (scratchpad `chunk_check2.py` style, compare lists). If it differs: check `n_keep` commit logic (GDN state), then `eh_proj` cat order.
- Print acceptance rate; expect 0.6-0.85 on prose/code. ~0 means wrong q|gate layout, wrong hidden (must be pre-output_norm), or
  wrong position/KV for the MTP layer.
- `python -m tinygrad.llm --model qwen3.8:27b --benchmark` for tok/s; `PROFILE=1` to confirm MTP adds ~2-3 ms.
- Test ONLY through the full model (calling a block in isolation with start_pos>0 on an empty cache crashed the GPU before).

### Gotchas (from previous sessions)
- Tensors cached across forwards get JIT-captured as constants -> `new_forward()` per pass (the sp tensor cache is keyed on `_fwd_id`).
- `custom_kernel` realizes its inputs immediately; chain buffers through its returned tensors for ordering.
- Sub-dword loads must go through `ld_u8/ld_u16`; float arrays addressed with byte offsets from a uniform base.
- Scripts need `PYTHONPATH=/home/quentin/tinygrad` and gguf-py from the scratchpad `pydeps`.
