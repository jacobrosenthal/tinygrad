from __future__ import annotations
# Qwen3-VL style vision encoder from a llama.cpp mmproj GGUF (projector type qwen3vl_merger): SigLIP-like ViT with 2D rope and a
# 2x2 spatial merger. an image becomes (grid_h/2 * grid_w/2) embeddings of the LLM width that replace the <|image_pad|> tokens.
import hashlib, io, math, pathlib
from collections import OrderedDict
from dataclasses import dataclass
import numpy as np
from typing import Any
from tinygrad import Tensor, TinyJit, dtypes
from tinygrad.helpers import getenv, DEBUG, Timing
from tinygrad.llm.gguf import gguf_load

@dataclass
class ImageEmbeds:
  key: str        # sha1 of the image bytes + preprocessing settings: identity for the prompt cache
  nx: int         # merged token grid width
  ny: int         # merged token grid height
  emb: Tensor     # (nx*ny, llm_dim) float32
  @property
  def n_tokens(self) -> int: return self.nx * self.ny
  @property
  def n_pos(self) -> int: return max(self.nx, self.ny)  # positions the image takes in the LLM (m-rope)

def smart_resize(h:int, w:int, factor:int, min_pixels:int, max_pixels:int) -> tuple[int, int]:
  # same as the Qwen processors / llama.cpp calc_size_preserved_ratio: sides rounded to the merge window, area within the limits
  hb, wb = max(factor, round(h / factor) * factor), max(factor, round(w / factor) * factor)
  if hb * wb > max_pixels:
    beta = math.sqrt(h * w / max_pixels)
    hb, wb = max(factor, math.floor(h / beta / factor) * factor), max(factor, math.floor(w / beta / factor) * factor)
  elif hb * wb < min_pixels:
    beta = math.sqrt(min_pixels / (h * w))
    hb, wb = math.ceil(h * beta / factor) * factor, math.ceil(w * beta / factor) * factor
  return hb, wb

class VisionEncoder:
  def __init__(self, path:str|pathlib.Path, max_tokens:int|None=None, min_tokens:int|None=None):
    with Timing("loaded mmproj in ", enabled=DEBUG >= 1):
      kv, sd = gguf_load(path)
      assert kv.get("clip.projector_type") == "qwen3vl_merger", f"unsupported projector {kv.get('clip.projector_type')}"
      assert not any(kv.get("clip.vision.is_deepstack_layers", [])), "deepstack layers are not supported"
      p = "clip.vision."
      self.dim, self.n_heads, self.n_layers = kv[p+"embedding_length"], kv[p+"attention.head_count"], kv[p+"block_count"]
      self.patch, self.merge, self.eps = kv[p+"patch_size"], kv.get(p+"spatial_merge_size", 2), kv[p+"attention.layer_norm_epsilon"]
      self.mean, self.std = np.array(kv[p+"image_mean"], np.float32), np.array(kv[p+"image_std"], np.float32)
      self.out_dim, self.head_dim = kv[p+"projection_dim"], self.dim // self.n_heads
      self.pos_side = int(math.sqrt(sd["v.position_embd.weight"].shape[0]))
      # both temporal slices of the patch conv see the same (single) image: fold them into one matrix
      self.patch_w = (sd["v.patch_embd.weight"].float() + sd["v.patch_embd.weight.1"].float()).reshape(self.dim, -1).transpose().contiguous()
      self.patch_b = sd["v.patch_embd.bias"].float()
      self.pos_embd = sd["v.position_embd.weight"].float().reshape(self.pos_side, self.pos_side, self.dim)
      self.post_ln = (sd["v.post_ln.weight"].float(), sd["v.post_ln.bias"].float())
      # matmul weights are kept f16 in (in, out) layout: the kernels read them directly (half activations, f32 accumulation)
      def lin(n:str) -> tuple[Tensor, Tensor]: return (sd[n+".weight"].half().transpose().contiguous().realize(), sd[n+".bias"].float().realize())
      def norm(n:str) -> tuple[Tensor, Tensor]: return (sd[n+".weight"].float().realize(), sd[n+".bias"].float().realize())
      self.mm = [lin(f"mm.{i}") for i in (0, 2)]
      self.blocks = [dict(ln1=norm(f"v.blk.{i}.ln1"), ln2=norm(f"v.blk.{i}.ln2"), qkv=lin(f"v.blk.{i}.attn_qkv"), out=lin(f"v.blk.{i}.attn_out"),
                          up=lin(f"v.blk.{i}.ffn_up"), down=lin(f"v.blk.{i}.ffn_down")) for i in range(self.n_layers)]
      Tensor.realize(self.patch_w, self.patch_b, self.pos_embd, *self.post_ln)
    factor = self.patch * self.merge
    self.max_tokens = max_tokens or getenv("IMG_MAX_TOKENS", 1024)
    self.min_tokens = min_tokens or getenv("IMG_MIN_TOKENS", 4)
    self.min_pixels, self.max_pixels = self.min_tokens * factor * factor, self.max_tokens * factor * factor
    self._jits: OrderedDict[tuple[int, int], Any] = OrderedDict()
    self._cache: OrderedDict[str, ImageEmbeds] = OrderedDict()  # recent images (chat clients resend the whole history every turn)
    self._table_cache: dict[tuple[int, int], tuple[Tensor, Tensor, Tensor]] = {}

  # ---- preprocessing (host) ----
  def preprocess(self, data:bytes) -> tuple[np.ndarray, int, int]:
    """image bytes -> (patches (grid_h*grid_w, 3*patch*patch) in 2x2-window order, grid_h, grid_w)"""
    from PIL import Image
    img = Image.open(io.BytesIO(data)).convert("RGB")
    w, h = img.size
    hb, wb = smart_resize(h, w, self.patch * self.merge, self.min_pixels, self.max_pixels)
    if (wb, hb) != (w, h): img = img.resize((wb, hb), Image.Resampling.BICUBIC)
    x = (np.asarray(img, dtype=np.float32) / 255.0 - self.mean) / self.std   # (hb, wb, 3)
    P, M, gh, gw = self.patch, self.merge, hb // self.patch, wb // self.patch
    # (y2, yp, py, x2, xp, px, c) -> (y2, x2, yp, xp, c, py, px): tokens ordered by merge window, patch flattened like the conv weight
    x = x.reshape(gh // M, M, P, gw // M, M, P, 3).transpose(0, 3, 1, 4, 6, 2, 5).reshape(gh * gw, 3 * P * P)
    return np.ascontiguousarray(x), gh, gw

  def _tables(self, gh:int, gw:int) -> tuple[Tensor, Tensor, Tensor]:
    """position embedding (bilinear resize of the learned grid, align corners) and 2D rope cos/sin for a grid, in window order"""
    if (gh, gw) in self._table_cache: return self._table_cache[(gh, gw)]
    M, N = self.merge, gh * gw
    pe = self.pos_embd.permute(2, 0, 1).interpolate((gh, gw), mode="linear", align_corners=True).permute(1, 2, 0)  # (gh, gw, D)
    pe = pe.reshape(gh // M, M, gw // M, M, self.dim).permute(0, 2, 1, 3, 4).reshape(N, self.dim)
    ys, xs = np.meshgrid(np.arange(gh), np.arange(gw), indexing="ij")
    def order(a:np.ndarray) -> np.ndarray: return a.reshape(gh // M, M, gw // M, M).transpose(0, 2, 1, 3).reshape(N)
    ys, xs = order(ys).astype(np.float32), order(xs).astype(np.float32)
    half = self.head_dim // 2
    inv = 1.0 / (10000.0 ** (np.arange(0, half, 2, dtype=np.float32) / half))  # (head_dim/4,)
    ang = np.concatenate([ys[:, None] * inv[None], xs[:, None] * inv[None]], axis=1)  # (N, head_dim/2): y on the first half, x on the second
    ang = np.concatenate([ang, ang], axis=1)  # rotate_half pairs dim i with i + head_dim/2
    cos, sin = Tensor(np.cos(ang)), Tensor(np.sin(ang))
    self._table_cache[(gh, gw)] = out = (pe.contiguous().realize(), cos.realize(), sin.realize())
    if len(self._table_cache) > 16: self._table_cache.pop(next(iter(self._table_cache)))
    return out

  # ---- encoder ----
  def _forward(self, patches:Tensor, pos:Tensor, cos:Tensor, sin:Tensor) -> Tensor:
    N, D, H, HD = patches.shape[0], self.dim, self.n_heads, self.head_dim
    def ln(x:Tensor, wb:tuple[Tensor, Tensor]) -> Tensor: return x.layernorm(eps=self.eps) * wb[0] + wb[1]
    def lin(x:Tensor, wb:tuple[Tensor, Tensor]) -> Tensor: return x.half().dot(wb[0], dtype=dtypes.float32) + wb[1]
    x = patches @ self.patch_w + self.patch_b + pos
    cos, sin = cos.reshape(1, N, HD), sin.reshape(1, N, HD)
    def rope(t:Tensor) -> Tensor:
      t1, t2 = t[..., :HD // 2], t[..., HD // 2:]
      return t * cos + t2.neg().cat(t1, dim=-1) * sin
    for b in self.blocks:
      qkv = lin(ln(x, b["ln1"]), b["qkv"]).reshape(N, 3, H, HD).permute(1, 2, 0, 3)  # (3, H, N, HD)
      q, k, v = rope(qkv[0]).contiguous(), rope(qkv[1]).contiguous(), qkv[2].contiguous()
      Tensor.realize(q, k, v)  # the head groups below must not recompute the projection (each realize schedules what it can see)
      # full (non-causal) attention over the image, a few heads at a time to bound the score matrices
      outs = []
      for h0 in range(0, H, 4):
        s = (q[h0:h0+4] @ k[h0:h0+4].transpose(-1, -2)) * (1.0 / math.sqrt(HD))
        outs.append((s.softmax(-1) @ v[h0:h0+4]).contiguous())
      a = Tensor.cat(*outs, dim=0).permute(1, 0, 2).reshape(N, D)
      x = x + lin(a, b["out"])
      x = (x + lin(lin(ln(x, b["ln2"]), b["up"]).gelu(), b["down"])).realize()  # per-block schedules keep the graphs small
    x = ln(x, self.post_ln).reshape(N // (self.merge * self.merge), -1)
    x = lin(lin(x, self.mm[0]).gelu(), self.mm[1])
    return x.contiguous()

  def encode(self, data:bytes) -> ImageEmbeds:
    key = hashlib.sha1(data + f"|{self.min_pixels}|{self.max_pixels}".encode()).hexdigest()
    if key in self._cache:
      self._cache.move_to_end(key)
      return self._cache[key]
    with Timing("vision encode in ", enabled=DEBUG >= 1):
      patches, gh, gw = self.preprocess(data)
      pos, cos, sin = self._tables(gh, gw)
      if (gh, gw) not in self._jits:
        self._jits[(gh, gw)] = jit = TinyJit(self._forward)
        jit.cnt = 1  # everything the graph reads is realized already: capture on the first call instead of after a plain run
        if len(self._jits) > 8: self._jits.popitem(last=False)
      emb = self._jits[(gh, gw)](Tensor(patches), pos, cos, sin).clone().realize()  # clone: jit outputs are reused by the next call
    out = ImageEmbeds(key, gw // self.merge, gh // self.merge, emb)
    self._cache[key] = out
    if len(self._cache) > getenv("IMG_CACHE", 16): self._cache.popitem(last=False)
    if DEBUG >= 1: print(f"vision: image {gw*self.patch}x{gh*self.patch} -> {out.nx}x{out.ny} = {out.n_tokens} tokens")
    return out

  def warmup(self, side:int=512):
    """compile the encoder once at startup (a gray square) so the first request does not pay for it"""
    from PIL import Image
    buf = io.BytesIO()
    Image.new("RGB", (side, side), (128, 128, 128)).save(buf, format="PNG")
    for _ in range(2): self.encode(buf.getvalue())
    self._cache.clear()
