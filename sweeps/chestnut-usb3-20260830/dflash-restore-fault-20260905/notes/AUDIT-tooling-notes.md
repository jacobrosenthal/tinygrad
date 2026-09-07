
## Tooling notes (2026-09-05): cyrozap
- `ghidra-asmedia-8051`: Ghidra processor module for ASMedia's 8051 variant (banked code, DPX, MOVX timing). Use it for any
  re-decompile of stock (e.g. to find the vendor 0xF0 dispatch, which a literal grep of ghidra.c does not surface).
- `8051-timing-db` + usb-to-pcie-re Notes: the core is 1T @ ~114.29 MHz (STC-Y5-like), MOVX 2-5 cycles. => ISR latency is
  sub-microsecond vs ~30-100 us between host control transfers; bounded 16-bit spin loops are ~5-8 ms worst case. Feed
  these into `emulate/` to replay host command sequences against the ISRs deterministically (validate the F0 fix off-hardware).
