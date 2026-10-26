#!/usr/bin/env python3
"""T-1312: GET /api/field-catalog, the project's attribute catalog for the io ref picker.

Starts the REAL reference server (tools/gallery-serve.py) on a free localhost port against a temp repo and asserts over HTTP:
  1. no catalog file                      -> 404 {ok: false, error: "no field catalog"}
  2. a well-formed v1 file at the default -> 200 {ok: true, catalog} (the file served unchanged)
  3. --field-catalog PATH                 -> that file is served (a project points at its own export, e.g. greenfield's
                                             docs/views/nid-attributes.json, without copying it)
  4. refused whole (422): not JSON; no "version": 1; "attributes" not a list; a row without a text "ref"; a non-text
     notation/label/dataType
  5. the route takes no input: a query string cannot change which file is read
Exit 0 = all passed.
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

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(ROOT, 'tools', 'gallery-serve.py')
results = []

V1 = {"version": 1, "generatedBy": "t1312 fixture", "count": 2, "attributes": [
    {"ref": "nid:attr-salesforce-opportunity-id", "notation": "sfdc:Opportunity.Id", "label": "Id (Salesforce Opportunity)",
     "system": "nid:app-salesforce", "systemLabel": "Salesforce", "entity": "nid:de-opportunity", "dataType": "id",
     "keyRole": "keyPrimary", "sources": 1},
    {"ref": "nid:attr-tacton-account-company", "notation": "", "label": "companyName (Tacton Account)",
     "system": "nid:app-tacton", "systemLabel": "Tacton", "entity": "nid:de-account", "dataType": "", "keyRole": "",
     "sources": 2}]}


def check(name, ok, detail=''):
    results.append(ok)
    print(('PASS  ' if ok else 'FAIL  ') + name + ('' if ok else '\n      %s' % detail))


def start(repo, extra=()):
    s = socket.socket(); s.bind(('127.0.0.1', 0)); port = s.getsockname()[1]; s.close()
    docroot = os.path.join(repo, 'build', 'gallery'); os.makedirs(docroot, exist_ok=True)
    p = subprocess.Popen([sys.executable, SERVER, str(port), '--repo', repo, '--docroot', docroot, '--bind', '127.0.0.1',
                          *extra], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(100):
        try:
            urllib.request.urlopen('http://127.0.0.1:%d/api/health' % port, timeout=0.5)
            return p, port
        except Exception:
            time.sleep(0.1)
    p.kill()
    raise RuntimeError('server did not start')


def get(port, path='/api/field-catalog'):
    try:
        r = urllib.request.urlopen('http://127.0.0.1:%d%s' % (port, path), timeout=10)
        return r.status, json.loads(r.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode('utf-8'))


def main():
    tmp = tempfile.mkdtemp(prefix='t1312-')
    procs = []
    try:
        repo = os.path.join(tmp, 'repo'); os.makedirs(repo)
        cat = os.path.join(repo, 'field-catalog.json')

        p, port = start(repo); procs.append(p)
        code, body = get(port)
        check('1 no catalog -> 404 "no field catalog"', code == 404 and body == {'ok': False, 'error': 'no field catalog'}, (code, body))

        with open(cat, 'w') as f:
            json.dump(V1, f)
        code, body = get(port)
        check('2 a v1 catalog at <repo>/field-catalog.json -> 200, served unchanged',
              code == 200 and body.get('ok') is True and body.get('catalog') == V1, (code, str(body)[:200]))

        code2, body2 = get(port, '/api/field-catalog?path=/etc/passwd&id=x')
        check('5 a query string changes nothing (the route takes no input)', (code2, body2) == (code, body), (code2, str(body2)[:120]))

        bad = {
            'not JSON': '{"version": 1, "attributes": [',
            'no version 1': json.dumps({"version": 2, "attributes": []}),
            'attributes not a list': json.dumps({"version": 1, "attributes": {"a": 1}}),
            'a row without ref': json.dumps({"version": 1, "attributes": [{"notation": "x"}]}),
            'an empty ref': json.dumps({"version": 1, "attributes": [{"ref": "  "}]}),
            'a non-text label': json.dumps({"version": 1, "attributes": [{"ref": "nid:x", "label": 3}]}),
            'a non-text dataType': json.dumps({"version": 1, "attributes": [{"ref": "nid:x", "dataType": None}]}),
        }
        for what, text in bad.items():
            with open(cat, 'w') as f:
                f.write(text)
            code, body = get(port)
            check('4 refused whole (422): %s' % what, code == 422 and body.get('ok') is False and 'catalog' not in body, (code, body))

        os.remove(cat)
        other = os.path.join(tmp, 'elsewhere', 'nid-attributes.json'); os.makedirs(os.path.dirname(other))
        with open(other, 'w') as f:
            json.dump(V1, f)
        p2, port2 = start(repo, ('--field-catalog', other)); procs.append(p2)
        code, body = get(port2)
        check('3 --field-catalog PATH serves that file (no copy into the repo)',
              code == 200 and body.get('catalog') == V1 and not os.path.exists(cat), (code, str(body)[:200]))
    finally:
        for p in procs:
            p.kill()
        shutil.rmtree(tmp, ignore_errors=True)
    print('\nT-1312 field catalog: %d/%d passed' % (sum(results), len(results)))
    return 0 if all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
