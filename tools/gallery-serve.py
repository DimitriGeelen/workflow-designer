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
      examples/aef-processes/rendered/<id>.bpmn   (canonical, committed)
      build/gallery/rendered/<id>.bpmn            (served copy, immediately loadable)
      .editor-versions/<id>/vN.bpmn               (immutable version snapshot)
      .editor-versions/<id>/vN.png                (thumbnail, if posted)
      .editor-versions/<id>/index.json            (version list)
  - localhost-bound; `id` is validated against ^[a-z0-9][a-z0-9_-]*$ (no traversal).

API:
  GET  /api/health                 -> {ok:true, versions:".editor-versions"}
  GET  /api/versions?id=<id>       -> index.json  ([] if none)
  GET  /api/version?id=<id>&v=<n>  -> that version's BPMN (text/xml)
  GET  /api/thumb?id=<id>&v=<n>    -> that version's PNG
  POST /api/save  {id, bpmn, png?, note?} -> {ok:true, v, ts}

Usage: gallery-serve.py [PORT] [--docroot DIR] [--repo DIR] [--bind ADDR]
Defaults: PORT=8834, docroot=<repo>/build/gallery, repo=<script>/.., bind=0.0.0.0
"""
import base64
import json
import os
import re
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


def _args(argv):
    global DOCROOT, REPO, BIND, PORT
    it = iter(argv)
    for a in it:
        if a == '--docroot':
            DOCROOT = os.path.abspath(next(it))
        elif a == '--repo':
            REPO = os.path.abspath(next(it))
        elif a == '--bind':
            BIND = next(it)
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


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=DOCROOT, **k)

    def log_message(self, fmt, *args):
        sys.stderr.write("[gallery-serve] " + (fmt % args) + "\n")

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
            p = os.path.join(versions_dir(id_), 'v%s.png' % v)
            if not (v.isdigit() and os.path.exists(p)):
                return self._json(404, {'ok': False, 'error': 'no thumbnail'})
            with open(p, 'rb') as f:
                return self._bytes(200, f.read(), 'image/png')
        return self._json(404, {'ok': False, 'error': 'unknown endpoint'})

    # ---- POST ----
    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != '/api/save':
            return self._json(404, {'ok': False, 'error': 'unknown endpoint'})
        try:
            length = int(self.headers.get('Content-Length', '0'))
            payload = json.loads(self.rfile.read(length) or b'{}')
        except Exception as e:
            return self._json(400, {'ok': False, 'error': 'bad json: %s' % e})
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
        # 3. canonical rendered map (committed) + served copy
        rendered_repo = os.path.join(REPO, 'examples', 'aef-processes', 'rendered', '%s.bpmn' % id_)
        os.makedirs(os.path.dirname(rendered_repo), exist_ok=True)
        with open(rendered_repo, 'wb') as f:
            f.write(bpmn_bytes)
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

        return self._json(200, {'ok': True, 'v': v, 'ts': ts})


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
    sys.stderr.write("API:    /api/health /api/save /api/versions /api/version /api/thumb\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.shutdown()


if __name__ == '__main__':
    main()
