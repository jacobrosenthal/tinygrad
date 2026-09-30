"""DFlash2 block-diffusion drafter (GGUF `general.architecture = dflash`), ported to match llama.cpp master's dflash.cpp (the path measured
lossless with 1.10-1.16x MTP acceptance on this model, sweeps/dflash2-revival-20260929/{SPEC.md, README.md E0}).

Per decode step, inside the spec jit:
  inject: the target's residual stream after blocks 5/19/33/47/61 for every row of the chunk -> g = hidden_norm(fc(cat)) -> per drafter
          layer K = rope(k_norm(wk g), p), V = wv g, written into a per-layer ring by absolute position p (mod RING). Rows past the accepted
          ones are dead: every position the next draft can see is rewritten by the next verify before that draft runs.
  draft:  block [anchor, MASK x D] at positions pos0..pos0+D (target token embeddings), 5 layers (grouped two-tap conv around attention
          and FFN), attention non-causal over the ring rows in the 2048 window (q_pos - k_pos < 2048, k_pos < pos0) plus all block rows,
          final norm -> the target's full lm_head on rows 1..D -> the top-16 lattice walk (dflash_sel.select_fused).
The ring holds RING > 2048 + max rows per write slots, so dead speculative rows and prefill padding only ever alias positions outside the
window of any later query. Positions stay on the device (SPEC_ASYNC has no host position at launch).
"""
from __future__ import annotations
import os
from tinygrad import Tensor, nn, dtypes
from tinygrad.helpers import DEBUG, getenv
from tinygrad.renderer import Estimates
from tinygrad.llm.gguf import gguf_load
from tinygrad.llm.kernels.amd import Linear

RING = 4096      # ring slots per layer (> 2048 window + the widest write, the 1024-row prefill chunk)
WINDOW = 2048
HEAD_DIM = 128
DFLASH_ATTN_REF = getenv("DFLASH_ATTN_REF", 0)  # 1: the tinygrad-ops attention instead of the dflash_attn kernel (reference / A-B)

def lin(layer:Linear, x:Tensor) -> Tensor:
  """the packed-weight gemv (T <= MAX_T) / dequant gemm when amd_gemv attached the raw bytes, else the generic quantized Linear"""
  if hasattr(layer, "_ggml"):
    from tinygrad.llm import amd_gemv
    return amd_gemv.linear_decode(layer, x)
  return layer(x)

def rope_neox(x:Tensor, pos:Tensor, theta:float) -> Tensor:
  """plain NeoX RoPE over the full head (pairs (i, i+64)); x (T, H, 128), pos (T,) int32 absolute positions"""
  half = HEAD_DIM // 2
  inv = Tensor([theta ** (-2.0 * i / HEAD_DIM) for i in range(half)], dtype=dtypes.float32, device=x.device)
  ang = pos.float().reshape(-1, 1) * inv.reshape(1, half)                       # (T, 64)
  c, s = ang.cos().reshape(-1, 1, half), ang.sin().reshape(-1, 1, half)
  x1, x2 = x[..., :half], x[..., half:]
  return (x1 * c - x2 * s).cat(x2 * c + x1 * s, dim=-1)

def _ring_write_src(T:int, C:int) -> str:
  from tinygrad.llm.amd_gemv import PRELUDE
  return PRELUDE + rf"""
KERNEL(dflash_ring_write, 256)(_Float16* __restrict__ rk, _Float16* __restrict__ rv, const float* __restrict__ k, const float* __restrict__ v,
                               const i32* __restrict__ pos) {{
  const u32 i = wg_id() * 256 + tid();
  if (i >= {T * C}u) return;
  const u32 t = i / {C}u, c = i % {C}u, slot = ((u32)pos[0] + t) % {RING}u;
  rk[slot * {C}u + c] = (_Float16)k[i];
  rv[slot * {C}u + c] = (_Float16)v[i];
}}
"""

def ring_write(rk:Tensor, rv:Tensor, k:Tensor, v:Tensor, pos:Tensor) -> tuple[Tensor, Tensor]:
  """write T rows of K/V (T, C) f32 into the f16 rings (RING, C) at slots (pos + t) % RING; returns the rings ordered after the write"""
  from tinygrad.llm.amd_gemv import _src_program, _arch
  T, C = int(k.shape[0]), int(k.shape[1])
  name = f"dflash_ring_write_{T}_{C}"
  src = _ring_write_src(T, C).replace("KERNEL(dflash_ring_write,", f"KERNEL({name},")
  outs = rk.custom_kernel(rv, k.contiguous(), v.contiguous(), pos.reshape(1).cast(dtypes.int32).contiguous(),
                          fxn=_src_program(name, src, (T * C + 255) // 256, 256, Estimates(mem=T * C * 12), _arch(rk.device)))
  return outs[0], outs[1]

_BAR = '#define BAR() __builtin_amdgcn_fence(__ATOMIC_RELEASE, "workgroup"); __builtin_amdgcn_s_barrier(); __builtin_amdgcn_fence(__ATOMIC_ACQUIRE, "workgroup")\n'

def _attn_src(B:int, NKV:int, G:int) -> str:
  from tinygrad.llm.amd_gemv import PRELUDE
  C, NH, NMAX = NKV * HEAD_DIM, NKV * G, WINDOW - 1 + B
  red = lambda op, arr: rf"""
  for (u32 g = 0; g < {G}u; g++) part[g][t] = {arr}[g];
  BAR();
  for (u32 s = 128; s > 0; s >>= 1) {{ if (t < s) for (u32 g = 0; g < {G}u; g++) part[g][t] = {op}(part[g][t], part[g][t + s]); BAR(); }}"""
  return PRELUDE + _BAR + rf"""
DEV float fmax_(float a, float b) {{ return a > b ? a : b; }}
DEV float fadd_(float a, float b) {{ return a + b; }}
// one workgroup per (kv head h, block row b): the {G} query heads of h attend to the ring rows in row b's window
// [max(0, pos0 + b - {WINDOW - 1}), pos0 - 1] plus all {B} block rows (non-causal), softmax in LDS, then P @ V
KERNEL(dflash_attn, 256)(float* __restrict__ out, const float* __restrict__ q, const _Float16* __restrict__ rk, const _Float16* __restrict__ rv,
                         const float* __restrict__ bk, const float* __restrict__ bv, const i32* __restrict__ pos0p) {{
  const u32 wg = wg_id(), h = wg % {NKV}u, b = wg / {NKV}u, t = tid();
  __attribute__((shared)) float qs[{G}][{HEAD_DIM}];
  __attribute__((shared)) float sc[{G}][{NMAX}];
  __attribute__((shared)) float part[{G}][256];
  for (u32 i = t; i < {G * HEAD_DIM}u; i += 256u) qs[i / {HEAD_DIM}u][i % {HEAD_DIM}u] = q[b * {NH * HEAD_DIM}u + (h * {G}u + i / {HEAD_DIM}u) * {HEAD_DIM}u + i % {HEAD_DIM}u];
  const i32 pos0 = pos0p[0], qp = pos0 + (i32)b;
  const i32 lo = qp - {WINDOW - 1} > 0 ? qp - {WINDOW - 1} : 0;
  const u32 nctx = pos0 > lo ? (u32)(pos0 - lo) : 0u, N = nctx + {B}u;
  BAR();
  float pm[{G}];
  for (u32 g = 0; g < {G}u; g++) pm[g] = -3.0e38f;
  for (u32 j = t; j < N; j += 256u) {{
    float d[{G}];
    for (u32 g = 0; g < {G}u; g++) d[g] = 0.0f;
    if (j < nctx) {{
      const _Float16* kr = rk + (u64)((u32)(lo + (i32)j) % {RING}u) * {C}u + h * {HEAD_DIM}u;
      for (u32 e = 0; e < {HEAD_DIM}u; e++) {{ const float kv = (float)kr[e]; for (u32 g = 0; g < {G}u; g++) d[g] += qs[g][e] * kv; }}
    }} else {{
      const float* kr = bk + (j - nctx) * {C}u + h * {HEAD_DIM}u;
      for (u32 e = 0; e < {HEAD_DIM}u; e++) {{ const float kv = kr[e]; for (u32 g = 0; g < {G}u; g++) d[g] += qs[g][e] * kv; }}
    }}
    for (u32 g = 0; g < {G}u; g++) {{ sc[g][j] = d[g] * {HEAD_DIM ** -0.5}f; pm[g] = fmax_(pm[g], sc[g][j]); }}
  }}{red("fmax_", "pm")}
  float mx[{G}], ps[{G}];
  for (u32 g = 0; g < {G}u; g++) {{ mx[g] = part[g][0]; ps[g] = 0.0f; }}
  BAR();
  for (u32 j = t; j < N; j += 256u)
    for (u32 g = 0; g < {G}u; g++) {{ const float e = __builtin_expf(sc[g][j] - mx[g]); sc[g][j] = e; ps[g] += e; }}{red("fadd_", "ps")}
  float inv[{G}];
  for (u32 g = 0; g < {G}u; g++) inv[g] = 1.0f / part[g][0];
  for (u32 o = t; o < {G * HEAD_DIM}u; o += 256u) {{
    const u32 g = o / {HEAD_DIM}u, e = o % {HEAD_DIM}u;
    float acc = 0.0f;
    for (u32 j = 0; j < nctx; j++) acc += sc[g][j] * (float)rv[(u64)((u32)(lo + (i32)j) % {RING}u) * {C}u + h * {HEAD_DIM}u + e];
    for (u32 j = 0; j < {B}u; j++) acc += sc[g][nctx + j] * bv[j * {C}u + h * {HEAD_DIM}u + e];
    out[b * {NH * HEAD_DIM}u + (h * {G}u + g) * {HEAD_DIM}u + e] = acc * inv[g];
  }}
}}
"""

def ring_attention(q:Tensor, rk:Tensor, rv:Tensor, bk:Tensor, bv:Tensor, pos0:Tensor, n_kv:int) -> Tensor:
  """q (B, NH*128) f32 (roped), rings (RING, n_kv*128) f16, block k/v (B, n_kv*128) f32 -> (B, NH*128): the fused dflash_attn kernel"""
  from tinygrad.llm.amd_gemv import _src_program, _arch
  B, NH = int(q.shape[0]), int(q.shape[1]) // HEAD_DIM
  G = NH // n_kv
  name = f"dflash_attn_{B}_{n_kv}_{G}"
  src = _attn_src(B, n_kv, G).replace("KERNEL(dflash_attn,", f"KERNEL({name},")
  out = Tensor.empty(B * NH * HEAD_DIM, dtype=dtypes.float32, device=q.device)
  est = Estimates(ops=4 * B * NH * WINDOW * HEAD_DIM, mem=4 * B * n_kv * WINDOW * HEAD_DIM)
  return out.custom_kernel(q.contiguous(), rk, rv, bk.contiguous(), bv.contiguous(), pos0.reshape(1).cast(dtypes.int32).contiguous(),
                           fxn=_src_program(name, src, n_kv * B, 256, est, _arch(q.device)))[0].reshape(B, NH * HEAD_DIM)

class GroupedConv:
  """y[t,c] = (base[side,0,c] + dyn[t,side,0,g(c)]) * x[t,c] + (base[side,1,c] + dyn[t,side,1,g(c)]) * x[t-1,c], x[-1] = 0; the same dyn
  (from the normed input before the conv) drives side 0 (before the op) and side 1 (after it)"""
  def __init__(self, dim:int, taps:int, group_size:int):
    assert dim % group_size == 0 and taps == 2
    self.taps, self.group_size, self.num_groups = taps, group_size, dim // group_size
    self.base = Tensor.zeros(2, taps, dim)
    self.proj = Linear(dim, 2 * taps * self.num_groups, bias=False)

  def _mix(self, x:Tensor, dyn:Tensor, side:int) -> Tensor:
    # x (B, C), dyn (B, 2, taps, G)
    B, C = x.shape
    xs = x.reshape(B, self.num_groups, self.group_size)
    coeff = self.base[side].float().reshape(1, self.taps, self.num_groups, self.group_size) + \
            dyn[:, side].reshape(B, self.taps, self.num_groups, 1)
    prev = xs[:-1].pad(((1, 0), None, None))          # x[t-1], zero at the block start
    return (coeff[:, 0] * xs + coeff[:, 1] * prev).reshape(B, C)

  def prepare(self, x:Tensor) -> tuple[Tensor, Tensor]:
    dyn = lin(self.proj, x).reshape(x.shape[0], 2, self.taps, self.num_groups)
    return self._mix(x, dyn, 0), dyn

  def finish(self, y:Tensor, dyn:Tensor) -> Tensor: return self._mix(y, dyn, 1)

class DFlashLayer:
  def __init__(self, dim:int, n_heads:int, n_kv:int, hidden:int, eps:float, taps:int, group_size:int):
    self.n_heads, self.n_kv = n_heads, n_kv
    self.attn_norm, self.ffn_norm = nn.RMSNorm(dim, eps), nn.RMSNorm(dim, eps)
    self.attn_q = Linear(dim, n_heads * HEAD_DIM, bias=False)
    self.attn_k = Linear(dim, n_kv * HEAD_DIM, bias=False)
    self.attn_v = Linear(dim, n_kv * HEAD_DIM, bias=False)
    self.attn_output = Linear(n_heads * HEAD_DIM, dim, bias=False)
    self.attn_q_norm, self.attn_k_norm = nn.RMSNorm(HEAD_DIM, eps), nn.RMSNorm(HEAD_DIM, eps)
    self.ffn_gate, self.ffn_up = Linear(dim, hidden, bias=False), Linear(dim, hidden, bias=False)
    self.ffn_down = Linear(hidden, dim, bias=False)
    self.attn_conv, self.ffn_conv = GroupedConv(dim, taps, group_size), GroupedConv(dim, taps, group_size)

  def context_kv(self, g:Tensor, pos:Tensor, theta:float) -> tuple[Tensor, Tensor]:
    """g (T, dim) fused target features -> K (T, n_kv*128) after k_norm + RoPE, V (T, n_kv*128): no attn_norm, no conv, no V norm"""
    T = int(g.shape[0])
    k = self.attn_k_norm(lin(self.attn_k, g).reshape(T, self.n_kv, HEAD_DIM))
    return rope_neox(k, pos, theta).reshape(T, -1), lin(self.attn_v, g)

  def __call__(self, x:Tensor, pos:Tensor, pos0:Tensor, rk:Tensor, rv:Tensor, theta:float) -> Tensor:
    """x (B, dim) block rows at positions pos (B,), rings (RING, n_kv*128) f16 holding context positions < pos0"""
    B = int(x.shape[0]); G = self.n_heads // self.n_kv
    n, dyn = self.attn_conv.prepare(self.attn_norm(x))
    q = rope_neox(self.attn_q_norm(lin(self.attn_q, n).reshape(B, self.n_heads, HEAD_DIM)), pos, theta)
    k = rope_neox(self.attn_k_norm(lin(self.attn_k, n).reshape(B, self.n_kv, HEAD_DIM)), pos, theta)
    v = lin(self.attn_v, n).reshape(B, self.n_kv, HEAD_DIM)
    # block K/V go through the f16 cache in llama.cpp: round them the same way
    k, v = k.cast(dtypes.half).float(), v.cast(dtypes.half).float()
    if not DFLASH_ATTN_REF:
      o = ring_attention(q.reshape(B, -1), rk, rv, k.reshape(B, -1), v.reshape(B, -1), pos0, self.n_kv)
      return self._rest(x, o, dyn)
    return self._rest(x, self._attn_ref(q, k, v, pos, pos0, rk, rv), dyn)

  def _attn_ref(self, q:Tensor, k:Tensor, v:Tensor, pos:Tensor, pos0:Tensor, rk:Tensor, rv:Tensor) -> Tensor:
    """the same attention in tinygrad ops (reference for the dflash_attn kernel; ~1.6 ms/layer at RING=4096)"""
    B = int(q.shape[0]); G = self.n_heads // self.n_kv
    # the ring slot j holds the latest position <= pos0-1 congruent to j; visible to query q_pos iff it is >= 0 and in the window
    j = Tensor.arange(RING, dtype=dtypes.int32)
    last = pos0.reshape(1) - 1
    kp = last - ((last - j + RING) % RING)                                                        # (RING,)
    ok = (kp.reshape(1, RING) >= 0) & ((pos.reshape(B, 1) - kp.reshape(1, RING)) < WINDOW)          # (B, RING)
    keys = rk.reshape(RING, self.n_kv, HEAD_DIM).float().permute(1, 0, 2).cat(k.permute(1, 0, 2), dim=1)   # (n_kv, RING+B, 128)
    vals = rv.reshape(RING, self.n_kv, HEAD_DIM).float().permute(1, 0, 2).cat(v.permute(1, 0, 2), dim=1)
    qg = q.reshape(B, self.n_kv, G, HEAD_DIM).permute(1, 2, 0, 3)                  # (n_kv, G, B, 128): q head h uses kv head h // G
    s = (qg @ keys.unsqueeze(1).transpose(-1, -2)) * (HEAD_DIM ** -0.5)            # (n_kv, G, B, RING+B)
    mask = ok.cat(Tensor.ones(B, B, dtype=dtypes.bool, device=q.device), dim=1)     # the block is non-causal: all B rows visible
    s = mask.reshape(1, 1, B, RING + B).where(s, float("-inf"))
    return (s.softmax(-1) @ vals.unsqueeze(1)).permute(2, 0, 1, 3).reshape(B, self.n_heads * HEAD_DIM)

  def _rest(self, x:Tensor, o:Tensor, dyn:Tensor) -> Tensor:
    x = x + self.attn_conv.finish(lin(self.attn_output, o), dyn)
    n, dyn = self.ffn_conv.prepare(self.ffn_norm(x))
    m = lin(self.ffn_down, lin(self.ffn_gate, n).silu() * lin(self.ffn_up, n))
    return x + self.ffn_conv.finish(m, dyn)

class DFlash2Module:
  def __init__(self, kv:dict):
    dim, hidden = kv['dflash.embedding_length'], kv['dflash.feed_forward_length']
    n_heads, n_kv = kv['dflash.attention.head_count'], kv['dflash.attention.head_count_kv']
    assert kv['dflash.attention.key_length'] == HEAD_DIM and kv['dflash.attention.sliding_window'] == WINDOW
    assert not kv.get('dflash.attention.causal', False), "the port assumes non-causal block attention"
    eps = kv['dflash.attention.layer_norm_rms_epsilon']
    self.dim, self.n_kv, self.theta = dim, n_kv, float(kv['dflash.rope.freq_base'])
    self.block_size = kv['dflash.block_size']
    self.top_k, self.rank = kv['dflash.selector_top_k'], kv['dflash.selector_rank']
    self.target_layers = tuple(int(i) - 1 for i in kv['dflash.target_layers'])  # llama.cpp layer-input ids -> 0-indexed block outputs
    self.mask_id = kv.get('tokenizer.ggml.mask_token_id', 248070)
    self.fc = Linear(dim * len(self.target_layers), dim, bias=False)
    self.hidden_norm, self.norm = nn.RMSNorm(dim, eps), nn.RMSNorm(dim, eps)
    self.layers = [DFlashLayer(dim, n_heads, n_kv, hidden, eps, kv['dflash.conv_kernel_size'], kv['dflash.conv_group_size'])
                   for _ in range(kv['dflash.block_count'])]
    self.sel_proj = Linear(dim, self.rank, bias=False)

  def init_rings(self, device:str):
    if not hasattr(self, "rings"):
      self.rings = [tuple(Tensor.zeros(RING, self.n_kv * HEAD_DIM, dtype=dtypes.half, device=device).contiguous().realize() for _ in range(2))
                    for _ in self.layers]

  def inject(self, hs:list[Tensor], start:Tensor) -> list[tuple[Tensor, Tensor]]:
    """hs: the target's residual stream after each of target_layers, (1, T, dim) each; start (1,) int32 position of row 0.
    writes every row's context K/V into the rings; returns the rings ordered after the writes (read them through these)"""
    T = int(hs[0].shape[1])
    g = self.hidden_norm(lin(self.fc, hs[0].cat(*hs[1:], dim=-1).reshape(T, -1).float()))
    pos = start.reshape(1) + Tensor.arange(T, dtype=dtypes.int32)
    return [ring_write(rk, rv, *layer.context_kv(g, pos, self.theta), start) for layer, (rk, rv) in zip(self.layers, self.rings)]

  def draft(self, emb:Tensor, pos0:Tensor, rings:list[tuple[Tensor, Tensor]]) -> Tensor:
    """emb (B, dim) target embeddings of [anchor, MASK x D] at positions pos0.. -> final-normed hidden (B, dim)"""
    B = int(emb.shape[0])
    pos = pos0.reshape(1) + Tensor.arange(B, dtype=dtypes.int32)
    x = emb.float()
    for layer, (rk, rv) in zip(self.layers, rings): x = layer(x, pos, pos0, rk, rv, self.theta)
    return self.norm(x)

  def select(self, h:Tensor, logits:Tensor, anchor:Tensor) -> Tensor:
    """the lattice walk over the top-16 of each row (dflash_sel): h (D, dim) final-normed rows 1..D, logits (D, vocab) -> (D,) int32"""
    from tinygrad.llm.dflash_sel import select_fused
    D, V = int(h.shape[0]), int(logits.shape[-1])
    hp = lin(self.sel_proj, h).float()
    return select_fused(logits.reshape(D, V).float(), hp, self.sel_pred_raw, self.sel_succ_raw, anchor, D, V, self.top_k, self.rank)

def _remap(k:str) -> str:
  k = k.replace("enc.output_norm.", "hidden_norm.")
  if not k.startswith("hidden_norm."): k = k.replace("output_norm.", "norm.")
  for a, b in (("selector_hidden.", "sel_proj."), ("attn_conv_base", "attn_conv.base"), ("attn_conv_proj.", "attn_conv.proj."),
               ("ffn_conv_base", "ffn_conv.base"), ("ffn_conv_proj.", "ffn_conv.proj.")): k = k.replace(a, b)
  if k.startswith("blk."):
    i, _, tail = k[4:].partition(".")
    k = f"layers.{i}.{tail}"
  return k

def default_path() -> str:
  """DFLASH=path to a DFlash2 drafter GGUF (0/unset: off)"""
  p = os.environ.get("DFLASH", "")
  return "" if p in ("", "0") else os.path.expanduser(p)

def load_dflash(path:str, device:str) -> DFlash2Module:
  raw:dict = {}
  kv, sd = gguf_load(path, raw_out=raw)
  assert kv.get("general.architecture") == "dflash", kv.get("general.architecture")
  m = DFlash2Module(kv)
  sd, raw = {_remap(k): v for k, v in sd.items()}, {_remap(k): v for k, v in raw.items()}
  # the selector codebooks are only read as ggml bytes by the walk kernel (Q4_K): no 254 MB dequantized tables
  cb = {k: raw.pop(k) for k in ("selector_predecessor.weight", "selector_successor.weight")}
  for k in cb: sd.pop(k, None)
  assert all(typ == 12 for _, typ, _ in cb.values()), "dflash_sel reads Q4_K codebooks only"
  nn.state.load_state_dict(m, {k: v.to(device) for k, v in sd.items()}, verbose=False, consume=True, realize=False)
  # set after the state dict load (which expects every Tensor attribute to come from the file)
  m.sel_pred_raw = cb["selector_predecessor.weight"][0].to(device).contiguous().realize()
  m.sel_succ_raw = cb["selector_successor.weight"][0].to(device).contiguous().realize()
  from tinygrad.llm import amd_gemv
  m._ggml_raw = {k: amd_gemv.GGMLWeight(t.to(device).contiguous().realize(), typ, *shape) for k, (t, typ, shape) in raw.items()}
  attached = amd_gemv.attach(m)
  Tensor.realize(*[p for p in nn.state.get_parameters(m) if p.numel() < 2**20])
  m.init_rings(device)
  if DEBUG >= 1: print(f"dflash: {path} layers={len(m.layers)} block={m.block_size} target blocks={m.target_layers} gemv-attached={len(attached)}")
  return m
