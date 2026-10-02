#!/usr/bin/env python3
"""_t1000-revendor-worklist — protocol step 3: what the upgrade overwrote, and how to put it back.

After the pristine vendor commit P and the baseline advance (tools/_t1000-revendor-gate.sh), every
declared local fix the upgrade overwrote is STALE in tools/_t517. For each one this lists:
  - its manifest entry (task, upstream class, the first line of its reason);
  - the LOCAL commits that touched the path before the upgrade (old baseline .. P^), excluding
    upgrade commits (any commit that changed .agentic-framework/VERSION);
  - a patch made of those commits' own diffs for that path, to re-apply with `git apply -3`.
Each entry is then resolved one of three ways: re-applied, reclassified `superseded` (upstream has
it), or dropped with a reason. The upgrade is done when _t517 is clean.

Why per-commit diffs and not diff(old baseline, P^): the old baseline may be several re-vendors
old (it was v1.6.763 when this was written), so that diff carries every upstream change in between
and would not apply. A local commit's own diff is the fix and nothing else.

Writes under build/revendor-worklist/<P>/ (gitignored). Prints a summary only.
  _t1000-revendor-worklist.py                    P = baseline_commit, paths = _t517 STALE
  _t1000-revendor-worklist.py --pristine SHA --old-base SHA --paths p1 p2 ...   (explicit)
"""
import argparse
import os
import re
import subprocess
import sys

import yaml

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DIV = '.agentic-framework/.vendor-divergence.yaml'
VF = '.agentic-framework/VERSION'


def git(*a, check=True):
    r = subprocess.run(['git', '-C', ROOT] + list(a), capture_output=True, text=True)
    if check and r.returncode:
        sys.exit('git %s failed: %s' % (' '.join(a), r.stderr.strip()))
    return r.stdout


def manifest(rev=None):
    text = git('show', '%s:%s' % (rev, DIV)) if rev else open(os.path.join(ROOT, DIV)).read()
    return yaml.safe_load(text) or {}


def stale_paths():
    r = subprocess.run([sys.executable, os.path.join(ROOT, 'tools', '_t517-vendor-divergence.py')],
                       capture_output=True, text=True, cwd=ROOT)
    return [m.group(1) for m in re.finditer(r'^\s*STALE\s+\[[^\]]*\]\s+(\S+)', r.stdout, re.M)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pristine')
    ap.add_argument('--old-base')
    ap.add_argument('--paths', nargs='*')
    a = ap.parse_args()
    P = a.pristine or str(manifest().get('baseline_commit') or '')
    if not P:
        sys.exit('no pristine commit: pass --pristine or set baseline_commit')
    P = git('rev-parse', P).strip()
    pre = git('rev-parse', P + '^').strip()
    old = a.old_base or str(manifest(pre).get('baseline_commit') or '')
    if not old:
        sys.exit('no old baseline: pass --old-base')
    paths = a.paths if a.paths is not None else stale_paths()
    entries = {e.get('path'): e for e in (manifest(pre).get('entries') or []) if isinstance(e, dict)}
    upgrades = set(git('log', '--format=%H', '%s..%s' % (old, pre), '--', VF).split())
    out = os.path.join(ROOT, 'build', 'revendor-worklist', P[:12])
    os.makedirs(out, exist_ok=True)
    rows, n_patch = [], 0
    for i, p in enumerate(paths, 1):
        commits = [c for c in git('log', '--format=%H', '--reverse', '%s..%s' % (old, pre), '--', p).split()
                   if c not in upgrades]
        e = entries.get(p, {})
        subj = [git('log', '-1', '--format=%h %s', c).strip()[:90] for c in commits]
        patch = ''.join(git('show', '--format=From %H%nSubject: %s%n', c, '--', p) for c in commits)
        pf = ''
        if patch.strip():
            pf = os.path.join(out, '%02d-%s.patch' % (i, re.sub(r'[^A-Za-z0-9._-]+', '_', p)))
            open(pf, 'w').write(patch)
            n_patch += 1
        reason = str(e.get('reason') or '').strip().split('\n')[0][:110]
        rows.append((p, e.get('task', '?'), e.get('upstream', '?'), reason, subj, pf))
    with open(os.path.join(out, 'WORKLIST.md'), 'w') as f:
        f.write('# Re-vendor worklist — pristine %s (pre-upgrade %s, old baseline %s)\n\n' % (P[:12], pre[:12], old[:12]))
        f.write('Resolve each: re-apply (`git apply -3 <patch>`), reclassify `superseded`, or drop with a reason.\n\n')
        for p, task, up, reason, subj, pf in rows:
            f.write('## %s\n- manifest: task %s, upstream %s — %s\n' % (p, task, up, reason or '(no manifest entry)'))
            f.write('- local commits: %s\n' % (len(subj) or 'NONE FOUND (fix predates the old baseline, or the entry was never a code fix)'))
            for s in subj:
                f.write('  - %s\n' % s)
            f.write('- patch: %s\n- resolution: \n\n' % (os.path.relpath(pf, ROOT) if pf else '-'))
    print('worklist: %d stale path(s), %d with a patch, %d with no local commit found -> %s' % (
        len(rows), n_patch, sum(1 for r in rows if not r[4]), os.path.relpath(out, ROOT) + '/WORKLIST.md'))
    for p, task, up, reason, subj, pf in rows:
        print('  %-62s %-6s %2d commit(s)' % (p[:62], task, len(subj)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
