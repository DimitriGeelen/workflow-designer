#!/usr/bin/env python3
"""T-973: POST /api/save returns the validator's verdict, advisorily.

WHAT THIS GUARDS. Evergreen's 26 maps passed 130 saves without a word: their generator
posted bytes to /api/save and the server stored them unexamined. /api/validate existed, but
a client has to know to call it. The save response is the one channel every client already
reads, so that is where the validator has to speak.

FOUR LEGS, OVER REAL HTTP against a live server with an isolated --repo (a test save must
never land in this repo's .editor-versions):

  1. a complete map saves and reports validation {ok:true} with ZERO findings;
  2. the SAME map with its <aef:workflowMeta> removed saves AND reports
     W-XML-NO-WORKFLOWMETA. Derived from leg 1's document so they differ in one respect;
  3. the legacy fields (ok, v, ts, corpus) are still there, so no current client breaks;
  4. THE TEETH: a copy of the server with no validator beside it. The save must STILL land
     on disk and return ok:true (advisory, never blocking, T-956), and validation must say
     {ok:false, reason} with NO `findings` key. A broken validator that reads as "no
     findings" is the false green this project keeps being bitten by.

Exit 0 iff every check passes. Run: python3 tests/test_t973_save_findings.py
"""
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


def save(port, id_, bpmn):
    """-> (status, parsed_json_or_None, raw)"""
    body = json.dumps({'id': id_, 'bpmn': bpmn}).encode('utf-8')
    req = urllib.request.Request(
        'http://127.0.0.1:%d/api/save' % port, data=body,
        headers={'Content-Type': 'application/json'}, method='POST')
    try:
        r = urllib.request.urlopen(req, timeout=30)
        raw, status = r.read().decode('utf-8'), r.status
    except urllib.error.HTTPError as e:
        raw, status = e.read().decode('utf-8'), e.code
    try:
        return status, json.loads(raw), raw
    except Exception:
        return status, None, raw


def main():
    for path in (SERVER, CLEAN):
        if not os.path.isfile(path):
            print('COULD-NOT-MEASURE: %s missing' % path, file=sys.stderr)
            return 3
    clean_xml = open(CLEAN).read()
    m = re.search(r'[ \t]*<aef:workflowMeta\b[^>]*/>\n', clean_xml)
    if not m:
        print('COULD-NOT-MEASURE: the clean fixture carries no self-closing '
              '<aef:workflowMeta/>, so the dirty case cannot be derived from it',
              file=sys.stderr)
        return 3
    dirty_xml = clean_xml.replace(m.group(0), '', 1)

    tmp = tempfile.mkdtemp(prefix='t973-')
    repo = os.path.join(tmp, 'repo')
    os.makedirs(repo)
    try:
        proc, port = start_server(SERVER, repo)
        try:
            # --- leg 1: complete map -> validation ok, zero findings ---------------
            st, doc, raw = save(port, 't973-clean', clean_xml)
            val = (doc or {}).get('validation') or {}
            check('complete map saves with validation ok:true and zero findings',
                  st == 200 and doc and doc.get('ok') is True and val.get('ok') is True
                  and val.get('findings') == [] and val.get('errors') == 0
                  and val.get('warnings') == 0,
                  'status=%s validation=%s' % (st, json.dumps(val)[:200]))

            # --- leg 3: legacy fields unchanged -------------------------------------
            check('legacy save fields ok/v/ts/corpus still present',
                  doc and all(k in doc for k in ('ok', 'v', 'ts', 'corpus')),
                  'keys=%s' % sorted((doc or {}).keys()))

            # --- leg 2: same map, workflowMeta removed -> the rule speaks ------------
            st, doc, raw = save(port, 't973-dirty', dirty_xml)
            val = (doc or {}).get('validation') or {}
            rules = [f.get('rule') for f in val.get('findings', [])]
            check('map without workflowMeta saves AND reports W-XML-NO-WORKFLOWMETA',
                  st == 200 and doc and doc.get('ok') is True
                  and 'W-XML-NO-WORKFLOWMETA' in rules and val.get('warnings', 0) >= 1,
                  'status=%s rules=%s' % (st, rules))
            check('the dirty save was written anyway (advisory, not blocking)',
                  os.path.isfile(os.path.join(repo, '.editor-versions', 't973-dirty', 'v1.bpmn')))
        finally:
            proc.terminate()
            proc.wait(timeout=5)

        # --- leg 4: THE TEETH. No validator beside the server ------------------------
        lone_dir = os.path.join(tmp, 'lone')
        os.makedirs(lone_dir)
        lone = os.path.join(lone_dir, 'gallery-serve.py')
        shutil.copy(SERVER, lone)
        check('teeth premise: no validate-workflow.py beside the copied server',
              not os.path.exists(os.path.join(lone_dir, 'validate-workflow.py')))
        lproc, lport = start_server(lone, repo)
        try:
            st, doc, raw = save(lport, 't973-noval', dirty_xml)
            val = (doc or {}).get('validation') or {}
            check('validator unloadable -> the save STILL succeeds',
                  st == 200 and doc and doc.get('ok') is True and doc.get('v') == 1
                  and os.path.isfile(os.path.join(repo, '.editor-versions', 't973-noval',
                                                  'v1.bpmn')),
                  'status=%s body=%s' % (st, raw[:160]))
            check('validator unloadable -> validation {ok:false, reason}, NO findings key',
                  val.get('ok') is False and bool(val.get('reason'))
                  and 'findings' not in val,
                  'validation=%s' % json.dumps(val)[:200])
        finally:
            lproc.terminate()
            lproc.wait(timeout=5)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    failed = [n for n, ok in results if not ok]
    print('\nT-973 save findings: %d/%d passed' % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
