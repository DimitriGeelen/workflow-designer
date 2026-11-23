#!/usr/bin/env python3
"""shard-coverage.py — T-1480 (T-1478 GO; codex: "missing-leg warnings must become gate failures"): did the shards of a
split run, together, run exactly the tier's legs?

  python3 tools/pool/shard-coverage.py <tier> <legs.tsv> [<legs.tsv> ...]

Each legs.tsv is one shard's leg log (T1288_LEGLOG: tier, leg, attempt, ...; a retried leg has a second row). The
expected set is `tests/run-bridge-tests.sh --list-legs` for the tier, read from the checkout this runs in (the gate's
HEAD). Counted: each leg's FIRST attempt row. Exit 0 when every expected leg ran exactly once across the shards and no
shard ran a leg the tier does not have; 1 otherwise, naming the legs; 2 when it cannot measure (no leg log, no list).
T1480_EXPECTED=<file>: the expected leg names, one per line, instead of --list-legs (tests only).
"""
import collections
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def expected(tier):
    if os.environ.get('T1480_EXPECTED'):
        return {l.strip() for l in open(os.environ['T1480_EXPECTED'], encoding='utf-8') if l.strip()}
    # T-1489: the list comes from the COMMIT the shards tested (T1480_REF, the gate's HEAD; default HEAD), exported, not
    # from the working tree: an uncommitted new leg made a green split read "missing 2" (2026-11-23), and an uncommitted
    # removal would hide a missing one.
    ref = os.environ.get('T1480_REF') or 'HEAD'
    tmp = tempfile.mkdtemp(prefix='t1480-legs-')
    try:
        arch = subprocess.run(['git', '-C', ROOT, 'archive', ref, 'tests', 'tools', 'examples'], capture_output=True, timeout=120)
        if arch.returncode != 0:
            return set()
        if subprocess.run(['tar', '-x', '-C', tmp], input=arch.stdout, capture_output=True, timeout=120).returncode != 0:
            return set()
        r = subprocess.run(['bash', os.path.join(tmp, 'tests/run-bridge-tests.sh'), '--list-legs'],
                           capture_output=True, text=True, cwd=tmp, timeout=300)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    legs = set()
    for line in r.stdout.splitlines():
        p = line.split(None, 1)
        if len(p) == 2 and p[0] == tier:
            legs.add(p[1].strip())
    return legs


def main(argv):
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    tier, files = argv[1], argv[2:]
    want = expected(tier)
    if not want:
        print('shard-coverage: NOT MEASURED — no %s legs listed' % tier)
        return 2
    ran = collections.Counter()
    for f in files:
        try:
            fh = open(f, encoding='utf-8')
        except OSError as e:
            print('shard-coverage: NOT MEASURED — no leg log %s (%s)' % (f, e.strerror))
            return 2
        with fh:
            for line in fh:
                p = line.rstrip('\n').split('\t')
                if len(p) >= 3 and p[0] == tier and p[2] == 'first':
                    ran[p[1]] += 1
    missing = sorted(want - set(ran))
    extra = sorted(set(ran) - want)
    twice = sorted(l for l, n in ran.items() if n > 1)
    if missing or extra or twice:
        print('shard-coverage: RED — %d shard(s), %d of %d %s legs ran; missing %d%s; not in the tier %d%s; ran more than once %d%s' % (
            len(files), len(set(ran) & want), len(want), tier,
            len(missing), (' (' + ', '.join(missing[:8]) + ')') if missing else '',
            len(extra), (' (' + ', '.join(extra[:8]) + ')') if extra else '',
            len(twice), (' (' + ', '.join(twice[:8]) + ')') if twice else ''))
        return 1
    print('shard-coverage: ok — %d shard(s) ran each of the %d %s legs exactly once' % (len(files), len(want), tier))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
