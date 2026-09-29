#!/usr/bin/env python3
"""T-884 (arc-005 S4): GET /api/instances?template=<id> on tools/gallery-serve.py.

Builds an isolated temp repo (binding table + rendered artefacts copied from this repo, one
fixture task at a recorded node, one fixture audit line), launches gallery-serve.py on a free
port against it (stdlib only, the _gallery-*-verify.py pattern), and asserts:

  1. a bound template answers 200 application/json with the tool's snapshot: state INSTANCES,
     the fixture instance at its node, its refusal line carried along
  2. a bound template with no live instances answers 200 with state NO-INSTANCES (a state,
     never a bare empty list)
  3. a missing / invalid (traversal-shaped) template is 400
  4. an unknown template is 404 with the tool's TEMPLATE-UNKNOWN detail
  5. the route never writes: the temp repo's file set is identical before and after

Exit 0 iff every check passes. Run: python3 tests/test_gallery_instances_api.py
"""
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
ROOT = os.path.abspath(os.path.join(HERE, '..'))
SERVER = os.path.join(ROOT, 'tools', 'gallery-serve.py')

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond)))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def build_repo(tmp):
    repo = os.path.join(tmp, 'repo')
    os.makedirs(os.path.join(repo, 'examples', 'aef-processes', 'rendered'))
    os.makedirs(os.path.join(repo, 'tools'))
    os.makedirs(os.path.join(repo, '.tasks', 'active'))
    os.makedirs(os.path.join(repo, '.tasks', 'completed'))
    os.makedirs(os.path.join(repo, '.context', 'audits'))
    shutil.copy(os.path.join(ROOT, 'examples', 'aef-processes', 'template-binding.yaml'),
                os.path.join(repo, 'examples', 'aef-processes'))
    for f in os.listdir(os.path.join(ROOT, 'examples', 'aef-processes', 'rendered')):
        if f.endswith('.bpmn'):
            shutil.copy(os.path.join(ROOT, 'examples', 'aef-processes', 'rendered', f),
                        os.path.join(repo, 'examples', 'aef-processes', 'rendered', f))
    shutil.copy(os.path.join(ROOT, 'tools', 'instance-node.py'), os.path.join(repo, 'tools'))
    with open(os.path.join(repo, '.tasks', 'active', 'T-9990-fixture.md'), 'w') as fh:
        fh.write('---\nid: T-9990\nname: "fixture"\nstatus: started-work\nworkflow_type: build\n'
                 'current_node: frw_6_run\nowner: human\n---\n\n# T-9990\n')
    with open(os.path.join(repo, '.context', 'audits', 'instance-refusals.jsonl'), 'w') as fh:
        fh.write(json.dumps({"ts": "2026-09-29T00:00:00Z", "task": "T-9990", "case": "skipped-human-gateway",
                             "rule": "R-033", "kind": "REFUSED-BY-GATE", "node": "frw_9_human", "target": "",
                             "template": "task-lifecycle", "detail": "fixture", "actor": "framework"}) + '\n')
        fh.write(json.dumps({"ts": "2026-09-29T00:00:01Z", "task": "T-0001", "case": "out-of-order-advance",
                             "rule": "template-flow", "kind": "REFUSED-TRANSITION", "node": "frw_3_start",
                             "target": "frw_10_finalize", "template": "x", "detail": "other task", "actor": "cli"}) + '\n')
    return repo


def file_set(root):
    out = set()
    for d, _, fs in os.walk(root):
        for f in fs:
            p = os.path.join(d, f)
            out.add((os.path.relpath(p, root), os.path.getsize(p)))
    return out


def start_server(repo):
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    docroot = os.path.join(repo, 'build', 'gallery')
    os.makedirs(docroot, exist_ok=True)
    proc = subprocess.Popen([sys.executable, SERVER, str(port), '--repo', repo, '--docroot', docroot,
                             '--bind', '127.0.0.1'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(100):
        try:
            urllib.request.urlopen('http://127.0.0.1:%d/api/health' % port, timeout=0.5)
            return proc, port
        except Exception:
            time.sleep(0.05)
    proc.terminate()
    raise RuntimeError('server did not come up')


def get(port, path):
    try:
        r = urllib.request.urlopen('http://127.0.0.1:%d%s' % (port, path), timeout=30)
        return r.status, r.headers.get('Content-Type', ''), r.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return e.code, e.headers.get('Content-Type', ''), e.read().decode('utf-8')


def main():
    tmp = tempfile.mkdtemp(prefix='t884-api-')
    proc = None
    try:
        repo = build_repo(tmp)
        before = file_set(repo)
        proc, port = start_server(repo)

        st, ct, body = get(port, '/api/instances?template=task-lifecycle')
        doc = json.loads(body) if st == 200 else {}
        inst = {i['task']: i for i in doc.get('instances', [])}
        check('bound template answers 200 application/json', st == 200 and ct.startswith('application/json'), '%s %s' % (st, ct))
        check('snapshot keys', sorted(doc.keys()) == ['examined', 'generated', 'instances', 'refusals', 'state', 'template'], str(sorted(doc.keys())))
        check('state INSTANCES with the fixture at its node', doc.get('state') == 'INSTANCES' and inst.get('T-9990', {}).get('node') == 'frw_6_run'
              and inst.get('T-9990', {}).get('state') == 'NODE' and inst.get('T-9990', {}).get('owner') == 'human', json.dumps(inst))
        rules = [(r['task'], r['rule'], r['node']) for r in doc.get('refusals', [])]
        check('the fixture\'s refusal is carried, the other task\'s is not', rules == [('T-9990', 'R-033', 'frw_9_human')], str(rules))

        st2, _, body2 = get(port, '/api/instances?template=inception-lifecycle')
        doc2 = json.loads(body2) if st2 == 200 else {}
        check('bound template with no live instance: 200, state NO-INSTANCES, instances []',
              st2 == 200 and doc2.get('state') == 'NO-INSTANCES' and doc2.get('instances') == [], '%s %s' % (st2, body2[:120]))

        st3, _, _ = get(port, '/api/instances')
        st4, _, _ = get(port, '/api/instances?template=../etc')
        st5, _, _ = get(port, '/api/instances?template=Task-Lifecycle')
        check('missing / traversal-shaped / uppercase template is 400', (st3, st4, st5) == (400, 400, 400), str((st3, st4, st5)))

        st6, _, body6 = get(port, '/api/instances?template=no-such-template')
        check('unknown template is 404 naming TEMPLATE-UNKNOWN', st6 == 404 and 'TEMPLATE-UNKNOWN' in body6, '%s %s' % (st6, body6[:120]))

        after = file_set(repo)
        check('the route wrote nothing into the repo', before == after, str(sorted(after - before)))
    finally:
        if proc:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except Exception:
                proc.kill()
        shutil.rmtree(tmp, ignore_errors=True)
    n_ok = sum(1 for _, ok in results if ok)
    print('\n%d/%d checks passed' % (n_ok, len(results)))
    return 0 if n_ok == len(results) else 1


if __name__ == '__main__':
    sys.exit(main())
