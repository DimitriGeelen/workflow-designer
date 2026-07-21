#!/usr/bin/env python3
"""_gallery-registry-verify.py — test for the T-227/S3b registry twin.

Proves the persistent ghost registry (.context/designer/registry.yaml) that
gallery-serve.py maintains on /api/save and /api/delete. Dependency-free (stdlib
only): builds an isolated temp repo, launches gallery-serve.py on an ephemeral
port, drives it via POST /api/save + /api/delete, and asserts on the registry
file + GET /api/list ghosts[].

Registry semantics under test (rail offset 134, task ≡ null on this twin):
  - uuid-pinned ghost  (<aef:link workflowRef=<uuid>>, uuid not a live map) — keyed by uuid
  - name-only ghost    (legacy <aef:link targetWorkflow=<slug>>, slug not live) — store-minted
                        uuid4, keyed/deduped by display name
  - ONE drop rule: a ghost drops when referenced_by becomes empty (both kinds); a dropped
    uuid-pinned ghost re-materializes from XML on a later save (registry = debt cache, not
    identity)
  - a legacy ref whose target IS live is skipped (never recorded)

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
U_TARGET = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def bpmn(name, uuid=None, uuid_links=None, legacy_links=None):
    """BPMN with optional own uuid + off-page link nodes. uuid_links: list of
    (node_id, node_name, workflow_ref, ref_name). legacy_links: list of
    (node_id, node_name, target_slug). <aef:link> nests under extensionElements."""
    meta = ('<aef:workflowMeta uuid="%s"/>' % uuid) if uuid else ''
    nodes = ''
    for nid, nname, wref, rname in (uuid_links or []):
        rn = (' name="%s"' % rname) if rname else ''
        nodes += ('<bpmn:linkEventThrow id="%s" name="%s"><bpmn:extensionElements>'
                  '<aef:link workflowRef="%s"%s/></bpmn:extensionElements>'
                  '</bpmn:linkEventThrow>' % (nid, nname, wref, rn))
    for nid, nname, slug in (legacy_links or []):
        nodes += ('<bpmn:linkEventThrow id="%s" name="%s"><bpmn:extensionElements>'
                  '<aef:link targetWorkflow="%s"/></bpmn:extensionElements>'
                  '</bpmn:linkEventThrow>' % (nid, nname, slug))
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


def post(port, route, obj):
    req = urllib.request.Request('http://127.0.0.1:%d%s' % (port, route),
                                 data=json.dumps(obj).encode('utf-8'),
                                 headers={'Content-Type': 'application/json'}, method='POST')
    with urllib.request.urlopen(req, timeout=3) as r:
        return json.loads(r.read())


def save(port, id_, xml):
    return post(port, '/api/save', {'id': id_, 'bpmn': xml})


def delete(port, id_):
    return post(port, '/api/delete', {'id': id_, 'scope': 'workflow'})


def get_list(port):
    with urllib.request.urlopen('http://127.0.0.1:%d/api/list' % port, timeout=3) as r:
        return json.loads(r.read())


def read_registry(repo):
    p = os.path.join(repo, '.context', 'designer', 'registry.yaml')
    if not os.path.exists(p):
        return None
    with open(p, encoding='utf-8') as f:
        return json.load(f)          # our writer emits JSON (valid YAML)


def ghost_by_uuid(reg, u):
    return next((g for g in (reg or {}).get('ghosts', []) if g['uuid'] == u), None)


def ghost_by_name(reg, n):
    return next((g for g in (reg or {}).get('ghosts', []) if g.get('name') == n), None)


def main():
    repo = tempfile.mkdtemp(prefix='t227-repo-')
    proc, port = start_server(repo)
    try:
        # 1. save a map with an unresolved workflowRef -> uuid-pinned ghost persisted
        save(port, 'refa', bpmn('Ref A', uuid_links=[('n_a', 'to ghost', U_GHOST, 'publish-map')]))
        reg = read_registry(repo)
        g = ghost_by_uuid(reg, U_GHOST)
        check('registry-created', reg is not None and isinstance(reg.get('ghosts'), list))
        check('uuid-pinned-ghost-persisted', g is not None and g.get('kind') == 'uuid-pinned',
              'ghost=%s' % g)
        check('ghost-first-seen-int', bool(g) and isinstance(g.get('first_seen'), int),
              'first_seen=%s' % (g or {}).get('first_seen'))
        check('ghost-task-null', bool(g) and g.get('task') is None)
        check('ghost-referenced-by-refa',
              bool(g) and g['referenced_by'] == [{'id': 'refa', 'node': 'n_a', 'nodeName': 'to ghost'}],
              'refs=%s' % (g or {}).get('referenced_by'))

        # 2. second referrer -> both maps
        save(port, 'refb', bpmn('Ref B', uuid_links=[('n_b', 'to ghost', U_GHOST, 'publish-map')]))
        g = ghost_by_uuid(read_registry(repo), U_GHOST)
        check('two-referrers', sorted(r['id'] for r in g['referenced_by']) == ['refa', 'refb'],
              'refs=%s' % [r['id'] for r in g['referenced_by']])

        # 3. re-save refa (same ref) -> no duplicate referrer
        save(port, 'refa', bpmn('Ref A', uuid_links=[('n_a', 'to ghost', U_GHOST, 'publish-map')]))
        g = ghost_by_uuid(read_registry(repo), U_GHOST)
        check('no-duplicate-referrer',
              [r['id'] for r in g['referenced_by']].count('refa') == 1
              and len(g['referenced_by']) == 2, 'refs=%s' % g['referenced_by'])

        # 4. delete one referrer -> ghost stays
        delete(port, 'refb')
        g = ghost_by_uuid(read_registry(repo), U_GHOST)
        check('delete-one-referrer-keeps-ghost',
              g is not None and [r['id'] for r in g['referenced_by']] == ['refa'],
              'refs=%s' % (g or {}).get('referenced_by'))

        # 5. delete last referrer -> ghost DROPS (no uuid-pinned exemption)
        delete(port, 'refa')
        check('delete-last-referrer-drops-ghost', ghost_by_uuid(read_registry(repo), U_GHOST) is None,
              'ghosts=%s' % [x['uuid'] for x in read_registry(repo).get('ghosts', [])])

        # 5b. re-save a map carrying the ref -> ghost re-materializes (debt cache, not identity)
        save(port, 'refc', bpmn('Ref C', uuid_links=[('n_c', 'to ghost', U_GHOST, 'publish-map')]))
        g = ghost_by_uuid(read_registry(repo), U_GHOST)
        check('re-materializes-from-xml', g is not None and isinstance(g.get('first_seen'), int),
              'ghost=%s' % g)

        # 6. resolve: a live map whose uuid == a referenced uuid -> that ref makes no ghost
        save(port, 'target', bpmn('Target', uuid=U_TARGET))
        save(port, 'refd', bpmn('Ref D', uuid_links=[('n_d', 'to target', U_TARGET, 'target')]))
        check('resolved-ref-no-ghost', ghost_by_uuid(read_registry(repo), U_TARGET) is None,
              'ghosts=%s' % [x['uuid'] for x in read_registry(repo).get('ghosts', [])])

        # 7. name-only: legacy targetWorkflow to an absent slug -> store-minted name-only ghost
        save(port, 'refe', bpmn('Ref E', legacy_links=[('n_e', 'to missing', 'absent-slug')]))
        g = ghost_by_name(read_registry(repo), 'absent-slug')
        check('name-only-ghost-minted',
              g is not None and g.get('kind') == 'name-only'
              and len(g['uuid']) == 36 and g['uuid'] != 'absent-slug', 'ghost=%s' % g)

        # 7b. dedupe-by-name: a second referrer of the same missing slug shares one ghost
        save(port, 'reff', bpmn('Ref F', legacy_links=[('n_f', 'to missing', 'absent-slug')]))
        reg = read_registry(repo)
        name_ghosts = [x for x in reg['ghosts'] if x.get('name') == 'absent-slug']
        check('name-only-dedupe-by-name',
              len(name_ghosts) == 1
              and sorted(r['id'] for r in name_ghosts[0]['referenced_by']) == ['refe', 'reff'],
              'count=%d refs=%s' % (len(name_ghosts),
                                    name_ghosts and name_ghosts[0]['referenced_by']))

        # 7c. skip-when-live: legacy ref to a LIVE slug records no ghost
        save(port, 'refg', bpmn('Ref G', legacy_links=[('n_g', 'to target', 'target')]))
        reg = read_registry(repo)
        check('legacy-ref-to-live-slug-skipped',
              ghost_by_name(reg, 'target') is None,
              'ghost names=%s' % [x.get('name') for x in reg['ghosts']])

        # 8. atomic write leaves no *.tmp behind
        desdir = os.path.join(repo, '.context', 'designer')
        check('no-temp-file-leaked',
              not any(f.endswith('.tmp') for f in os.listdir(desdir)),
              'dir=%s' % os.listdir(desdir))

        # merged /api/list reflects registry ghosts (name-only visible, task/first_seen present)
        data = get_list(port)
        wire = {g['uuid']: g for g in data.get('ghosts', [])}
        na = ghost_by_name(read_registry(repo), 'absent-slug')
        check('api-list-ghosts-includes-name-only',
              na is not None and na['uuid'] in wire
              and set(wire[na['uuid']]) == {'uuid', 'name', 'referenced_by', 'task', 'first_seen'},
              'wire keys=%s' % (na and na['uuid'] in wire and sorted(wire[na['uuid']])))

        # 9. malformed registry -> /api/list still 200, treated as empty (no crash)
        with open(os.path.join(desdir, 'registry.yaml'), 'w') as f:
            f.write('{ this is not: valid json ][')
        data = get_list(port)
        check('malformed-registry-no-crash', isinstance(data.get('maps'), list)
              and isinstance(data.get('ghosts'), list),
              'maps=%s ghosts=%s' % (type(data.get('maps')).__name__, type(data.get('ghosts')).__name__))
    finally:
        proc.terminate()

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print('\n%d/%d checks passed' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
