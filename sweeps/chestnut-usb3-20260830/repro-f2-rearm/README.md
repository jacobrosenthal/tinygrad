# USB copyin: many small transfers back-to-back (regression control)

Setup: RX 7900 XTX behind an ASM2464PD bridge (tinygrad `AMD` device, USB iface), USB 3 link, bridge firmware
`asm2464pd-firmware` master `ed4e39b7` (no F2 re-arm wait; stock firmware has the same 0xF2 handler).

    python3 repro.py            # 800 random 8-16 KiB buffers, one transfer each, synchronize between (= kernel binary uploads)
    GAP=0.01 python3 repro.py   # same with 10 ms between uploads

Result 2026-09-05 on `ed4e39b7`: 0/800 differ back-to-back (800 uploads in 5.0 s), 0/800 with GAP=0.01.
Small single-chunk transfers do not lose their head on this firmware. The F2 re-arm race (engine re-armed while the
previous transfer is still draining drops the first ~2 sectors) reproduces with large pipelined transfers instead:
`repro-f2-corruption` / `test/external/external_test_usb_asm24.py` at `SIZE=64000000`, ~39/40 runs corrupt on
`ed4e39b7`, 0/50 with firmware `fix-f2-arm-race` (`17a145f`: poll XDATA `0xC450` bit 1 idle before re-arming).

`test_snippet.py` is the same check in `test/external/external_test_usb_asm24.py` form (`TestUSBIntegrity`), for the
regression suite that accompanies the firmware/host fix.

The server-side GCVM fault on LLM-cache restore is a separate issue; see the fork's sweeps notes.
