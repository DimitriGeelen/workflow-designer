#!/usr/bin/env python3
"""_gallery-save-allowlist-verify.py — regression test for T-138 corpus gating.

Proves the /api/save canonical-corpus write is existence-or-promotion gated so
scratch/test saves cannot pollute examples/aef-processes/rendered/. Dependency-free
(stdlib only): builds an isolated temp repo, launches gallery-serve.py on an
ephemeral port pointing at it, and POSTs the five cases.

Cases:
  1. new id            -> NOT written to corpus (corpus:false); version+served ARE written
  2. existing corpus   -> overwrites canonical (corpus:true)
  3. promote:true      -> new id published to corpus (corpus:true)
  4. --allow-new-corpus-> new id published to corpus (corpus:true)
  5. no work lost      -> new (blocked) id still has vN.bpmn + served copy on disk

Exit 0 = all pass; exit 1 = any failure (P-011 gate reads this).
"""
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.request
import urllib.error

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.join(HERE, 'gallery-serve.py')
MIN_BPMN = '<?xml version="1.0"?><definitions xmlns="x"><process id="p"/></definitions>'

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def make_repo():
    """Isolated repo with one pre-existing corpus map ('existing')."""
    root = tempfile.mkdtemp(prefix='t138-repo-')
    corpus = os.path.join(root, 'examples', 'aef-processes', 'rendered')
    os.makedirs(corpus, exist_ok=True)
    os.makedirs(os.path.join(root, 'build', 'gallery', 'rendered'), exist_ok=True)
    with open(os.path.join(corpus, 'existing.bpmn'), 'w') as f:
        f.write('<old/>')
    return root


def start_server(repo, extra=None):
    # Port 0 -> OS picks a free port; read it back from the socket via a probe port.
    # gallery-serve.py binds a fixed PORT, so pick one and retry on collision.
    import socket
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    docroot = os.path.join(repo, 'build', 'gallery')
    cmd = [sys.executable, SERVER, str(port),
           '--repo', repo, '--docroot', docroot, '--bind', '127.0.0.1']
    if extra:
        cmd += extra
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # wait for health
    url = 'http://127.0.0.1:%d/api/health' % port
    for _ in range(100):
        try:
            urllib.request.urlopen(url, timeout=0.5)
            return proc, port
        except Exception:
            time.sleep(0.05)
    proc.terminate()
    raise RuntimeError('server did not come up on port %d' % port)


def save(port, id_, promote=False):
    body = {'id': id_, 'bpmn': MIN_BPMN}
    if promote:
        body['promote'] = True
    req = urllib.request.Request(
        'http://127.0.0.1:%d/api/save' % port,
        data=json.dumps(body).encode('utf-8'),
        headers={'Content-Type': 'application/json'}, method='POST')
    with urllib.request.urlopen(req, timeout=2) as r:
        return json.loads(r.read())


def corpus_path(repo, id_):
    return os.path.join(repo, 'examples', 'aef-processes', 'rendered', '%s.bpmn' % id_)


def version_path(repo, id_):
    return os.path.join(repo, '.editor-versions', id_, 'v1.bpmn')


def served_path(repo, id_):
    return os.path.join(repo, 'build', 'gallery', 'rendered', '%s.bpmn' % id_)


def main():
    # --- default gating ---
    repo = make_repo()
    proc, port = start_server(repo)
    try:
        # Case 1: new id blocked from corpus
        r = save(port, 'scratch1')
        check('new-id-not-published-to-corpus',
              r.get('corpus') is False and not os.path.exists(corpus_path(repo, 'scratch1')),
              'resp=%s exists=%s' % (r.get('corpus'), os.path.exists(corpus_path(repo, 'scratch1'))))
        # Case 5: no work lost — version + served still written
        check('scratch-still-versioned',
              os.path.exists(version_path(repo, 'scratch1')),
              version_path(repo, 'scratch1'))
        check('scratch-still-served',
              os.path.exists(served_path(repo, 'scratch1')),
              served_path(repo, 'scratch1'))
        # Case 2: existing corpus map edits normally
        r = save(port, 'existing')
        with open(corpus_path(repo, 'existing')) as f:
            body = f.read()
        check('existing-corpus-map-overwritten',
              r.get('corpus') is True and body == MIN_BPMN,
              'resp=%s bytes=%d' % (r.get('corpus'), len(body)))
        # Case 3: explicit promote publishes a new id
        r = save(port, 'promoted1', promote=True)
        check('promote-flag-publishes-new-id',
              r.get('corpus') is True and os.path.exists(corpus_path(repo, 'promoted1')),
              'resp=%s exists=%s' % (r.get('corpus'), os.path.exists(corpus_path(repo, 'promoted1'))))
    finally:
        proc.terminate()

    # --- --allow-new-corpus opt-out ---
    repo2 = make_repo()
    proc2, port2 = start_server(repo2, extra=['--allow-new-corpus'])
    try:
        r = save(port2, 'legacy1')
        check('allow-new-corpus-flag-publishes-new-id',
              r.get('corpus') is True and os.path.exists(corpus_path(repo2, 'legacy1')),
              'resp=%s exists=%s' % (r.get('corpus'), os.path.exists(corpus_path(repo2, 'legacy1'))))
    finally:
        proc2.terminate()

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print('\n%d/%d checks passed' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
