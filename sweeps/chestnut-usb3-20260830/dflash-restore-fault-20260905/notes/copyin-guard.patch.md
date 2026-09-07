# Host-side copyin guard (to apply AFTER the code-image verdict; NOT applied yet — source edits invalidate the LLM cache)

## A. Poll the bridge's bulk-DMA-idle bit before every F2 arm (mirror of the C450 firmware fix; works on STOCK firmware)
In `tinygrad/runtime/ops_amd.py` `_copyin`, immediately before `usb.usb.control_write(0xF2, ...)`:

    # F2 re-arm race: arming while the bridge's bulk DMA is still draining the previous chunk drops the first ~2 sectors of the
    # new one (silent corruption; a kernel image loses its first 1 KB). C450 bit1 = DMA active (firmware fix polls the same bit).
    # Bounded: ~100 us per read; the DMA clears in microseconds, so this normally costs one read.
    for _ in range(64):
      if not (usb.read(0xC450, 1)[0] & 0x02): break
    else: raise RuntimeError("USB bridge bulk DMA stuck active before F2 re-arm")

Cost: one 0xE4 control read (~100 us) per 256 KB chunk => ~0.4 ms/MB => negligible vs ~500 MB/s. Env-gate as USB_F2_IDLE_POLL (default 1).

## B. Verify program uploads (belt and braces; catches any copyin corruption class, not just this one)
In `AMDProgram.__init__` after `_copyin` + `synchronize()`:

    if self.dev.is_usb() and getenv("AMD_VERIFY_CODE", 1):
      for attempt in range(3):
        back = memoryview(bytearray(image.nbytes)); self.dev.allocator._copyout(back, self.lib_gpu)
        if bytes(back) == bytes(image): break
        first = next(i for i in range(image.nbytes) if back[i] != image[i])
        print(f"amd: kernel code upload corrupted ({self.name}, first bad byte +{first:#x} of {image.nbytes:#x}), re-uploading", flush=True)
        self.dev.allocator._copyin(self.lib_gpu, image); self.dev.synchronize()
      else: raise RuntimeError(f"kernel code upload keeps failing verification: {self.name}")

Cost: one copyout per program (~13 KB, ~30-50 ms over USB) => ~800 programs => +25-40 s on a restore. Acceptable as a
detector; default ON until A + the firmware fix are validated, then default OFF (or keep for USB only).

## C. Order of operations
1. Verdict from the VRAM readback (this run).  2. Apply A (+B as detector).  3. Validate on fresh RESTORED instances
(the 3-minute reproducer): expect B to log "corrupted ... re-uploading" with A=0 and NEVER with A=1 => mechanism proven
twice over.  4. Flash fix-f0-f2-arm-race (C450 + F0) and repeat with A=0: expect 0 corruption => firmware fix validated.

## A2. Leading sentinel (host-protocol hardening; independent of firmware)
The trailing sentinel cannot see sectors dropped at the FRONT of a chunk (the F2 re-arm race drops the first ~2 sectors; the
end of the wire, and thus the sentinel, still lands). Put a second sentinel in the FIRST dword of each chunk's wire image
(payload shifted by 4 bytes, or the first 4 payload bytes carried in the trailer) and have the SDMA ring POLL_REGMEM both the
leading and the trailing sentinel before the SRAM->VRAM copy. A front-dropped chunk then never satisfies the leading poll: the
host's wait_fence times out (10 s) with a clear error instead of silently copying garbage. One extra POLL_REGMEM per 256 KB
chunk => negligible. Note upstream #17969/#17972 are real fixes of the sentinel protocol (stale match, torn fence read); this
closes its remaining blind spot. Upstreamable.
