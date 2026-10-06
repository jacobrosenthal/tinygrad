import pickle, tempfile, os, unittest
from unittest.mock import patch
from tinygrad.llm import cache, gguf

class TestLLMCacheLoad(unittest.TestCase):
  def test_failed_load_drops_uploaded_weights(self):
    # the weights are uploaded before the model unpickles: a failure after that must not leave them registered (a second copy in VRAM)
    with tempfile.TemporaryDirectory() as d:
      model, weights = os.path.join(d, "m.gguf"), os.path.join(d, "w.bin")
      with open(model, "wb") as f: f.write(b"x")
      with open(weights, "wb") as f: f.write(bytes(4096))
      with patch.object(cache, "cache_dir", d), patch.object(cache._Unpickler, "load", side_effect=RuntimeError("corrupt")):
        cf = cache._cache_file(model, 8); os.makedirs(cf.parent, exist_ok=True)
        with open(cf, "wb") as f: pickle.dump({"key": cache._cache_key(model, 8), "max_slot": 0, "bases": [(weights, 0, 4096)]}, f)
        n = len(gguf.base_registry)
        self.assertIsNone(cache.load_llm_cache(model, 8))
        self.assertEqual(len(gguf.base_registry), n)

if __name__ == "__main__":
  unittest.main()
