#!/usr/bin/env python3
# One-shot edit of perf_sweep2.sh (applied by chain_20260906.sh once the running copy exits; a running bash script must not be
# edited in place): add the exclusive sweep lock and an ONLY=<regex> leg filter, matching perf_sweep.sh.
import sys
p = sys.argv[1]; s = open(p).read()
lock = 'exec 9>/tmp/chestnut-sweep.lock; flock -n 9 || { echo "another sweep holds /tmp/chestnut-sweep.lock; refusing to run concurrently"; exit 1; }\n'
a = '  IFS=\'|\' read -r name extra flags temp <<< "$leg"; LOG='
b = '  IFS=\'|\' read -r name extra flags temp <<< "$leg"\n  if [ -n "$ONLY" ] && ! echo "$name" | grep -qE "$ONLY"; then continue; fi\n  LOG='
assert a in s and "flock" not in s, "perf_sweep2.sh does not look like the expected original"
lines = s.split("\n"); lines.insert(1, lock.rstrip("\n"))
open(p, "w").write("\n".join(lines).replace(a, b))
print("patched", p)
