#!/usr/bin/env python3
"""On-device correctness test of the fused DFlash selector (dflash_sel.select_fused) against a numpy reference of the same math
(top-16 over the vocab, greedy codebook walk) using the DEQUANTIZED selector tables, on random draft logits / hidden states and the
real Q4_K codebooks of the drafter gguf. Also runs the tinygrad-op select_gpu for a three-way check.
  DEV=USB+AMD:LLVM PYTHONPATH=<tree> python3 test_select_fused.py [trials=5] [K=5]"""
import sys, os, time, numpy as np
from tinygrad import Tensor, dtypes, Device
from tinygrad.helpers import getenv
from tinygrad.llm.dflash import load_dflash
from tinygrad.llm.dflash_sel import select_fused
from tinygrad.llm import amd_gemv

trials, K = (int(sys.argv[1]) if len(sys.argv) > 1 else 5), (int(sys.argv[2]) if len(sys.argv) > 2 else 5)
path = os.environ.get("DFLASH", "/home/jacob/models/Qwen3.8-27B-DFlash2-Q4_K_M.gguf")
dfm, kv, raw = load_dflash(path, 8192)
dev = Device.DEFAULT
dfm.sel_pred_raw, dfm.sel_succ_raw = dfm.sel_pred_raw.to(dev).realize(), dfm.sel_succ_raw.to(dev).realize()
V, R, TK, dim = len(kv["tokenizer.ggml.tokens"]), dfm.rank, dfm.top_k, dfm.dim
print(f"vocab={V} rank={R} top_k={TK} dim={dim} K={K} device={dev}")
# dequantized tables for the reference (the nn.Embedding weights are the gguf loader's float views)
pred = dfm.sel_pred.weight.float().numpy(); succ = dfm.sel_succ.weight.float().numpy()
wproj = dfm.sel_proj.weight.float().numpy()  # (R, dim)
print("tables:", pred.shape, succ.shape, wproj.shape)
rng = np.random.default_rng(0); ok = 0
for trial in range(trials):
  dl = rng.standard_normal((K, V), dtype=np.float32) * 4.0
  # make a few clear winners so ties are rare, plus one exact tie to exercise the lowest-id rule
  for t in range(K): dl[t, rng.integers(0, V, 16)] += 20.0
  dl[0, 100] = dl[0, 200] = dl[0].max() + 5.0
  h = rng.standard_normal((K, dim), dtype=np.float32)
  anchor = int(rng.integers(0, V))
  # reference
  hp_ref = h @ wproj.T  # (K, R)
  ref, prev = [], anchor
  for t in range(K):
    ids = np.argsort(-dl[t], kind="stable")[:TK]; vals = dl[t, ids]
    order = np.lexsort((ids, -vals)); ids, vals = ids[order], vals[order]   # descending value, lowest id first on ties
    gate = pred[prev] * hp_ref[t]
    scores = vals + succ[ids] @ gate
    tok = int(ids[int(np.argmax(scores))]); ref.append(tok); prev = tok
  # device: hp through the real sel_proj (gemv, quantized activations) then the fused kernels; compare with a float hp too
  dl_t, h_t, a_t = Tensor(dl, device=dev), Tensor(h, device=dev), Tensor([anchor], dtype=dtypes.int32, device=dev)
  t0 = time.perf_counter(); out = dfm.select_fused(h_t.reshape(1, K, dim), dl_t.reshape(1, K, V), a_t).tolist(); dt = time.perf_counter() - t0
  out_fhp = select_fused(dl_t, Tensor(hp_ref, device=dev), dfm.sel_pred_raw, dfm.sel_succ_raw, a_t, K, V, TK, R).tolist()
  gpu = dfm.select_gpu(h_t.reshape(1, K, dim), dl_t.reshape(1, K, V), a_t).tolist()
  match = out_fhp == ref
  ok += match
  print(f"trial {trial}: ref={ref}\n         fused(float hp)={out_fhp} {'OK' if match else 'MISMATCH'}\n         fused(gemv hp)={out} {'same' if out == ref else 'differs (quantized hp)'}\n         select_gpu={gpu} {'same' if gpu == ref else 'differs'}  [{dt*1e3:.1f} ms first call]")
print(f"{ok}/{trials} trials bit-match the float reference (fused kernels with float hp)")
sys.exit(0 if ok == trials else 1)
