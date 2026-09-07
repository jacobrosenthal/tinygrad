"""Memory-bound GGUF-quantized GEMV kernels for AMD RDNA3 (gfx1100), used for single-token decode.

y[N] = W[N,K] @ x[K] with W kept in its raw GGUF block format. x is quantized to int8 (per-32 scales) once per GEMV input and the
weights are consumed with v_dot4_i32_iu8, so the kernels stream weights at DRAM bandwidth. Source is HIP C++ compiled to LLVM IR by the
system clang (no ROCm needed) and then handed to tinygrad's own AMD LLVM compiler like any other kernel, so the JIT/graph sees normal programs.
"""
from __future__ import annotations
import functools, hashlib, pathlib, re, subprocess, os
from tinygrad import Tensor, dtypes, nn
from tinygrad.uop.ops import UOp, Ops, KernelInfo
from tinygrad.renderer import Estimates
from tinygrad.helpers import getenv, cache_dir

# ---------------------------------------------------------------------------------------------------------------------------------------
# compile HIP C++ device code to LLVM IR text with clang (cached on disk by content hash)

_IR_CACHE = pathlib.Path(cache_dir) / "amd_gemv_ir"
def hip_to_ir(src:str, arch:str="gfx1100") -> str:
  _IR_CACHE.mkdir(parents=True, exist_ok=True)
  f = _IR_CACHE / f"{hashlib.sha256((arch + src).encode()).hexdigest()[:24]}.ll"
  if not f.exists():
    cpp = f.with_suffix(".hip"); cpp.write_text(src)
    clang = os.environ.get("AMD_GEMV_CLANG", "clang")
    r = subprocess.run([clang, "-x", "hip", "--offload-device-only", f"--offload-arch={arch}", "-nogpulib", "-nogpuinc", "-O3",
                        "-S", "-emit-llvm", "-o", str(f), str(cpp)], capture_output=True, text=True)
    if r.returncode != 0:
      raise RuntimeError("clang failed:\n" + r.stderr + "\n--- source ---\n" + "\n".join(f"{i+1:4d} {l}" for i, l in enumerate(src.split("\n"))))
  ir = f.read_text()
  # drop the hip cuid global + llvm.compiler.used so the object has no data section
  ir = re.sub(r"^@__hip_cuid_\w+ = .*$\n", "", ir, flags=re.M)
  ir = re.sub(r"^@llvm\.compiler\.used = .*$\n", "", ir, flags=re.M)
  return ir

def _src_program(name:str, src:str, n_wg:int, wg:int, est:Estimates, arch:str):
  def fxn(*params):
    sink = UOp.sink(UOp.special(n_wg, "gidx0"), UOp.special(wg, "lidx0"), *params, arg=KernelInfo(name=name, estimates=est))
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=hip_to_ir(src, arch))))
  return fxn

_ARCH: dict[str, str] = {}
def _arch(device:str) -> str:
  # cached, the Device can't be touched while a @function graph is being captured
  if (a:=_ARCH.get(device)) is None:
    from tinygrad.device import Device
    _ARCH[device] = a = Device[device].renderer.target.arch.split(":")[0]
  return a

# ---------------------------------------------------------------------------------------------------------------------------------------
# device code

PRELUDE = r"""
typedef unsigned char u8; typedef unsigned short u16; typedef unsigned int u32; typedef int i32; typedef signed char i8;
typedef unsigned long u64;
typedef u32 u32x4 __attribute__((ext_vector_type(4)));
typedef u32 u32x2 __attribute__((ext_vector_type(2)));
#define DEV static inline __attribute__((device, always_inline))
#define KERNEL(name, wg) extern "C" __attribute__((global)) void __attribute__((amdgpu_flat_work_group_size(wg, wg))) name
DEV u32 lane_id() { return __builtin_amdgcn_mbcnt_hi(~0u, __builtin_amdgcn_mbcnt_lo(~0u, 0u)); }
DEV u32 wg_id() { return __builtin_amdgcn_workgroup_id_x(); }
DEV u32 tid() { return __builtin_amdgcn_workitem_id_x(); }
// v_dot4_i32_iu8: a,b are 4 packed int8 (signed/unsigned selectable), c is the i32 accumulator
DEV i32 dot4_ss(u32 a, u32 b, i32 c) { return __builtin_amdgcn_sudot4(true, (i32)a, true, (i32)b, c, false); }
DEV i32 dot4_us(u32 a, u32 b, i32 c) { return __builtin_amdgcn_sudot4(false, (i32)a, true, (i32)b, c, false); }
DEV i32 dot16_ss(u32x4 q, u32x4 x) { i32 a = dot4_ss(q.x, x.x, 0); a = dot4_ss(q.y, x.y, a); a = dot4_ss(q.z, x.z, a); return dot4_ss(q.w, x.w, a); }
DEV i32 dot16_us(u32x4 q, u32x4 x) { i32 a = dot4_us(q.x, x.x, 0); a = dot4_us(q.y, x.y, a); a = dot4_us(q.z, x.z, a); return dot4_us(q.w, x.w, a); }
DEV float f16_to_f32(u32 h) { return (float)__builtin_bit_cast(_Float16, (u16)(h & 0xffff)); }
DEV u32 ld_u32(const u8* p) { u32 v; __builtin_memcpy(&v, p, 4); return v; }
DEV u32x2 ld_u32x2(const u8* p) { u32x2 v; __builtin_memcpy(&v, p, 8); return v; }
DEV u32x4 ld_u32x4(const u8* p) { u32x4 v; __builtin_memcpy(&v, p, 16); return v; }
// sub-dword loads read the containing aligned dword: the d16 loads the compiler emits otherwise (two in-flight loads filling the halves of
// one VGPR) corrupt results nondeterministically on gfx1100. u16 addresses are 2-byte aligned (all block layouts have even sizes/offsets)
DEV u32 ld_u16(const u8* p) { const u64 a = (u64)p; u32 v; __builtin_memcpy(&v, (const u8*)(a & ~3ull), 4); return (v >> ((a & 2) * 8)) & 0xffff; }
DEV u32 ld_u8(const u8* p) { const u64 a = (u64)p; u32 v; __builtin_memcpy(&v, (const u8*)(a & ~3ull), 4); return (v >> ((a & 3) * 8)) & 0xff; }
DEV float ld_f32(const u8* p) { float v; __builtin_memcpy(&v, p, 4); return v; }
#define dpp_shr(v, ctrl) __builtin_bit_cast(float, __builtin_amdgcn_update_dpp(0, __builtin_bit_cast(i32, (v)), (ctrl), 0xf, 0xf, true))
// sum over lanes [0,16) -> lane 15, [16,32) -> lane 31 (row_shr within each 16-lane row, bound_ctrl zero-fills)
DEV float row_sum16(float v) {
  v += dpp_shr(v, 0x111); v += dpp_shr(v, 0x112); v += dpp_shr(v, 0x114); v += dpp_shr(v, 0x118); return v;
}
DEV float read_lane(float v, u32 l) { return __builtin_bit_cast(float, __builtin_amdgcn_readlane(__builtin_bit_cast(i32, v), l)); }
DEV float wave_sum(float v) { v = row_sum16(v); return read_lane(v, 15) + read_lane(v, 31); }
// spread the low 4 bits of s into bytes (0x00/0x01 per byte), bit i -> byte i
DEV u32 sign_m(u32 s) { return ((s & 0xFu) * 0x00204081u) & 0x01010101u; }
// negate the bytes of g (all nonzero) where the 0/1 byte m is 1: (g ^ 0xFF) + 1 per byte, no cross-byte carries since g != 0
DEV u32 apply_signs(u32 g, u32 m) { return (g ^ ((m << 8) - m)) + m; }
// 7-bit sign index -> 8 sign bits (bit 7 = parity), see ksigns_iq2xs
DEV u32 ksigns(u32 idx) { idx &= 127u; return idx | ((u32)(__builtin_popcount(idx) & 1) << 7); }
// 16-entry int8 LUT applied to the 4 nibbles of n (each byte of n must be in [0,16)). lut0 = entries 0-7, lut1 = entries 8-15
DEV u32 nib_lut(u32 n, u32 lut0_lo, u32 lut0_hi, u32 lut1_lo, u32 lut1_hi) {
  const u32 lo = __builtin_amdgcn_perm(lut0_hi, lut0_lo, n & 0x07070707u);
  const u32 hi = __builtin_amdgcn_perm(lut1_hi, lut1_lo, n & 0x07070707u);
  const u32 m1 = (n >> 3) & 0x01010101u, m = (m1 << 8) - m1;  // 0xFF where bit 3 of the nibble is set
  return (hi & m) | (lo & ~m);
}
"""

# x quantization: float x[K] -> int8 q[K], f32 xs[K/32] (block scale), f32 xsum16[K/16] (sum of the dequantized x per 16)
def _quant_src(K:int, in_dtype:str, BLK:int=32) -> str:
  # one wave per BLK-block: lane holds elements blk*BLK + 32*c + lane, c < BLK/32. xs per block, xsum16 per 16 (dequantized sums)
  C = BLK // 32
  return PRELUDE + rf"""
KERNEL(quant_x, 256)(i8* __restrict__ q, float* __restrict__ xs, float* __restrict__ xsum16, const {in_dtype}* __restrict__ x) {{
  const u32 lane = lane_id(), blk = wg_id() * 8 + (tid() >> 5);
  if (blk * {BLK} >= {K}u) return;
  float v[{C}], a = 0.0f;
  #pragma unroll
  for (int c = 0; c < {C}; c++) {{ v[c] = (float)x[blk * {BLK} + c * 32 + lane]; a = __builtin_fmaxf(a, __builtin_fabsf(v[c])); }}
  a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
  a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
  const float m = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
  const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
  #pragma unroll
  for (int c = 0; c < {C}; c++) {{
    const i32 qi = (i32)__builtin_rintf(v[c] * id);
    q[blk * {BLK} + c * 32 + lane] = (i8)qi;
    const float s = row_sum16((float)qi);
    if (lane == 15) xsum16[(blk * {C} + c) * 2] = d * s;
    if (lane == 31) xsum16[(blk * {C} + c) * 2 + 1] = d * s;
  }}
  if (lane == 31) xs[blk] = d;
}}
"""

# per-format lane dot products. one wave step covers 4 consecutive 256-element blocks: lane -> (g = lane>>3: block, j = lane&7).
# each format is split in:
#   setup:  lane constants from j
#   wloads: (name, type, address relative to blk) raw weight words of the block this lane handles
#   xloads: (name, type, address relative to X (int8 x of the block), xs (8 block scales), xsum16 (16 sums)) the x slice of the lane
#   decode: weight-only work (scales, nibble unpack, grid lookups) from r.<wload> into the Dec fields o.<field> (done once per block)
#   dot:    this lane's float contribution from o.<field> and x.<xload> (done once per token, T times for the batched gemv)
# so the skeleton can issue the loads of the next step before computing the current one, and reuse the decoded weights across tokens.
# formats with 32-element ggml blocks treat 8 consecutive ggml blocks as one 256-element block.
FORMATS: dict[int, dict] = {}
def _fmt(ggml_type:int, name:str, block_bytes:int, setup:str, wloads:list[tuple[str, str, str]], xloads:list[tuple[str, str, str]],
         dec:str, decode:str, dot:str, grid:str|None=None, grid_words:int=0):
  FORMATS[ggml_type] = dict(name=name, bb=block_bytes, setup=setup, wloads=wloads, xloads=xloads, dec=dec, decode=decode, dot=dot,
                            grid=grid, grid_words=grid_words)

_LD = {"u32x4": "ld_u32x4", "u32x2": "ld_u32x2", "u32": "ld_u32", "u16": "ld_u16", "u8": "ld_u8", "float": "ld_f32"}

# the common x slices: 32 consecutive elements of 32-block j (xA, xB) and its scale
_X32 = [("xA", "u32x4", "X + 32 * j"), ("xB", "u32x4", "X + 32 * j + 16"), ("xs0", "float", "xs + j")]
_XV = "const u32 xv[8] = {x.xA.x, x.xA.y, x.xA.z, x.xA.w, x.xB.x, x.xB.y, x.xB.z, x.xB.w};"
_DOT8 = _XV + r"""
  i32 acc = 0;
  #pragma unroll
  for (int i = 0; i < 8; i++) acc = dot4_ss(o.g[i], xv[i], acc);
  return o.d * x.xs0 * (float)acc;
"""
_DOT8_2 = _XV + r"""
  i32 acc0 = 0, acc1 = 0;
  #pragma unroll
  for (int i = 0; i < 4; i++) { acc0 = dot4_ss(o.g[i], xv[i], acc0); acc1 = dot4_ss(o.g[i + 4], xv[i + 4], acc1); }
  return x.xs0 * (o.d0 * (float)acc0 + o.d1 * (float)acc1);
"""
_DOT32 = "  return o.d * x.xs0 * (float)(dot16_ss(o.qA, x.xA) + dot16_ss(o.qB, x.xB));\n"

_K4SCALES = r"""
  const float dd = f16_to_f32(r.hdr.x), dmin = f16_to_f32(r.hdr.x >> 16);
  const u32 sh = (i & 1) * 16;
  const u32 y = r.hdr.y >> sh, w = r.hdr.w >> sh;
  const u32 sc0 = i < 2 ? (y & 63) : ((w & 0xF) | (((y >> 6) & 3) << 4));
  const u32 sc1 = i < 2 ? ((y >> 8) & 63) : (((w >> 8) & 0xF) | (((y >> 14) & 3) << 4));
  const u32 shj = (j & 3) * 8;
  const u32 mj = j < 4 ? ((r.hdr.z >> shj) & 63) : ((((r.hdr.w >> shj) >> 4) & 0xF) | ((((r.hdr.z >> shj) >> 6) & 3) << 4));
  o.s0 = dd * (float)sc0; o.s1 = dd * (float)sc1; o.m = dmin * (float)mj;
"""
_K4X = [("xlo", "u32x4", "X + e0"), ("xhi", "u32x4", "X + e0 + 32"), ("xs0", "float", "xs + 2 * i"), ("xs1", "float", "xs + 2 * i + 1"),
        ("xm0", "float", "xsum16 + 2 * j"), ("xm1", "float", "xsum16 + 2 * j + 1")]
_K4DOT = "  return o.s0 * x.xs0 * (float)dot16_us(o.qlo, x.xlo) + o.s1 * x.xs1 * (float)dot16_us(o.qhi, x.xhi) - o.m * (x.xm0 + x.xm1);\n"
# Q4_K (144): d f16 @0, dmin f16 @2, scales[12] @4, qs[128] @16. lane j: i=j>>1 (64-group), h=j&1 (16B half of the 32B)
# low nibbles -> elements 64i+16h+[0,16) (sub-block 2i), high nibbles -> +32 (sub-block 2i+1). mins: lane j handles sub-block j
_fmt(12, "q4k", 144, "const u32 i = j >> 1, h = j & 1, e0 = 64 * i + 16 * h;",
     [("hdr", "u32x4", "blk"), ("q", "u32x4", "blk + 16 + 32 * i + 16 * h")], _K4X, "u32x4 qlo, qhi; float s0, s1, m;",
     _K4SCALES + "  o.qlo = r.q & 0x0f0f0f0fu; o.qhi = (r.q >> 4) & 0x0f0f0f0fu;\n", _K4DOT)

# Q5_K (176): d @0, dmin @2, scales[12] @4, qh[32] @16, qs[128] @48
_fmt(13, "q5k", 176, "const u32 i = j >> 1, h = j & 1, e0 = 64 * i + 16 * h;",
     [("hdr", "u32x4", "blk"), ("q", "u32x4", "blk + 48 + 32 * i + 16 * h"), ("qh", "u32x4", "blk + 16 + 16 * h")], _K4X,
     "u32x4 qlo, qhi; float s0, s1, m;",
     _K4SCALES + r"""
  o.qlo = (r.q & 0x0f0f0f0fu) | (((r.qh >> (2 * i)) & 0x01010101u) << 4);
  o.qhi = ((r.q >> 4) & 0x0f0f0f0fu) | (((r.qh >> (2 * i + 1)) & 0x01010101u) << 4);
""", _K4DOT)

# Q6_K (210): ql[128] @0, qh[64] @128, scales[16] i8 @192, d f16 @208. lane j: n=j>>2 (128-half), t=j&3
# run A = 128n + 32*(t>>1) + 16*(t&1) + [0,16) (low nibbles), run B = A + 64 (high nibbles)
_fmt(14, "q6k", 210, "const u32 n = j >> 2, t = j & 3, t1 = t >> 1, t0 = t & 1, eA = 128 * n + 32 * t1 + 16 * t0, eB = eA + 64;",
     [("ql", "u32x4", "blk + 64 * n + 32 * t1 + 16 * t0"), ("qh", "u32x4", "blk + 128 + 32 * n + 16 * t0"), ("scb", "u32x4", "blk + 192"),
      ("dd", "u16", "blk + 208")],
     [("xA", "u32x4", "X + eA"), ("xB", "u32x4", "X + eB"), ("xsA", "float", "xs + (eA >> 5)"), ("xsB", "float", "xs + (eB >> 5)"),
      ("xmA", "float", "xsum16 + (eA >> 4)"), ("xmB", "float", "xsum16 + (eB >> 4)")],
     "u32x4 qA, qB; float sA, sB;",
     r"""
  const float d = f16_to_f32(r.dd);
  const u32 shA = 2 * t1, shB = 4 + 2 * t1;
  o.qA = (r.ql & 0x0f0f0f0fu) | (((r.qh >> shA) & 0x03030303u) << 4);
  o.qB = ((r.ql >> 4) & 0x0f0f0f0fu) | (((r.qh >> shB) & 0x03030303u) << 4);
  const u32 iA = eA >> 4, iB = eB >> 4;
  const u32 wA = iA < 4 ? r.scb.x : iA < 8 ? r.scb.y : iA < 12 ? r.scb.z : r.scb.w;
  const u32 wB = iB < 4 ? r.scb.x : iB < 8 ? r.scb.y : iB < 12 ? r.scb.z : r.scb.w;
  o.sA = d * (float)(i32)(i8)((wA >> ((iA & 3) * 8)) & 0xff); o.sB = d * (float)(i32)(i8)((wB >> ((iB & 3) * 8)) & 0xff);
""", "  return o.sA * (x.xsA * (float)dot16_us(o.qA, x.xA) - 32.0f * x.xmA) + o.sB * (x.xsB * (float)dot16_us(o.qB, x.xB) - 32.0f * x.xmB);\n")

# Q3_K (110): hmask[32] @0, qs[64] @32, scales[12] @96, d f16 @108. lane j: n=j>>2 (128-half), k=j&3 (2-bit shift index)
# lane elements: 128n + 32k + [0,32); q = ((qs[32n+l] >> 2k) & 3) - (hmask[l] bit (4n+k) ? 0 : 4)
_fmt(11, "q3k", 110, "const u32 n = j >> 2, k = j & 3, e0 = 128 * n + 32 * k;",
     [("hm0", "u32x4", "blk"), ("hm1", "u32x4", "blk + 16"), ("q0", "u32x4", "blk + 32 + 32 * n"), ("q1", "u32x4", "blk + 48 + 32 * n"),
      ("scw", "u32x2", "blk + 96"), ("tmp", "u32", "blk + 104"), ("dd", "u16", "blk + 108")],
     [("xA", "u32x4", "X + e0"), ("xB", "u32x4", "X + e0 + 16"), ("xs0", "float", "xs + (e0 >> 5)")],
     "u32x4 qA, qB; float sA, sB;",
     r"""
  const float d = f16_to_f32(r.dd);
  const u32 k1 = 0x03030303u, k2 = 0x0f0f0f0fu;
  const u32 a0 = (r.scw.x & k2) | (((r.tmp >> 0) & k1) << 4), a1 = (r.scw.y & k2) | (((r.tmp >> 2) & k1) << 4);
  const u32 a2 = ((r.scw.x >> 4) & k2) | (((r.tmp >> 4) & k1) << 4), a3 = ((r.scw.y >> 4) & k2) | (((r.tmp >> 6) & k1) << 4);
  const u32 iA = e0 >> 4, iB = iA + 1;
  const u32 wA = iA < 4 ? a0 : iA < 8 ? a1 : iA < 12 ? a2 : a3;
  o.sA = d * ((float)(i32)((wA >> ((iA & 3) * 8)) & 0xff) - 32.0f); o.sB = d * ((float)(i32)((wA >> ((iB & 3) * 8)) & 0xff) - 32.0f);
  const u32 hsh = 4 * n + k, qsh = 2 * k;
  const u32x4 hbA = (r.hm0 >> hsh) & 0x01010101u, hbB = (r.hm1 >> hsh) & 0x01010101u;
  o.qA = ((r.q0 >> qsh) & 0x03030303u) | ((hbA ^ 0x01010101u) * 0xFCu);
  o.qB = ((r.q1 >> qsh) & 0x03030303u) | ((hbB ^ 0x01010101u) * 0xFCu);
""", "  return x.xs0 * (o.sA * (float)dot16_ss(o.qA, x.xA) + o.sB * (float)dot16_ss(o.qB, x.xB));\n")

# Q2_K (84): scales[16] @0 (lo nibble scale, hi nibble min), qs[64] @16, d f16 @80, dmin f16 @82. lane j: n=j>>2, k=j&3
_fmt(10, "q2k", 84, "const u32 n = j >> 2, k = j & 3, e0 = 128 * n + 32 * k, iA = e0 >> 4, iB = iA + 1;",
     [("scb", "u32x4", "blk"), ("q0", "u32x4", "blk + 16 + 32 * n"), ("q1", "u32x4", "blk + 32 + 32 * n"), ("dd", "u32", "blk + 80")],
     [("xA", "u32x4", "X + e0"), ("xB", "u32x4", "X + e0 + 16"), ("xs0", "float", "xs + (e0 >> 5)"),
      ("xmA", "float", "xsum16 + iA"), ("xmB", "float", "xsum16 + iB")],
     "u32x4 qA, qB; float sA, sB, mA, mB;",
     r"""
  const float d = f16_to_f32(r.dd), dmin = f16_to_f32(r.dd >> 16);
  const u32 wA = iA < 4 ? r.scb.x : iA < 8 ? r.scb.y : iA < 12 ? r.scb.z : r.scb.w;
  const u32 sA = (wA >> ((iA & 3) * 8)) & 0xff, sB = (wA >> ((iB & 3) * 8)) & 0xff;
  const u32 qsh = 2 * k;
  o.qA = (r.q0 >> qsh) & 0x03030303u; o.qB = (r.q1 >> qsh) & 0x03030303u;
  o.sA = d * (float)(sA & 0xF); o.sB = d * (float)(sB & 0xF); o.mA = dmin * (float)(sA >> 4); o.mB = dmin * (float)(sB >> 4);
""", "  return x.xs0 * (o.sA * (float)dot16_us(o.qA, x.xA) + o.sB * (float)dot16_us(o.qB, x.xB)) - (o.mA * x.xmA + o.mB * x.xmB);\n")

# Q8_0 (8 x 34 = 272 per 256): per 32-block: d f16, qs[32] i8. lane j -> ggml block j
_fmt(8, "q8_0", 272, "", [("dd", "u16", "blk + 34 * j"), ("qA", "u32x4", "blk + 34 * j + 2"), ("qB", "u32x4", "blk + 34 * j + 18")], _X32,
     "u32x4 qA, qB; float d;", "  o.qA = r.qA; o.qB = r.qB; o.d = f16_to_f32(r.dd);\n", _DOT32)

_IQ4NL = "0xbfad9881u, 0xf6eaddcfu, 0x26190d01u, 0x71594535u"  # kvalues_iq4nl as 4 packed i8 words
_NIBLUT = r"""
  o.qA.x = nib_lut(r.q.x & 0x0f0f0f0fu, IQ4LUT); o.qA.y = nib_lut(r.q.y & 0x0f0f0f0fu, IQ4LUT); o.qA.z = nib_lut(r.q.z & 0x0f0f0f0fu, IQ4LUT); o.qA.w = nib_lut(r.q.w & 0x0f0f0f0fu, IQ4LUT);
  o.qB.x = nib_lut((r.q.x >> 4) & 0x0f0f0f0fu, IQ4LUT); o.qB.y = nib_lut((r.q.y >> 4) & 0x0f0f0f0fu, IQ4LUT); o.qB.z = nib_lut((r.q.z >> 4) & 0x0f0f0f0fu, IQ4LUT); o.qB.w = nib_lut((r.q.w >> 4) & 0x0f0f0f0fu, IQ4LUT);
""".replace("IQ4LUT", _IQ4NL)

# IQ4_NL (8 x 18 = 144 per 256): per 32-block: d f16, qs[16]; element l: lut[qs[l]&0xF], l+16: lut[qs[l]>>4]
_fmt(20, "iq4nl", 144, "", [("dd", "u16", "blk + 18 * j"), ("q", "u32x4", "blk + 18 * j + 2")], _X32, "u32x4 qA, qB; float d;",
     _NIBLUT + "  o.d = f16_to_f32(r.dd);\n", _DOT32)

# IQ4_XS (136): d f16 @0, scales_h u16 @2, scales_l[4] @4, qs[128] @8. lane j = 32-block: qs[16j..], low nibbles -> 32j+[0,16), high -> +16
_fmt(23, "iq4xs", 136, "", [("hdr", "u32x2", "blk"), ("q", "u32x4", "blk + 8 + 16 * j")], _X32, "u32x4 qA, qB; float d;",
     _NIBLUT + r"""
  const u32 ls = ((r.hdr.y >> (4 * j)) & 0xF) | ((((r.hdr.x >> 16) >> (2 * j)) & 3) << 4);
  o.d = f16_to_f32(r.hdr.x) * ((float)(i32)ls - 32.0f);
""", _DOT32)

# IQ3_XXS (98): d f16 @0, qs[64] @2 (8 grid idx per 32-block, 4 elements each), scales_and_signs u32[8] @66. grid iq3xxs_grid[256] u32
_fmt(18, "iq3xxs", 98, "", [("dd", "u16", "blk"), ("gi", "u32x2", "blk + 2 + 8 * j"), ("aux", "u32", "blk + 66 + 4 * j")], _X32,
     "u32 g[8]; float d;",
     r"""
  o.d = f16_to_f32(r.dd) * (0.5f + (float)(r.aux >> 28)) * 0.5f;
  #pragma unroll
  for (int l = 0; l < 4; l++) {
    const u32 i0 = (l < 2 ? r.gi.x : r.gi.y) >> (16 * (l & 1)), i1 = i0 >> 8;
    const u32 s = ksigns(r.aux >> (7 * l));
    o.g[2 * l] = grid[((i0 & 0xff) << 4) | (s & 0xF)]; o.g[2 * l + 1] = grid[((i1 & 0xff) << 4) | (s >> 4)];
  }
""", _DOT8, grid="iq3xxs_grid_signed", grid_words=256 * 16)

# IQ3_S (110): d f16 @0, qs[64] @2, qh[8] @66, signs[32] @74, scales[4] @106. grid iq3s_grid[512] u32. lane j = 32-block
_fmt(21, "iq3s", 110, "",
     [("dd", "u16", "blk"), ("gi", "u32x2", "blk + 2 + 8 * j"), ("qh", "u8", "blk + 66 + j"), ("sg", "u32", "blk + 74 + 4 * j"), ("scb", "u8", "blk + 106 + (j >> 1)")],
     _X32, "u32 g[8]; float d;",
     r"""
  const u32 ls = (r.scb >> (4 * (j & 1))) & 0xF;
  o.d = f16_to_f32(r.dd) * (1.0f + 2.0f * (float)ls);
  #pragma unroll
  for (int l = 0; l < 4; l++) {
    const u32 i0 = ((l < 2 ? r.gi.x : r.gi.y) >> (16 * (l & 1))) & 0xff, i1 = ((l < 2 ? r.gi.x : r.gi.y) >> (16 * (l & 1) + 8)) & 0xff;
    const u32 s = r.sg >> (8 * l);
    o.g[2 * l] = grid[((i0 | (((r.qh >> (2 * l)) & 1) << 8)) << 4) | (s & 0xF)];
    o.g[2 * l + 1] = grid[((i1 | (((r.qh >> (2 * l + 1)) & 1) << 8)) << 4) | ((s >> 4) & 0xF)];
  }
""", _DOT8, grid="iq3s_grid_signed", grid_words=512 * 16)

# IQ2_S (82): d @0, qs[32] @2, signs[32] @34, qh[8] @66, scales[8] @74. grid iq2s_grid[1024] u64 (8 elements per entry). lane j = 32-block
_fmt(22, "iq2s", 82, "",
     [("dd", "u16", "blk"), ("qs", "u32", "blk + 2 + 4 * j"), ("sg", "u32", "blk + 34 + 4 * j"), ("qh", "u8", "blk + 66 + j"), ("sc", "u8", "blk + 74 + j")],
     _X32, "u32 g[8]; float d0, d1;",
     r"""
  const float d = f16_to_f32(r.dd);
  o.d0 = d * (0.5f + (float)(r.sc & 0xF)) * 0.25f; o.d1 = d * (0.5f + (float)(r.sc >> 4)) * 0.25f;
  #pragma unroll
  for (int l = 0; l < 4; l++) {
    const u32 gidx = ((r.qs >> (8 * l)) & 0xff) | (((r.qh >> (2 * l)) & 3) << 8);
    const u32 s = r.sg >> (8 * l);
    o.g[2 * l] = apply_signs(grid[2 * gidx], sign_m(s)); o.g[2 * l + 1] = apply_signs(grid[2 * gidx + 1], sign_m(s >> 4));
  }
""", _DOT8_2, grid="iq2s_grid", grid_words=2048)

# IQ2_XS (74): d @0, qs u16[32] @2, scales[8] @66. grid iq2xs_grid[512] u64. lane j = 32-block: 4 u16: idx = q&511, signs = ksigns[q>>9]
_fmt(17, "iq2xs", 74, "", [("dd", "u16", "blk"), ("qq", "u32x2", "blk + 2 + 8 * j"), ("sc", "u8", "blk + 66 + j")], _X32, "u32 g[8]; float d0, d1;",
     r"""
  const float d = f16_to_f32(r.dd);
  o.d0 = d * (0.5f + (float)(r.sc & 0xF)) * 0.25f; o.d1 = d * (0.5f + (float)(r.sc >> 4)) * 0.25f;
  #pragma unroll
  for (int l = 0; l < 4; l++) {
    const u32 q16 = ((l < 2 ? r.qq.x : r.qq.y) >> (16 * (l & 1))) & 0xffff;
    const u32 gidx = q16 & 511;
    const u32 s = ksigns(q16 >> 9);
    o.g[2 * l] = apply_signs(grid[2 * gidx], sign_m(s)); o.g[2 * l + 1] = apply_signs(grid[2 * gidx + 1], sign_m(s >> 4));
  }
""", _DOT8_2, grid="iq2xs_grid", grid_words=1024)

# IQ2_XXS (66): d @0, qs u16[32] @2 -> per 32-block 2 u32: aux0 = 4 grid idx bytes, aux1 = 4 x 7-bit sign idx | scale<<28. grid iq2xxs_grid[256] u64
_fmt(16, "iq2xxs", 66, "", [("dd", "u16", "blk"), ("aux", "u32x2", "blk + 2 + 8 * j")], _X32, "u32 g[8]; float d;",
     r"""
  o.d = f16_to_f32(r.dd) * (0.5f + (float)(r.aux.y >> 28)) * 0.25f;
  #pragma unroll
  for (int l = 0; l < 4; l++) {
    const u32 gidx = (r.aux.x >> (8 * l)) & 0xff;
    const u32 s = ksigns(r.aux.y >> (7 * l));
    o.g[2 * l] = grid[(gidx << 5) | (s & 0xF)]; o.g[2 * l + 1] = grid[(gidx << 5) | 16 | (s >> 4)];
  }
""", _DOT8, grid="iq2xxs_grid_signed", grid_words=512 * 16)

# native F32 (1024B per 256) / F16 (512B per 256) weights: lane j takes its 32-block, x is rebuilt from the int8 quantization
_F_DOT = r"""
  const u32 xb[8] = {x.xA.x, x.xA.y, x.xA.z, x.xA.w, x.xB.x, x.xB.y, x.xB.z, x.xB.w};
  float acc = 0.0f;
  #pragma unroll
  for (int i = 0; i < 8; i++) {
    const u32 x4 = xb[i];
    acc += o.w[4 * i] * (float)(i32)(i8)(x4 & 0xff) + o.w[4 * i + 1] * (float)(i32)(i8)((x4 >> 8) & 0xff)
         + o.w[4 * i + 2] * (float)(i32)(i8)((x4 >> 16) & 0xff) + o.w[4 * i + 3] * (float)(i32)(i8)(x4 >> 24);
  }
  return acc * x.xs0;
"""
_fmt(0, "f32", 1024, "", [(f"w{i}", "u32x4", f"blk + 128 * j + {16 * i}") for i in range(8)], _X32, "float w[32];",
     "  const u32x4 wv[8] = {r.w0, r.w1, r.w2, r.w3, r.w4, r.w5, r.w6, r.w7};\n"
     "  #pragma unroll\n  for (int i = 0; i < 8; i++) { o.w[4 * i] = __builtin_bit_cast(float, (u32)(wv[i].x)); o.w[4 * i + 1] = __builtin_bit_cast(float, (u32)(wv[i].y));"
     " o.w[4 * i + 2] = __builtin_bit_cast(float, (u32)(wv[i].z)); o.w[4 * i + 3] = __builtin_bit_cast(float, (u32)(wv[i].w)); }\n", _F_DOT)
_fmt(1, "f16", 512, "", [(f"w{i}", "u32x4", f"blk + 64 * j + {16 * i}") for i in range(4)], _X32, "float w[32];",
     "  const u32x4 wv[4] = {r.w0, r.w1, r.w2, r.w3};\n"
     "  #pragma unroll\n  for (int i = 0; i < 16; i++) { const u32 v = (u32)(wv[i >> 2][i & 3]); o.w[2 * i] = f16_to_f32(v); o.w[2 * i + 1] = f16_to_f32(v >> 16); }\n", _F_DOT)

def _rel(addr:str) -> tuple[str, str]:
  """split an address expression into (base name, offset expression) for uniform-base + 32-bit lane offset addressing"""
  m = re.match(r"^(blk|X|xs|xsum16)\s*(?:\+\s*(.*))?$", addr.strip())
  assert m, addr
  return m.group(1), m.group(2) or "0"

def _fmt_code(f:dict, sfx:str="") -> str:
  """structs RawW (weight words), RawX (x slice), Dec (decoded weights) + load_w/load_x/decode/dot for a format.
  loads use a wave-uniform base pointer plus a 32-bit per-lane offset"""
  bases = {"blk": ("wb", "boff"), "X": ("X", "xoff"), "xs": ("xs", "xsoff"), "xsum16": ("xsum16", "xmoff")}
  def loads(lst, var):
    out = []
    for n, t, a in lst:
      base, off = _rel(a)
      bp, bo = bases[base]
      # float arrays are addressed in bytes from the uniform base so the lane offset stays a 32-bit VGPR (saddr addressing)
      if t == "float": out.append(f"  {var}.{n} = ld_f32((const u8*){bp} + (u64)(({bo} + ({off})) * 4u));")
      else: out.append(f"  {var}.{n} = {_LD[t]}({bp} + (u64)({bo} + ({off})));")
    return "\n".join(out)
  wfields = "\n".join(f"  {t} {n};" for n, t, _ in f["wloads"])
  xfields = "\n".join(f"  {t} {n};" for n, t, _ in f["xloads"])
  garg = ", const u32* grid" if f["grid"] else ""
  return rf"""
struct RawW{sfx} {{
{wfields}
}};
struct RawX{sfx} {{
{xfields}
}};
struct Dec{sfx} {{ {f["dec"]} }};
DEV RawW{sfx} fmt_load_w{sfx}(const u8* __restrict__ wb, u32 boff, u32 j) {{
  {f["setup"]}
  RawW{sfx} r;
{loads(f["wloads"], "r")}
  return r;
}}
DEV RawX{sfx} fmt_load_x{sfx}(const u8* __restrict__ X, u32 xoff, const float* __restrict__ xs, u32 xsoff, const float* __restrict__ xsum16, u32 xmoff, u32 j) {{
  {f["setup"]}
  RawX{sfx} x;
{loads(f["xloads"], "x")}
  return x;
}}
DEV Dec{sfx} fmt_decode{sfx}(const RawW{sfx}& r, u32 j{garg}) {{
  {f["setup"]}
  Dec{sfx} o;
{f["decode"]}
  return o;
}}
DEV float fmt_dot{sfx}(const Dec{sfx}& o, const RawX{sfx}& x, u32 j) {{
  {f["setup"]}
{f["dot"]}
}}
"""

def _seg_body(f:dict, N:int, K:int, R:int, U:int, WG:int, n_wg:int, sfx:str, residual:bool, T:int=1, XP:bool|None=None) -> str:
  """the row loop of one gemv segment: rows [0, N) of weights w x T tokens -> y[T][N], for workgroups wg in [0, n_wg) (grid-stride over
  row groups). XP: prefetch the x slices one step ahead together with the weights (register cost grows with T)"""
  NB, BB = K // 256, f["bb"]
  assert K % 1024 == 0, f"K={K} must be a multiple of 1024"
  NSTEPS, WAVES = NB // 4, WG // 32
  if XP is None: XP = T <= 2
  gcall = ", grid" if f["grid"] else ""
  xload = lambda b: f"fmt_load_x{sfx}((const u8*)xq + (u64)t * {K}u, ({b}) * 256, xs + t * {K // 32}u, ({b}) * 8, xsum16 + t * {K // 16}u, ({b}) * 16, j)"
  return rf"""
  {{
  const u32 lane = lane_id();
  const u32 wave = __builtin_amdgcn_readfirstlane(tid() >> 5);
  const u32 g = lane >> 3, j = lane & 7;
  for (u32 row0 = (wg * {WAVES} + wave) * {R}; row0 < {N}u; row0 += {n_wg} * {WAVES} * {R}) {{
  float acc[{R}][{T}];
  #pragma unroll
  for (int r = 0; r < {R}; r++)
    #pragma unroll
    for (int t = 0; t < {T}; t++) acc[r][t] = 0.0f;
  // rows past N (when N % R != 0) re-read the last row instead of running off the buffer
  const u8* wrow[{R}];
  #pragma unroll
  for (int r = 0; r < {R}; r++) wrow[r] = w + (u64)(row0 + r < {N}u ? row0 + r : {N - 1}u) * ({NB} * {BB});
  RawW{sfx} cur[{R}];
  RawX{sfx} xcur[{T}];
  #pragma unroll
  for (int r = 0; r < {R}; r++) cur[r] = fmt_load_w{sfx}(wrow[r], g * {BB}, j);
  {"" if not XP else f"#pragma unroll{chr(10)}  for (u32 t = 0; t < {T}; t++) xcur[t] = {xload('g')};"}
  #pragma unroll {U}
  for (u32 s = 0; s < {NSTEPS}; s++) {{
    RawW{sfx} nxt[{R}];
    RawX{sfx} xnxt[{T}];
    if (s + 1 < {NSTEPS}) {{
      const u32 b = 4 * (s + 1) + g;
      #pragma unroll
      for (int r = 0; r < {R}; r++) nxt[r] = fmt_load_w{sfx}(wrow[r], b * {BB}, j);
      {"" if not XP else f"#pragma unroll{chr(10)}      for (u32 t = 0; t < {T}; t++) xnxt[t] = {xload('b')};"}
    }}
    {"" if XP else f"{{ const u32 b = 4 * s + g;{chr(10)}    #pragma unroll{chr(10)}    for (u32 t = 0; t < {T}; t++) xcur[t] = {xload('b')}; }}"}
    Dec{sfx} o[{R}];
    #pragma unroll
    for (int r = 0; r < {R}; r++) o[r] = fmt_decode{sfx}(cur[r], j{gcall});
    #pragma unroll
    for (u32 t = 0; t < {T}; t++) {{
      #pragma unroll
      for (int r = 0; r < {R}; r++) acc[r][t] += fmt_dot{sfx}(o[r], xcur[t], j);
    }}
    #pragma unroll
    for (int r = 0; r < {R}; r++) cur[r] = nxt[r];
    {"" if not XP else f"#pragma unroll{chr(10)}    for (int t = 0; t < {T}; t++) xcur[t] = xnxt[t];"}
  }}
  #pragma unroll
  for (int r = 0; r < {R}; r++)
    #pragma unroll
    for (int t = 0; t < {T}; t++) {{
      const float s = wave_sum(acc[r][t]);
      if (lane == 0 && row0 + r < {N}u) y[t * {N}u + row0 + r] = s{" + res[t * " + str(N) + "u + row0 + r]" if residual else ""};
    }}
  }}
  }}
"""

def _grid_load(words:int, WG:int) -> str:
  return rf"""
  for (u32 t = tid(); t < {words}u; t += {WG}u) grid[t] = grid_g[t];
  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
"""

def _gemv_src(ggml_type:int, N:int, K:int, R:int, U:int, WG:int, n_wg:int, residual:bool=False, T:int=1, XP:bool|None=None) -> str:
  f = FORMATS[ggml_type]
  grid_arg = ", const u32* __restrict__ grid_g" if f["grid"] else ""
  grid_setup = (f"  __attribute__((shared)) u32 grid[{f['grid_words']}];" + _grid_load(f["grid_words"], WG)) if f["grid"] else ""
  return PRELUDE + _fmt_code(f) + rf"""
KERNEL(gemv, {WG})(float* __restrict__ y, const u8* __restrict__ w, const i8* __restrict__ xq, const float* __restrict__ xs,
                   const float* __restrict__ xsum16{grid_arg}{", const float* __restrict__ res" if residual else ""}) {{
{grid_setup}
  const u32 wg = wg_id();
{_seg_body(f, N, K, R, U, WG, n_wg, "", residual, T, XP)}
}}
"""

def _gemv_multi_src(segs:list[tuple[int, int]], K:int, WG:int, cfgs:list[tuple[int, int, int]], T:int=1, XP:bool|None=None) -> str:
  """several gemvs sharing x in one launch. segs: [(ggml_type, N)], cfgs: [(R, U, n_wg)] per segment. workgroup ranges are contiguous"""
  fmts = sorted({t for t, _ in segs})
  code = "".join(_fmt_code(FORMATS[t], f"_{FORMATS[t]['name']}") for t in fmts)
  grid_words = max((FORMATS[t]["grid_words"] for t in fmts), default=0)
  args = ", ".join(f"float* __restrict__ y{i}, const u8* __restrict__ w{i}" for i in range(len(segs)))
  gargs = "".join(f", const u32* __restrict__ grid{i}" for i, (t, _) in enumerate(segs) if FORMATS[t]["grid"])
  body, start = "", 0
  for i, ((t, N), (R, U, n_wg)) in enumerate(zip(segs, cfgs)):
    f = FORMATS[t]
    gl = _grid_load(f["grid_words"], WG).replace("grid_g", f"grid{i}") if f["grid"] else ""
    seg = _seg_body(f, N, K, R, U, WG, n_wg, f"_{f['name']}", False, T, XP).replace("wrow[r] = w +", f"wrow[r] = w{i} +").replace(" y[t * ", f" y{i}[t * ")
    body += f"  {'if' if i == 0 else 'else if'} (wg_all < {start + n_wg}u) {{ const u32 wg = wg_all - {start}u;{gl}{seg} }}\n"
    start += n_wg
  return PRELUDE + code + rf"""
KERNEL(gemv_multi, {WG})({args}, const i8* __restrict__ xq, const float* __restrict__ xs, const float* __restrict__ xsum16{gargs}) {{
  {f"__attribute__((shared)) u32 grid[{grid_words}];" if grid_words else ""}
  const u32 wg_all = wg_id();
{body}
}}
"""

# ---------------------------------------------------------------------------------------------------------------------------------------
# python side

def _signed_word(w:int, nib:int) -> int:
  """the 4 magnitude bytes of w negated where the corresponding bit of nib is set, as packed int8"""
  out = 0
  for b in range(4):
    v = (w >> (8 * b)) & 0xff
    if nib >> b & 1: v = (-v) & 0xff
    out |= v << (8 * b)
  return out

@functools.cache
def _grid_tensor(name:str, device:str) -> Tensor:
  from tinygrad.runtime.autogen import ggml_common as g
  base = name.removesuffix("_signed")
  words = getattr(g, base)
  if base in ("iq2xxs_grid", "iq2xs_grid", "iq2s_grid"): words = [v for w in words for v in (w & 0xffffffff, w >> 32)]  # u64 -> 2 u32 (LE)
  # *_signed: entry [word][nib] = word with the signs of nib applied, so the kernel does one lookup per 4 elements with no sign math
  flat = [_signed_word(w, nib) for w in words for nib in range(16)] if name.endswith("_signed") else list(words)
  return Tensor(flat, dtype=dtypes.uint32, device=device).realize()

MAX_T = getenv("MAX_T", 8)  # tokens per batched gemv launch (weights stream once per T tokens)
PREFILL_T = getenv("PREFILL_T", 256)  # prefill chunk: T > MAX_T tokens go through the dequant + tensor-core GEMM (amd_prefill)
def fused_T(T:int) -> bool:
  """token counts the fused kernels take: the decode gemv batch or a prefill chunk (multiple of 64 up to PREFILL_T)"""
  return T <= MAX_T or (T % 64 == 0 and T <= PREFILL_T)

def xblk(T:int) -> int:
  """activation quantization block: 32 for the decode gemv (T <= MAX_T), 128 for the prefill GEMM"""
  return 32 if T <= MAX_T else 128

def quantize_x(x:Tensor, BLK:int=32) -> tuple[Tensor, Tensor, Tensor]:
  """float x[T, K] -> (int8 q[T*K], f32 scale[T*K/BLK], f32 sum16[T*K/16]), the per-block quantization of every token row"""
  K = int(x.numel())
  assert K % BLK == 0
  x = x.reshape(K)
  if x.dtype not in (dtypes.float32, dtypes.float16): x = x.float()
  in_dtype = "float" if x.dtype == dtypes.float32 else "_Float16"
  q = Tensor.empty(K, dtype=dtypes.int8, device=x.device)
  xs = Tensor.empty(K // BLK, dtype=dtypes.float32, device=x.device)
  xsum16 = Tensor.empty(K // 16, dtype=dtypes.float32, device=x.device)
  name = f"quant_x_{K}_{in_dtype.strip('_')}" + (f"_b{BLK}" if BLK != 32 else "")
  src = _quant_src(K, in_dtype, BLK).replace("KERNEL(quant_x,", f"KERNEL({name},")
  outs = q.custom_kernel(xs, xsum16, x, fxn=_src_program(name, src, (K // BLK + 7) // 8, 256, Estimates(ops=4 * K, mem=5 * K), _arch(x.device)))
  return outs[0], outs[1], outs[2]

def gemv_config(ggml_type:int, N:int, K:int, T:int=1, WG:int=0) -> tuple[int, int, int, int]:
  """(rows per wave, unroll, workgroup size, number of workgroups)"""
  R = int(getenv("GEMV_R", 0)) or ((1 if N <= 8192 else 2) if T == 1 else int(getenv("GEMV_RT", 2)))
  big_grid = FORMATS[ggml_type]["grid_words"] >= 4096
  WG = WG or int(getenv("GEMV_WG", 0)) or (512 if big_grid else 128)
  waves = (N + R - 1) // R
  n_wg = (waves + WG // 32 - 1) // (WG // 32)
  # formats with a big LDS table run persistent workgroups (grid-stride over the rows) to amortize the table fill
  if big_grid: n_wg = min(n_wg, int(getenv("GEMV_NWG", 192)))
  return R, int(getenv("GEMV_U", 2)), WG, n_wg

def _xp(T:int) -> bool|None:
  v = getenv("GEMV_XP", -1)
  return None if v < 0 else bool(v)

def gemv(w:Tensor, ggml_type:int, N:int, K:int, xq:Tensor, xs:Tensor, xsum16:Tensor, residual:Tensor|None=None, T:int=1) -> Tensor:
  """y[T, N] = x[T, K] @ W[N,K]^T (+ residual[T, N]) with W the raw ggml bytes of an (N,K) tensor of type ggml_type, x quantized by quantize_x"""
  f = FORMATS[ggml_type]
  R, U, WG, n_wg = gemv_config(ggml_type, N, K, T)
  XP = _xp(T)
  name = f"gemv_{f['name']}_{N}_{K}_t{T}_r{R}_u{U}_w{WG}_g{n_wg}" + ("_res" if residual is not None else "") + ("" if XP is None else f"_xp{int(XP)}")
  src = _gemv_src(ggml_type, N, K, R, U, WG, n_wg, residual is not None, T, XP).replace("KERNEL(gemv,", f"KERNEL({name},")
  y = Tensor.empty(T * N, dtype=dtypes.float32, device=w.device)
  args = [w, xq, xs, xsum16] + ([_grid_tensor(f["grid"], w.device)] if f["grid"] else []) + \
         ([residual.reshape(T * N).float()] if residual is not None else [])
  est = Estimates(ops=2 * T * N * K, mem=N * (K // 256) * f["bb"] + T * (K + N * 4))
  return y.custom_kernel(*args, fxn=_src_program(name, src, n_wg, WG, est, _arch(w.device)))[0]

def gemv_multi(ws:list[tuple[Tensor, int, int]], K:int, xq:Tensor, xs:Tensor, xsum16:Tensor, T:int=1) -> list[Tensor]:
  """one launch for several y_i = x @ W_i^T. ws: [(raw bytes, ggml_type, N)]"""
  WG = 256
  cfgs = [(R, U, n_wg) for R, U, _, n_wg in (gemv_config(t, N, K, T, WG) for _, t, N in ws)]
  segs = [(t, N) for _, t, N in ws]
  XP = _xp(T)
  name = "gemv_multi_" + "_".join(f"{FORMATS[t]['name']}{N}" for t, N in segs) + f"_{K}_t{T}_" + "_".join(f"r{R}u{U}g{g}" for R, U, g in cfgs) + \
         ("" if XP is None else f"_xp{int(XP)}")
  src = _gemv_multi_src(segs, K, WG, cfgs, T, XP).replace("KERNEL(gemv_multi,", f"KERNEL({name},")
  dev = ws[0][0].device
  ys = [Tensor.empty(T * N, dtype=dtypes.float32, device=dev) for _, _, N in ws]
  args:list[Tensor] = []
  for y, (w, _, _) in zip(ys, ws): args += [y, w]
  args += [xq, xs, xsum16] + [_grid_tensor(FORMATS[t]["grid"], dev) for _, t, _ in ws if FORMATS[t]["grid"]]
  est = Estimates(ops=sum(2 * T * N * K for _, _, N in ws), mem=sum(N * (K // 256) * FORMATS[t]["bb"] for _, t, N in ws) + T * K)
  outs = args[0].custom_kernel(*args[1:], fxn=_src_program(name, src, sum(c[2] for c in cfgs), WG, est, _arch(dev)))
  return [outs[2 * i] for i in range(len(ws))]

def _tokens(x:Tensor, K:int) -> int:
  """number of K-vectors in x (0 when x is not a batch of K-vectors the fused kernels take, see fused_T)"""
  n = x.numel()
  if x.shape[-1] != K or not isinstance(n, int) or n % K != 0 or not fused_T(n // K): return 0
  return n // K

def linear_decode_multi(lins:list[nn.Linear], x:Tensor) -> list[Tensor]:
  """several Linears on the same (<= MAX_T tokens) input in one launch"""
  gws:list[GGMLWeight] = [lin._ggml for lin in lins]  # type: ignore[attr-defined]
  K = gws[0].K
  T = _tokens(x, K)
  xq, xs, xsum16 = quantize_x_cached(x.reshape(T, K), xblk(T))
  if T > MAX_T:
    from tinygrad.llm.amd_prefill import gemm
    ys = [gemm(gw.raw, gw.ggml_type, gw.N, K, xq, xs, T) for gw in gws]
  else: ys = gemv_multi([(gw.raw, gw.ggml_type, gw.N) for gw in gws], K, xq, xs, xsum16, T)
  dt = x.dtype if dtypes.is_float(x.dtype) else dtypes.float32
  return [y.cast(dt).reshape(*x.shape[:-1], gw.N) for y, gw in zip(ys, gws)]

def supported(ggml_type:int, K:int) -> bool: return ggml_type in FORMATS and K % 1024 == 0

# ---------------------------------------------------------------------------------------------------------------------------------------
# model integration: Linear layers whose weight came from a GGUF tensor get the raw bytes attached (see Transformer.from_gguf)

class GGMLWeight:
  """raw ggml bytes of an (N, K) weight plus its type"""
  def __init__(self, raw:Tensor, ggml_type:int, N:int, K:int): self.raw, self.ggml_type, self.N, self.K = raw, ggml_type, N, K
  def realize(self): self.raw.realize(); return self

_xq_cache: dict[UOp, tuple[Tensor, Tensor, Tensor]] = {}
def _xq_key(x:Tensor) -> UOp: return x.uop.base  # views (reshape/cast-free) of the same activation share the quantization
def quantize_x_cached(x:Tensor, BLK:int=32) -> tuple[Tensor, Tensor, Tensor]:
  if (r:=_xq_cache.get(k:=_xq_key(x))) is None:
    if len(_xq_cache) >= 16: _xq_cache.clear()
    _xq_cache[k] = r = quantize_x(x, BLK)
  assert r[1].numel() * BLK == x.numel(), "cached activation quantization has a different block size"
  return r
def cache_quant(x:Tensor, q:Tensor, xs:Tensor, xsum16:Tensor):
  if len(_xq_cache) >= 16: _xq_cache.clear()
  _xq_cache[_xq_key(x)] = (q, xs, xsum16)

_orig_linear_call = nn.Linear.__call__
def _linear_call(self:nn.Linear, x:Tensor) -> Tensor:
  gw:GGMLWeight|None = getattr(self, "_ggml", None)
  if gw is not None and _tokens(x, gw.K): return linear_decode(self, x)
  return _orig_linear_call(self, x)

def linear_decode(lin:nn.Linear, x:Tensor, residual:Tensor|None=None) -> Tensor:
  """Linear on <= MAX_T tokens through the packed-weight gemv, optionally fusing `+ residual` into the epilogue"""
  gw:GGMLWeight = lin._ggml  # type: ignore[attr-defined]
  T = _tokens(x, gw.K)
  xq, xs, xsum16 = quantize_x_cached(x.reshape(T, gw.K), xblk(T))
  if T > MAX_T:
    from tinygrad.llm.amd_prefill import gemm
    y = gemm(gw.raw, gw.ggml_type, gw.N, gw.K, xq, xs, T, residual)
  else: y = gemv(gw.raw, gw.ggml_type, gw.N, gw.K, xq, xs, xsum16, residual, T)
  y = y.cast(x.dtype if dtypes.is_float(x.dtype) else dtypes.float32)
  if lin.bias is not None: y = y.reshape(T, gw.N) + lin.bias
  return y.reshape(*x.shape[:-1], gw.N)

def _gather_src(T:int, RB:int) -> str:
  return PRELUDE + rf"""
KERNEL(gather_rows, 256)(u8* __restrict__ out, const u8* __restrict__ raw, const i32* __restrict__ idx) {{
  const u32 t = wg_id();
  const u64 src = (u64)idx[t] * {RB}u;
  for (u32 o = tid() * 4; o < {RB}u; o += 1024) {{ u32 v; __builtin_memcpy(&v, raw + src + o, 4); __builtin_memcpy(out + (u64)t * {RB}u + o, &v, 4); }}
}}
"""

def gather_rows(raw:Tensor, idx:Tensor, row_bytes:int) -> Tensor:
  """out[t] = raw[idx[t]*row_bytes : (idx[t]+1)*row_bytes] for the T indices in idx (int32)"""
  T = int(idx.numel())
  assert row_bytes % 4 == 0
  idx = idx.reshape(T).cast(dtypes.int32)
  out = Tensor.empty(T, row_bytes, dtype=dtypes.uint8, device=raw.device)
  name = f"gather_rows_{T}_{row_bytes}"
  src = _gather_src(T, row_bytes).replace("KERNEL(gather_rows,", f"KERNEL({name},")
  return out.custom_kernel(raw, idx, fxn=_src_program(name, src, T, 256, Estimates(ops=0, mem=2 * T * row_bytes), _arch(raw.device)))[0]

_orig_embedding_call = nn.Embedding.__call__
def _embedding_call(self:nn.Embedding, idx:Tensor) -> Tensor:
  gw:GGMLWeight|None = getattr(self, "_ggml", None)
  if gw is not None and isinstance(idx.shape[-1], int):
    from tinygrad.llm.gguf import ggml_data_to_tensor, _GGML_QUANT
    T = int(idx.numel())
    bb = _GGML_QUANT[gw.ggml_type]
    row_bytes = gw.K // bb[0] * bb[1]
    rows = gather_rows(gw.raw, idx, row_bytes)
    return ggml_data_to_tensor(rows.reshape(-1), T * gw.K, gw.ggml_type).reshape(*idx.shape, gw.K).cast(self.weight.dtype)
  return _orig_embedding_call(self, idx)

def attach(model) -> list[GGMLWeight]:
  """attach raw ggml weights (GGMLWeight set by the gguf loader under the tensor name) to the Linear/Embedding modules of model"""
  raws:dict[str, GGMLWeight] = getattr(model, "_ggml_raw", {})
  attached:list[GGMLWeight] = []
  norms:list[nn.RMSNorm] = []
  def walk(obj, prefix):
    if isinstance(obj, nn.RMSNorm) and obj.weight is not None:
      obj._w32 = obj.weight.float().contiguous(); norms.append(obj)  # type: ignore[union-attr]
    if isinstance(obj, (nn.Linear, nn.Embedding)):
      if (gw:=raws.get(prefix + ".weight")) is not None and tuple(obj.weight.shape) == (gw.N, gw.K) and \
         gw.ggml_type in FORMATS and (gw.K % 1024 == 0 or isinstance(obj, nn.Embedding)):
        obj._ggml = gw; attached.append(gw)  # type: ignore[union-attr]
    elif isinstance(obj, (list, tuple)):
      for i, o in enumerate(obj): walk(o, f"{prefix}.{i}")
    elif isinstance(obj, dict):
      for k, o in obj.items(): walk(o, f"{prefix}.{k}")
    elif hasattr(obj, "__dict__"):
      for k, o in obj.__dict__.items():
        if not k.startswith("_"): walk(o, f"{prefix}.{k}" if prefix else k)
  walk(model, "")
  Tensor.realize(*[n._w32 for n in norms])  # type: ignore[attr-defined]
  # warm the caches that need the device (arch, grid tables) outside of any function capture
  for gw in attached:
    _arch(gw.raw.device)
    if (grid:=FORMATS[gw.ggml_type].get("grid")) is not None: _grid_tensor(grid, gw.raw.device)
  return attached


# ---------------------------------------------------------------------------------------------------------------------------------------
# fused Gated DeltaNet decode step (T=1), see GatedDeltaNetBlock._attention for the reference math

_sp_cache: dict = {}
_fwd_id = 0
_n_keep: int|UOp|Tensor|None = None
def _sp_elem_key(x:int|UOp|Tensor) -> int|bytes:
  if isinstance(x, int): return x
  if isinstance(x, Tensor): return id(x)
  return x.key
def new_forward(n_keep:int|UOp|Tensor|None=None):
  """call at the start of every model forward (and again before the MTP pass): the [start_pos, n_tok, n_keep] tensor is shared between
  the layers of one pass only (one from an earlier pass is already realized and the JIT would capture it as a constant instead of a
  kernel reading the variables). n_keep is how many tokens of this chunk commit GDN/conv state; default n_tok. a Tensor is allowed
  (n_keep + accept for the MTP pass)."""
  global _fwd_id, _n_keep
  _fwd_id += 1
  _n_keep = n_keep
  _sp_cache.clear()
  import sys
  if (pf:=sys.modules.get("tinygrad.llm.amd_prefill")) is not None: pf.new_forward()
def end_forward():
  """drop the per-pass caches: a cached tensor whose graph spans the pass (the MTP sp tensor depends on the sampled tokens) would stay
  alive between steps and make every realize walk the whole graph"""
  _sp_cache.clear(); _xq_cache.clear()
def start_pos_tensor(start_pos:UOp|int, device:str, n_tok:UOp|int=1, n_keep:int|UOp|Tensor|None=None) -> Tensor:
  """[start_pos, n_tok, n_keep] as an int32 tensor (kernels read them from memory, no dependency on symbolic variable plumbing)"""
  if n_keep is None: n_keep = _n_keep
  if n_keep is None: n_keep = n_tok
  key = (_fwd_id, _sp_elem_key(start_pos), _sp_elem_key(n_tok), _sp_elem_key(n_keep), device)
  if (t:=_sp_cache.get(key)) is None:
    if len(_sp_cache) >= 8: _sp_cache.clear()
    sp = (Tensor.zeros(1, dtype=dtypes.int32, device=device) + start_pos).cast(dtypes.int32)
    nt = (Tensor.zeros(1, dtype=dtypes.int32, device=device) + n_tok).cast(dtypes.int32)
    nk = n_keep.reshape(1).cast(dtypes.int32) if isinstance(n_keep, Tensor) else \
         (Tensor.zeros(1, dtype=dtypes.int32, device=device) + n_keep).cast(dtypes.int32)
    _sp_cache[key] = t = sp.cat(nt, nk).contiguous()
  return t

def _gdn_conv_src(C:int, KC:int, T:int) -> str:
  # conv_state: (KC-1, C) f32 in/out, qkv: (T, C) f32 new rows, w: (C, KC) f32. conv_out: (T, C) f32 = silu(sum_i win[t+i][c] * w[c][i])
  # sp_p = [start_pos, n_tok, n_keep]: tokens t >= n_tok are padding, the new conv state is the last KC-1 rows of [state | qkv[:n_keep]]
  # one thread per channel walks the window sequentially (any T): win[m] = m < KC-1 ? state[m] : qkv[m - (KC-1)]
  return PRELUDE + rf"""
KERNEL(gdn_conv, 256)(float* __restrict__ conv_out, float* __restrict__ conv_state, const float* __restrict__ qkv,
                      const float* __restrict__ w, const i32* __restrict__ sp_p) {{
  const i32 start_pos = sp_p[0], nk = sp_p[2];
  const u32 c = wg_id() * 256 + tid();
  if (c >= {C}u) return;
  const bool reset = start_pos == 0;
  float win[{KC}];  // the last KC window values, win[KC-1] = newest
  #pragma unroll
  for (int i = 0; i < {KC} - 1; i++) win[i + 1] = reset ? 0.0f : conv_state[i * {C} + c];
  float wv[{KC}];
  #pragma unroll
  for (int i = 0; i < {KC}; i++) wv[i] = w[c * {KC} + i];
  for (i32 t = 0; t < {T}; t++) {{
    #pragma unroll
    for (int i = 0; i < {KC} - 1; i++) win[i] = win[i + 1];
    win[{KC} - 1] = qkv[t * {C} + c];
    float acc = 0.0f;
    #pragma unroll
    for (int i = 0; i < {KC}; i++) acc += win[i] * wv[i];
    conv_out[t * {C} + c] = acc / (1.0f + __builtin_expf(-acc));
    // after consuming qkv[t] the window holds [state | qkv[:t+1]][t+1 .. t+KC): the new state once t + 1 == nk
    if (t + 1 == nk) {{
      #pragma unroll
      for (int i = 0; i < {KC} - 1; i++) conv_state[i * {C} + c] = win[i + 1];
    }}
  }}
  if (nk == 0) {{  // nothing committed: the state is the old window (zeros after a reset)
    #pragma unroll
    for (int i = 0; i < {KC} - 1; i++) conv_state[i * {C} + c] = reset ? 0.0f : conv_state[i * {C} + c];
  }}
}}
"""

def _gdn_step_src(H:int, HK:int, V:int, K:int, C:int, eps:float, qk_eps:float, T:int, BLK:int=32) -> str:
  # one workgroup (512 threads) per v-head h: 4 threads per state row (v), 32 k each. the state stays in registers over the T steps,
  # which are processed in groups of TG tokens staged in LDS. z is quantized per BLK (32: one wave per 32-block, 128: one wave per
  # token: the head's V=128 outputs are one block)
  assert V == 128 and K == 128 and BLK in (32, 128)
  TG = min(T, 16); NG = T // TG
  assert T % TG == 0
  QD = HK * K  # q/k width in conv_out
  BAR = '__builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");'
  quant32 = rf"""
  for (u32 i = t; i < {TG} * {V}; i += 512) {{  // each wave handles one 32-block of one token: gated norm + quantization
    const u32 tt = i / {V}, vv = i % {V}, tok = g0 + tt, e = tok * {H * V} + h * {V} + vv;
    const float g = gate[e];
    const float y = tok < n ? outs[tt][vv] * red[tt][2] * norm_w[vv] * (g / (1.0f + __builtin_expf(-g))) : 0.0f;
    z[e] = y;
    float a = __builtin_fabsf(y);
    a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
    a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
    const float m = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
    const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
    const i32 qi = (i32)__builtin_rintf(y * id);
    zq[e] = (i8)qi;
    const float sq = row_sum16((float)qi);
    if (lane == 15) zsum16[(e >> 5) * 2] = d * sq;
    if (lane == 31) {{ zsum16[(e >> 5) * 2 + 1] = d * sq; zs[e >> 5] = d; }}
  }}
"""
  quant128 = rf"""
  if (wave < {TG}) {{  // one wave per token: the head's {V} outputs are one 128-block
    const u32 tt = wave, tok = g0 + tt;
    float y[4], a = 0.0f;
    #pragma unroll
    for (int c = 0; c < 4; c++) {{
      const u32 vv = c * 32 + lane, e = tok * {H * V} + h * {V} + vv;
      const float g = gate[e];
      y[c] = tok < n ? outs[tt][vv] * red[tt][2] * norm_w[vv] * (g / (1.0f + __builtin_expf(-g))) : 0.0f;
      z[e] = y[c];
      a = __builtin_fmaxf(a, __builtin_fabsf(y[c]));
    }}
    a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
    a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
    const float m = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
    const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
    #pragma unroll
    for (int c = 0; c < 4; c++) {{
      const u32 vv = c * 32 + lane, e = tok * {H * V} + h * {V} + vv;
      const i32 qi = (i32)__builtin_rintf(y[c] * id);
      zq[e] = (i8)qi;
      const float sq = row_sum16((float)qi);
      if (lane == 15) zsum16[(e >> 5) * 2] = d * sq;
      if (lane == 31) zsum16[(e >> 5) * 2 + 1] = d * sq;
    }}
    if (lane == 31) zs[(tok * {H * V} + h * {V}) >> 7] = d;
  }}
"""
  return PRELUDE + rf"""
#define dpp_xmask(v, m) __builtin_bit_cast(float, __builtin_amdgcn_update_dpp(0, __builtin_bit_cast(i32, (v)), 0x160 | (m), 0xf, 0xf, true))
DEV float sum4(float v) {{ v += dpp_xmask(v, 1); v += dpp_xmask(v, 2); return v; }}
KERNEL(gdn_step, 512)(float* __restrict__ z, i8* __restrict__ zq, float* __restrict__ zs, float* __restrict__ zsum16,
                      float* __restrict__ state, const float* __restrict__ conv_out,
                      const float* __restrict__ alpha_raw, const float* __restrict__ beta_raw, const float* __restrict__ dt_bias,
                      const float* __restrict__ A, const float* __restrict__ gate, const float* __restrict__ norm_w, const i32* __restrict__ sp_p) {{
  __attribute__((shared)) float qs[{TG}][{K}], ks[{TG}][{K}], vs[{TG}][{V}], outs[{TG}][{V}], red[{TG}][4], dec[{TG}], bet[{TG}];
  const i32 start_pos = sp_p[0];
  const u32 n = __builtin_amdgcn_readfirstlane((u32)sp_p[1]);
  const u32 nk = __builtin_amdgcn_readfirstlane((u32)sp_p[2]);
  const u32 h = wg_id(), t = tid(), lane = lane_id(), wave = t >> 5;
  const u32 hk = h % {HK};
  // this thread: row v = t >> 2, k range [32*(t&3), +32)
  const u32 v = t >> 2, k0 = (t & 3) * 32;
  float* srow = state + ((u64)h * {V} + v) * {K} + k0;
  float s[32], kk[32];
  #pragma unroll
  for (int i = 0; i < 32; i++) s[i] = srow[i];
  if (nk == 0) {{  // nothing committed this chunk: the state is the old one (zeros after a reset)
    #pragma unroll
    for (int i = 0; i < 32; i++) srow[i] = start_pos == 0 ? 0.0f : s[i];
  }}
  for (u32 g0 = 0; g0 < {T}u; g0 += {TG}) {{
    if (g0 >= n) break;
    {BAR}
    // load q, k, v of this head for the group's tokens
    for (u32 i = t; i < {TG} * {K}; i += 512) {{
      const u32 tt = i / {K}, kk_ = i % {K}, tok = g0 + tt;
      qs[tt][kk_] = conv_out[tok * {C} + hk * {K} + kk_]; ks[tt][kk_] = conv_out[tok * {C} + {QD} + hk * {K} + kk_];
      vs[tt][kk_] = conv_out[tok * {C} + 2 * {QD} + h * {V} + kk_];
    }}
    if (t < {TG}) {{  // per-token decay and beta of this head
      const u32 tok = g0 + t;
      const float a_in = alpha_raw[tok * {H} + h] + dt_bias[h];
      const float sp = a_in > 20.0f ? a_in : __builtin_logf(1.0f + __builtin_expf(a_in));  // softplus
      dec[t] = start_pos + (i32)tok == 0 ? 0.0f : __builtin_expf(sp * A[h]);               // state reset folds into the decay
      bet[t] = 1.0f / (1.0f + __builtin_expf(-beta_raw[tok * {H} + h]));
    }}
    {BAR}
    for (u32 p = wave; p < 2 * {TG}; p += 16) {{  // |q_t| (even p) and |k_t| (odd p)
      const float* src = (p & 1) ? ks[p >> 1] : qs[p >> 1];
      float ss = 0.0f;
      #pragma unroll
      for (int i = 0; i < {K} / 32; i++) {{ const float x = src[lane * ({K} / 32) + i]; ss += x * x; }}
      ss = wave_sum(ss);
      if (lane == 0) red[p >> 1][p & 1] = __builtin_fmaxf(__builtin_sqrtf(ss), {qk_eps}f);
    }}
    {BAR}
    for (u32 tt = 0; tt < {TG}u && g0 + tt < n; tt++) {{
      const float qscale = {K**-0.5}f / red[tt][0], kscale = 1.0f / red[tt][1], decay = dec[tt], beta = bet[tt];
      float dot = 0.0f;
      #pragma unroll
      for (int i = 0; i < 32; i++) {{ kk[i] = ks[tt][k0 + i] * kscale; s[i] *= decay; dot += s[i] * kk[i]; }}
      dot = sum4(dot);
      const float delta = (vs[tt][v] - dot) * beta;
      float o = 0.0f;
      #pragma unroll
      for (int i = 0; i < 32; i++) {{ s[i] += delta * kk[i]; o += s[i] * qs[tt][k0 + i]; }}
      o = sum4(o) * qscale;
      if ((t & 3) == 0) outs[tt][v] = o;
      if (g0 + tt + 1 == nk) {{
        #pragma unroll
        for (int i = 0; i < 32; i++) srow[i] = s[i];
      }}
    }}
    {BAR}
    if (wave < {TG}) {{  // rms of the output of token `wave` of the group
      float ss = 0.0f;
      #pragma unroll
      for (int i = 0; i < {V} / 32; i++) {{ const float x = g0 + wave < n ? outs[wave][lane * ({V} / 32) + i] : 0.0f; ss += x * x; }}
      ss = wave_sum(ss);
      if (lane == 0) red[wave][2] = 1.0f / __builtin_sqrtf(ss / {V}.0f + {eps}f);
    }}
    {BAR}
    {quant32 if BLK == 32 else quant128}
  }}
}}
"""

def gdn_decode(conv_state:Tensor, rec_state:Tensor, qkv:Tensor, conv_w:Tensor, alpha_raw:Tensor, beta_raw:Tensor, dt_bias:Tensor, A:Tensor,
               gate:Tensor, norm_w:Tensor, start_pos:UOp|int, H:int, HK:int, V:int, K:int, eps:float, qk_eps:float, max_context:int,
               T:int=1, n_tok:UOp|int|None=None) -> Tensor:
  """T Gated DeltaNet token steps (tokens >= n_tok are padding). updates conv_state (KC-1, C) and rec_state (H, V, K) in place,
  returns z (T, H*V) f32 with its int8 quantization cached"""
  C, KC = int(conv_w.shape[0]), int(conv_w.shape[1])
  dev, arch = conv_state.device, _arch(conv_state.device)
  conv_out = Tensor.empty(T * C, dtype=dtypes.float32, device=dev)
  sp_t = start_pos_tensor(start_pos, dev, T if n_tok is None else n_tok)
  def conv_fxn(co, cs, q, w, sp):
    sink = UOp.sink(UOp.special((C + 255) // 256, "gidx0"), UOp.special(256, "lidx0"), co, cs, q, w, sp,
                    arg=KernelInfo(name=f"gdn_conv_{C}_{KC}_t{T}", estimates=Estimates(ops=T * C * KC * 2, mem=C * 4 * (2 * KC + T))))
    src = _gdn_conv_src(C, KC, T).replace("KERNEL(gdn_conv,", f"KERNEL(gdn_conv_{C}_{KC}_t{T},")
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=hip_to_ir(src, arch))))
  conv_out = conv_out.custom_kernel(conv_state, qkv.reshape(T * C).float(), conv_w, sp_t, fxn=conv_fxn)[0]
  z = Tensor.empty(T * H * V, dtype=dtypes.float32, device=dev)
  BLK = xblk(T)
  zq, zs, zsum16 = (Tensor.empty(n, dtype=dt, device=dev) for n, dt in ((T * H * V, dtypes.int8), (T * H * V // BLK, dtypes.float32), (T * H * V // 16, dtypes.float32)))
  name = f"gdn_step_{H}_{HK}_{V}_{K}_t{T}" + (f"_b{BLK}" if BLK != 32 else "")
  def step_fxn(zz, zzq, zzs, zzsum, st, co, ar, br, db, aa, g, nw, sp):
    sink = UOp.sink(UOp.special(H, "gidx0"), UOp.special(512, "lidx0"), zz, zzq, zzs, zzsum, st, co, ar, br, db, aa, g, nw, sp,
                    arg=KernelInfo(name=name, estimates=Estimates(ops=T * H * V * K * 6, mem=H * V * K * 8)))
    src = _gdn_step_src(H, HK, V, K, C, eps, qk_eps, T, BLK).replace("KERNEL(gdn_step,", f"KERNEL({name},")
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=hip_to_ir(src, arch))))
  outs = z.custom_kernel(zq, zs, zsum16, rec_state, conv_out, alpha_raw.reshape(T * H).float(), beta_raw.reshape(T * H).float(),
                         dt_bias, A, gate.reshape(T * H * V).float(), norm_w, sp_t, fxn=step_fxn)
  z = outs[0]
  cache_quant(z, outs[1], outs[2], outs[3])
  return z.reshape(T, H * V)

# ---------------------------------------------------------------------------------------------------------------------------------------
# fused activation producers: they return the float activation and pre-populate the int8 quantization cache keyed by its uop

def _act_quant_src(K:int, mode:str, in_dtype:str, BLK:int=32) -> str:
  # mode "rmsnorm": y = x * rsqrt(mean(x^2) + eps) * w   (one workgroup per row, K <= 1024*BLK)
  # mode "silumul": y = silu(a) * b                       (per block, independent)
  # a wave quantizes one BLK-block at a time (C = BLK/32 chunks of 32 lanes): xs per block, xsum16 per 16
  C, NBLK = BLK // 32, K // BLK
  WG = 1024 if mode == "rmsnorm" else 256
  NWAVES = WG // 32
  NPER = (NBLK + NWAVES - 1) // NWAVES  # blocks per wave (rmsnorm: the row loops over them)
  assert NBLK <= 1024 * NWAVES or mode != "rmsnorm"
  quant = r"""
    float a = 0.0f;
    #pragma unroll
    for (int c = 0; c < C; c++) a = __builtin_fmaxf(a, __builtin_fabsf(v[c]));
    a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
    a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
    const float m = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
    const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
    #pragma unroll
    for (int c = 0; c < C; c++) {
      const u32 ee = b * BLK + c * 32 + lane;
      y[ee] = v[c];
      const i32 qi = (i32)__builtin_rintf(v[c] * id);
      q[ee] = (i8)qi;
      const float sq = row_sum16((float)qi);
      if (lane == 15) xsum16[(b * C + c) * 2] = d * sq;
      if (lane == 31) xsum16[(b * C + c) * 2 + 1] = d * sq;
    }
    if (lane == 31) xs[b] = d;
"""
  body = (r"""
  __attribute__((shared)) float red[32];
  const u32 row = wg_id();
  x += (u64)row * K; y += (u64)row * K; q += (u64)row * K; xs += row * NBLK; xsum16 += row * (K / 16);
  float xv[NPER][C];
  float ss = 0.0f;
  #pragma unroll
  for (int i = 0; i < NPER; i++) {
    const u32 b = wave + i * NWAVES;
    #pragma unroll
    for (int c = 0; c < C; c++) { xv[i][c] = b < NBLK ? (float)x[b * BLK + c * 32 + lane] : 0.0f; ss += xv[i][c] * xv[i][c]; }
  }
  ss = wave_sum(ss);
  if (lane == 0) red[wave] = ss;
  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
  float tot = 0.0f;
  #pragma unroll
  for (int i = 0; i < NWAVES; i++) tot += red[i];
  const float rs = 1.0f / __builtin_sqrtf(tot / (float)K + EPS);
  #pragma unroll
  for (int i = 0; i < NPER; i++) {
    const u32 b = wave + i * NWAVES;
    if (b >= NBLK) break;
    float v[C];
    #pragma unroll
    for (int c = 0; c < C; c++) v[c] = xv[i][c] * rs * w[b * BLK + c * 32 + lane];
""" + quant + "  }\n" if mode == "rmsnorm" else r"""
  const u32 b = wg_id() * NWAVES + wave;
  if (b >= NBLK) return;
  {
    float v[C];
    #pragma unroll
    for (int c = 0; c < C; c++) { const u32 e = b * BLK + c * 32 + lane; const float g = (float)x[e]; v[c] = g / (1.0f + __builtin_expf(-g)) * (float)w[e]; }
""" + quant + "  }\n")
  return PRELUDE + rf"""
#define K {K}
#define BLK {BLK}
#define C {C}
#define NBLK {NBLK}
#define NWAVES {NWAVES}
#define NPER {NPER}
KERNEL(act_quant, {WG})(float* __restrict__ y, i8* __restrict__ q, float* __restrict__ xs, float* __restrict__ xsum16,
                        const {in_dtype}* __restrict__ x, const {"float" if mode == "rmsnorm" else in_dtype}* __restrict__ w) {{
  const u32 lane = lane_id(), wave = tid() >> 5;
  {body}
}}
"""

def _act_quant(x:Tensor, w:Tensor, mode:str, eps:float=0.0) -> Tensor:
  """x: T rows of K. rmsnorm: w[K] float, one workgroup per row. silumul: w has the shape of x, elementwise.
  the int8 quantization (block xblk(T)) of the result is cached on the returned tensor"""
  K = int(x.shape[-1])
  T = _tokens(x, K)
  assert T, f"{x.shape} is not a batch of K-vectors"
  BLK = xblk(T)
  x = x.reshape(T * K)
  if x.dtype not in (dtypes.float32, dtypes.float16): x = x.float()
  in_dtype = "float" if x.dtype == dtypes.float32 else "_Float16"
  if mode == "rmsnorm": w = w.reshape(K).float()
  else: w = w.reshape(T * K).cast(x.dtype)
  dev = x.device
  y = Tensor.empty(T * K, dtype=dtypes.float32, device=dev)
  q = Tensor.empty(T * K, dtype=dtypes.int8, device=dev)
  xs = Tensor.empty(T * K // BLK, dtype=dtypes.float32, device=dev)
  xsum16 = Tensor.empty(T * K // 16, dtype=dtypes.float32, device=dev)
  WG = 1024 if mode == "rmsnorm" else 256
  n_wg = T if mode == "rmsnorm" else (T * K // BLK + WG // 32 - 1) // (WG // 32)
  name = f"{mode}_quant_{K}_{in_dtype.strip('_')}" + (f"_t{T}" if mode != "rmsnorm" else "") + (f"_b{BLK}" if BLK != 32 else "")
  src = _act_quant_src(K if mode == "rmsnorm" else T * K, mode, in_dtype, BLK).replace("EPS", f"{eps}f").replace("KERNEL(act_quant,", f"KERNEL({name},")
  outs = y.custom_kernel(q, xs, xsum16, x, w, fxn=_src_program(name, src, n_wg, WG, Estimates(ops=8 * T * K, mem=10 * T * K), _arch(dev)))
  y, q, xs, xsum16 = outs[0], outs[1], outs[2], outs[3]
  cache_quant(y, q, xs, xsum16)
  return y

def rmsnorm_quant(x:Tensor, w:Tensor, eps:float) -> Tensor:
  """RMSNorm of (up to MAX_T) K-vectors that also produces the int8 quantization consumed by gemv (cached on the returned tensor)"""
  return _act_quant(x, w, "rmsnorm", eps).reshape(x.shape)

def silu_mul_quant(a:Tensor, b:Tensor) -> Tensor:
  """silu(a) * b for (up to MAX_T) K-vectors, also produces the int8 quantization consumed by gemv"""
  return _act_quant(a, b, "silumul").reshape(a.shape)

_orig_rmsnorm_call = nn.RMSNorm.__call__
def _rmsnorm_call(self:nn.RMSNorm, x:Tensor) -> Tensor:
  K = x.shape[-1]
  if _ARCH and self.weight is not None and isinstance(K, int) and K % 32 == 0 and K <= 32768 and _tokens(x, K) and \
     x.device.split(":")[0] == "AMD" and dtypes.is_float(x.dtype):
    w = getattr(self, "_w32", self.weight)
    return rmsnorm_quant(x, w, self.eps).cast(x.dtype) if x.dtype != dtypes.float32 else rmsnorm_quant(x, w, self.eps)
  return _orig_rmsnorm_call(self, x)

def install():
  if not getenv("AMD_GEMV", 1): return
  nn.Linear.__call__ = _linear_call  # type: ignore[method-assign]
  nn.Embedding.__call__ = _embedding_call  # type: ignore[method-assign]
  nn.RMSNorm.__call__ = _rmsnorm_call  # type: ignore[method-assign]

# ---------------------------------------------------------------------------------------------------------------------------------------
# KV cache quantization (TurboQuant style): keys/values are rotated by a fixed random orthogonal transform (random signs + Walsh-Hadamard),
# normalized and scalar-quantized per coordinate with a Lloyd-Max codebook for N(0,1) (the coordinates of a rotated unit vector are
# ~N(0,1/D)). the key residual is projected with a second transform and stored as 1 bit per coordinate (QJL), an unbiased inner product
# estimate that removes most of the remaining score error. q is rotated in-kernel, so scores are computed directly in the rotated space.

def lloyd_max(bits:int, iters:int=500) -> list[float]:
  """MSE-optimal scalar quantizer centroids for N(0,1), sorted"""
  import math
  n = 2 ** bits
  pdf = lambda x: math.exp(-x * x / 2) / math.sqrt(2 * math.pi)
  cdf = lambda x: 0.5 * (1 + math.erf(x / math.sqrt(2)))
  c = [-2.5 + 5.0 * (i + 0.5) / n for i in range(n)]
  for _ in range(iters):
    b = [-40.0] + [(c[i] + c[i + 1]) / 2 for i in range(n - 1)] + [40.0]
    c = [(pdf(b[i]) - pdf(b[i + 1])) / (cdf(b[i + 1]) - cdf(b[i])) for i in range(n)]
  return c

def kv_sign(i:int, seed:int) -> int:
  """deterministic pseudo-random sign bit for coordinate i (1 = negative), same hash as the kernel"""
  return bin(((i ^ seed) * 0x9E3779B1) & 0xffffffff).count("1") & 1
KV_SEED_ROT, KV_SEED_QJL = 0x1234567, 0x7654321

class KVQuant:
  """byte layout of the quantized cache of one kv head: planar arrays [MAXC][bytes] per plane, head region = MAXC * bytes_per_pos.
  k{2,4}: main index plane (2 or 4 bits per coordinate), k1: extra 1-bit plane (3-bit codes), kj: QJL sign bits, ks: (norm/16, qjl scale) f32"""
  def __init__(self, kbits:int, vbits:int, qjl:bool, D:int=256):
    assert kbits in (2, 3, 4) and vbits in (2, 3, 4) and D == 256
    self.kbits, self.vbits, self.qjl, self.D = kbits, vbits, qjl, D
    self.cbk, self.cbv = lloyd_max(kbits), lloyd_max(vbits)
    planes: list[tuple[str, int]] = [("kq", D // 8 * (2 if kbits == 2 else 4 if kbits == 4 else 2))]
    if kbits == 3: planes.append(("k1", D // 8))
    if qjl: planes.append(("kj", D // 8))
    planes.append(("ks", 8))
    planes.append(("vq", D // 8 * (2 if vbits == 2 else 4 if vbits == 4 else 2)))
    if vbits == 3: planes.append(("v1", D // 8))
    planes.append(("vs", 4))
    self.planes = dict(planes)
    self.bytes_per_pos = sum(self.planes.values())
    self.key = f"k{kbits}{'j' if qjl else ''}v{vbits}"
  def offsets(self, maxc:int) -> dict[str, int]:
    off, out = 0, {}
    for name, b in self.planes.items(): out[name] = off; off += maxc * b
    return out
  def cache_bytes(self, hkv:int, maxc:int) -> int: return hkv * maxc * self.bytes_per_pos

def kv_quant_spec() -> KVQuant|None:
  """KV_QUANT=0 keeps the f32 cache. KV_KBITS/KV_VBITS in {2,3,4}, KV_QJL adds the 1-bit key residual (default k4+qjl, v4: ~6.8x smaller)"""
  if not getenv("KV_QUANT", 1): return None
  return KVQuant(getenv("KV_KBITS", 4), getenv("KV_VBITS", 4), bool(getenv("KV_QJL", 1)))

# ---------------------------------------------------------------------------------------------------------------------------------------
# fused single-token attention (flash-decoding): q/k norm + rope + kv cache write + chunked softmax(q k^T) v, merged by a second kernel

# device code shared by the decode and prefill attention kernels (expects WG and BAR() defined)
ATTN_DEV = r"""
// pseudo-random sign of coordinate i (1 = negative); the python side (kv_sign) uses the same hash
DEV bool kv_sgn(u32 i, u32 seed) { return __builtin_popcount((i ^ seed) * 0x9E3779B1u) & 1u; }
// in-place (unnormalized) Walsh-Hadamard transform of nvec contiguous 256-vectors in LDS, all WG threads, barriers inside
DEV void wht_vecs(float* v, const u32 nvec, const u32 t) {
  #pragma unroll
  for (u32 h = 1; h < 256; h <<= 1) {
    BAR();
    for (u32 i = t; i < nvec * 128; i += WG) {
      const u32 a = ((i >> 7) << 8) + (((i & 127) & ~(h - 1)) << 1) + ((i & 127) & (h - 1)), b = a + h;
      const float x = v[a], y = v[b];
      v[a] = x + y; v[b] = x - y;
    }
  }
  BAR();
}
"""

# --- the quantized cache: per-lane loads of the 8 coordinates [8*lane, 8*lane+8), index extraction, new-token quantization + stores
def kv_load_idx(kvq:KVQuant, off:dict, D:int, pre:str, bits:int, plane:str, plane1:str) -> str:
  """loads the packed indices of coordinates [8*lane, +8) of position `pos` into {pre}n (and {pre}n1 for 3 bits)"""
  if bits == 4: return f"const u32 {pre}n = ld_u32(Kh + {off[plane]} + (u64)pos * {D // 2} + lane * 4);"
  r = f"const u32 {pre}n = ld_u16(Kh + {off[plane]} + (u64)pos * {D // 4} + lane * 2);"
  if bits == 3: r += f" const u32 {pre}n1 = ld_u8(Kh + {off[plane1]} + (u64)pos * {D // 8} + lane);"
  return r
def kv_idx_of(pre:str, bits:int, i:int) -> str:
  if bits == 4: return f"(({pre}n >> {4 * i}) & 15u)"
  if bits == 2: return f"(({pre}n >> {2 * i}) & 3u)"
  return f"((({pre}n >> {2 * i}) & 3u) | ((({pre}n1 >> {i}) & 1u) << 2))"
def kv_store_idx(off:dict, D:int, bits:int, plane:str, plane1:str) -> str:
  """stores idx_s[D] (LDS) as the packed planes of position start_pos; thread t"""
  if bits == 4: return f"if (t < {D // 2}) Kh[{off[plane]} + (u64)start_pos * {D // 2} + t] = (u8)(idx_s[2 * t] | (idx_s[2 * t + 1] << 4));"
  r = f"if (t < {D // 4}) Kh[{off[plane]} + (u64)start_pos * {D // 4} + t] = (u8)((idx_s[4 * t] & 3u) | ((idx_s[4 * t + 1] & 3u) << 2) | ((idx_s[4 * t + 2] & 3u) << 4) | ((idx_s[4 * t + 3] & 3u) << 6));"
  if bits == 3:
    r += f"\n    if (t < {D // 8}) {{ u32 b = 0; for (int i = 0; i < 8; i++) b |= ((idx_s[8 * t + i] >> 2) & 1u) << i; Kh[{off[plane1]} + (u64)start_pos * {D // 8} + t] = (u8)b; }}"
  return r
def kv_cb_init(kvq:KVQuant) -> str:
  """LDS codebooks cbk_s/cbv_s[16] via select chains (a const array would land in .rodata, which the ELF loader does not relocate)"""
  cbk = " ".join(f"t == {i} ? {c:.7f}f :" for i, c in enumerate(kvq.cbk)) + " 0.0f"
  cbv = " ".join(f"t == {i} ? {c:.7f}f :" for i, c in enumerate(kvq.cbv)) + " 0.0f"
  return "if (t < 16) { cbk_s[t] = " + cbk + "; cbv_s[t] = " + cbv + "; }"
def kv_rotate_code(kvq:KVQuant, D:int, G:int, NV:int) -> str:
  """rotate the NV LDS vectors (q heads, [qjl q heads], k, v) into the quantization space: signs + WHT / 16 (qjl q: signs2 + WHT)"""
  J = kvq.qjl
  return f"""// 2b. rotate q, k, v into the quantization space (signs + WHT / 16){" and project q for the QJL residual estimate (signs2 + WHT)" if J else ""}
  for (u32 i = t; i < {NV * D}; i += WG) {{
    const u32 vec = i / {D}, d = i % {D};
    {f"if (vec >= {G} && vec < {2 * G}) vecs[vec][d] = kv_sgn(d, {KV_SEED_QJL}u) ? -q_s[vec - {G}][d] : q_s[vec - {G}][d]; else" if J else ""}
    vecs[vec][d] = kv_sgn(d, {KV_SEED_ROT}u) ? -vecs[vec][d] : vecs[vec][d];
  }}
  wht_vecs(&vecs[0][0], {NV}, t);
  for (u32 i = t; i < {NV * D}; i += WG) {{ const u32 vec = i / {D}; if ({f"vec < {G} || vec >= {2 * G}" if J else "true"}) vecs[vec][i % {D}] *= 1.0f / 16.0f; }}
  BAR();"""
def kv_write_code(kvq:KVQuant, off:dict, D:int) -> str:
  """quantize the rotated knew/vnew (LDS) into the cache planes of position start_pos (needs has_new, r_s, idx_s, red2, cbk_s, cbv_s)"""
  J = kvq.qjl
  qjl_store = f"""
    // QJL: project the residual with the second transform, keep the sign bits and the residual norm
    {{ const float rr = r_s[t]; const float ssr = wave_sum(rr * rr); if (lane == 0) red2[wave] = ssr; }}
    BAR();
    const float nr = __builtin_sqrtf(red2[0] + red2[1] + red2[2] + red2[3] + red2[4] + red2[5] + red2[6] + red2[7]) / 16.0f;
    r_s[t] = kv_sgn(t, {KV_SEED_QJL}u) ? -r_s[t] : r_s[t];
    wht_vecs(r_s, 1, t);
    idx_s[t] = r_s[t] >= 0.0f ? 1u : 0u;
    BAR();
    if (t < {D // 8}) {{ u32 b = 0; for (int i = 0; i < 8; i++) b |= idx_s[8 * t + i] << i; Kh[{off['kj']} + (u64)start_pos * {D // 8} + t] = (u8)b; }}
    if (t == 0) ((float*)(Kh + {off['ks']}))[start_pos * 2 + 1] = nk * nr * {(3.141592653589793 / 2) ** 0.5 / D}f;""" if J else ""
  return f"""// 3b. quantize the rotated new k and v (per-vector norm + Lloyd-Max index per coordinate) into the cache planes
  if (has_new) {{
    float ss = knew[t] * knew[t]; ss = wave_sum(ss); if (lane == 0) red2[wave] = ss;
    BAR();
    const float nk = __builtin_sqrtf(red2[0] + red2[1] + red2[2] + red2[3] + red2[4] + red2[5] + red2[6] + red2[7]);
    const float z = knew[t] * (nk > 0.0f ? 16.0f / nk : 0.0f);
    u32 idx = 0;
    #pragma unroll
    for (int j = 1; j < {2 ** kvq.kbits}; j++) idx += z > 0.5f * (cbk_s[j] + cbk_s[j - 1]) ? 1u : 0u;
    r_s[t] = z - cbk_s[idx]; idx_s[t] = idx;
    if (t == 0) {{ ((float*)(Kh + {off['ks']}))[start_pos * 2] = nk / 16.0f; {"" if J else f"((float*)(Kh + {off['ks']}))[start_pos * 2 + 1] = 0.0f;"} }}
    BAR();
    {kv_store_idx(off, D, kvq.kbits, "kq", "k1")}{qjl_store}
    BAR();
    ss = vnew[t] * vnew[t]; ss = wave_sum(ss); if (lane == 0) red2[wave] = ss;
    BAR();
    const float nv = __builtin_sqrtf(red2[0] + red2[1] + red2[2] + red2[3] + red2[4] + red2[5] + red2[6] + red2[7]);
    const float zv = vnew[t] * (nv > 0.0f ? 16.0f / nv : 0.0f);
    idx = 0;
    #pragma unroll
    for (int j = 1; j < {2 ** kvq.vbits}; j++) idx += zv > 0.5f * (cbv_s[j] + cbv_s[j - 1]) ? 1u : 0u;
    idx_s[t] = idx;
    if (t == 0) ((float*)(Kh + {off['vs']}))[start_pos] = nv / 16.0f;
    BAR();
    {kv_store_idx(off, D, kvq.vbits, "vq", "v1")}
  }}"""
def kv_qk_prep_code(H:int, HKV:int, D:int, RD:int, G:int, QSTRIDE:int, eps:float, qk_norm:bool) -> str:
  """steps 1-2 of the attention kernels: normalize q (G heads), the new k, v into LDS (q_s, knew, vnew) and apply rope (fr = freqs row)"""
  return rf"""// 1. normalize q (G heads) and the new k, v: wave w < G handles q head w, wave G handles k, wave G+1 handles v
  if (wave < {G}) {{
    const float* src = q_raw + (u64)({G} * kvh + wave) * {QSTRIDE};
    float x[8]; float ss = 0.0f;
    #pragma unroll
    for (int i = 0; i < 8; i++) {{ x[i] = src[lane * 8 + i]; ss += x[i] * x[i]; }}
    const float rs = {"1.0f / __builtin_sqrtf(wave_sum(ss) / " + str(D) + ".0f + " + str(eps) + "f)" if qk_norm else "1.0f"};
    #pragma unroll
    for (int i = 0; i < 8; i++) q_s[wave][lane * 8 + i] = x[i] * rs * {"qnw[lane * 8 + i]" if qk_norm else "1.0f"} * {D**-0.5}f;
  }} else if (wave == {G}) {{
    const float* src = k_raw + (u64)kvh * {D};
    float x[8]; float ss = 0.0f;
    #pragma unroll
    for (int i = 0; i < 8; i++) {{ x[i] = src[lane * 8 + i]; ss += x[i] * x[i]; }}
    const float rs = {"1.0f / __builtin_sqrtf(wave_sum(ss) / " + str(D) + ".0f + " + str(eps) + "f)" if qk_norm else "1.0f"};
    #pragma unroll
    for (int i = 0; i < 8; i++) knew[lane * 8 + i] = x[i] * rs * {"knw[lane * 8 + i]" if qk_norm else "1.0f"};
  }} else if (wave == {G} + 1) {{
    const float* src = v_raw + (u64)kvh * {D};
    #pragma unroll
    for (int i = 0; i < 8; i++) vnew[lane * 8 + i] = src[lane * 8 + i];
  }}
  BAR();
  // 2. rope on the first RD dims of q (each head) and k: pairs (d, d + RD/2); compute into rot[], then write back
  if (t < {G + 1} * {RD // 2}) {{
    const u32 hh = t / {RD // 2}, d = t % {RD // 2};
    float* vec = hh < {G} ? q_s[hh] : knew;
    const float x1 = vec[d], x2 = vec[d + {RD // 2}], c = fr[d], s = fr[d + {RD // 2}];
    if (hh < {G}) {{ rot[hh][d] = x1 * c - x2 * s; rot[hh][d + {RD // 2}] = x2 * c + x1 * s; }}
  }}
  float k1 = 0.0f, k2 = 0.0f;
  if (t < {RD // 2}) {{ const float c = fr[t], s = fr[t + {RD // 2}]; k1 = knew[t] * c - knew[t + {RD // 2}] * s; k2 = knew[t + {RD // 2}] * c + knew[t] * s; }}
  BAR();
  for (u32 i = t; i < {G} * {RD}; i += WG) q_s[i / {RD}][i % {RD}] = rot[i / {RD}][i % {RD}];
  if (t < {RD // 2}) {{ knew[t] = k1; knew[t + {RD // 2}] = k2; }}
  BAR();"""

def _attn_src(H:int, HKV:int, D:int, RD:int, MAXC:int, CH:int, eps:float, gated:bool, qk_norm:bool, toff:int=0, kvq:KVQuant|None=None) -> str:
  G = H // HKV  # q heads per kv head
  NCH = (MAXC + CH - 1) // CH
  assert D == 256 and G <= 8 and RD % 2 == 0 and RD <= 64
  QSTRIDE = 2 * D if gated else D  # q_raw layout per head: [q(D), gate(D)] when gated
  Q, J = kvq is not None, kvq is not None and kvq.qjl
  NV = 2 * G + 2 if J else G + 2  # LDS vectors: q heads, (qjl-projected q heads), new k, new v
  SQ = f"vecs + {G}" if J else "vecs"  # qjl-projected q (unused without qjl)
  # --- the quantized cache: per-lane loads of the 8 coordinates [8*lane, 8*lane+8), index extraction, new-token quantization + stores
  if Q:
    off = kvq.offsets(MAXC)
    loads = f"""{kv_load_idx(kvq, off, D, "k", kvq.kbits, "kq", "k1")} {kv_load_idx(kvq, off, D, "v", kvq.vbits, "vq", "v1")}
      {f"const u32 kj = ld_u8(Kh + {off['kj']} + (u64)pos * {D // 8} + lane);" if J else ""}
      const float ka = ld_f32(Kh + {off['ks']} + (u64)pos * 8), va = ld_f32(Kh + {off['vs']} + (u64)pos * 4);
      {f"const float kb = ld_f32(Kh + {off['ks']} + (u64)pos * 8 + 4);" if J else ""}
      {" ".join(f"kk[{i}] = cbk_s[{kv_idx_of('k', kvq.kbits, i)}] * ka;" for i in range(8))}
      {" ".join(f"vv[{i}] = cbv_s[{kv_idx_of('v', kvq.vbits, i)}] * va;" for i in range(8))}
      {" ".join(f"kjs[{i}] = ((kj >> {i}) & 1u) ? kb : -kb;" for i in range(8)) if J else ""}"""
    rotate = kv_rotate_code(kvq, D, G, NV)
    write_new = kv_write_code(kvq, off, D)
    cache_decl = f"u8* Kh = cache + (u64)kvh * {MAXC * kvq.bytes_per_pos};"
    lds_extra = "__attribute__((shared)) float cbk_s[16], cbv_s[16], r_s[256], red2[NW]; __attribute__((shared)) u32 idx_s[256];"
    cb_init = kv_cb_init(kvq)
    unrotate = f"""// undo the value rotation: out = signs * WHT(acc) / 16
  y_s[t] = y; wht_vecs(y_s, 1, t); y = (kv_sgn(t, {KV_SEED_ROT}u) ? -y_s[t] : y_s[t]) * (1.0f / 16.0f);"""
  else:
    loads = f"""const u32x4 ka = ld_u32x4((const u8*)(K + (u64)pos * {D} + lane * 8)), kb = ld_u32x4((const u8*)(K + (u64)pos * {D} + lane * 8 + 4));
      const u32x4 va = ld_u32x4((const u8*)(V + (u64)pos * {D} + lane * 8)), vb = ld_u32x4((const u8*)(V + (u64)pos * {D} + lane * 8 + 4));
      kk[0] = __builtin_bit_cast(float, (u32)ka.x); kk[1] = __builtin_bit_cast(float, (u32)ka.y); kk[2] = __builtin_bit_cast(float, (u32)ka.z); kk[3] = __builtin_bit_cast(float, (u32)ka.w);
      kk[4] = __builtin_bit_cast(float, (u32)kb.x); kk[5] = __builtin_bit_cast(float, (u32)kb.y); kk[6] = __builtin_bit_cast(float, (u32)kb.z); kk[7] = __builtin_bit_cast(float, (u32)kb.w);
      vv[0] = __builtin_bit_cast(float, (u32)va.x); vv[1] = __builtin_bit_cast(float, (u32)va.y); vv[2] = __builtin_bit_cast(float, (u32)va.z); vv[3] = __builtin_bit_cast(float, (u32)va.w);
      vv[4] = __builtin_bit_cast(float, (u32)vb.x); vv[5] = __builtin_bit_cast(float, (u32)vb.y); vv[6] = __builtin_bit_cast(float, (u32)vb.z); vv[7] = __builtin_bit_cast(float, (u32)vb.w);"""
    rotate, unrotate, lds_extra, cb_init = "", "", "", ""
    write_new = f"if (has_new && t < {D}) {{ K[(u64)start_pos * {D} + t] = knew[t]; V[(u64)start_pos * {D} + t] = vnew[t]; }}"
    cache_decl = f"float* K = cache + (u64)kvh * {MAXC} * {D}; float* V = cache + (u64)({HKV} + kvh) * {MAXC} * {D};"
  # toff: the token of a batch this launch handles (position start_pos + toff, row toff of q/k/v/out). tokens >= sp_p[1] are padding
  return PRELUDE + rf"""
#define WG 256
#define NW 8
#define TOFF {toff}
#define BAR() __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup")
{ATTN_DEV}
// partial attention of one kv head over one chunk of CH positions, all G q-heads of the group
KERNEL(attn_part, WG)(float* __restrict__ pacc, float* __restrict__ pm, float* __restrict__ pl, {"u8" if Q else "float"}* __restrict__ cache,
                      const float* __restrict__ q_raw, const float* __restrict__ k_raw, const float* __restrict__ v_raw,
                      const float* __restrict__ qnw, const float* __restrict__ knw, const float* __restrict__ freqs, const i32* __restrict__ sp_p) {{
  __attribute__((shared)) float vecs[{NV}][{D}], acc_s[{G}][{D}], red[NW][{G}][2], rot[{G}][{RD}];
  {lds_extra}
  float (*q_s)[{D}] = vecs; float (*sq_s)[{D}] = {SQ}; float* knew = vecs[{NV - 2}]; float* vnew = vecs[{NV - 1}];
  if (TOFF >= sp_p[1]) return;
  const i32 start_pos = sp_p[0] + TOFF;
  q_raw += TOFF * {H * QSTRIDE}; k_raw += TOFF * {HKV * D}; v_raw += TOFF * {HKV * D};
  const u32 kvh = wg_id() / {NCH}, chunk = wg_id() % {NCH};
  const u32 pos0 = chunk * {CH};
  if (pos0 > (u32)start_pos) return;
  const u32 n = __builtin_amdgcn_readfirstlane((u32)start_pos + 1 - pos0 < {CH}u ? (u32)start_pos + 1 - pos0 : {CH}u);
  const u32 t = tid(), lane = lane_id(), wave = t >> 5;
  {cache_decl}
  {cb_init}
  const float* fr = freqs + (u64)start_pos * {RD};
  {kv_qk_prep_code(H, HKV, D, RD, G, QSTRIDE, eps, qk_norm)}
  {rotate}
  // 3. the chunk holding start_pos writes the new k, v into the cache (and uses the LDS copies for that position)
  const bool has_new = pos0 + n - 1 == (u32)start_pos;
  {write_new}
  // 4. online softmax over this wave's positions: pos0 + wave*PER .. ; lane owns dims [8*lane, 8*lane+8)
  float qv[{G}][8];
  #pragma unroll
  for (int h = 0; h < {G}; h++)
    #pragma unroll
    for (int i = 0; i < 8; i++) qv[h][i] = q_s[h][lane * 8 + i];
  {f"float sqv[{G}][8]; for (int h = 0; h < {G}; h++) for (int i = 0; i < 8; i++) sqv[h][i] = sq_s[h][lane * 8 + i];" if J else ""}
  float m[{G}], l[{G}], acc[{G}][8];
  #pragma unroll
  for (int h = 0; h < {G}; h++) {{ m[h] = -1e30f; l[h] = 0.0f;
    #pragma unroll
    for (int i = 0; i < 8; i++) acc[h][i] = 0.0f; }}
  // positions interleaved over the waves (p = pp * NW + wave) so a partially filled chunk still spreads over all NW waves
  const u32 PER = {CH} / NW;
  for (u32 pp = 0; pp < PER; pp++) {{
    const u32 p = pp * NW + wave;
    if (p >= n) break;
    const u32 pos = pos0 + p;
    const bool is_new = has_new && pos == (u32)start_pos;
    float kk[8], vv[8];
    {"float kjs[8];" if J else ""}
    if (is_new) {{
      #pragma unroll
      for (int i = 0; i < 8; i++) {{ kk[i] = knew[lane * 8 + i]; vv[i] = vnew[lane * 8 + i]; {"kjs[i] = 0.0f;" if J else ""} }}
    }} else {{
      {loads}
    }}
    #pragma unroll
    for (int h = 0; h < {G}; h++) {{
      float d = 0.0f;
      #pragma unroll
      for (int i = 0; i < 8; i++) {{ d += qv[h][i] * kk[i]; {"d += sqv[h][i] * kjs[i];" if J else ""} }}
      const float sc = wave_sum(d);
      const float mn = __builtin_fmaxf(m[h], sc);
      const float corr = __builtin_expf(m[h] - mn), pw = __builtin_expf(sc - mn);
      l[h] = l[h] * corr + pw;
      #pragma unroll
      for (int i = 0; i < 8; i++) acc[h][i] = acc[h][i] * corr + pw * vv[i];
      m[h] = mn;
    }}
  }}
  // 5. merge the NW waves: global max per head, then scaled accumulation into LDS (sequential over waves)
  if (lane == 0) {{
    #pragma unroll
    for (int h = 0; h < {G}; h++) {{ red[wave][h][0] = m[h]; red[wave][h][1] = l[h]; }}
  }}
  for (u32 i = t; i < {G} * {D}; i += WG) acc_s[i / {D}][i % {D}] = 0.0f;
  BAR();
  float M[{G}], Lsum[{G}];
  #pragma unroll
  for (int h = 0; h < {G}; h++) {{
    float mm = -1e30f;
    #pragma unroll
    for (int w = 0; w < NW; w++) mm = __builtin_fmaxf(mm, red[w][h][0]);
    float ll = 0.0f;
    #pragma unroll
    for (int w = 0; w < NW; w++) ll += red[w][h][1] * __builtin_expf(red[w][h][0] - mm);
    M[h] = mm; Lsum[h] = ll;
  }}
  for (u32 w = 0; w < NW; w++) {{
    if (wave == w) {{
      #pragma unroll
      for (int h = 0; h < {G}; h++) {{
        const float sc = __builtin_expf(m[h] - M[h]);
        #pragma unroll
        for (int i = 0; i < 8; i++) acc_s[h][lane * 8 + i] += acc[h][i] * sc;
      }}
    }}
    BAR();
  }}
  // 6. write the chunk partials: pacc[(kvh*G+h)][chunk][D], pm/pl[(kvh*G+h)][chunk]
  for (u32 i = t; i < {G} * {D}; i += WG) {{
    const u32 h = i / {D}, d = i % {D};
    pacc[((u64)(kvh * {G} + h) * {NCH} + chunk) * {D} + d] = acc_s[h][d];
  }}
  if (t < {G}) {{ pm[(kvh * {G} + t) * {NCH} + chunk] = M[t]; pl[(kvh * {G} + t) * {NCH} + chunk] = Lsum[t]; }}
}}
// merge the chunks of every q head, apply the output gate, and quantize for the output projection. one workgroup per head, thread = dim
KERNEL(attn_merge, 256)(float* __restrict__ out, i8* __restrict__ oq, float* __restrict__ os, float* __restrict__ osum16,
                        const float* __restrict__ pacc, const float* __restrict__ pm, const float* __restrict__ pl,
                        const float* __restrict__ q_raw, const i32* __restrict__ sp_p) {{
  {"__attribute__((shared)) float y_s[256];" if Q else ""}
  const bool pad = TOFF >= sp_p[1];
  const i32 start_pos = sp_p[0] + TOFF;
  q_raw += TOFF * {H * QSTRIDE}; out += TOFF * {H * D}; oq += TOFF * {H * D}; os += TOFF * {H * D // 32}; osum16 += TOFF * {H * D // 16};
  const u32 h = wg_id(), t = tid(), lane = lane_id();
  const u32 nch = pad ? 0 : ((u32)start_pos + {CH}) / {CH};
  float M = -1e30f;
  for (u32 c = 0; c < nch; c++) M = __builtin_fmaxf(M, pm[h * {NCH} + c]);
  float L = 0.0f, a = 0.0f;
  for (u32 c = 0; c < nch; c++) {{
    const float w = __builtin_expf(pm[h * {NCH} + c] - M);
    L += pl[h * {NCH} + c] * w;
    a += pacc[((u64)h * {NCH} + c) * {D} + t] * w;
  }}
  float y = pad ? 0.0f : a / L;
  {unrotate}
  {"const float g = q_raw[h * " + str(QSTRIDE) + " + " + str(D) + " + t]; y *= 1.0f / (1.0f + __builtin_expf(-g));" if gated else ""}
  out[h * {D} + t] = y;
  // quantize this 32-block (one wave = one block)
  float ab = __builtin_fabsf(y);
  ab = __builtin_fmaxf(ab, dpp_shr(ab, 0x111)); ab = __builtin_fmaxf(ab, dpp_shr(ab, 0x112));
  ab = __builtin_fmaxf(ab, dpp_shr(ab, 0x114)); ab = __builtin_fmaxf(ab, dpp_shr(ab, 0x118));
  const float mx = __builtin_fmaxf(read_lane(ab, 15), read_lane(ab, 31));
  const float dq = mx / 127.0f, id = dq != 0.0f ? 1.0f / dq : 0.0f;
  const i32 qi = (i32)__builtin_rintf(y * id);
  const u32 blk = (h * {D} + t) >> 5;
  oq[h * {D} + t] = (i8)qi;
  const float sq = row_sum16((float)qi);
  if (lane == 15) osum16[blk * 2] = dq * sq;
  if (lane == 31) {{ osum16[blk * 2 + 1] = dq * sq; os[blk] = dq; }}
}}
"""

def attn_decode(cache:Tensor, q_raw:Tensor, k_raw:Tensor, v_raw:Tensor, qnw:Tensor|None, knw:Tensor|None, freqs:Tensor, start_pos:UOp|int,
                H:int, HKV:int, D:int, RD:int, MAXC:int, eps:float, gated:bool, T:int=1, n_tok:UOp|int|None=None, kvq:KVQuant|None=None) -> Tensor:
  """attention of T tokens (positions start_pos.., tokens >= n_tok are padding) with the kv cache updated in place: (2, 1, HKV, MAXC, D) f32,
  or the quantized u8 layout of kvq (see KVQuant).
  one fused kernel pair per token, chained; prefill chunks (T > MAX_T) go through amd_prefill.attn_prefill (needs the quantized cache).
  returns (T, H*D) f32 (gated), quantization cached"""
  if T > MAX_T:
    assert kvq is not None, "prefill attention needs the quantized kv cache"
    from tinygrad.llm.amd_prefill import attn_prefill
    return attn_prefill(cache, q_raw, k_raw, v_raw, qnw, knw, freqs, start_pos, H, HKV, D, RD, MAXC, eps, gated, T, n_tok, kvq)
  # positions per workgroup: larger chunks amortize the per-workgroup q prep and shrink the partials (G*D floats per chunk) the merge
  # kernel reads back, which at long context cost as much traffic as the quantized cache itself with 128; smaller chunks give more
  # parallelism at short context
  CH = getenv("AMD_ATTN_CH", 256)
  assert CH % 16 == 0
  if kvq is not None and getenv("AMD_ATTN_MQ", 1):
    # multi-query flash decoding: the whole chunk of tokens scores every cache chunk in one pass (tensor cores), cache read once per step
    from tinygrad.llm.amd_prefill import attn_decode_mq
    return attn_decode_mq(cache, q_raw, k_raw, v_raw, qnw, knw, freqs, start_pos, H, HKV, D, RD, MAXC, eps, gated, T, n_tok, kvq,
                          getenv("AMD_ATTN_MQ_CH", CH))
  NCH = (MAXC + CH - 1) // CH
  dev, arch = cache.device, _arch(cache.device)
  qk_norm = qnw is not None
  sfx = f"_{H}_{HKV}_{D}_{RD}_{MAXC}_{CH}_{int(gated)}{int(qk_norm)}{'_' + kvq.key if kvq is not None else ''}"
  pacc = Tensor.empty(H * NCH * D, dtype=dtypes.float32, device=dev)
  pm = Tensor.empty(H * NCH, dtype=dtypes.float32, device=dev)
  pl = Tensor.empty(H * NCH, dtype=dtypes.float32, device=dev)
  dummy = qnw if qnw is not None else Tensor.empty(D, dtype=dtypes.float32, device=dev)
  dummyk = knw if knw is not None else dummy
  sp_t = start_pos_tensor(start_pos, dev, T if n_tok is None else n_tok)
  q_raw, k_raw, v_raw = q_raw.reshape(-1).float(), k_raw.reshape(-1).float(), v_raw.reshape(-1).float()
  out = Tensor.empty(T * H * D, dtype=dtypes.float32, device=dev)
  oq, os_, osum16 = (Tensor.empty(n, dtype=dt, device=dev) for n, dt in ((T * H * D, dtypes.int8), (T * H * D // 32, dtypes.float32), (T * H * D // 16, dtypes.float32)))
  for toff in range(T):
    src = _attn_src(H, HKV, D, RD, MAXC, CH, eps, gated, qk_norm, toff, kvq)
    tsfx = f"{sfx}_t{toff}"
    # one kernel per source/ELF (the loader expects a single kernel per program)
    cut = src.index("// merge the chunks")
    ir = hip_to_ir(src[:cut].replace("KERNEL(attn_part,", f"KERNEL(attn_part{tsfx},"), arch)
    ir_merge = hip_to_ir(src[:src.index("// partial attention")] + src[cut:].replace("KERNEL(attn_merge,", f"KERNEL(attn_merge{tsfx},"), arch)
    def part_fxn(pa, pmm, pll, c, q, k, v, qw, kw, fq, sp, ir=ir, tsfx=tsfx):
      sink = UOp.sink(UOp.special(HKV * NCH, "gidx0"), UOp.special(256, "lidx0"), pa, pmm, pll, c, q, k, v, qw, kw, fq, sp,
                      arg=KernelInfo(name=f"attn_part{tsfx}", estimates=Estimates(ops=H * MAXC * D * 4, mem=2 * HKV * MAXC * D * 4)))
      return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=ir)))
    outs = pacc.custom_kernel(pm, pl, cache, q_raw, k_raw, v_raw, dummy, dummyk, freqs, sp_t, fxn=part_fxn)
    pacc, pm, pl, cache = outs[0], outs[1], outs[2], outs[3]
    def merge_fxn(o, q8, s8, sm, pa, pmm, pll, q, sp, ir_merge=ir_merge, tsfx=tsfx):
      sink = UOp.sink(UOp.special(H, "gidx0"), UOp.special(256, "lidx0"), o, q8, s8, sm, pa, pmm, pll, q, sp,
                      arg=KernelInfo(name=f"attn_merge{tsfx}", estimates=Estimates(ops=H * NCH * D * 2, mem=H * NCH * D * 4)))
      return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=ir_merge)))
    outs = out.custom_kernel(oq, os_, osum16, pacc, pm, pl, q_raw, sp_t, fxn=merge_fxn)
    out, oq, os_, osum16, pacc, pm, pl = outs[0], outs[1], outs[2], outs[3], outs[4], outs[5], outs[6]
  cache_quant(out, oq, os_, osum16)
  return out.reshape(T, H * D)
