# USB transfers per decode step — measurement, 2026-09-06

Why: the comms survey (sweeps/qwen38-research-20260906) derived ~190-240 USB transfers per decode step FROM THE CODE (each MMIO
dword write = 0xF0 control + bulk OUT, each signal read = control + bulk IN; ~26 per graph launch x 4 graphs + copyouts + token copyin
+ polls) = 15-25 ms of a ~37 ms step. That number sizes both "one graph per step" (USB3 stays) and the USB4/KFD move; it has not been
measured. This directory measures it.

How: `scripts/count_transfers.sh` runs the production config (MTP K=3) with `LIBUSB_DEBUG=4`, which makes libusb log every submitted
transfer to stderr (the hcq2 runtime calls libusb from compiled programs through function pointers, so a Python wrapper would miss
them; libusb's own log does not). `scripts/usb_count.py` splits the log per request and divides by the step count from the server's
own "gen:" line. Logging slows the server; the counts are what matter. Nothing needs root (usbmon would, and would also count the
laptop's other USB traffic).

## Runs
| when | config | result |
|---|---|---|
| queued (chain3, after chain2's GEMV_TG sweep + bit-exactness gate) | mtp-k3, 4 x 300 tokens | pending |
| 05:29-05:37 | mtp-k3, 4 x 300 tok, LIBUSB_DEBUG=4 (logs/20260906-052928-usbdebug-mtp-k3.log) | **~540 libusb submits per decode step** (548 / 538 / 531 on requests 1-3; request 0 = 997 incl. first-request work); gen tok/s unaffected by the logging (76/71/73 vs 75 baseline) |

Result: 2.5x the code-derived 190-240. At 75 tok/s and 2.8 tok/step a step is ~37 ms, so 540 transfers cannot each cost 75-150 us
(that would be 40-80 ms): most are pipelined/async or ~30-50 us. Either way USB traffic is the dominant per-step cost on this
path, which is the case for (a) USB4/KFD (removes all of it) and (b) "one graph per step" + batched doorbells on USB3.
