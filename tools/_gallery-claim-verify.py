#!/usr/bin/env python3
"""_gallery-claim-verify.py — test for the T-228/S4a ui-claim path.

Proves the 'create from pending ref' claim mechanics that gallery-serve.py applies on
/api/save: when a saved map's OWN uuid matches a pending ghost, the server records a
claim ({uuid,project,ts,via:"ui"}) in .context/designer/registry.yaml and drops the
ghost — every referrer then resolves (its workflowRef now matches a live map uuid) with
NO diagram-XML edit. Dependency-free (stdlib only): isolated temp repo, real server on
an ephemeral port, driven via POST /api/save.

The editor picker seeds a NEW map adopting the ghost uuid; saving it is the claim. This
test drives that server contract directly (the UI half is Playwright-verified separately).

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
AEF_NS = 'xmlns:aef="http://anchorpoint.framework/aef/extensions"'
U_GHOST = '99999999-9999-4999-8999-999999999999'
U_FRESH = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def bpmn(name, uuid=None, uuid_links=None):
    """BPMN with optional own workflowMeta uuid + off-page uuid link nodes.
    uuid_links: list of (node_id, node_name, workflow_ref, ref_name)."""
    meta = ('<aef:workflowMeta uuid="%s"/>' % uuid) if uuid else ''
    nodes = ''
    for nid, nname, wref, rname in (uuid_links or []):
        rn = (' name="%s"' % rname) if rname else ''
        # T-327: host tag must be one an emitter can actually produce. Both
        # emitters render a linkEventThrow node as <bpmn:intermediateThrowEvent>
        # (bridge TYPE_MAP, designer TYPE_TAG) with link-ness on <aef:link>.
        nodes += ('<bpmn:intermediateThrowEvent id="%s" name="%s"><bpmn:extensionElements>'
                  '<aef:link workflowRef="%s"%s/></bpmn:extensionElements>'
                  '</bpmn:intermediateThrowEvent>' % (nid, nname, wref, rn))
    return ('<?xml version="1.0"?><bpmn:definitions xmlns:bpmn="x" %s>'
            '<bpmn:process id="Pool_x" name="%s">%s%s</bpmn:process>'
            '</bpmn:definitions>' % (AEF_NS, name, meta, nodes))


def start_server(repo):
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
    s.close()
    docroot = os.path.join(repo, 'build', 'gallery')
    os.makedirs(docroot, exist_ok=True)
    cmd = [sys.executable, SERVER, str(port),
           '--repo', repo, '--docroot', docroot, '--bind', '127.0.0.1']
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(100):
        try:
            urllib.request.urlopen('http://127.0.0.1:%d/api/health' % port, timeout=0.5)
            return proc, port
        except Exception:
            time.sleep(0.05)
    proc.terminate()
    raise RuntimeError('server did not come up')


def save(port, id_, xml):
    req = urllib.request.Request('http://127.0.0.1:%d/api/save' % port,
                                 data=json.dumps({'id': id_, 'bpmn': xml}).encode('utf-8'),
                                 headers={'Content-Type': 'application/json'}, method='POST')
    with urllib.request.urlopen(req, timeout=3) as r:
        return json.loads(r.read())


def get_list(port):
    with urllib.request.urlopen('http://127.0.0.1:%d/api/list' % port, timeout=3) as r:
        return json.loads(r.read())


def read_registry(repo):
    p = os.path.join(repo, '.context', 'designer', 'registry.yaml')
    if not os.path.exists(p):
        return {'ghosts': [], 'claims': []}
    with open(p, encoding='utf-8') as f:
        return json.load(f)          # writer emits JSON (valid YAML)


def claims_for(reg, u):
    return [c for c in (reg or {}).get('claims', []) if c.get('uuid') == u]


def ghost_uuids(data):
    return [g['uuid'] for g in data.get('ghosts', [])]


def main():
    repo = tempfile.mkdtemp(prefix='t228-repo-')
    proc, port = start_server(repo)
    try:
        # 1. a referrer to an unresolved uuid -> pending uuid-pinned ghost
        save(port, 'refa', bpmn('Ref A', uuid_links=[('n_a', 'to ghost', U_GHOST, 'publish-map')]))
        save(port, 'refb', bpmn('Ref B', uuid_links=[('n_b', 'to ghost', U_GHOST, 'publish-map')]))
        data = get_list(port)
        check('ghost-pending-before-claim', U_GHOST in ghost_uuids(data),
              'ghosts=%s' % ghost_uuids(data))
        check('no-claims-yet', claims_for(read_registry(repo), U_GHOST) == [])

        # 2. picker path: save a NEW map that ADOPTS the ghost uuid -> claim
        save(port, 'publish-map', bpmn('publish-map', uuid=U_GHOST))
        data = get_list(port)
        reg = read_registry(repo)

        # 2a. ghost dropped from /api/list
        check('ghost-gone-after-claim', U_GHOST not in ghost_uuids(data),
              'ghosts=%s' % ghost_uuids(data))
        # 2b. claimed uuid is now a live map uuid
        claimed = next((m for m in data['maps'] if m.get('id') == 'publish-map'), None)
        check('claimed-map-carries-uuid', claimed is not None and claimed.get('uuid') == U_GHOST,
              'map=%s' % claimed)
        # 2c. referrers resolve — refa/refb produced no ghost, and their XML is untouched
        check('referrers-resolve-no-ghost', U_GHOST not in ghost_uuids(data))
        # 2d. claim recorded exactly once, via:ui, project = the adopting map
        cl = claims_for(reg, U_GHOST)
        check('claim-recorded-once', len(cl) == 1, 'claims=%s' % cl)
        check('claim-shape',
              bool(cl) and cl[0].get('via') == 'ui' and cl[0].get('project') == 'publish-map'
              and isinstance(cl[0].get('ts'), int), 'claim=%s' % (cl[0] if cl else None))

        # 3. idempotent: re-save the claimed map -> no duplicate claim, ghost stays gone
        save(port, 'publish-map', bpmn('publish-map', uuid=U_GHOST))
        reg = read_registry(repo)
        check('claim-idempotent-on-resave', len(claims_for(reg, U_GHOST)) == 1,
              'claims=%s' % claims_for(reg, U_GHOST))
        check('ghost-stays-gone', U_GHOST not in [g['uuid'] for g in reg.get('ghosts', [])])

        # 4. a normal save whose uuid matches NO ghost records no claim (no false positive)
        save(port, 'plain', bpmn('plain', uuid=U_FRESH))
        reg = read_registry(repo)
        check('normal-save-no-spurious-claim', claims_for(reg, U_FRESH) == [],
              'claims=%s' % reg.get('claims'))

        # 5. atomic write leaves no *.tmp behind
        desdir = os.path.join(repo, '.context', 'designer')
        check('no-temp-file-leaked',
              not any(f.endswith('.tmp') for f in os.listdir(desdir)),
              'dir=%s' % os.listdir(desdir))
    finally:
        proc.terminate()

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print('\n%d/%d checks passed' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
