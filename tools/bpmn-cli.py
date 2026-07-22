#!/usr/bin/env python3
"""bpmn-cli.py — headless off-page connector operations (T-230 / S4b).

`fw bpmn claim <uuid> <project>` claims a pending off-page-connector ghost for an
existing project WITHOUT the editor. It:

  1. resolves <uuid> against a pending ghost in .context/designer/registry.yaml,
  2. splices the uuid into <project>'s stored BPMN <aef:workflowMeta> (a new
     version, so it becomes the authoritative + served + corpus-if-existing copy),
  3. drops the ghost and records {uuid, project, ts, via:"cli"} in claims[].

That is the SAME outcome as S4a's editor picker (via:"ui") — the target becomes a
live map identity, so every referrer whose workflowRef==<uuid> resolves by the S3
rescan with ZERO referrer-XML edit — only the surface (headless CLI) and the `via`
marker differ.

Design (single source of truth, T-230 antifragility): the durable mutation reuses
gallery-serve.py's PROVEN registry/version helpers — the version write mirrors the
/api/save handler, and the registry update calls the exact same two functions the
server calls on save (sync_registry_after_save + claim_ghost_after_save). No claim
semantics are re-implemented here.

Boundary (T-559): operates ONLY on 832's own store — the target repo's
.context/designer/registry.yaml + gallery/version store. Never invokes AEF tooling.

Guardrails (all fail loud, non-zero, NO registry/store mutation):
  * <uuid> is not a pending ghost (and not already claimed) → error.
  * <project> has no stored map (no version and no rendered corpus file) → error.
  * <project>'s workflowMeta already carries a DIFFERENT live uuid → error (claiming
    would orphan that identity; claim onto a uuid-less map, matching S4a's
    fresh-adoption semantics, or use the editor picker).
  * <project> has no <aef:workflowMeta> element at all → error (open+save it in the
    editor once to mint identity, then claim).

Idempotent: re-claiming an already-claimed uuid, or claiming a uuid the target map
already carries, is a no-op success — no duplicate claims[] entry, ghost stays gone,
no new version written.

Stdlib-only. Usage:
    bpmn-cli.py [--repo DIR] claim <uuid> <project>
--repo defaults to $PROJECT_ROOT (exported by fw), else gallery-serve.py's own repo.
"""
import importlib.util
import os
import re
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def _load_gallery_serve():
    """Import gallery-serve.py by path (hyphen in filename blocks a plain import).
    Safe: its argv parse + server start live under `if __name__ == '__main__'`."""
    path = os.path.join(HERE, 'gallery-serve.py')
    spec = importlib.util.spec_from_file_location('gallery_serve', path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _set_repo(gs, repo):
    """Point gallery-serve's module globals at `repo` so every registry/version/
    corpus path resolves under it (enables isolated testing + explicit project root).
    The helpers read REPO/DOCROOT at call time, so reassigning the globals suffices."""
    repo = os.path.abspath(repo)
    gs.REPO = repo
    gs.DOCROOT = os.path.join(repo, 'build', 'gallery')


_WFM_TAG_RE = re.compile(r'<aef:workflowMeta\b([^>]*?)(/?)>')
_UUID_ATTR_RE = re.compile(r'\buuid="[^"]*"')


def splice_uuid(text, uuid):
    """Return (new_text, note). Splice `uuid` into the map's <aef:workflowMeta>:
      * no workflowMeta element     -> (None, 'no-workflowMeta')
      * uuid already == `uuid`      -> (text, 'already')      (idempotent)
      * a DIFFERENT uuid present    -> (None, 'conflict:<other>')
      * workflowMeta, no uuid attr  -> inject uuid  -> (new, 'injected')
    Only the workflowMeta open tag is rewritten; all other content is untouched."""
    if not text:
        return None, 'no-workflowMeta'
    m = _WFM_TAG_RE.search(text)
    if not m:
        return None, 'no-workflowMeta'
    attrs, selfclose = m.group(1), m.group(2)
    existing = _UUID_ATTR_RE.search(attrs)
    if existing:
        cur = existing.group(0)[len('uuid="'):-1]
        if cur == uuid:
            return text, 'already'
        return None, 'conflict:%s' % cur
    new_tag = '<aef:workflowMeta uuid="%s"%s%s>' % (uuid, attrs, selfclose)
    return text[:m.start()] + new_tag + text[m.end():], 'injected'


def _write_version(gs, id_, bpmn_text, note):
    """Persist `bpmn_text` as the next version of `id_`, mirroring the /api/save
    handler's durable writes: version snapshot (always) + committed corpus copy
    (only when the canonical file already exists — never publishes a NEW corpus map)
    + served copy (best-effort) + index bump. Returns the new version number."""
    index = gs.read_index(id_)
    v = (max([e.get('v', 0) for e in index]) + 1) if index else 1
    vdir = gs.versions_dir(id_)
    os.makedirs(vdir, exist_ok=True)
    data = bpmn_text.encode('utf-8')
    with open(os.path.join(vdir, 'v%d.bpmn' % v), 'wb') as f:
        f.write(data)
    rendered_repo = os.path.join(gs.REPO, 'examples', 'aef-processes', 'rendered', '%s.bpmn' % id_)
    if os.path.exists(rendered_repo):                 # existence-gated (T-138): never publish a NEW corpus map
        with open(rendered_repo, 'wb') as f:
            f.write(data)
    served = os.path.join(gs.DOCROOT, 'rendered', '%s.bpmn' % id_)
    try:
        os.makedirs(os.path.dirname(served), exist_ok=True)
        with open(served, 'wb') as f:
            f.write(data)
    except Exception:
        pass                                          # served copy is best-effort (docroot may be read-only)
    index.append({'v': v, 'ts': int(time.time() * 1000), 'note': note,
                  'thumb': None, 'bytes': len(data)})
    gs.write_index(id_, index)
    return v


def _err(msg):
    sys.stderr.write('fw bpmn claim: %s\n' % msg)
    return 1


def cmd_claim(gs, uuid, project):
    """Claim a pending ghost `uuid` for existing map `project`. Returns exit code."""
    if not gs.ID_RE.match(project or ''):
        return _err("invalid project id %r (need ^[a-z0-9][a-z0-9_-]*$)" % project)

    reg = gs.read_registry()
    ghost = next((g for g in reg['ghosts'] if g.get('uuid') == uuid), None)
    already = any(c.get('uuid') == uuid for c in reg.get('claims', []))

    if ghost is None:
        if already:
            print('already claimed: %s (idempotent no-op)' % uuid)   # ghost long gone, claim on record
            return 0
        return _err("no pending ghost with uuid %r — nothing to claim "
                    "(see `fw bpmn` targets in .context/designer/registry.yaml ghosts[])" % uuid)

    # Resolve the target map's authoritative BPMN (latest version, else rendered corpus).
    latest = gs._latest_version(project)
    path = gs._authoritative_bpmn_path(project, latest)
    text = gs._read_text(path)
    if not text:
        return _err("unknown project %r — no stored map (no saved version and no "
                    "rendered corpus file). NO mutation performed." % project)

    new_text, note = splice_uuid(text, uuid)
    if note == 'no-workflowMeta':
        return _err("project %r has no <aef:workflowMeta> element; open and save it in "
                    "the editor once to mint identity, then claim. NO mutation." % project)
    if note.startswith('conflict:'):
        other = note.split(':', 1)[1]
        return _err("project %r already carries a different identity uuid=%s; claiming "
                    "would orphan it. Claim onto a uuid-less map (or use the editor "
                    "picker for a fresh map). NO mutation." % (project, other))
    if note == 'already':
        # Target already carries this uuid but a ghost still lists it: record the claim +
        # drop the ghost (converge to claimed) without writing a redundant version.
        claimed = gs.claim_ghost_after_save(project, new_text, via='cli')
        print('claimed (already carried): %s -> %s (via:cli)' % (uuid, project)
              if claimed else 'already claimed: %s (idempotent no-op)' % uuid)
        return 0

    # note == 'injected' — write the new version, then reuse the server's own
    # save-time registry path (sync THEN claim) so the outcome is byte-identical
    # to S4a apart from via:"cli".
    v = _write_version(gs, project, new_text, 'fw bpmn claim (via:cli)')
    gs.sync_registry_after_save(project, new_text)
    claimed = gs.claim_ghost_after_save(project, new_text, via='cli')
    if not claimed:
        return _err("version v%d written but ghost %s vanished before claim (concurrent "
                    "writer?) — re-run `fw bpmn claim` to converge." % (v, uuid))
    print('claimed: %s -> %s v%d (via:cli); ghost dropped, referrers now resolve' % (uuid, project, v))
    return 0


def _usage():
    sys.stderr.write(
        "Usage: fw bpmn claim <uuid> <project>\n"
        "  Claim a pending off-page-connector ghost for an existing project (headless,\n"
        "  via:cli). The project map adopts the uuid so its referrers resolve.\n")
    return 1


def main(argv):
    repo = os.environ.get('PROJECT_ROOT') or None
    args = list(argv)
    if args and args[0] == '--repo':
        if len(args) < 2:
            return _usage()
        repo, args = args[1], args[2:]
    if not args:
        return _usage()
    sub, rest = args[0], args[1:]
    if sub != 'claim':
        sys.stderr.write("fw bpmn: unknown subcommand %r (only 'claim' is supported)\n" % sub)
        return _usage()
    if len(rest) != 2:
        return _usage()

    gs = _load_gallery_serve()
    if repo:
        _set_repo(gs, repo)
    uuid, project = rest
    return cmd_claim(gs, uuid, project)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
