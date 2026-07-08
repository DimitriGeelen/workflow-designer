#!/usr/bin/env python3
"""_gallery-list-verify.py — test for the T-143 read-only /api/list endpoint.

Proves /api/list merges the rendered corpus with saved maps, resolves each map's
latest saved version + openTarget, extracts titles, and excludes invalid ids.
Dependency-free (stdlib only): builds an isolated temp repo, launches
gallery-serve.py on an ephemeral port pointing at it, GETs /api/list, and asserts.

Fixture repo:
  rendered/alpha.bpmn  (name="Alpha Process")  + saved versions v1,v2  -> sources[rendered,saved], openTarget v2
  rendered/beta.bpmn   (name="beta")           , no saved versions     -> sources[rendered],       openTarget rendered
  .editor-versions/gamma (saved-only, v1)                              -> sources[saved],          openTarget v1
  rendered/UPPER.bpmn  + .editor-versions/Bad_Upper (invalid ids)      -> excluded

Exit 0 = all pass; exit 1 = any failure (P-011 gate reads this).
"""
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.join(HERE, 'gallery-serve.py')

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def bpmn(name):
    return ('<?xml version="1.0"?><bpmn:definitions xmlns:bpmn="x">'
            '<bpmn:process id="Pool_x" name="%s"/></bpmn:definitions>' % name)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)


def write_index(root, id_, entries):
    d = os.path.join(root, '.editor-versions', id_)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'index.json'), 'w', encoding='utf-8') as f:
        json.dump(entries, f)


def make_repo():
    root = tempfile.mkdtemp(prefix='t143-repo-')
    rendered = os.path.join(root, 'examples', 'aef-processes', 'rendered')
    write(os.path.join(rendered, 'alpha.bpmn'), bpmn('Alpha Process'))
    write(os.path.join(rendered, 'beta.bpmn'), bpmn('beta'))
    write(os.path.join(rendered, 'UPPER.bpmn'), bpmn('nope'))          # invalid id -> excluded
    os.makedirs(os.path.join(root, 'build', 'gallery'), exist_ok=True)
    # alpha has saved versions v1,v2 (latest v2)
    write_index(root, 'alpha', [{'v': 1, 'ts': 1000, 'thumb': 'v1.png'},
                                {'v': 2, 'ts': 2000, 'thumb': 'v2.png'}])
    # gamma is saved-only (v1)
    write_index(root, 'gamma', [{'v': 1, 'ts': 500, 'thumb': 'v1.png'}])
    # Bad_Upper is an invalid id in the store -> excluded
    write_index(root, 'Bad_Upper', [{'v': 1, 'ts': 1}])
    return root


def start_server(repo):
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    docroot = os.path.join(repo, 'build', 'gallery')
    cmd = [sys.executable, SERVER, str(port),
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


def get_list(port):
    with urllib.request.urlopen('http://127.0.0.1:%d/api/list' % port, timeout=2) as r:
        return json.loads(r.read())


def main():
    repo = make_repo()
    proc, port = start_server(repo)
    try:
        data = get_list(port)
        maps = {m['id']: m for m in data.get('maps', [])}

        check('returns-maps-array', isinstance(data.get('maps'), list),
              'type=%s' % type(data.get('maps')).__name__)
        check('has-corpus-and-saved-only', set(maps) == {'alpha', 'beta', 'gamma'},
              'ids=%s' % sorted(maps))
        check('excludes-invalid-ids', 'UPPER' not in maps and 'Bad_Upper' not in maps,
              'ids=%s' % sorted(maps))

        a = maps.get('alpha', {})
        check('alpha-merges-rendered-and-saved', sorted(a.get('sources', [])) == ['rendered', 'saved'],
              'sources=%s' % a.get('sources'))
        check('alpha-latest-is-v2', (a.get('latest') or {}).get('v') == 2
              and (a.get('latest') or {}).get('count') == 2, 'latest=%s' % a.get('latest'))
        check('alpha-opentarget-version-v2', a.get('openTarget') == {'kind': 'version', 'v': 2},
              'openTarget=%s' % a.get('openTarget'))
        check('alpha-title-from-process-name', a.get('title') == 'Alpha Process',
              'title=%s' % a.get('title'))

        b = maps.get('beta', {})
        check('beta-rendered-only', b.get('sources') == ['rendered'] and b.get('latest') is None,
              'sources=%s latest=%s' % (b.get('sources'), b.get('latest')))
        check('beta-opentarget-rendered', b.get('openTarget') == {'kind': 'rendered'},
              'openTarget=%s' % b.get('openTarget'))

        g = maps.get('gamma', {})
        check('gamma-saved-only', g.get('sources') == ['saved']
              and (g.get('latest') or {}).get('v') == 1, 'sources=%s latest=%s'
              % (g.get('sources'), g.get('latest')))
        check('gamma-opentarget-version-v1', g.get('openTarget') == {'kind': 'version', 'v': 1},
              'openTarget=%s' % g.get('openTarget'))

        # read-only: /api/list must not create anything under the corpus
        check('list-is-read-only',
              not os.path.exists(os.path.join(repo, 'examples', 'aef-processes', 'rendered', 'gamma.bpmn')),
              'no gamma.bpmn written to corpus')
    finally:
        proc.terminate()

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print('\n%d/%d checks passed' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
