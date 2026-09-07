#!/usr/bin/env python3
"""Chunk-width numerics: the same 4 teacher-forced tokens after the same prompt, decoded either as four T=1 forwards (seq) or as one
T=4 forward (chunk). Records every block's output at the last of those positions and the final logits, so compare_numerics.py can
name the first block whose output depends on the chunk width (bitwise).
  MTP_K=3 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 DEV=USB+AMD:LLVM python3 chunk_numerics.py seq   out-seq.npz
  MTP_K=3 MAX_T=12 ATTN_QT=8 NGRAM_DRAFT=0 DEV=USB+AMD:LLVM python3 chunk_numerics.py chunk out-chunk.npz [N=4]
(one process per variant: the recurrent state / kv cache are mutated by the decode; the LLM cache key must match a warmed entry or
the load is a full warmup)"""
import sys, numpy as np
from tinygrad import Tensor, dtypes
from tinygrad.llm.model import Transformer, FFNBlock
from tinygrad.llm.cli import SimpleTokenizer
from tinygrad.llm import amd_gemv

mode, out = sys.argv[1], sys.argv[2]; N = int(sys.argv[3]) if len(sys.argv) > 3 else 4
MODEL = "/home/jacob/models/Qwen3.8-27B-UD-Q4_K_XL.gguf"
# no warmup: the spec-JIT captures of a warmup (or a restored cache) plus this script's eager passes exceed 24 GB (OOM at 23.85 GB, chainK5)
Transformer.warmup = lambda self, *a, **k: None
Transformer._warmup = lambda self, *a, **k: None
model, kv = Transformer.from_gguf(MODEL, 8192, repeat_penalty=1.15)
tok = SimpleTokenizer.from_gguf_kv(kv)
prompt = tok.encode("<|im_start|>user\nWrite a Python merge sort with comments and complexity analysis, then explain stability.<|im_end|>\n<|im_start|>assistant\n")
teacher = tok.encode("The user wants me to implement four classic algorithms in Python with detailed comments and tests")[:N]
assert len(teacher) == N, (len(teacher), N)
P = len(prompt); CT = model._chunk_T
SSM = [type(b).__name__ == "GatedDeltaNetBlock" for b in model.blk]
from tinygrad.helpers import GlobalCounters
print(f"loaded: {GlobalCounters.mem_used_per_device.get(str(Tensor([0]).device), 0)/1e9:.2f} GB used", flush=True)
print(f"prompt {P} tokens, teacher {teacher}, prefill chunk {CT}, blocks {len(model.blk)}, gdn blocks {sum(SSM)}", flush=True)
temp = Tensor([0.0])
t = Tensor(prompt + teacher + [0] * (CT + 16), dtype=dtypes.int32).reshape(1, -1)
# feed the prompt through the DECODE path in 8-token chunks (the fused gemv/attention kernels, same as a spec verify chunk): the
# 256-wide prefill path through Transformer.forward allocates ~6 GB of temporaries and OOMs next to the loaded model (chainK5/K7)
PC = 8; sp = 0
while sp < P:
  nt = min(PC, P - sp)
  model.forward(t[:, sp:sp + PC], sp, temp, n_tok=nt).realize()
  sp += nt
print(f"prefill done, {max(GlobalCounters.mem_used_per_device.values())/1e9:.2f} GB used", flush=True)
# hook every block: record its output row at the LAST valid position of the call
rec: list[np.ndarray] = []
orig = FFNBlock.__call__
def hooked(self, x, start_pos, n_tok=None):
  y = orig(self, x, start_pos, n_tok)
  n = int(n_tok) if n_tok is not None else int(y.shape[1])
  rec.append(y.realize()[:, n - 1].float().numpy().reshape(-1).copy())
  return y
FFNBlock.__call__ = hooked
def run(tokens:Tensor, start_pos:int, n_tok:int) -> np.ndarray:
  if hasattr(model, "_ggml_raw"): amd_gemv.new_forward()
  x = model._embed(tokens, None)
  for block in model.blk: x = block(x, start_pos, n_tok)
  last = x.shrink((None, (n_tok - 1, n_tok), None)).contiguous()
  return model.output(model.output_norm(last))[:, -1, :].float().numpy().reshape(-1)
if mode == "seq":
  for j in range(N):
    rec.clear(); logits = run(t[:, P + j:P + j + 1], P + j, 1)
    print(f"seq step {j}: token {teacher[j]} at {P + j}: top1 {int(logits.argmax())} ({logits.max():.4f})", flush=True)
else:
  rec.clear(); logits = run(t[:, P:P + N], P, N)
  print(f"chunk T={N}: top1 {int(logits.argmax())} ({logits.max():.4f})", flush=True)
np.savez(out, blocks=np.stack(rec), logits=logits, teacher=np.array(teacher), ssm=np.array(SSM))
print(f"saved {out}: {len(rec)} block rows (last position), logits {logits.shape}")
