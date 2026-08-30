# Pre-Chestnut baseline (2026-08-30)

Baseline numbers for the `amd-gemv-qwen38-jacob` branch, captured on the current
hardware (GMKtec M8, Ryzen 5 PRO 6650H, 7900 XTX over the internal OCuLink port —
PCIe 4.0 x4, ~64 Gbit/s) right before switching the GPU to an external "tiny
chestnut" dock (comma.ai/tinygrad, PCIe Gen4 x4 -> USB3/USB4 bridge, open-frame,
own ATX PSU) driven from a different host over USB.

Purpose: a clean pre/post diff once the GPU moves to Chestnut. Per the general
research on eGPU interconnects (see session discussion), decode/prefill tok/s
should barely move once weights are resident in VRAM -- the interconnect mostly
governs cold-start weight-load time, not steady-state throughput. This sweep is
the "before" half of that comparison.

## Setup

- Branch: `amd-gemv-qwen38-jacob` (curated rebase of the Splizard fork's work
  onto current tinygrad master), commit at capture time: see `git log -1` in
  this repo at the commit this README is checked in with.
- Model: `Qwen3.8-27B-UD-Q4_K_XL.gguf` (same as production `tinygrad-server-splizard.service`).
- Launched directly (not via systemd -- no sudo needed for a one-off sweep):
  `DEV=AMD:LLVM LLM_CACHE=1 PYTHONUNBUFFERED=1 .venv/bin/python3 -m tinygrad.llm.cli
  --model .../Qwen3.8-27B-UD-Q4_K_XL.gguf --mmproj none --repeat-penalty 1.15
  --max_context 98304 --host 127.0.0.1 --serve 8080`
- Cold compile: fresh `LLM_CACHE` key (different source than the fork checkout's
  own cache), full warmup paid.
- Harness: `~/llama.cpp/sweeps/newquants-20260828/send_request.py` (v3 -- the
  fixed version with `reasoning_content` capture and temperature=0.6 default,
  not the older buggy temperature=0 copies still sitting in this repo's own
  `sweeps/*-20260825/` dirs).
- Prompts: `~/llama.cpp/sweeps/newquants-20260828/prompts/{prose,code}.txt`
  (short prompts: 57 and 72 tokens respectively) -- 3 trials each, 800 max_tokens.

## Results (`results.json`)

`server_prefill_tok_s` / `server_gen_tok_s` / `server_accept_rate` are read
directly from the server's own request log line (ground truth, per this
session's "trust the wire" convention), not derived client-side. `wall_s`,
`completion_tokens`, etc. are the client's own view of the same request.

| task  | server gen tok/s | server prefill tok/s | accept rate |
|-------|-------------------|-----------------------|-------------|
| prose | 52-53             | 50-83                 | 0.35-0.37   |
| code  | 70-73             | 103-104               | 0.62-0.66   |

Prefill here (50-104 tok/s) is much lower than the 313-529 tok/s seen against
real Hermes traffic earlier the same day -- not a regression, just prompt-size
effect: these prompts are 57-72 tokens vs. 23-34K token real conversation
turns. Prefill throughput on this stack scales up with prompt/batch size, so
this number is only meaningful as a same-harness before/after comparison, not
as an absolute figure to compare against the longer-prompt numbers.

The raw server stdout (weight copy + JIT compile timings) isn't committed --
this repo's `sweeps/.gitignore` excludes `*.log`, matching the convention
already used by the other sweep dirs here.
