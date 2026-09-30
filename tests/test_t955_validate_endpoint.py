#!/usr/bin/env python3
"""T-955 (T-309 GO slice 1): POST /api/validate on tools/gallery-serve.py.

WHAT THIS GUARDS. The designer has no validation surface — `grep` for one in
src/aef-workflow-designer.html finds nothing — so ~24 XmlValidator rules run only in the
bridge suite and from the CLI and never reach the person drawing the map, which is where
the mistake is made (T-309). This route is the reach. The test drives it over real HTTP
against a live server, because an endpoint asserted by unit-calling its handler proves the
handler works and not that the route is wired.

BOTH DIRECTIONS, ALWAYS. An endpoint only ever observed returning `[]` is indistinguishable
from one that cannot find anything, so every "clean" leg is paired with a leg that makes the
same document dirty and demands the specific rule id back.

THE LEG THAT MATTERS MOST is leg 7: a copy of the server with the route stripped must answer
404. Without it this file would pass against a server that answers /api/validate by accident,
and would keep passing after someone deleted the route's dispatch line.

Exit 0 iff every check passes. Run: python3 tests/test_t955_validate_endpoint.py
"""
import json
import os
import re
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
CLEAN = os.path.join(ROOT, 'examples', 'aef-processes', 'rendered', 'task-lifecycle.bpmn')

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond)))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def free_port():
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    return port


def start_server(server_path, repo):
    port = free_port()
    docroot = os.path.join(repo, 'build', 'gallery')
    os.makedirs(docroot, exist_ok=True)
    proc = subprocess.Popen(
        [sys.executable, server_path, str(port), '--repo', repo,
         '--docroot', docroot, '--bind', '127.0.0.1'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(100):
        try:
            urllib.request.urlopen('http://127.0.0.1:%d/api/health' % port, timeout=0.5)
            return proc, port
        except Exception:
            time.sleep(0.05)
    proc.terminate()
    raise RuntimeError('server did not come up: %s' % server_path)


def post(port, path, obj):
    """-> (status, parsed_json_or_None, raw)"""
    body = json.dumps(obj).encode('utf-8')
    req = urllib.request.Request(
        'http://127.0.0.1:%d%s' % (port, path), data=body,
        headers={'Content-Type': 'application/json'}, method='POST')
    try:
        r = urllib.request.urlopen(req, timeout=30)
        raw = r.read().decode('utf-8')
        status = r.status
    except urllib.error.HTTPError as e:
        raw = e.read().decode('utf-8')
        status = e.code
    try:
        return status, json.loads(raw), raw
    except Exception:
        return status, None, raw


def rules_of(doc):
    return [f.get('rule') for f in (doc or {}).get('findings', [])]


def main():
    if not os.path.isfile(SERVER):
        print('COULD-NOT-MEASURE: %s missing' % SERVER, file=sys.stderr)
        return 3
    if not os.path.isfile(CLEAN):
        print('COULD-NOT-MEASURE: clean fixture %s missing' % CLEAN, file=sys.stderr)
        return 3

    clean_xml = open(CLEAN).read()

    # The dirty fixture is the clean one with ONE flowNodeRef removed, which is T-309's own
    # falsifiability control: "drop a flowNodeRef -> W-XML-NODE-UNASSIGNED, exit 1". Deriving
    # it from the clean document rather than hand-authoring means the two differ in exactly
    # one respect, so a rule firing on the dirty one cannot be blamed on anything else.
    m = re.search(r'[ \t]*<bpmn:flowNodeRef>[^<]+</bpmn:flowNodeRef>\n', clean_xml)
    if not m:
        print('COULD-NOT-MEASURE: no flowNodeRef in the clean fixture to remove; the '
              'corpus shape changed and this test cannot build its dirty case',
              file=sys.stderr)
        return 3
    dirty_xml = clean_xml.replace(m.group(0), '', 1)

    tmp = tempfile.mkdtemp(prefix='t955-')
    repo = os.path.join(tmp, 'repo')
    os.makedirs(repo, exist_ok=True)

    proc, port = start_server(SERVER, repo)
    try:
        # --- leg 1: a clean corpus document returns zero findings -------------
        st, doc, raw = post(port, '/api/validate', {'bpmn': clean_xml})
        check('clean document -> 200 ok with zero findings',
              st == 200 and doc and doc.get('ok') is True
              and doc.get('findings') == [] and doc.get('errors') == 0,
              'status=%s body=%s' % (st, raw[:120]))

        # --- leg 2: the SAME document, one flowNodeRef removed, must fire ------
        st, doc, raw = post(port, '/api/validate', {'bpmn': dirty_xml})
        got = rules_of(doc)
        check('one flowNodeRef removed -> E-XML-NODE-UNASSIGNED fires',
              st == 200 and any('NODE-UNASSIGNED' in (r or '') for r in got),
              'status=%s rules=%s' % (st, got[:6]))

        # --- leg 3: findings keep their identity, not prose -------------------
        first = (doc or {}).get('findings', [{}])[0] if (doc or {}).get('findings') else {}
        check('a finding carries rule + severity + message',
              all(k in first for k in ('rule', 'severity', 'message')),
              'keys=%s' % sorted(first.keys()))

        # --- leg 4: garbage is E-XML-PARSE, never an empty findings list -------
        # An empty list on garbage would read as "this document is fine", which is the
        # false-green shape this whole project keeps getting bitten by.
        st, doc, raw = post(port, '/api/validate', {'bpmn': 'this is not xml at all <<<'})
        got = rules_of(doc)
        check('non-XML -> E-XML-PARSE, not an empty pass',
              st == 200 and 'E-XML-PARSE' in got,
              'status=%s rules=%s' % (st, got))

        # --- leg 5: missing/empty bpmn is refused with 400 --------------------
        st_missing, _, _ = post(port, '/api/validate', {})
        st_empty, _, _ = post(port, '/api/validate', {'bpmn': '   '})
        check('missing or empty bpmn -> 400',
              st_missing == 400 and st_empty == 400,
              'missing=%s empty=%s' % (st_missing, st_empty))

        # --- leg 6: the route pattern is intact (unknown POST still 404) -------
        st, _, _ = post(port, '/api/nope', {'bpmn': clean_xml})
        check('an unknown POST endpoint still 404s',
              st == 404, 'status=%s' % st)
    finally:
        proc.terminate()
        proc.wait(timeout=10)

    # --- leg 7: THE TEETH. Strip the route; the endpoint must disappear -------
    # A copy of the server with the dispatch line removed must 404. Without this leg the
    # file above would pass against a server that answered by accident, and would keep
    # passing after someone deleted the route.
    stripped = os.path.join(tmp, 'gallery-serve-stripped.py')
    src = open(SERVER).read()
    needle = "if parsed.path not in ('/api/save', '/api/delete', '/api/validate'):"
    if needle not in src:
        check('teeth: route-allowlist line found for mutation', False,
              'the dispatch allowlist changed shape; re-anchor this leg')
    else:
        mutated = src.replace(needle, "if parsed.path not in ('/api/save', '/api/delete'):", 1)
        open(stripped, 'w').write(mutated)
        if mutated == src:
            check('teeth: mutation landed', False, 'replace was a no-op')
        else:
            mproc, mport = start_server(stripped, repo)
            try:
                st, _, _ = post(mport, '/api/validate', {'bpmn': clean_xml})
                check('teeth: route removed -> 404 (so leg 1 can actually fail)',
                      st == 404, 'status=%s' % st)
            finally:
                mproc.terminate()
                mproc.wait(timeout=10)

    passed = sum(1 for _, ok in results if ok)
    failed = len(results) - passed
    print()
    print('validate endpoint: %d passed, %d failed' % (passed, failed))
    if failed:
        print('validate endpoint: FAILED')
        return 1
    print('OK: /api/validate reaches the one validator, both directions, with teeth')
    return 0


if __name__ == '__main__':
    sys.exit(main())
