#!/usr/bin/env python3
"""_t684-mutation-control.py — mutation control for the /api/save containment fence.

WHAT A MUTATION CONTROL IS FOR
------------------------------
A regression test that has only ever been green is a claim, not a control. This
one breaks the fence on purpose and checks that the breach is observable, then
puts the fence back and checks it holds. If the manufactured breach cannot be
seen, the control refuses to report anything at all.

THE FAILURE THIS EXISTS TO PREVENT (PL-177)
-------------------------------------------
T-681 S2 prototyped this and its first run reported NO-GO for a broken reason:
the mutated guard refused the escape id on grounds unrelated to containment, so
its "fence held" phase could not have gone red however broken the fence was. A
probe that produces the right answer for a broken reason is the only failure
mode that survives review.

The specific trap is that `ID_RE` rejects `../escaped` on FORMAT grounds before
the containment fence is ever consulted. A pristine run therefore refuses the
save whether or not the fence exists — which is why phase C below is reported
but explicitly excluded from the verdict.

THE PHASES
----------
  A  guard removed AND ID_RE widened   -> MUST escape (proves a breach is visible)
  B  ID_RE widened, guard intact       -> MUST refuse (the real assertion)
  C  pristine                          -> refuses on FORMAT grounds; evidence of
                                          nothing about containment, reported only

VERDICT
-------
  GREEN (0)         A escaped AND B refused
  BREACH (1)        B escaped — the fence is broken
  INCONCLUSIVE (2)  A did not escape — the harness could not observe a breach it
                    manufactured, so B's refusal is unevidenced. NOT a pass.

INCONCLUSIVE is the whole point. Without it, a harness that silently stopped
being able to see breaches would report GREEN forever.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.join(HERE, 'gallery-serve.py')
MIN_BPMN = '<?xml version="1.0"?><definitions xmlns="x"><process id="p"/></definitions>'

ORIGINAL_ID_RE = r"ID_RE = re.compile(r'^[a-z0-9][a-z0-9_-]*$')"
WIDE_ID_RE = r"ID_RE = re.compile(r'^[A-Za-z0-9._/-]+$')"
GUARD_CALL = '        escape = _escaping_save_target(id_)'
GUARD_END = '        ts = int(time.time() * 1000)'

# Escapes .editor-versions/<id>/ but stays inside REPO — the case a repo-level
# guard would wave through. The witness is a directory: versions_dir() makedirs it.
ESCAPE_ID = '../escaped'
WITNESS = 'escaped'

GREEN, BREACH, INCONCLUSIVE = 0, 1, 2


def variant(widen_id_re: bool, remove_guard: bool, sabotage: bool = False) -> str:
    """A temp dir holding a gallery-serve.py mutated as requested."""
    src = open(SERVER, encoding='utf-8').read()
    if widen_id_re:
        if ORIGINAL_ID_RE not in src:
            raise RuntimeError('ID_RE literal not found — cannot mutate what cannot be located')
        src = src.replace(ORIGINAL_ID_RE, WIDE_ID_RE)
    if remove_guard:
        if GUARD_CALL not in src:
            raise RuntimeError('containment guard call not found on the save path')
        start = src.index(GUARD_CALL)
        end = src.index(GUARD_END, start)
        src = src[:start] + src[end:]
        if 'escape = _escaping_save_target' in src:
            raise RuntimeError('guard removal did not take')
    if sabotage:
        # --self-test only: make phase A unable to escape, so INCONCLUSIVE must fire.
        src = src.replace(WIDE_ID_RE, ORIGINAL_ID_RE)
    tmp = tempfile.mkdtemp(prefix='t684-server-')
    dst = os.path.join(tmp, 'gallery-serve.py')
    with open(dst, 'w', encoding='utf-8') as f:
        f.write(src)
    return dst


def fresh_repo() -> str:
    root = tempfile.mkdtemp(prefix='t684-repo-')
    os.makedirs(os.path.join(root, 'examples', 'aef-processes', 'rendered'), exist_ok=True)
    os.makedirs(os.path.join(root, 'build', 'gallery', 'rendered'), exist_ok=True)
    return root


def run_phase(label: str, server: str) -> tuple[int, bool]:
    """Launch the given server against a fresh repo, POST the escape id."""
    repo = fresh_repo()
    docroot = os.path.join(repo, 'build', 'gallery')
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    proc = subprocess.Popen(
        [sys.executable, server, str(port), '--repo', repo,
         '--docroot', docroot, '--bind', '127.0.0.1'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        for _ in range(100):
            try:
                urllib.request.urlopen('http://127.0.0.1:%d/api/health' % port, timeout=0.5)
                break
            except Exception:
                time.sleep(0.05)
        req = urllib.request.Request(
            'http://127.0.0.1:%d/api/save' % port,
            data=json.dumps({'id': ESCAPE_ID, 'bpmn': MIN_BPMN}).encode('utf-8'),
            headers={'Content-Type': 'application/json'}, method='POST')
        try:
            with urllib.request.urlopen(req, timeout=3) as r:
                status = r.status
                r.read()
        except urllib.error.HTTPError as e:
            status = e.code
            e.read()
    finally:
        proc.terminate()
        proc.wait(timeout=5)
    escaped = os.path.exists(os.path.join(repo, WITNESS))
    print('  %-11s HTTP %-3d  escaped=%-5s' % (label, status, escaped))
    shutil.rmtree(repo, ignore_errors=True)
    return status, escaped


def control(sabotage_phase_a: bool = False) -> int:
    servers = []
    try:
        print('phase A — MANUFACTURED BREACH (guard removed, ID_RE widened)')
        print('  the harness must be able to SEE a breach, or nothing below means anything')
        sa = variant(widen_id_re=True, remove_guard=True, sabotage=sabotage_phase_a)
        servers.append(sa)
        _, a_escaped = run_phase('A breach', sa)

        print('\nphase B — THE FENCE (ID_RE widened, containment guard intact)')
        sb = variant(widen_id_re=True, remove_guard=False)
        servers.append(sb)
        b_status, b_escaped = run_phase('B fence', sb)

        print('\nphase C — PRISTINE (reported, EXCLUDED from the verdict)')
        c_status, c_escaped = run_phase('C pristine', SERVER)
        print('  refusal above is on FORMAT grounds (ID_RE rejects %r before the fence is'
              % ESCAPE_ID)
        print('  reached). It is evidence about the regex, not about containment.')

        print('\n' + '=' * 72)
        if not a_escaped:
            print('VERDICT: INCONCLUSIVE (exit 2)')
            print('  Phase A manufactured a breach and the harness did NOT observe it.')
            print('  Phase B refused — but a refusal that phase A cannot contradict is')
            print('  not evidence the fence works. Reporting GREEN here would be the')
            print('  exact PL-177 failure this control exists to prevent.')
            return INCONCLUSIVE
        if b_escaped:
            print('VERDICT: BREACH (exit 1)')
            print('  Phase A proved breaches are visible, and phase B escaped:')
            print('  the containment fence on /api/save is broken. See T-683.')
            return BREACH
        print('VERDICT: GREEN (exit 0)')
        print('  Phase A escaped, so the harness can see a breach. Phase B did not,')
        print('  so the fence holds when ID_RE does not. (Phase C: HTTP %d, escaped=%s —'
              % (c_status, c_escaped))
        print('  reported for completeness, excluded from this verdict.)')
        return GREEN
    finally:
        for s in servers:
            shutil.rmtree(os.path.dirname(s), ignore_errors=True)


def self_test() -> int:
    """Prove INCONCLUSIVE is reachable — the control's refusal-to-conclude must fire."""
    print('SELF-TEST — sabotaging phase A so it cannot observe its own breach.')
    print('If this does not return INCONCLUSIVE, the meta-assertion is decorative.\n')
    code = control(sabotage_phase_a=True)
    print()
    if code == INCONCLUSIVE:
        print('self-test OK — INCONCLUSIVE is reachable; the control can refuse to conclude')
        return 0
    print('SELF-TEST FAIL: sabotaged phase A returned %d, expected %d (INCONCLUSIVE)'
          % (code, INCONCLUSIVE), file=sys.stderr)
    return 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--self-test', action='store_true',
                    help='prove INCONCLUSIVE is reachable, then exit')
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    return control()


if __name__ == '__main__':
    sys.exit(main())
