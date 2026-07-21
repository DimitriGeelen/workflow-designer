#!/usr/bin/env python3
"""gallery-serve.py — write-capable gallery/designer server (T-129 / B2).

Serves the assembled gallery (designer.html + rendered/*.bpmn) exactly like the
static `python -m http.server` does, AND adds a small `/api/*` surface so the
editor can save the current document durably into the repo with per-map
versioning.

Design (T-128 GO, refined at B2 build):
  - Store format is BPMN (the editor's native output). No bpmn->yaml conversion,
    no re-layout — the operator's geometry is written verbatim. `workflow.yaml`
    (the human-authored semantic source) is NOT touched.
  - A Save writes:
      .editor-versions/<id>/vN.bpmn               (immutable version snapshot — always)
      .editor-versions/<id>/vN.png                (thumbnail, if posted)
      .editor-versions/<id>/index.json            (version list — always)
      build/gallery/rendered/<id>.bpmn            (served copy, immediately loadable — always)
      examples/aef-processes/rendered/<id>.bpmn   (canonical, committed — GATED, see below)
  - Corpus gating (T-138): the canonical committed file is written only when the
    id already exists in the corpus (an edit) OR the save is explicitly promoted
    (`promote:true` in payload, or server started with --allow-new-corpus). A new
    id is treated as scratch: it is versioned and served but NOT published to the
    committed corpus, so ad-hoc/test saves cannot pollute it.
  - localhost-bound; `id` is validated against ^[a-z0-9][a-z0-9_-]*$ (no traversal).

API:
  GET  /api/health                 -> {ok:true, versions:".editor-versions"}
  GET  /api/list                   -> {maps:[{id,title,sources[],latest,openTarget}...]}
  GET  /api/versions?id=<id>       -> index.json  ([] if none)
  GET  /api/version?id=<id>&v=<n>  -> that version's BPMN (text/xml)
  GET  /api/thumb?id=<id>&v=<n>    -> that version's PNG
  POST /api/save  {id, bpmn, png?, note?, promote?} -> {ok:true, v, ts, corpus:bool}

Usage: gallery-serve.py [PORT] [--docroot DIR] [--repo DIR] [--bind ADDR] [--allow-new-corpus]
Defaults: PORT=8834, docroot=<repo>/build/gallery, repo=<script>/.., bind=0.0.0.0
"""
import base64
import json
import os
import re
import shutil
import sys
import tempfile
import threading
import time
import uuid as _uuidlib
import xml.etree.ElementTree as ET
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

ID_RE = re.compile(r'^[a-z0-9][a-z0-9_-]*$')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(SCRIPT_DIR, '..'))
DOCROOT = os.path.join(REPO, 'build', 'gallery')
BIND = '0.0.0.0'
PORT = 8834
# T-138: canonical committed-corpus writes are existence-or-promotion gated so
# scratch/test saves cannot pollute examples/aef-processes/rendered/. This flag
# restores the legacy always-write behaviour (any valid id publishes to corpus).
ALLOW_NEW_CORPUS = False


def _args(argv):
    global DOCROOT, REPO, BIND, PORT, ALLOW_NEW_CORPUS
    it = iter(argv)
    for a in it:
        if a == '--docroot':
            DOCROOT = os.path.abspath(next(it))
        elif a == '--repo':
            REPO = os.path.abspath(next(it))
        elif a == '--bind':
            BIND = next(it)
        elif a == '--allow-new-corpus':
            ALLOW_NEW_CORPUS = True
        elif a.isdigit():
            PORT = int(a)


def versions_dir(id_):
    return os.path.join(REPO, '.editor-versions', id_)


def read_index(id_):
    p = os.path.join(versions_dir(id_), 'index.json')
    if os.path.exists(p):
        try:
            with open(p, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            return []
    return []


def write_index(id_, index):
    d = versions_dir(id_)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, 'index.json'), 'w', encoding='utf-8') as f:
        json.dump(index, f, indent=2)


# ---- delete/archive (T-166) — deletion is recoverable: sources move to _trash ----
def trash_dir(id_, ts):
    """Per-delete archive folder: .editor-versions/_trash/<id>-<ts>/. The '_trash'
    prefix starts with '_' so ID_RE/build_map_list never re-enumerate archived maps."""
    return os.path.join(REPO, '.editor-versions', '_trash', '%s-%d' % (id_, ts))


def _within_repo(path):
    """True iff path resolves inside REPO (traversal guard, PL-020). Belt-and-braces
    on top of the ID_RE format check — a valid id still shouldn't escape the tree."""
    rp = os.path.realpath(path)
    return rp == REPO or rp.startswith(REPO + os.sep)


def archive_move(src, dst):
    """Move src → dst if src exists and is inside REPO; create parents. Returns the
    REPO-relative source path if it was archived, else None. Never clobbers: an
    existing dst is suffixed with -1, -2, ..."""
    if not os.path.exists(src) or not _within_repo(src):
        return None
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    final = dst
    n = 1
    while os.path.exists(final):
        final = '%s-%d' % (dst, n)
        n += 1
    shutil.move(src, final)
    return os.path.relpath(src, REPO)


# ---- /api/list (T-143, T-142 GO) — read-only corpus + saved-map enumeration ----
_PROCESS_NAME_RE = re.compile(r'<bpmn:process\b[^>]*\bname="([^"]*)"')


def _title_from_bpmn(path):
    """Best-effort title from the BPMN <bpmn:process name>; None on any failure."""
    try:
        with open(path, encoding='utf-8') as f:
            head = f.read(4000)
    except Exception:
        return None
    m = _PROCESS_NAME_RE.search(head)
    return m.group(1) if m else None


def _latest_version(id_):
    """Latest saved version for a map, or None if it has no saved versions."""
    idx = read_index(id_)
    if not idx:
        return None
    top = max(idx, key=lambda e: e.get('v', 0))
    return {'v': top.get('v'), 'ts': top.get('ts'), 'count': len(idx)}


# ---- S3a (T-226) — additive uuid + read-only ghosts[] derivation ----
# The off-page connector seam (T-218 GO): a map carries an immutable uuid in
# <aef:workflowMeta uuid=…> (minted by the editor at draw time, S1/T-224), and
# off-page connectors pin a target by <aef:link workflowRef="<uuid>"/>. A ref
# whose uuid matches no live map uuid is a GHOST (unresolved reference). S3a
# derives both read-only from the authoritative BPMN of each listed map; no file
# is written. The stateful registry twin + drop rules are S3b.
_WORKFLOWMETA_UUID_RE = re.compile(r'<aef:workflowMeta\b[^>]*\buuid="([^"]*)"')


def _rendered_path(id_):
    return os.path.join(REPO, 'examples', 'aef-processes', 'rendered', '%s.bpmn' % id_)


def _authoritative_bpmn_path(id_, latest):
    """Path to the BPMN a map's openTarget would load: the latest saved version
    when one exists, else the rendered corpus file. None if neither is present."""
    if latest:
        p = os.path.join(versions_dir(id_), 'v%s.bpmn' % latest['v'])
        if os.path.exists(p):
            return p
    p = _rendered_path(id_)
    return p if os.path.exists(p) else None


def _read_text(path):
    if not path:
        return None
    try:
        with open(path, encoding='utf-8') as f:
            return f.read()
    except Exception:
        return None


def _uuid_from_text(text):
    """The map's own uuid from <aef:workflowMeta uuid=…>; None when absent
    (legacy/rendered maps not yet saved through the uuid-minting editor)."""
    if not text:
        return None
    m = _WORKFLOWMETA_UUID_RE.search(text)
    return m.group(1) if m else None


def _local(tag):
    return tag.rsplit('}', 1)[-1] if '}' in tag else tag


def _link_refs_from_text(text):
    """Every uuid-pinned off-page ref in a map: [{workflowRef, name, node, nodeName}].
    node/nodeName come from the ENCLOSING element — the <aef:link> child is the key,
    the host tag is host-agnostic (rail seam-fact, offset 130). Legacy refs
    (targetWorkflow, no workflowRef) are ignored: only uuid-pinned refs resolve/ghost."""
    if not text:
        return []
    try:
        root = ET.fromstring(text)
    except Exception:
        return []
    parents = {child: parent for parent in root.iter() for child in parent}
    refs = []
    for el in root.iter():
        if _local(el.tag) != 'link':
            continue
        wref = el.get('workflowRef')
        if not wref:
            continue
        # Climb to the nearest ancestor carrying an id — the flow node. The editor
        # nests <aef:link> under <bpmn:extensionElements>, so the direct parent has
        # no id/name; the host tag itself is host-agnostic (rail seam-fact).
        host = parents.get(el)
        while host is not None and host.get('id') is None:
            host = parents.get(host)
        refs.append({
            'workflowRef': wref,
            'name': el.get('name'),
            'node': host.get('id') if host is not None else None,
            'nodeName': host.get('name') if host is not None else None,
        })
    return refs


# ---- S3b (T-227) — persistent registry twin (.context/designer/registry.yaml) ----
# The registry is a DEBT record, not an identity record (rail offset 134): a ghost's
# uuid identity lives in the diagram XML, so a ghost dropped when its last referrer
# goes away re-materializes from the XML on a later save. `task` is ALWAYS null on this
# twin — AEF's substrate is the sole doc-task minter. Two ghost kinds:
#   uuid-pinned  — from <aef:link workflowRef=<uuid>>; keyed/deduped by uuid.
#   name-only    — from a legacy <aef:link targetWorkflow=<slug>> whose target is not a
#                  live map; store-mints a uuid4 (registry-side only, XML never rewritten),
#                  keyed/deduped by display name.
# ONE drop rule, on every sync (save + delete): drop a ghost when referenced_by is empty
# — both kinds alike (no uuid-pinned exemption). File is written as JSON (a strict subset
# of YAML 1.2) so the server stays stdlib-only yet the .yaml parses under any yaml.safe_load.
_REG_LOCK = threading.Lock()


def registry_path():
    """Resolved at call time — REPO is reassigned by --repo AFTER import, so a module
    constant would freeze the wrong path (and write into the source tree during tests)."""
    return os.path.join(REPO, '.context', 'designer', 'registry.yaml')


def read_registry():
    """Registry as {ghosts:[], claims:[]}. Missing/malformed → empty; never raises
    (a corrupt registry must never break /api/list or /api/save)."""
    try:
        with open(registry_path(), encoding='utf-8') as f:
            data = json.load(f)
        return {'ghosts': data.get('ghosts') or [], 'claims': data.get('claims') or []}
    except Exception:
        return {'ghosts': [], 'claims': []}


def write_registry(reg):
    """Atomic write: temp file in the same dir + os.replace (atomic on POSIX)."""
    path = registry_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), suffix='.tmp')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as f:
            json.dump({'ghosts': reg.get('ghosts', []), 'claims': reg.get('claims', [])},
                      f, indent=2)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def _mint_uuid4():
    return str(_uuidlib.uuid4())


def _legacy_refs_from_text(text):
    """Legacy off-page refs: <aef:link targetWorkflow="slug"> with NO workflowRef.
    Returns [{slug, node, nodeName}] via the same nearest-id ancestor climb as S3a."""
    if not text:
        return []
    try:
        root = ET.fromstring(text)
    except Exception:
        return []
    parents = {child: parent for parent in root.iter() for child in parent}
    refs = []
    for el in root.iter():
        if _local(el.tag) != 'link' or el.get('workflowRef'):
            continue
        slug = el.get('targetWorkflow')
        if not slug:
            continue
        host = parents.get(el)
        while host is not None and host.get('id') is None:
            host = parents.get(host)
        refs.append({'slug': slug,
                     'node': host.get('id') if host is not None else None,
                     'nodeName': host.get('name') if host is not None else None})
    return refs


def _append_referrer(ghost, map_id, node, node_name):
    """Add {id,node,nodeName} to a ghost's referenced_by, deduped by (id, node)."""
    for e in ghost['referenced_by']:
        if e.get('id') == map_id and e.get('node') == node:
            return
    ghost['referenced_by'].append({'id': map_id, 'node': node, 'nodeName': node_name})


def _drop_empty(ghosts):
    """The single drop rule (rail offset 134): drop any ghost with empty referenced_by,
    uuid-pinned and name-only alike. task is always null here so no KEEP branch applies."""
    return [g for g in ghosts if g.get('referenced_by')]


def sync_registry_after_save(map_id, bpmn_text):
    """Rescan a just-saved map's off-page refs and reconcile the registry (S3b).
    uuid-pinned refs → upsert by uuid; legacy refs whose target is not live → upsert a
    name-only ghost by display name (store-minted uuid4). This map's prior referrers are
    cleared first (the save is the fresh truth), then the single drop rule is applied."""
    maps = build_map_list()[0]
    live_uuids = {m['uuid'] for m in maps if m.get('uuid')}
    live_slugs = {m['id'] for m in maps}
    uuid_refs = _link_refs_from_text(bpmn_text)
    legacy_refs = _legacy_refs_from_text(bpmn_text)
    now = int(time.time())
    with _REG_LOCK:
        reg = read_registry()
        ghosts = reg['ghosts']
        for g in ghosts:                       # clear this map's stale contributions
            g['referenced_by'] = [r for r in g.get('referenced_by', []) if r.get('id') != map_id]
        by_uuid = {g['uuid']: g for g in ghosts if g.get('kind') == 'uuid-pinned'}
        by_name = {g.get('name'): g for g in ghosts if g.get('kind') == 'name-only'}
        for ref in uuid_refs:                  # uuid-pinned
            wref = ref['workflowRef']
            if wref in live_uuids:
                continue                       # resolved → contributes no ghost
            g = by_uuid.get(wref)
            if g is None:
                g = {'uuid': wref, 'name': ref.get('name'), 'kind': 'uuid-pinned',
                     'referenced_by': [], 'task': None, 'first_seen': now}
                ghosts.append(g)
                by_uuid[wref] = g
            elif not g.get('name') and ref.get('name'):
                g['name'] = ref['name']
            _append_referrer(g, map_id, ref['node'], ref['nodeName'])
        for ref in legacy_refs:                # name-only (legacy slug)
            slug = ref['slug']
            if slug in live_slugs:
                continue                       # target live → skip recording (offset 134)
            g = by_name.get(slug)
            if g is None:
                g = {'uuid': _mint_uuid4(), 'name': slug, 'kind': 'name-only',
                     'referenced_by': [], 'task': None, 'first_seen': now}
                ghosts.append(g)
                by_name[slug] = g
            _append_referrer(g, map_id, ref['node'], ref['nodeName'])
        reg['ghosts'] = _drop_empty(ghosts)
        write_registry(reg)


def sync_registry_after_delete(map_id):
    """Strip a deleted map from every ghost's referenced_by, then apply the drop rule."""
    with _REG_LOCK:
        reg = read_registry()
        for g in reg['ghosts']:
            g['referenced_by'] = [r for r in g.get('referenced_by', []) if r.get('id') != map_id]
        reg['ghosts'] = _drop_empty(reg['ghosts'])
        write_registry(reg)


def claim_ghost_after_save(map_id, bpmn_text, via='ui'):
    """S4a claim: if the just-saved map's OWN uuid matches a pending ghost, record the
    claim (audit) and drop that ghost. The uuid is now a live map identity, so every
    referrer resolves by S3 rescan with ZERO diagram edit. Fires only through the
    editor's 'create from pending ref' picker, which seeds a new map adopting the ghost
    uuid (a normal new map gets a fresh mint — T-229 — so it can't collide).

    Idempotent: the claim fires only while the ghost is still present in
    registry.ghosts; a re-save of an already-claimed map finds no matching ghost and is
    a no-op (no duplicate claim entry). Returns the claimed uuid, or None."""
    map_uuid = _uuid_from_text(bpmn_text)
    if not map_uuid:
        return None
    with _REG_LOCK:
        reg = read_registry()
        idx = next((i for i, g in enumerate(reg['ghosts']) if g.get('uuid') == map_uuid), None)
        if idx is None:
            return None                    # not a pending ghost → nothing to claim
        reg['ghosts'].pop(idx)
        reg.setdefault('claims', []).append(
            {'uuid': map_uuid, 'project': map_id, 'ts': int(time.time()), 'via': via})
        write_registry(reg)
        return map_uuid


def merged_ghosts():
    """/api/list ghosts[] = S3a live derivation (authoritative for current uuid-pinned
    referenced_by) UNION the persisted registry (authoritative for first_seen + the
    name-only ghosts derivation can't see). Read-only — never writes the registry.
    Emits the S3a wire shape {uuid,name,referenced_by,task,first_seen} (no `kind`)."""
    _maps, derived = build_map_list()
    live_uuids = {m['uuid'] for m in _maps if m.get('uuid')}
    reg = read_registry()
    reg_by_uuid = {g['uuid']: g for g in reg['ghosts']}
    out = {}
    for g in derived:                          # uuid-pinned, live referenced_by
        entry = {'uuid': g['uuid'], 'name': g['name'], 'referenced_by': g['referenced_by'],
                 'task': None, 'first_seen': None}
        rg = reg_by_uuid.get(g['uuid'])
        if rg:
            entry['first_seen'] = rg.get('first_seen')
        out[g['uuid']] = entry
    for g in reg['ghosts']:                     # registry-only (name-only, mainly)
        # A uuid that is now a live map is resolved by definition (matches S3a derivation);
        # never surface a stale registry ghost for it (belt-and-suspenders to claim-drop).
        if g['uuid'] in out or g['uuid'] in live_uuids or not g.get('referenced_by'):
            continue
        out[g['uuid']] = {'uuid': g['uuid'], 'name': g.get('name'),
                          'referenced_by': g.get('referenced_by', []),
                          'task': g.get('task'), 'first_seen': g.get('first_seen')}
    return sorted(out.values(), key=lambda g: g['uuid'])


def _derive_ghosts(records):
    """Read-only ghosts[] from the listed maps' uuid-pinned refs (S3a).

    A ref resolves when its workflowRef matches some live map's uuid → no ghost.
    Otherwise it is a ghost, grouped by uuid: {uuid, name, referenced_by:[{id,node,
    nodeName}], task, first_seen}. task/first_seen are null here — they are owned by
    the persistent registry twin (S3b); this derivation never writes state."""
    live_uuids = {r['uuid'] for r in records if r.get('uuid')}
    ghosts = {}
    for r in records:
        for ref in r['refs']:
            wref = ref['workflowRef']
            if wref in live_uuids:
                continue
            g = ghosts.get(wref)
            if g is None:
                g = {'uuid': wref, 'name': ref.get('name'), 'referenced_by': [],
                     'task': None, 'first_seen': None}
                ghosts[wref] = g
            elif g['name'] is None and ref.get('name'):
                g['name'] = ref['name']
            g['referenced_by'].append({'id': r['id'], 'node': ref['node'],
                                       'nodeName': ref['nodeName']})
    return sorted(ghosts.values(), key=lambda g: g['uuid'])


def build_map_list():
    """Merge the rendered corpus with saved maps into one read-only listing, and
    derive the off-page ghost[] set (S3a/T-226).

    Returns (maps, ghosts). Per map: {id, title, sources:[rendered|saved],
    latest:{v,ts,count}|null, uuid:str|null, openTarget:{kind:'version',v}|
    {kind:'rendered'}}. `uuid` is additive (read from <aef:workflowMeta uuid=…>,
    null when absent). `ghosts` is a SEPARATE top-level array (never status-flagged
    inside maps[]) so a 0.3.0 picker never tries to open a versionless ghost.
    openTarget is the latest saved version when one exists, else the rendered
    baseline. Read-only; every id is validated with ID_RE so nothing outside the
    corpus/version store is enumerated."""
    rendered_dir = os.path.join(REPO, 'examples', 'aef-processes', 'rendered')
    maps = {}
    if os.path.isdir(rendered_dir):
        for name in sorted(os.listdir(rendered_dir)):
            if not name.endswith('.bpmn'):
                continue
            id_ = name[:-5]
            if not ID_RE.match(id_):
                continue
            maps[id_] = {
                'id': id_,
                'title': _title_from_bpmn(os.path.join(rendered_dir, name)) or id_,
                'sources': ['rendered'],
                'latest': _latest_version(id_),
            }
    store = os.path.join(REPO, '.editor-versions')
    if os.path.isdir(store):
        for id_ in sorted(os.listdir(store)):
            if not ID_RE.match(id_) or not os.path.isdir(versions_dir(id_)):
                continue
            lv = _latest_version(id_)
            if not lv:
                continue
            if id_ in maps:
                maps[id_]['sources'].append('saved')
            else:
                maps[id_] = {'id': id_, 'title': id_, 'sources': ['saved'], 'latest': lv}
    out = []
    records = []
    for m in maps.values():
        m['openTarget'] = ({'kind': 'version', 'v': m['latest']['v']}
                           if m['latest'] else {'kind': 'rendered'})
        text = _read_text(_authoritative_bpmn_path(m['id'], m['latest']))
        m['uuid'] = _uuid_from_text(text)
        records.append({'id': m['id'], 'uuid': m['uuid'], 'refs': _link_refs_from_text(text)})
        out.append(m)
    out.sort(key=lambda m: m['id'])
    return out, _derive_ghosts(records)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=DOCROOT, **k)

    def log_message(self, fmt, *args):
        sys.stderr.write("[gallery-serve] " + (fmt % args) + "\n")

    def end_headers(self):
        # Dev gallery — never let a browser serve a stale designer.html (T-135). The editor
        # is a single self-contained file that changes on every redeploy; heuristic caching
        # (SimpleHTTPRequestHandler sends no Cache-Control) made operators see old behaviour
        # until they used incognito. no-store on every response (static + API) fixes it.
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    # ---- helpers ----
    def _json(self, code, obj):
        body = json.dumps(obj).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _bytes(self, code, body, ctype):
        self.send_response(code)
        self.send_header('Content-Type', ctype)
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _valid_id(self, id_):
        return bool(id_) and bool(ID_RE.match(id_))

    # ---- GET ----
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith('/api/'):
            return self._api_get(parsed)
        return super().do_GET()

    def _api_get(self, parsed):
        q = parse_qs(parsed.query)
        route = parsed.path
        if route == '/api/health':
            return self._json(200, {'ok': True, 'store': '.editor-versions'})
        if route == '/api/list':
            # T-143: read-only corpus + saved-map enumeration (no id required).
            # T-226/S3a: additive maps[].uuid + separate top-level ghosts[].
            # T-227/S3b: ghosts[] is the merged live-derivation ∪ persisted-registry view.
            maps, _derived = build_map_list()
            return self._json(200, {'maps': maps, 'ghosts': merged_ghosts()})
        id_ = (q.get('id') or [''])[0]
        if route in ('/api/versions', '/api/version', '/api/thumb') and not self._valid_id(id_):
            return self._json(400, {'ok': False, 'error': 'invalid id'})
        if route == '/api/versions':
            return self._json(200, read_index(id_))
        if route == '/api/version':
            v = (q.get('v') or [''])[0]
            p = os.path.join(versions_dir(id_), 'v%s.bpmn' % v)
            if not (v.isdigit() and os.path.exists(p)):
                return self._json(404, {'ok': False, 'error': 'no such version'})
            with open(p, 'rb') as f:
                return self._bytes(200, f.read(), 'application/xml')
        if route == '/api/thumb':
            v = (q.get('v') or [''])[0]
            if v:
                # saved-version thumbnail (unchanged)
                p = os.path.join(versions_dir(id_), 'v%s.png' % v)
                if not (v.isdigit() and os.path.exists(p)):
                    return self._json(404, {'ok': False, 'error': 'no thumbnail'})
            else:
                # T-153: rendered-corpus cached tile. Corpus BPMNs carry no DI coords and
                # no saved PNG, so tools/gen-rendered-thumbs.mjs pre-renders each map into
                # this tracked cache. id_ is ID_RE-validated above (no traversal). The
                # cache dir starts with '_' so build_map_list() never enumerates it as a map.
                p = os.path.join(REPO, '.editor-versions', '_rendered', '%s.png' % id_)
                if not os.path.exists(p):
                    return self._json(404, {'ok': False, 'error': 'no thumbnail'})
            with open(p, 'rb') as f:
                return self._bytes(200, f.read(), 'image/png')
        return self._json(404, {'ok': False, 'error': 'unknown endpoint'})

    # ---- POST ----
    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path not in ('/api/save', '/api/delete'):
            return self._json(404, {'ok': False, 'error': 'unknown endpoint'})
        try:
            length = int(self.headers.get('Content-Length', '0'))
            payload = json.loads(self.rfile.read(length) or b'{}')
        except Exception as e:
            return self._json(400, {'ok': False, 'error': 'bad json: %s' % e})
        if parsed.path == '/api/delete':
            return self._api_delete(payload)
        id_ = payload.get('id', '')
        bpmn = payload.get('bpmn', '')
        if not self._valid_id(id_):
            return self._json(400, {'ok': False, 'error': 'invalid id (need ^[a-z0-9][a-z0-9_-]*$)'})
        if not bpmn or '<' not in bpmn:
            return self._json(400, {'ok': False, 'error': 'missing/empty bpmn'})
        ts = int(time.time() * 1000)
        note = (payload.get('note') or '').strip()[:200]

        # next version number
        index = read_index(id_)
        v = (max([e.get('v', 0) for e in index]) + 1) if index else 1
        vdir = versions_dir(id_)
        os.makedirs(vdir, exist_ok=True)

        bpmn_bytes = bpmn.encode('utf-8')
        # 1. version snapshot
        with open(os.path.join(vdir, 'v%d.bpmn' % v), 'wb') as f:
            f.write(bpmn_bytes)
        # 2. thumbnail (optional)
        thumb = None
        png_b64 = payload.get('png')
        if png_b64:
            try:
                raw = base64.b64decode(png_b64.split(',', 1)[-1])
                with open(os.path.join(vdir, 'v%d.png' % v), 'wb') as f:
                    f.write(raw)
                thumb = 'v%d.png' % v
            except Exception:
                thumb = None
        # 3. canonical rendered map (committed) — existence-or-promotion gated (T-138).
        #    Version snapshot (step 1) already persisted the operator's work durably;
        #    publishing into the *committed* corpus is a separate, deliberate act.
        #    A new id (no canonical file yet) is treated as scratch and NOT published
        #    unless explicitly promoted, so ad-hoc/test saves can't pollute the corpus.
        rendered_repo = os.path.join(REPO, 'examples', 'aef-processes', 'rendered', '%s.bpmn' % id_)
        is_existing_corpus = os.path.exists(rendered_repo)
        promote = bool(payload.get('promote')) or ALLOW_NEW_CORPUS
        to_corpus = is_existing_corpus or promote
        if to_corpus:
            os.makedirs(os.path.dirname(rendered_repo), exist_ok=True)
            with open(rendered_repo, 'wb') as f:
                f.write(bpmn_bytes)
        # served copy — always written so the map is immediately loadable in the gallery
        served = os.path.join(DOCROOT, 'rendered', '%s.bpmn' % id_)
        try:
            os.makedirs(os.path.dirname(served), exist_ok=True)
            with open(served, 'wb') as f:
                f.write(bpmn_bytes)
        except Exception:
            pass  # served copy is best-effort (docroot may be read-only in tests)
        # 4. index
        index.append({'v': v, 'ts': ts, 'note': note, 'thumb': thumb, 'bytes': len(bpmn_bytes)})
        write_index(id_, index)

        # 5. registry twin (T-227/S3b) — rescan this map's off-page refs into the ghost
        #    registry. Best-effort: a registry glitch must never fail an otherwise-durable
        #    save (the version snapshot in step 1 already persisted the operator's work).
        try:
            sync_registry_after_save(id_, bpmn)
            # S4a: a save of a map whose own uuid is a pending ghost IS a claim (via the
            # 'create from pending ref' picker). Record it + drop the ghost. Best-effort.
            claim_ghost_after_save(id_, bpmn, via='ui')
        except Exception as e:
            sys.stderr.write("[gallery-serve] registry sync (save) failed for %r: %s\n" % (id_, e))

        return self._json(200, {'ok': True, 'v': v, 'ts': ts, 'corpus': to_corpus})

    # ---- DELETE (T-166) — archive-based, recoverable ----
    def _api_delete(self, payload):
        id_ = payload.get('id', '')
        scope = payload.get('scope', 'workflow')
        if not self._valid_id(id_):
            return self._json(400, {'ok': False, 'error': 'invalid id (need ^[a-z0-9][a-z0-9_-]*$)'})
        if scope == 'workflow':
            return self._delete_workflow(id_)
        if scope == 'version':
            return self._delete_version(id_, payload.get('v'))
        if scope == 'prune-old':
            return self._prune_old_versions(id_)
        return self._json(400, {'ok': False, 'error': "unsupported scope (want workflow|version|prune-old)"})

    def _delete_workflow(self, id_):
        ts = int(time.time() * 1000)
        trash = trash_dir(id_, ts)
        # Whole-workflow delete: version store + committed corpus baseline + rendered thumbnail.
        candidates = [
            (versions_dir(id_), os.path.join(trash, 'versions')),
            (os.path.join(REPO, 'examples', 'aef-processes', 'rendered', '%s.bpmn' % id_),
             os.path.join(trash, 'rendered', '%s.bpmn' % id_)),
            (os.path.join(REPO, '.editor-versions', '_rendered', '%s.png' % id_),
             os.path.join(trash, 'rendered_thumb', '%s.png' % id_)),
        ]
        archived = [rel for rel in (archive_move(s, d) for s, d in candidates) if rel]
        # served copy is gitignored and regenerable — just drop it (best-effort).
        served = os.path.join(DOCROOT, 'rendered', '%s.bpmn' % id_)
        try:
            if os.path.exists(served):
                os.remove(served)
        except Exception:
            pass
        if not archived:
            return self._json(404, {'ok': False, 'error': 'nothing to delete for id %r' % id_})
        # registry twin (T-227/S3b) — strip this map from every ghost's referenced_by, then
        # drop now-unreferenced ghosts. Best-effort: never fail a completed delete.
        try:
            sync_registry_after_delete(id_)
        except Exception as e:
            sys.stderr.write("[gallery-serve] registry sync (delete) failed for %r: %s\n" % (id_, e))
        return self._json(200, {'ok': True, 'archived': archived, 'trash': os.path.relpath(trash, REPO)})

    def _delete_version(self, id_, v):
        # Archive a single snapshot (vN.bpmn + vN.png) and drop its index entry (T-167).
        if not (isinstance(v, int) or (isinstance(v, str) and str(v).isdigit())):
            return self._json(400, {'ok': False, 'error': 'missing/invalid v'})
        v = int(v)
        index = read_index(id_)
        if not any(e.get('v') == v for e in index):
            return self._json(404, {'ok': False, 'error': 'no such version %d' % v})
        ts = int(time.time() * 1000)
        trash = trash_dir(id_, ts)
        vdir = versions_dir(id_)
        archived = [rel for rel in (
            archive_move(os.path.join(vdir, 'v%d.bpmn' % v), os.path.join(trash, 'v%d.bpmn' % v)),
            archive_move(os.path.join(vdir, 'v%d.png' % v), os.path.join(trash, 'v%d.png' % v)),
        ) if rel]
        write_index(id_, [e for e in index if e.get('v') != v])
        return self._json(200, {'ok': True, 'v': v, 'archived': archived, 'trash': os.path.relpath(trash, REPO)})

    def _prune_old_versions(self, id_):
        # Keep only the highest-numbered snapshot; archive the rest (T-167).
        index = read_index(id_)
        if not index:
            return self._json(404, {'ok': False, 'error': 'no versions for id %r' % id_})
        keep = max(e.get('v', 0) for e in index)
        older = [e for e in index if e.get('v') != keep]
        if not older:
            return self._json(200, {'ok': True, 'kept': keep, 'archived': []})  # single version → no-op
        ts = int(time.time() * 1000)
        trash = trash_dir(id_, ts)
        vdir = versions_dir(id_)
        archived = []
        for e in older:
            n = e.get('v')
            for rel in (archive_move(os.path.join(vdir, 'v%d.bpmn' % n), os.path.join(trash, 'v%d.bpmn' % n)),
                        archive_move(os.path.join(vdir, 'v%d.png' % n), os.path.join(trash, 'v%d.png' % n))):
                if rel:
                    archived.append(rel)
        write_index(id_, [e for e in index if e.get('v') == keep])
        return self._json(200, {'ok': True, 'kept': keep, 'archived': archived, 'trash': os.path.relpath(trash, REPO)})


def main():
    _args(sys.argv[1:])
    httpd = ThreadingHTTPServer((BIND, PORT), Handler)
    ip = ''
    try:
        import subprocess
        ip = subprocess.check_output(['hostname', '-I']).decode().split()[0]
    except Exception:
        ip = 'localhost'
    sys.stderr.write("gallery-serve (write-capable) docroot=%s repo=%s\n" % (DOCROOT, REPO))
    sys.stderr.write("Local:  http://localhost:%d/\n" % PORT)
    sys.stderr.write("LAN:    http://%s:%d/\n" % (ip, PORT))
    sys.stderr.write("API:    /api/health /api/list /api/save /api/delete /api/versions /api/version /api/thumb\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.shutdown()


if __name__ == '__main__':
    main()
