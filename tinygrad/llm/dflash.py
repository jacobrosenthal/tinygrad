"""DFlash2 block-diffusion draft (GGUF `general.architecture = dflash`).

Shares the target embedding and lm_head. Target hidden states from `dflash.target_layers`
are fused with `fc` and injected as K/V into every draft layer. Block attention is
non-causal; grouped two-tap convs wrap attn/FFN; the selector walks top-k candidates.
"""
from __future__ import annotations
import os, pathlib
from tinygrad import Tensor, nn, dtypes, TinyJit
from tinygrad.nn import Linear
from tinygrad.helpers import DEBUG, getenv
from tinygrad.llm.gguf import gguf_load
from tinygrad.llm.model import apply_rope, precompute_freqs_cis

class GroupedConv:
  """out[t,c] = (base[0,c]+δ0[t,g(c)]) * x[t,c] + (base[1,c]+δ1[t,g(c)]) * x[t-1,c] * [t>=1]."""
  def __init__(self, dim:int, taps:int, group_size:int, block_size:int):
    assert dim % group_size == 0 and taps == 2
    self.dim, self.taps, self.group_size, self.block_size = dim, taps, group_size, block_size
    self.num_groups = dim // group_size
    self.base = Tensor.zeros(2, taps, dim)  # [in/out, tap, C]; tap 0 is 1 at init
    self.proj = Linear(dim, 2 * taps * self.num_groups, bias=False)

  def _mix(self, x:Tensor, delta:Tensor, side:int) -> Tensor:
    # x: (1, T, C), delta: (1, T, taps, G), base[side]: (taps, C)
    B, T, C = x.shape
    g = self.num_groups
    xs = x.reshape(B, T, g, self.group_size)
    coeff = self.base[side].reshape(1, 1, self.taps, g, self.group_size) + delta.unsqueeze(-1)
    out = coeff[:, :, 0] * xs
    prev = xs[:, :-1].pad((None, (1, 0), None, None))
    pos = Tensor.arange(T, dtype=dtypes.int32).reshape(1, T, 1, 1)
    out = out + coeff[:, :, 1] * prev * (pos >= 1).reshape(1, T, 1, 1)
    return out.reshape(B, T, C)

  def prepare(self, x:Tensor) -> tuple[Tensor, Tensor]:
    d = self.proj(x).reshape(*x.shape[:-1], 2, self.taps, self.num_groups)
    return self._mix(x, d[..., 0, :, :], 0), d[..., 1, :, :]

  def finish(self, y:Tensor, d1:Tensor) -> Tensor: return self._mix(y, d1, 1)

class DFlashLayer:
  def __init__(self, dim:int, n_heads:int, n_kv:int, head_dim:int, hidden:int, eps:float,
               taps:int, group_size:int, block_size:int, window:int, max_ctx:int, rope_theta:float):
    self.dim, self.n_heads, self.n_kv, self.head_dim = dim, n_heads, n_kv, head_dim
    self.window, self.max_ctx, self.eps = window, max_ctx, eps
    self.attn_norm, self.ffn_norm = nn.RMSNorm(dim, eps), nn.RMSNorm(dim, eps)
    self.attn_q = Linear(dim, n_heads * head_dim, bias=False)
    self.attn_k = Linear(dim, n_kv * head_dim, bias=False)
    self.attn_v = Linear(dim, n_kv * head_dim, bias=False)
    self.attn_output = Linear(n_heads * head_dim, dim, bias=False)
    self.attn_q_norm, self.attn_k_norm = nn.RMSNorm(head_dim, eps), nn.RMSNorm(head_dim, eps)
    self.ffn_gate = Linear(dim, hidden, bias=False)
    self.ffn_up = Linear(dim, hidden, bias=False)
    self.ffn_down = Linear(hidden, dim, bias=False)
    self.attn_conv = GroupedConv(dim, taps, group_size, block_size)
    self.ffn_conv = GroupedConv(dim, taps, group_size, block_size)

  def _init_state(self, x:Tensor):
    if hasattr(self, "freqs_cis"): return
    self.freqs_cis = precompute_freqs_cis(self.head_dim, self.max_ctx, 10000000.0, device=x.device)
    self.ctx_k: Tensor|None = None
    self.ctx_v: Tensor|None = None

  def inject_kv(self, ctx:Tensor, pos:int):
    """keep the last fused target row as a single context K/V (full 4k draft cache hangs the GPU)."""
    self._init_state(ctx)
    row = ctx[:, -1:, :]
    T, p = 1, pos + int(ctx.shape[1]) - 1
    k = self.attn_k_norm(self.attn_k(row).reshape(1, T, self.n_kv, self.head_dim)).transpose(1, 2)
    v = self.attn_v(row).reshape(1, T, self.n_kv, self.head_dim).transpose(1, 2)
    self.ctx_k, self.ctx_v = apply_rope(k, self.freqs_cis[p:p+1]).contiguous(), v.contiguous()
    Tensor.realize(self.ctx_k, self.ctx_v)

  def __call__(self, x:Tensor, start_pos:int) -> Tensor:
    self._init_state(x)
    B, T, _ = x.shape
    h = x
    n, a1 = self.attn_conv.prepare(self.attn_norm(x))
    q = self.attn_q_norm(self.attn_q(n).reshape(B, T, self.n_heads, self.head_dim)).transpose(1, 2)
    k = self.attn_k_norm(self.attn_k(n).reshape(B, T, self.n_kv, self.head_dim)).transpose(1, 2)
    v = self.attn_v(n).reshape(B, T, self.n_kv, self.head_dim).transpose(1, 2)
    q = apply_rope(q, self.freqs_cis[start_pos:start_pos+T])
    k = apply_rope(k, self.freqs_cis[start_pos:start_pos+T])
    if self.ctx_k is not None:
      k, v = self.ctx_k.cat(k, dim=2), self.ctx_v.cat(v, dim=2)
    attn = q.scaled_dot_product_attention(k, v, enable_gqa=True)
    a = self.attn_output(attn.transpose(1, 2).reshape(B, T, -1))
    x = h + self.attn_conv.finish(a, a1)
    h = x
    n, f1 = self.ffn_conv.prepare(self.ffn_norm(x))
    if hasattr(self.ffn_down, "_ggml"):
      from tinygrad.llm import amd_gemv
      f = self.ffn_down(amd_gemv.silu_mul_quant(self.ffn_gate(n), self.ffn_up(n)))
    else:
      f = self.ffn_down(self.ffn_gate(n).silu().contiguous() * self.ffn_up(n))
    return h + self.ffn_conv.finish(f, f1)

class DFlash2Module:
  def __init__(self, kv:dict, max_ctx:int):
    dim = kv['dflash.embedding_length']
    hidden = kv['dflash.feed_forward_length']
    n_heads, n_kv = kv['dflash.attention.head_count'], kv['dflash.attention.head_count_kv']
    head_dim = kv['dflash.attention.key_length']
    eps = kv['dflash.attention.layer_norm_rms_epsilon']
    n_layers = kv['dflash.block_count']
    self.block_size = int(getenv("DFLASH_BLOCK", 0) or min(4, kv['dflash.block_size']))
    self.trained_block = kv['dflash.block_size']
    taps, gsz = kv['dflash.conv_kernel_size'], kv['dflash.conv_group_size']
    window = kv['dflash.attention.sliding_window']
    rope_theta = kv['dflash.rope.freq_base']
    self.top_k = kv['dflash.selector_top_k']
    self.rank = kv['dflash.selector_rank']
    self.target_layers = tuple(int(i) for i in kv['dflash.target_layers'])
    self.mask_id = kv.get('tokenizer.ggml.mask_token_id', 248070)
    self.dim = dim
    self.fc = Linear(dim * len(self.target_layers), dim, bias=False)
    self.hidden_norm, self.norm = nn.RMSNorm(dim, eps), nn.RMSNorm(dim, eps)
    self.layers = [DFlashLayer(dim, n_heads, n_kv, head_dim, hidden, eps, taps, gsz, self.trained_block, window, max_ctx, rope_theta)
                   for _ in range(n_layers)]
    self.sel_proj = Linear(dim, self.rank, bias=False)
    vocab = len(kv['tokenizer.ggml.tokens'])
    self.sel_pred, self.sel_succ = nn.Embedding(vocab, self.rank), nn.Embedding(vocab, self.rank)
    self.draft_pos = 0

  def reset(self):
    self.draft_pos = 0
    for layer in self.layers:
      layer.ctx_k = layer.ctx_v = None

  def fuse(self, hcat:Tensor) -> Tensor:
    """hcat (..., n_layers*dim) -> fused (..., dim)."""
    return self.hidden_norm(self.fc(hcat.float()))

  def inject(self, fused:Tensor, pos:int):
    """fused (1, T, D) or (1, D). writes T rows at pos.."""
    if fused.ndim == 2: fused = fused.unsqueeze(1)
    T = int(fused.shape[1])
    for layer in self.layers: layer.inject_kv(fused, pos)
    self.draft_pos = pos + T

  def draft(self, embeds:Tensor, start_pos:int) -> Tensor:
    x = embeds.float()
    for layer in self.layers: x = layer(x, start_pos)
    return self.norm(x)

  def select(self, h:Tensor, logits:Tensor, anchor:int) -> list[int]:
    """greedy path through top-k candidates. h/logits (T, ...)."""
    T = int(h.shape[-2] if h.ndim == 3 else h.shape[0])
    h = h.reshape(T, -1)
    logits = logits.reshape(T, -1)
    vals, ids = logits.topk(self.top_k, dim=-1)  # (T, K)
    hp = self.sel_proj(h)  # (T, R)
    Tensor.realize(vals, ids, hp)
    ids_np = ids.numpy().astype(int)
    un = vals.numpy()
    hp_np = hp.numpy()
    # walk
    path = []
    pred = anchor
    import numpy as np
    for t in range(T):
      cids = ids_np[t]
      A = self.sel_pred(Tensor([pred], dtype=dtypes.int32)).realize().numpy().reshape(-1)  # (R,)
      B = self.sel_succ(Tensor(cids.tolist(), dtype=dtypes.int32)).realize().numpy()  # (K, R)
      gate = A * hp_np[t]
      scores = un[t] + B @ gate
      j = int(scores.argmax())
      tok = int(cids[j])
      path.append(tok)
      pred = tok
    return path

def remap_dflash_keys(sd:dict) -> dict:
  out = {}
  for k, v in sd.items():
    k = k.replace("enc.output_norm.", "hidden_norm.")
    k = k.replace("output_norm.", "norm.") if not k.startswith("hidden_norm.") else k
    k = k.replace("selector_hidden.", "sel_proj.")
    k = k.replace("selector_predecessor.", "sel_pred.")
    k = k.replace("selector_successor.", "sel_succ.")
    k = k.replace("attn_conv_base", "attn_conv.base")
    k = k.replace("attn_conv_proj.", "attn_conv.proj.")
    k = k.replace("ffn_conv_base", "ffn_conv.base")
    k = k.replace("ffn_conv_proj.", "ffn_conv.proj.")
    if k.startswith("blk."):
      rest = k[4:]
      i, _, tail = rest.partition(".")
      k = f"layers.{i}.{tail}"
    out[k] = v
  return out

def default_path() -> str:
  env = os.environ.get("DFLASH", "0")
  if env in ("0", "false", "False"): return ""
  if env not in ("1", "true", "True"): return env
  for p in ("/home/quentin/models/dflash2-incoai-Q4_K_M.gguf",
            os.path.expanduser("~/models/dflash2-incoai-Q4_K_M.gguf")):
    if pathlib.Path(p).is_file(): return p
  return ""

def load_dflash(path:str, max_ctx:int) -> tuple[DFlash2Module, dict, dict]:
  raw: dict = {}
  kv, sd = gguf_load(path, raw_out=raw)
  assert kv.get("general.architecture") == "dflash", kv.get("general.architecture")
  sd = remap_dflash_keys(sd)
  raw = remap_dflash_keys(raw)
  m = DFlash2Module(kv, max_ctx)
  nn.state.load_state_dict(m, sd, verbose=False, consume=True, realize=False)
  if DEBUG >= 1: print(f"dflash: {path} layers={kv['dflash.block_count']} block={m.block_size} "
                       f"target_layers={m.target_layers}")
  return m, kv, raw
