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
def _quant_src(K:int, in_dtype:str) -> str:
  return PRELUDE + rf"""
KERNEL(quant_x, 256)(i8* __restrict__ q, float* __restrict__ xs, float* __restrict__ xsum16, const {in_dtype}* __restrict__ x) {{
  const u32 lane = lane_id(), blk = wg_id() * 8 + (tid() >> 5);
  if (blk * 32 >= {K}u) return;
  const float v = (float)x[blk * 32 + lane];
  float a = __builtin_fabsf(v);
  a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
  a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
  const float m = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
  const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
  const i32 qi = (i32)__builtin_rintf(v * id);
  q[blk * 32 + lane] = (i8)qi;
  const float s = row_sum16((float)qi);
  if (lane == 15) xsum16[blk * 2] = d * s;
  if (lane == 31) {{ xsum16[blk * 2 + 1] = d * s; xs[blk] = d; }}
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

MAX_T = 8  # tokens per batched gemv launch (weights stream once per T tokens)

def quantize_x(x:Tensor) -> tuple[Tensor, Tensor, Tensor]:
  """float x[T, K] -> (int8 q[T*K], f32 scale[T*K/32], f32 sum16[T*K/16]), the per-32-block quantization of every token row"""
  K = int(x.numel())
  assert K % 32 == 0
  x = x.reshape(K)
  if x.dtype not in (dtypes.float32, dtypes.float16): x = x.float()
  in_dtype = "float" if x.dtype == dtypes.float32 else "_Float16"
  q = Tensor.empty(K, dtype=dtypes.int8, device=x.device)
  xs = Tensor.empty(K // 32, dtype=dtypes.float32, device=x.device)
  xsum16 = Tensor.empty(K // 16, dtype=dtypes.float32, device=x.device)
  name = f"quant_x_{K}_{in_dtype.strip('_')}"
  src = _quant_src(K, in_dtype).replace("KERNEL(quant_x,", f"KERNEL({name},")
  outs = q.custom_kernel(xs, xsum16, x, fxn=_src_program(name, src, (K // 32 + 7) // 8, 256, Estimates(ops=4 * K, mem=5 * K), _arch(x.device)))
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
  """number of K-vectors in x (0 when x is not a batch of at most MAX_T K-vectors)"""
  n = x.numel()
  if x.shape[-1] != K or not isinstance(n, int) or n % K != 0 or n // K > MAX_T: return 0
  return n // K

def linear_decode_multi(lins:list[nn.Linear], x:Tensor) -> list[Tensor]:
  """several Linears on the same (<= MAX_T tokens) input in one launch"""
  gws:list[GGMLWeight] = [lin._ggml for lin in lins]  # type: ignore[attr-defined]
  K = gws[0].K
  T = _tokens(x, K)
  xq, xs, xsum16 = quantize_x_cached(x.reshape(T, K))
  ys = gemv_multi([(gw.raw, gw.ggml_type, gw.N) for gw in gws], K, xq, xs, xsum16, T)
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
def quantize_x_cached(x:Tensor) -> tuple[Tensor, Tensor, Tensor]:
  if (r:=_xq_cache.get(k:=_xq_key(x))) is None:
    if len(_xq_cache) >= 16: _xq_cache.clear()
    _xq_cache[k] = r = quantize_x(x)
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
  xq, xs, xsum16 = quantize_x_cached(x.reshape(T, gw.K))
  y = gemv(gw.raw, gw.ggml_type, gw.N, gw.K, xq, xs, xsum16, residual, T)
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
def new_forward():
  """call at the start of every model forward: the [start_pos, n_tok] tensor is shared between the layers of one pass only (one from an
  earlier pass is already realized and the JIT would capture it as a constant instead of a kernel reading the variables)"""
  global _fwd_id
  _fwd_id += 1
  _sp_cache.clear()
def start_pos_tensor(start_pos:UOp|int, device:str, n_tok:UOp|int=1) -> Tensor:
  """[start_pos, n_tok] as an int32 tensor (kernels read them from memory, no dependency on symbolic variable plumbing)"""
  key = (_fwd_id, start_pos if isinstance(start_pos, int) else start_pos.key, n_tok if isinstance(n_tok, int) else n_tok.key, device)
  if (t:=_sp_cache.get(key)) is None:
    if len(_sp_cache) >= 8: _sp_cache.clear()
    sp = (Tensor.zeros(1, dtype=dtypes.int32, device=device) + start_pos).cast(dtypes.int32)
    nt = (Tensor.zeros(1, dtype=dtypes.int32, device=device) + n_tok).cast(dtypes.int32)
    _sp_cache[key] = t = sp.cat(nt).contiguous()
  return t

def _gdn_conv_src(C:int, KC:int, T:int) -> str:
  # conv_state: (KC-1, C) f32 in/out, qkv: (T, C) f32 new rows, w: (C, KC) f32. conv_out: (T, C) f32 = silu(sum_i win[t+i][c] * w[c][i])
  # sp_p = [start_pos, n_tok]: tokens t >= n_tok are padding, the new conv state is the last KC-1 rows of [state | qkv[:n_tok]]
  return PRELUDE + rf"""
KERNEL(gdn_conv, 256)(float* __restrict__ conv_out, float* __restrict__ conv_state, const float* __restrict__ qkv,
                      const float* __restrict__ w, const i32* __restrict__ sp_p) {{
  const i32 start_pos = sp_p[0], n = sp_p[1];
  const u32 c = wg_id() * 256 + tid();
  if (c >= {C}u) return;
  const bool reset = start_pos == 0;
  float win[{KC} - 1 + {T}];
  #pragma unroll
  for (int i = 0; i < {KC} - 1; i++) win[i] = reset ? 0.0f : conv_state[i * {C} + c];
  #pragma unroll
  for (int t = 0; t < {T}; t++) win[{KC} - 1 + t] = qkv[t * {C} + c];
  float wv[{KC}];
  #pragma unroll
  for (int i = 0; i < {KC}; i++) wv[i] = w[c * {KC} + i];
  #pragma unroll
  for (int t = 0; t < {T}; t++) {{
    float acc = 0.0f;
    #pragma unroll
    for (int i = 0; i < {KC}; i++) acc += win[t + i] * wv[i];
    conv_out[t * {C} + c] = acc / (1.0f + __builtin_expf(-acc));
  }}
  #pragma unroll
  for (int i = 0; i < {KC} - 1; i++) {{
    float v = 0.0f;
    #pragma unroll
    for (int m = 0; m < {KC} - 1 + {T}; m++) v = (m == n + i) ? win[m] : v;
    conv_state[i * {C} + c] = v;
  }}
}}
"""

def _gdn_step_src(H:int, HK:int, V:int, K:int, C:int, eps:float, qk_eps:float, T:int) -> str:
  # one workgroup (512 threads) per v-head h: 4 threads per state row (v), 32 k each. the state stays in registers over the T steps
  assert V == 128 and K == 128 and T <= 8
  QD = HK * K  # q/k width in conv_out
  BAR = '__builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");'
  return PRELUDE + rf"""
#define dpp_xmask(v, m) __builtin_bit_cast(float, __builtin_amdgcn_update_dpp(0, __builtin_bit_cast(i32, (v)), 0x160 | (m), 0xf, 0xf, true))
DEV float sum4(float v) {{ v += dpp_xmask(v, 1); v += dpp_xmask(v, 2); return v; }}
KERNEL(gdn_step, 512)(float* __restrict__ z, i8* __restrict__ zq, float* __restrict__ zs, float* __restrict__ zsum16,
                      float* __restrict__ state, const float* __restrict__ conv_out,
                      const float* __restrict__ alpha_raw, const float* __restrict__ beta_raw, const float* __restrict__ dt_bias,
                      const float* __restrict__ A, const float* __restrict__ gate, const float* __restrict__ norm_w, const i32* __restrict__ sp_p) {{
  __attribute__((shared)) float qs[{T}][{K}], ks[{T}][{K}], vs[{T}][{V}], outs[{T}][{V}], red[{T}][4], dec[{T}], bet[{T}];
  const i32 start_pos = sp_p[0];
  const u32 n = __builtin_amdgcn_readfirstlane((u32)sp_p[1]);
  const u32 h = wg_id(), t = tid(), lane = lane_id(), wave = t >> 5;
  const u32 hk = h % {HK};
  // load q, k, v of this head for all T tokens
  for (u32 i = t; i < {T} * {K}; i += 512) {{
    const u32 tt = i / {K}, kk = i % {K};
    qs[tt][kk] = conv_out[tt * {C} + hk * {K} + kk]; ks[tt][kk] = conv_out[tt * {C} + {QD} + hk * {K} + kk]; vs[tt][kk] = conv_out[tt * {C} + 2 * {QD} + h * {V} + kk];
  }}
  if (t < {T}) {{  // per-token decay and beta of this head
    const float a_in = alpha_raw[t * {H} + h] + dt_bias[h];
    const float sp = a_in > 20.0f ? a_in : __builtin_logf(1.0f + __builtin_expf(a_in));  // softplus
    dec[t] = start_pos + (i32)t == 0 ? 0.0f : __builtin_expf(sp * A[h]);                 // state reset folds into the decay
    bet[t] = 1.0f / (1.0f + __builtin_expf(-beta_raw[t * {H} + h]));
  }}
  {BAR}
  for (u32 p = wave; p < 2 * {T}; p += 16) {{  // |q_t| (even p) and |k_t| (odd p)
    const float* src = (p & 1) ? ks[p >> 1] : qs[p >> 1];
    float s = 0.0f;
    #pragma unroll
    for (int i = 0; i < {K} / 32; i++) {{ const float x = src[lane * ({K} / 32) + i]; s += x * x; }}
    s = wave_sum(s);
    if (lane == 0) red[p >> 1][p & 1] = __builtin_fmaxf(__builtin_sqrtf(s), {qk_eps}f);
  }}
  {BAR}
  // this thread: row v = t >> 2, k range [32*(t&3), +32)
  const u32 v = t >> 2, k0 = (t & 3) * 32;
  float* srow = state + ((u64)h * {V} + v) * {K} + k0;
  float s[32], kk[32];
  #pragma unroll
  for (int i = 0; i < 32; i++) s[i] = srow[i];
  for (u32 tt = 0; tt < n; tt++) {{
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
  }}
  #pragma unroll
  for (int i = 0; i < 32; i++) srow[i] = s[i];
  {BAR}
  if (wave < {T}) {{  // rms of the output of token `wave`
    float ss = 0.0f;
    #pragma unroll
    for (int i = 0; i < {V} / 32; i++) {{ const float x = wave < n ? outs[wave][lane * ({V} / 32) + i] : 0.0f; ss += x * x; }}
    ss = wave_sum(ss);
    if (lane == 0) red[wave][2] = 1.0f / __builtin_sqrtf(ss / {V}.0f + {eps}f);
  }}
  {BAR}
  for (u32 i = t; i < {T} * {V}; i += 512) {{  // each wave handles one 32-block of one token: gated norm + quantization
    const u32 tt = i / {V}, vv = i % {V}, e = tt * {H * V} + h * {V} + vv;
    const float g = gate[e];
    const float y = tt < n ? outs[tt][vv] * red[tt][2] * norm_w[vv] * (g / (1.0f + __builtin_expf(-g))) : 0.0f;
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
  zq, zs, zsum16 = (Tensor.empty(n, dtype=dt, device=dev) for n, dt in ((T * H * V, dtypes.int8), (T * H * V // 32, dtypes.float32), (T * H * V // 16, dtypes.float32)))
  name = f"gdn_step_{H}_{HK}_{V}_{K}_t{T}"
  def step_fxn(zz, zzq, zzs, zzsum, st, co, ar, br, db, aa, g, nw, sp):
    sink = UOp.sink(UOp.special(H, "gidx0"), UOp.special(512, "lidx0"), zz, zzq, zzs, zzsum, st, co, ar, br, db, aa, g, nw, sp,
                    arg=KernelInfo(name=name, estimates=Estimates(ops=T * H * V * K * 6, mem=H * V * K * 8)))
    src = _gdn_step_src(H, HK, V, K, C, eps, qk_eps, T).replace("KERNEL(gdn_step,", f"KERNEL({name},")
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=hip_to_ir(src, arch))))
  outs = z.custom_kernel(zq, zs, zsum16, rec_state, conv_out, alpha_raw.reshape(T * H).float(), beta_raw.reshape(T * H).float(),
                         dt_bias, A, gate.reshape(T * H * V).float(), norm_w, sp_t, fxn=step_fxn)
  z = outs[0]
  cache_quant(z, outs[1], outs[2], outs[3])
  return z.reshape(T, H * V)

# ---------------------------------------------------------------------------------------------------------------------------------------
# fused activation producers: they return the float activation and pre-populate the int8 quantization cache keyed by its uop

def _act_quant_src(K:int, mode:str, in_dtype:str) -> str:
  # mode "rmsnorm": y = x * rsqrt(mean(x^2) + eps) * w   (one workgroup, K <= 256*32)
  # mode "silumul": y = silu(a) * b                       (per 32-block, independent)
  NW = K // 32
  assert NW <= 1024 or mode != "rmsnorm"
  WG = 1024 if mode == "rmsnorm" else 256
  body = rf"""
  const u32 lane = lane_id(), wave = tid() >> 5, blk = wg_id() * ({WG} / 32) + wave;
  {"" if mode == "rmsnorm" else f"if (blk >= {NW}u) return;"}
  const u32 e = blk * 32 + lane;
  """ + (r"""
  __attribute__((shared)) float red[32];
  // one workgroup per token row
  const u32 row = wg_id();
  x += (u64)row * K; y += (u64)row * K; q += (u64)row * K; xs += row * (K / 32); xsum16 += row * (K / 16);
  float xv[NPER];
  float ss = 0.0f;
  #pragma unroll
  for (int i = 0; i < NPER; i++) { xv[i] = (float)x[(wave * NPER + i) * 32 + lane]; ss += xv[i] * xv[i]; }
  ss = wave_sum(ss);
  if (lane == 0) red[wave] = ss;
  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
  float tot = 0.0f;
  #pragma unroll
  for (int i = 0; i < NWAVES; i++) tot += red[i];
  const float rs = 1.0f / __builtin_sqrtf(tot / (float)K + EPS);
  #pragma unroll
  for (int i = 0; i < NPER; i++) {
    const u32 b = wave * NPER + i, ee = b * 32 + lane;
    const float v = xv[i] * rs * w[ee];
    y[ee] = v;
    float a = __builtin_fabsf(v);
    a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
    a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
    const float m = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
    const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
    const i32 qi = (i32)__builtin_rintf(v * id);
    q[ee] = (i8)qi;
    const float s = row_sum16((float)qi);
    if (lane == 15) xsum16[b * 2] = d * s;
    if (lane == 31) { xsum16[b * 2 + 1] = d * s; xs[b] = d; }
  }
""" if mode == "rmsnorm" else r"""
  const float g = (float)x[e];
  const float v = g / (1.0f + __builtin_expf(-g)) * (float)w[e];
  y[e] = v;
  float a = __builtin_fabsf(v);
  a = __builtin_fmaxf(a, dpp_shr(a, 0x111)); a = __builtin_fmaxf(a, dpp_shr(a, 0x112));
  a = __builtin_fmaxf(a, dpp_shr(a, 0x114)); a = __builtin_fmaxf(a, dpp_shr(a, 0x118));
  const float m = __builtin_fmaxf(read_lane(a, 15), read_lane(a, 31));
  const float d = m / 127.0f, id = d != 0.0f ? 1.0f / d : 0.0f;
  const i32 qi = (i32)__builtin_rintf(v * id);
  q[e] = (i8)qi;
  const float s = row_sum16((float)qi);
  if (lane == 15) xsum16[blk * 2] = d * s;
  if (lane == 31) { xsum16[blk * 2 + 1] = d * s; xs[blk] = d; }
""")
  return PRELUDE + rf"""
#define K {K}
#define NWAVES {WG // 32}
#define NPER {max(1, NW // (WG // 32))}
KERNEL(act_quant, {WG})(float* __restrict__ y, i8* __restrict__ q, float* __restrict__ xs, float* __restrict__ xsum16,
                        const {in_dtype}* __restrict__ x, const {"float" if mode == "rmsnorm" else in_dtype}* __restrict__ w) {{
  {body}
}}
"""

def _act_quant(x:Tensor, w:Tensor, mode:str, eps:float=0.0) -> Tensor:
  """x: T rows of K (T <= MAX_T). rmsnorm: w[K] float, one workgroup per row. silumul: w has the shape of x, elementwise"""
  K = int(x.shape[-1])
  T = _tokens(x, K)
  assert T, f"{x.shape} is not a batch of at most {MAX_T} K-vectors"
  x = x.reshape(T * K)
  if x.dtype not in (dtypes.float32, dtypes.float16): x = x.float()
  in_dtype = "float" if x.dtype == dtypes.float32 else "_Float16"
  if mode == "rmsnorm": w = w.reshape(K).float()
  else: w = w.reshape(T * K).cast(x.dtype)
  dev = x.device
  y = Tensor.empty(T * K, dtype=dtypes.float32, device=dev)
  q = Tensor.empty(T * K, dtype=dtypes.int8, device=dev)
  xs = Tensor.empty(T * K // 32, dtype=dtypes.float32, device=dev)
  xsum16 = Tensor.empty(T * K // 16, dtype=dtypes.float32, device=dev)
  WG = 1024 if mode == "rmsnorm" else 256
  n_wg = T if mode == "rmsnorm" else (T * K // 32 + WG // 32 - 1) // (WG // 32)
  name = f"{mode}_quant_{K}_{in_dtype.strip('_')}" + (f"_t{T}" if mode != "rmsnorm" else "")
  src = _act_quant_src(K if mode == "rmsnorm" else T * K, mode, in_dtype).replace("EPS", f"{eps}f").replace("KERNEL(act_quant,", f"KERNEL({name},")
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
# fused single-token attention (flash-decoding): q/k norm + rope + kv cache write + chunked softmax(q k^T) v, merged by a second kernel

def _attn_src(H:int, HKV:int, D:int, RD:int, MAXC:int, CH:int, eps:float, gated:bool, qk_norm:bool, toff:int=0) -> str:
  G = H // HKV  # q heads per kv head
  NCH = (MAXC + CH - 1) // CH
  assert D == 256 and G <= 8 and RD % 2 == 0 and RD <= 64
  QSTRIDE = 2 * D if gated else D  # q_raw layout per head: [q(D), gate(D)] when gated
  # toff: the token of a batch this launch handles (position start_pos + toff, row toff of q/k/v/out). tokens >= sp_p[1] are padding
  return PRELUDE + rf"""
#define WG 256
#define NW 8
#define TOFF {toff}
// partial attention of one kv head over one chunk of CH positions, all G q-heads of the group
KERNEL(attn_part, WG)(float* __restrict__ pacc, float* __restrict__ pm, float* __restrict__ pl, float* __restrict__ cache,
                      const float* __restrict__ q_raw, const float* __restrict__ k_raw, const float* __restrict__ v_raw,
                      const float* __restrict__ qnw, const float* __restrict__ knw, const float* __restrict__ freqs, const i32* __restrict__ sp_p) {{
  __attribute__((shared)) float q_s[{G}][{D}], knew[{D}], vnew[{D}], acc_s[{G}][{D}], red[NW][{G}][2], rot[{G}][{RD}];
  if (TOFF >= sp_p[1]) return;
  const i32 start_pos = sp_p[0] + TOFF;
  q_raw += TOFF * {H * QSTRIDE}; k_raw += TOFF * {HKV * D}; v_raw += TOFF * {HKV * D};
  const u32 kvh = wg_id() / {NCH}, chunk = wg_id() % {NCH};
  const u32 pos0 = chunk * {CH};
  if (pos0 > (u32)start_pos) return;
  const u32 n = __builtin_amdgcn_readfirstlane((u32)start_pos + 1 - pos0 < {CH}u ? (u32)start_pos + 1 - pos0 : {CH}u);
  const u32 t = tid(), lane = lane_id(), wave = t >> 5;
  float* K = cache + (u64)kvh * {MAXC} * {D};
  float* V = cache + (u64)({HKV} + kvh) * {MAXC} * {D};
  const float* fr = freqs + (u64)start_pos * {RD};
  // 1. normalize q (G heads) and the new k, v: wave w < G handles q head w, wave G handles k, wave G+1 handles v
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
  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
  // 2. rope on the first RD dims of q (each head) and k: pairs (d, d + RD/2); compute into rot[], then write back
  if (t < {G + 1} * {RD // 2}) {{
    const u32 hh = t / {RD // 2}, d = t % {RD // 2};
    float* vec = hh < {G} ? q_s[hh] : knew;
    const float x1 = vec[d], x2 = vec[d + {RD // 2}], c = fr[d], s = fr[d + {RD // 2}];
    if (hh < {G}) {{ rot[hh][d] = x1 * c - x2 * s; rot[hh][d + {RD // 2}] = x2 * c + x1 * s; }}
  }}
  float k1 = 0.0f, k2 = 0.0f;
  if (t < {RD // 2}) {{ const float c = fr[t], s = fr[t + {RD // 2}]; k1 = knew[t] * c - knew[t + {RD // 2}] * s; k2 = knew[t + {RD // 2}] * c + knew[t] * s; }}
  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
  for (u32 i = t; i < {G} * {RD}; i += WG) q_s[i / {RD}][i % {RD}] = rot[i / {RD}][i % {RD}];
  if (t < {RD // 2}) {{ knew[t] = k1; knew[t + {RD // 2}] = k2; }}
  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
  // 3. the chunk holding start_pos writes the new k, v into the cache (and uses the LDS copies for that position)
  const bool has_new = pos0 + n - 1 == (u32)start_pos;
  if (has_new && t < {D}) {{ K[(u64)start_pos * {D} + t] = knew[t]; V[(u64)start_pos * {D} + t] = vnew[t]; }}
  // 4. online softmax over this wave's positions: pos0 + wave*PER .. ; lane owns dims [8*lane, 8*lane+8)
  float qv[{G}][8];
  #pragma unroll
  for (int h = 0; h < {G}; h++)
    #pragma unroll
    for (int i = 0; i < 8; i++) qv[h][i] = q_s[h][lane * 8 + i];
  float m[{G}], l[{G}], acc[{G}][8];
  #pragma unroll
  for (int h = 0; h < {G}; h++) {{ m[h] = -1e30f; l[h] = 0.0f;
    #pragma unroll
    for (int i = 0; i < 8; i++) acc[h][i] = 0.0f; }}
  const u32 PER = {CH} / NW;
  for (u32 pp = 0; pp < PER; pp++) {{
    const u32 p = wave * PER + pp;
    if (p >= n) break;
    const u32 pos = pos0 + p;
    const bool is_new = has_new && pos == (u32)start_pos;
    float kk[8], vv[8];
    if (is_new) {{
      #pragma unroll
      for (int i = 0; i < 8; i++) {{ kk[i] = knew[lane * 8 + i]; vv[i] = vnew[lane * 8 + i]; }}
    }} else {{
      const u32x4 ka = ld_u32x4((const u8*)(K + (u64)pos * {D} + lane * 8)), kb = ld_u32x4((const u8*)(K + (u64)pos * {D} + lane * 8 + 4));
      const u32x4 va = ld_u32x4((const u8*)(V + (u64)pos * {D} + lane * 8)), vb = ld_u32x4((const u8*)(V + (u64)pos * {D} + lane * 8 + 4));
      kk[0] = __builtin_bit_cast(float, (u32)ka.x); kk[1] = __builtin_bit_cast(float, (u32)ka.y); kk[2] = __builtin_bit_cast(float, (u32)ka.z); kk[3] = __builtin_bit_cast(float, (u32)ka.w);
      kk[4] = __builtin_bit_cast(float, (u32)kb.x); kk[5] = __builtin_bit_cast(float, (u32)kb.y); kk[6] = __builtin_bit_cast(float, (u32)kb.z); kk[7] = __builtin_bit_cast(float, (u32)kb.w);
      vv[0] = __builtin_bit_cast(float, (u32)va.x); vv[1] = __builtin_bit_cast(float, (u32)va.y); vv[2] = __builtin_bit_cast(float, (u32)va.z); vv[3] = __builtin_bit_cast(float, (u32)va.w);
      vv[4] = __builtin_bit_cast(float, (u32)vb.x); vv[5] = __builtin_bit_cast(float, (u32)vb.y); vv[6] = __builtin_bit_cast(float, (u32)vb.z); vv[7] = __builtin_bit_cast(float, (u32)vb.w);
    }}
    #pragma unroll
    for (int h = 0; h < {G}; h++) {{
      float d = 0.0f;
      #pragma unroll
      for (int i = 0; i < 8; i++) d += qv[h][i] * kk[i];
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
  __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
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
    __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup");
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
                H:int, HKV:int, D:int, RD:int, MAXC:int, eps:float, gated:bool, T:int=1, n_tok:UOp|int|None=None) -> Tensor:
  """attention of T tokens (positions start_pos.., tokens >= n_tok are padding) with the kv cache (2, 1, HKV, MAXC, D) f32 updated in place.
  one fused kernel pair per token, chained. returns (T, H*D) f32 (gated), quantization cached"""
  CH = 128
  NCH = (MAXC + CH - 1) // CH
  dev, arch = cache.device, _arch(cache.device)
  qk_norm = qnw is not None
  sfx = f"_{H}_{HKV}_{D}_{RD}_{MAXC}_{int(gated)}{int(qk_norm)}"
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
    src = _attn_src(H, HKV, D, RD, MAXC, CH, eps, gated, qk_norm, toff)
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
