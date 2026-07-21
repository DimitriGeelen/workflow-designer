# T-227 / S3b — Designer registry twin: implementation spec

**Status:** execution-ready, FULLY UNBLOCKED. Seam-Q resolved on the rail (offset 133→134):
`task` is always null on the 832 twin, the drop logic collapses to a single rule, and 832 mirrors
the name-only store-mint. Corrections from AEF folded in below (§4 was rewritten — the earlier
uuid-pinned drop-exemption and independent name-in-slugs trigger were both wrong).

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
to the twin. It grants **no drop exemption** (rail offset 134); its only job is to distinguish a
store-minted name-only uuid from an XML-pinned workflowRef uuid at CLAIM time (S4) and to key the
upsert (name-only dedupes by name, uuid-pinned by uuid). `/api/list` MAY omit it from the wire
payload — keep the wire `ghosts[]` entry shape identical to S3a's.

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
1. `uuid_refs = _link_refs_from_text(bpmn)` (workflowRef) — reuse S3a.
   `legacy_refs = _legacy_refs_from_text(bpmn)` — NEW helper: `<aef:link targetWorkflow="slug">`
   with NO `workflowRef`; return `[{slug, node, nodeName}]` via the same ancestor-climb as S3a.
2. Live maps: `maps = build_map_list()[0]`; `live_uuids = {m['uuid'] for m in maps if m['uuid']}`;
   `live_slugs = {m['id'] for m in maps}` (store slug == map id).
3. Under `_REG_LOCK`: `reg = read_registry()`.
4. **Drop this map's stale contributions:** for every ghost, remove any `referenced_by` entry
   whose `id == id_` (this save is the fresh truth for that map).
5. **uuid-pinned:** for each uuid ref whose `workflowRef` ∉ `live_uuids`: upsert a ghost by uuid —
   if absent create `{uuid, name, kind:"uuid-pinned", referenced_by:[], task:null, first_seen:now}`;
   append `{id:id_, node, nodeName}` (dedup by `(id,node)`). Refs that resolve contribute nothing.
5b. **name-only (legacy), sub-Q YES:** for each legacy ref whose `slug` ∉ `live_slugs`
   (**skip recording when the target IS live** — that's the "name matches slug" behavior, done by
   omission, §4): upsert a ghost keyed **by display name** (`slug`) — dedupe so two referrers of
   the same missing workflow share ONE ghost; if absent **store-mint** `uuid = _mint_uuid4()`
   (uuid4, registry-side only, **never rewrite diagram XML**) → `{uuid, name:slug,
   kind:"name-only", referenced_by:[], task:null, first_seen:now}`; append the referrer
   (dedup by `(id,node)`). Find-existing by `name==slug AND kind=="name-only"`.
6. **Apply the single drop rule (§4):** remove every ghost whose `referenced_by` is now empty.
   `write_registry(reg)`.

`_mint_uuid4()`: `str(uuid.uuid4())` — add `import uuid` (stdlib). uuid4 makes cross-store
collision a non-issue (AEF rationale: a minted ghost uuid becomes real identity only at claim
time in whichever store performs the claim).

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

## 4. The drop rule (AC4) — **RESOLVED, rail offset 134: ONE rule**

AEF confirmed (code-verified `designer_registry.py:158-163`): `task` is always null on the 832
twin (their substrate is the sole doc-task minter). Their full keep-rule
`keep iff (referenced_by nonempty OR task set) AND NOT (referenced_by empty AND name in live_slugs)`
collapses with `task≡null` to a **single rule applied on every registry sync (save + delete)**:

> **DROP a ghost when its `referenced_by` becomes empty — for `uuid-pinned` AND `name-only` alike.**

Two corrections to the earlier draft (both were wrong):
- **NO uuid-pinned drop exemption.** The registry is a **debt record, not an identity record** —
  the uuid identity lives in the diagram XML. A uuid-pinned ghost whose last referrer is deleted
  DROPS on rescan (deleted-connector debt closed); it **re-materializes** from S3a derivation /
  the next save if the ref returns. "Exit via claim" (S4) is about name-*resolution*, not a drop
  exemption. → The `kind` field is still useful to distinguish store-minted vs XML-pinned uuids at
  claim time, but it grants NO drop exemption.
- **"name matches live slug" is NOT an independent drop trigger.** The rescan simply **skips
  recording** a legacy ref whose named target is already live (see §2, legacy branch); referrers
  then decay per-project as each referring map is re-saved. The slug-match clause only ever fires
  when `referenced_by` is also empty, so with `task≡null` it is dead code — do not implement it.
  Consequence (congruent both sides): a name-only ghost whose target now exists keeps showing
  until every referring map has been re-saved.

Delete-path parity: `/api/delete`'s strip applies the same single "drop when empty" filter.
No `task`-set KEEP branch, no task-minting path — S3b builds no `fw task create` call.

---

## 5. Tests (AC6) — `tools/_gallery-registry-verify.py`

Isolated-temp-repo pattern from `_gallery-list-verify.py`. Assert:
1. save a map with an unresolved `workflowRef` → registry.yaml created; ghost persisted with
   `first_seen` int, `kind:"uuid-pinned"`, referenced_by=[that map/node].
2. second save of same map (same ref) → referenced_by not duplicated (dedup by id,node).
3. save a second map referencing the same ghost uuid → referenced_by has both maps.
4. delete one of two referrers → its entries stripped; ghost still present (other referrer).
5. delete the LAST referrer → ghost **DROPS** (single rule; uuid-pinned is NOT exempt).
5b. **re-materialize:** re-save a map still carrying that workflowRef → ghost reappears with a
   fresh first_seen (registry is a debt cache, not identity — uuid identity lives in the XML).
6. resolve: create a live map whose uuid == the ghost's uuid, re-save a referrer → that ref no
   longer contributes; `/api/list` ghosts[] no longer lists it.
7. **name-only:** save a map with legacy `targetWorkflow="absent-slug"` (not live) → a
   `kind:"name-only"` ghost minted with a uuid4, `name=="absent-slug"`, first_seen set.
7b. **dedupe-by-name:** a SECOND map with the same `targetWorkflow="absent-slug"` → shares the
   SAME ghost (one entry, two referrers), not a second mint.
7c. **skip-when-live:** save a map with `targetWorkflow="alpha"` where `alpha` IS a live map →
   NO ghost recorded for it.
8. atomic write leaves no `*.tmp` behind in `.context/designer/`.
9. malformed registry.yaml (write garbage) → `/api/list` still 200, treated as empty.

## Verification block for T-227
```
python3 tools/_gallery-registry-verify.py
python3 tools/_gallery-list-verify.py
python3 tools/_gallery-save-allowlist-verify.py
python3 -m pytest tests/test_corpus_fixture_pins.py -q
```

## Decisions captured here
- **json.dump into .yaml** (valid YAML, keeps server stdlib-only) — not `import yaml`.
- **`kind` field** on registry ghosts distinguishes store-minted (name-only) from XML-pinned
  (uuid-pinned) uuids — for the upsert key (dedupe by name vs uuid) and S4 claim behavior. It is
  NOT a drop exemption (rail offset 134): both kinds drop on empty referenced_by.
- **Single drop rule** (rail offset 134): drop when referenced_by empty, both kinds. Registry is
  a debt cache, not identity — dropped uuid-pinned ghosts re-materialize from XML on re-save.
- **name-only store-mint** (uuid4, dedupe by display name, registry-side only, never rewrite XML)
  mirrors AEF for S4 congruence on pair-draft-3's legacy `review-map` leg.
- **Threading lock** around registry read-modify-write (ThreadingHTTPServer).
- **Merge policy:** derivation authoritative for referenced_by; registry authoritative for
  task/first_seen. Prevents the persisted registry from masking a just-drawn ref and vice-versa.
