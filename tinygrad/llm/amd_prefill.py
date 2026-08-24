# custom AMD (gfx1100) prefill kernels: many-token chunks through the packed GGUF weights.
# the decode gemv (amd_gemv) streams the weights once per <= MAX_T tokens and dots them from registers, which is ALU bound past ~8
# tokens. for prefill chunks the weights are decoded once per chunk into an int8 copy with per-row/per-128 scales (deq8), then a
# tensor-core GEMM (v_wmma_i32_16x16x16_iu8, wave32) multiplies them with the per-128 int8 activations (amd_gemv.xblk). the attention of
# a chunk is a batched flash-attention over the quantized kv cache (attn_prep + attn_pf), also on the tensor cores.
from __future__ import annotations
from tinygrad import Tensor, dtypes
from tinygrad.renderer import Estimates
from tinygrad.helpers import getenv
from tinygrad.llm.amd_gemv import PRELUDE, FORMATS, _fmt_code, _src_program, _arch, _grid_tensor

# ---------------------------------------------------------------------------------------------------------------------------------------
# deq8: raw ggml (N, K) -> q8[N][K] int8 with one scale per 128 elements (sw[N][K/128], Q8_K-like). lane j of a 256-block decodes 32
# elements in two runs of 16 (offsets/fields per format); in every format the 4 lanes j>>2 together cover one 128-block, so the block max
# is a 4-lane reduction. the requantization adds ~0.4% relative noise, far below the 2-6 bit weight noise.
# (start, words, signed, scale, offset): value[i] = scale * q[i] - offset for the 16 int8/uint8 q in the u32x4 `words`
_G03, _G47 = "(u32x4){o.g[0], o.g[1], o.g[2], o.g[3]}", "(u32x4){o.g[4], o.g[5], o.g[6], o.g[7]}"
# q4k/q5k: the lane's values are sub-blocks 2i and 2i+1 while o.m is the min of sub-block j (the dot sums over lanes), so the two mins
# are re-extracted from the header here (see _K4SCALES)
_K4MINS = r"""
  float mm[2];
  #pragma unroll
  for (int u = 0; u < 2; u++) {
    const u32 jj = 2 * i + u, shj = (jj & 3) * 8;
    const u32 mj = jj < 4 ? ((r.hdr.z >> shj) & 63) : ((((r.hdr.w >> shj) >> 4) & 0xF) | ((((r.hdr.z >> shj) >> 6) & 3) << 4));
    mm[u] = f16_to_f32(r.hdr.x >> 16) * (float)mj;
  }
"""
DEQ: dict[int, tuple] = {  # ggml_type: (runs, unused[, extra code before the runs])
  12: ([("e0", "o.qlo", False, "o.s0", "mm[0]"), ("e0 + 32", "o.qhi", False, "o.s1", "mm[1]")], 1, _K4MINS),
  13: ([("e0", "o.qlo", False, "o.s0", "mm[0]"), ("e0 + 32", "o.qhi", False, "o.s1", "mm[1]")], 1, _K4MINS),
  14: ([("eA", "o.qA", False, "o.sA", "32.0f * o.sA"), ("eB", "o.qB", False, "o.sB", "32.0f * o.sB")], 1),
  11: ([("e0", "o.qA", True, "o.sA", "0.0f"), ("e0 + 16", "o.qB", True, "o.sB", "0.0f")], 0),
  10: ([("e0", "o.qA", False, "o.sA", "o.mA"), ("e0 + 16", "o.qB", False, "o.sB", "o.mB")], 0),
  8: ([("32 * j", "o.qA", True, "o.d", "0.0f"), ("32 * j + 16", "o.qB", True, "o.d", "0.0f")], 0),
  20: ([("32 * j", "o.qA", True, "o.d", "0.0f"), ("32 * j + 16", "o.qB", True, "o.d", "0.0f")], 0),
  23: ([("32 * j", "o.qA", True, "o.d", "0.0f"), ("32 * j + 16", "o.qB", True, "o.d", "0.0f")], 0),
  16: ([("32 * j", _G03, True, "o.d", "0.0f"), ("32 * j + 16", _G47, True, "o.d", "0.0f")], 0),
  18: ([("32 * j", _G03, True, "o.d", "0.0f"), ("32 * j + 16", _G47, True, "o.d", "0.0f")], 0),
  21: ([("32 * j", _G03, True, "o.d", "0.0f"), ("32 * j + 16", _G47, True, "o.d", "0.0f")], 0),
  17: ([("32 * j", _G03, True, "o.d0", "0.0f"), ("32 * j + 16", _G47, True, "o.d1", "0.0f")], 0),
  22: ([("32 * j", _G03, True, "o.d0", "0.0f"), ("32 * j + 16", _G47, True, "o.d1", "0.0f")], 0),
  0: ([("32 * j", "o.w", True, "", ""), ("32 * j + 16", "o.w + 16", True, "", "")], 0),  # float runs
  1: ([("32 * j", "o.w", True, "", ""), ("32 * j + 16", "o.w + 16", True, "", "")], 0),
}

def _deq8_src(ggml_type:int, N:int, K:int, WG:int, n_wg:int) -> str:
  f = FORMATS[ggml_type]
  runs, pair, *pre = DEQ[ggml_type]
  NB, BB = K // 256, f["bb"]
  gcall = ", grid" if f["grid"] else ""
  grid_arg = ", const u32* __restrict__ grid_g" if f["grid"] else ""
  grid_setup = ""
  if f["grid"]:
    grid_setup = f"  __attribute__((shared)) u32 grid[{f['grid_words']}];\n  for (u32 t = tid(); t < {f['grid_words']}u; t += {WG}u) grid[t] = grid_g[t];\n" + \
                 '  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");\n'
  def run_code(r:int) -> str:
    start, words, signed, scale, offset = runs[r]
    if not scale:  # float weights
      return f"  {{ const float* wp = {words};\n    #pragma unroll\n    for (int i = 0; i < 16; i++) v[{r}][i] = wp[i]; }}\n"
    cast = "(float)(i32)(i8)" if signed else "(float)"
    return rf"""  {{ const u32x4 wq = {words}; const u32 ww[4] = {{wq.x, wq.y, wq.z, wq.w}}; const float sc = {scale}, of = {offset};
    #pragma unroll
    for (int i = 0; i < 16; i++) v[{r}][i] = sc * {cast}((ww[i >> 2] >> ((i & 3) * 8)) & 0xffu) - of; }}
"""
  return PRELUDE + _fmt_code(f) + rf"""
#define dpp_xor1(v) __builtin_bit_cast(float, __builtin_amdgcn_mov_dpp(__builtin_bit_cast(i32, (v)), 0xB1, 0xf, 0xf, true))
#define dpp_xor2(v) __builtin_bit_cast(float, __builtin_amdgcn_mov_dpp(__builtin_bit_cast(i32, (v)), 0x4E, 0xf, 0xf, true))
KERNEL(deq8, {WG})(i8* __restrict__ q8, float* __restrict__ sw, const u8* __restrict__ w, const i8* __restrict__ dep{grid_arg}) {{
{grid_setup}
  __attribute__((shared)) u8 stg_all[{WG // 32} * 1024];
  const u32 lane = lane_id(), wave = __builtin_amdgcn_readfirstlane(tid() >> 5);
  const u32 g = lane >> 3, j = lane & 7;
  u8* stg = stg_all + wave * 1024;
  {f["setup"]}
  // a workgroup walks one row at a time with its {WG // 32} waves on consecutive 1KB pieces, so the writes of a workgroup are contiguous
  // (waves on separate rows scatter 1KB writes over thousands of DRAM pages, which halves the store throughput)
  for (u32 row = wg_id(); row < {N}u; row += {n_wg}) {{
    const u8* wrow = w + (u64)row * ({NB} * {BB});
    i8* qrow = q8 + (u64)row * {K};
    float* srow = sw + (u64)row * {K // 128};
    const u32 bstep = {WG // 32} * 4;
    RawW r = fmt_load_w(wrow, (wave * 4 + g < {NB}u ? wave * 4 + g : {NB - 1}u) * {BB}, j);
    for (u32 blk = wave * 4 + g; blk < {NB}u; blk += bstep) {{
      // next block in flight during the decode (unconditional, clamped: a branch around it makes the compiler wait for every load)
      const RawW nxt = fmt_load_w(wrow, (blk + bstep < {NB}u ? blk + bstep : blk) * {BB}, j);
      const Dec o = fmt_decode(r, j{gcall});
      float v[2][16];
{(pre[0] if pre else "") + run_code(0) + run_code(1)}
      float m = 0.0f;
      #pragma unroll
      for (int i = 0; i < 16; i++) m = __builtin_fmaxf(m, __builtin_fmaxf(__builtin_fabsf(v[0][i]), __builtin_fabsf(v[1][i])));
      m = __builtin_fmaxf(m, dpp_xor1(m)); m = __builtin_fmaxf(m, dpp_xor2(m));  // the 4 lanes of the 128-block
      const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
      u32 p0[4], p1[4];
      #pragma unroll
      for (int i = 0; i < 4; i++) {{
        p0[i] = 0u; p1[i] = 0u;
        #pragma unroll
        for (int b = 0; b < 4; b++) {{
          p0[i] |= ((u32)(i32)__builtin_rintf(v[0][4 * i + b] * id) & 0xffu) << (8 * b);
          p1[i] |= ((u32)(i32)__builtin_rintf(v[1][4 * i + b] * id) & 0xffu) << (8 * b);
        }}
      }}
      // the 4 blocks of this wave are 1KB contiguous in the row: stage them in LDS so each store instruction writes 512 contiguous bytes
      // (the runs alone would write 16B pieces at a 32B stride, two half passes per line)
      const u32 s0 = g * 256 + ({runs[0][0]}), s1 = g * 256 + ({runs[1][0]});
      __builtin_memcpy(stg + s0, p0, 16); __builtin_memcpy(stg + s1, p1, 16);
      __builtin_amdgcn_fence(__ATOMIC_SEQ_CST, "wavefront");
      u32x4 o0, o1; __builtin_memcpy(&o0, stg + lane * 16, 16); __builtin_memcpy(&o1, stg + 512 + lane * 16, 16);
      __builtin_amdgcn_fence(__ATOMIC_SEQ_CST, "wavefront");
      const u32 base = (blk - g) * 256;
      __builtin_memcpy(qrow + base + lane * 16, &o0, 16); __builtin_memcpy(qrow + base + 512 + lane * 16, &o1, 16);
      r = nxt;
      if ((j & 3) == 0) srow[(blk * 256 + ({runs[0][0]})) >> 7] = d;
    }}
  }}
}}
"""

def deq8(w:Tensor, ggml_type:int, N:int, K:int, dep:Tensor, q8:Tensor|None=None, sw:Tensor|None=None) -> tuple[Tensor, Tensor]:
  """raw ggml bytes of an (N, K) tensor -> (q8[N*K] int8, sw[N*K/128] f32), into q8/sw when given. dep: an unused kernel input that
  orders the dequant after the activation it is consumed with (or after the previous reader of the q8 buffer)"""
  assert ggml_type in DEQ and K % 1024 == 0, f"deq8: unsupported type {ggml_type} / K={K}"
  f = FORMATS[ggml_type]
  WG = 32 * min(8, (K // 256 + 3) // 4)  # waves x 4 blocks cover the row
  n_wg = min(N, 2048 if f["grid"] else 8192)
  name = f"deq8_{f['name']}_{N}_{K}"
  src = _deq8_src(ggml_type, N, K, WG, n_wg).replace("KERNEL(deq8,", f"KERNEL({name},")
  if q8 is None: q8 = Tensor.empty(N * K, dtype=dtypes.int8, device=w.device)
  if sw is None: sw = Tensor.empty(N * K // 128, dtype=dtypes.float32, device=w.device)
  args = [sw, w, dep.reshape(-1)] + ([_grid_tensor(f["grid"], w.device)] if f["grid"] else [])
  outs = q8.custom_kernel(*args, fxn=_src_program(name, src, n_wg, WG, Estimates(ops=8 * N * K, mem=N * (K // 256) * f["bb"] + N * K), _arch(w.device)))
  return outs[0], outs[1]

# ---------------------------------------------------------------------------------------------------------------------------------------
# gemm_q8: y[T][N] = xq[T][K] . q8[N][K]^T, both sides int8 with one scale per 128 k (+ residual). workgroup tile BM rows x BT tokens,
# K staged in LDS KS = 128 at a time (= one scale block: the int32 accumulators of a stage are folded into the float accumulators once).
# wave tile 32 rows x (16 * WN) tokens: 2 x WN WMMA 16x16 tiles. v_wmma_i32_16x16x16_iu8 wave32 layout (measured): A lane l holds row
# l%16 (16 k bytes), B lane l holds column l%16, accumulator element i of lane l is D[2i + (l>=16)][l%16].
BM, BT, KS = getenv("GEMM_BM", 64), getenv("GEMM_BT", 64), 128
LDA = KS + 16  # row pitch in LDS (bytes): 16B b128 reads of 16 rows land on distinct banks in two phases

def _gemm_src(N:int, K:int, T:int, residual:bool) -> str:
  WN = getenv("GEMM_WN", 2)  # token tiles per wave
  PF = getenv("GEMM_PF", 1)  # prefetch the next stage into registers during compute
  WT = BT // (16 * WN)       # waves along tokens
  WR = BM // 32               # waves along rows
  NWAVE = WR * WT; NT = NWAVE * 32
  assert T % BT == 0 and K % KS == 0 and BT % (16 * WN) == 0
  NRT = (N + BM - 1) // BM  # row tiles (the last one clamps its loads and skips its stores past N)
  NTT = T // BT             # token tiles: consecutive workgroups share a row tile so the weight tile stays in L2
  NKB = KS // 32
  LA, LB = BM * KS // 16 // NT, BT * KS // 16 // NT  # 16B loads per thread per stage
  assert LA * NT * 16 == BM * KS and LB * NT * 16 == BT * KS and NT >= BM and NT >= BT
  # the staged 16B words are individually named registers: an array of vectors here ends up in scratch memory
  def ldc(k0:str) -> str:
    out = []
    for it in range(LA):
      out.append(f"    {{ const u32 idx = {it * NT} + t, r = idx / {KS // 16}, c = idx % {KS // 16}; "
                 f"__builtin_memcpy(&pa{it}, q8 + (u64)(row0 + r < {N}u ? row0 + r : {N - 1}u) * {K} + {k0} + c * 16, 16); }}")
    for it in range(LB):
      out.append(f"    {{ const u32 idx = {it * NT} + t, r = idx / {KS // 16}, c = idx % {KS // 16}; "
                 f"__builtin_memcpy(&pb{it}, xq + (u64)(tok0 + r) * {K} + {k0} + c * 16, 16); }}")
    out.append(f"    if (t < {BM}) psw = sw[(u64)(row0 + t < {N}u ? row0 + t : {N - 1}u) * {K // KS} + ({k0}) / {KS}];")
    out.append(f"    if (t < {BT}) psx = xs[(u64)(tok0 + t) * {K // KS} + ({k0}) / {KS}];")
    return "\n".join(out) + "\n"
  st = "\n".join([f"    {{ const u32 idx = {it * NT} + t; __builtin_memcpy(As + (idx / {KS // 16}) * {LDA} + (idx % {KS // 16}) * 16, &pa{it}, 16); }}" for it in range(LA)] +
                 [f"    {{ const u32 idx = {it * NT} + t; __builtin_memcpy(Bs + (idx / {KS // 16}) * {LDA} + (idx % {KS // 16}) * 16, &pb{it}, 16); }}" for it in range(LB)] +
                 [f"    if (t < {BM}) sws[(t & ~15u) | ((t & 1u) << 3) | ((t & 15u) >> 1)] = psw;", f"    if (t < {BT}) sxs[t] = psx;"]) + "\n"
  decl = "  u32x4 " + ", ".join([f"pa{it}" for it in range(LA)] + [f"pb{it}" for it in range(LB)]) + "; float psw = 0.0f, psx = 0.0f;\n"
  return PRELUDE + rf"""
typedef i32 i32x4 __attribute__((ext_vector_type(4)));
typedef i32 i32x8 __attribute__((ext_vector_type(8)));
typedef float f32x4 __attribute__((ext_vector_type(4)));
#define BAR() __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup")
KERNEL(gemm, {NT})(float* __restrict__ y, const i8* __restrict__ q8, const float* __restrict__ sw, const i8* __restrict__ xq,
                  const float* __restrict__ xs{", const float* __restrict__ res" if residual else ""}) {{
  __attribute__((shared)) u8 As[{BM} * {LDA}];
  __attribute__((shared)) u8 Bs[{BT} * {LDA}];
  __attribute__((shared)) float sws[{BM}];  // rows permuted per 16: even rows first, then odd (matches the accumulator layout)
  __attribute__((shared)) float sxs[{BT}];
  const u32 t = tid(), lane = lane_id(), wave = __builtin_amdgcn_readfirstlane(t >> 5);
  const u32 wr = wave / {WT}, wt = wave % {WT};  // wave tile: rows [wr*32, +32), tokens [wt*{16 * WN}, +{16 * WN})
  const u32 l16 = lane & 15, h = lane >> 4;
  const u32 row0 = (wg_id() / {NTT}) * {BM}, tok0 = (wg_id() % {NTT}) * {BT};
  f32x4 acc[2][{WN}][2];  // [row tile][token tile][lo/hi 4 of the 8 accumulator elements]
  #pragma unroll
  for (int a = 0; a < 2; a++)
    #pragma unroll
    for (int b = 0; b < {WN}; b++) acc[a][b][0] = acc[a][b][1] = (f32x4){{0.0f, 0.0f, 0.0f, 0.0f}};
{decl}
  {ldc("0u") if PF else ""}
  for (u32 k0 = 0; k0 < {K}u; k0 += {KS}) {{
    {"" if PF else ldc("k0")}
    BAR();
{st}
    BAR();
    {"if (k0 + " + str(KS) + " < " + str(K) + "u) {" + ldc("(k0 + " + str(KS) + ")") + "}" if PF else ""}
    i32x8 ci[2][{WN}];
    #pragma unroll
    for (int a = 0; a < 2; a++)
      #pragma unroll
      for (int b = 0; b < {WN}; b++) ci[a][b] = (i32x8){{0, 0, 0, 0, 0, 0, 0, 0}};
    #pragma unroll
    for (int kb = 0; kb < {NKB}; kb++) {{
      i32x4 a[2][2], b[{WN}][2];
      #pragma unroll
      for (int rt = 0; rt < 2; rt++)
        #pragma unroll
        for (int hf = 0; hf < 2; hf++) __builtin_memcpy(&a[rt][hf], As + (wr * 32 + rt * 16 + l16) * {LDA} + kb * 32 + hf * 16, 16);
      #pragma unroll
      for (int tt = 0; tt < {WN}; tt++)
        #pragma unroll
        for (int hf = 0; hf < 2; hf++) __builtin_memcpy(&b[tt][hf], Bs + (wt * {16 * WN} + tt * 16 + l16) * {LDA} + kb * 32 + hf * 16, 16);
      #pragma unroll
      for (int rt = 0; rt < 2; rt++)
        #pragma unroll
        for (int tt = 0; tt < {WN}; tt++) {{
          ci[rt][tt] = __builtin_amdgcn_wmma_i32_16x16x16_iu8_w32(true, a[rt][0], true, b[tt][0], ci[rt][tt], false);
          ci[rt][tt] = __builtin_amdgcn_wmma_i32_16x16x16_iu8_w32(true, a[rt][1], true, b[tt][1], ci[rt][tt], false);
        }}
    }}
    // fold the stage: acc += ci * sw[row] * sx[token]
    f32x4 swv[2][2];
    #pragma unroll
    for (int rt = 0; rt < 2; rt++) {{
      __builtin_memcpy(&swv[rt][0], &sws[wr * 32 + rt * 16 + h * 8], 16);
      __builtin_memcpy(&swv[rt][1], &sws[wr * 32 + rt * 16 + h * 8 + 4], 16);
    }}
    #pragma unroll
    for (int tt = 0; tt < {WN}; tt++) {{
      const float sx = sxs[wt * {16 * WN} + tt * 16 + l16];
      #pragma unroll
      for (int rt = 0; rt < 2; rt++)
        #pragma unroll
        for (int i = 0; i < 4; i++) {{
          acc[rt][tt][0][i] += (float)ci[rt][tt][i] * (swv[rt][0][i] * sx);
          acc[rt][tt][1][i] += (float)ci[rt][tt][4 + i] * (swv[rt][1][i] * sx);
        }}
    }}
  }}
  // accumulator element i of lane: row 2i + h, token l16
  #pragma unroll
  for (int rt = 0; rt < 2; rt++)
    #pragma unroll
    for (int tt = 0; tt < {WN}; tt++) {{
      const u32 tok = tok0 + wt * {16 * WN} + tt * 16 + l16;
      #pragma unroll
      for (int i = 0; i < 8; i++) {{
        const u32 row = row0 + wr * 32 + rt * 16 + 2 * i + h;
        const u64 e = (u64)tok * {N} + row;
        if (row < {N}u) y[e] = acc[rt][tt][i >> 2][i & 3]{" + res[e]" if residual else ""};
      }}
    }}
}}
"""

def gemm_q8(q8:Tensor, sw:Tensor, N:int, K:int, xq:Tensor, xs:Tensor, T:int, residual:Tensor|None=None) -> Tensor:
  """y[T, N] f32 = x[T, K] @ W[N, K]^T (+ residual) from the deq8 weights and quantize_x(BLK=128) activations"""
  assert xs.numel() == T * K // 128, "gemm_q8 needs per-128 activation scales"
  name = f"gemm_q8_{N}_{K}_t{T}_m{BM}n{BT}_wn{getenv('GEMM_WN', 4)}_pf{getenv('GEMM_PF', 0)}" + ("_res" if residual is not None else "")
  src = _gemm_src(N, K, T, residual is not None).replace("KERNEL(gemm,", f"KERNEL({name},")
  y = Tensor.empty(T * N, dtype=dtypes.float32, device=q8.device)
  args = [q8, sw, xq, xs] + ([residual.reshape(T * N).float()] if residual is not None else [])
  n_wg = ((N + BM - 1) // BM) * (T // BT)
  NT = 32 * (BM // 32) * (BT // (16 * getenv("GEMM_WN", 2)))
  return y.custom_kernel(*args, fxn=_src_program(name, src, n_wg, NT, Estimates(ops=2 * T * N * K, mem=N * K + T * K + T * N * 4), _arch(q8.device)))[0]

# the dequantized weights live in a small pool of persistent slots per size (two per size, alternating): a fresh buffer per linear would
# keep every layer's copy alive during the JIT capture. the slot's previous reader (the gemm output) is the next dequant's dependency, so
# the schedule cannot overwrite a slot before the gemm that reads it ran.
class _Pool:
  def __init__(self): self.slots: dict[tuple[str, int], list[tuple[Tensor, Tensor, Tensor|None]]] = {}; self.turn: dict[tuple[str, int], int] = {}
  def get(self, dev:str, N:int, K:int, dep:Tensor) -> tuple[Tensor, Tensor, Tensor]:
    key = (dev, N * K)
    if key not in self.slots:
      self.slots[key] = [(Tensor.empty(N * K, dtype=dtypes.int8, device=dev).contiguous().realize(),
                          Tensor.empty(N * K // 128, dtype=dtypes.float32, device=dev).contiguous().realize(), None) for _ in range(2)]
      self.turn[key] = 0
    i = self.turn[key]; self.turn[key] = (i + 1) % 2
    q8, sw, last = self.slots[key][i]
    return q8, sw, (last if last is not None else dep)
  def used(self, dev:str, N:int, K:int, y:Tensor):
    key = (dev, N * K); i = (self.turn[key] + 1) % 2  # the slot handed out last
    q8, sw, _ = self.slots[key][i]; self.slots[key][i] = (q8, sw, y)
  def new_forward(self):
    for key, lst in self.slots.items(): self.slots[key] = [(q8, sw, None) for q8, sw, _ in lst]
_pool = _Pool()
def new_forward(): _pool.new_forward()

def gemm(w:Tensor, ggml_type:int, N:int, K:int, xq:Tensor, xs:Tensor, T:int, residual:Tensor|None=None) -> Tensor:
  """prefill linear: deq8 (into a pool slot) + gemm_q8"""
  q8, sw, dep = _pool.get(w.device, N, K, xq)
  q8, sw = deq8(w, ggml_type, N, K, dep, q8, sw)
  y = gemm_q8(q8, sw, N, K, xq, xs, T, residual)
  _pool.used(w.device, N, K, y)
  return y

# ---------------------------------------------------------------------------------------------------------------------------------------
# prefill attention over the quantized kv cache (KVQuant), two kernels:
#  attn_prep (one workgroup per token x kv head): norm + rope + rotation of q (and the QJL-projected q) -> int8 rows with a per-row scale;
#    the new k, v quantized into the cache exactly like the decode kernel (shared code, amd_gemv.kv_write_code)
#  attn_pf (one workgroup per QT query tokens x kv head = QT*G query rows): flash attention in KV tiles of 16 positions. scores through
#    int8 WMMA (q int8 . codebook-index int8 LUT, QJL term: projected q int8 . sign bytes), online softmax in the accumulator layout, P.V
#    through f16 WMMA with the tile's V dequantized (transposed) into LDS. then the rotation is undone, the gate applied and the output
#    quantized per 128 for the output projection.
from tinygrad.uop.ops import UOp, Ops, KernelInfo
from tinygrad.llm.amd_gemv import (ATTN_DEV, KVQuant, KV_SEED_ROT, kv_load_idx, kv_idx_of, kv_cb_init, kv_rotate_code, kv_write_code,
                                   kv_qk_prep_code, hip_to_ir, start_pos_tensor, cache_quant)

def _attn_prep_src(H:int, HKV:int, D:int, RD:int, MAXC:int, eps:float, gated:bool, qk_norm:bool, kvq:KVQuant) -> str:
  G = H // HKV
  assert D == 256 and G <= 8
  QSTRIDE = 2 * D if gated else D
  J = kvq.qjl
  NV = 2 * G + 2 if J else G + 2
  off = kvq.offsets(MAXC)
  def qrow(name:str, sc:str, vec:str) -> str:
    return f"""if (wave < {G}) {{
    float x[8], a = 0.0f;
    #pragma unroll
    for (int i = 0; i < 8; i++) {{ x[i] = {vec}[wave][lane * 8 + i]; a = __builtin_fmaxf(a, __builtin_fabsf(x[i])); }}
    a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
    a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
    const float mx = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
    const float d = mx / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
    const u64 row = (u64)tok * {H} + {G} * kvh + wave;
    u32 w0 = 0, w1 = 0;
    #pragma unroll
    for (int i = 0; i < 4; i++) {{ w0 |= ((u32)(i32)__builtin_rintf(x[i] * id) & 0xffu) << (8 * i); w1 |= ((u32)(i32)__builtin_rintf(x[4 + i] * id) & 0xffu) << (8 * i); }}
    const u32x2 w = {{w0, w1}};
    __builtin_memcpy({name} + row * {D} + lane * 8, &w, 8);
    if (lane == 0) {sc}[row] = d;
  }}"""
  return PRELUDE + rf"""
#define WG 256
#define NW 8
#define BAR() __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup")
{ATTN_DEV}
KERNEL(attn_prep, WG)(i8* __restrict__ qq, float* __restrict__ qsc, i8* __restrict__ sqq, float* __restrict__ sqsc, u8* __restrict__ cache,
                      const float* __restrict__ q_raw, const float* __restrict__ k_raw, const float* __restrict__ v_raw,
                      const float* __restrict__ qnw, const float* __restrict__ knw, const float* __restrict__ freqs, const i32* __restrict__ sp_p) {{
  __attribute__((shared)) float vecs[{NV}][{D}], rot[{G}][{RD}];
  __attribute__((shared)) float cbk_s[16], cbv_s[16], r_s[256], red2[NW]; __attribute__((shared)) u32 idx_s[256];
  float (*q_s)[{D}] = vecs; float* knew = vecs[{NV - 2}]; float* vnew = vecs[{NV - 1}];
  {f"float (*sq_s)[{D}] = vecs + {G};" if J else ""}
  const u32 tok = wg_id() / {HKV}, kvh = wg_id() % {HKV};
  if (tok >= (u32)sp_p[1]) return;
  const i32 start_pos = sp_p[0] + (i32)tok;
  q_raw += (u64)tok * {H * QSTRIDE}; k_raw += (u64)tok * {HKV * D}; v_raw += (u64)tok * {HKV * D};
  const u32 t = tid(), lane = lane_id(), wave = t >> 5;
  u8* Kh = cache + (u64)kvh * {MAXC * kvq.bytes_per_pos};
  {kv_cb_init(kvq)}
  const float* fr = freqs + (u64)start_pos * {RD};
  {kv_qk_prep_code(H, HKV, D, RD, G, QSTRIDE, eps, qk_norm)}
  {kv_rotate_code(kvq, D, G, NV)}
  const bool has_new = true;
  {kv_write_code(kvq, off, D)}
  BAR();
  // the rotated q heads (and QJL-projected q) as int8 rows with a per-row scale
  {qrow("qq", "qsc", "q_s")}
  {qrow("sqq", "sqsc", "sq_s") if J else ""}
}}
"""

def _attn_pf_src(H:int, HKV:int, D:int, RD:int, MAXC:int, gated:bool, kvq:KVQuant, QT:int) -> str:
  G = H // HKV
  NR, RT = QT * G, (QT * G + 15) // 16
  assert D == 256 and NR % 16 == 0
  NWAVE = RT * 2; WG = NWAVE * 32
  QSTRIDE = 2 * D if gated else D
  J = kvq.qjl
  off = kvq.offsets(MAXC)
  LQ = D + 16  # int8 row pitch in LDS
  SK = max(abs(c) for c in kvq.cbk) / 127.0
  cbk8 = " ".join(f"t == {i} ? {int(round(c / SK))} :" for i, c in enumerate(kvq.cbk)) + " 0"
  cbv = " ".join(f"t == {i} ? {c:.7f}f :" for i, c in enumerate(kvq.cbv)) + " 0.0f"
  return PRELUDE + rf"""
#define WG {WG}
#define BAR() __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup")
#define dpp_keep(v, ctrl) __builtin_bit_cast(float, __builtin_amdgcn_update_dpp(__builtin_bit_cast(i32, (v)), __builtin_bit_cast(i32, (v)), (ctrl), 0xf, 0xf, false))
typedef i32 i32x4 __attribute__((ext_vector_type(4)));
typedef i32 i32x8 __attribute__((ext_vector_type(8)));
typedef float f32x8 __attribute__((ext_vector_type(8)));
typedef _Float16 f16x16 __attribute__((ext_vector_type(16)));
{ATTN_DEV}
// max over the 16 lanes of a DPP row -> lanes 15 / 31 (out-of-row sources keep the lane's own value)
DEV float row_max16(float v) {{
  v = __builtin_fmaxf(v, dpp_keep(v, 0x111)); v = __builtin_fmaxf(v, dpp_keep(v, 0x112));
  v = __builtin_fmaxf(v, dpp_keep(v, 0x114)); v = __builtin_fmaxf(v, dpp_keep(v, 0x118)); return v;
}}
KERNEL(attn_pf, WG)(float* __restrict__ out, i8* __restrict__ oq, float* __restrict__ os, float* __restrict__ osum16,
                    const i8* __restrict__ qq, const float* __restrict__ qsc, const i8* __restrict__ sqq, const float* __restrict__ sqsc,
                    const u8* __restrict__ cache, const float* __restrict__ q_raw, const i32* __restrict__ sp_p) {{
  __attribute__((shared)) u8 qbuf[{(2 if J else 1) * NR * LQ}];  // Qs[NR][LQ] (| SQs[NR][LQ]); reused as Os[16][D] f32 in the epilogue
  __attribute__((shared)) i8 Ks[16 * {LQ}]{f", KJs[16 * {LQ}]" if J else ""};
  __attribute__((shared)) _Float16 Vt[{D} * 16];            // [dim][pos]
  __attribute__((shared)) _Float16 Ps[{NWAVE} * 16 * 16];   // per wave [row][pos]
  __attribute__((shared)) float ka_s[16], kb_s[16], va_s[16], qsc_s[{NR}], sqsc_s[{NR}], cbv_s[16];
  __attribute__((shared)) i32 cbk8_s[16];
  i8* Qs = (i8*)qbuf; {f"i8* SQs = (i8*)qbuf + {NR * LQ};" if J else ""}
  const u32 qb = wg_id() / {HKV}, kvh = wg_id() % {HKV};
  const u32 qt0 = qb * {QT}, n = (u32)sp_p[1];
  if (qt0 >= n) return;
  const u32 nq = n - qt0 < {QT}u ? n - qt0 : {QT}u;
  const i32 sp = sp_p[0];
  const u32 kv_end = (u32)sp + qt0 + nq;  // positions [0, kv_end)
  const u32 t = tid(), lane = lane_id(), wave = t >> 5, rt = wave >> 1, dh = wave & 1, l16 = lane & 15, h = lane >> 4;
  const u8* Kh = cache + (u64)kvh * {MAXC * kvq.bytes_per_pos};
  if (t < 16) {{ cbk8_s[t] = {cbk8}; cbv_s[t] = {cbv}; }}
  // the query rows: r = tl * G + hh -> token qt0 + tl, head G*kvh + hh (rows of padding tokens are zero)
  for (u32 i = t; i < {NR * D}; i += WG) {{
    const u32 r = i / {D}, d = i % {D}, tl = r / {G}, hh = r % {G};
    const u64 src = ((u64)(qt0 + tl) * {H} + {G} * kvh + hh) * {D} + d;
    Qs[r * {LQ} + d] = tl < nq ? qq[src] : (i8)0;
    {f"SQs[r * {LQ} + d] = tl < nq ? sqq[src] : (i8)0;" if J else ""}
  }}
  if (t < {NR}) {{
    const u32 tl = t / {G}, hh = t % {G};
    const u64 row = (u64)(qt0 + tl) * {H} + {G} * kvh + hh;
    qsc_s[t] = tl < nq ? qsc[row] * {SK}f : 0.0f;
    sqsc_s[t] = {"tl < nq ? sqsc[row] : 0.0f" if J else "0.0f"};
  }}
  BAR();
  // this lane's 8 accumulator rows: 2i + h of row tile rt
  float qs_r[8], sqs_r[8], m[8], l[8]; i32 row_pos[8];
  f32x8 O[8];
  #pragma unroll
  for (int i = 0; i < 8; i++) {{
    const u32 r = rt * 16 + 2 * i + h;
    qs_r[i] = qsc_s[r]; sqs_r[i] = sqsc_s[r]; m[i] = -1e30f; l[i] = 0.0f; row_pos[i] = sp + (i32)qt0 + (i32)(r / {G});
  }}
  #pragma unroll
  for (int dt = 0; dt < 8; dt++) O[dt] = (f32x8){{0, 0, 0, 0, 0, 0, 0, 0}};
  _Float16* Pw = Ps + wave * 256;
  const u32 ntiles = (kv_end + 15) / 16;
  for (u32 tile = 0; tile < ntiles; tile++) {{
    BAR();
    // dequantize the tile: K as codebook int8, QJL signs as +-1, V as f16 (transposed)
    for (u32 pp = wave; pp < 16; pp += {NWAVE}) {{
      const u32 pos = tile * 16 + pp;
      if (pos < kv_end) {{
        {kv_load_idx(kvq, off, D, "k", kvq.kbits, "kq", "k1")} {kv_load_idx(kvq, off, D, "v", kvq.vbits, "vq", "v1")}
        {f"const u32 kj = ld_u8(Kh + {off['kj']} + (u64)pos * {D // 8} + lane);" if J else ""}
        const float va = ld_f32(Kh + {off['vs']} + (u64)pos * 4);
        u32 kw0 = 0, kw1 = 0{", jw0 = 0, jw1 = 0" if J else ""};
        {" ".join(f"{'kw0' if i < 4 else 'kw1'} |= ((u32)cbk8_s[{kv_idx_of('k', kvq.kbits, i)}] & 0xffu) << {8 * (i % 4)};" for i in range(8))}
        {" ".join(f"{'jw0' if i < 4 else 'jw1'} |= (((kj >> {i}) & 1u) ? 1u : 0xffu) << {8 * (i % 4)};" for i in range(8)) if J else ""}
        {" ".join(f"Vt[(lane * 8 + {i}) * 16 + pp] = (_Float16)(cbv_s[{kv_idx_of('v', kvq.vbits, i)}] * va);" for i in range(8))}
        {{ const u32x2 w = {{kw0, kw1}}; __builtin_memcpy(Ks + pp * {LQ} + lane * 8, &w, 8); }}
        {f"{{ const u32x2 w = {{jw0, jw1}}; __builtin_memcpy(KJs + pp * {LQ} + lane * 8, &w, 8); }}" if J else ""}
        if (lane == 0) {{ ka_s[pp] = ld_f32(Kh + {off['ks']} + (u64)pos * 8); kb_s[pp] = {f"ld_f32(Kh + {off['ks']} + (u64)pos * 8 + 4)" if J else "0.0f"}; }}
      }} else {{
        const u32x2 z = {{0u, 0u}};
        __builtin_memcpy(Ks + pp * {LQ} + lane * 8, &z, 8);
        {f"__builtin_memcpy(KJs + pp * {LQ} + lane * 8, &z, 8);" if J else ""}
        #pragma unroll
        for (int i = 0; i < 8; i++) Vt[(lane * 8 + i) * 16 + pp] = (_Float16)0.0f;
        if (lane == 0) {{ ka_s[pp] = 0.0f; kb_s[pp] = 0.0f; }}
      }}
    }}
    BAR();
    // scores of this wave's 16 rows x the 16 positions
    i32x8 ci = (i32x8){{0, 0, 0, 0, 0, 0, 0, 0}}{", cj = (i32x8){0, 0, 0, 0, 0, 0, 0, 0}" if J else ""};
    #pragma unroll
    for (int ks = 0; ks < {D // 16}; ks++) {{
      i32x4 a, b;
      __builtin_memcpy(&a, Qs + (rt * 16 + l16) * {LQ} + ks * 16, 16);
      __builtin_memcpy(&b, Ks + l16 * {LQ} + ks * 16, 16);
      ci = __builtin_amdgcn_wmma_i32_16x16x16_iu8_w32(true, a, true, b, ci, false);
      {f"__builtin_memcpy(&a, SQs + (rt * 16 + l16) * {LQ} + ks * 16, 16); __builtin_memcpy(&b, KJs + l16 * {LQ} + ks * 16, 16);" if J else ""}
      {"cj = __builtin_amdgcn_wmma_i32_16x16x16_iu8_w32(true, a, true, b, cj, false);" if J else ""}
    }}
    const float ka = ka_s[l16], kb = kb_s[l16];
    const i32 pos = (i32)(tile * 16 + l16);
    float p[8];
    #pragma unroll
    for (int i = 0; i < 8; i++) {{
      float sc = (float)ci[i] * qs_r[i] * ka{" + (float)cj[i] * sqs_r[i] * kb" if J else ""};
      sc = (pos > row_pos[i] || (u32)pos >= kv_end) ? -1e30f : sc;
      float rm = row_max16(sc); rm = h ? read_lane(rm, 31) : read_lane(rm, 15);
      const float mn = __builtin_fmaxf(m[i], rm), corr = __builtin_expf(m[i] - mn);
      p[i] = __builtin_expf(sc - mn);
      float ps = row_sum16(p[i]); ps = h ? read_lane(ps, 31) : read_lane(ps, 15);
      l[i] = l[i] * corr + ps; m[i] = mn;
      #pragma unroll
      for (int dt = 0; dt < 8; dt++) O[dt][i] *= corr;
      Pw[(2 * i + h) * 16 + l16] = (_Float16)p[i];
    }}
    __builtin_amdgcn_fence(__ATOMIC_SEQ_CST, "wavefront");
    f16x16 pa; __builtin_memcpy(&pa, Pw + l16 * 16, 32);
    #pragma unroll
    for (int dt = 0; dt < 8; dt++) {{
      f16x16 vb; __builtin_memcpy(&vb, Vt + (dh * 128 + dt * 16 + l16) * 16, 32);
      O[dt] = __builtin_amdgcn_wmma_f32_16x16x16_f16_w32(pa, vb, O[dt]);
    }}
    __builtin_amdgcn_fence(__ATOMIC_SEQ_CST, "wavefront");
  }}
  // epilogue per row tile: O / l into LDS, undo the rotation (signs * WHT / 16), gate, write + quantize per 128
  float* Os = (float*)qbuf;
  #pragma unroll
  for (int i = 0; i < 8; i++) l[i] = l[i] > 0.0f ? 1.0f / l[i] : 0.0f;
  for (u32 rtt = 0; rtt < {RT}; rtt++) {{
    BAR();
    if (rt == rtt) {{
      #pragma unroll
      for (int dt = 0; dt < 8; dt++)
        #pragma unroll
        for (int i = 0; i < 8; i++) Os[(2 * i + h) * {D} + dh * 128 + dt * 16 + l16] = O[dt][i] * l[i];
    }}
    wht_vecs(Os, 16, t);
    for (u32 b = wave; b < 32; b += {NWAVE}) {{  // one wave per 128-block: row rr, half hf
      const u32 rr = b >> 1, hf = b & 1, r = rtt * 16 + rr, tl = r / {G}, hh = r % {G};
      if (tl >= nq) continue;
      const u64 tok = qt0 + tl, head = {G} * kvh + hh, e0 = (tok * {H} + head) * {D} + hf * 128;
      float y[4], a = 0.0f;
      #pragma unroll
      for (int c = 0; c < 4; c++) {{
        const u32 d = hf * 128 + c * 32 + lane;
        float v = (kv_sgn(d, {KV_SEED_ROT}u) ? -Os[rr * {D} + d] : Os[rr * {D} + d]) * (1.0f / 16.0f);
        {f"const float g = q_raw[(tok * {H} + head) * {QSTRIDE} + {D} + d]; v *= 1.0f / (1.0f + __builtin_expf(-g));" if gated else ""}
        y[c] = v; out[e0 + c * 32 + lane] = v; a = __builtin_fmaxf(a, __builtin_fabsf(v));
      }}
      a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
      a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
      const float mx = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
      const float dq = mx / 127.0f, id = dq != 0.0f ? 1.0f / dq : 0.0f;
      #pragma unroll
      for (int c = 0; c < 4; c++) {{
        const u64 e = e0 + c * 32 + lane;
        const i32 qi = (i32)__builtin_rintf(y[c] * id);
        oq[e] = (i8)qi;
        const float sq = row_sum16((float)qi);
        if (lane == 15) osum16[(e >> 5) * 2] = dq * sq;
        if (lane == 31) osum16[(e >> 5) * 2 + 1] = dq * sq;
      }}
      if (lane == 31) os[e0 >> 7] = dq;
    }}
  }}
}}
"""

def attn_prefill(cache:Tensor, q_raw:Tensor, k_raw:Tensor, v_raw:Tensor, qnw:Tensor|None, knw:Tensor|None, freqs:Tensor, start_pos:UOp|int,
                 H:int, HKV:int, D:int, RD:int, MAXC:int, eps:float, gated:bool, T:int, n_tok:UOp|int|None, kvq:KVQuant) -> Tensor:
  """attention of a T-token chunk (positions start_pos.., tokens >= n_tok are padding) over the quantized kv cache, updated in place.
  returns (T, H*D) f32 (gated), int8 quantization (block 128) cached"""
  G = H // HKV
  QT = getenv("ATTN_QT", 8)
  qk_norm = qnw is not None
  dev, arch = cache.device, _arch(cache.device)
  sp_t = start_pos_tensor(start_pos, dev, T if n_tok is None else n_tok)
  dummy = qnw if qk_norm else Tensor.zeros(D, device=dev)
  dummyk = knw if qk_norm else dummy
  J = kvq.qjl
  qq, sqq = Tensor.empty(T * H * D, dtype=dtypes.int8, device=dev), Tensor.empty(T * H * D if J else 8, dtype=dtypes.int8, device=dev)
  qsc, sqsc = Tensor.empty(T * H, dtype=dtypes.float32, device=dev), Tensor.empty(T * H if J else 8, dtype=dtypes.float32, device=dev)
  sfx = f"_{H}_{HKV}_{D}_{RD}_{MAXC}_{int(gated)}{int(qk_norm)}_{kvq.key}"
  src = _attn_prep_src(H, HKV, D, RD, MAXC, eps, gated, qk_norm, kvq).replace("KERNEL(attn_prep,", f"KERNEL(attn_prep{sfx},")
  ir = hip_to_ir(src, arch)
  def prep_fxn(*params):
    sink = UOp.sink(UOp.special(T * HKV, "gidx0"), UOp.special(256, "lidx0"), *params,
                    arg=KernelInfo(name=f"attn_prep{sfx}", estimates=Estimates(ops=T * H * D * 64, mem=T * H * D * 8)))
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=ir)))
  outs = qq.custom_kernel(qsc, sqq, sqsc, cache, q_raw.reshape(-1).float(), k_raw.reshape(-1).float(), v_raw.reshape(-1).float(),
                          dummy, dummyk, freqs, sp_t, fxn=prep_fxn)
  qq, qsc, sqq, sqsc, cache = outs[0], outs[1], outs[2], outs[3], outs[4]
  out = Tensor.empty(T * H * D, dtype=dtypes.float32, device=dev)
  oq, os_, osum16 = (Tensor.empty(n, dtype=dt, device=dev) for n, dt in ((T * H * D, dtypes.int8), (T * H * D // 128, dtypes.float32), (T * H * D // 16, dtypes.float32)))
  name = f"attn_pf{sfx}_q{QT}"
  src = _attn_pf_src(H, HKV, D, RD, MAXC, gated, kvq, QT).replace("KERNEL(attn_pf,", f"KERNEL({name},")
  ir_pf = hip_to_ir(src, arch)
  NWG, WGS = ((T + QT - 1) // QT) * HKV, 32 * 2 * ((QT * G + 15) // 16)
  def pf_fxn(*params):
    sink = UOp.sink(UOp.special(NWG, "gidx0"), UOp.special(WGS, "lidx0"), *params,
                    arg=KernelInfo(name=name, estimates=Estimates(ops=T * H * MAXC * D * 4, mem=HKV * MAXC * kvq.bytes_per_pos * (T // QT))))
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=ir_pf)))
  outs = out.custom_kernel(oq, os_, osum16, qq, qsc, sqq, sqsc, cache, q_raw.reshape(-1).float(), sp_t, fxn=pf_fxn)
  out = outs[0]
  cache_quant(out, outs[1], outs[2], outs[3])
  return out.reshape(T, H * D)
