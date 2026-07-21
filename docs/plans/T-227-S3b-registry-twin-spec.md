# T-227 / S3b — Designer registry twin: implementation spec

**Status:** execution-ready except the *name-only/legacy branch*, which is BLOCKED on the
rail seam-Q (posted offset 133). Both branches are specified below; when AEF answers, keep
one and delete the other — no re-derivation needed.

**Predecessor:** T-226 / S3a (read-only `maps[].uuid` + derived `ghosts[]`) — DONE. This spec
extends the same `tools/gallery-serve.py`; reuse S3a's `_link_refs_from_text`, `_uuid_from_text`,
`_authoritative_bpmn_path`, `_derive_ghosts`.

**Contract:** ratified rail offset 109/110; drop rules offset 113; `<aef:link>` is child-keyed +
host-agnostic (seam-fact offset 130). Registry is STORE-side — "one contract, two
implementations" (832 local gallery store ⟷ AEF Watchtower designer_api). 832's file is local;
it need NOT be byte-identical to AEF's, only behaviorally equivalent.

---

## 1. Registry file & schema

Path: `.context/designer/registry.yaml` (sibling of `projects/`). Schema:

```yaml
ghosts:
  - uuid: "<uuid>"            # workflowRef uuid (uuid-pinned) OR store-minted uuid (name-only)
    name: "<display>"        # aef:link name attr, or legacy slug for name-only
    kind: "uuid-pinned" | "name-only"   # NEW field — governs drop-rule exemption (see §4)
    referenced_by:
      - {id: "<mapId>", node: "<nodeId>", nodeName: "<hostName>"}
    task: "T-XXXX" | null    # seam-Q — see §4 branch
    first_seen: <epoch_int>
claims: []                   # populated by S4 (fw bpmn claim): [{uuid, project, ts, via:ui|cli}]
```

`kind` is additive over the ratified `{uuid,name,referenced_by,task,first_seen}` shape — internal
to the twin's drop logic; `/api/list` MAY omit it from the wire payload (S3a's derived entries
have no `kind`), so serve it only if harmless. Keep the wire `ghosts[]` entry shape identical to
S3a's.

### Serialization — stay stdlib-only (portability, Directive 4)
`gallery-serve.py` is stdlib-only today. **Write with `json.dump` (indent=2), extension `.yaml`.**
JSON is a strict subset of YAML 1.2 — `yaml.safe_load` (PyYAML 6.x, present in-env) reads it,
and AEF-side / audit tooling that expects YAML works unchanged. No `import yaml` added to the
server. (Verified: `yaml.safe_load(json.dumps({...}))` round-trips.)

### Atomic write (AC1)
```python
REGISTRY = os.path.join(REPO, '.context', 'designer', 'registry.yaml')

def read_registry():
    try:
        with open(REGISTRY, encoding='utf-8') as f:
            data = json.load(f)                 # json.load also parses our own output
        return {'ghosts': data.get('ghosts') or [], 'claims': data.get('claims') or []}
    except Exception:
        return {'ghosts': [], 'claims': []}     # missing/malformed -> empty, never raises

def write_registry(reg):
    os.makedirs(os.path.dirname(REGISTRY), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(REGISTRY), suffix='.tmp')
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as f:
            json.dump({'ghosts': reg['ghosts'], 'claims': reg['claims']}, f, indent=2)
        os.replace(tmp, REGISTRY)               # atomic on POSIX
    except Exception:
        try: os.unlink(tmp)
        except OSError: pass
        raise
```
`read_registry` must be exception-proof (AC1) — a malformed file NEVER breaks `/api/list`/`/api/save`.
Add `import tempfile` (stdlib). No cross-process lock: gallery-serve is single-writer localhost
(`ThreadingHTTPServer` but one operator); a threading `Lock` around read-modify-write of the
registry is sufficient and cheap — add `_REG_LOCK = threading.Lock()`.

---

## 2. `/api/save` rescan (AC2)

Hook AFTER `write_index(id_, index)` (currently `gallery-serve.py:462`), before the `return`.

```python
_sync_registry_after_save(id_, bpmn)   # bpmn = the just-saved XML string
```

`_sync_registry_after_save`:
1. `refs = _link_refs_from_text(bpmn)` (uuid-pinned) — reuse S3a.
   Legacy: `_legacy_refs_from_text(bpmn)` (targetWorkflow, no workflowRef) — **name-only branch, §4**.
2. Compute live map uuids: `{m['uuid'] for m in build_map_list()[0] if m['uuid']}`.
3. Under `_REG_LOCK`: `reg = read_registry()`.
4. First, **drop this map's stale contributions**: for every ghost, remove any
   `referenced_by` entry whose `id == id_` (this save is the fresh truth for that map).
5. For each uuid-pinned ref whose `workflowRef` ∉ live uuids: upsert a `kind:"uuid-pinned"`
   ghost — find by uuid; if absent create `{uuid, name, kind, referenced_by:[], task:null,
   first_seen:now}`; append `{id:id_, node, nodeName}` (dedup by `(id,node)`).
   A ref that DOES resolve to a live uuid contributes nothing (and step 4 already cleared it).
6. Apply drop rules (§4) → `write_registry(reg)`.

`now = int(time.time())` (epoch seconds; S3a's derived entries use null first_seen — registry is
authoritative once persisted, see §3).

---

## 3. `/api/delete` strip + merged `/api/list` (AC3, AC5)

**Delete** (`_api_delete`, `gallery-serve.py:467`): after the existing archive move, under
`_REG_LOCK`: `reg = read_registry()`; for every ghost remove `referenced_by` entries with
`id == <deleted id>`; apply drop rules; `write_registry`. A uuid-pinned ghost left
`referenced_by`-empty is KEPT (claim-only exit); name-only empties drop per §4.

**`/api/list` merge** (AC5): the wire `ghosts[]` = registry ∪ live-derivation:
- `derived = _derive_ghosts(records)` (S3a) — authoritative for CURRENT `referenced_by`
  (reflects unsaved-but-drawn refs too).
- `reg = read_registry()` — authoritative for `task` + `first_seen`.
- Merge by uuid: start from `derived`; for each, if a registry ghost has same uuid, copy its
  `task`/`first_seen` onto the derived entry. Include registry-only ghosts whose `referenced_by`
  is non-empty OR that survive drop rules (e.g. name-only debt with a task). Emit the S3a wire
  shape `{uuid,name,referenced_by,task,first_seen}`.
- Keep `ghosts[]` a SEPARATE top-level array (never status-flag maps[]) — S3a invariant.

> Rationale: derivation catches a ref drawn since the last save (nice for the picker); registry
> supplies persistent fields derivation can't know (first_seen, task). Registry ghosts with empty
> referenced_by that survive drop rules (name-only + task, target still absent) stay visible even
> though no current map references them — that's the "deleted-connector debt stays visible" case.

---

## 4. The 3 ghost-drop rules (AC4) — **branches on the seam-Q**

Applied on every registry sync (save + delete), AFTER referenced_by is recomputed:

**Exemption (both branches, unconditional):** a `kind:"uuid-pinned"` ghost is NEVER auto-dropped.
It exits ONLY via an S4 claim (uuid → project meta.json, removed from `ghosts`, recorded in
`claims`). Rules below govern ONLY `kind:"name-only"` ghosts.

Live slugs for rule 3: `{m['id'] for m in maps}` (store slug == map id) plus any name→slug match.

### Branch A — 832 twin does NOT mint tasks (`task` always null) — my working assumption
Rules 2/3's "task set" clauses can't fire, so they collapse to:
- **Drop** a name-only ghost when `referenced_by` is empty (rule 1; rule 3's slug-match is a
  strict subset — an empty-ref name-only ghost drops regardless of whether its name now matches a
  live slug).
- Net: name-only ghost lives exactly as long as some saved map still carries its legacy slug ref.
- Simplest to implement + test. **Preferred pending confirmation.**

### Branch B — 832 twin mints doc-tasks (`task` populated, mirrors AEF)
Full offset-113 semantics:
1. **DROP** when `referenced_by` empty AND `task` is null.
2. **KEEP** when `referenced_by` empty AND `task` set AND the named target still doesn't exist
   (a live map with that slug/name) — debt stays visible.
3. **DROP** when `referenced_by` empty AND the ghost's `name` now matches a live map slug, even
   if `task` is set (legacy debt closes once the target is created).
Requires a task-minting path (gated writer, idempotent per uuid) — a meaningfully larger build;
if AEF picks this, consider splitting task-minting into its own slice.

**Sub-Q (also on rail):** whether 832 store-mints a uuid for a legacy `targetWorkflow` slug with
no live map at all (creating the name-only ghost) — if AEF says "leave legacy slugs untracked,"
the entire name-only branch + rules 2/3 disappear and S3b is only uuid-pinned persistence +
claim-exit, which is small and unblocked.

---

## 5. Tests (AC6) — `tools/_gallery-registry-verify.py`

Isolated-temp-repo pattern from `_gallery-list-verify.py`. Assert:
1. save a map with an unresolved `workflowRef` → registry.yaml created; ghost persisted with
   `first_seen` int, `kind:"uuid-pinned"`, referenced_by=[that map/node].
2. second save of same map (same ref) → referenced_by not duplicated (dedup by id,node).
3. save a second map referencing the same ghost uuid → referenced_by has both maps.
4. delete one referrer → its entries stripped; ghost still present (uuid-pinned, claim-only).
5. delete last referrer → uuid-pinned ghost KEPT with empty referenced_by.
6. resolve: create a live map whose uuid == the ghost's uuid, re-save a referrer → that ref no
   longer contributes a ghost (moves to resolved); `/api/list` ghosts[] no longer lists it.
7. atomic write leaves no `*.tmp` behind in `.context/designer/`.
8. malformed registry.yaml (write garbage) → `/api/list` still 200, treated as empty.
9. [Branch A] name-only ghost drops when its last referrer is removed.
   [Branch B, if chosen] rules 1/2/3 fire/hold per the offset-113 table.

## Verification block for T-227
```
python3 tools/_gallery-registry-verify.py
python3 tools/_gallery-list-verify.py
python3 tools/_gallery-save-allowlist-verify.py
python3 -m pytest tests/test_corpus_fixture_pins.py -q
```

## Decisions captured here
- **json.dump into .yaml** (valid YAML, keeps server stdlib-only) — not `import yaml`.
- **`kind` field** on registry ghosts to encode the uuid-pinned drop-exemption explicitly rather
  than re-deriving it (a uuid-pinned ghost could momentarily have empty referenced_by and must
  not be mistaken for a droppable name-only one).
- **Threading lock** around registry read-modify-write (ThreadingHTTPServer).
- **Merge policy:** derivation authoritative for referenced_by; registry authoritative for
  task/first_seen. Prevents the persisted registry from masking a just-drawn ref and vice-versa.
