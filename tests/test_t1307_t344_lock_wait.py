#!/usr/bin/env python3
"""T-1307: _t344 waits for an audit that holds the lock, and says so honestly when the wait runs out.

The 2026-10-26 reproduction: a full `fw audit` (492 s measured) held the one-at-a-time lock while _t344 waited its
fixed 300 s; the wait ran out and leg 8 parsed "Another audit is already running" as the verdict, reporting a stale
anchor ("coverage=none") instead of the truth. A stand-in fw (T344_FW, tests only) holds the lock for a given number of
calls, then prints a recorded verdict:
  1. lock released inside the wait  -> leg 8 reads the verdict and agrees; the NOTE names the wait
  2. lock held past the wait        -> red naming the held lock (UNMEASURED), never the stale-anchor text
  3. the default wait outlasts a measured full audit (492 s), so a real one is waited for, not misread
Exit 0 = all passed.
"""
import os
import re
import stat
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, 'tools', '_t344-watch-set-denominator.sh')
results = []

STUB = r'''#!/bin/bash
n=$(cat "$STUB_COUNT" 2>/dev/null || echo 0); n=$((n+1)); echo $n > "$STUB_COUNT"
if [ "$n" -le "$STUB_HOLD" ]; then echo "Another audit is already running — exiting (no verdict produced)"; exit 0; fi
echo "[WARN] Fabric: 530 registered, 135 unregistered (of 644 watched — 82% covered)"
'''


def check(name, ok, detail=''):
    results.append(ok)
    print(('PASS  ' if ok else 'FAIL  ') + name + ('' if ok else '\n      %s' % detail))


def run(tmp, hold, wait_max):
    stub = os.path.join(tmp, 'fw')
    with open(stub, 'w') as f:
        f.write(STUB)
    os.chmod(stub, os.stat(stub).st_mode | stat.S_IEXEC)
    count = os.path.join(tmp, 'count')
    if os.path.exists(count):
        os.remove(count)
    env = dict(os.environ, T344_FW=stub, STUB_COUNT=count, STUB_HOLD=str(hold), T344_WAIT_MAX=str(wait_max),
               T344_WAIT_STEP='0', T344_INDEPENDENT='135 644')
    p = subprocess.run(['bash', SCRIPT], cwd=ROOT, env=env, capture_output=True, text=True, timeout=600)
    return p.returncode, p.stdout + p.stderr


def main():
    with tempfile.TemporaryDirectory(prefix='t1307-') as tmp:
        rc, out = run(tmp, hold=2, wait_max=60)
        check('1 lock released inside the wait: leg 8 agrees, NOTE names the wait',
              'coverage checks agree: 135 unregistered of 644 watched' in out and 'another audit was running' in out,
              out[-600:])

        rc, out = run(tmp, hold=10 ** 6, wait_max=3)
        check('2 lock held past the wait: red naming the held lock, not a stale anchor',
              rc != 0 and 'UNMEASURED' in out and 'still held' in out and 'anchor has gone stale' not in out,
              'rc=%d\n%s' % (rc, out[-800:]))

    src = open(SCRIPT, encoding='utf-8').read()
    m = re.search(r'T344_WAIT_MAX:-(\d+)', src)
    check('3 the default wait (%s s) outlasts a measured full audit (492 s)' % (m.group(1) if m else '?'),
          bool(m) and int(m.group(1)) > 492, 'no T344_WAIT_MAX default found' if not m else m.group(0))

    print('\nT-1307 _t344 lock wait: %d/%d passed' % (sum(results), len(results)))
    return 0 if all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
