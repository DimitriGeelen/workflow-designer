# T-220 — Off-page seam editor build: decomposition & readiness plan

**Type:** design (readiness plan) · **Arc:** designer-authoring-surface · **Status:** design-only
**Gate:** This plan is **NOT authorization to build.** The editor build is gated on the operator's
go/no-go at `/inception/T-218` (Tier 0, human-only). This document decomposes that build into
independently-shippable slices so that, when GO lands, work starts immediately with real ACs and no
re-scoping. No source edits to the editor happen under this task — the deliverable is this plan.

**Grounding:** contract v0 (ratified both sides, rail offsets 107–111), the three ghost-drop rules
(offset 113), and AEF's live half (S1–S5 shipped, offset 112). See
`docs/reports/T-218-offpage-connector-pairing.md` and `[[aef-integration-rail]]`.

---

## What GO authorizes (scope fence)

The build makes 832's designer speak the ratified off-page connector seam:
1. **uuid identity model** — a stable per-workflow uuid as primary key (today identity IS the slug).
2. **`workflowRef` serialization** — connectors pin the uuid, not just the display name.
3. **claim picker** — "create from pending ref" UX + `fw bpmn claim <uuid> <project>` CLI backstop.
4. **`/api/list` extension + registry twin** — additive `maps[].uuid` + top-level `ghosts[]`, backed
   by a STORE-side `.context/designer/registry.yaml`.
5. **gallery ghost cards** — unresolved refs render as GHOST entries.

**Explicitly OUT (this arc):** any change to AEF's compile/store half (shipped, live), the validator
vocabulary (no new W-code needed — `workflowRef` already validates clean, confirmed T-219), and the
link-event *pairing* check (IW-2, separate disposition — not part of the seam build).

---

## Current state (verified anchors, 2026-07-21)

| Concern | Today | File:line |
|---------|-------|-----------|
| Workflow identity | slug/name only, no uuid | `src/aef-workflow-designer.html:2080` (`nextId=100`), `:2211` (`renameActiveWorkflow` slugifies) |
| Connector serialize | `<aef:link targetWorkflow=".." linkId=".."/>` | `src/aef-workflow-designer.html:8158` |
| Connector fields | `linkEvent*: ['targetWorkflow','linkId']` | `:1685-1686` |
| Import disambiguation | branches on `aef:link` vs `aef:eventDef` | `:8108` (`adoptImportedXml`) |
| Ref picker | `workflowPicker` special field reads `/api/list` | `:5057-5091`, field def `:1721` |
| Jump-to-ref | `jumpToWorkflow(id)` resolves "three ways" | `:6728`, wired `:6759` |
| `/api/list` server | `gallery-serve.py`, shape `{maps:[{id,title,sources,latest,openTarget}]}` | `tools/gallery-serve.py:242`, doc `:28` |
| Registry | **does not exist yet** | — (`.context/designer/registry.yaml` is new) |

**Reassurance:** most scaffolding exists. The genuinely-new piece is the **uuid identity model** (S1) —
everything else layers on top of picker/jump/`/api/list` machinery that already ships.

---

## Slice decomposition (4 slices + 1 cross-cutting guard)

Ordered by dependency. Each is independently shippable and independently verifiable.

### S1 — uuid identity model  *(the foundation; largest, highest-risk)*
Thread a stable uuid as the workflow primary key through the editor.
- **Mint:** draw-time via `crypto.randomUUID()` on new-workflow / first-save; **no store write-back**
  (identity decided where intent is expressed — ratified Q2).
- **Persist:** uuid in `aef:workflowMeta` (new attr, additive). Load reads it; absent → mint-on-load
  once, then it's sticky. Rename (`:2211`) changes display name only — uuid is immutable (name→display).
- **Collision/threading:** uuid survives save/load/rename; slug remains the human-facing handle.
- **Deliverable ACs (sketch):** new map gets a uuid; save→load round-trips it byte-stable; rename
  preserves uuid; a legacy map (no uuid) mints exactly once and is stable thereafter.
- **Risk:** identity-model change touches save/load/rename/collision paths. PL-002 (namespace drift)
  and PL-005 (editor/bridge serialization drift) both bite here — the parity guard (S5) is the counter.
- **Depends on:** nothing. **Blocks:** S2, S3, S4.

### S2 — `workflowRef` connector serialization
Make connectors pin the uuid, keeping `linkId` orthogonal (intra-diagram pairing) and `targetWorkflow`
as a back-compat alias.
- **Fields:** extend `AEF_FIELDS` link events (`:1685-6`) → `['workflowRef','name','targetWorkflow','linkId']`.
- **Export (`:8158`):** emit `<aef:link workflowRef=".." name=".." linkId=".."/>`; keep `targetWorkflow`
  only when no `workflowRef` (legacy leg). **Preserve the two axes** — `workflowRef` ⊥ `linkId`.
- **Import (`adoptImportedXml`, `:8108`):** read `workflowRef`; **alias** `targetWorkflow`→`workflowRef`
  on load so old maps resolve (ratified). Migrate-advisory, not silent rewrite.
- **Conformance anchor:** the T-219 byte-fixture (`tests/fixtures/aef-bpmn/offpage-seam.bpmn`) is the
  exemplar — all three legs (resolved `workflowRef` / ghost `workflowRef` / legacy `targetWorkflow`) must
  round-trip through export identically to the pinned bytes.
- **Depends on:** S1 (needs uuids to reference). **Blocks:** S4 (claim writes `workflowRef`).

### S3 — `/api/list` extension + registry twin
Additive server changes in `gallery-serve.py`, plus the STORE-side registry.
- **`/api/list` (`:242`):** add `maps[].uuid`; add NEW top-level `ghosts[]:[{uuid,name,referenced_by:
  [{id,node,nodeName}],task,first_seen}]`. Additive-only — existing `maps[]` shape unchanged (AEF
  confirmed offset 113: "No /api/list shape change — behavior-only" on *their* side; 832's is the additive extension).
- **Registry:** `.context/designer/registry.yaml` = `{ghosts:[], claims:[]}`, atomic YAML write.
- **Ghost-DROP rules at sync (mirror AEF offset 113 exactly):**
  1. DROP when `referenced_by` empty AND no doc task minted.
  2. KEEP when `referenced_by` empty but task set AND named target still doesn't exist (deleted-connector debt stays visible).
  3. **NEW:** DROP when `referenced_by` empty AND ghost name matches a live store slug **even with a task minted** (closes the stale-needs-mapping-card-forever failure mode). uuid-pinned (`workflowRef`) ghosts unaffected — exit only via explicit claim.
- **Depends on:** S1 (uuid in map records). **Blocks:** S4 (picker reads ghosts[]), S5-gallery.

### S4 — claim UX (picker + CLI)
- **Picker:** extend `workflowPicker` (`:5057`) with a "create from pending ref" affordance — selecting
  an unresolved `ghosts[]` entry mints a new workflow claiming that uuid.
- **CLI backstop:** `fw bpmn claim <uuid> <project>` — moves a ghost→claim in the registry.
- **Name-match:** suggest-only, **never silent** (ratified). Claim refuses a *different* uuid
  (structural enforcement AEF confirmed offset 111 — claim-refuses-different-uuid / setdefault).
- **Depends on:** S2 + S3.

### S5 — cross-cutting: parity guard + gallery ghost cards
- **Parity guard (PL-005, PL-030):** editor-export ↔ bridge-import conformance on the *full* `aef:link`
  field set (`workflowRef`, `name`, `targetWorkflow`, `linkId`), anchored on the T-219 byte-fixture.
  PL-030 warns: aspect-by-aspect guards can *all* pass while a real gap survives — so the guard asserts
  round-trip byte-equality on the shared fixture, not per-field presence.
- **Gallery ghost cards:** render `ghosts[]` as GHOST entries (visually distinct from live maps).
- **Depends on:** S2, S3. Runs alongside/after.

---

## Dependency graph

```
S1 (uuid identity) ──┬──> S2 (workflowRef serialize) ──┐
                     │                                  ├──> S4 (claim UX)
                     └──> S3 (/api/list + registry) ────┤
                                                        └──> S5 (parity guard + ghost cards)
```

Critical path: **S1 → S2 → S4**. S3 parallels S2 after S1. S5 closes.

---

## Cross-cutting risks (from related-knowledge PL-hits)

- **PL-005 / PL-002 — editor/bridge & namespace drift:** any `aef:` serialization change can silently
  diverge editor (JS) from bridge (Python). *Counter:* S5 parity guard + the T-219 pinned byte-fixture as
  the single shared conformance anchor.
- **PL-030 — seam guards passing while a gap survives:** don't ship per-field presence checks; assert
  round-trip byte-equality on the fixture.
- **PL-022 — baseline-snapshot traps in "document unchanged?" guards:** S1's mint-on-load-once must not
  dirty a pristine loaded map (else every legacy open reports unsaved changes). Explicit guard needed.

---

## Still-open seam questions (carry into build)

- **Who serves the registry endpoint / where it lives relative to `gallery-serve.py`** — 832 proposed
  extending the existing `/api/list` (one server) rather than forking `/api/workflows`. Confirm final
  placement with AEF before S3.
- **The 7 `{id,uuid}` pairs** (rail offset 114 request) — needed to finalize T-219's resolved leg; not a
  build blocker but the fixture that anchors S2/S5 conformance depends on it.

---

## Readiness checklist (what makes the GO instantaneous)

- [x] Current-state anchors verified (this doc).
- [x] Slices defined with dependencies, deliverable-AC sketches, and risk notes.
- [x] Conformance anchor identified (T-219 byte-fixture).
- [x] Ghost-drop rules captured for the registry twin (3 rules, mirror AEF offset 113).
- [ ] On GO: spin S1–S5 as separate build tasks (one deliverable each, per Task Sizing Rules), each with
      real ACs + a `## Verification` block; do **not** build under T-218's inception id.
- [ ] Resolve the two open seam questions (registry placement; `{id,uuid}` pairs) before S3/S2 finalize.
