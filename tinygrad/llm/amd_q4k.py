"""Hand-written gfx1100 Q4_K GEMV. One wave32 per output row, no tinygrad scheduler."""
from __future__ import annotations
from tinygrad import Tensor, dtypes, nn
from tinygrad.renderer import Estimates
from tinygrad.renderer.amd.dsl import s, v, DPP, NULL, EXEC_LO
from tinygrad.uop.ops import UOp, Ops, KernelInfo
from tinygrad.runtime.autogen.amd.rdna3.ins import (
  s_load_b128, s_load_b64, s_mov_b32, s_add_u32, s_addc_u32, s_mul_i32, s_lshl_b32, s_lshr_b32,
  s_and_b32, s_or_b32, s_bfe_u32, s_cmp_lt_u32, s_cbranch_scc1, s_waitcnt, s_endpgm, s_sendmsg,
  global_load_u8, global_load_b32, global_store_b32,
  v_mov_b32_e32, v_lshlrev_b32_e32, v_and_b32_e32, v_lshrrev_b32_e32, v_add_nc_u32_e32,
  v_cvt_f32_u32_e32, v_cvt_f32_f16_e32, v_mul_f32_e32, v_add_f32_e32, v_fmac_f32_e32,
  v_fma_f32, v_permlanex16_b32,
)

QK_K = 256
Q4K_BLOCK = 144
LANES = 32

class Kernel:
  def __init__(self): self.instructions, self.labels, self.pos = [], {}, 0
  def label(self, name): self.labels[name] = self.pos
  def emit(self, inst, target=None):
    self.instructions.append(inst)
    inst._target, inst._pos = target, self.pos
    self.pos += inst.size()
    return inst
  def waitcnt(self, lgkm=None, vm=None):
    vmcnt, lgkmcnt, expcnt = vm if vm is not None else 63, lgkm if lgkm is not None else 63, 7
    self.emit(s_waitcnt(simm16=(expcnt & 0x7) | ((lgkmcnt & 0x3f) << 4) | ((vmcnt & 0x3f) << 10)))
  def finalize(self, sink: UOp) -> UOp:
    for inst in self.instructions:
      if inst._target is None: continue
      offset_dwords = (self.labels[inst._target] - inst._pos - inst.size()) // 4
      if not -32768 <= offset_dwords <= 32767:
        raise ValueError(f"branch to '{inst._target}' offset {offset_dwords} exceeds simm16")
      inst.simm16 = offset_dwords
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=tuple(UOp(Ops.INS, arg=x) for x in self.instructions))))

# RDNA3 ABI: s[0:1]=kernarg, s[2]=wgid_x, v[0]=lane
S_OUT, S_X, S_W = 4, 6, 8
S_ROW, S_BLK, S_TMP = 2, 10, 11
S_WCUR = 12
S_HDR = 16
S_SC0, S_MN0, S_SC1, S_MN1 = 20, 21, 22, 23
S_TMP2 = 24

V_LANE, V_ACC, V_OFF = 0, 2, 3
V_Q0, V_Q1, V_TMP = 26, 27, 8
V_D, V_DMIN, V_SC0, V_MN0, V_SC1, V_MN1 = 20, 21, 22, 23, 24, 25

def _bfe(width, offset): return offset | (width << 16)

def _emit_scale_pair(k: Kernel, j0: int):
  """Unpack Q4_K scales/mins for groups j0,j0+1 into VGPRs as d*sc and dmin*mn (f32)."""
  for t, j in enumerate((j0, j0 + 1)):
    sc_s, mn_s = (S_SC0, S_MN0) if t == 0 else (S_SC1, S_MN1)
    sc_v, mn_v = (V_SC0, V_MN0) if t == 0 else (V_SC1, V_MN1)
    if j < 4:
      k.emit(s_bfe_u32(s[sc_s], s[S_HDR + 1], _bfe(8, j * 8)))
      k.emit(s_and_b32(s[sc_s], s[sc_s], 63))
      k.emit(s_bfe_u32(s[mn_s], s[S_HDR + 2], _bfe(8, j * 8)))
      k.emit(s_and_b32(s[mn_s], s[mn_s], 63))
    else:
      k.emit(s_bfe_u32(s[sc_s], s[S_HDR + 3], _bfe(8, (j - 4) * 8)))
      k.emit(s_and_b32(s[S_TMP2], s[sc_s], 15))
      k.emit(s_bfe_u32(s[mn_s], s[S_HDR + 1], _bfe(8, (j - 4) * 8)))
      k.emit(s_lshr_b32(s[mn_s], s[mn_s], 6))
      k.emit(s_lshl_b32(s[mn_s], s[mn_s], 4))
      k.emit(s_or_b32(s[sc_s], s[S_TMP2], s[mn_s]))
      k.emit(s_bfe_u32(s[mn_s], s[S_HDR + 3], _bfe(8, (j - 4) * 8)))
      k.emit(s_lshr_b32(s[mn_s], s[mn_s], 4))
      k.emit(s_bfe_u32(s[S_TMP2], s[S_HDR + 2], _bfe(8, (j - 4) * 8)))
      k.emit(s_lshr_b32(s[S_TMP2], s[S_TMP2], 6))
      k.emit(s_lshl_b32(s[S_TMP2], s[S_TMP2], 4))
      k.emit(s_or_b32(s[mn_s], s[mn_s], s[S_TMP2]))
    k.emit(v_mov_b32_e32(v[sc_v], s[sc_s]))
    k.emit(v_cvt_f32_u32_e32(v[sc_v], v[sc_v]))
    k.emit(v_mul_f32_e32(v[sc_v], v[sc_v], v[V_D]))
    k.emit(v_mov_b32_e32(v[mn_v], s[mn_s]))
    k.emit(v_cvt_f32_u32_e32(v[mn_v], v[mn_v]))
    k.emit(v_mul_f32_e32(v[mn_v], v[mn_v], v[V_DMIN]))

def build_q4k_gemv(out: UOp, x: UOp, packed: UOp, N: int, K: int) -> UOp:
  assert K % QK_K == 0 and N >= 1
  nblocks = K // QK_K
  row_stride = nblocks * Q4K_BLOCK
  k = Kernel()

  k.emit(s_load_b128(sdata=s[S_OUT:S_OUT+3], sbase=s[0:1], offset=0x0, soffset=NULL))
  k.emit(s_load_b64(sdata=s[S_W:S_W+1], sbase=s[0:1], offset=0x10, soffset=NULL))
  k.emit(s_mov_b32(s[S_BLK], 0))
  k.emit(v_mov_b32_e32(v[V_ACC], 0))
  k.waitcnt(lgkm=0)

  k.emit(s_mul_i32(s[S_TMP], s[S_ROW], row_stride))
  k.emit(s_add_u32(s[S_W], s[S_W], s[S_TMP]))
  k.emit(s_addc_u32(s[S_W+1], s[S_W+1], 0))

  k.label("LOOP")
  k.emit(s_mul_i32(s[S_TMP], s[S_BLK], Q4K_BLOCK))
  k.emit(s_add_u32(s[S_WCUR], s[S_W], s[S_TMP]))
  k.emit(s_addc_u32(s[S_WCUR+1], s[S_W+1], 0))

  k.emit(s_load_b128(sdata=s[S_HDR:S_HDR+3], sbase=s[S_WCUR:S_WCUR+1], offset=0x0, soffset=NULL))
  k.waitcnt(lgkm=0)
  k.emit(v_mov_b32_e32(v[V_D], s[S_HDR]))
  k.emit(v_mov_b32_e32(v[V_DMIN], s[S_HDR]))
  k.emit(v_cvt_f32_f16_e32(v[V_D], v[V_D]))
  k.emit(v_lshrrev_b32_e32(v[V_DMIN], 16, v[V_DMIN]))
  k.emit(v_cvt_f32_f16_e32(v[V_DMIN], v[V_DMIN]))

  k.emit(s_lshl_b32(s[S_TMP2], s[S_BLK], 10))
  k.emit(v_lshlrev_b32_e32(v[V_OFF], 2, v[V_LANE]))
  k.emit(v_add_nc_u32_e32(v[V_OFF], s[S_TMP2], v[V_OFF]))
  for c in range(4):
    k.emit(global_load_u8(vdst=v[16 + c], addr=v[V_LANE], saddr=s[S_WCUR:S_WCUR+1], offset=16 + 32 * c))
    k.emit(global_load_b32(vdst=v[4 + 2 * c], addr=v[V_OFF], saddr=s[S_X:S_X+1], offset=(64 * c) * 4))
    k.emit(global_load_b32(vdst=v[5 + 2 * c], addr=v[V_OFF], saddr=s[S_X:S_X+1], offset=(64 * c) * 4 + 128))
  k.waitcnt(vm=0)
  for c in range(4):
    _emit_scale_pair(k, 2 * c)
    k.emit(v_and_b32_e32(v[V_Q0], 15, v[16 + c]))
    k.emit(v_lshrrev_b32_e32(v[V_Q1], 4, v[16 + c]))
    k.emit(v_cvt_f32_u32_e32(v[V_Q0], v[V_Q0]))
    k.emit(v_cvt_f32_u32_e32(v[V_Q1], v[V_Q1]))
    k.emit(v_fma_f32(v[V_Q0], v[V_Q0], v[V_SC0], -v[V_MN0]))
    k.emit(v_fma_f32(v[V_Q1], v[V_Q1], v[V_SC1], -v[V_MN1]))
    k.emit(v_fmac_f32_e32(v[V_ACC], v[V_Q0], v[4 + 2 * c]))
    k.emit(v_fmac_f32_e32(v[V_ACC], v[V_Q1], v[5 + 2 * c]))

  k.emit(s_add_u32(s[S_BLK], s[S_BLK], 1))
  k.emit(s_cmp_lt_u32(s[S_BLK], nblocks))
  k.emit(s_cbranch_scc1(), target="LOOP")

  for shift in (1, 2, 4, 8):
    k.emit(v_add_f32_e32(v[V_ACC], DPP, v[V_ACC], vsrc0=v[V_ACC], dpp=0x100 | shift, row_mask=0xf, bank_mask=0xf, bc=1))
  k.emit(v_permlanex16_b32(v[V_TMP], v[V_ACC], 0, 0))
  k.emit(v_add_f32_e32(v[V_ACC], v[V_ACC], v[V_TMP]))

  k.emit(s_mov_b32(EXEC_LO, 1))
  k.emit(v_mov_b32_e32(v[V_OFF], s[S_ROW]))
  k.emit(v_lshlrev_b32_e32(v[V_OFF], 2, v[V_OFF]))
  k.emit(global_store_b32(addr=v[V_OFF], data=v[V_ACC], saddr=s[S_OUT:S_OUT+1]))
  k.emit(s_sendmsg(simm16=3))
  k.emit(s_endpgm())

  mem = N * nblocks * Q4K_BLOCK + N * 4 + K * 4
  sink = UOp.sink(UOp.special(N, "gidx0"), UOp.special(LANES, "lidx0"), out, x, packed,
                  arg=KernelInfo(name=f"q4k_gemv_{N}_{K}", estimates=Estimates(ops=2 * N * K, mem=mem)))
  return k.finalize(sink)

def q4k_gemv(x: Tensor, packed: Tensor, N: int, K: int) -> Tensor:
  """y = packed_q4_k(N, K) @ x. x is (K,) or (1,K)."""
  x = x.reshape(K).float().contiguous()
  packed = packed.reshape(N * (K // QK_K) * Q4K_BLOCK).contiguous()
  out = Tensor.empty(N, dtype=dtypes.float32, device=x.device).contiguous()
  def fxn(o, xv, w): return build_q4k_gemv(o, xv, w, N, K)
  return out.custom_kernel(x, packed, fxn=fxn)[0]

def packed_from_q4k_weight(w: Tensor) -> Tensor | None:
  n = w.numel()
  if n % QK_K: return None
  want = (n // QK_K) * Q4K_BLOCK
  for u in w.uop.toposort():
    shp = getattr(u, "shape", None)
    if u.dtype is dtypes.uint8 and shp == (want,):
      return Tensor(u)
    if u.dtype is dtypes.uint8 and shp == (n // QK_K, Q4K_BLOCK):
      return Tensor(u).reshape(want)
  return None

_orig_linear_call = nn.Linear.__call__

def _asm_linear_call(self, x: Tensor):
  packed = getattr(self, "_q4k_packed", None)
  if packed is None:
    packed = packed_from_q4k_weight(self.weight)
    if packed is not None: self._q4k_packed = packed
  if packed is not None and x.ndim >= 1:
    N, K = int(self.weight.shape[0]), int(self.weight.shape[1])
    if K % QK_K == 0 and x.shape[-1] == K:
      flat = x.reshape(-1, K)
      if flat.shape[0] == 1:
        y = q4k_gemv(flat[0], packed, N, K).cast(x.dtype)
        if self.bias is not None: y = y + self.bias
        return y.reshape(*x.shape[:-1], N)
  return _orig_linear_call(self, x)

def install():
  nn.Linear.__call__ = _asm_linear_call
