#!/usr/bin/env python3
# AMD: an HCQ graph bakes the scratch base; a later scratch regrowth frees that buffer -> replaying the graph spills into freed memory.
# Any AMD device (AM or KFD). Repro: a jitted kernel with a 260 B private segment (captured: graph holds scratch A), then compile a
# kernel with a 2052 B private segment (AMDDevice._ensure_has_local_memory reallocs: A freed), then replay the graph.
#   DEV=AMD python3 repro.py            # asserts the device scratch moved while the captured graph still targets the old one
#   DEV=AMD python3 repro.py --fault    # also replays the graph: GCVM_L2_PROTECTION_FAULT (write) inside the freed range
import sys
from tinygrad import Tensor, TinyJit, Device, dtypes
from tinygrad.uop.ops import UOp, Ops, KernelInfo

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

def scratch_kernel(name:str, n:int):
  def fxn(*params):
    sink = UOp.sink(UOp.special(1, "gidx0"), UOp.special(64, "lidx0"), *params, arg=KernelInfo(name=name))
    return UOp(Ops.PROGRAM, src=(sink, UOp(Ops.LINEAR, src=()), UOp(Ops.SOURCE, arg=scratch_ir(name, n))))
  return fxn

if __name__ == "__main__":
  dev = Device["AMD"]
  small = TinyJit(lambda x: x.custom_kernel(fxn=scratch_kernel("k_small", 64))[0])
  x = Tensor.zeros(64, dtype=dtypes.int32).contiguous().realize()
  for _ in range(3): small(x).realize()                       # call 2 captures the graph, call 3 replays it
  a, tr_a, a_size = dev.scratch.va_addr, dev.tmpring_size, dev.scratch.size
  print(f"graph captured with scratch {a:#x} ({dev.scratch.size >> 20} MiB), tmpring {tr_a:#x}")
  Tensor.zeros(64, dtype=dtypes.int32).contiguous().custom_kernel(fxn=scratch_kernel("k_big", 512))[0].realize()
  dev.allocator.free_cache()  # the LRU allocator keeps freed buffers mapped until it needs the memory: release them now
  b = dev.scratch.va_addr
  print(f"after a kernel with a larger private segment: scratch {b:#x} ({dev.scratch.size >> 20} MiB), tmpring {dev.tmpring_size:#x}")
  assert b != a, "scratch did not regrow (raise the second kernel's array)"
  print(f"the graph still dispatches with COMPUTE_DISPATCH_SCRATCH_BASE={a:#x}, which _ensure_has_local_memory freed")
  # victim buffers: allocations of the old scratch's size land on its freed VA range (first fit); the replay's spills then corrupt them.
  # (a fault instead of corruption needs the range to stay unmapped, which depends on the driver and what got allocated since)
  old_size = a_size
  sizes = [64 << 10] * 8 + [512 << 10] * 4 + [old_size]   # small ones first: the freed range is handed out first-fit from its start
  victims = [Tensor.full(sz // 4, 0x1234567, dtype=dtypes.int32).contiguous().realize() for sz in sizes]
  vas = [int(v.uop.buffer._buf.va_addr) for v in victims]
  inside = [a <= va < a + old_size for va in vas]
  print("victims inside the old scratch range:", sum(inside), "of", len(vas), "first at", f"{min(vas):#x}", "(old base", f"{a:#x})", flush=True)
  if "--fault" in sys.argv:
    print("replaying the graph (spills go to the old base) ...", flush=True)
    small(x).realize()
    print("replay returned:", small(x).tolist()[:4])
    bad = [int((v != 0x1234567).sum().item()) for v in victims]
    print("corrupted words per victim:", bad, "<-- USE AFTER FREE (the replay spilled into freed, reallocated memory)" if any(bad) else "(victims intact)")
