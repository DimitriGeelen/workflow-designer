#!/usr/bin/env python3
"""T-1483: the suite runs the what-a-person-sees gate as one browser leg PER CHECK, so the sharder can place them apart.
  P1 the suite's person-sees-<check> browser legs name exactly the gate's checks (`person-sees-gate.sh --list`):
     none lost, none extra, none twice; and the old single `person-sees-gate` leg is gone
  P2 `person-sees-gate.sh --only <a name that is no check>` is NOT a pass (exit 2, says NOT RUN): a misspelt leg
     cannot pass by running nothing
Control: T1483_SUITE=<a suite listing that still has the single leg> fails P1.
"""
import collections
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
GATE = os.path.join(ROOT, 'tools/person-sees-gate.sh')


def suite_legs():
    if os.environ.get('T1483_SUITE'):
        return open(os.environ['T1483_SUITE'], encoding='utf-8').read().splitlines()
    r = subprocess.run(['bash', os.path.join(ROOT, 'tests/run-bridge-tests.sh'), '--list-legs'],
                       capture_output=True, text=True, cwd=ROOT, timeout=300)
    return r.stdout.splitlines()


def main():
    fails = 0
    checks = subprocess.run(['bash', GATE, '--list'], capture_output=True, text=True, timeout=60).stdout.split()
    browser = [l.split(None, 1)[1].strip() for l in suite_legs() if l.startswith('browser ')]
    ours = [n[len('person-sees-'):] for n in browser if n.startswith('person-sees-')]
    twice = sorted(n for n, c in collections.Counter(ours).items() if c > 1)
    if checks and sorted(set(ours)) == sorted(checks) and not twice and 'person-sees-gate' not in browser:
        print('PASS  P1 %d person-sees legs = the gate\'s %d checks, each once; no single person-sees-gate leg' % (len(ours), len(checks)))
    else:
        fails += 1
        print('FAIL  P1 gate checks %s; suite legs %s; twice %s; single leg still there: %s' % (
            checks, ours, twice, 'person-sees-gate' in browser))
    r = subprocess.run(['bash', GATE, '--only', 'no-such-check'], capture_output=True, text=True, timeout=60)
    if r.returncode == 2 and 'NOT RUN' in r.stdout:
        print('PASS  P2 --only with no matching check exits 2 and says NOT RUN')
    else:
        fails += 1
        print('FAIL  P2 --only no-such-check: exit %d, %r' % (r.returncode, r.stdout[-200:]))
    print('T-1483 person-sees legs: %s' % ('GREEN' if fails == 0 else 'RED'))
    return 1 if fails else 0


if __name__ == '__main__':
    sys.exit(main())
