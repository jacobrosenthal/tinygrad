from __future__ import annotations
import dataclasses, enum, functools, itertools, pathlib
from dataclasses import dataclass, replace
from typing import Any
from tinygrad import Tensor, nn, UOp, TinyJit, getenv, function, dtypes
from tinygrad.llm.kernels.amd import Linear, gated_delta_prefill, flash_attention, amd_custom_kernels_supported
from tinygrad.helpers import DEBUG, Timing
from tinygrad.llm.gguf import gguf_load
from tinygrad.uop.ops import resolve

@dataclass
class StateSnapshot:
  """a saved decode state: the token prefix it was computed for, the media key, and a private copy of every state buffer.
  The copies are raw Buffers moved with Buffer.copy_from (one copy op each, no Tensor.realize: a realize walks every live
  Tensor in the process, ~0.2 s here). They live on the model's device (a VRAM slot) or, once evicted, in host memory
  (device "PYTHON"): see StateSnapshot.to_host and Handler._pick_prefix_state in serve.py."""
  tokens: list[int]
  media: tuple
  bufs: list  # Buffer per Transformer.snapshot_tensors() entry
  ckpt_tokens: list[int]|None  # the prefill checkpoint that belongs to this state (see Transformer._save_checkpoint), if one was taken
  ckpt_bufs: list
  ckpts: list = dataclasses.field(default_factory=list)  # periodic checkpoints (token prefix, buffers), see Transformer._ckpts
  def nbytes(self) -> int: return sum(b.nbytes for b in self.bufs + self.ckpt_bufs) + sum(b.nbytes for _, bs in self.ckpts for b in bs)
  @property
  def on_host(self) -> bool: return bool(self.bufs) and bool(getattr(self.bufs[0].options, "host", False))
  @staticmethod
  def _host_copy(b):
    # a device-visible pinned host buffer (BufferSpec(host=True)) on the same device: the copy is one SDMA transfer over PCIe in
    # either direction. A "PYTHON" buffer instead goes through _copyout's chunked staging loop (~0.2 GB/s measured, 2026-08-26)
    from tinygrad.device import Buffer, BufferSpec
    return Buffer(b.device, b.size, b.dtype, options=BufferSpec(host=True)).ensure_allocated().copy_from(b)
  def to_host(self) -> "StateSnapshot":
    """the same snapshot with every buffer copied to host memory (frees the device copies)"""
    return StateSnapshot(self.tokens, self.media, [self._host_copy(b) for b in self.bufs], self.ckpt_tokens, [self._host_copy(b) for b in self.ckpt_bufs],
                         [(t, [self._host_copy(b) for b in bs]) for t, bs in self.ckpts])

class ExpertGating(enum.IntEnum):
  SOFTMAX = 1
  SIGMOID = 2
  SOFTMAX_WEIGHT = 3  # softmax over the top-k selected logits
  SQRT_SOFTPLUS = 4

@functools.cache
def precompute_freqs_cis(dim: int, end: int, theta: float = 10000.0, device:str|None=None) -> Tensor:
  freqs = 1.0 / (theta ** (Tensor.arange(0, dim, 2)[:(dim // 2)] / dim))
  freqs = Tensor.arange(end).unsqueeze(dim=1) * freqs.unsqueeze(dim=0)
  return freqs.cos().cat(freqs.sin(), dim=-1).clone(device)

class ExpertWeights:
  """Like Linear but with num_experts dimension. Weight shape: (num_experts, out_features, in_features)."""
  def __init__(self, num_experts:int, in_features:int, out_features:int):
    self.weight = Tensor.zeros(num_experts, out_features, in_features)
  def __call__(self, sel:Tensor, x:Tensor) -> Tensor:
    # sel: (B, T, k), x: (B, T, 1, in) or (B, T, k, in) -> output: (B, T, k, out)
    return (x.unsqueeze(-2) @ self.weight[sel].transpose(-1, -2)).contiguous().squeeze(-2)

def apply_rope(x:Tensor, freqs_cis:Tensor) -> Tensor:
  assert x.shape[-1] % 2 == 0
  cos, sin = freqs_cis.reshape(1, 1, x.shape[2], -1).chunk(2, dim=-1)
  x1, x2 = x.chunk(2, dim=-1)
  return (x1 * cos - x2 * sin).cat(x2 * cos + x1 * sin, dim=-1)

def pairwise_topk(x: Tensor, k: int) -> tuple[Tensor, Tensor]:
  n = x.shape[-1]
  vals = Tensor.arange(n).reshape(1,1,n).cast(x.dtype).expand(x.shape)
  cmp = (x.unsqueeze(-1) > x.unsqueeze(-2)) | ((x.unsqueeze(-1) == x.unsqueeze(-2)) & \
    (Tensor.arange(n).reshape(1,1,n,1) < Tensor.arange(n).reshape(1,1,1,n)))
  sel = x.const_like(0).scatter(-1, cmp.sum(axis=-1).cast('int32'), vals)[:,:,n-k:].cast('int32')
  return x.gather(-1, sel), sel

@dataclass(frozen=True)
class SSMConfig:
  conv_kernel: int
  state_size: int
  group_count: int
  time_step_rank: int
  inner_size: int
  kda: bool = False

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
  ssm: SSMConfig|None = None
  shared_expert_gate: bool = True
  leading_dense_blocks: int = 0
  dense_hidden_dim: int = 0
  routed_scaling_factor: float = 1.0
  qkv_bias: bool = False
  expert_bias: bool = False
  rope_sections: tuple[int, ...]|None = None  # m-rope (t, h, w, extra) pair counts per section, interleaved (Qwen3-VL / Qwen3.5)

class FFNBlock:
  def __init__(self, config:TransformerConfig):
    self.config = config

    # --- RMSNorms --------------------------------------------------------
    self.attn_norm   = nn.RMSNorm(config.dim, config.norm_eps)
    self.ffn_norm    = nn.RMSNorm(config.dim, config.norm_eps)

    # --- feed-forward (MoE or dense) -------------------------------------
    if config.num_experts > 0:
      self.ffn_gate_inp = Linear(config.dim, config.num_experts, bias=False)  # router
      if config.expert_bias: self.exp_probs_b = {"bias": Tensor.zeros(config.num_experts)}
      self.ffn_gate_exps = ExpertWeights(config.num_experts, config.dim, config.hidden_dim)
      self.ffn_up_exps = ExpertWeights(config.num_experts, config.dim, config.hidden_dim)
      self.ffn_down_exps = ExpertWeights(config.num_experts, config.hidden_dim, config.dim)
      if config.shared_expert_dim > 0:
        self.ffn_gate_shexp = Linear(config.dim, config.shared_expert_dim, bias=False)
        self.ffn_up_shexp = Linear(config.dim, config.shared_expert_dim, bias=False)
        self.ffn_down_shexp = Linear(config.shared_expert_dim, config.dim, bias=False)
        if config.shared_expert_gate: self.ffn_gate_inp_shexp = {"weight": Tensor.zeros(config.dim)}
    else:
      self.ffn_gate    = Linear(config.dim, config.hidden_dim, bias=False)
      self.ffn_up      = Linear(config.dim, config.hidden_dim, bias=False)
      self.ffn_down    = Linear(config.hidden_dim, config.dim, bias=False)

  def _feed_forward(self, x:Tensor) -> Tensor:
    if hasattr(self, 'ffn_gate_exps'):
      h = x.unsqueeze(2)  # (B, T, 1, D) - add expert dim for broadcasting
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
      x_down = self.ffn_down_exps(sel, (self.ffn_gate_exps(sel, h).silu() * self.ffn_up_exps(sel, h)).contiguous())  # (B, T, k, D)
      out = (x_down * probs.unsqueeze(-1)).sum(axis=2)  # (B, T, D)
      if hasattr(self, 'ffn_gate_shexp'):
        shexp = self.ffn_down_shexp(self.ffn_gate_shexp(x).silu().contiguous() * self.ffn_up_shexp(x))
        if hasattr(self, 'ffn_gate_inp_shexp'): shexp = shexp * (x * self.ffn_gate_inp_shexp["weight"]).sum(axis=-1, keepdim=True).sigmoid()
        out = out + shexp
      return out
    if hasattr(self.ffn_down, "_ggml") and self._n_fused(x):
      from tinygrad.llm import amd_gemv
      return self.ffn_down(amd_gemv.silu_mul_quant(self.ffn_gate(x), self.ffn_up(x)))
    # TODO: remove the need for this contiguous
    return self.ffn_down(self.ffn_gate(x).silu().contiguous() * self.ffn_up(x))

  # given the token-prefix match, return how much cached state this block can still reuse
  def _reusable_prefix_len(self, prefix_len:int, cached_len:int) -> int: return prefix_len
  def _init_state(self, x:Tensor): raise NotImplementedError
  def _attention(self, x:Tensor, start_pos:int|UOp, residual:Tensor|None=None, n_tok:int|UOp|None=None) -> Tensor: raise NotImplementedError

  def __call__(self, x: Tensor, start_pos: int|UOp, n_tok:int|UOp|None=None):
    self._init_state(x)
    if self._decode_fused(x): return self._run_decode(x, start_pos, n_tok)
    assert n_tok is None, "padded token chunks need the fused decode path"
    # we pass in the weights implicitly so we unpack the GGUF on the fly
    @function(precompile=True, allow_implicit=True)
    def _run(x:Tensor, start_pos:int|UOp):
      h =     x + self._attention(self.attn_norm(x), start_pos)
      return (h + self._feed_forward(self.ffn_norm(h))).contiguous()
    return _run(x, start_pos)

  # number of tokens x holds if it is a batch the fused AMD kernels take (B=1, T <= MAX_T), else 0
  @staticmethod
  def _n_fused(x:Tensor) -> int:
    from tinygrad.llm.amd_gemv import fused_T
    return x.shape[1] if x.shape[0] == 1 and isinstance(x.shape[1], int) and fused_T(x.shape[1]) else 0
  # decode of up to MAX_T tokens with the packed-weight kernels: no function boundary (it copies in and out), residual adds fused into
  # the gemv epilogues. n_tok (runtime) is the number of valid tokens of a padded chunk
  def _decode_fused(self, x:Tensor) -> bool:
    return bool(self._n_fused(x)) and hasattr(self.ffn_down, "_ggml") and hasattr(self.attn_output_linear(), "_ggml")
  def attn_output_linear(self) -> Linear: return self.attn_output
  def _run_decode(self, x:Tensor, start_pos:int|UOp, n_tok:int|UOp|None=None) -> Tensor:
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
    self.attn_output = Linear(config.head_dim * config.n_heads, config.dim, bias=False)
    if config.qk_norm: self.attn_q_norm, self.attn_k_norm = nn.RMSNorm(config.qk_norm, config.norm_eps), nn.RMSNorm(config.qk_norm, config.norm_eps)

  def _attention_fused(self, x:Tensor, start_pos:int|UOp, residual:Tensor, n_tok:int|UOp|None) -> Tensor:
    # decode on AMD: fused attention kernel pairs (norm + rope + cache write + flash-decoding) per token, same math as _attention
    from tinygrad.llm import amd_gemv
    c = self.config
    T = x.shape[1]
    q, k, v = amd_gemv.linear_decode_multi([self.attn_q, self.attn_k, self.attn_v], x)
    qk = c.qk_norm == c.head_dim
    if not hasattr(self, "_attn_params"):
      self._attn_params = (self.attn_q_norm.weight.float().contiguous().realize(), self.attn_k_norm.weight.float().contiguous().realize()) if qk else (None, None)
    qnw, knw = self._attn_params
    attn = amd_gemv.attn_decode(self.cache_kv, q, k, v, qnw, knw, self.freqs_cis, start_pos, c.n_heads, c.n_kv_heads, c.head_dim, c.rope_dim,
                                self.kv_maxc, c.norm_eps, c.attn_output_gate, T, n_tok, self.kv_quant)
    return amd_gemv.linear_decode(self.attn_output, attn.reshape(1, T, -1), residual=residual)

  def _fused_ok(self) -> bool:
    c = self.config
    return all(hasattr(l, "_ggml") for l in (self.attn_q, self.attn_k, self.attn_v)) and bool(getenv("AMD_ATTN", 1)) and \
       c.head_dim == 256 and c.n_heads % c.n_kv_heads == 0 and c.n_heads // c.n_kv_heads <= 8 and c.qk_norm in (0, c.head_dim) and \
       c.rope_dim <= 64 and (self.cache_kv.dtype == dtypes.float32 or self.kv_quant is not None)

  def _attention(self, x:Tensor, start_pos:int|UOp, residual:Tensor|None=None, n_tok:int|UOp|None=None) -> Tensor:
    if residual is not None and self._n_fused(x) and self._fused_ok(): return self._attention_fused(x, start_pos, residual, n_tok)
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

    q = apply_rope(q[..., :self.config.rope_dim], self.freqs_cis[start_pos:start_pos+T]).cat(q[..., self.config.rope_dim:], dim=-1)
    k = apply_rope(k[..., :self.config.rope_dim], self.freqs_cis[start_pos:start_pos+T]).cat(k[..., self.config.rope_dim:], dim=-1)

    # NOTE: we don't want to change self.cache_kv, the function API doesn't support this well
    store = self.cache_kv[:, :, :, start_pos:start_pos+T, :].uop.store(Tensor.stack(k, v).cast(dtypes.half).uop)
    assigned_kv = Tensor(self.cache_kv.uop.after(store))
    # on RDNA3, hybrid models use custom flash attention kernels on the KV cache
    if amd_custom_kernels_supported(x.device) and self.config.ssm is not None:
      attn = flash_attention(q, assigned_kv, start_pos+T)
      attn = attn.transpose(1, 2).reshape(B, T, -1)                                    # back to (B,T,D)
      return self.attn_output(attn if not self.config.attn_output_gate else (attn * gate.sigmoid()))
    k = assigned_kv[0, :, :, 0:start_pos+T, :]
    v = assigned_kv[1, :, :, 0:start_pos+T, :]

    #self.cache_kv[:, :, :, start_pos:start_pos+T, :].assign(Tensor.stack(k, v))
    #k = self.cache_kv[0, :, :, 0:start_pos+T, :]
    #v = self.cache_kv[1, :, :, 0:start_pos+T, :]

    # NOTE: this mask is causal_lower_right, not the causal_upper_left generated by is_casual = True
    # TODO: this if statement should be removed and it shouldn't generate extra kernels
    mask = Tensor.full((1, 1, T, start_pos+T), float("-inf"), dtype=x.dtype, buffer=False).triu(start_pos+1) \
      if resolve(T != 1) else None
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
      # the fused attention kernel (AMD, head_dim 256) keeps a quantized cache; every other path uses the dense f32 one
      if x.shape[0] == 1 and all(hasattr(l, "_ggml") for l in (self.attn_q, self.attn_k, self.attn_v)) and getenv("AMD_ATTN", 1) and \
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
        self.cache_kv = Tensor.zeros(2, x.shape[0], c.n_kv_heads, self.kv_maxc, c.head_dim, dtype=dtypes.default_float, device=x.device)
      self.freqs_cis = precompute_freqs_cis(self.config.rope_dim, self.kv_maxc, self.config.rope_theta, device=x.device)

class MLATransformerBlock(FFNBlock):
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

  def _attention(self, x:Tensor, start_pos:int|UOp, residual:Tensor|None=None, n_tok:int|UOp|None=None) -> Tensor:
    assert residual is None and n_tok is None
    B, T, _ = x.shape
    q_nope_head_dim = self.config.head_dim - self.config.rope_dim
    q_proj = self.attn_q_b(self.attn_q_a_norm(self.attn_q_a(x))) if self.config.q_lora_rank > 0 else self.attn_q(x)
    q = q_proj.reshape(B, T, self.config.n_heads, self.config.head_dim).transpose(1, 2)
    q_nope, q_rope = q[..., :q_nope_head_dim], q[..., q_nope_head_dim:]
    if not self.config.ssm or not self.config.ssm.kda: q_rope = apply_rope(q_rope, self.freqs_cis[start_pos:start_pos+T])
    q = (q_nope @ self.attn_k_b["weight"].transpose(-1, -2)).cat(q_rope, dim=-1)

    kv_a = self.attn_kv_a_mqa(x)
    c_kv = self.attn_kv_a_norm(kv_a[..., :self.config.kv_lora_rank])
    k_rope = kv_a[..., self.config.kv_lora_rank:].reshape(B, T, 1, self.config.rope_dim).transpose(1, 2)
    if not self.config.ssm or not self.config.ssm.kda: k_rope = apply_rope(k_rope, self.freqs_cis[start_pos:start_pos+T])

    k_store = c_kv.reshape(B, 1, T, self.config.kv_lora_rank).cat(k_rope.reshape(B, 1, T, self.config.rope_dim), dim=-1)
    k = Tensor(self.cache_k.uop.after(self.cache_k[:, :, start_pos:start_pos+T, :].uop.store(k_store.uop)))[:, :, 0:start_pos+T, :]
    v = k[..., :self.config.kv_lora_rank]

    mask = Tensor.full((1, 1, T, start_pos+T), float("-inf"), dtype=x.dtype, buffer=False).triu(start_pos+1) \
      if resolve(T != 1) else None
    attn = q @ k.transpose(-1, -2) * (1.0 / self.config.head_dim ** 0.5)
    if mask is not None: attn = attn + mask
    attn = attn.softmax(-1)
    attn = ((attn @ v) @ self.attn_v_b["weight"].transpose(-1, -2)).transpose(1, 2).reshape(B, T, -1)
    return self.attn_output(attn)

  def _init_state(self, x:Tensor):
    if not hasattr(self, "cache_k"):
      self.kv_maxc = self.config.max_context + getenv("MAX_T", 8)  # slack so a chunk straddling the ceiling fits (see FFNBlock._init_state)
      self.cache_k = Tensor.empty(x.shape[0], 1, self.kv_maxc, self.config.kv_lora_rank + self.config.rope_dim, device=x.device)
      self.freqs_cis = precompute_freqs_cis(self.config.rope_dim, self.kv_maxc, self.config.rope_theta, device=x.device)

class GatedDeltaNetBlock(FFNBlock):
  def __init__(self, config:TransformerConfig, ssm:SSMConfig):
    super().__init__(config)
    self.head_k_dim, self.num_k_heads, self.num_v_heads = ssm.state_size, ssm.group_count, ssm.time_step_rank
    assert self.num_v_heads % self.num_k_heads == 0
    self.head_v_dim, self.ssm_conv_kernel = ssm.inner_size // ssm.time_step_rank, ssm.conv_kernel
    self.conv_channels, self.q_dim = ssm.inner_size + 2*ssm.group_count*ssm.state_size, ssm.state_size*ssm.group_count
    self.attn_qkv = Linear(config.dim, self.conv_channels, bias=False)
    if ssm.kda:
      self.ssm_g_a, self.ssm_g_b = Linear(config.dim, self.head_v_dim, bias=False), Linear(self.head_v_dim, ssm.inner_size, bias=False)
      self.ssm_f_a, self.ssm_f_b = Linear(config.dim, self.head_k_dim, bias=False), Linear(self.head_k_dim, ssm.inner_size, bias=False)
    else:
      self.attn_gate = Linear(config.dim, ssm.inner_size, bias=False)
      self.ssm_alpha = Linear(config.dim, self.num_v_heads, bias=False)
    self.ssm_beta = Linear(config.dim, self.num_v_heads, bias=False)
    self.ssm_conv1d = {"weight": Tensor.zeros(self.conv_channels, self.ssm_conv_kernel)}
    self.ssm_dt = {"bias": Tensor.zeros(ssm.inner_size if ssm.kda else self.num_v_heads)}
    self.ssm_a = Tensor.zeros(self.num_v_heads, 1) if ssm.kda else Tensor.zeros(self.num_v_heads)
    self.ssm_norm, self.ssm_out = nn.RMSNorm(self.head_v_dim, config.norm_eps), Linear(ssm.inner_size, config.dim, bias=False)

  def attn_output_linear(self) -> Linear: return self.ssm_out
  def _attention_fused(self, x:Tensor, start_pos:int|UOp, residual:Tensor|None, n_tok:int|UOp|None) -> Tensor:
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
    return not hasattr(self, "ssm_g_a") and hasattr(self.attn_qkv, "_ggml") and self.conv_state.dtype == dtypes.float32 and \
       self.recurrent_state.dtype == dtypes.float32 and bool(getenv("AMD_GDN", 1))

  def _attention(self, x:Tensor, start_pos:int|UOp, residual:Tensor|None=None, n_tok:int|UOp|None=None) -> Tensor:
    B, T, _ = x.shape
    # bind ints to a variable so the reset flag stays a runtime value (it toggles when generation restarts at position 0)
    start_pos = start_pos if isinstance(start_pos, UOp) else UOp.variable("start_pos", 0, self.config.max_context-1).bind(start_pos)
    is_kda = hasattr(self, "ssm_g_a")
    if self._n_fused(x) and self._fused_ok(): return self._attention_fused(x, start_pos, residual, n_tok)
    assert residual is None and n_tok is None
    initial = Tensor(start_pos).eq(0)
    symbolic = isinstance(T, UOp)
    T_pad = x.max_shape[1]  # symbolic chunks are padded to their max size: one graph serves every size

    # input processing
    x = x.half()
    out_gate = self.ssm_g_b(self.ssm_g_a(x)) if is_kda else self.attn_gate(x)
    out_gate = out_gate.reshape(B, T, self.num_v_heads, self.head_v_dim)
    beta = self.ssm_beta(x).sigmoid().reshape(B, T, self.num_v_heads)
    alpha = self.ssm_f_b(self.ssm_f_a(x)) if is_kda else self.ssm_alpha(x)
    log_alpha = ((alpha.float() + self.ssm_dt["bias"]).softplus().reshape(B, T, self.num_v_heads, -1) *
                 self.ssm_a.reshape(self.num_v_heads, -1))

    # qkv conv, conv_state is reset when starting from position 0
    conv_state = initial.where(0, self.conv_state)
    # assemble the conv window in a static-size buffer: [conv_state | qkv rows | zero-pad].
    # padded steps are exact no-ops: beta=0 (delta rule off), log_alpha=0 (decay 1 after exp)
    win = Tensor.zeros(B, self.ssm_conv_kernel-1 + T_pad, self.conv_channels).uop
    win = win.after(win[:, :self.ssm_conv_kernel-1].store(conv_state.cast(win.dtype).uop))
    win = win.after(win[:, self.ssm_conv_kernel-1:self.ssm_conv_kernel-1+T].store(self.attn_qkv(x).cast(win.dtype).uop))
    conv_window = Tensor(win)
    # the last conv_kernel-1 columns of the window become the next conv state
    conv_state_store = self.conv_state.uop.store(conv_window[:, T:T+self.ssm_conv_kernel-1].cast(self.conv_state.dtype).uop)

    conv_out = functools.reduce(lambda a,b: a+b,
      (conv_window[:, i:i+T_pad] * self.ssm_conv1d["weight"][:, i] for i in range(self.ssm_conv_kernel))).silu()
    if symbolic:
      out_gate = out_gate.pad_to((B, T_pad, self.num_v_heads, self.head_v_dim))
      beta, log_alpha = beta.pad_to((B, T_pad, self.num_v_heads)), log_alpha.pad_to((B, T_pad, *log_alpha.shape[2:]))
    q, k, v = conv_out.split([self.q_dim, self.q_dim, self.conv_channels - 2*self.q_dim], dim=-1)
    qk_eps = 1e-12 if is_kda else 1e-6
    q, k = (z.reshape(B, T_pad, self.num_k_heads, self.head_k_dim).normalize(dim=-1, eps=qk_eps)
            .repeat(1, 1, self.num_v_heads//self.num_k_heads, 1) for z in (q, k))
    v = v.reshape(B, T_pad, self.num_v_heads, self.head_v_dim)
    # layout the per-step operands to broadcast against the (B, H, V, K) state
    q, k, v, beta = (z.transpose(1, 2).float() for z in (q, k, v, beta))
    q = q * self.head_k_dim**-0.5
    alpha = log_alpha.transpose(1, 2).exp()  # per-channel decay for kda, per-head otherwise (B, H, T, V|1)

    # recurrent: scan over the (padded) tokens, updating the recurrent state. collect the per-step outputs
    state = Tensor(self.recurrent_state.uop.after(conv_state_store))  # carry the conv write into this graph
    if self.head_k_dim % 32 == 0 and self.head_v_dim % 4 == 0 and amd_custom_kernels_supported(x.device):
      # one fused kernel for the whole scan; it resets and updates the recurrent state in place (RDNA3)
      core = gated_delta_prefill(q, k, v, beta, alpha, state, Tensor(start_pos)).transpose(1, 2)
    else:
      q, k, v, beta = q.unsqueeze(-2), k.unsqueeze(-2), v.unsqueeze(-1), beta.unsqueeze(-1).unsqueeze(-1)
      alpha = alpha.unsqueeze(-1)
      state = initial.where(0, state.float())
      outs = []
      for t in range(T_pad):
        s1 = state * alpha[:, :, t]  # decay the state
        delta = (v[:, :, t] - (s1*k[:, :, t]).sum(-1, keepdim=True)) * beta[:, :, t]  # the delta rule update
        state = s1 + delta * k[:, :, t]
        outs.append((state * q[:, :, t]).sum(-1))

      # store the updated recurrent state in place, then read the stacked outputs after the write
      state_store = self.recurrent_state.uop.store(state.cast(self.recurrent_state.dtype).uop)
      core = Tensor(outs[0].stack(*outs[1:], dim=1).contiguous().uop.after(state_store))

    # output; undo the padding before the output projection
    z = (self.ssm_norm(core) * (out_gate.sigmoid() if is_kda else out_gate.silu())).cast(x.dtype).contiguous()
    if symbolic: z = z[:, :T]
    return self.ssm_out(z.reshape(B, T, -1))

  def _init_state(self, x):
    if not hasattr(self, "conv_state"):
      self.conv_state = Tensor.zeros(x.shape[0], self.ssm_conv_kernel-1, self.conv_channels, device=x.device).clone()
      self.recurrent_state = Tensor.zeros(x.shape[0], self.num_v_heads, self.head_v_dim, self.head_k_dim, device=x.device).clone()
      if hasattr(self.attn_qkv, "_ggml"):  # f32 copies of the small params for the fused decode kernels, realized outside the function capture
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
    return self.blk(self.eh_proj(self.enorm(next_emb).cat(self.hnorm(hidden), dim=-1)), start_pos, n_tok)

class Transformer:
  def __init__(self, config:TransformerConfig):
    dense_config = replace(config, num_experts=0, num_experts_per_tok=0, shared_expert_dim=0, hidden_dim=config.dense_hidden_dim or config.hidden_dim)
    if config.ssm: config = replace(config, qk_norm=config.head_dim)
    block_cls = MLATransformerBlock if config.kv_lora_rank > 0 else TransformerBlock
    self.blk:list[FFNBlock] = [GatedDeltaNetBlock(dense_config if i < config.leading_dense_blocks else config, config.ssm)
                               if config.ssm and config.ssm_layers[i] else
                               block_cls(dense_config if i < config.leading_dense_blocks else config) for i in range(config.num_blocks)]
    self.token_embd  = nn.Embedding(config.vocab_size, config.dim)
    self.output_norm = nn.RMSNorm(config.dim, config.norm_eps)
    self.output = Linear(config.dim, config.vocab_size, bias=False)
    self.max_context = config.max_context
    self.has_recurrent_block = any(isinstance(b, GatedDeltaNetBlock) for b in self.blk)
    self._cached_tokens: list[int] = []
    # recurrent-state checkpoint taken after every prompt prefill (see _save_checkpoint); the dict keys end in the _TRANSIENT names so
    # tinygrad.llm.cache drops the buffers like the live state
    self._ckpt: dict[str, dict[str, Tensor]] = {}
    self._ckpt_tokens: list[int]|None = None
    # periodic recurrent-state checkpoints along the live conversation (--checkpoints N every --checkpoint-every tokens): a request that
    # diverges mid-conversation (compaction, an edited tool result, a new session sharing the system prompt) resumes from the longest
    # one it still extends instead of token 0. ~100 MB each here; valid while the kv cache holds the same prefix (see get_start_pos)
    self._ckpts: list[tuple[list[int], list]] = []
    self._ckpt_max, self._ckpt_every = 0, 4096
    self._warming = False
    # vision: set when an encoder is attached. image tokens (the pad id) take their embeddings from an `emb` input of the prefill chunk
    self.image_pad_id: int|None = None
    self._cached_media: tuple = ()
    self._emb_zero: dict[int, Tensor] = {}
    self._pos_dirty = False
    self.mtp: MTPModule|None = None
    self.mtp_k = 1
    # top_p/top_k: server-fixed (see _apply_top_pk), set by from_gguf from the --top-p/--top-k CLI flags.
    # disabled (1.0 / 0) unless set -- matches the old temperature-only sampling behavior.
    self.top_p, self.top_k = 1.0, 0
    self._spec_jits: dict = {}
    # we specialize the JIT for prefill and rollout
    self.prefill_jit = TinyJit(self.forward)
    self.rollout_jit = TinyJit(self.forward)

  def _embed(self, tokens:Tensor, emb:Tensor|None) -> Tensor:
    x = self.token_embd(tokens).float()                   # (B, T, D)
    # image tokens take the rows of `emb` (vision encoder output placed at their positions, zeros elsewhere)
    return x if emb is None else (tokens == self.image_pad_id).unsqueeze(-1).where(emb, x)

  def forward(self, tokens:Tensor, start_pos:int|UOp, temperature:Tensor, n_tok:int|UOp|None=None, emb:Tensor|None=None) -> Tensor:
    # n_tok: number of valid tokens when `tokens` is a padded fixed-size chunk (fused AMD path), the rest are ignored
    if hasattr(self, "_ggml_raw"):
      from tinygrad.llm import amd_gemv
      amd_gemv.new_forward()
    x = self._embed(tokens, emb)
    for block in self.blk: x = block(x, start_pos, n_tok)
    # only run the output projection on the last (valid) token
    last = x[:, -1:] if n_tok is None else x.shrink((None, (n_tok - 1, n_tok), None)).contiguous()
    logits = self.output(self.output_norm(last))[:, -1, :]
    logits = Transformer._apply_top_pk(logits, self.top_p, self.top_k)
    # Gumbel-max trick: argmax(logits/temp - log(-log(uniform))) is equivalent to sampling from softmax(logits/temp)
    return (logits / temperature.maximum(1e-12) - (Tensor.rand_like(logits).maximum(1e-12).log().neg()).log()).argmax(-1, keepdim=True)

  @staticmethod
  def _apply_top_pk(logits:Tensor, top_p:float, top_k:int) -> Tensor:
    """Server-fixed top_k/top_p filtering (set at startup from the --top-p/--top-k CLI flags, baked
    into the JIT graph as Python constants). Not a per-request parameter: tinygrad's
    topk/sort need a static k, and the fused AMD/MTP graphs are already expensive to (re)compile
    (see docs/development/qwen38-mtp-fork-splizard.md), so this must stay fixed for the server's
    lifetime like MTP/KV_QUANT rather than vary per request like temperature does.
    top_k=0 or top_p>=1.0 disables the respective filter (matches vLLM/SGLang semantics).

    The top_k candidates come from k rounds of max()+mask-out (iterative argmax), NOT Tensor.topk:
    topk() is sort()+slice, and sort() is a bitonic sort over the whole ~152K vocab (padded to 2^18,
    18 stages) that expanded to ~1300 kernels per sampling site -- one warmup graph took 273s just to
    *schedule* ("scheduled 1475 kernels in 272891 ms", 2026-08-25 sweep) and blew the 30-minute
    startup timeout. k rounds of max() over the vocab is ~2k tiny kernels instead.
    top_p is the nucleus over those candidates (a descending prefix, so its threshold is the smallest
    kept value). With top_p but no top_k the candidate set is capped at _TOP_P_ONLY_CANDIDATES --
    an approximation for flat distributions; Qwen's recommended profile always pairs the two."""
    use_k, use_p = bool(top_k and top_k > 0), bool(top_p and top_p < 1.0)
    if not (use_k or use_p): return logits
    k = min(top_k if use_k else Transformer._TOP_P_ONLY_CANDIDATES, int(logits.shape[-1]))
    vals, cur = [], logits
    for _ in range(k):
      m = cur.max(axis=-1, keepdim=True)
      vals.append(m)
      cur = (cur >= m).where(-float("inf"), cur)
    cand = Tensor.cat(*vals, dim=-1)  # (..., k), descending
    if use_p:
      probs = cand.softmax(-1)
      excl_cum = probs.cumsum(-1) - probs  # probability mass strictly before each candidate
      # keep candidates until the mass before them reaches top_p; position 0 (excl_cum=0) always qualifies
      thresh = (excl_cum < top_p).where(cand, float("inf")).min(axis=-1, keepdim=True)
    else:
      thresh = cand[..., -1:]
    return (logits < thresh).where(-float("inf"), logits)

  _TOP_P_ONLY_CANDIDATES = 64

  @staticmethod
  def _sample_rows(logits:Tensor, temperature:Tensor, top_p:float=1.0, top_k:int=0) -> Tensor:
    # per-row Gumbel-max sampling (same as _sample): the draft is verified by sample-then-compare so temperature>0 stays lossless
    logits = Transformer._apply_top_pk(logits, top_p, top_k)
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
      x = block(x, start_pos, n_tok)
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
      out_last = Transformer._sample_rows(self.output(self.output_norm(lastx)), temperature, self.top_p, self.top_k).reshape(1).cast(dtypes.int32)
      out = out_last.expand(T).contiguous()
    else: out = Transformer._sample_rows(self.output(self.output_norm(x)), temperature, self.top_p, self.top_k).reshape(T).cast(dtypes.int32)
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
    drafts = [Transformer._sample_rows(self.output(self.mtp.shared_head_norm(h)), temperature, self.top_p, self.top_k).reshape(1).cast(dtypes.int32)]
    for k in range(1, K):
      amd_gemv.new_forward(1)
      h = self.mtp(h, self.token_embd(drafts[-1].reshape(1, 1)).float(), (j_last + start_pos) + k, 1)  # Tensor + UOp works, not UOp + Tensor
      drafts.append(Transformer._sample_rows(self.output(self.mtp.shared_head_norm(h)), temperature, self.top_p, self.top_k).reshape(1).cast(dtypes.int32))
    draft = drafts[0].cat(*drafts[1:]) if K > 1 else drafts[0]
    # candidate next chunks: L accepted -> U = drafts[:L] + [out[n_keep-1+L]], chunk = U + new drafts
    last = pick(out, j_last)
    if prefill: cands = [last.cat(draft).reshape(1, 1 + K).contiguous()]
    else: cands = [chunk[n_keep:n_keep+L].cat(out[n_keep-1+L:n_keep+L], draft).reshape(1, L + 1 + K).contiguous() for L in range(K + 1)]
    res = out.cat(draft).contiguous()
    amd_gemv.end_forward()
    return (res, *cands)

  def __call__(self, tokens:Tensor, start_pos:int|UOp, temperature:Tensor, n_tok:int|UOp|None=None, emb:Tensor|None=None) -> Tensor:
    jit = self.prefill_jit if resolve(tokens.shape[1] != 1) else self.rollout_jit
    kw = {} if emb is None else {"emb": emb}
    if n_tok is not None: return jit(tokens.contiguous(), start_pos, temperature, n_tok, **kw)
    return jit(tokens.contiguous(), start_pos, temperature, **kw)

  @staticmethod
  def from_gguf(gguf:Tensor|str|pathlib.Path, max_context:int|None=None,
                realize=bool(getenv("REALIZE", 0)), vision:bool=False, top_p:float=1.0, top_k:int=0) -> tuple[Transformer, dict]:
    # vision: the prefill jits take the image-embedding input (the pad token id is set by the caller before warmup)
    # top_p/top_k: sampling filters baked into the captured jits (see _apply_top_pk), so they are part of the cache key below
    # a warmed-up model may be cached whole (weights re-uploaded, jits unpickled): ~seconds instead of a full load + warmup
    extra = " ".join(s for s in ["vision" if vision else "", f"top_p={top_p}" if top_p < 1.0 else "", f"top_k={top_k}" if top_k > 0 else ""] if s)
    if not isinstance(gguf, Tensor):
      from tinygrad.llm.cache import load_llm_cache
      if (cached:=load_llm_cache(str(gguf), max_context, extra)) is not None:
        cached[0]._from_cache, cached[0]._cache_extra = True, extra
        return cached

    # TODO: remove the need for copy to default device
    raw: dict = {}
    kv, state_dict = gguf_load(gguf.to(None).realize() if isinstance(gguf, Tensor) else gguf, raw_out=raw)

    # all state items should be float16, not float32
    state_dict = {k:v.cast('float16') if getenv("HALF", 1) else v for k,v in state_dict.items()}

    # some models like Llama 3.2 don't have an output.weight, they just tie to the token_embd.weight
    if 'output.weight' not in state_dict:
      state_dict['output.weight'] = state_dict['token_embd.weight']
      if 'token_embd.weight' in raw: raw['output.weight'] = raw['token_embd.weight']

    arch = kv['general.architecture']
    max_context = min(max_context, kv[f'{arch}.context_length']) if max_context is not None else kv[f'{arch}.context_length']
    n_heads, n_kv_heads = kv[f'{arch}.attention.head_count'], kv[f'{arch}.attention.head_count_kv']

    ssm = None
    ssm_layers: tuple[bool, ...] = ()
    if arch in ('qwen35', 'qwen35moe'):
      ssm = SSMConfig(**{k: kv[f'{arch}.ssm.{k}'] for k in ('conv_kernel','state_size','group_count','time_step_rank','inner_size')})
      ssm_layers = tuple((i+1) % kv[f'{arch}.full_attention_interval'] != 0 for i in range(kv[f'{arch}.block_count']))
    elif arch == 'kimi-linear':
      ssm_layers = tuple(x == 0 for x in n_kv_heads)
      n_kv_heads = max(n_kv_heads)
      ssm = SSMConfig(kv[f'{arch}.ssm.conv_kernel'], kv[f'{arch}.kda.head_dim'], n_heads, n_heads, n_heads*kv[f'{arch}.kda.head_dim'], kda=True)
      for i, is_ssm in enumerate(ssm_layers):
        if not is_ssm: continue
        state_dict[f"blk.{i}.attn_qkv.weight"] = state_dict.pop(f"blk.{i}.attn_q.weight").cat(
          state_dict.pop(f"blk.{i}.attn_k.weight"), state_dict.pop(f"blk.{i}.attn_v.weight"), dim=0).contiguous()
        state_dict[f"blk.{i}.ssm_conv1d.weight"] = state_dict.pop(f"blk.{i}.ssm_conv1d_q.weight").cat(
          state_dict.pop(f"blk.{i}.ssm_conv1d_k.weight"), state_dict.pop(f"blk.{i}.ssm_conv1d_v.weight"), dim=0).squeeze(1).contiguous()
        state_dict[f"blk.{i}.ssm_out.weight"] = state_dict.pop(f"blk.{i}.attn_output.weight")
    if arch in ('qwen35', 'qwen35moe', 'glm4moe'):
      state_dict = {k.replace('post_attention_norm', 'ffn_norm'):v for k,v in state_dict.items()}

    kv_lora_rank = kv.get(f'{arch}.attention.kv_lora_rank', 0)
    head_dim = kv.get(f'{arch}.attention.key_length_mla', kv.get(f'{arch}.attention.key_length', kv[f'{arch}.embedding_length'] // n_heads))
    rope_dim = kv.get(f'{arch}.rope.dimension_count', head_dim)

    # Permute RoPE weights from interleaved to half-split layout.
    for name in state_dict:
      if arch == 'kimi-linear': continue
      if ('attn_q.weight' in name or 'attn_q_b.weight' in name) and (arch == 'llama' or kv_lora_rank):
        w = state_dict[name].reshape(n_heads, state_dict[name].shape[0]//n_heads, -1)
        prefix = head_dim-rope_dim
        state_dict[name] = w[:, :prefix].cat(w[:, prefix:].rearrange("n (h two) d -> n (two h) d", two=2), dim=1).reshape(-1, w.shape[-1])
      elif arch == 'llama' and 'attn_k.weight' in name:
        w = state_dict[name].reshape(n_kv_heads, state_dict[name].shape[0]//n_kv_heads, -1)
        state_dict[name] = w.rearrange("n (h two) d -> n (two h) d", two=2).reshape(-1, w.shape[-1])
      elif kv_lora_rank and 'attn_kv_a_mqa.weight' in name:
        state_dict[name] = state_dict[name][:kv_lora_rank].cat(state_dict[name][kv_lora_rank:].rearrange("(h two) d -> (two h) d", two=2), dim=0)
    config = TransformerConfig(
      num_blocks=kv[f'{arch}.block_count'] - kv.get(f'{arch}.nextn_predict_layers', 0), dim=kv[f'{arch}.embedding_length'],
      hidden_dim=kv.get(f'{arch}.expert_feed_forward_length', kv.get(f'{arch}.feed_forward_length', 0)),
      n_heads=n_heads, n_kv_heads=n_kv_heads, norm_eps=kv[f'{arch}.attention.layer_norm_rms_epsilon'],
      vocab_size=len(kv['tokenizer.ggml.tokens']),
      head_dim=head_dim,
      rope_theta=kv[f'{arch}.rope.freq_base'],
      rope_dim=rope_dim,
      rope_sections=tuple(kv[k]) if (k:=f'{arch}.rope.dimension_sections') in kv else None,
      v_head_dim=kv.get(f'{arch}.attention.value_length_mla', kv.get(f'{arch}.attention.value_length', head_dim)),
      max_context=max_context,
      qk_norm=int(state_dict['blk.0.attn_q_norm.weight'].shape[0]) if 'blk.0.attn_q_norm.weight' in state_dict else 0,
      num_experts=kv.get(f'{arch}.expert_count', 0), num_experts_per_tok=kv.get(f'{arch}.expert_used_count', 0),
      norm_topk_prob=kv.get(f'{arch}.expert_weights_norm', arch in ('qwen3moe', 'qwen35moe', 'kimi-linear')),
      expert_gating_func=ExpertGating(kv.get(f'{arch}.expert_gating_func', ExpertGating.SOFTMAX)),
      kv_lora_rank=kv_lora_rank, q_lora_rank=kv.get(f'{arch}.attention.q_lora_rank', 0),
      leading_dense_blocks=kv.get(f'{arch}.leading_dense_block_count', 0),
      shared_expert_dim=kv.get(
        f'{arch}.expert_shared_feed_forward_length',
        kv.get(f'{arch}.expert_shared_count', 0) * kv.get(f'{arch}.expert_feed_forward_length', 0)),
      shared_expert_gate=f"blk.{kv.get(f'{arch}.leading_dense_block_count', 0)}.ffn_gate_inp_shexp.weight" in state_dict,
      dense_hidden_dim=kv.get(f'{arch}.feed_forward_length', 0) if kv.get(f'{arch}.leading_dense_block_count', 0) else 0,
      routed_scaling_factor=kv.get(f'{arch}.expert_weights_scale', 1.0), attn_output_gate=arch in ('qwen35', 'qwen35moe'), ssm=ssm,
      ssm_layers=ssm_layers,
      qkv_bias='blk.0.attn_q.bias' in state_dict,
      expert_bias=f"blk.{kv.get(f'{arch}.leading_dense_block_count', 0)}.exp_probs_b.bias" in state_dict)
    mtp_prefix = f'blk.{config.num_blocks}.'
    if getenv("MTP", 1) and any(k.startswith(mtp_prefix) for k in state_dict):
      def _mtp_key(k:str) -> str:
        if not k.startswith(mtp_prefix): return k
        rest = k[len(mtp_prefix):]
        return 'mtp.' + rest[len('nextn.'):] if rest.startswith('nextn.') else 'mtp.blk.' + rest
      state_dict = {_mtp_key(k): v for k, v in state_dict.items()}
      for k in [k for k in raw if k.startswith(mtp_prefix)]: raw[_mtp_key(k)] = raw.pop(k)
    model = Transformer(config)
    model.top_p, model.top_k, model._cache_extra = top_p, top_k, extra  # see _apply_top_pk; the cache save in cli.py reuses extra
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
    return model, kv

  def _spec_jit(self, T:int):
    if T not in self._spec_jits: self._spec_jits[T] = TinyJit(self.forward_spec)
    return self._spec_jits[T]

  def warmup(self):
    try: self._warmup()
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
    self._warming, self._ckpt_tokens, self._ckpts = False, None, []

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
      self._ckpt = {k: {k.split(".")[-1]: Tensor.empty(*t.shape, dtype=t.dtype, device=t.device).contiguous().realize()} for k, t in st}
    return [(t, self._ckpt[k][k.split(".")[-1]]) for k, t in st]
  def _save_checkpoint(self, tokens:list[int]):
    if not self.has_recurrent_block or self._warming: return
    # direct device-to-device copies: an assign + realize walks every live Tensor in the process (~0.2 s per request here)
    for t, c in self._ckpt_pairs(): c.uop.buffer.ensure_allocated().copy_from(t.uop.buffer.ensure_allocated())
    self._ckpt_tokens = list(tokens)
  def _restore_checkpoint(self):
    for t, c in self._ckpt_pairs(): t.uop.buffer.ensure_allocated().copy_from(c.uop.buffer.ensure_allocated())
  def _take_periodic_checkpoint(self, tokens:list[int]):
    """copy the recurrent states for the prefix `tokens` (direct copies); on MemoryError stop taking them for this conversation"""
    if not self.has_recurrent_block or self._warming or len(self._ckpts) >= self._ckpt_max: return
    try: bufs = [self._device_copy(t) for t, _ in self._ckpt_pairs()]
    except MemoryError: self._ckpt_max = 0; return
    self._ckpts.append((list(tokens), bufs))
  def _resume_from_periodic(self, ck:tuple[list[int], list]) -> int:
    toks, bufs = ck
    for (t, _), b in zip(self._ckpt_pairs(), bufs): t.uop.buffer.ensure_allocated().copy_from(b)
    self._cached_tokens = list(toks)
    self._ckpts = [c for c in self._ckpts if len(c[0]) <= len(toks)]  # longer ones cover kv positions about to be rewritten
    return len(toks)

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
      # periodic checkpoints: the longest whose prefix the request extends and whose kv positions the cache still holds
      best = None
      for c in self._ckpts:
        n = len(c[0])
        if (cut is None or cut >= n) and n < len(tokens) and tokens[:n] == c[0] and self._cached_tokens[:n] == c[0] and (best is None or n > len(best[0])): best = c
      if best is not None: return self._resume_from_periodic(best)
      return 0
    prefix_len = sum(1 for _ in itertools.takewhile(lambda ab: ab[0] == ab[1], zip(tokens[:-1], cached)))
    return min(block._reusable_prefix_len(prefix_len, len(self._cached_tokens)) for block in self.blk)

  # ---- prefix-state snapshots: save/restore the whole decode state, so one conversation's cache survives another's requests ----
  def prefix_match(self, tokens:list[int], cached:list[int]) -> int:
    """how many leading tokens of `tokens` a state that ended at `cached` can serve. same rule as get_start_pos without the media cut"""
    if self.has_recurrent_block:
      return len(cached) if cached and len(cached) < len(tokens) and tokens[:len(cached)] == cached else 0
    return sum(1 for _ in itertools.takewhile(lambda ab: ab[0] == ab[1], zip(tokens[:-1], cached)))
  def snapshot_tensors(self) -> list[Tensor]:
    """every buffer the forward pass mutates in place: attention kv caches, recurrent (ssm) states, the mtp block's kv cache.
    the jits capture these by identity, so a snapshot clones their contents and a restore assigns back into the same buffers"""
    out: list[Tensor] = []
    for b in self.blk + ([self.mtp.blk] if self.mtp is not None else []):
      for name in ("cache_kv", "cache_k", "conv_state", "recurrent_state"):
        if (t := getattr(b, name, None)) is not None: out.append(t)
    return out
  @staticmethod
  def _device_copy_buf(src):
    from tinygrad.device import Buffer
    return Buffer(src.device, src.size, src.dtype).ensure_allocated().copy_from(src)
  @staticmethod
  def _device_copy(t:Tensor): return Transformer._device_copy_buf(t.uop.buffer.ensure_allocated())
  def snapshot_state(self) -> StateSnapshot:
    """copy the whole decode state, and the prefill checkpoint with it: a conversation almost always comes back extending its
    previous prompt rather than the generated sequence, so the checkpoint is what a restored snapshot gets resumed from.
    Direct buffer copies (see StateSnapshot); a MemoryError from the allocation is the caller's to handle."""
    bufs = [self._device_copy(t) for t in self.snapshot_tensors()]
    ckpt_bufs = [self._device_copy(c) for _, c in self._ckpt_pairs()] if self._ckpt_tokens is not None else []
    ckpts = [(list(t), [self._device_copy_buf(b) for b in bs]) for t, bs in self._ckpts]
    return StateSnapshot(list(self._cached_tokens), self._cached_media, bufs, list(self._ckpt_tokens) if self._ckpt_tokens is not None else None, ckpt_bufs, ckpts)
  def restore_state(self, snap:StateSnapshot) -> None:
    """write a snapshot (device or host copy) back into the live state buffers"""
    live = self.snapshot_tensors()
    assert len(live) == len(snap.bufs), "snapshot does not match the model's state layout"
    for t, b in zip(live, snap.bufs): t.uop.buffer.ensure_allocated().copy_from(b)
    if snap.ckpt_bufs:
      for (_, c), b in zip(self._ckpt_pairs(), snap.ckpt_bufs): c.uop.buffer.ensure_allocated().copy_from(b)
    self._cached_tokens, self._cached_media = list(snap.tokens), snap.media
    # the live checkpoint belonged to the conversation that was live; its kv positions are gone now. take the snapshot's (if any)
    self._ckpt_tokens = list(snap.ckpt_tokens) if snap.ckpt_bufs else None
    self._ckpts = [(list(t), [self._device_copy_buf(b) for b in bs]) for t, bs in snap.ckpts]

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
      sp, nt = v_start_pos.bind(start_pos), v_toks.bind(n_toks)
      if chunk_T and (start_pos < prompt_len or out is None):
        emb = self._emb_chunk(spans, start_pos, chunk_size) if self.image_pad_id is not None else None
        out = self(t[:, sp:sp+chunk_size], sp, temp, nt, emb).realize()
      else: out = self(t[:, sp:sp+nt] if start_pos < prompt_len or out is None else out, sp, temp).realize()
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
    if p == 0: self._ckpts = []  # a new conversation: the kv cache is rewritten from position 0
    while p < prompt_len:
      n_toks = min(chunk_T, prompt_len - p)
      # hold the prompt's last token back for a chunk of its own: the checkpoint is taken just before it (see _save_checkpoint)
      if p < prompt_len - 1 and p + n_toks == prompt_len: n_toks -= 1
      sp, nt = v_start_pos.bind(p), v_toks.bind(n_toks)
      emb = self._emb_chunk(spans or [], p, chunk_T) if self.image_pad_id is not None else None
      res, cands = run(t[:, sp:sp + chunk_T], p, nt, nt, emb)
      p_prev, p = p, p + n_toks
      self._cached_tokens = tokens[:p]
      if p == prompt_len - 1: self._save_checkpoint(tokens[:p])
      elif self._ckpt_max and p // self._ckpt_every > p_prev // self._ckpt_every: self._take_periodic_checkpoint(tokens[:p])
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
