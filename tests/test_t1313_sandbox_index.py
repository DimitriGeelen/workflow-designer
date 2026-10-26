#!/usr/bin/env python3
"""T-1313: a core-tier sandbox cannot reach the real repo's git.

The defect: the core tier's per-run TMPDIR lives inside the project (.context/st/r.XXXXXX, T-1299). _t630 and _t634 build
sandbox projects there without a .git of their own, and the framework's task close runs `git -C "$PROJECT_ROOT" add -A`
in them. git searched upward, found THIS repo and staged the sandbox's files in its index: 12 paths on every core run,
committed 11 times by commits without a pathspec (2026-10-24..26).

The real tools/_t1288-tiers.sh is sourced against a stand-in repo (a fresh `git init` in a temp dir, never this repo), so
the old code's failure lands in the stand-in's index, not ours:
  1. a git write from a non-repo sandbox under the run's TMPDIR leaves the stand-in's index empty
  2. a sandbox that is its own repo still works (git init + add inside the run's TMPDIR)
  3. the stand-in repo itself is still reachable from its root (the ceiling only stops the upward search)
  4. .context/st/ is ignored by this repo, so a leaked path cannot ride a pathspec-free commit
Exit 0 = all passed.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, 'tools', '_t1288-tiers.sh')
results = []

SCRIPT = r'''
set -u
ROOT="$1"
. "$2"
T1288_TIER=core; T1288_LIST=0
t1288_private_tmpdir
mkdir -p "$TMPDIR/sb/.tasks" && echo x > "$TMPDIR/sb/.tasks/T-901.md"
git -C "$TMPDIR/sb" add -A -- .tasks >/dev/null 2>&1
echo "leak=$(git -C "$ROOT" diff --cached --name-only | wc -l)"
git init -q "$TMPDIR/own" && echo y > "$TMPDIR/own/f" && git -C "$TMPDIR/own" add f && echo "own=$(git -C "$TMPDIR/own" diff --cached --name-only | wc -l)"
echo "root=$(git -C "$ROOT" rev-parse --show-toplevel)"
t1288_cleanup
'''


def check(name, ok, detail=''):
    results.append(ok)
    print(('PASS  ' if ok else 'FAIL  ') + name + ('' if ok else '\n      %s' % detail))


def main():
    tmp = tempfile.mkdtemp(prefix='t1313-')
    try:
        stand = os.path.join(tmp, 'repo')
        os.makedirs(stand)
        subprocess.run(['git', 'init', '-q', stand], check=True)
        env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
        p = subprocess.run(['bash', '-c', SCRIPT, 'x', stand, LIB], capture_output=True, text=True, env=env, timeout=60)
        out = p.stdout + p.stderr
        kv = dict(l.split('=', 1) for l in p.stdout.split() if '=' in l)
        check('1 a git write in a non-repo sandbox under the run TMPDIR leaves the repo index empty', kv.get('leak') == '0', out)
        check('2 a sandbox that is its own repo still works', kv.get('own') == '1', out)
        check('3 the repo is still found from its own root', os.path.realpath(kv.get('root', '')) == os.path.realpath(stand), out)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    ig = subprocess.run(['git', '-C', ROOT, 'check-ignore', '-q', '.context/st/r.ABCDEF/x/.tasks/completed/T-901.md'])
    check('4 .context/st/ is ignored by this repo', ig.returncode == 0, 'git check-ignore rc=%d' % ig.returncode)
    print('\nT-1313 sandbox index: %d/%d passed' % (sum(results), len(results)))
    return 0 if all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
