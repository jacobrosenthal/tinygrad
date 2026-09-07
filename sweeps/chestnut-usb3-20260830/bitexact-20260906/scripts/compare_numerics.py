#!/usr/bin/env python3
"""Compare the per-block rows + logits saved by chunk_numerics.py (seq vs chunk): first block whose output differs bitwise, its type
(attention vs GatedDeltaNet), and per-block max |diff| / relative diff; the logits' top-1 and margin under both.
  python3 compare_numerics.py out-seq.npz out-chunk.npz"""
import sys, numpy as np
a, b = np.load(sys.argv[1]), np.load(sys.argv[2])
A, B, ssm = a["blocks"], b["blocks"], a["ssm"].astype(bool)
assert A.shape == B.shape, (A.shape, B.shape)
print(f"{A.shape[0]} blocks, dim {A.shape[1]}; teacher {a['teacher'].tolist()}")
first = None
for i in range(A.shape[0]):
  d = np.abs(A[i] - B[i]); rel = d.max() / (np.abs(A[i]).max() + 1e-30); eq = np.array_equal(A[i], B[i])
  if not eq and first is None: first = i
  if not eq or i < 3 or i == A.shape[0] - 1:
    print(f"block {i:2d} {'GDN ' if ssm[i] else 'ATTN'} {'EXACT' if eq else f'diff max {d.max():.3e} rel {rel:.2e} n!= {int((d > 0).sum())}/{d.size}'}")
la, lb = a["logits"], b["logits"]
ta, tb = np.argsort(-la)[:2], np.argsort(-lb)[:2]
print(f"logits: seq top {ta.tolist()} ({la[ta[0]]:.4f}, margin {la[ta[0]] - la[ta[1]]:.4f}) | chunk top {tb.tolist()} ({lb[tb[0]]:.4f}, margin {lb[tb[0]] - lb[tb[1]]:.4f}) | max |dlogit| {np.abs(la - lb).max():.3e}")
print("verdict:", "all blocks bitwise identical" if first is None else f"first difference at block {first} ({'GDN' if ssm[first] else 'ATTN'}), {int(sum(not np.array_equal(A[i], B[i]) for i in range(A.shape[0])))} blocks differ")
