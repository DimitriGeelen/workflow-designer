# T-221 — S1 uuid identity model: execution-ready implementation spec

**Type:** design (pre-GO) · **Arc:** designer-authoring-surface · **Parent build:** T-218 slice **S1** (per `docs/plans/T-220-offpage-seam-editor-build-decomposition.md`)

**Gate:** design-only — writes NO editor code. The S1 *build* is gated on the operator's GO at
`/inception/T-218` (Tier-0, human-only, still pending). This spec makes that build pure execution.

**Goal of S1:** give every workflow a stable, immutable **uuid** as the connector-referenceable
identity, so an off-page `<aef:link workflowRef="<uuid>">` survives a rename. Today identity IS the
slug (`workflowMeta.id`), which changes on rename — the exact "name-only" gap the seam closes.

---

## Design decision — minimal-churn: uuid as an ADDITIONAL immutable field

The library is keyed by slug (`activeKey` = `workflowMeta.id`; `library.get/set/has` everywhere use
it: `2116`, `2118`, `7257-7259`, `7982-7990`, save `7440`, `renameActiveWorkflow` `2216`). **Do NOT
re-key the library by uuid** — that touches dozens of call sites for zero seam benefit. The seam only
requires *a uuid that is stable across rename*. Adding `workflowMeta.uuid` as a new immutable field
delivers that; the slug stays the human-facing handle and library key.

- **Chose:** `workflowMeta.uuid` additive field; library stays slug-keyed.
- **Why:** connectors reference `uuid` (stable across rename) — the requirement. Re-key is unrelated churn.
- **Rejected:** library keyed by uuid — large blast radius (`activeKey`, all `library.*`, undo `6283`, import collision `7990`), no seam gain. Revisit only if a future slice needs uuid-primary lookup.

---

## Current-state anchors (verified 2026-07-21, `src/aef-workflow-designer.html`)

| Concern | Line(s) | Note |
|---------|---------|------|
| `workflowMeta` shape `{id, version, title, …}` | `1787`, `2185`, `4650` | **no uuid today** |
| Library keyed by `workflowMeta.id` (slug) | `2116`,`2118`,`7257`,`7982-7990` | `activeKey` = slug |
| `renameActiveWorkflow` mutates `workflowMeta.id`, re-keys library | `2211-2224` | uuid must stay UNTOUCHED here |
| Process-level `<aef:workflowMeta …>` export | in `buildBpmnXml` (emits `id/version/schemaVersion/title/description/tier_default`; see fixture) | add `uuid` attr here |
| Import parses `workflowMeta` | `adoptImportedXml` (`7982` keys off `loaded.workflowMeta.id`) | read `uuid`; backfill if absent |
| `saveToProject` builds bytes, guards pristine seed | `7434-7455` | `id = state.workflowMeta.id` `7440` |
| `_seedBpmn = buildBpmnXml(state)` pristine baseline | `8781` (captured at end of Init, before `autoLoadStored()` `8782`) | **PL-022 trap — see below** |
| localStorage autosave arms after Init | `_appReady` `8781`, `autoLoadStored()` `8782` | minted uuid must autosave |

---

## Implementation steps (execution order on GO)

### 1. Mint helper + seed uuid at Init (BEFORE `_seedBpmn` capture)
- Add `function mintUuid(){ return crypto.randomUUID(); }` (guard: `crypto.randomUUID` exists in all
  target browsers; the designer is already localhost/HTTPS-gated so `crypto` is present).
- In Init, ensure `state.workflowMeta.uuid` is set for the seed **before line `8781`**
  (`const _seedBpmn = buildBpmnXml(state)`). This is the crux (see PL-022 trap): `_seedBpmn` must be
  captured *with* the uuid already present, or a genuinely-unedited seed will no longer byte-match
  `_seedBpmn` and the T-141 guard misfires.
- Per-session-random seed uuid is fine: `_seedBpmn` is captured fresh each session and compared
  within the same session, so the guard stays correct.

### 2. Persist in state + autosave
- `workflowMeta.uuid` rides `state`, so the existing localStorage autosave (armed at `_appReady`)
  and `saveActiveToLibrary()` (`2093`) carry it with no extra work. Verify `autoLoadStored()` (`8782`)
  round-trips it (it serializes `state`, so it will).

### 3. Export — add `uuid` to `<aef:workflowMeta>`
- In `buildBpmnXml`'s process-header emit, add `uuid="${escAttr(state.workflowMeta.uuid)}"` to the
  `<aef:workflowMeta …>` attribute list. Additive — no other attr changes. (Node-level export at
  `8130-8160` is untouched; uuid is process-level identity.)

### 4. Import — read + lazy backfill
- In `adoptImportedXml`, read `uuid` off the parsed `<aef:workflowMeta>`; if absent (legacy map),
  `loaded.workflowMeta.uuid = mintUuid()` — one-time backfill.
- **Backfill must NOT mark the map dirty** (PL-022 corollary): the "diverged from loaded snapshot"
  / unsaved-changes signal must treat a first-time uuid backfill as clean, else opening any legacy
  map nags "unsaved changes." Implement by computing the dirty/loaded-snapshot comparison over bytes
  with `uuid` normalized out (or set a `_uuidBackfilled` flag the dirty-check ignores). Saving a
  backfilled map then writes the uuid — a legitimate, advisory one-time migration.

### 5. Rename — leave uuid immutable
- `renameActiveWorkflow` (`2211`) already only touches `workflowMeta.id` + library key + pool name.
  **Add nothing that touches `uuid`.** Add an assertion/comment that uuid is invariant across rename;
  a test locks it (AC below).

### 6. Import collision (`7982-7990`)
- Collision resolution keys off slug (`while library.has(key)`) — unchanged. Two maps with the same
  slug still get `_v2` suffix; their uuids are already distinct (each minted independently). No change
  needed, but a test asserts two imports of the same slug keep distinct uuids.

---

## Acceptance Criteria (for the S1 BUILD task, drafted here)
- [ ] A new/seed workflow has `workflowMeta.uuid` (v4) set before `_seedBpmn` capture; the T-141
      pristine-seed guard still fires correctly (unedited seed → save prompts; edited → saves silently).
- [ ] Export emits `<aef:workflowMeta … uuid="<v4>" …>`; re-import → same uuid (round-trip stable).
- [ ] Rename changes slug (`workflowMeta.id`) but `uuid` is byte-identical before/after.
- [ ] Legacy map (no `uuid` on import) mints exactly once; opening it does NOT mark it dirty / nag
      unsaved changes; saving then persists the uuid.
- [ ] Two imports of the same slug resolve to distinct library keys AND distinct uuids.
- [ ] `tools/validate-workflow.py` still clean on a `uuid`-bearing map (validator ignores unknown
      `aef:workflowMeta` attrs — confirm; the T-219 fixture already carries extra attrs cleanly).

## Test plan
- CDP/editor harness (T-103 substrate): new-map uuid presence; export→import round-trip; rename-holds-uuid;
  legacy-backfill-not-dirty; same-slug-distinct-uuid.
- `tools/validate-workflow.py` on an exported uuid-map → exit 0.
- Bridge parity: if the bridge parses `workflowMeta`, extend `test_editor_bridge_meta_parity.py` so
  editor-export and bridge-read agree on `uuid` (PL-005 drift guard).

## Risks / notes
- **PL-022 (baseline-snapshot trap)** — steps 1 & 4 are the whole point: mint before baseline capture;
  exclude backfill from the dirty check. Get these wrong and the editor nags on every legacy open.
- **PL-002 (namespace drift)** — `uuid` rides the existing `aef:` namespace; no new ns.
- **PL-005 (editor/bridge drift)** — covered by the bridge-parity test above.
- **Blast radius:** contained to `workflowMeta` field + export/import + Init + one dirty-check tweak.
  No library re-key. This is the smallest change that gives connectors a rename-stable identity.

## Handoff
On GO: create the S1 build task with the ACs above, execute steps 1–6, run the test plan, then S2
(`workflowRef` serialization) can begin — it references the uuids this slice mints.
