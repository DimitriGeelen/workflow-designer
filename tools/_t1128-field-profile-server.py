#!/usr/bin/env python3
"""T-1128: the field-profile write path of tools/gallery-serve.py, against a throwaway repository.

Legs: GET project/map 404 with base 'none'; PUT project valid -> 200 + base; GET returns it; PUT with a
stale base -> 409 + current; malformed -> 422 and the file unchanged; map scope stored beside the map's
versions; bad id -> 400 on GET and PUT; history has one line per successful write; no temp files left.
Exit 0 = all legs pass.
"""
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SERVER = os.path.join(HERE, 'gallery-serve.py')


def free_port():
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    p = s.getsockname()[1]
    s.close()
    return p


def call(base, method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + path, data=data, method=method,
                                 headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, json.loads(r.read() or b'{}')
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b'{}')


def main():
    repo = tempfile.mkdtemp(prefix='t1128-repo-')
    doc = tempfile.mkdtemp(prefix='t1128-doc-')
    port = free_port()
    proc = subprocess.Popen([sys.executable, SERVER, str(port), '--repo', repo, '--docroot', doc,
                             '--bind', '127.0.0.1'], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    base = 'http://127.0.0.1:%d' % port
    legs = []

    def leg(ok, name, detail=None):
        legs.append((bool(ok), name, detail))

    try:
        for _ in range(100):
            try:
                if call(base, 'GET', '/api/health')[0] == 200:
                    break
            except OSError:
                pass
            time.sleep(0.1)
        P1 = {'version': 1, 'types': {'serviceTask': {'hide': ['horizon'], 'show': ['sideEffect']}}}
        P2 = {'version': 1, 'types': {'serviceTask': {'hide': ['endpoint']}}}
        c, b = call(base, 'GET', '/api/field-profile')
        cm, bm = call(base, 'GET', '/api/field-profile?id=map-a')
        leg(c == 404 and b.get('base') == 'none' and cm == 404 and bm.get('scope') == 'map',
            'GET project and map: 404 with base none', (c, b, cm, bm))
        c, b = call(base, 'PUT', '/api/field-profile', {'profile': P1, 'base': 'none', 'note': 'first'})
        b1 = b.get('base')
        c2, g = call(base, 'GET', '/api/field-profile')
        leg(c == 200 and b1 and b1 != 'none' and c2 == 200 and g['profile'] == P1 and g['base'] == b1,
            'PUT project valid, GET returns it with the same base', (c, b, c2, g))
        c, b = call(base, 'PUT', '/api/field-profile', {'profile': P2, 'base': 'none'})
        leg(c == 409 and b.get('current') == P1 and b.get('base') == b1, 'stale base refused 409 with current', (c, b))
        before = open(os.path.join(repo, 'field-profile.json'), 'rb').read()
        c, b = call(base, 'PUT', '/api/field-profile',
                    {'profile': {'version': 1, 'types': {'serviceTask': {'hide': ['tier'], 'show': ['tier']}}}, 'base': b1})
        after = open(os.path.join(repo, 'field-profile.json'), 'rb').read()
        leg(c == 422 and before == after, 'malformed refused 422, file unchanged', (c, b))
        c, b = call(base, 'PUT', '/api/field-profile?id=map-a', {'profile': P2, 'base': 'none'})
        mp = os.path.join(repo, '.editor-versions', 'map-a', 'field-profile.json')
        cm, gm = call(base, 'GET', '/api/field-profile?id=map-a')
        cp, gp = call(base, 'GET', '/api/field-profile')
        leg(c == 200 and os.path.exists(mp) and cm == 200 and gm['profile'] == P2 and gp['profile'] == P1,
            'map scope stored beside its versions, project untouched', (c, b, cm, gm))
        cg, _ = call(base, 'GET', '/api/field-profile?id=../etc')
        cpu, _ = call(base, 'PUT', '/api/field-profile?id=..%2Fetc', {'profile': P2, 'base': 'none'})
        leg(cg == 400 and cpu == 400 and not os.path.exists(os.path.join(repo, 'etc')), 'bad id refused 400 (GET, PUT)', (cg, cpu))
        hp = [json.loads(l) for l in open(os.path.join(repo, 'field-profile.history.jsonl'))]
        hm = [json.loads(l) for l in open(os.path.join(repo, '.editor-versions', 'map-a', 'field-profile.history.jsonl'))]
        leg(len(hp) == 1 and hp[0]['new'] == P1 and hp[0]['previous'] is None and hp[0]['note'] == 'first'
            and len(hm) == 1 and hm[0]['scope'] == 'map', 'history: one line per successful write', (hp, hm))
        tmps = [f for d, _, fs in os.walk(repo) for f in fs if f.endswith('.tmp')]
        leg(not tmps, 'no temp files left behind', tmps)
    finally:
        proc.kill()
    for ok, name, detail in legs:
        print(('ok   ' if ok else 'FAIL ') + name + ('' if ok else '  ' + json.dumps(detail, default=str)[:400]))
    n = sum(1 for l in legs if l[0])
    print('T-1128 server: %d/%d' % (n, len(legs)))
    return 0 if n == len(legs) else 1


if __name__ == '__main__':
    sys.exit(main())
