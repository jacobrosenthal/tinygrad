#!/usr/bin/env python3
# AMD scratch use-after-free: a bound HCQ queue re-submits the dispatch packets it was built with, including
# COMPUTE_DISPATCH_SCRATCH_BASE. A later program with a larger private segment makes AMDDevice._ensure_has_local_memory
# realloc the scratch and free the old buffer; the re-submitted queue then spills into freed memory.
#   DEV=AMD python3 repro_scratch_uaf.py      (any AMD device with the LLVM renderer; exits 1 when the corruption is observed)
import sys
from tinygrad import Tensor, Device, dtypes, Variable
from tinygrad.uop.ops import UOp, Ops, KernelInfo, ProgramInfo, graph_rewrite
from tinygrad.codegen import pm_to_program
from tinygrad.engine.realize import get_runtime

def scratch_ir(name:str, n:int) -> str:
  # a [n x i32] private array written and read with volatile accesses (never promoted to registers) -> lives in scratch
  return f'''target triple = "amdgcn-amd-amdhsa"
define amdgpu_kernel void @{name}(ptr addrspace(1) %out) #0 {{
entry:
  %arr = alloca [{n} x i32], align 4, addrspace(5)
  %lid = tail call i32 @llvm.amdgcn.workitem.id.x()
  br label %loop
loop:
  %i = phi i32 [0, %entry], [%inext, %loop]
  %p = getelementptr inbounds [{n} x i32], ptr addrspace(5) %arr, i32 0, i32 %i
  %v = add i32 %i, %lid
  store volatile i32 %v, ptr addrspace(5) %p, align 4
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, {n}
  br i1 %done, label %exit, label %loop
exit:
  %idx = urem i32 %lid, {n}
  %q = getelementptr inbounds [{n} x i32], ptr addrspace(5) %arr, i32 0, i32 %idx
  %r = load volatile i32, ptr addrspace(5) %q, align 4
  %o = getelementptr inbounds i32, ptr addrspace(1) %out, i32 %lid
  store i32 %r, ptr addrspace(1) %o, align 4
  ret void
}}
declare i32 @llvm.amdgcn.workitem.id.x()
attributes #0 = {{ nounwind "amdgpu-flat-work-group-size"="1,64" }}
!llvm.module.flags = !{{!0}}
!0 = !{{i32 1, !"amdhsa_code_object_version", i32 500}}
'''


def scratch_program(dev, name:str, n:int):
  sink = UOp.sink(UOp.special(1, "gidx0"), UOp.special(64, "lidx0"), UOp.placeholder((64,), dtypes.int32, 0), arg=KernelInfo(name=name))
  prg = UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=scratch_ir(name, n))), arg=ProgramInfo.from_sink(sink, dev.renderer.target))
  return get_runtime(dev.device, graph_rewrite(prg, pm_to_program, ctx=dev.renderer))

dev = Device["AMD"]
out = Tensor.zeros(64, dtype=dtypes.int32).contiguous().realize()
small = scratch_program(dev, "scratch_small", 64)                       # 260 B private segment
sig_val = Variable("sig_val", 0, 0xffffffff, dtypes.uint32)
q = dev.hw_compute_queue_t().exec(small, small.fill_kernargs([out.uop.buffer._buf]), (1, 1, 1), (64, 1, 1))
q.signal(dev.timeline_signal, sig_val).bind(dev)
def run():
  q.submit(dev, {sig_val.expr: dev.timeline_value}); dev.timeline_signal.wait(dev.timeline_value, timeout=10000); dev.timeline_value += 1
run(); assert out.tolist() == [2 * i for i in range(64)]
base, size = dev.scratch.va_addr, dev.scratch.size
print(f"bound queue ran with scratch {base:#x} ({size >> 20} MiB)")
scratch_program(dev, "scratch_big", 512)                                 # 2052 B private segment: regrowth
print(f"after a larger program: scratch {dev.scratch.va_addr:#x} ({dev.scratch.size >> 20} MiB); the bound queue still targets {base:#x}")
assert dev.scratch.va_addr != base
dev.allocator.free_cache()                                               # the LRU allocator keeps freed buffers mapped until now
victims = [Tensor.full(sz // 4, 0x1234567, dtype=dtypes.int32).contiguous().realize() for sz in [64 << 10] * 8 + [512 << 10] * 4 + [size]]
run()
bad = [int((v != 0x1234567).sum().item()) for v in victims]
print("corrupted words per victim after the re-submit:", bad)
if any(bad): print("USE AFTER FREE: the queue spilled into freed, reallocated memory"); sys.exit(1)
print("ok: the old scratch stayed mapped")
