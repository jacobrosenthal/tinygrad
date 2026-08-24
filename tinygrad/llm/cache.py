"""Cross-process cache of the fully loaded + warmed-up LLM: model object, captured jits, and tokenizer metadata.

Weight bytes are not stored: the pickle references them as ("base", i) persistent ids and the loader re-uploads the GGUF
tensor-data region (one big copy per file) before unpickling. Big non-weight buffers (kv caches, jit intermediates) are
restored empty: their contents at save time are garbage from the warmup run. Everything else (norm params, LUTs, rope
caches, the captured jit graphs) is pickled by value. Disable with LLM_CACHE=0.
"""
from __future__ import annotations
import copyreg, hashlib, itertools, os, pathlib, pickle, weakref
from tinygrad import Tensor
from tinygrad.helpers import DEBUG, Timing, cache_dir, getenv
from tinygrad.device import Buffer
from tinygrad.uop.ops import UOp
from tinygrad.engine.jit import _TinyJit
from tinygrad.tensor import all_tensors
from tinygrad.llm import gguf as _gguf

# model attributes holding per-sequence state: their contents at save time are garbage from the warmup run, restored as zeros
_TRANSIENT = ("cache_kv", "cache_k", "conv_state", "recurrent_state")
# buffers that are not reachable from the model (jit-planned intermediates, jit outputs) carry nothing worth storing above this size.
# NOTE: model attributes are never dropped by size: precomputed tables (e.g. freqs_cis at 160k context) are big and their contents matter
_CUTOFF = 16 << 20
# env vars that change what gets captured; a different value means a different cache entry
_ENV_KEYS = ("MTP", "MTP_K", "HALF", "AMD_GEMV", "AMD_CHUNK", "REALIZE", "JIT", "JIT_BATCH_SIZE",
             "GEMV_R", "GEMV_RT", "GEMV_WG", "GEMV_U", "GEMV_NWG", "GEMV_XP", "DFLASH", "HANG_DEBUG")

def _cache_key(path:str, max_context:int|None, extra:str="") -> str:
  h = hashlib.sha256()
  st = os.stat(path)
  h.update(f"{path} {st.st_size} {st.st_mtime_ns} {max_context} {extra}".encode())
  for k in _ENV_KEYS: h.update(f" {k}={os.environ.get(k, '')}".encode())
  # the pickled graphs depend on the tinygrad sources; hash their mtimes so editing any of it invalidates the cache
  for p in sorted(pathlib.Path(__file__).parents[1].rglob("*.py")): h.update(f" {p} {p.stat().st_mtime_ns}".encode())
  return h.hexdigest()

def _cache_file(path:str) -> pathlib.Path:
  return pathlib.Path(cache_dir) / "llm" / (hashlib.sha256(path.encode()).hexdigest()[:16] + ".pkl")

def _make_tensor(uop:UOp, is_param:bool) -> Tensor:
  # Tensors must re-register in all_tensors (default unpickling would skip Tensor.__init__)
  t = Tensor.__new__(Tensor)
  t.uop, t.grad, t.is_param = uop, None, is_param
  all_tensors[weakref.ref(t)] = None
  return t

def _make_jit(fxn, captured) -> _TinyJit: return _TinyJit(fxn, captured)

def _model_buffers(model) -> tuple[set[int], set[int]]:
  """ids of the realized buffers of the model's tensors: (kept by value, transient state)"""
  from tinygrad import nn
  keep, transient = set(), set()
  for name, t in nn.state.get_state_dict(model).items():
    if not t.uop.is_realized: continue
    (transient if name.split(".")[-1] in _TRANSIENT else keep).add(id(t.uop.buffer))
  return keep, transient

class _Pickler(pickle.Pickler):
  def __init__(self, f, bases:dict[int, int], keep:set[int], transient:set[int]):
    super().__init__(f, protocol=5)
    self.bases, self.keep, self.transient, self.dropped = bases, keep, transient, []
    self.dispatch_table = copyreg.dispatch_table.copy()
    # uncaptured jits (shapes never hit during warmup) are saved as fresh ones that capture on demand
    self.dispatch_table[_TinyJit] = lambda j: (_make_jit, (None, j.captured) if j.captured is not None else (j.fxn, None))
    self.dispatch_table[Tensor] = lambda t: (_make_tensor, (t.uop, t.is_param))

  def persistent_id(self, obj):
    if not isinstance(obj, Buffer): return None
    if (i:=self.bases.get(id(obj))) is not None: return ("base", i)
    if obj.device.split(":")[0] == "DISK": raise RuntimeError("a DISK buffer reached the llm cache pickle, this would embed the file")
    if id(obj) in self.keep: return None
    if id(obj) in self.transient or (obj._base is None and obj.nbytes > _CUTOFF):
      self.dropped.append(obj.nbytes)
      return ("empty", id(obj), obj.device, obj.size, obj.dtype)
    return None

class _Unpickler(pickle.Unpickler):
  def __init__(self, f, bases:list[Buffer]):
    super().__init__(f)
    self.bases, self.made = bases, {}

  def persistent_load(self, pid):
    if pid[0] == "base": return self.bases[pid[1]]
    if pid[0] == "empty":  # same saved buffer must unpickle to the same (empty) buffer, jits alias them (e.g. kv caches)
      if (b:=self.made.get(pid[1])) is None: b = self.made[pid[1]] = Buffer(pid[2], pid[3], pid[4])
      return b
    raise pickle.UnpicklingError(f"unknown persistent id {pid[0]!r}")

def save_llm_cache(model, kv:dict, path:str, max_context:int|None, extra:str="") -> None:
  """pickle the warmed-up model (weights by reference) next to its cache key. best effort: failures only print."""
  if not getenv("LLM_CACHE", 1): return
  try:
    bases = {id(b): i for i, (b, _, _) in enumerate(_gguf.base_registry)}
    for _, p, _ in _gguf.base_registry:
      if p is None: raise RuntimeError("model was loaded from a Tensor, not a path: no way to reference the weights")
    meta = {"key": _cache_key(path, max_context, extra), "max_slot": next(UOp.unique_num),
            "bases": [(p, off, b.size) for b, p, off in _gguf.base_registry]}
    (cf:=_cache_file(path)).parent.mkdir(parents=True, exist_ok=True)
    tmp = cf.with_suffix(f".tmp{os.getpid()}")
    keep, transient = _model_buffers(model)
    with Timing("saved llm cache in ", enabled=DEBUG >= 1), open(tmp, "wb") as f:
      pickle.dump(meta, f)
      (pk:=_Pickler(f, bases, keep, transient)).dump((model, kv))
    os.replace(tmp, cf)
    if DEBUG >= 1:
      print(f"llm cache: {cf} {cf.stat().st_size/1e6:.0f} MB, dropped {len(pk.dropped)} big buffers "
            f"({sum(pk.dropped)/1e6:.0f} MB) and referenced {len(bases)} weight bases")
  except Exception as e:
    print(f"llm cache: save failed: {e!r}")

def load_llm_cache(path:str, max_context:int|None, extra:str=""):
  """returns (model, kv) or None. re-uploads the weights from the GGUF file, then unpickles the model around them."""
  if not getenv("LLM_CACHE", 1) or not (cf:=_cache_file(path)).is_file(): return None
  try:
    with open(cf, "rb") as f:
      meta = pickle.load(f)
      if meta["key"] != _cache_key(path, max_context, extra):
        if DEBUG >= 1: print("llm cache: stale (model file, env, or llm sources changed), reloading")
        return None
      # saved BUFFER uops keep their slot numbers: move the counter past them so fresh buffers can't alias
      UOp.unique_num = itertools.count(meta["max_slot"] + 1)
      bases = []
      with Timing("llm cache: uploaded weights in ", enabled=DEBUG >= 1):
        for p, off, size in meta["bases"]:
          t = Tensor(pathlib.Path(p))[off:off + size].to(None).contiguous().realize()
          bases.append(t.uop.buffer)
          _gguf.base_registry.append((bases[-1], p, off))  # a later save from this process references the same bases
      with Timing("llm cache: unpickled model in ", enabled=DEBUG >= 1):
        model, kv = _Unpickler(f, bases).load()
    model._cached_tokens = []  # the state buffers were restored empty, the saved prefix is not resident
    from tinygrad import nn
    # per-sequence state comes back uninitialized: zero it like _init_state did (the recurrent/conv state must start at zero)
    zeroed = [t for name, t in nn.state.get_state_dict(model).items() if name.split(".")[-1] in _TRANSIENT and t.uop.is_realized]
    for t in zeroed: t.assign(Tensor.zeros(*t.shape, dtype=t.dtype, device=t.device))
    Tensor.realize(*zeroed)
    print(f"llm cache: loaded warmed-up model from {cf}")
    if getenv("AMD_GEMV", 1) and nn.state.get_parameters(model)[0].device.split(":")[0] == "AMD":
      from tinygrad.llm import amd_gemv
      amd_gemv.install()
    return model, kv
  except Exception as e:
    print(f"llm cache: load failed ({e!r}), reloading from gguf")
    return None
