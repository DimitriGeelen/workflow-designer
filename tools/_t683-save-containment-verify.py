#!/usr/bin/env python3
"""_t683-save-containment-verify.py — regression test for save-path containment.

WHY THIS EXISTS
---------------
`/api/save` writes five targets (version snapshot, thumbnail, index.json, canonical
corpus copy, served copy), every one derived from the request's `id`. Before T-683 the
only fence was ID_RE. `_within_repo` existed, documented itself as belt-and-braces, and
was referenced ONLY on the delete path (:120) — the write path had no containment check
at all. T-681 S2 showed behaviourally that widening ID_RE alone puts a write outside the
version store (HTTP 200, escaped=True).

THE DISCRIMINATING CASE
-----------------------
The obvious fix — apply `_within_repo` to the save path — does not work, and this test
is built to prove it rather than assert it. `_within_repo` asserts containment in REPO,
but the save targets live in specific roots INSIDE repo. An id of `../.claude/settings`
resolves inside REPO, so `_within_repo` PASSES it, while it escapes the version store
entirely and lands on enforcement config. Case `within-repo-would-have-allowed-it` below
asserts that the rejected path really would have passed the weaker guard — without it,
this suite could not tell the real fix from the decorative one (PL-318).

CUTTING THE BRACES
------------------
ID_RE rejects the hostile id before the containment guard is ever reached, which is what
defence-in-depth means and also makes the second belt untestable through the front door.
So the live cases run a COPY of the server with ID_RE widened — T-681 S2's experiment
repeated against the fixed code. A guard that is only reachable when the first belt
breaks must be tested with the first belt broken, or it is being asserted, not verified.

Exit 0 = all pass; exit 1 = any failure (P-011 gate reads this).
"""
import importlib.util
import json
import os
import re
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

# Stays INSIDE repo, escapes the version store. The whole point of the suite.
ESCAPING_ID = '../.claude/settings'
ORIGINAL_ID_RE = r"ID_RE = re.compile(r'^[a-z0-9][a-z0-9_-]*$')"

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def load_module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def make_repo():
    root = tempfile.mkdtemp(prefix='t683-repo-')
    os.makedirs(os.path.join(root, 'examples', 'aef-processes', 'rendered'), exist_ok=True)
    os.makedirs(os.path.join(root, 'build', 'gallery', 'rendered'), exist_ok=True)
    return root


def widened_server():
    """A copy of gallery-serve.py with ID_RE widened — the first belt deliberately cut."""
    src = open(SERVER, encoding='utf-8').read()
    if ORIGINAL_ID_RE not in src:
        return None, 'ID_RE literal not found — the suite cannot cut a belt it cannot locate'
    wide = src.replace(ORIGINAL_ID_RE, r"ID_RE = re.compile(r'^[A-Za-z0-9._/-]+$')")
    tmp = tempfile.mkdtemp(prefix='t683-server-')
    dst = os.path.join(tmp, 'gallery-serve.py')
    with open(dst, 'w', encoding='utf-8') as f:
        f.write(wide)
    return dst, None


def start_server(server, repo, docroot):
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    cmd = [sys.executable, server, str(port),
           '--repo', repo, '--docroot', docroot, '--bind', '127.0.0.1']
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    url = 'http://127.0.0.1:%d/api/health' % port
    for _ in range(100):
        try:
            urllib.request.urlopen(url, timeout=0.5)
            return proc, port
        except Exception:
            time.sleep(0.05)
    proc.terminate()
    raise RuntimeError('server did not come up on port %d' % port)


def save(port, id_):
    """POST /api/save. Returns (status, body_dict)."""
    req = urllib.request.Request(
        'http://127.0.0.1:%d/api/save' % port,
        data=json.dumps({'id': id_, 'bpmn': MIN_BPMN}).encode('utf-8'),
        headers={'Content-Type': 'application/json'}, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
            return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except Exception:
            return e.code, {}


def main():
    # ---------- unit level: the discrimination this whole task turns on ----------
    mod = load_module(SERVER, 't683_gallery_serve')
    repo = make_repo()
    mod.REPO = repo
    mod.DOCROOT = os.path.join(repo, 'build', 'gallery')

    escape = mod._escaping_save_target(ESCAPING_ID)
    check('escaping-id-refused-by-per-target-guard',
          escape is not None,
          'first escaping target=%s' % (escape[0] if escape else None))

    # The load-bearing assertion: the SAME paths pass the weaker guard the task
    # description proposed. Without this, a decorative fix would score identically.
    all_inside_repo = all(mod._within_repo(p) for p, _ in mod._save_targets(ESCAPING_ID))
    check('within-repo-would-have-allowed-it',
          all_inside_repo,
          'every save target for %r resolves inside REPO — _within_repo alone is not a fence'
          % ESCAPING_ID)

    ordinary = mod._escaping_save_target('normal-map')
    check('ordinary-id-not-refused-by-guard', ordinary is None,
          'guard must not be always-red')

    # ---------- ID_RE untouched: the fix must not rest on the regex ----------
    src = open(SERVER, encoding='utf-8').read()
    check('id-re-unchanged', ORIGINAL_ID_RE in src,
          'containment must be redundant with ID_RE, not a replacement for it')

    # ---------- live: the belt holds with the braces cut ----------
    wide_server, err = widened_server()
    if err:
        check('widened-server-built', False, err)
    else:
        repo2 = make_repo()
        docroot2 = os.path.join(repo2, 'build', 'gallery')
        proc, port = start_server(wide_server, repo2, docroot2)
        try:
            status, body = save(port, ESCAPING_ID)
            check('widened-id-re-save-refused', status == 400,
                  'status=%s error=%s' % (status, body.get('error')))
            landed = os.path.join(repo2, '.claude', 'settings')
            check('no-write-escaped-the-version-store',
                  not os.path.exists(landed),
                  'would-be escape target: %s' % landed)

            # not always-red: an ordinary save on the SAME widened server still works
            status, body = save(port, 'normal-map')
            wrote_version = os.path.exists(
                os.path.join(repo2, '.editor-versions', 'normal-map', 'v1.bpmn'))
            wrote_served = os.path.exists(
                os.path.join(docroot2, 'rendered', 'normal-map.bpmn'))
            check('ordinary-save-still-succeeds',
                  status == 200 and wrote_version and wrote_served,
                  'status=%s version=%s served=%s' % (status, wrote_version, wrote_served))
        finally:
            proc.terminate()
            shutil.rmtree(os.path.dirname(wide_server), ignore_errors=True)

    # ---------- DOCROOT outside REPO must not produce a false refusal ----------
    repo3 = make_repo()
    docroot3 = tempfile.mkdtemp(prefix='t683-docroot-outside-')
    os.makedirs(os.path.join(docroot3, 'rendered'), exist_ok=True)
    proc, port = start_server(SERVER, repo3, docroot3)
    try:
        status, body = save(port, 'outside-docroot-map')
        served = os.path.join(docroot3, 'rendered', 'outside-docroot-map.bpmn')
        check('docroot-outside-repo-no-false-refusal',
              status == 200 and os.path.exists(served),
              'status=%s served_exists=%s' % (status, os.path.exists(served)))
    finally:
        proc.terminate()

    failed = [n for n, ok, _ in results if not ok]
    print('\n%d/%d passed' % (len(results) - len(failed), len(results)))
    if failed:
        print('FAILED: %s' % ', '.join(failed))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
