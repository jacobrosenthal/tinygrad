"""DFlash2 candidate selector as two fixed-shape custom kernels, so it can live INSIDE the spec graph (JIT-stable, 2 launches).

The selector picks, for each of the K masked draft positions, one of the top-16 draft-logit candidates by a greedy walk:
  score_j = logit_j + succ[cand_j] . (pred[prev] * hp[t]),   hp[t] = sel_proj(dh[t]),   prev = the token chosen at t-1 (anchor at t=0)
The tinygrad-op version (dflash.select_gpu, T unrolled, topk over the 248k vocab, masked gathers) compiles to hundreds of kernels and
ran at 5 tok/s in its own TinyJit (sweeps/chestnut-usb3-20260830/dflash-restore-fault-20260905, 09-06 selector sweeps).

kernel 1 dflash_topk (grid K, 256 threads): per-thread local top-TK over a strided slice of the vocab, then TK rounds of a workgroup
argmax. kernel 2 dflash_walk (grid 1, 256 threads): the sequential walk; the selector codebooks are read straight from their Q4_K
ggml bytes (one 256-wide block per token row: 144 B), so no 254 MB float tables are needed.
"""
from __future__ import annotations
from tinygrad import Tensor, dtypes
from tinygrad.renderer import Estimates
from tinygrad.llm.amd_gemv import PRELUDE, _src_program, _arch

_BAR = '#define BAR() __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup")\n'
_Q4K_ROW = r"""
// dequantize element e (0..255) of the Q4_K block at blk (144 B: d f16, dmin f16, scales[12], qs[128])
DEV float q4k_elem(const u8* blk, u32 e) {
  const float d = f16_to_f32(ld_u16(blk)), dmin = f16_to_f32(ld_u16(blk + 2));
  const u32 sb = e >> 5;                       // sub-block of 32 (8 per block), scale/min index
  u32 sc, mn;
  if (sb < 4) { sc = ld_u8(blk + 4 + sb) & 63u; mn = ld_u8(blk + 4 + sb + 4) & 63u; }
  else { sc = (ld_u8(blk + 4 + sb + 4) & 0xFu) | ((ld_u8(blk + 4 + sb - 4) >> 6) << 4);
         mn = (ld_u8(blk + 4 + sb + 4) >> 4) | ((ld_u8(blk + 4 + sb) >> 6) << 4); }
  const u32 pair = e >> 6, r = e & 63u;        // 64-element pair: low nibbles = first 32, high nibbles = next 32
  const u32 q = ld_u8(blk + 16 + 32 * pair + (r & 31u));
  const u32 nib = (r < 32) ? (q & 0xFu) : (q >> 4);
  return d * (float)sc * (float)nib - dmin * (float)mn;
}
"""

def _topk_src(K:int, V:int, TK:int) -> str:
  return PRELUDE + _BAR + rf"""
KERNEL(dflash_topk, 256)(float* __restrict__ vals, i32* __restrict__ ids, const float* __restrict__ logits) {{
  const u32 t = wg_id(), th = tid();
  const float* row = logits + (u64)t * {V}u;
  float lv[{TK}]; i32 li[{TK}];
  #pragma unroll
  for (int k = 0; k < {TK}; k++) {{ lv[k] = -3.0e38f; li[k] = -1; }}
  for (u32 v = th; v < {V}u; v += 256u) {{           // strided scan, sorted-insert into the local top-{TK} (descending)
    const float x = row[v];
    if (x > lv[{TK - 1}]) {{
      int k = {TK - 1};
      #pragma unroll
      for (int s = {TK - 1}; s > 0; s--) {{ if (x > lv[s - 1]) {{ lv[s] = lv[s - 1]; li[s] = li[s - 1]; k = s - 1; }} }}
      lv[k] = x; li[k] = (i32)v;
    }}
  }}
  __attribute__((shared)) float sv[256]; __attribute__((shared)) i32 si[256];
  int head = 0;
  for (int k = 0; k < {TK}; k++) {{                      // {TK} rounds: workgroup argmax over every thread's current head
    sv[th] = head < {TK} ? lv[head] : -3.0e38f; si[th] = head < {TK} ? li[head] : -1;
    BAR();
    for (u32 s = 128; s > 0; s >>= 1) {{
      if (th < s) {{ const bool take = sv[th + s] > sv[th] || (sv[th + s] == sv[th] && si[th + s] >= 0 && si[th + s] < si[th]);
                      if (take) {{ sv[th] = sv[th + s]; si[th] = si[th + s]; }} }}
      BAR();
    }}
    const float bv = sv[0]; const i32 bi = si[0];
    if (th == 0) {{ vals[t * {TK} + k] = bv; ids[t * {TK} + k] = bi; }}
    if (head < {TK} && li[head] == bi) head++;           // the winner pops its head (ids are unique across threads)
    BAR();
  }}
}}
"""

def _walk_src(K:int, TK:int, R:int, BB:int) -> str:
  assert R == 256 and TK == 16, "walk kernel is written for rank 256 (one Q4_K block per row) and 16 candidates"
  return PRELUDE + _BAR + _Q4K_ROW + rf"""
KERNEL(dflash_walk, 256)(i32* __restrict__ draft, const float* __restrict__ vals, const i32* __restrict__ ids, const float* __restrict__ hp,
                         const u8* __restrict__ pred_raw, const u8* __restrict__ succ_raw, const i32* __restrict__ anchor) {{
  const u32 th = tid();
  __attribute__((shared)) float gate[{R}];
  __attribute__((shared)) float part[256];
  __attribute__((shared)) i32 s_prev;
  if (th == 0) s_prev = anchor[0];
  BAR();
  for (u32 t = 0; t < {K}u; t++) {{
    const i32 prev = s_prev;
    gate[th] = q4k_elem(pred_raw + (u64)prev * {BB}u, th) * hp[t * {R}u + th];   // A[r] * hp[t][r], one r per thread
    BAR();
    // candidate j = th / 16 handles 16 of the 256 ranks: r = (th % 16) * 16 .. +16
    const u32 j = th >> 4, r0 = (th & 15u) * 16u;
    const i32 cid = ids[t * {TK} + j];
    const u8* srow = succ_raw + (u64)cid * {BB}u;
    float acc = 0.0f;
    #pragma unroll
    for (u32 q = 0; q < 16; q++) acc += q4k_elem(srow, r0 + q) * gate[r0 + q];
    part[th] = acc;
    BAR();
    if (th < {TK}) {{                                    // thread j sums its 16 partials -> score_j
      float s = vals[t * {TK} + th];
      #pragma unroll
      for (u32 q = 0; q < 16; q++) s += part[th * 16 + q];
      part[th] = s;
    }}
    BAR();
    if (th == 0) {{
      u32 best = 0;
      for (u32 q = 1; q < {TK}; q++) if (part[q] > part[best]) best = q;
      const i32 tok = ids[t * {TK} + best];
      draft[t] = tok; s_prev = tok;
    }}
    BAR();
  }}
}}
"""

def select_fused(dlogits:Tensor, hp:Tensor, pred_raw:Tensor, succ_raw:Tensor, anchor:Tensor, K:int, V:int, TK:int=16, R:int=256, BB:int=144) -> Tensor:
  """dlogits (K, V) f32 draft logits, hp (K, R) f32 = sel_proj(dh), pred_raw/succ_raw the Q4_K bytes of the codebooks (V*BB u8),
  anchor (1,) i32 committed token -> (K,) i32 selected draft tokens"""
  dev = dlogits.device; arch = _arch(dev)
  vals = Tensor.empty(K * TK, dtype=dtypes.float32, device=dev); ids = Tensor.empty(K * TK, dtype=dtypes.int32, device=dev)
  src = _topk_src(K, V, TK).replace("KERNEL(dflash_topk,", f"KERNEL(dflash_topk_{K}_{V}_{TK},")
  vals, ids, _ = vals.custom_kernel(ids, dlogits.reshape(K * V).contiguous(),
                                    fxn=_src_program(f"dflash_topk_{K}_{V}_{TK}", src, K, 256, Estimates(ops=2 * K * V, mem=4 * K * V), arch))
  draft = Tensor.empty(K, dtype=dtypes.int32, device=dev)
  src = _walk_src(K, TK, R, BB).replace("KERNEL(dflash_walk,", f"KERNEL(dflash_walk_{K}_{TK}_{R},")
  outs = draft.custom_kernel(vals, ids, hp.reshape(K * R).contiguous(), pred_raw, succ_raw, anchor.reshape(1).contiguous(),
                             fxn=_src_program(f"dflash_walk_{K}_{TK}_{R}", src, 1, 256, Estimates(ops=K * TK * R * 2, mem=K * TK * BB), arch))
  return outs[0]

def argmax_rows(x:Tensor) -> Tensor:
  """argmax over the last axis of (..., V) float rows as one custom kernel (one workgroup per row; the tinygrad reduce over a
  248k-wide vocab launches 2 workgroups and takes ~58 us, this takes ~8 us). Ties -> lowest index. Returns int32 (...,)."""
  V = int(x.shape[-1]); K = int(x.numel()) // V; dev = x.device
  xf = x.reshape(K * V).float().contiguous()
  vals = Tensor.empty(K, dtype=dtypes.float32, device=dev); ids = Tensor.empty(K, dtype=dtypes.int32, device=dev)
  src = _topk_src(K, V, 1).replace("KERNEL(dflash_topk,", f"KERNEL(argmax_rows_{K}_{V},")
  outs = vals.custom_kernel(ids, xf, fxn=_src_program(f"argmax_rows_{K}_{V}", src, K, 256, Estimates(ops=K * V, mem=4 * K * V), _arch(dev)))
  return outs[1].reshape(*x.shape[:-1])
