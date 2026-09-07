#!/usr/bin/env python3
"""Offline register-pressure probe for the batched decode gemv (no GPU needed): build the HIP source exactly as amd_gemv does for a
given (format, N, K, T, R, U, WG, XP), compile it with clang -> LLVM IR -> AMDLLVMCompiler(gfx1100), and print the kernel
descriptor's VGPR count / spill count / private segment bytes from the ELF notes.

  PYTHONPATH=<tinygrad tree> python3 compile_probe.py                      # the default shape list (the T>=9 kernels seen in the K=5 sweep)
  PYTHONPATH=<tree> python3 compile_probe.py q5k:5120:6144:res T=8,10,12 R=1,2 XP=0,1
  PYTHONPATH=<tree> python3 compile_probe.py multi:q5k10240,q4k6144,q8_048,q8_048:5120 T=7   # fused multi-gemv (WG 256), segs "<fmt><N>"
  PYTHONPATH=<tree> python3 compile_probe.py multi T=7                                       # the 8 production multi combos

The tree it imports is whichever tinygrad is first on PYTHONPATH: point it at a worktree so the serving checkout stays untouched
(editing tinygrad/**/*.py there invalidates the LLM cache of every running sweep).
"""
import sys, os, re, subprocess, tempfile, itertools
from tinygrad.llm import amd_gemv as G
from tinygrad.runtime.support.compiler_llvm import AMDLLVMCompiler

DEFAULT = ["q5k:5120:6144:res", "q6k:5120:6144:res", "q6k:5120:17408:res", "q6k:5120:10240", "iq4nl:5120:17408:res", "iq3s:5120:17408:res"]
# the fused launches production uses (from the 09-06 sweep logs): GDN in-proj (qkv, gate, alpha, beta), attention q/k/v, ffn gate/up
MULTI = ["multi:q6k12288,q8_01024,q8_01024:5120", "multi:q4k12288,q6k1024,q8_01024:5120", "multi:q4k12288,q5k1024,q8_01024:5120",
         "multi:q5k10240,q4k6144,q8_048,q8_048:5120", "multi:q6k17408,q5k17408:5120", "multi:q6k17408,q6k17408:5120",
         "multi:iq4xs17408,q3k17408:5120", "multi:iq4xs17408,iq4xs17408:5120"]
READELF = next((p for p in ("llvm-readelf-14", "llvm-readelf-13", "llvm-readelf") if subprocess.run(["which", p], capture_output=True).returncode == 0), None)
BY_NAME = {f["name"]: t for t, f in G.FORMATS.items()}

def meta(elf:bytes) -> dict:
  with tempfile.NamedTemporaryFile(suffix=".elf", delete=False) as f: f.write(elf); p = f.name
  try:
    out = subprocess.run([READELF, "--notes", p], capture_output=True, text=True).stdout
  finally: os.unlink(p)
  return {k: int(v) for k, v in re.findall(r"\.(vgpr_count|vgpr_spill_count|sgpr_count|sgpr_spill_count|private_segment_fixed_size|group_segment_fixed_size):\s+(\d+)", out)}

def show(name:str, m:dict):
  print(f"{name:60s} vgpr={m.get('vgpr_count', -1):3d} spill={m.get('vgpr_spill_count', -1):3d} scratch={m.get('private_segment_fixed_size', -1):4d}B "
        f"sgpr={m.get('sgpr_count', -1):3d} lds={m.get('group_segment_fixed_size', -1)}B", flush=True)

def probe(fmt:str, N:int, K:int, residual:bool, T:int, R:int|None, U:int|None, WG:int|None, XP:bool|None):
  ggml_type = BY_NAME[fmt]
  r0, u0, wg0, n_wg = G.gemv_config(ggml_type, N, K, T, WG or 0)
  R, U, WG = R or r0, U or u0, WG or wg0
  waves = (N + R - 1) // R; n_wg = (waves + WG // 32 - 1) // (WG // 32)
  if G.FORMATS[ggml_type]["grid_words"] >= 4096: n_wg = min(n_wg, 192)
  src = G._gemv_src(ggml_type, N, K, R, U, WG, n_wg, residual, T, XP)
  m = meta(AMDLLVMCompiler("gfx1100").compile(G.hip_to_ir(src, "gfx1100")))
  tg = G._tg(T, G.FORMATS[ggml_type]) if hasattr(G, "_tg") else T
  show(f"gemv_{fmt}_{N}_{K}_t{T}_r{R}_u{U}_w{WG}_g{n_wg}{'_res' if residual else ''}{'' if XP is None else f'_xp{int(XP)}'}{f'_tg{tg}' if tg < T else ''}", m)
  return m

def probe_multi(segs:list[tuple[str, int]], K:int, T:int, XP:bool|None):
  WG = 256
  ts = [(BY_NAME[f], N) for f, N in segs]
  cfgs = [(R, U, n_wg) for R, U, _, n_wg in (G.gemv_config(t, N, K, T, WG) for t, N in ts)]
  src = G._gemv_multi_src(ts, K, WG, cfgs, T, XP)
  m = meta(AMDLLVMCompiler("gfx1100").compile(G.hip_to_ir(src, "gfx1100")))
  tgs = "".join(str(G._tg(T, G.FORMATS[t])) for t, _ in ts) if hasattr(G, "_tg") else ""
  show("gemv_multi_" + "_".join(f"{f}{N}" for f, N in segs) + f"_{K}_t{T}_" + "_".join(f"r{R}u{U}g{g}" for R, U, g in cfgs) + (f"_tg{tgs}" if tgs and any(G._tg(T, G.FORMATS[t]) < T for t, _ in ts) else ""), m)
  return m

if __name__ == "__main__":
  shapes = [a for a in sys.argv[1:] if ":" in a or a == "multi"] or DEFAULT
  if "multi" in shapes: shapes = [s for s in shapes if s != "multi"] + MULTI
  opts = {k: v.split(",") for k, v in (a.split("=") for a in sys.argv[1:] if "=" in a)}
  Ts = [int(x) for x in opts.get("T", ["10"])]; Rs = [int(x) if x != "-" else None for x in opts.get("R", ["-"])]
  Us = [int(x) if x != "-" else None for x in opts.get("U", ["-"])]; WGs = [int(x) if x != "-" else None for x in opts.get("WG", ["-"])]
  XPs = [None if x == "-" else bool(int(x)) for x in opts.get("XP", ["-"])]
  for s in shapes:
    parts = s.split(":")
    if parts[0] == "multi":
      def seg(p:str) -> tuple[str, int]:  # "<fmt><N>" with fmt the longest known format-name prefix (q8_048 -> q8_0, 48)
        fmt = max((n for n in BY_NAME if p.startswith(n)), key=len); return fmt, int(p[len(fmt):])
      segs = [seg(p) for p in parts[1].split(",")]
      for T, XP in itertools.product(Ts, XPs):
        try: probe_multi(segs, int(parts[2]), T, XP)
        except Exception as e: print(f"{s} T={T} XP={XP}: FAILED {str(e)[:300]}")
      continue
    fmt, N, K = parts[0], int(parts[1]), int(parts[2]); residual = "res" in parts[3:]
    for T, R, U, WG, XP in itertools.product(Ts, Rs, Us, WGs, XPs):
      try: probe(fmt, N, K, residual, T, R, U, WG, XP)
      except Exception as e: print(f"{s} T={T} R={R} U={U} WG={WG} XP={XP}: FAILED {str(e)[:200]}")
