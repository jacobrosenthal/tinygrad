"""#2 check, CPU only: piece-memoized encode == original encode, and the 2nd pass over a grown chat prompt is fast."""
import time, random, sys
from tinygrad.llm.gguf import gguf_load
from tinygrad.llm.cli import SimpleTokenizer
kv, _ = gguf_load("/home/j/models/Qwen3.8-27B-UD-Q4_K_XL.gguf")
tok = SimpleTokenizer.from_gguf_kv(kv)
ref = SimpleTokenizer.from_gguf_kv(kv); ref._piece_cache_max_chars = 0  # reference: caching off
random.seed(1)
words = "the lighthouse keeper logged the tide table and the fog signal schedule while the supply boat waited offshore sensor readings were archived".split()
def turn(i): return f"<|im_start|>user\nTurn {i}: " + " ".join(random.choice(words) for _ in range(random.randint(400, 900))) + f"<|im_end|>\n<|im_start|>assistant\nAnswer {i} " + " ".join(random.choice(words) for _ in range(300)) + "<|im_end|>\n"
conv = "<|im_start|>system\nYou are helpful.<|im_end|>\n"
for i in range(120):
  conv += turn(i)
  prompt = conv + "<|im_start|>assistant\n"
  t0 = time.perf_counter(); a = tok.encode(prompt); dt = time.perf_counter() - t0
  if i % 30 == 29 or i == 0:
    t1 = time.perf_counter(); b = ref.encode(prompt); dr = time.perf_counter() - t1
    assert a == b, f"mismatch at turn {i}"
    print(f"turn {i:3d}: {len(a):6d} tokens  cached-encode {dt*1e3:7.1f} ms  reference {dr*1e3:7.1f} ms  cache {tok._piece_cache_chars/1e6:.1f} M chars", flush=True)
print("all equal")
