# Drop-in for test/external/external_test_usb_asm24.py, class TestUSBIntegrity (same conventions as the tests there).
# Not applied to test/ yet: goes into the upstream PR together with the fix.

  def testCopyinBackToBack(self):
    # Hundreds of small uploads in a row (loading kernel binaries) must not lose the head of a transfer: the bridge drops
    # the first ~2 sectors when re-armed while the previous transfer is still draining. The trailing sentinel still lands.
    rng = np.random.default_rng(0)
    srcs = [rng.integers(0, 256, int(rng.integers(8192, 16384)) & ~3, dtype=np.uint8) for _ in range(getenv("N", 800))]
    ts = []
    for a in srcs:
      ts.append(Tensor(a, device="AMD").realize())
      self.dev.synchronize()
    for i, (a, t) in enumerate(zip(srcs, ts)):
      with self.subTest(i=i, size=a.size): np.testing.assert_array_equal(a, t.numpy())
