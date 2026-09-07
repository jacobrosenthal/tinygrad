#!/usr/bin/env python3
# Bound-queue form of the scratch use-after-free (any AMD device): the dispatch packets of a BOUND HCQ queue are built once (exec)
# and re-submitted as-is, so they keep COMPUTE_DISPATCH_SCRATCH_BASE of the scratch that existed at exec time. A later program with
# a larger private segment makes _ensure_has_local_memory free that scratch; re-submitting the bound queue spills into freed memory.
# (The plain TinyJit path rebuilds packets on every replay via exec, so it does not show this; bound queues / cached command
# streams (the USB path, graph replays that cache packets) do.)
#   DEV=AMD python3 repro_bound.py          # victims placed on the freed range -> corrupted after the re-submit (or a GCVM fault)
import sys
from tinygrad import Tensor, Device, dtypes, Variable
from tinygrad.uop.ops import UOp, Ops, KernelInfo, ProgramInfo, graph_rewrite
from tinygrad.codegen import pm_to_program
from tinygrad.engine.realize import get_runtime
sys.path.insert(0, __file__.rsplit("/", 1)[0]); from repro import scratch_ir

def program(dev, name, n):
  sink = UOp.sink(UOp.special(1, "gidx0"), UOp.special(64, "lidx0"), UOp.placeholder((64,), dtypes.int32, 0), arg=KernelInfo(name=name))
  prg = UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=scratch_ir(name, n))))
  prg = prg.replace(arg=ProgramInfo.from_sink(sink, dev.renderer.target))
  return get_runtime(dev.device, graph_rewrite(prg, pm_to_program, ctx=dev.renderer))

dev = Device["AMD"]
out = Tensor.zeros(64, dtype=dtypes.int32).contiguous().realize()
small = program(dev, "k_small", 64)
q = dev.hw_compute_queue_t().exec(small, small.fill_kernargs([out.uop.buffer._buf]), (1, 1, 1), (64, 1, 1))
sig_val = Variable("sig_val", 0, 0xffffffff, dtypes.uint32)   # the signal value is a variable: a bound queue's packets are fixed otherwise
q.signal(dev.timeline_signal, sig_val).bind(dev)
def run():
  q.submit(dev, {sig_val.expr: dev.timeline_value}); dev.timeline_signal.wait(dev.timeline_value, timeout=10000); dev.timeline_value += 1
run(); print("bound queue ran:", out.tolist()[:4], f"scratch {dev.scratch.va_addr:#x} ({dev.scratch.size >> 20} MiB)")
a, a_size = dev.scratch.va_addr, dev.scratch.size
program(dev, "k_big", 512)                  # larger private segment -> scratch regrowth, old buffer freed
dev.allocator.free_cache()                  # the LRU allocator keeps freed buffers mapped until it needs the memory
print(f"regrown: scratch {dev.scratch.va_addr:#x} ({dev.scratch.size >> 20} MiB); the bound queue still targets {a:#x}")
assert dev.scratch.va_addr != a
sizes = [64 << 10] * 8 + [512 << 10] * 4 + [a_size]
victims = [Tensor.full(sz // 4, 0x1234567, dtype=dtypes.int32).contiguous().realize() for sz in sizes]
vas = [int(v.uop.buffer._buf.va_addr) for v in victims]
print("victims inside the freed range:", sum(a <= va < a + a_size for va in vas), "of", len(vas), "first at", f"{min(vas):#x}")
run()
bad = [int((v != 0x1234567).sum().item()) for v in victims]
print("bound queue re-submitted:", out.tolist()[:4], "| corrupted words per victim:", bad, "<-- USE AFTER FREE" if any(bad) else "(victims intact)")
