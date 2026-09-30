# This fork: Qwen3.8-27B on a single RX 7900 XTX

Branch `amd-qwen-on-master` of [jacobrosenthal/tinygrad](https://github.com/jacobrosenthal/tinygrad). Upstream tinygrad's README follows below.

## What it adds
- Fast decode kernels for the 7900 XTX that read the quantized GGUF weights directly (Q3_K to Q8_0, IQ4_XS)
- Faster prompt processing using the GPU's matrix cores
- Speculative decoding: a small drafter guesses the next few tokens and the model checks them all in one pass. Output is unchanged.
- A compressed kv cache, so 98K tokens of context fit in 24 GB
- Conversation reuse: a request that continues an earlier conversation, or shares its system prompt, skips re-reading that part
- The compiled model is cached on disk, so restarts take 10-20 s

## Requirements
- AMD RX 7900 XTX, 24 GB (measured as an eGPU over a USB4 dock)
- `Qwen3.8-27B-UD-Q4_K_XL.gguf` ([unsloth](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF))
- `Qwen3.8-27B-DFlash2-Q4_K_M.gguf`, the drafter ([z-lab](https://huggingface.co/z-lab/Qwen3.8-27B-DFlash2-GGUF), 1.1 GB)

## Install
```bash
git clone -b amd-qwen-on-master https://github.com/jacobrosenthal/tinygrad.git
cd tinygrad && python -m venv .venv && .venv/bin/pip install -e .
```

## Run
```bash
DEV=KFD+AMD:LLVM LLM_CACHE=1 MTP_DRAFT_VOCAB=65536 \
GDN_REPLAY=1 SPEC_ASYNC=1 MTP_K=5 DFLASH=Qwen3.8-27B-DFlash2-Q4_K_M.gguf \
.venv/bin/python -m tinygrad.llm.cli \
  --model Qwen3.8-27B-UD-Q4_K_XL.gguf \
  --mmproj none \
  --repeat-penalty 1.0 \
  --max_context 98304 \
  --host 0.0.0.0 \
  --serve 8080
```

The first start compiles the model, which takes a few minutes. Later starts load it from the cache. The server speaks the OpenAI chat
API (`/v1/chat/completions`) on port 8080, and answers Ollama's model-listing requests.

| setting | what it does |
|---|---|
| `DEV=KFD+AMD:LLVM` | use the AMD GPU |
| `LLM_CACHE=1` | cache the compiled model on disk |
| `MTP_DRAFT_VOCAB=65536` | drafts only score the first 64K entries of the vocabulary: cheaper, same output |
| `GDN_REPLAY=1` | after a draft is accepted, update the model's state cheaply instead of running the model again |
| `SPEC_ASYNC=1` | queue the next step before reading the current one, so the GPU doesn't wait on Python |
| `MTP_K=5` | draft 5 tokens per step |
| `DFLASH=...gguf` | use the DFlash2 drafter instead of the model's built-in one |
| `--mmproj none` | text only (the default loads an image model if one sits next to the GGUF) |
| `--repeat-penalty 1.0` | no repeat penalty |
| `--max_context 98304` | 96K tokens of context |

The server also keeps a saved copy of a conversation when another request pushes it out, in host memory and only the part in use, so
it works at 98K context. Switching back to a saved conversation costs a few seconds instead of re-reading all of it.

## How much the speed settings help
All off by default; the run command above turns them on. Decode speed on the 7900 XTX, compared to the built-in drafter with 3 drafts
and nothing else:

| settings | code gen | code edit | agent | prose |
|---|---|---|---|---|
| `GDN_REPLAY=1 SPEC_ASYNC=1 MTP_K=4` | +23% | +19% | +14% | +5% |
| `GDN_REPLAY=1 SPEC_ASYNC=1 MTP_K=5 DFLASH=...` | +38% | +32% | +26% | +4% |

Measured with greedy decoding. With normal sampling, the DFlash2 row is 13-18% faster than the `MTP_K=4` row on code and agent work.

On real traffic (a batch of short structured requests) the run command above averages ~130 tok/s and peaks at 160, against 84 tok/s
before these settings.

---

<div align="center">

<picture>
  <source media="(prefers-color-scheme: light)" srcset="/docs/logo_tiny_light.svg">
  <img alt="tiny corp logo" src="/docs/logo_tiny_dark.svg" width="50%" height="50%">
</picture>

tinygrad: For something between [PyTorch](https://github.com/pytorch/pytorch) and [karpathy/micrograd](https://github.com/karpathy/micrograd). Maintained by [tiny corp](https://tinygrad.org).

<h3>

[Homepage](https://github.com/tinygrad/tinygrad) | [Documentation](https://docs.tinygrad.org/) | [Discord](https://discord.gg/ZjZadyC7PK)

</h3>

[![GitHub Repo stars](https://img.shields.io/github/stars/tinygrad/tinygrad)](https://github.com/tinygrad/tinygrad/stargazers)
[![Unit Tests](https://github.com/tinygrad/tinygrad/actions/workflows/test.yml/badge.svg)](https://github.com/tinygrad/tinygrad/actions/workflows/test.yml)
[![Discord](https://img.shields.io/discord/1068976834382925865)](https://discord.gg/ZjZadyC7PK)

</div>

---

tinygrad is an end-to-end deep learning stack:

- **Tensor library** with autograd
- **IR and compiler** that fuse and lower kernels
- **JIT + graph execution**
- **nn / optim / datasets** for real training

It’s inspired by PyTorch (ergonomics), JAX (functional transforms and IR-based AD), and TVM (scheduling and codegen), but stays intentionally tiny and hackable.

---

## How tinygrad compares

**PyTorch**

- ✅ Similar: eager `Tensor` API, autograd, `optim`, basic datasets and layers.
- ✅ You can write familiar training loops.
- 🔁 Unlike PyTorch, the entire compiler and IR are visible and hackable.

**JAX**

- ✅ IR-based autodiff over primitives (like JAXPR + XLA).
- ✅ Function-level JIT (`TinyJit`) that captures and replays kernels.
- 🔁 Fewer functional transforms (no full `vmap`/`pmap` yet), but far easier to read.

**TVM**

- ✅ Multiple lowering passes, scheduling, and BEAM search over kernels.
- ✅ Device “graphs” for batched execution.
- 🔁 tinygrad also ships the **front-end framework** (tensors, nn, optim), not just the compiler.

---

### Laziness

Try a matmul. See how, despite the style, it is fused into one kernel with the power of laziness.

```sh
DEBUG=3 python3 -c "from tinygrad import Tensor;
N = 1024; a, b = Tensor.empty(N, N), Tensor.empty(N, N);
(a.reshape(N, 1, N) * b.T.reshape(1, N, N)).sum(axis=2).realize()"
```

And we can change `DEBUG` to `4` to see the generated code.

### Neural networks

As it turns out, 90% of what you need for neural networks are a decent autograd/tensor library.
Throw in an optimizer, a data loader, and some compute, and you have all you need.

```python
from tinygrad import Tensor, nn, Context

class LinearNet:
  def __init__(self):
    self.l1 = Tensor.kaiming_uniform(784, 128)
    self.l2 = Tensor.kaiming_uniform(128, 10)
  def __call__(self, x:Tensor) -> Tensor:
    return x.flatten(1).dot(self.l1).relu().dot(self.l2)

model = LinearNet()
optim = nn.optim.Adam([model.l1, model.l2], lr=0.001)

x, y = Tensor.rand(4, 1, 28, 28), Tensor([2,4,3,7])  # replace with real mnist dataloader

with Context(TRAINING=1):
  for i in range(10):
    optim.zero_grad()
    loss = model(x).sparse_categorical_crossentropy(y).backward()
    optim.step()
    print(i, loss.item())
```

See [examples/beautiful_mnist.py](examples/beautiful_mnist.py) for the full version that gets 98% in ~5 seconds

## Accelerators

tinygrad already supports numerous accelerators, including:

- [x] [OpenCL](tinygrad/runtime/ops_cl.py)
- [x] [CPU](tinygrad/runtime/ops_cpu.py)
- [x] [METAL](tinygrad/runtime/ops_metal.py)
- [x] [CUDA](tinygrad/runtime/ops_cuda.py)
- [x] [AMD](tinygrad/runtime/ops_amd.py)
- [x] [NV](tinygrad/runtime/ops_nv.py)
- [x] [QCOM](tinygrad/runtime/ops_qcom.py)
- [x] [WEBGPU](tinygrad/runtime/ops_webgpu.py)

And it is easy to add more! Your accelerator of choice only needs to support a total of ~25 low level ops.

To check default accelerator run: `python3 -c "from tinygrad import Device; print(Device.DEFAULT)"`

## Installation

The current recommended way to install tinygrad is from source.

### From source

```sh
git clone https://github.com/tinygrad/tinygrad.git
cd tinygrad
python3 -m pip install -e .
```

### Direct (master)

```sh
python3 -m pip install git+https://github.com/tinygrad/tinygrad.git
```

## Documentation

Documentation along with a quick start guide can be found on the [docs website](https://docs.tinygrad.org/) built from the [docs/](/docs) directory.

### Quick example comparing to PyTorch

```python
from tinygrad import Tensor

x = Tensor.eye(3).clone()  # clone to make it a buffer
y = Tensor([[2.0,0,-2.0]])
z = y.matmul(x).sum()
z.backward()

print(x.grad.tolist())  # dz/dx
print(y.grad.tolist())  # dz/dy
```

The same thing but in PyTorch:
```python
import torch

x = torch.eye(3, requires_grad=True)
y = torch.tensor([[2.0,0,-2.0]], requires_grad=True)
z = y.matmul(x).sum()
z.backward()

print(x.grad.tolist())  # dz/dx
print(y.grad.tolist())  # dz/dy
```

## Contributing

There has been a lot of interest in tinygrad lately. Following these guidelines will help your PR get accepted. If you do submit a PR, please include a sentence or two about why you want this merged and why you think it will improve the project.

If you are a new contributor with something that looks even close to AI written, it will be closed without feedback and you may be banned from our GitHub. No human should waste time reading AI slop. And for everyone, if you used AI, disclose what you used it for.

We'll start with what will get your PR closed with a pointer to this section:

- No code golf! While low line count is a guiding light of this project, anything that remotely looks like code golf will be closed. The true goal is reducing complexity and increasing readability, and deleting `\n`s does nothing to help with that.
- All docs and whitespace changes will be closed unless you are a well-known contributor. The people writing the docs should be those who know the codebase the absolute best. People who have not demonstrated that shouldn't be messing with docs. Whitespace changes are both useless *and* carry a risk of introducing bugs.
- Anything you claim is a "speedup" must be benchmarked. In general, the goal is simplicity, so even if your PR makes things marginally faster, you have to consider the tradeoff with maintainability and readability.
- In general, the code outside the core `tinygrad/` folder is not well tested, so unless the current code there is broken, you shouldn't be changing it.
- If your PR looks "complex", is a big diff, or adds lots of lines, it won't be reviewed or merged. Consider breaking it up into smaller PRs that are individually clear wins. A common pattern I see is prerequisite refactors before adding new functionality. If you can (cleanly) refactor to the point that the feature is a 3 line change, this is great, and something easy for us to review.

Now, what we want:

- Bug fixes (with a regression test) are great! This library isn't 1.0 yet, so if you stumble upon a bug, fix it, write a test, and submit a PR, this is valuable work.
- Solving bounties! tinygrad [offers cash bounties](https://docs.google.com/spreadsheets/d/1WKHbT-7KOgjEawq5h5Ic1qUWzpfAzuD_J06N1JwOCGs/edit?usp=sharing) for certain improvements to the library. All new code should be high quality and well tested.
- Features. However, if you are adding a feature, consider the line tradeoff. If it's 3 lines, there's less of a bar of usefulness it has to meet over something that's 30 or 300 lines. All features must have regression tests. In general with no other constraints, your feature's API should match torch or numpy.
- Refactors that are clear wins. In general, if your refactor isn't a clear win it will be closed. But some refactors are amazing! Think about readability in a deep core sense. A whitespace change or moving a few functions around is useless, but if you realize that two 100 line functions can actually use the same 110 line function with arguments while also improving readability, this is a big win. Refactors should pass [process replay](#process-replay-tests).
- Tests/fuzzers. If you can add tests that are non brittle, they are welcome. We have some fuzzers in here too, and there's a plethora of bugs that can be found with them and by improving them. Finding bugs, even writing broken tests (that should pass) with `@unittest.expectedFailure` is great. This is how we make progress.
- Dead code removal from core `tinygrad/` folder. We don't care about the code in extra, but removing dead code from the core library is great. Less for new people to read and be confused by.

### Running tests

You should install the pre-commit hooks with `pre-commit install`. This will run the linter, mypy, and a subset of the tests on every commit.

For more examples on how to run the full test suite please refer to the [CI workflow](.github/workflows/test.yml).

Some examples of running tests locally:
```sh
python3 -m pip install -e '.[testing]'  # install extra deps for testing
python3 test/runtime/test_ops.py        # just the ops tests
python3 -m pytest test/                 # whole test suite
```

For agents, always run tests with `-n12` for speed.

#### Process replay tests

[Process replay](https://github.com/tinygrad/tinygrad/blob/master/test/external/process_replay/README.md) compares your PR's generated kernels against master. If your PR is a refactor or speedup without any expected behavior change, It should include [pr] in the pull request title.
