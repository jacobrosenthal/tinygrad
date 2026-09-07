from __future__ import annotations
import enum, functools, itertools, json, math, pathlib, re
from dataclasses import dataclass, replace
from typing import Any, Callable
from tinygrad import Tensor, nn, UOp, TinyJit, getenv, function, dtypes, Device
from tinygrad.llm.kernels.amd import Linear, ExpertWeights, fp8_matmul, gated_delta_prefill, flash_attention, amd_custom_kernels_supported
from tinygrad.llm.gguf import gguf_parse, gguf_shard, GGUFPackedTable, _GGML_QUANT, _load_raw
from tinygrad.llm.hf import hf_load
from tinygrad.uop.ops import resolve, smax, ssimplify
from tinygrad.helpers import unwrap, round_up, get_child, DEBUG, Timing

StartPos = tuple[int|UOp, ...]

class ExpertGating(enum.IntEnum):
  SOFTMAX = 1
  SIGMOID = 2
  SOFTMAX_WEIGHT = 3  # softmax over the top-k selected logits
  SQRT_SOFTPLUS = 4

@dataclass(frozen=True)
class YaRNConfig:
  factor: float
  orig_ctx_len: int
  beta_fast: float
  beta_slow: float

@functools.cache
def precompute_freqs_cis(dim: int, end: int, theta: float = 10000.0, device:str|tuple[str, ...]|None=None, yarn:YaRNConfig|None=None) -> Tensor:
  freqs = 1.0 / (theta ** (Tensor.arange(0, dim, 2) / dim))
  concentration = 1.0
  if yarn is not None and yarn.factor > 1.0:
    concentration = 0.1 * math.log(yarn.factor) + 1.0
    d_half = dim // 2
    low = max(0, math.floor(d_half * math.log(yarn.orig_ctx_len / (yarn.beta_fast * 2 * math.pi)) / math.log(theta)))
    high = min(dim-1, math.ceil(d_half * math.log(yarn.orig_ctx_len / (yarn.beta_slow * 2 * math.pi)) / math.log(theta)))
    interp = 1 - ((Tensor.arange(d_half).float() - low) / max(0.001, high-low)).clamp(0, 1)
    freqs = freqs * interp + (freqs / yarn.factor) * (1 - interp)
  freqs = Tensor.arange(end).unsqueeze(dim=1) * freqs.unsqueeze(dim=0)
  return (freqs.cos() * concentration).cat(freqs.sin() * concentration, dim=-1).clone(device)

def gated_activation(gate:Tensor, up:Tensor, config:TransformerConfig) -> Tensor:
  alpha, limit, up_bias, situ = config.swiglu_alpha, config.swiglu_limit, config.swiglu_up_bias, config.situ
  if situ is not None: return (gate / situ[0]).tanh() * situ[0] * gate.sigmoid() * (up / situ[1]).tanh() * situ[1]
  if limit is not None and limit > 0: gate, up = gate.clamp(max_=limit), up.clamp(-limit, limit)
  # TODO: remove the need for this contiguous
  return gate * (gate * alpha).sigmoid().contiguous() * (up + up_bias)

def apply_rope(x:Tensor, freqs_cis:Tensor, interleaved:bool=False) -> Tensor:
  assert x.shape[-1] % 2 == 0
  if interleaved: x = x.rearrange("b h t (d two) -> b h t (two d)", two=2)
  cos, sin = freqs_cis.unsqueeze(-3).chunk(2, dim=-1)
  x1, x2 = x.chunk(2, dim=-1)
  return (x1 * cos - x2 * sin).cat(x2 * cos + x1 * sin, dim=-1)

def _update_cache(cache:Tensor, value:Tensor, start_pos:StartPos, dim:int) -> Tensor:
  def store(c:Tensor, v:Tensor, pos:int|UOp) -> UOp:
    return c.shrink(tuple((pos, pos+v.shape[dim]) if i == dim else None for i in range(c.ndim))).uop.store(v.cast(c.dtype).uop)
  stores = ([store(cache, value, start_pos[0])] if len(start_pos) == 1 else [store(cache[b:b+1], value[b:b+1], p) for b, p in enumerate(start_pos)])
  return Tensor(cache.uop.after(*stores))

def _cache_prefix(cache:Tensor, start_pos:StartPos, n_tokens:int|UOp, dim:int) -> Tensor:
  end = ssimplify(smax(start_pos) + n_tokens)
  cache = cache.shrink(tuple((0, end) if i == dim else None for i in range(cache.ndim)))
  if len(start_pos) > 1:
    keys = Tensor.arange(end).reshape(tuple(end if i == dim else 1 for i in range(cache.ndim)))
    ends = (Tensor.stack(*(Tensor(p) for p in start_pos)) + Tensor(n_tokens)).reshape(len(start_pos), *((1,) * (cache.ndim-1)))
    cache = (keys < ends).where(cache, 0)  # future entries can be uninitialized, including NaNs
  return cache

def _causal_mask(x:Tensor, start_pos:StartPos, window:int=0) -> Tensor|None:
  T = x.shape[1]
  if len(start_pos) == 1 and not resolve(T != 1) and not window: return None
  q_pos = Tensor.stack(*(Tensor(p) for p in start_pos)).reshape(-1, 1, 1, 1) + Tensor.arange(T).reshape(1, 1, T, 1)
  k_pos = Tensor.arange(ssimplify(smax(start_pos) + T)).reshape(1, 1, 1, -1)
  valid = k_pos <= q_pos
  if window: valid = valid & (k_pos > q_pos-window)
  return valid.where(0.0, -math.inf).cast(x.dtype)

def permute_rope(w:Tensor, n_heads:int, rope_dim:int) -> Tensor:
  x = w.reshape(n_heads, w.shape[0]//n_heads, -1)
  prefix = x.shape[1]-rope_dim
  return x[:, :prefix].cat(x[:, prefix:].rearrange("n (h two) d -> n (two h) d", two=2), dim=1).reshape(w.shape)

def pairwise_topk(x: Tensor, k: int) -> tuple[Tensor, Tensor]:
  n = x.shape[-1]
  vals = Tensor.arange(n).reshape(1,1,n).cast(x.dtype).expand(x.shape)
  cmp = (x.unsqueeze(-1) > x.unsqueeze(-2)) | ((x.unsqueeze(-1) == x.unsqueeze(-2)) & \
    (Tensor.arange(n).reshape(1,1,n,1) < Tensor.arange(n).reshape(1,1,1,n)))
  sel = x.const_like(0).scatter(-1, cmp.sum(axis=-1).cast('int32'), vals)[:,:,n-k:].cast('int32')
  return x.gather(-1, sel), sel

def short_conv(state:Tensor, x:Tensor, weight:Tensor, initial:Tensor, dilation:int=1) -> tuple[Tensor, UOp]:
  assert state.shape[1] == (weight.shape[1]-1)*dilation, f"state has {state.shape[1]} rows, expected {(weight.shape[1]-1)*dilation}"
  # assemble the conv window in a static-size buffer: [state | x rows | zero-pad], state is zeroed when initial
  T, T_pad = x.shape[1], x.max_shape[1]
  window = initial.where(0, state).cat(x.cast(state.dtype), dim=1).pad_to((x.shape[0], state.shape[1] + T_pad, x.shape[-1])).contiguous()
  # the last state.shape[1] rows before the padding become the next state
  store = state.uop.store(window[:, T:T+state.shape[1]].uop)
  return functools.reduce(lambda a,b: a+b, (window[:, i*dilation:i*dilation+T_pad] * weight[:, i] for i in range(weight.shape[1]))).silu(), store

@dataclass(frozen=True)
class SSMConfig:
  conv_kernel: int
  state_size: int
  group_count: int
  time_step_rank: int
  inner_size: int
  kda: bool = False
  gate_lower_bound: float|None = None  # kda: bounded decay gate
  full_rank_gate: bool = False
  silu_gate: bool = False

@dataclass(frozen=True)
class HCConfig:  # manifold-constrained hyper-connections: count residual streams, mixed by a doubly stochastic matrix
  count: int
  sinkhorn_iters: int
  eps: float
  low_rank: int = 0

@dataclass(frozen=True)
class PLEConfig:
  layer: int
  head_dim: int
  multipliers: tuple[int, ...]
  vocab_sizes: tuple[int, ...]
  eos: int
  conv_kernel: int

@dataclass(frozen=True)
class IndexerConfig:  # select top_k tokens by scoring individual keys or pools of kpool keys
  n_heads: int
  head_dim: int
  top_k: int
  kpool: int = 1
  norm_eps: float = 1e-6
  rope_dim: int = 0
  rope_interleave: bool = True
  msa: bool = False
  qsa: bool = False

@dataclass(frozen=True)
class TransformerConfig:
  num_blocks: int
  dim: int
  hidden_dim: int
  n_heads: int
  n_kv_heads: int
  norm_eps: float
  vocab_size: int
  head_dim: int
  rope_theta: float
  rope_dim: int
  v_head_dim: int
  yarn: YaRNConfig|None = None
  max_context: int = 0
  qk_norm: int = 0
  num_experts: int = 0
  num_experts_per_tok: int = 0
  norm_topk_prob: bool = False
  expert_gating_func: ExpertGating = ExpertGating.SOFTMAX
  q_lora_rank: int = 0
  kv_lora_rank: int = 0
  shared_expert_dim: int = 0
  ssm_layers: tuple[bool, ...] = ()
  attn_output_gate: bool = False
  attn_output_bias: bool = False
  attn_sinks: bool = False
  ssm: SSMConfig|None = None
  shared_expert_gate: bool = True
  leading_dense_blocks: int = 0
  dense_hidden_dim: int = 0
  routed_scaling_factor: float = 1.0
  qkv_bias: bool = False
  expert_bias: bool = False
  expert_proj_bias: bool = False
  swiglu_alpha: float = 1.0
  swiglu_limit: float|None = None
  swiglu_up_bias: float = 0.0
  sliding_window: int = 0
  sliding_window_pattern: int = 0
  hc: HCConfig|None = None
  indexer: IndexerConfig|None = None
  ple: PLEConfig|None = None
  indexer_shared: tuple[bool, ...] = ()
  rope_interleave: bool = False
  expert_latent_dim: int = 0
  situ: tuple[float, float]|None = None
  attn_res_block_size: int = 0
  attn_res_new_block: bool = False
  rope_sections: tuple[int, ...]|None = None  # m-rope (t, h, w, extra) pair counts per section, interleaved (Qwen3-VL / Qwen3.5)

class AttentionResidual:
  def __init__(self, config:TransformerConfig, new_block:bool=False):
    self.weight, self.norm_eps, self.new_block = Tensor.zeros(config.dim), config.norm_eps, new_block

  def mix(self, xs:Tensor) -> Tensor:
    scores = (xs.rmsnorm(eps=self.norm_eps) * self.weight).sum(-1, keepdim=True)
    return (scores.softmax(2) * xs).sum(2)  # xs: (B, T, N, D) streams: (B, T, D)

  def __call__(self, xs:Tensor, sublayer:Callable[[Tensor], tuple[Tensor, Tensor|None]]) -> tuple[Tensor, Tensor|None]:
    out, aux = sublayer(self.mix(xs))
    # (B, T, N+1, D) if new_block else (B, T, N, D)
    return (xs.cat(out.unsqueeze(2), dim=2) if self.new_block else xs[:, :, :-1].cat(xs[:, :, -1:] + out.unsqueeze(2), dim=2)), aux

class HyperConnection:
  def __init__(self, config:TransformerConfig):
    self.count, self.eps, self.iters, self.norm_eps = (hc:=unwrap(config.hc)).count, hc.eps, hc.sinkhorn_iters, config.norm_eps
    self.fn = Linear(self.count * config.dim, (2 + self.count) * self.count, bias=False)
    self.base, self.scale = {"weight": Tensor.zeros((2 + self.count) * self.count)}, {"weight": Tensor.zeros(3)}

  def __call__(self, xs:Tensor, sublayer:Callable[[Tensor], tuple[Tensor, Tensor|None]]) -> tuple[Tensor, Tensor|None]:
    """mHC: the sublayer sees a pre-weighted sum of the (B, T, hc, D) streams, its output is added back by post onto the streams mixed by comb"""
    base, scale, mix = self.base["weight"], self.scale["weight"], self.fn(xs.flatten(2).rmsnorm(eps=self.norm_eps))
    pre  = (mix[..., :self.count] * scale[0] + base[:self.count]).sigmoid() + self.eps
    post = (mix[..., self.count:2*self.count] * scale[1] + base[self.count:2*self.count]).sigmoid() * 2
    comb = (mix[..., 2*self.count:] * scale[2] + base[2*self.count:]).reshape(*mix.shape[:-1], self.count, self.count).softmax(-1) + self.eps
    # sinkhorn: normalize the columns then the rows, alternating, to make comb doubly stochastic
    for i in range(2 * self.iters - 1): comb = comb / (comb.sum(-1 if i % 2 else -2, keepdim=True) + self.eps)
    out, aux = sublayer((xs * pre.unsqueeze(-1)).sum(2))
    return out.unsqueeze(2) * post.unsqueeze(-1) + (comb.transpose(-1, -2) @ xs), aux

class GroupedRMSNorm:  # x: (B, T, count, dim), w: (count*dim,)
  def __init__(self, count:int, dim:int, eps:float): self.weight, self.eps = Tensor.zeros(count*dim), eps
  def __call__(self, x:Tensor) -> Tensor: return x.rmsnorm(eps=self.eps) * self.weight.reshape(x.shape[-2:])

class GatedResidual(HyperConnection):
  def __init__(self, config:TransformerConfig, inject:bool=True):
    self.count, self.dim, low_rank = (hc:=unwrap(config.hc)).count, config.dim, hc.low_rank
    self.norm = GroupedRMSNorm(self.count, self.dim, config.norm_eps)
    self.down, self.up = Linear(self.count*self.dim, low_rank, bias=False), Linear(low_rank, self.count*self.dim, bias=False)
    if inject: self.inject = Linear(self.count*self.dim, self.count, bias=False)

  def mix(self, xs:Tensor) -> tuple[Tensor, Tensor]:
    xn = self.norm(xs).flatten(2)
    return (self.up((self.down(xn) / self.count).silu()).sigmoid() * xn).reshape(xs.shape).mean(2), xn

  def __call__(self, xs:Tensor, sublayer:Callable[[Tensor], tuple[Tensor, Tensor|None]]) -> tuple[Tensor, Tensor|None]:
    mixed, xn = self.mix(xs)
    out, aux = sublayer(mixed)
    return xs + out.unsqueeze(2) * (self.inject(xn) / self.count).sigmoid().unsqueeze(-1) * 2, aux

class FFNBlock:
  def __init__(self, config:TransformerConfig):
    self.config = config

    # --- RMSNorms --------------------------------------------------------
    self.attn_norm: Callable[[Tensor], Tensor] = nn.RMSNorm(config.dim, config.norm_eps)
    self.ffn_norm:  Callable[[Tensor], Tensor] = nn.RMSNorm(config.dim, config.norm_eps)
    if config.hc is not None:
      hc = GatedResidual if config.hc.low_rank else HyperConnection
      self.hc_attn, self.hc_ffn = hc(config), hc(config)
      if config.hc.low_rank: self.attn_norm = self.ffn_norm = lambda x: x
    if config.ple is not None: self.ple = PLELayer(config)
    if config.attn_res_block_size:
      self.attn_res_score, self.ffn_res_score = AttentionResidual(config, config.attn_res_new_block), AttentionResidual(config)

    # --- feed-forward (MoE or dense) -------------------------------------
    if config.num_experts > 0:
      self.ffn_gate_inp = Linear(config.dim, config.num_experts, bias=config.expert_proj_bias)  # router
      if config.expert_bias: self.exp_probs_b = {"bias": Tensor.zeros(config.num_experts)}
      expert_dim = config.expert_latent_dim or config.dim
      self.ffn_gate_exps = ExpertWeights(config.num_experts, expert_dim, config.hidden_dim, bias=config.expert_proj_bias)
      self.ffn_up_exps = ExpertWeights(config.num_experts, expert_dim, config.hidden_dim, bias=config.expert_proj_bias)
      self.ffn_down_exps = ExpertWeights(config.num_experts, config.hidden_dim, expert_dim, bias=config.expert_proj_bias)
      if config.shared_expert_dim > 0:
        self.ffn_gate_shexp = Linear(config.dim, config.shared_expert_dim, bias=False)
        self.ffn_up_shexp = Linear(config.dim, config.shared_expert_dim, bias=False)
        self.ffn_down_shexp = Linear(config.shared_expert_dim, config.dim, bias=False)
        if config.shared_expert_gate: self.ffn_gate_inp_shexp = {"weight": Tensor.zeros(config.dim)}
      if config.expert_latent_dim:
        self.ffn_routed_down, self.ffn_routed_up = Linear(config.dim, expert_dim, bias=False), Linear(expert_dim, config.dim, bias=False)
        self.ffn_routed_norm = nn.RMSNorm(expert_dim, config.norm_eps)
    else:
      self.ffn_gate    = Linear(config.dim, config.hidden_dim, bias=False)
      self.ffn_up      = Linear(config.dim, config.hidden_dim, bias=False)
      self.ffn_down    = Linear(config.hidden_dim, config.dim, bias=False)

  def _feed_forward(self, x:Tensor) -> Tensor:
    if hasattr(self, 'ffn_gate_exps'):
      h = (self.ffn_routed_down(x) if self.config.expert_latent_dim else x).unsqueeze(2)  # (B, T, 1, D) - add expert dim for broadcasting
      logits = self.ffn_gate_inp(x)
      bias = self.exp_probs_b["bias"] if hasattr(self, 'exp_probs_b') else None
      gating, normalize_topk = self.config.expert_gating_func, self.config.norm_topk_prob
      # fast path: without selection bias, normalized SOFTMAX is equivalent to SOFTMAX_WEIGHT
      if gating == ExpertGating.SOFTMAX and bias is None and normalize_topk:
        gating, normalize_topk = ExpertGating.SOFTMAX_WEIGHT, False
      if   gating == ExpertGating.SOFTMAX_WEIGHT: scores = logits
      elif gating == ExpertGating.SOFTMAX:        scores = logits.softmax(-1)
      elif gating == ExpertGating.SIGMOID:        scores = logits.sigmoid()
      elif gating == ExpertGating.SQRT_SOFTPLUS:  scores = logits.softplus().sqrt()

      _, sel = pairwise_topk(scores if bias is None else scores + bias, self.config.num_experts_per_tok)
      probs = scores.gather(-1, sel)
      # SOFTMAX_WEIGHT applies softmax after top-k selection
      if gating == ExpertGating.SOFTMAX_WEIGHT: probs = probs.softmax(-1)
      if normalize_topk: probs = probs / probs.sum(axis=-1, keepdim=True)
      probs = probs * self.config.routed_scaling_factor
      gate, up = self.ffn_gate_exps(sel, h), self.ffn_up_exps(sel, h)
      x_down = self.ffn_down_exps(sel, gated_activation(gate, up, self.config).contiguous())  # ([ndev,] B, T, k, D)
      out = (x_down * probs.unsqueeze(-1)).sum(axis=-2)  # ([ndev,] B, T, D)
      if out.ndim == x.ndim + 1: out = out.sum(0)
      if self.config.expert_latent_dim: out = self.ffn_routed_up(self.ffn_routed_norm(out))
      if hasattr(self, 'ffn_gate_shexp'):
        shexp = self.ffn_down_shexp(gated_activation(self.ffn_gate_shexp(x), self.ffn_up_shexp(x), self.config).contiguous())
        if hasattr(self, 'ffn_gate_inp_shexp'): shexp = shexp * (x * self.ffn_gate_inp_shexp["weight"]).sum(axis=-1, keepdim=True).sigmoid()
        out = out + shexp
      return out
    if hasattr(self.ffn_down, "_ggml") and self._n_fused(x) and self._plain_swiglu():
      from tinygrad.llm import amd_gemv
      return self.ffn_down(amd_gemv.silu_mul_quant(self.ffn_gate(x), self.ffn_up(x)))
    return self.ffn_down(gated_activation(self.ffn_gate(x), self.ffn_up(x), self.config))

  # given the token-prefix match, return how much cached state this block can still reuse
  def _reusable_prefix_len(self, prefix_len:int, cached_len:int) -> int: return prefix_len
  def _init_state(self, x:Tensor): raise NotImplementedError
  def _attention(self, x:Tensor, start_pos:StartPos, idx_mask:Tensor|None=None, residual:Tensor|None=None,
                 n_tok:int|UOp|None=None) -> Tensor: raise NotImplementedError
  def _indexer_mask(self, x:Tensor, start_pos:StartPos, idx_mask:Tensor|None) -> Tensor|None:
    # a full indexer layer selects the top-k tokens for itself and the shared layers after it (MLATransformerBlock)
    return idx_mask

  def __call__(self, x: Tensor, start_pos: StartPos, idx_mask: Tensor|None=None, n_tok:int|UOp|None=None):
    self._init_state(x)
    if hasattr(self, 'ple'): self.ple._init_state(x)
    if self._decode_fused(x): return self._run_decode(x, start_pos, n_tok), idx_mask
    assert n_tok is None, "padded token chunks need the fused decode path"
    # we pass in the weights implicitly so we unpack the GGUF on the fly
    @function(precompile=True, allow_implicit=True)
    def _run(x:Tensor, start_pos:StartPos, idx_mask:Tensor|None):
      if hasattr(self, 'ple'): x = x + self.ple(x, start_pos)  # (B, T, hc, D)
      def attend(h:Tensor) -> tuple[Tensor, Tensor|None]:
        h = self.attn_norm(h)
        mask = self._indexer_mask(h, start_pos, idx_mask)
        return self._attention(h, start_pos, mask), mask
      res_attn = res_ffn = lambda xs, sublayer: (xs + (ret:=sublayer(xs))[0], ret[1])
      if self.config.hc is not None: res_attn, res_ffn = self.hc_attn, self.hc_ffn
      elif self.config.attn_res_block_size: res_attn, res_ffn = self.attn_res_score, self.ffn_res_score
      x, idx_mask = res_attn(x, attend)
      out = res_ffn(x, lambda h: (self._feed_forward(self.ffn_norm(h)), None))[0].contiguous()
      return (out, idx_mask) if idx_mask is not None else out
    out = _run(x, start_pos, idx_mask)
    return out if isinstance(out, tuple) else (out, None)

  # number of tokens x holds if it is a batch the fused AMD kernels take (B=1, T <= MAX_T), else 0
  @staticmethod
  def _n_fused(x:Tensor) -> int:
    from tinygrad.llm.amd_gemv import fused_T
    return x.shape[1] if x.shape[0] == 1 and isinstance(x.shape[1], int) and fused_T(x.shape[1]) else 0
  # decode of up to MAX_T tokens with the packed-weight kernels: no function boundary (it copies in and out), residual adds fused into
  # the gemv epilogues. n_tok (runtime) is the number of valid tokens of a padded chunk
  def _decode_fused(self, x:Tensor) -> bool:
    return bool(self._n_fused(x)) and isinstance(x.device, str) and self._plain_swiglu() and self.config.hc is None and \
      not self.config.attn_res_block_size and not hasattr(self, 'ple') and getattr(self, 'indexer', None) is None and \
      hasattr(self.ffn_down, "_ggml") and hasattr(self.attn_output_linear(), "_ggml")
  # silu(gate) * up, the only activation the fused kernels implement
  def _plain_swiglu(self) -> bool:
    c = self.config
    return c.swiglu_alpha == 1.0 and not c.swiglu_limit and c.swiglu_up_bias == 0.0 and c.situ is None
  def attn_output_linear(self) -> Linear: return self.attn_output
  def _run_decode(self, x:Tensor, start_pos:StartPos, n_tok:int|UOp|None=None) -> Tensor:
    from tinygrad.llm.amd_gemv import linear_decode, linear_decode_multi, silu_mul_quant
    h = self._attention(self.attn_norm(x), start_pos, residual=x, n_tok=n_tok)
    xn = self.ffn_norm(h)
    gate, up = linear_decode_multi([self.ffn_gate, self.ffn_up], xn)
    return linear_decode(self.ffn_down, silu_mul_quant(gate, up), residual=h)

class TransformerBlock(FFNBlock):
  def __init__(self, config:TransformerConfig):
    super().__init__(config)
    assert config.v_head_dim == config.head_dim, "TransformerBlock requires v_head_dim == head_dim"

    # --- attention projections (all linear, bias-free) ------------------
    q_proj_out       = config.head_dim * config.n_heads * (2 if config.attn_output_gate else 1)
    kv_proj_out      = config.head_dim * config.n_kv_heads
    self.attn_q      = Linear(config.dim, q_proj_out,  bias=config.qkv_bias)
    self.attn_k      = Linear(config.dim, kv_proj_out, bias=config.qkv_bias)
    self.attn_v      = Linear(config.dim, kv_proj_out, bias=config.qkv_bias)
    self.attn_output = Linear(config.head_dim * config.n_heads, config.dim, bias=config.attn_output_bias)
    if config.qk_norm: self.attn_q_norm, self.attn_k_norm = nn.RMSNorm(config.qk_norm, config.norm_eps), nn.RMSNorm(config.qk_norm, config.norm_eps)
    if config.attn_sinks: self.attn_sinks = {"weight": Tensor.zeros(config.n_heads)}
    self.indexer = Indexer(config) if config.indexer else None

  def _attention_fused(self, x:Tensor, start_pos:StartPos, residual:Tensor, n_tok:int|UOp|None) -> Tensor:
    # decode on AMD: fused attention kernel pairs (norm + rope + cache write + flash-decoding) per token, same math as _attention
    from tinygrad.llm import amd_gemv
    c = self.config
    T = x.shape[1]
    q, k, v = amd_gemv.linear_decode_multi([self.attn_q, self.attn_k, self.attn_v], x)
    qk = c.qk_norm == c.head_dim
    if not hasattr(self, "_attn_params"):
      self._attn_params = (self.attn_q_norm.weight.float().contiguous().realize(), self.attn_k_norm.weight.float().contiguous().realize()) if qk else (None, None)
    qnw, knw = self._attn_params
    attn = amd_gemv.attn_decode(self.cache_kv, q, k, v, qnw, knw, self.freqs_cis, start_pos[0], c.n_heads, c.n_kv_heads, c.head_dim, c.rope_dim,
                                self.kv_maxc, c.norm_eps, c.attn_output_gate, T, n_tok, self.kv_quant)
    return amd_gemv.linear_decode(self.attn_output, attn.reshape(1, T, -1), residual=residual)

  def _fused_ok(self) -> bool:
    c = self.config
    return all(hasattr(l, "_ggml") for l in (self.attn_q, self.attn_k, self.attn_v)) and bool(getenv("AMD_ATTN", 1)) and \
       c.head_dim == 256 and c.n_heads % c.n_kv_heads == 0 and c.n_heads // c.n_kv_heads <= 8 and c.qk_norm in (0, c.head_dim) and \
       c.rope_dim <= 64 and (self.cache_kv.dtype == dtypes.float32 or self.kv_quant is not None)

  def _attention(self, x:Tensor, start_pos:StartPos, idx_mask:Tensor|None=None, residual:Tensor|None=None,
                 n_tok:int|UOp|None=None) -> Tensor:
    if residual is not None and idx_mask is None and self.indexer is None and len(start_pos) == 1 and self._n_fused(x) and self._fused_ok():
      return self._attention_fused(x, start_pos, residual, n_tok)
    assert n_tok is None, "padded token chunks need the fused attention path"
    assert self.kv_quant is None, "the quantized kv cache is only readable by the fused attention kernel"
    if residual is not None and all(hasattr(l, "_ggml") for l in (self.attn_q, self.attn_k, self.attn_v)):
      from tinygrad.llm.amd_gemv import linear_decode_multi
      q, k, v = linear_decode_multi([self.attn_q, self.attn_k, self.attn_v], x)
    else: q, k, v = self.attn_q(x), self.attn_k(x), self.attn_v(x)
    if self.config.qk_norm and self.config.qk_norm != self.config.head_dim: q, k = self.attn_q_norm(q), self.attn_k_norm(k)

    B, T, _ = x.shape
    if self.config.attn_output_gate:
      qg = q.reshape(B, T, self.config.n_heads, 2, self.config.head_dim)
      q, gate = qg[:, :, :, 0, :], qg[:, :, :, 1, :].reshape(B, T, self.config.n_heads * self.config.head_dim)
    q = q.reshape(B, T, self.config.n_heads,    self.config.head_dim).transpose(1, 2)  # (B,H,T,Hd)
    k = k.reshape(B, T, self.config.n_kv_heads, self.config.head_dim).transpose(1, 2)  # (B,KvH,T,Hd)
    v = v.reshape(B, T, self.config.n_kv_heads, self.config.head_dim).transpose(1, 2)  # (B,KvH,T,Hd)
    if self.config.qk_norm == self.config.head_dim: q, k = self.attn_q_norm(q), self.attn_k_norm(k)

    freqs = Tensor.stack(*(self.freqs_cis[p:p+T] for p in start_pos))
    q = apply_rope(q[..., :self.config.rope_dim], freqs).cat(q[..., self.config.rope_dim:], dim=-1)
    k = apply_rope(k[..., :self.config.rope_dim], freqs).cat(k[..., self.config.rope_dim:], dim=-1)

    # NOTE: we don't want to change self.cache_kv, the function API doesn't support this well
    assigned_kv = _update_cache(self.cache_kv.transpose(0, 1), Tensor.stack(k, v).transpose(0, 1), start_pos, 3)
    # on RDNA3/4, hybrid models use custom flash attention kernels on the KV cache
    if  idx_mask is None and amd_custom_kernels_supported(x.device) and self.config.ssm is not None and len(start_pos) == 1:
      attn = flash_attention(q, assigned_kv.transpose(0, 1), start_pos[0]+T)
      attn = attn.transpose(1, 2).reshape(B, T, -1)                                    # back to (B,T,D)
      return self.attn_output(attn if not self.config.attn_output_gate else (attn * gate.sigmoid()))
    assigned_kv = _cache_prefix(assigned_kv, start_pos, T, 3).transpose(0, 1)
    k, v = assigned_kv[0], assigned_kv[1]
    mask = (idx_mask.repeat_interleave(self.config.n_heads // int(idx_mask.shape[1]), dim=1) if idx_mask is not None else
            _causal_mask(x, start_pos, self.config.sliding_window))
    if hasattr(self, 'attn_sinks'):
      S = k.shape[-2]
      k, v = k.cat(k[..., :1, :].const_like(0), dim=-2), v.cat(v[..., :1, :].const_like(0), dim=-2)
      sink_col = self.attn_sinks["weight"].reshape(1, -1, 1, 1).expand(1, self.config.n_heads, T, 1)
      if mask is None: mask = Tensor.zeros(1, 1, T, S, dtype=x.dtype, buffer=False)
      mask = mask.expand(B, self.config.n_heads, T, S).cat(sink_col.expand(B, -1, -1, -1), dim=-1)
    attn = q.scaled_dot_product_attention(k, v, attn_mask=mask, enable_gqa=True)     # (B,H,T,Hd)
    attn = attn.transpose(1, 2).reshape(B, T, -1)                                    # back to (B,T,D)
    attn = attn if not self.config.attn_output_gate else (attn * gate.sigmoid())
    if residual is not None:
      from tinygrad.llm.amd_gemv import linear_decode
      return linear_decode(self.attn_output, attn.contiguous(), residual=residual)
    return self.attn_output(attn)

  kv_quant = None  # amd_gemv.KVQuant when the cache is quantized (only the fused kernel can read it)
  def _init_state(self, x:Tensor):
    if not hasattr(self, "cache_kv"):
      c = self.config
      # the fused attention kernel (AMD, head_dim 256) keeps a quantized cache; every other path uses the dense f16 one
      if x.shape[0] == 1 and isinstance(x.device, str) and self.indexer is None and \
         all(hasattr(l, "_ggml") for l in (self.attn_q, self.attn_k, self.attn_v)) and getenv("AMD_ATTN", 1) and \
         c.head_dim == 256 and c.n_heads % c.n_kv_heads == 0 and c.n_heads // c.n_kv_heads <= 8 and c.qk_norm in (0, c.head_dim) and c.rope_dim <= 64:
        from tinygrad.llm import amd_gemv
        self.kv_quant = amd_gemv.kv_quant_spec()
      # the kv cache and the kernel's MAXC (self.kv_maxc) are max_context + MAX_T: a spec-decode chunk near the ceiling writes
      # start_pos..start_pos+T-1 (start_pos <= max_context-1, T <= 2*mtp_k+1 <= MAX_T), which would run off a max_context-sized
      # buffer and fault the GPU (MMU fault seen 2026-08-26 at start_pos 98301). the slack rows are never read (the flash scan is
      # bounded by the real position, not MAXC).
      self.kv_maxc = c.max_context + getenv("MAX_T", 8)
      if self.kv_quant is not None:
        self.cache_kv = Tensor.empty(self.kv_quant.cache_bytes(c.n_kv_heads, self.kv_maxc), dtype=dtypes.uint8, device=x.device)
      else:
        # zeroed so the flash kernels can safely read whole tiles past the valid region (masked lanes multiply by 0)
        self.cache_kv = Tensor.zeros(2, x.shape[0], c.n_kv_heads, self.kv_maxc, c.head_dim,
                                     dtype=dtypes.half, device=x.device if isinstance(x.device, str) else None)
        if isinstance(x.device, tuple): self.cache_kv = self.cache_kv.shard(x.device, 2).realize()
      # start_pos and T have independent symbolic bounds, the slice can overrun the context by all but one of T
      self.freqs_cis = precompute_freqs_cis(self.config.rope_dim, max(self.kv_maxc, self.config.max_context + x.max_shape[1]-1), self.config.rope_theta,
                                            device=x.device, yarn=self.config.yarn)
    if self.indexer: self.indexer._init_state(x)

class PLELayer:
  def __init__(self, config:TransformerConfig):
    self.table: GGUFPackedTable
    self.ple, self.count, self.dim = unwrap(config.ple), unwrap(config.hc).count, config.dim
    self.max_context, self.hist, width = config.max_context, (self.ple.conv_kernel - 1) * len(self.ple.multipliers), self.count * config.dim
    self.key, self.value = (Linear(len(self.ple.vocab_sizes) * self.ple.head_dim, out, bias=False) for out in (width, config.dim))
    self.norm_key, self.norm_query, self.norm_conv = (GroupedRMSNorm(self.count, self.dim, config.norm_eps) for _ in range(3))
    self.conv1d = {"weight": Tensor.zeros(width, self.ple.conv_kernel)}

  def _init_state(self, x:Tensor):
    if not hasattr(self, "conv_state"): self.conv_state = Tensor.zeros(x.shape[0], self.hist, self.count*self.dim, device=x.device).clone()

  def write_rows(self, tokens:list[int], start_pos:int, n_toks:int, chunk_size:int):
    # hash the n-grams ending at each token (t0*m0 ^ t1*m1 ^ ..., EOS before the start or an EOS)
    ple, n, ids, offsets = self.ple, len(self.ple.multipliers), [], list(itertools.accumulate(self.ple.vocab_sizes, initial=0))
    for p in range(start_pos, start_pos+n_toks):
      ctx = [ple.eos if p < i or ple.eos in tokens[p-i:p] else tokens[p-i] for i in range(n)]
      hashes = list(itertools.accumulate((c*m for c,m in zip(ctx, ple.multipliers)), lambda a,b: a^b))[1:]
      ids.append([hashes[j*(n-1)//len(ple.vocab_sizes)] % v + o for j,(v,o) in enumerate(zip(ple.vocab_sizes, offsets))])
    self.table.write(start_pos, ids, self.max_context+chunk_size)

  def __call__(self, x:Tensor, start_pos:StartPos) -> Tensor:
    assert len(start_pos) == 1, "independent positions are not supported for per-layer embeddings"
    pos = start_pos[0]
    (B, T), T_pad, n = x.shape[:2], x.max_shape[1], len(self.ple.multipliers)
    emb = self.table.read(pos, T_pad, x.device).reshape(B, T_pad, -1)[:, :T].float()
    s = (self.norm_key(self.key(emb).reshape(x.shape)) * self.norm_query(x)).sum(-1, keepdim=True) * self.dim**-0.5
    gated = self.value(emb).unsqueeze(2) * (s.sign() * s.abs().clamp(min_=1e-6).sqrt()).sigmoid()
    conv, store = short_conv(self.conv_state, self.norm_conv(gated).flatten(2), self.conv1d["weight"], Tensor(pos).eq(0), n)
    return Tensor((gated + conv[:, :T].reshape(gated.shape)).contiguous().uop.after(store))

class Indexer:
  def __init__(self, config:TransformerConfig):
    self.idx, self.max_context = (idx:=unwrap(config.indexer)), config.max_context
    self.attn_q_b = Linear(config.q_lora_rank or config.dim, idx.n_heads * idx.head_dim, bias=False)
    self.attn_k = Linear(config.dim, idx.head_dim, bias=False)
    self.k_norm = (nn.RMSNorm if idx.msa or idx.qsa else nn.LayerNorm)(idx.head_dim, eps=idx.norm_eps)
    if idx.msa or idx.qsa: self.q_norm = nn.RMSNorm(idx.head_dim, eps=idx.norm_eps)
    else: self.proj = Linear(config.dim, idx.n_heads, bias=False)
    if idx.kpool > 1 and not (idx.msa or idx.qsa):
      self.compressor_gate, self.compressor_ape = Linear(config.dim, idx.head_dim, bias=False), {"weight": Tensor.zeros(idx.kpool, idx.head_dim)}

  def _init_state(self, x:Tensor):
    if not hasattr(self, "cache_kg"):
      self.cache_kg = Tensor.zeros(x.shape[0], round_up(self.max_context, self.idx.kpool),
                                  *((2, self.idx.head_dim) if hasattr(self, "compressor_gate") else (self.idx.head_dim,)),
                                  dtype=dtypes.half, device=x.device)

  def __call__(self, x:Tensor, q:Tensor, start_pos:StartPos, freqs:Tensor|None=None) -> Tensor:
    (B, T, _), idx, S = x.shape, self.idx, ssimplify(smax(start_pos) + x.shape[1])
    k, iq = self.attn_k(x) if idx.qsa else self.k_norm(self.attn_k(x)), self.attn_q_b(q).reshape(B, T, idx.n_heads, idx.head_dim)
    if idx.msa or idx.qsa: iq = self.q_norm(iq)
    if idx.rope_dim:
      rot = Tensor.stack(*(unwrap(freqs)[p:p+T] for p in start_pos))
      if not idx.qsa: k = apply_rope(k[..., :idx.rope_dim].unsqueeze(1), rot, idx.rope_interleave).squeeze(1).cat(k[..., idx.rope_dim:], dim=-1)
      iq = apply_rope(iq[..., :idx.rope_dim].transpose(1, 2), rot, idx.rope_interleave).transpose(1, 2).cat(iq[..., idx.rope_dim:], dim=-1)
    if hasattr(self, "compressor_gate"):
      # cache an indexer key and a pooling gate per token, a pool's key is the gate softmax weighted sum of its keys
      kg = k.stack(self.compressor_gate(x), dim=2)  # (B, T, kpool, 2, D)
      kg = _update_cache(self.cache_kg, kg, start_pos, 1).float().reshape(B, -1, idx.kpool, 2, idx.head_dim)
      k = ((kg[..., 1, :] + self.compressor_ape["weight"]).softmax(2) * kg[..., 0, :]).sum(2)  # (B, S, D)
    else:
      k = _update_cache(self.cache_kg, k, start_pos, 1).float()  # (B, S, D)
    if idx.qsa:
      k, rot = self.k_norm(k.reshape(B, -1, idx.kpool, idx.head_dim).mean(2)), unwrap(freqs)[:self.max_context:idx.kpool]
      k = apply_rope(k[..., :idx.rope_dim].unsqueeze(1), rot, idx.rope_interleave).squeeze(1).cat(k[..., idx.rope_dim:], dim=-1)
    scores = iq @ k.transpose(-1, -2).unsqueeze(1)
    if idx.msa:   scores = scores.reshape(B, T, idx.n_heads, scores.shape[-1] // idx.kpool, idx.kpool).max(-1).transpose(1, 2)
    elif idx.qsa: scores = (scores.relu() * idx.head_dim**-0.5).sum(2).unsqueeze(1)
    else:         scores = (scores.relu() * (self.proj(x) * (idx.n_heads * idx.head_dim)**-0.5).unsqueeze(-1)).sum(2).unsqueeze(1)
    # the query sees the top_k/kpool best complete pools and the tokens of its own pool while incomplete (the tail)
    q_pos = Tensor.stack(*(Tensor(p) for p in start_pos)).reshape(-1, 1, 1, 1) + Tensor.arange(T).reshape(1, 1, T, 1)
    k_pos = Tensor.arange(S)
    scores = ((Tensor.arange(scores.shape[-1]) + 1) * idx.kpool <= q_pos + 1).where(scores, -math.inf)
    if idx.msa: scores = (Tensor.arange(scores.shape[-1]) == q_pos // idx.kpool).where(math.inf, scores)
    _, sel = scores.topk(idx.top_k // idx.kpool)
    # selected incomplete pools add only tail/future tokens, handled by the final tail and causal mask
    picked = scores.zeros_like(dtype=dtypes.bool).scatter(-1, sel, True).repeat_interleave(idx.kpool, dim=-1)[..., :S]
    return ((picked | (k_pos >= (q_pos + 1) // idx.kpool * idx.kpool)) & (k_pos <= q_pos)).where(0.0, -math.inf).cast(x.dtype)


class MLATransformerBlock(FFNBlock):
  kv_b_block_size:tuple[int, int] = (128, 128)
  def __init__(self, config:TransformerConfig):
    super().__init__(config)
    qk_nope_head_dim = config.head_dim - config.rope_dim
    if config.q_lora_rank > 0:
      self.attn_q_a = Linear(config.dim, config.q_lora_rank, bias=False)
      self.attn_q_a_norm = nn.RMSNorm(config.q_lora_rank, config.norm_eps)
      self.attn_q_b = Linear(config.q_lora_rank, config.n_heads * config.head_dim, bias=False)
    else:
      self.attn_q = Linear(config.dim, config.n_heads * config.head_dim, bias=False)
    self.attn_kv_a_mqa = Linear(config.dim, config.kv_lora_rank + config.rope_dim, bias=False)
    self.attn_kv_a_norm = nn.RMSNorm(config.kv_lora_rank, config.norm_eps)
    self.attn_k_b = {"weight": Tensor.zeros(config.n_heads, config.kv_lora_rank, qk_nope_head_dim)}
    self.attn_v_b = {"weight": Tensor.zeros(config.n_heads, config.v_head_dim, config.kv_lora_rank)}
    self.attn_output = Linear(config.n_heads * config.v_head_dim, config.dim, bias=False)
    self.indexer = Indexer(config) if config.indexer else None
    if config.attn_output_gate: self.attn_gate = Linear(config.dim, config.n_heads * config.v_head_dim, bias=False)

  def _attention(self, x:Tensor, start_pos:StartPos, idx_mask:Tensor|None=None, residual:Tensor|None=None,
                 n_tok:int|UOp|None=None) -> Tensor:
    assert residual is None and n_tok is None
    B, T, _ = x.shape
    q_nope_head_dim = self.config.head_dim - self.config.rope_dim
    q_proj = self.attn_q_b(self.attn_q_a_norm(self.attn_q_a(x))) if self.config.q_lora_rank > 0 else self.attn_q(x)
    q = q_proj.reshape(B, T, self.config.n_heads, self.config.head_dim).transpose(1, 2)
    q_nope, q_rope = q[..., :q_nope_head_dim], q[..., q_nope_head_dim:]
    freqs = Tensor.stack(*(self.freqs_cis[p:p+T] for p in start_pos)) if not self.config.ssm or not self.config.ssm.kda else None
    if freqs is not None: q_rope = apply_rope(q_rope, freqs, self.config.rope_interleave)
    if 'weight_scale_inv' in self.attn_k_b:
      q_nope = fp8_matmul(q_nope, self.attn_k_b['weight'], self.attn_k_b['weight_scale_inv'], self.kv_b_block_size[::-1])
    else: q_nope = q_nope @ self.attn_k_b['weight'].transpose(-1, -2)
    q = q_nope.cat(q_rope, dim=-1)

    kv_a = self.attn_kv_a_mqa(x)
    c_kv = self.attn_kv_a_norm(kv_a[..., :self.config.kv_lora_rank])
    k_rope = kv_a[..., self.config.kv_lora_rank:].reshape(B, T, 1, self.config.rope_dim).transpose(1, 2)
    if freqs is not None: k_rope = apply_rope(k_rope, freqs, self.config.rope_interleave)

    k_store = c_kv.reshape(B, 1, T, self.config.kv_lora_rank).cat(k_rope.reshape(B, 1, T, self.config.rope_dim), dim=-1)
    k = _cache_prefix(_update_cache(self.cache_k, k_store, start_pos, 2), start_pos, T, 2)
    v = k[..., :self.config.kv_lora_rank]

    attn = q @ k.transpose(-1, -2) * (1.0 / self.config.head_dim ** 0.5)
    mask = idx_mask if idx_mask is not None else _causal_mask(x, start_pos)
    if mask is not None: attn = attn + mask
    attn = attn.softmax(-1)
    attn = attn @ v
    if 'weight_scale_inv' in self.attn_v_b:
      attn = fp8_matmul(attn, self.attn_v_b['weight'], self.attn_v_b['weight_scale_inv'], self.kv_b_block_size)
    else: attn = attn @ self.attn_v_b['weight'].transpose(-1, -2)
    attn = attn.transpose(1, 2).reshape(B, T, -1)
    return self.attn_output(attn * self.attn_gate(x).sigmoid() if self.config.attn_output_gate else attn)

  def _indexer_mask(self, x:Tensor, start_pos:StartPos, idx_mask:Tensor|None) -> Tensor|None:
    # a full indexer layer selects the top-k tokens for itself and the shared layers after it
    if self.indexer is not None and self.config.max_context > self.indexer.idx.top_k:
      return self.indexer(x, self.attn_q_a_norm(self.attn_q_a(x)), start_pos, self.freqs_cis)
    return idx_mask

  def _init_state(self, x:Tensor):
    if not hasattr(self, "cache_k"):
      self.kv_maxc = self.config.max_context + getenv("MAX_T", 8)  # slack so a chunk straddling the ceiling fits (see FFNBlock._init_state)
      self.cache_k = Tensor.empty(x.shape[0], 1, self.kv_maxc, self.config.kv_lora_rank + self.config.rope_dim, device=x.device)
      self.freqs_cis = precompute_freqs_cis(self.config.rope_dim, self.kv_maxc, self.config.rope_theta,
                                            device=x.device, yarn=self.config.yarn)
    if self.indexer: self.indexer._init_state(x)

class GatedDeltaNetBlock(FFNBlock):
  def __init__(self, config:TransformerConfig, ssm:SSMConfig):
    super().__init__(config)
    self.head_k_dim, self.num_k_heads, self.num_v_heads = ssm.state_size, ssm.group_count, ssm.time_step_rank
    assert self.num_v_heads % self.num_k_heads == 0
    self.head_v_dim, self.ssm_conv_kernel = ssm.inner_size // ssm.time_step_rank, ssm.conv_kernel
    self.conv_channels, self.q_dim = ssm.inner_size + 2*ssm.group_count*ssm.state_size, ssm.state_size*ssm.group_count
    if ssm.kda:
      self.qkv_dims = (self.q_dim, self.q_dim, ssm.inner_size)
      self.attn_q, self.attn_k, self.attn_v = (Linear(config.dim, d, bias=False) for d in self.qkv_dims)
      self.ssm_conv1d_q, self.ssm_conv1d_k, self.ssm_conv1d_v = ({"weight": Tensor.zeros(d, 1, ssm.conv_kernel)} for d in self.qkv_dims)
      if ssm.full_rank_gate: self.ssm_g = Linear(config.dim, ssm.inner_size, bias=False)
      else: self.ssm_g_a, self.ssm_g_b = Linear(config.dim, self.head_v_dim, bias=False), Linear(self.head_v_dim, ssm.inner_size, bias=False)
      self.ssm_f_a, self.ssm_f_b = Linear(config.dim, self.head_k_dim, bias=False), Linear(self.head_k_dim, ssm.inner_size, bias=False)
    else:
      self.attn_qkv = Linear(config.dim, self.conv_channels, bias=False)
      self.ssm_conv1d = {"weight": Tensor.zeros(self.conv_channels, self.ssm_conv_kernel)}
      self.attn_gate = Linear(config.dim, ssm.inner_size, bias=False)
      self.ssm_alpha = Linear(config.dim, self.num_v_heads, bias=False)
    self.ssm_beta = Linear(config.dim, self.num_v_heads, bias=False)
    self.ssm_dt = {"bias": Tensor.zeros(ssm.inner_size if ssm.kda else self.num_v_heads)}
    self.ssm_a = Tensor.zeros(self.num_v_heads, 1) if ssm.kda else Tensor.zeros(self.num_v_heads)
    self.ssm_norm, self.ssm_out = nn.RMSNorm(self.head_v_dim, config.norm_eps), Linear(ssm.inner_size, config.dim, bias=False)

  def attn_output_linear(self) -> Linear: return self.ssm_out
  def _attention_fused(self, x:Tensor, start_pos:UOp, residual:Tensor|None, n_tok:int|UOp|None) -> Tensor:
    # decode on AMD: custom fused kernels (see amd_gemv.gdn_decode), same math as _attention
    from tinygrad.llm import amd_gemv
    conv_w, dt_bias, A, norm_w = self._gdn_params
    T = x.shape[1]
    qkv, gate, alpha, beta = amd_gemv.linear_decode_multi([self.attn_qkv, self.attn_gate, self.ssm_alpha, self.ssm_beta], x)
    z = amd_gemv.gdn_decode(self.conv_state, self.recurrent_state, qkv, conv_w, alpha, beta, dt_bias, A,
                            gate, norm_w, start_pos, self.num_v_heads, self.num_k_heads, self.head_v_dim, self.head_k_dim,
                            self.config.norm_eps, 1e-6, self.config.max_context, T, n_tok)
    return amd_gemv.linear_decode(self.ssm_out, z.reshape(1, T, -1), residual=residual)

  def _fused_ok(self) -> bool:
    ssm = unwrap(self.config.ssm)
    return not ssm.kda and ssm.gate_lower_bound is None and hasattr(self.attn_qkv, "_ggml") and self.conv_state.dtype == dtypes.float32 and \
       self.recurrent_state.dtype == dtypes.float32 and bool(getenv("AMD_GDN", 1))

  def _attention(self, x:Tensor, start_pos:StartPos, idx_mask:Tensor|None=None, residual:Tensor|None=None,
                 n_tok:int|UOp|None=None) -> Tensor:
    B, T, _ = x.shape
    assert len(start_pos) == 1, "independent positions are not supported for recurrent blocks"
    # bind ints to a variable so the reset flag stays a runtime value (it toggles when generation restarts at position 0)
    pos = start_pos[0]
    pos = pos if isinstance(pos, UOp) else UOp.variable("start_pos", 0, self.config.max_context-1).bind(pos)
    is_kda = unwrap(self.config.ssm).kda
    if self._n_fused(x) and self._fused_ok(): return self._attention_fused(x, pos, residual, n_tok)
    assert residual is None and n_tok is None
    initial = Tensor(pos).eq(0)
    symbolic = isinstance(T, UOp)
    T_pad = x.max_shape[1]  # symbolic chunks are padded to their max size: one graph serves every size

    # input processing
    x = x.half()
    out_gate = (self.ssm_g(x) if hasattr(self, "ssm_g") else self.ssm_g_b(self.ssm_g_a(x))) if is_kda else self.attn_gate(x)
    out_gate = out_gate.reshape(B, T, self.num_v_heads, self.head_v_dim)
    beta = self.ssm_beta(x).sigmoid().reshape(B, T, self.num_v_heads)
    alpha = self.ssm_f_b(self.ssm_f_a(x)) if is_kda else self.ssm_alpha(x)
    g, a = (alpha.float() + self.ssm_dt["bias"]).reshape(B, T, self.num_v_heads, -1), self.ssm_a.reshape(self.num_v_heads, -1)
    # the decay: log_alpha = softplus(g) * A, or bounded by gate_lower_bound: sigmoid(g * -A) * lb
    log_alpha = g.softplus() * a if (lb:=unwrap(self.config.ssm).gate_lower_bound) is None else (g * -a).sigmoid() * lb

    # qkv conv, conv_state is reset when starting from position 0
    projs = (self.attn_q, self.attn_k, self.attn_v) if is_kda else (self.attn_qkv,)
    convs = (self.ssm_conv1d_q, self.ssm_conv1d_k, self.ssm_conv1d_v) if is_kda else (self.ssm_conv1d,)
    states = self.conv_states if is_kda else [self.conv_state]
    conv_outs, conv_state_stores = zip(*(short_conv(s, proj(x), w["weight"].flatten(1), initial) for s, proj, w in zip(states, projs, convs)))
    # padded steps are exact no-ops: beta=0 (delta rule off), log_alpha=0 (decay 1 after exp)
    if symbolic:
      out_gate = out_gate.pad_to((B, T_pad, self.num_v_heads, self.head_v_dim))
      beta, log_alpha = beta.pad_to((B, T_pad, self.num_v_heads)), log_alpha.pad_to((B, T_pad, *log_alpha.shape[2:]))
    q, k, v = conv_outs if is_kda else conv_outs[0].split([self.q_dim, self.q_dim, self.conv_channels - 2*self.q_dim], dim=-1)
    q, k = (z.reshape(B, T_pad, self.num_k_heads, self.head_k_dim) for z in (q, k))
    # l2 norm x/sqrt(sum(x²)+1e-6) as in the FLA kernels, then the v heads share the k heads
    q, k = ((z.rmsnorm(eps=1e-6/self.head_k_dim) / self.head_k_dim**0.5).repeat(1, 1, self.num_v_heads//self.num_k_heads, 1) for z in (q, k))
    v = v.reshape(B, T_pad, self.num_v_heads, self.head_v_dim)
    # layout the per-step operands to broadcast against the (B, H, V, K) state
    q, k, v, beta = (z.transpose(1, 2).float() for z in (q, k, v, beta))
    q = q * self.head_k_dim**-0.5
    alpha = log_alpha.transpose(1, 2).exp()  # per-channel decay for kda, per-head otherwise (B, H, T, K|1)

    # recurrent: scan over the (padded) tokens, updating the recurrent state. collect the per-step outputs
    if self.head_k_dim % 32 == 0 and self.head_v_dim % 4 == 0 and amd_custom_kernels_supported(x.device):
      # one fused kernel for the whole scan; it resets and updates the recurrent state in place (RDNA3/4)
      state = Tensor(self.recurrent_state.uop.after(*conv_state_stores))  # carry the conv write into this graph
      core = gated_delta_prefill(q, k, v, beta, alpha, state, Tensor(pos)).transpose(1, 2)
    else:
      q, k, v, beta = q.unsqueeze(-2), k.unsqueeze(-2), v.unsqueeze(-1), beta.unsqueeze(-1).unsqueeze(-1)
      alpha = alpha.unsqueeze(-2)
      state = initial.where(0, self.recurrent_state.float())
      outs = []
      for t in range(T_pad):
        s1 = state * alpha[:, :, t]  # decay the state
        delta = (v[:, :, t] - (s1*k[:, :, t]).sum(-1, keepdim=True)) * beta[:, :, t]  # the delta rule update
        state = s1 + delta * k[:, :, t]
        outs.append((state * q[:, :, t]).sum(-1))

      # store the updated recurrent state in place, then read the stacked outputs after the state and conv writes
      state_store = self.recurrent_state.uop.after(self.recurrent_state.uop.store(state.cast(self.recurrent_state.dtype).uop))
      conv_writes = [c.uop.after(st) for c, st in zip(states, conv_state_stores)]
      core = Tensor(outs[0].stack(*outs[1:], dim=1).contiguous().uop.after(state_store, *conv_writes))

    # output; undo the padding before the output projection
    z = (self.ssm_norm(core) * (out_gate.silu() if unwrap(self.config.ssm).silu_gate else out_gate.sigmoid())).cast(x.dtype).contiguous()
    if symbolic: z = z[:, :T]
    return self.ssm_out(z.reshape(B, T, -1))

  def _init_state(self, x):
    if not hasattr(self, "recurrent_state"):
      if kda:=unwrap(self.config.ssm).kda:
        self.conv_states = [Tensor.zeros(x.shape[0], self.ssm_conv_kernel-1, d, device=x.device, axis=-1).clone() for d in self.qkv_dims]
      else: self.conv_state = Tensor.zeros(x.shape[0], self.ssm_conv_kernel-1, self.conv_channels, device=x.device).clone()
      self.recurrent_state = Tensor.zeros(x.shape[0], self.num_v_heads, self.head_v_dim, self.head_k_dim, device=x.device,
                                          axis=1 if kda else None).clone()
      if not kda and hasattr(self.attn_qkv, "_ggml"):  # f32 copies of the small params for the fused decode kernels, realized outside the function capture
        self._gdn_params = tuple(t.float().contiguous().realize() for t in (self.ssm_conv1d["weight"], self.ssm_dt["bias"], self.ssm_a, self.ssm_norm.weight))

class MTPModule:
  """Qwen3.8 nextn (MTP) draft layer: eh_proj(cat(enorm(embed(t_{i+1})), hnorm(h_i))) -> TransformerBlock -> shared lm_head."""
  def __init__(self, config:TransformerConfig):
    self.blk = TransformerBlock(config)
    self.eh_proj = Linear(2 * config.dim, config.dim, bias=False)
    self.enorm = nn.RMSNorm(config.dim, config.norm_eps)
    self.hnorm = nn.RMSNorm(config.dim, config.norm_eps)
    self.shared_head_norm = nn.RMSNorm(config.dim, config.norm_eps)

  def __call__(self, hidden:Tensor, next_emb:Tensor, start_pos:int|UOp, n_tok:int|UOp|None=None) -> Tensor:
    return self.blk(self.eh_proj(self.enorm(next_emb).cat(self.hnorm(hidden), dim=-1)), (start_pos,), None, n_tok)[0]

class Transformer:
  def __init__(self, config:TransformerConfig):
    dense_config = replace(config, num_experts=0, num_experts_per_tok=0, shared_expert_dim=0, hidden_dim=config.dense_hidden_dim or config.hidden_dim)
    if config.ssm: config = replace(config, qk_norm=config.head_dim)
    self.config = config
    block_cls = MLATransformerBlock if config.kv_lora_rank > 0 else TransformerBlock
    self.blk:list[FFNBlock] = []
    for i in range(config.num_blocks):
      c = dense_config if i < config.leading_dense_blocks else config
      if config.sliding_window_pattern != 0 and (i+1) % config.sliding_window_pattern == 0: c = replace(c, sliding_window=0)
      if config.indexer_shared and config.indexer_shared[i]: c = replace(c, indexer=None)
      if config.attn_res_block_size and i % config.attn_res_block_size == 0: c = replace(c, attn_res_new_block=True)
      if config.ple and i != config.ple.layer: c = replace(c, ple=None)
      self.blk.append(GatedDeltaNetBlock(c, config.ssm) if config.ssm and config.ssm_layers[i] else block_cls(c))
    self.token_embd  = nn.Embedding(config.vocab_size, config.dim)
    self.output_norm: Callable[[Tensor], Tensor] = nn.RMSNorm(config.dim, config.norm_eps)
    if config.hc and config.hc.low_rank: self.output_hc, self.output_norm = GatedResidual(config, inject=False), lambda x: x
    if config.attn_res_block_size: self.output_res_score = AttentionResidual(config)
    self.output = Linear(config.dim, config.vocab_size, bias=False)
    self.max_context = config.max_context
    self.has_recurrent_block = any(isinstance(b, GatedDeltaNetBlock) for b in self.blk)
    self._cached_tokens: list[int] = []
    self._position_count: int|None = None
    # recurrent-state checkpoint taken after every prompt prefill (see _save_checkpoint); the dict keys end in the _TRANSIENT names so
    # tinygrad.llm.cache drops the buffers like the live state
    self._ckpt: dict[str, dict[str, Tensor]] = {}
    self._ckpt_tokens: list[int]|None = None
    self._warming = False
    # vision: set when an encoder is attached. image tokens (the pad id) take their embeddings from an `emb` input of the prefill chunk
    self.image_pad_id: int|None = None
    self._cached_media: tuple = ()
    self._emb_zero: dict[int, Tensor] = {}
    self._pos_dirty = False
    self.mtp: MTPModule|None = None
    self.mtp_k = 1
    self._spec_jits: dict = {}
    # we specialize the JIT for prefill and rollout
    self.prefill_jit = TinyJit(self.forward)
    self.rollout_jit = TinyJit(self.forward)

  def _embed(self, tokens:Tensor, emb:Tensor|None) -> Tensor:
    x = self.token_embd(tokens.to(self.token_embd.weight.device)).float()  # (B, T, D)
    # image tokens take the rows of `emb` (vision encoder output placed at their positions, zeros elsewhere)
    return x if emb is None else (tokens == self.image_pad_id).unsqueeze(-1).where(emb, x)

  def forward(self, tokens:Tensor, temperature:Tensor, *start_pos:int|UOp, n_tok:int|UOp|None=None, emb:Tensor|None=None) -> Tensor:
    # n_tok: number of valid tokens when `tokens` is a padded fixed-size chunk (fused AMD path), the rest are ignored
    if hasattr(self, "_ggml_raw"):
      from tinygrad.llm import amd_gemv
      amd_gemv.new_forward()
    x = self._embed(tokens, emb)
    if (hc:=self.config.hc) is not None: x = x.unsqueeze(2).expand(*x.shape[:2], hc.count, x.shape[-1]).contiguous()
    elif self.config.attn_res_block_size: x = x.unsqueeze(2)
    idx_mask = None
    for block in self.blk: x, idx_mask = block(x, start_pos, idx_mask, n_tok)
    if hc is not None: x = self.output_hc.mix(x)[0] if hc.low_rank else x.mean(2)
    elif self.config.attn_res_block_size: x = self.output_res_score.mix(x)
    # only run the output projection on the last (valid) token
    last = x[:, -1:] if n_tok is None else x.shrink((None, (n_tok - 1, n_tok), None)).contiguous()
    logits = self.output(self.output_norm(last))[:, -1, :].to(tokens.device)
    # Gumbel-max trick: argmax(logits/temp - log(-log(uniform))) is equivalent to sampling from softmax(logits/temp)
    return (logits / temperature.maximum(1e-12) - (Tensor.rand_like(logits).maximum(1e-12).log().neg()).log()).argmax(-1, keepdim=True)

  @staticmethod
  def _sample_rows(logits:Tensor, temperature:Tensor) -> Tensor:
    # per-row Gumbel-max sampling (same as _sample): the draft is verified by sample-then-compare so temperature>0 stays lossless
    return (logits / temperature.maximum(1e-12) - (Tensor.rand_like(logits).maximum(1e-12).log().neg()).log()).argmax(-1)

  def forward_spec(self, tokens:Tensor, start_pos:int|UOp, temperature:Tensor, n_tok:int|UOp, n_keep:int|UOp,
                   emb:Tensor|None=None) -> tuple[Tensor, ...]:
    """main model on a T-token chunk (n_keep tokens commit GDN/conv state; the rest are the K drafts being verified), then K chained
    passes of the MTP draft layer. returns (res[T+K] = sampled tokens of the T rows + the K new drafts, next chunk if L drafts were
    accepted for L = 0..K). the next chunks are realized here so the next step feeds a JIT output straight back in (realizing a fresh
    Tensor each step walks the whole live graph); accept count / draft rows stay on GPU so the JIT has no Python branch."""
    from tinygrad.llm import amd_gemv
    from tinygrad.engine.realize import capturing
    import gc
    assert self.mtp is not None
    K, T = self.mtp_k, int(tokens.shape[1])
    prefill = not isinstance(n_keep, int)
    amd_gemv.new_forward(n_keep)
    x = self._embed(tokens, emb)
    for block in self.blk:
      x, _ = block(x, (start_pos,), None, n_tok)
      # long chunks: realize per block outside the JIT. the eager (first, pre-capture) run cannot memory-plan the custom kernels' in/out
      # buffers, so one schedule for the whole chunk would allocate every layer's intermediates at once (~7 GB at T=256). inside a capture
      # realize only records the schedule, the captured graph is planned as a whole. TinyJit runs with the cyclic GC disabled, and the
      # finished block's graph is a reference cycle: collect it so its buffers are freed before the next block
      if T > amd_gemv.MAX_T and not capturing:
        x = x.realize()
        gc.collect(1)
    chunk, idx = tokens.reshape(T), Tensor.arange(T, dtype=dtypes.int32)
    if prefill:  # only the last valid row is sampled (the output projection of a long chunk would be the biggest GEMM of the step)
      lastx = x.shrink((None, (n_tok - 1, n_tok), None)).contiguous() if isinstance(n_tok, int) else \
        ((idx == (n_tok - 1)).reshape(1, T, 1).where(x, 0)).sum(axis=1, keepdim=True)
      out_last = Transformer._sample_rows(self.output(self.output_norm(lastx)), temperature).reshape(1).cast(dtypes.int32)
      out = out_last.expand(T).contiguous()
    else: out = Transformer._sample_rows(self.output(self.output_norm(x)), temperature).reshape(T).cast(dtypes.int32)
    # rows < n_keep-1 see the next chunk token, the others the token sampled from them
    next_toks = (idx < (n_keep - 1)).where(chunk[1:].cat(chunk[-1:]), out).reshape(1, T)
    if prefill:  # nothing to verify
      n_acc, j_last = 0, n_tok - 1
    else:  # L = number of leading drafts that match what the model sampled in their place (lossless at any temperature)
      acc = (out[n_keep-1:n_keep-1+K] == chunk[n_keep:n_keep+K]).cast(dtypes.int32)
      n_acc = (acc.cumsum(0) == idx[:K] + 1).sum().reshape(1).cast(dtypes.int32)  # type: ignore[assignment]
      j_last = n_keep - 1 + n_acc  # row of the last accepted position
    def pick(t:Tensor, j) -> Tensor:  # row j of (1, T, ...) / (T,) as a (1, 1, ...) / (1,) tensor, j int, UOp or int32 Tensor
      if isinstance(j, Tensor):
        m = (idx == j.reshape(())).reshape(*([1, T] if t.ndim == 3 else [T]), *([1] * (t.ndim - 2 if t.ndim == 3 else 0)))
        return (m.where(t, 0)).sum(axis=1 if t.ndim == 3 else 0, keepdim=True)
      return t.shrink(((None,) if t.ndim == 3 else ()) + ((j, j + 1),) + ((None,) if t.ndim == 3 else ())).contiguous()
    # MTP pass 1 over the chunk rows (fills its KV cache), then K-1 single-row passes chained on its own hidden state and draft
    amd_gemv.new_forward(n_keep if prefill else n_keep + n_acc)
    mx = self.mtp(x, self.token_embd(next_toks).float(), start_pos, n_tok)
    h = pick(mx, j_last)
    drafts = [Transformer._sample_rows(self.output(self.mtp.shared_head_norm(h)), temperature).reshape(1).cast(dtypes.int32)]
    for k in range(1, K):
      amd_gemv.new_forward(1)
      h = self.mtp(h, self.token_embd(drafts[-1].reshape(1, 1)).float(), (j_last + start_pos) + k, 1)  # Tensor + UOp works, not UOp + Tensor
      drafts.append(Transformer._sample_rows(self.output(self.mtp.shared_head_norm(h)), temperature).reshape(1).cast(dtypes.int32))
    draft = drafts[0].cat(*drafts[1:]) if K > 1 else drafts[0]
    # candidate next chunks: L accepted -> U = drafts[:L] + [out[n_keep-1+L]], chunk = U + new drafts
    last = pick(out, j_last)
    if prefill: cands = [last.cat(draft).reshape(1, 1 + K).contiguous()]
    else: cands = [chunk[n_keep:n_keep+L].cat(out[n_keep-1+L:n_keep+L], draft).reshape(1, L + 1 + K).contiguous() for L in range(K + 1)]
    res = out.cat(draft).contiguous()
    amd_gemv.end_forward()
    return (res, *cands)

  def __call__(self, tokens:Tensor, start_pos:StartPos, temperature:Tensor, n_tok:int|UOp|None=None, emb:Tensor|None=None) -> Tensor:
    assert len(start_pos) in (1, tokens.shape[0]), "expected one shared position or one position per batch row"
    if self._position_count is None: self._position_count = len(start_pos)
    assert len(start_pos) == self._position_count, "position count is fixed for this model"
    positions = tuple(UOp.variable(f"start_pos_{b}", 0, self.max_context-1).bind(p) if isinstance(p, int) else p for b, p in enumerate(start_pos))
    kw = ({} if n_tok is None else {"n_tok": n_tok}) | ({} if emb is None else {"emb": emb})
    return (self.prefill_jit if resolve(tokens.shape[1] != 1) else self.rollout_jit)(tokens.contiguous(), temperature, *positions, **kw)

  @staticmethod
  def from_gguf(gguf:Tensor|str|pathlib.Path, max_context:int|None=None,
                realize=bool(getenv("REALIZE", 0)), shard:int=1, vision:bool=False) -> tuple[Transformer, dict]:
    # vision: the prefill jits take the image-embedding input (the pad token id is set by the caller before warmup)
    # a warmed-up model may be cached whole (weights re-uploaded, jits unpickled): ~seconds instead of a full load + warmup
    if not isinstance(gguf, Tensor) and shard == 1:
      from tinygrad.llm.cache import load_llm_cache
      if (cached:=load_llm_cache(str(gguf), max_context, "vision" if vision else "")) is not None:
        cached[0]._from_cache = True
        return cached

    # TODO: remove the need for copy to default device
    kv, entries = gguf_parse(gguf.to(None).realize() if isinstance(gguf, Tensor) else gguf)
    arch = kv['general.architecture']
    ple_entry = entries.pop('per_layer_token_embd.weight', None)
    n_heads, n_kv_heads = kv[f'{arch}.attention.head_count'], kv[f'{arch}.attention.head_count_kv']
    assert shard >= 1, f"shard must be at least 1, got {shard}"
    shard_map, repeats = {}, {}
    if shard > 1:
      if not kv.get(f'{arch}.attention.kv_lora_rank') and n_kv_heads < shard and shard % n_kv_heads == 0:
        # too few KV heads to split: repeat each one so every device holds one
        repeats = {k: shard // n_kv_heads for k in entries if k.split('.', 2)[-1] in ('attn_k.weight', 'attn_v.weight', 'attn_k.bias', 'attn_v.bias')}
        n_kv_heads = shard
      heads = n_heads if kv.get(f'{arch}.attention.kv_lora_rank') else n_kv_heads
      assert heads % shard == 0, f"tensor parallel needs the attention heads to split over {shard} devices"
      # shard MLA heads and routed experts while replicating latent projections, KV cache and shared experts
      rules = {**{w: 0 for w in ('token_embd.weight', 'output.weight', 'attn_q.weight', 'attn_k.weight', 'attn_v.weight', 'ffn_gate.weight',
        'ffn_up.weight', 'attn_q_b.weight', 'attn_k_b.weight', 'attn_v_b.weight')},
        **{w: 1 for w in ('attn_output.weight', 'ffn_down.weight', 'ffn_gate_exps.weight', 'ffn_up_exps.weight')}, 'ffn_down_exps.weight':2}
      if arch in ('kimi-linear', 'glm5-next', 'kimi-k3'): rules.update({w: 0 for w in ('ssm_conv1d_q.weight', 'ssm_conv1d_k.weight',
        'ssm_conv1d_v.weight', 'ssm_dt.bias', 'ssm_a', 'ssm_beta.weight', 'ssm_f_b.weight', 'ssm_g.weight', 'ssm_g_b.weight', 'attn_gate.weight')})
      shard_map = {name: rules[k] for name in entries if (k:=re.sub(r"^blk\.\d+\.", "", name)) in rules}
    devices = tuple(Device.canonicalize(f'{Device.DEFAULT}:{i}') for i in range(shard))
    ep = any(shape[-1] % (shard*_GGML_QUANT.get(typ, (1,))[0]) for k,(_,shape,typ) in entries.items() if 'ffn_down_exps.' in k)
    # one device: the fork's loader keeps the packed bytes of every quantized matrix (raw) for the AMD kernels
    raw: dict = {}
    if shard == 1: state_dict = _load_raw(entries, raw)
    else: state_dict = gguf_shard(entries, devices, {k: 0 if ep and '_exps.' in k else v for k,v in shard_map.items()}, repeats)

    # all state items should be float16, not float32
    state_dict = {k:v.cast('float16') if getenv("HALF", 1) else v for k,v in state_dict.items()}

    # some models like Llama 3.2 don't have an output.weight, they just tie to the token_embd.weight
    if 'output.weight' not in state_dict:
      state_dict['output.weight'] = state_dict['token_embd.weight']
      if 'token_embd.weight' in raw: raw['output.weight'] = raw['token_embd.weight']

    hc = HCConfig(kv[f'{arch}.hyper_connection.count'], kv.get(f'{arch}.hyper_connection.sinkhorn_iterations', 0),
                  kv.get(f'{arch}.hyper_connection.epsilon', 0.0),
                  kv.get(f'{arch}.hyper_connection.low_rank', 0)) if f'{arch}.hyper_connection.count' in kv else None
    if hc is not None: state_dict = {re.sub(r'(hc_attn|hc_ffn|output_hc|\.ple)_', r'\1.', k):v for k,v in state_dict.items()}

    kpool = kv.get(f'{arch}.attention.indexer.block_size' if arch == 'minimax-m3' else f'{arch}.attention.indexer.kpool',
                   1 if f'{arch}.attention.indexer.top_k' in kv else None)
    if arch == 'qwen4exp': kpool = max(kv[f'{arch}.attention.compress_ratios'])
    indexer = IndexerConfig(kv[f'{arch}.attention.indexer.head_count'], kv[f'{arch}.attention.indexer.key_length'],
                            kv[f'{arch}.attention.indexer.top_k'], kpool,
                            kv.get(f'{arch}.attention.layer_norm_epsilon') or kv[f'{arch}.attention.layer_norm_rms_epsilon']) if kpool else None
    if indexer is not None: state_dict = {k.replace('.indexer_compressor_', '.indexer.compressor_'):v for k,v in state_dict.items()}
    if arch == 'glm-dsa': indexer = replace(unwrap(indexer), rope_dim=kv[f'{arch}.rope.dimension_count'], norm_eps=1e-6)
    if arch in ('minimax-m3', 'qwen4exp'):
      indexer = replace(unwrap(indexer), rope_dim=kv[f'{arch}.rope.dimension_count'], rope_interleave=False, msa=arch == 'minimax-m3',
                        qsa=arch == 'qwen4exp', top_k=kv[f'{arch}.attention.indexer.top_k'] * kv.get(f'{arch}.attention.indexer.block_size', 1))
      state_dict = {k.replace('.indexer.q_proj', '.indexer.attn_q_b').replace('.indexer.k_proj', '.indexer.attn_k'):v for k,v in state_dict.items()}

    max_context = min(max_context, kv[f'{arch}.context_length']) if max_context is not None else kv[f'{arch}.context_length']

    num_blocks = kv[f'{arch}.block_count'] - kv.get(f'{arch}.nextn_predict_layers', 0)
    ssm = None
    ssm_layers: tuple[bool, ...] = ()
    if arch in ('qwen35', 'qwen35moe', 'qwen4exp'):
      ssm = SSMConfig(**{k: kv[f'{arch}.ssm.{k}'] for k in ('conv_kernel','state_size','group_count','time_step_rank','inner_size')},
                      silu_gate=arch != 'qwen4exp')
      ssm_layers = tuple((i+1) % kv[f'{arch}.full_attention_interval'] != 0 for i in range(num_blocks))
    elif arch in ('kimi-linear', 'glm5-next', 'kimi-k3'):
      ssm_layers = tuple(x == 0 for x in n_kv_heads)[:num_blocks]
      n_kv_heads = max(n_kv_heads)
      ssm = SSMConfig(kv[f'{arch}.ssm.conv_kernel'], kv[f'{arch}.kda.head_dim'], n_heads, n_heads, n_heads*kv[f'{arch}.kda.head_dim'], kda=True,
                      gate_lower_bound=kv.get(f'{arch}.kda.gate_lower_bound'), full_rank_gate=arch == 'kimi-k3')
      for i, is_ssm in enumerate(ssm_layers):
        if not is_ssm: continue
        state_dict[f"blk.{i}.ssm_a"] = state_dict[f"blk.{i}.ssm_a"].reshape(n_heads, 1)
        state_dict[f"blk.{i}.ssm_out.weight"] = state_dict.pop(f"blk.{i}.attn_output.weight")
    if arch in ('qwen35', 'qwen35moe', 'glm4moe', 'gpt-oss'):
      state_dict = {k.replace('post_attention_norm', 'ffn_norm'):v for k,v in state_dict.items()}

    kv_lora_rank = kv.get(f'{arch}.attention.kv_lora_rank', 0)
    head_dim = kv.get(f'{arch}.attention.key_length_mla', kv.get(f'{arch}.attention.key_length', kv[f'{arch}.embedding_length'] // n_heads))
    rope_dim = kv.get(f'{arch}.rope.dimension_count', head_dim)
    yarn = YaRNConfig(factor=kv[f'{arch}.rope.scaling.factor'],
                      orig_ctx_len=kv.get(f'{arch}.rope.scaling.original_context_length', kv[f'{arch}.context_length']),
                      beta_fast=kv.get(f'{arch}.rope.scaling.yarn_beta_fast', 32.0),
                      beta_slow=kv.get(f'{arch}.rope.scaling.yarn_beta_slow', 1.0)) if kv.get(f'{arch}.rope.scaling.type') == 'yarn' else None

    # Permute RoPE weights from interleaved to half-split layout.
    for name in state_dict:
      if arch in ('kimi-linear', 'glm5-next', 'kimi-k3') or '.indexer.' in name: continue
      if ('attn_q.weight' in name or 'attn_q_b.weight' in name) and (arch == 'llama' or kv_lora_rank):
        state_dict[name] = permute_rope(state_dict[name], n_heads, rope_dim)
      elif arch == 'llama' and 'attn_k.weight' in name:
        state_dict[name] = permute_rope(state_dict[name], n_kv_heads, state_dict[name].shape[0]//n_kv_heads)
      elif kv_lora_rank and 'attn_kv_a_mqa.weight' in name:
        state_dict[name] = permute_rope(state_dict[name], 1, state_dict[name].shape[0]-kv_lora_rank)
    swiglu_oai = arch in ('gpt-oss', 'minimax-m3')
    config = TransformerConfig(
      num_blocks=num_blocks, dim=kv[f'{arch}.embedding_length'],
      hidden_dim=kv.get(f'{arch}.expert_feed_forward_length', kv.get(f'{arch}.feed_forward_length', 0)),
      n_heads=n_heads, n_kv_heads=n_kv_heads, norm_eps=kv[f'{arch}.attention.layer_norm_rms_epsilon'],
      vocab_size=len(kv['tokenizer.ggml.tokens']),
      head_dim=head_dim,
      rope_theta=kv.get(f'{arch}.rope.freq_base', 10000.0), rope_dim=rope_dim, yarn=yarn,
      rope_sections=tuple(kv[k]) if (k:=f'{arch}.rope.dimension_sections') in kv else None,
      v_head_dim=kv.get(f'{arch}.attention.value_length_mla', kv.get(f'{arch}.attention.value_length', head_dim)),
      max_context=max_context,
      qk_norm=int(state_dict['blk.0.attn_q_norm.weight'].shape[0]) if 'blk.0.attn_q_norm.weight' in state_dict else 0,
      num_experts=kv.get(f'{arch}.expert_count', 0), num_experts_per_tok=kv.get(f'{arch}.expert_used_count', 0),
      norm_topk_prob=kv.get(f'{arch}.expert_weights_norm', arch in ('qwen3moe', 'qwen35moe', 'kimi-linear', 'qwen4exp')),
      expert_gating_func=ExpertGating(kv.get(f'{arch}.expert_gating_func',
        ExpertGating.SOFTMAX_WEIGHT if arch == 'gpt-oss' else ExpertGating.SOFTMAX)),
      kv_lora_rank=kv_lora_rank, q_lora_rank=kv.get(f'{arch}.attention.q_lora_rank', 0),
      leading_dense_blocks=kv.get(f'{arch}.leading_dense_block_count', 0),
      shared_expert_dim=kv.get(
        f'{arch}.expert_shared_feed_forward_length',
        kv.get(f'{arch}.expert_shared_count', 0) * kv.get(f'{arch}.expert_feed_forward_length', 0)),
      shared_expert_gate=f"blk.{kv.get(f'{arch}.leading_dense_block_count', 0)}.ffn_gate_inp_shexp.weight" in state_dict,
      dense_hidden_dim=kv.get(f'{arch}.feed_forward_length', 0) if kv.get(f'{arch}.leading_dense_block_count', 0) else 0,
      routed_scaling_factor=kv.get(f'{arch}.expert_weights_scale', 1.0), attn_output_gate=arch in ('qwen35', 'qwen35moe', 'kimi-k3', 'qwen4exp'),
      ssm=ssm, ssm_layers=ssm_layers,
      qkv_bias='blk.0.attn_q.bias' in state_dict,
      expert_bias=f"blk.{kv.get(f'{arch}.leading_dense_block_count', 0)}.exp_probs_b.bias" in state_dict,
      expert_proj_bias='blk.0.ffn_gate_exps.bias' in state_dict, attn_output_bias='blk.0.attn_output.bias' in state_dict,
      swiglu_alpha=1.702 if swiglu_oai else 1.0, swiglu_limit=7.0 if swiglu_oai else kv.get(f'{arch}.swiglu_clamp_exp', [None])[0],
      swiglu_up_bias=1.0 if swiglu_oai else 0.0, attn_sinks='blk.0.attn_sinks.weight' in state_dict,
      sliding_window=kv.get(f'{arch}.attention.sliding_window', 0),
      sliding_window_pattern=kv.get(f'{arch}.attention.sliding_window_pattern', 2 if arch == 'gpt-oss' else 0), hc=hc, indexer=indexer,
      # without indexer.types, GLM-5.2+ (1M context) runs the indexer on blocks 0-2 and every 4th after (6, 10, ..), GLM-5/5.1 on all
      indexer_shared=tuple(not full for full in kv[f'{arch}.attention.indexer.types']) if f'{arch}.attention.indexer.types' in kv else
        tuple(i > 2 and i % 4 != 2 for i in range(num_blocks)) if arch == 'glm-dsa' and kv[f'{arch}.context_length'] >= 1048576 else (),
      ple=PLEConfig(kv[f'{arch}.ple.layers'][0], ple_entry[1][1], tuple(kv[f'{arch}.ple.layer_multipliers']),
                    tuple(kv[f'{arch}.ple.head_vocab_sizes']), kv[f'{arch}.ple.eos_token_id'], kv[f'{arch}.ple.conv_kernel']) if ple_entry else None,
      expert_latent_dim=kv.get(f'{arch}.expert_latent_length', 0), attn_res_block_size=kv.get(f'{arch}.attn_res.block_size', 0),
      situ=(kv[f'{arch}.activation.situ_beta'], kv[f'{arch}.activation.situ_linear_beta']) if f'{arch}.activation.situ_beta' in kv else None)
    mtp_prefix = f'blk.{config.num_blocks}.'
    if getenv("MTP", 1) and any(k.startswith(mtp_prefix) for k in state_dict):
      def _mtp_key(k:str) -> str:
        if not k.startswith(mtp_prefix): return k
        rest = k[len(mtp_prefix):]
        return 'mtp.' + rest[len('nextn.'):] if rest.startswith('nextn.') else 'mtp.blk.' + rest
      state_dict = {_mtp_key(k): v for k, v in state_dict.items()}
      for k in [k for k in raw if k.startswith(mtp_prefix)]: raw[_mtp_key(k)] = raw.pop(k)
    model = Transformer(config)
    for p in (nn.state.get_parameters(model) if shard > 1 else []): p.to_(devices)
    if any(k.startswith('mtp.') for k in state_dict):
      model.mtp = MTPModule(replace(config, qk_norm=config.head_dim) if config.ssm else config)
      from tinygrad.llm.amd_gemv import MAX_T
      model.mtp_k = getenv("MTP_K", 3)  # drafts per step: chunk = up to K+1 committed tokens + K drafts must fit the fused T <= MAX_T path
      assert 1 <= model.mtp_k and 2 * model.mtp_k + 1 <= MAX_T, f"MTP_K={model.mtp_k} needs 2K+1 <= {MAX_T}"
    nn.state.load_state_dict(model, state_dict, verbose=False, consume=True, realize=False)  # NOTE: rope_freqs.weight (32,) is unused
    # the packed weights stay resident: realize the raw bytes of the model's tensors once (straight from disk), and the small
    # parameters (norms, biases, conv weights) so nothing is re-copied or re-cast every token
    with Timing("loaded weights in ", enabled=DEBUG >= 1):
      used = set(nn.state.get_state_dict(model).keys())
      Tensor.realize(*[t for k, (t, _, _) in raw.items() if k in used])
      Tensor.realize(*[p for p in nn.state.get_parameters(model) if p.numel() < 2**20])
    # custom quantized GEMV kernels consume the raw ggml bytes directly (single token decode on AMD)
    if getenv("AMD_GEMV", 1) and nn.state.get_parameters(model)[0].device.split(":")[0] == "AMD":
      from tinygrad.llm import amd_gemv
      model._ggml_raw = {k: amd_gemv.GGMLWeight(t, typ, *shape) for k, (t, typ, shape) in raw.items()}
      amd_gemv.install()
      if DEBUG >= 1: print(f"amd_gemv: attached raw ggml weights to {len(amd_gemv.attach(model))} layers")
      else: amd_gemv.attach(model)
      # prefill in fixed-size token chunks through the fused kernels when every block takes that path (state updates must skip padding)
      probe = Tensor.empty(1, 1, config.dim, device=nn.state.get_parameters(model)[0].device)
      for b in model.blk: b._init_state(probe)
      if model.mtp is not None: model.mtp.blk._init_state(probe)
      if getenv("AMD_CHUNK", 1) and all(b._decode_fused(probe) and hasattr(b, "_fused_ok") and b._fused_ok() for b in model.blk):
        # the long prefill chunk (dequant + tensor-core GEMM, batched attention) needs the quantized kv cache in every attention block
        blocks = list(model.blk) + ([model.mtp.blk] if model.mtp is not None else [])
        model._chunk_T = amd_gemv.PREFILL_T if all(getattr(b, "kv_quant", True) is not None for b in blocks) else amd_gemv.MAX_T
    # NOTE: without this contiguous, it unpacks the weights from the model every time. we shouldn't need this, but for now it's faster
    if realize:
      for s in (params:=nn.state.get_parameters(model)): s.replace(s.contiguous())
      Tensor.realize(*params)
    if config.ple is not None: model.blk[config.ple.layer].ple.table = GGUFPackedTable(unwrap(ple_entry))
    return model, kv

  @staticmethod
  def from_hf(path:str|pathlib.Path, max_context:int|None=None,
              realize=bool(getenv("REALIZE", 0)), shard:int=1) -> tuple[Transformer, dict]:
    path = pathlib.Path(path)
    cfg = json.loads((path/'config.json').read_text())
    assert cfg['architectures'][0] == 'GlmMoeDsaForCausalLM', "from_hf only supports glm-dsa checkpoints"
    assert shard >= 1 and cfg['num_attention_heads'] % shard == 0, "tensor parallel must divide the attention heads"
    devices = tuple(Device.canonicalize(f'{Device.DEFAULT}:{i}') for i in range(shard))
    hf_names = {'token_embd.weight': 'model.embed_tokens.weight', 'output_norm.weight': 'model.norm.weight', 'output.weight': 'lm_head.weight',
                'attn_norm.weight': 'input_layernorm.weight', 'ffn_norm.weight': 'post_attention_layernorm.weight',
                'attn_q_a.weight': 'self_attn.q_a_proj.weight', 'attn_q_a_norm.weight': 'self_attn.q_a_layernorm.weight',
                'attn_q_b.weight': 'self_attn.q_b_proj.weight', 'attn_kv_a_mqa.weight': 'self_attn.kv_a_proj_with_mqa.weight',
                'attn_kv_a_norm.weight': 'self_attn.kv_a_layernorm.weight', 'attn_k_b.weight': 'self_attn.kv_b_proj.weight',
                'attn_output.weight': 'self_attn.o_proj.weight', 'indexer.attn_q_b.weight': 'self_attn.indexer.wq_b.weight',
                'indexer.attn_k.weight': 'self_attn.indexer.wk.weight', 'indexer.proj.weight': 'self_attn.indexer.weights_proj.weight',
                'indexer.k_norm.weight': 'self_attn.indexer.k_norm.weight', 'indexer.k_norm.bias': 'self_attn.indexer.k_norm.bias',
                'ffn_gate_inp.weight': 'mlp.gate.weight', 'exp_probs_b.bias': 'mlp.gate.e_score_correction_bias',
                **{f'ffn_{p}.weight': f'mlp.{p}_proj.weight' for p in ('gate', 'up', 'down')},
                **{f'ffn_{p}_shexp.weight': f'mlp.shared_experts.{p}_proj.weight' for p in ('gate', 'up', 'down')},
                **{f'ffn_{p}_exps.weight': f'mlp.experts.{{}}.{p}_proj.weight' for p in ('gate', 'up', 'down')}}
    shard_axes = {**{w: 0 for w in ('token_embd.weight', 'output.weight', 'attn_q_b.weight', 'attn_k_b.weight', 'ffn_gate.weight', 'ffn_up.weight')},
                  **{w: 1 for w in ('attn_output.weight', 'ffn_down.weight', 'ffn_gate_exps.weight', 'ffn_up_exps.weight')},
                  **{w: 2 for w in ('ffn_down_exps.weight',)}}

    global_names = ('token_embd.weight', 'output_norm.weight', 'output.weight')
    sources:dict[str, str|list[str]] = {k: hf_names[k] for k in global_names}
    for layer in range(cfg['num_hidden_layers']):
      for key, source in hf_names.items():
        if key in global_names or (key.startswith('indexer.') and cfg['indexer_types'][layer] != 'full'): continue
        source = f'model.layers.{layer}.' + source
        sources[f'blk.{layer}.{key}'] = [source.format(i) for i in range(cfg['n_routed_experts'])] if '{}' in source else source
    shard_map = {name: shard_axes[key] for name in sources if (key:=re.sub(r'^blk\.\d+\.', '', name)) in shard_axes}
    state_dict = hf_load(path, devices, sources, shard_map)
    block_size = tuple(cfg['quantization_config']['weight_block_size'])
    nope, value = cfg['qk_nope_head_dim'], cfg['v_head_dim']
    step = math.gcd(block_size[0], nope, value)

    config = TransformerConfig(
      num_blocks=cfg['num_hidden_layers'], dim=cfg['hidden_size'], hidden_dim=cfg['moe_intermediate_size'],
      n_heads=cfg['num_attention_heads'], n_kv_heads=1, norm_eps=cfg['rms_norm_eps'], vocab_size=cfg['vocab_size'],
      head_dim=cfg['qk_nope_head_dim'] + cfg['qk_rope_head_dim'], v_head_dim=cfg['v_head_dim'],
      rope_theta=cfg['rope_parameters']['rope_theta'], rope_dim=cfg['qk_rope_head_dim'],
      max_context=min(max_context, cfg['max_position_embeddings']) if max_context is not None else cfg['max_position_embeddings'],
      num_experts=cfg['n_routed_experts'], num_experts_per_tok=cfg['num_experts_per_tok'], norm_topk_prob=cfg['norm_topk_prob'],
      expert_gating_func=ExpertGating.SIGMOID if cfg['scoring_func'] == 'sigmoid' else ExpertGating.SOFTMAX,
      kv_lora_rank=cfg['kv_lora_rank'], q_lora_rank=cfg['q_lora_rank'], leading_dense_blocks=cfg['first_k_dense_replace'],
      shared_expert_dim=cfg['n_shared_experts'] * cfg['moe_intermediate_size'], shared_expert_gate=False, expert_bias=True,
      dense_hidden_dim=cfg['intermediate_size'], routed_scaling_factor=cfg['routed_scaling_factor'],
      indexer=IndexerConfig(cfg['index_n_heads'], cfg['index_head_dim'], cfg['index_topk'], rope_dim=cfg['qk_rope_head_dim'],
                            rope_interleave=cfg['indexer_rope_interleave']),
      indexer_shared=tuple(t != 'full' for t in cfg['indexer_types']), rope_interleave=cfg['rope_interleave'])
    model = Transformer(config)
    for p in (nn.state.get_parameters(model) if shard > 1 else []): p.to_(devices)
    for i, block in enumerate(model.blk):
      assert isinstance(block, MLATransformerBlock)
      prefix = f'blk.{i}.'
      w = state_dict[prefix+'attn_k_b.weight']
      kv = w.reshape(config.n_heads, nope + value, config.kv_lora_rank)
      state_dict[prefix+'attn_k_b.weight'] = kv[:, :nope].transpose(1, 2)
      state_dict[prefix+'attn_v_b.weight'] = kv[:, nope:]
      if (scale:=state_dict.get(prefix+'attn_k_b.weight_scale_inv')) is not None:
        # Repeat scales to align their blocks with each head's K/V slices.
        scales = scale.repeat_interleave(block_size[0] // step, -2)[:w.shape[0] // step].reshape(config.n_heads, -1, scale.shape[-1])
        state_dict[prefix+'attn_k_b.weight_scale_inv'] = scales[:, :nope // step].transpose(-1, -2)
        state_dict[prefix+'attn_v_b.weight_scale_inv'] = scales[:, nope // step:]
        block.kv_b_block_size = (step, block_size[1])
    for name, scale in state_dict.items():
      if not name.endswith('.weight_scale_inv'): continue
      projection = get_child(model, name.removesuffix('.weight_scale_inv'))
      if isinstance(projection, dict): projection['weight_scale_inv'] = scale
      else: projection.weight_scale_inv, projection.weight_block_size = scale, block_size
    nn.state.load_state_dict(model, state_dict, verbose=False, consume=True, realize=False)
    if realize:
      params = nn.state.get_parameters(model)
      packed = [s.bitcast(dtypes.uint8).contiguous() for s in params]
      Tensor.realize(*packed)
      for s, data in zip(params, packed): s.replace(data.bitcast(s.dtype))
    return model, cfg

  def _spec_jit(self, T:int):
    if T not in self._spec_jits: self._spec_jits[T] = TinyJit(self.forward_spec)
    return self._spec_jits[T]

  def warmup(self):
    try:
      self._warmup()
      # allocate the checkpoint buffers here, not inside the first request's prefill
      if self.has_recurrent_block: self._ckpt_pairs()
    finally:  # the eager pre-capture runs leave freed buffers in the allocator cache: hand that VRAM back (the display stack needs it)
      from tinygrad import Device
      for d in Device._opened_devices:
        if hasattr(Device[d].allocator, "free_cache"): Device[d].allocator.free_cache()
  def _warmup(self):
    self._warming = True
    for _ in range(2): list(zip(range(2), self.generate([0])))
    chunk_T = getattr(self, "_chunk_T", 0)
    if self.mtp is None or not chunk_T: return
    # generate() hits T=chunk_T (prefill) and T=K+1 (no accept); the chunk sizes after L accepted drafts get captured here
    K, temp = self.mtp_k, Tensor([0.0])
    v_sp = UOp.variable("start_pos", 0, self.max_context-1)
    for _ in range(2):
      for L in range(K + 1): self._spec_jit(T:=L + 1 + K)(Tensor([[0] * T], dtype="int32"), v_sp.bind(0), temp, T, L + 1)
    self._cached_tokens = []  # the extra calls rewrote the state at position 0
    self._warming, self._ckpt_tokens = False, None

  # ---- recurrent-state checkpoints: a chat turn's next prompt extends the previous *prompt*, not the cached sequence (the template
  # strips the reasoning of earlier answers, a tool call comes back with its result appended), and GDN state cannot be rewound. so the
  # state during each prefill is kept aside and the next request resumes from it, prefilling only the answer as the client renders it
  # + the new message instead of the whole conversation.
  # the checkpoint is taken one token BEFORE the end of the prompt. the tokenizer splits on special tokens, so everything up to the
  # closing <|im_end|> re-tokenizes identically next turn, but the prompt's last token (the "\n" after the generation prompt's
  # <think>) merges with whatever the answer starts with and comes back as a different id: a checkpoint that included it never matched ----
  def _state_tensors(self) -> list[tuple[str, Tensor]]:
    return [(f"{i}.{n}", t) for i, b in enumerate(self.blk) if isinstance(b, GatedDeltaNetBlock)
            for n in ("conv_state", "recurrent_state") if (t := getattr(b, n, None)) is not None]
  def _ckpt_pairs(self) -> list[tuple[Tensor, Tensor]]:
    """(live state tensor, its checkpoint buffer) per recurrent state tensor, allocating the checkpoint buffers on first use"""
    st = self._state_tensors()
    if len(self._ckpt) != len(st):
      # one realize for all of them: every realize walks every live Tensor in the process (~0.04 s each here x 96 buffers: 4 s on the first request)
      self._ckpt = {k: {k.split(".")[-1]: Tensor.empty(*t.shape, dtype=t.dtype, device=t.device).contiguous()} for k, t in st}
      Tensor.realize(*[c for d in self._ckpt.values() for c in d.values()])
    return [(t, self._ckpt[k][k.split(".")[-1]]) for k, t in st]
  def _save_checkpoint(self, tokens:list[int]):
    if not self.has_recurrent_block or self._warming: return
    # direct device-to-device copies: an assign + realize walks every live Tensor in the process (~0.2 s per request here)
    for t, c in self._ckpt_pairs(): c.uop.buffer.ensure_allocated().copy_from(t.uop.buffer.ensure_allocated())
    self._ckpt_tokens = list(tokens)
  def _restore_checkpoint(self):
    for t, c in self._ckpt_pairs(): t.uop.buffer.ensure_allocated().copy_from(c.uop.buffer.ensure_allocated())

  def get_start_pos(self, tokens:list[int], media_key:tuple=()) -> int:
    # image tokens are all the same pad id: the cached prefix only counts up to the first image that differs from the cached request
    cached = self._cached_tokens
    if (cut := self._media_cut(media_key)) is not None: cached = cached[:cut]
    # recurrent state can't be partially reused after divergence: reuse it only when tokens extend the cached prefix
    if self.has_recurrent_block:
      if cached and len(cached) == len(self._cached_tokens) and len(cached) < len(tokens) and tokens[:len(cached)] == cached: return len(cached)
      ck = self._ckpt_tokens
      if ck and (cut is None or cut >= len(ck)) and len(ck) < len(tokens) and tokens[:len(ck)] == ck:
        self._restore_checkpoint()
        self._cached_tokens = list(ck)
        return len(ck)
      return 0
    prefix_len = sum(1 for _ in itertools.takewhile(lambda ab: ab[0] == ab[1], zip(tokens[:-1], cached)))
    return min(block._reusable_prefix_len(prefix_len, len(self._cached_tokens)) for block in self.blk)

  # ---- vision: image embeddings replace the <|image_pad|> tokens, attention positions follow Qwen's m-rope ----
  def _media_cut(self, media_key:tuple) -> int|None:
    """token index of the first image that differs between this request and the cached one (None: same images)"""
    for a, b in zip(media_key, self._cached_media):
      if a != b: return min(a[0], b[0])
    rest = media_key[len(self._cached_media):] or self._cached_media[len(media_key):]
    return rest[0][0] if rest else None
  def _media_spans(self, tokens:list[int], media:list) -> list[tuple[int, Any]]:
    """(start index, ImageEmbeds) per image, matched in order to the runs of image pad tokens"""
    spans, i = [], 0
    for m in media:
      while i < len(tokens) and tokens[i] != self.image_pad_id: i += 1
      if i + m.n_tokens > len(tokens) or any(t != self.image_pad_id for t in tokens[i:i + m.n_tokens]):
        raise ValueError(f"image {len(spans)} needs {m.n_tokens} pad tokens at {i}, the prompt does not match its images")
      spans.append((i, m))
      i += m.n_tokens
    return spans
  def _emb_chunk(self, spans:list[tuple[int, Any]], p:int, T:int) -> Tensor:
    """(1, T, dim) embeddings for the tokens [p, p+T): the images' rows, zeros elsewhere (the model only reads the pad rows)"""
    D = self.token_embd.weight.shape[1]
    pieces, cur = [], p
    for s, m in spans:
      a, b = max(s, p), min(s + m.n_tokens, p + T)
      if a >= b: continue
      if a > cur: pieces.append(Tensor.zeros(a - cur, D, device=m.emb.device))
      pieces.append(m.emb[a - s:b - s])
      cur = b
    if not pieces:
      if T not in self._emb_zero: self._emb_zero[T] = Tensor.zeros(1, T, D, device=self.token_embd.weight.device).contiguous().realize()
      return self._emb_zero[T]
    if cur < p + T: pieces.append(Tensor.zeros(p + T - cur, D, device=pieces[0].device))
    return Tensor.cat(*pieces, dim=0).reshape(1, T, D).contiguous().realize()
  def _set_positions(self, tokens:list[int], spans:list[tuple[int, Any]]) -> None:
    """rewrite the rope table for this prompt. text tokens count up; an image's tokens sit at (t, t+row, t+col) and the text after it
    continues at t + max(rows, cols) (Qwen m-rope, interleaved sections). the table is indexed by token index, so the attention kernels
    need no change; generated tokens keep counting up past the prompt. a text-only prompt restores the plain table"""
    if not spans and not self._pos_dirty: return
    import numpy as np
    parts, cur, i = [], 0, 0
    for s, m in spans:
      parts.append(np.repeat(np.arange(cur, cur + s - i, dtype=np.int32)[:, None], 3, axis=1))
      cur += s - i
      r = np.arange(m.n_tokens, dtype=np.int32)
      parts.append(np.stack([np.full_like(r, cur), cur + r // m.nx, cur + r % m.nx], axis=1))
      cur, i = cur + m.n_pos, s + m.n_tokens
    parts.append(np.repeat(np.arange(cur, cur + self.max_context - i, dtype=np.int32)[:, None], 3, axis=1))
    c = self.blk[0].config
    tables = {id(t): t for b in self.blk + ([self.mtp.blk] if self.mtp is not None else []) if (t := getattr(b, "freqs_cis", None)) is not None}
    if not tables: return
    n_pairs = c.rope_dim // 2
    if (sec := c.rope_sections) is not None:  # ggml interleaved m-rope: pair i -> h if i%3==1, w if i%3==2, else t (within the section sizes)
      comp = [1 if i % 3 == 1 and i < 3 * sec[1] else 2 if i % 3 == 2 and i < 3 * sec[2] else 0 for i in range(n_pairs)]
    else: comp = [0] * n_pairs
    freqs = (1.0 / (c.rope_theta ** (np.arange(0, c.rope_dim, 2, dtype=np.float32)[:n_pairs] / c.rope_dim))).astype(np.float32)
    ang = np.concatenate(parts)[:, comp].astype(np.float32) * freqs[None]  # (max_context, n_pairs): position per rope pair
    table = np.concatenate([np.cos(ang), np.sin(ang)], axis=1)
    for t in tables.values(): t.assign(Tensor(table, device=t.device)).realize()
    self._pos_dirty = bool(spans)

  def generate(self, tokens:list[int], chunk_size:int=32, temperature:float=0.0, media:list|None=None):
    # media: ImageEmbeds per image in the prompt (in order); their tokens are runs of image_pad_id in `tokens`
    spans: list[tuple[int, Any]] = self._media_spans(tokens, media or []) if self.image_pad_id is not None else []
    media_key = tuple((s, m.key) for s, m in spans)
    start_pos = self.get_start_pos(tokens, media_key)
    self._cached_media = media_key
    if self.image_pad_id is not None: self._set_positions(tokens, spans)
    # the fused AMD kernels take fixed-size chunks with a runtime count of valid tokens (one JIT capture for every prompt length)
    chunk_T = getattr(self, "_chunk_T", 0)
    if self.mtp is not None and chunk_T:
      yield from self._generate_spec(tokens, chunk_T, temperature, spans, start_pos)
      return
    if chunk_T: chunk_size = chunk_T
    elif self.has_recurrent_block and not amd_custom_kernels_supported(self.token_embd.weight.device): chunk_size = 1
    v_start_pos = UOp.variable("start_pos", 0, self.max_context-1)
    v_toks = UOp.variable("toks", 1, chunk_size)
    # TODO: use UOp.variable for temperature once float variables are supported
    temp = Tensor([temperature])
    # assign all input tokens once, then slice from start_pos for the model call (padded so a fixed chunk never runs past the end)
    t = Tensor(tokens + [0] * (self.max_context + chunk_size - len(tokens)), dtype="int32").reshape(1, -1)
    out, prompt_len = None, len(tokens)
    while len(tokens) < self.max_context:
      n_toks = min(chunk_size, len(tokens) - start_pos)
      # hold the prompt's last token back for a chunk of its own: the checkpoint is taken just before it (see _save_checkpoint)
      if start_pos < prompt_len - 1 and start_pos + n_toks >= prompt_len: n_toks = prompt_len - 1 - start_pos
      if self.config.ple: self.blk[self.config.ple.layer].ple.write_rows(tokens, start_pos, n_toks, chunk_size)
      sp, nt = v_start_pos.bind(start_pos), v_toks.bind(n_toks)
      if chunk_T and (start_pos < prompt_len or out is None):
        emb = self._emb_chunk(spans, start_pos, chunk_size) if self.image_pad_id is not None else None
        out = self(t[:, sp:sp+chunk_size], (sp,), temp, nt, emb).realize()
      else: out = self(t[:, sp:sp+nt] if start_pos < prompt_len or out is None else out, (sp,), temp).realize()
      start_pos += n_toks
      if start_pos == prompt_len - 1: self._save_checkpoint(tokens[:start_pos])
      # chunked prefill: keep processing until all prompt tokens are consumed
      if start_pos < len(tokens): continue
      tokens.append(int(out.item()))
      self._cached_tokens = tokens[:-1]
      yield tokens[-1]

  def _prompt_tensor(self, tokens:list[int], chunk_T:int) -> Tensor:
    """the prompt in one persistent device buffer (padded to max_context + chunk_T), written with a direct copy: Buffer.copy_from runs
    a single copy op without going through Tensor.realize, which would walk every live Tensor in the process (~0.2 s here)"""
    import array
    from tinygrad.device import Buffer
    n = self.max_context + chunk_T
    if getattr(self, "_prompt_buf", None) is None or self._prompt_buf.shape[1] != n:
      self._prompt_buf = Tensor.empty(1, n, dtype=dtypes.int32).contiguous().realize()
    src = memoryview(array.array("i", tokens + [0] * (n - len(tokens))))
    # Tensor.empty().realize() does not allocate (the tensor already has buffer identity): allocate before the direct copy
    self._prompt_buf.uop.buffer.ensure_allocated().copy_from(Buffer("PYTHON", n, dtypes.int32, opaque=src).ensure_allocated())
    return self._prompt_buf

  def _generate_spec(self, tokens:list[int], chunk_T:int, temperature:float=0.0, spans:list|None=None, start_pos:int|None=None):
    K = self.mtp_k
    v_start_pos = UOp.variable("start_pos", 0, self.max_context-1)
    v_toks = UOp.variable("toks", 1, chunk_T)
    # one realized tensor per distinct temperature: a fresh Tensor([temperature]) per request is realized by the first jit call,
    # and every realize walks all live Tensors (~0.2 s here)
    if not hasattr(self, "_temp_tensors"): self._temp_tensors: dict[float, Tensor] = {}
    if (temp := self._temp_tensors.get(float(temperature))) is None:
      temp = self._temp_tensors[float(temperature)] = Tensor([float(temperature)]).realize()
    p, prompt_len = self.get_start_pos(tokens) if start_pos is None else start_pos, len(tokens)
    n_acc = n_step = 0
    def run(chunk:Tensor, start_pos:int, n_tok:int|UOp, n_keep:int|UOp, emb:Tensor|None=None) -> tuple[list[int], tuple[Tensor, ...]]:
      kw = {} if emb is None else {"emb": emb}
      res, *cands = self._spec_jit(int(chunk.shape[1]))(chunk, v_start_pos.bind(start_pos), temp, n_tok, n_keep, **kw)
      return res.tolist(), tuple(cands)
    # prefill: commit every valid token (n_keep = n_tok), fill the MTP KV cache, last chunk yields the first decode chunk.
    # the whole prompt goes to the device once and each chunk is a symbolic slice of it (like generate()): a fresh Tensor per
    # chunk has to be realized by the jit, and a realize walks every live Tensor in the process (~250K here, ~0.2 s per chunk
    # of pure Python, 2026-08-26 cProfile: 6.4 of 11.4 s of a 2202-token prefill in _apply_map_to_tensors)
    t = self._prompt_tensor(tokens, chunk_T) if p < prompt_len else None
    while p < prompt_len:
      n_toks = min(chunk_T, prompt_len - p)
      # hold the prompt's last token back for a chunk of its own: the checkpoint is taken just before it (see _save_checkpoint)
      if p < prompt_len - 1 and p + n_toks == prompt_len: n_toks -= 1
      sp, nt = v_start_pos.bind(p), v_toks.bind(n_toks)
      emb = self._emb_chunk(spans or [], p, chunk_T) if self.image_pad_id is not None else None
      res, cands = run(t[:, sp:sp + chunk_T], p, nt, nt, emb)
      p += n_toks
      self._cached_tokens = tokens[:p]
      if p == prompt_len - 1: self._save_checkpoint(tokens[:p])
    first, drafts, chunk = res[n_toks - 1], res[-K:], cands[0]
    tokens.append(first)
    yield first
    # decode: chunk = U + drafts (a JIT output of the previous step), n_keep = len(U). res = [out[0..T-1], K new drafts]
    while len(tokens) < self.max_context:
      T = int(chunk.shape[1]); n_keep = T - K
      res, cands = run(chunk, p, T, n_keep)
      # the state now holds the n_keep committed tokens: record that before yielding, the consumer may close the generator at any yield
      p += n_keep
      self._cached_tokens = tokens[:p]
      n_step += 1
      L = 0
      while L < K and res[n_keep - 1 + L] == drafts[L]: L += 1
      n_acc += L
      self._mtp_accept = (n_acc, n_step)
      for t in drafts[:L] + [res[n_keep - 1 + L]]:  # the accepted drafts and the token sampled after them
        tokens.append(t)
        yield t
        if len(tokens) >= self.max_context: return
      chunk, drafts = cands[L], res[-K:]
      if DEBUG >= 1 and n_step % 32 == 0: print(f"mtp accept {n_acc}/{n_step * K} = {n_acc / n_step / K:.2f} ({n_acc / n_step + 1:.2f} tok/step)")
