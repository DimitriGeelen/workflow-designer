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
import time
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


def build_map_list():
    """Merge the rendered corpus with saved maps into one read-only listing.

    Per map: {id, title, sources:[rendered|saved], latest:{v,ts,count}|null,
    openTarget:{kind:'version',v}|{kind:'rendered'}}. openTarget is the latest saved
    version when one exists, else the rendered baseline. Read-only; every id is
    validated with ID_RE so nothing outside the corpus/version store is enumerated."""
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
    for m in maps.values():
        m['openTarget'] = ({'kind': 'version', 'v': m['latest']['v']}
                           if m['latest'] else {'kind': 'rendered'})
        out.append(m)
    return sorted(out, key=lambda m: m['id'])


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
            return self._json(200, {'maps': build_map_list()})
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

        return self._json(200, {'ok': True, 'v': v, 'ts': ts, 'corpus': to_corpus})

    # ---- DELETE (T-166) — archive-based, recoverable ----
    def _api_delete(self, payload):
        id_ = payload.get('id', '')
        scope = payload.get('scope', 'workflow')
        if not self._valid_id(id_):
            return self._json(400, {'ok': False, 'error': 'invalid id (need ^[a-z0-9][a-z0-9_-]*$)'})
        if scope != 'workflow':
            return self._json(400, {'ok': False, 'error': "unsupported scope (want 'workflow')"})
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
        return self._json(200, {'ok': True, 'archived': archived, 'trash': os.path.relpath(trash, REPO)})


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
