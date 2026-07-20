# T-218 — Off-page connector (link-event) pairing in AEF-captured processes

**Type:** inception (exploration) · **Recommendation:** DEFER (await AEF's captured artifacts + concrete ask)
**Arc:** designer-authoring-surface · **Trigger:** operator observed off-page connectors "not connected" in AEF-captured processes; AEF expected to make rail contact.

## Problem statement

The AEF agent reverse-discovered / captured a number of processes. In the resulting maps,
the operator reports the **off-page connectors are "not connected."** This inception
establishes what 832's dialect/designer currently does with off-page connectors so that,
when AEF contacts the rail with the actual artifacts, the gap is already understood and a
fix task can be scoped fast. **No fix is built here** (G-020 — a heads-up is not a build
instruction; the concrete ask is AEF's to bring).

## What 832 already supports (read-only survey)

Off-page connectors ARE first-class in 832's dialect — they are BPMN **link events**:

- **Dialect / validator** (`tools/validate-workflow.py`): `linkEventThrow` and
  `linkEventCatch` are allowed node types (lines 54-55). In the reachability check a
  `linkEventCatch` is seeded as a cross-workflow **entry** and a `linkEventThrow` as a
  cross-workflow **terminus** (lines 506-580) — so a lone throw/catch does NOT trip
  `W-XML-UNREACHABLE` / `W-XML-DEADEND`.
- **Designer** (`src/aef-workflow-designer.html`): palette items (1193, 1205); node specs
  36×36 in the framework lane (1659-1660); rendered as a hollow circle with a chevron,
  throw filled / catch hollow (2527-2531); connection rules `linkEventThrow {in:true,
  out:false}`, `linkEventCatch {in:false, out:true}` (1762-1763).
- **Pairing field:** both carry `['targetWorkflow', 'linkId']` (1685-1686). The pair is
  logical: a throw with `linkId="X"` corresponds to a catch with `linkId="X"` (optionally
  in another workflow via `targetWorkflow`).
- **Lane-band geometry** (`tools/check-lane-bands.py`): both sized 36×36 (43-44).

## The likely gap (hypothesis, to confirm against AEF's artifacts)

Off-page connectors by definition have **no drawn edge** between throw and catch — that is
correct BPMN (a link event replaces a long/cross-page connector with a named throw/catch
pair). So "not connected" is one of two things:

1. **Expected-behavior misread** — the operator sees throw/catch glyphs with no line and
   reads it as broken, but the pairing is by `linkId`, not by a drawn edge. If so, the ask
   is a **designer affordance** (highlight the matching throw/catch, show/echo the shared
   `linkId`, click-to-jump between paired ends).
2. **A real orphan/pairing defect in capture** — AEF's reverse-discovery emits throws
   and/or catches whose `linkId` / `targetWorkflow` values do NOT line up (orphaned throw
   with no catch, mismatched ids, or a dangling `targetWorkflow`). **This would pass the
   validator clean today** — there is **no throw↔catch pairing / orphaned-link check**
   (confirmed: the validator only seeds reachability from links; it never asserts every
   `linkEventThrow` has a matching `linkEventCatch` by `linkId`, nor that ids are
   consistent, nor that `targetWorkflow` resolves). That is the structural blind spot: a
   captured map with unpaired links looks disconnected and nothing flags it.

Most probable: **(2)** — capture is where mismatched/orphaned link ids would be introduced,
and the absence of a pairing check is exactly the kind of validator blindness this arc keeps
surfacing. AEF's actual artifacts will disambiguate (orphaned? mismatched id? dangling
targetWorkflow?).

## If confirmed, candidate 832-side work (NOT started — for scoping when AEF contacts)

- **Validator:** add a link-event pairing check — e.g. `W-LINK-ORPHAN` (a `linkEventThrow`
  with no `linkEventCatch` sharing its `linkId` in the same workflow, absent a
  `targetWorkflow` cross-ref) and/or `W-LINK-DUP` (two catches for one `linkId`). Mirrors
  the existing `W-PGW-UNBALANCED` fork/join "must pair" pattern.
- **Designer:** paired-link affordance (shared-`linkId` highlight / jump), so a correctly
  paired off-page connector reads as connected to the operator.
- **Boundary reality (T-559):** if this becomes a shared contract, it wants a byte-identical
  fixture + pinned sha per the pair-draft loop; 832 owns the validator vocabulary.

## Decision

DEFER the fix until AEF makes rail contact with the captured artifacts and their concrete
ask. This inception has established the current-state understanding; a build/design task
spins out of AEF's specifics (which of (1)/(2), and whether it's validator, designer, or
both).

## AEF seam proposal (rail offset 107, AEF T-2571) + 832 positions

AEF made contact with a full **seam proposal** (operator-steered on the AEF side). Their
DECIDED half: immutable **uuid** per workflow in meta.json (name→display-only); connectors
pin the uuid; a pending-ref **registry** (`.context/designer/registry.yaml`) with unresolved
refs rendered as **GHOST** gallery entries; first sighting of a dangling ref **mints a
documentation task** (owner:human, captured, horizon later, idempotent per uuid). Proposed
832 half + three questions, with 832's grounded positions:

**Reassurance from the code survey — most of this already exists in 832:**
- Connectors already serialize as `<aef:link targetWorkflow="…" linkId="…"/>`
  (aef-workflow-designer.html:8158); import disambiguates on `aef:link` (8108).
- `workflowPicker` special field already consumes `/api/list` (5057-5091);
  `jumpToWorkflow` resolves a ref "three ways and opens" (6726-6759).
- `gallery-serve.py` already serves `/api/list` → `{maps:[{id,title,sources,latest…}]}`.
- BUT identity today IS the slug/name (`renameActiveWorkflow` slugifies, 2211-2219; nodes
  use a `nextId` counter, 2080) — no uuid. That is precisely the "name-only" gap.

**Q1 — `workflowRef` on `aef:link`, or a new `aef:offPageRef` element?**
→ **Extend the existing `<aef:link>`**; do NOT mint a new element. Additive-vocab discipline;
the pipeline already branches on `aef:link`. Proposed shape:
`<aef:link workflowRef="<uuid>" name="<display>" linkId="<intra-diagram pairing>"/>`.
Preserve TWO distinct axes — `workflowRef` = cross-workflow uuid (AEF's focus) vs `linkId` =
intra-diagram throw↔catch pairing (a separate concern 832 already models; don't collapse
them). Renaming `targetWorkflow`→`workflowRef` is fine with a back-compat import alias.

**Q2 — draw-time uuid minting in the editor, or store-mints-on-save (write-back)?**
→ **Accept draw-time minting in the editor.** Fits 832's architecture (editor is the
authoring surface) and avoids a store write-back channel (less coupling; identity decided
where intent is expressed). `crypto.randomUUID()` makes minting trivial. FLAG: today there
is no uuid at all — workflow identity is the slug — so this is a real identity-model addition
(uuid as primary key threaded through save/load/rename/collision + /api), the largest piece.

**Q3 — "create from pending ref" picker feasible in 0.x line? want the API contract now?**
→ **Feasible** — the `workflowPicker` + `jumpToWorkflow` scaffolding already reads `/api/list`.
**Yes, send the contract** so I can design against it — but **don't fork a second endpoint**:
extend the existing `/api/list` (already consumed by the picker) with `{uuid, status:
live|ghost, referenced_by}`, or have `/api/workflows` served by `gallery-serve.py` reading
`.context/designer/registry.yaml`, so the editor keeps talking to one server. Open seam-Q
back to AEF: who serves the endpoint, and where does the registry live relative to
gallery-serve.py? "create from pending ref" + `fw bpmn claim` CLI backstop both good; agree
no silent name-matching.

**Correction to AEF:** 832 is on **0.3.0** (T-200 shipped it), not the 0.2.x their Q3 assumed.

**Build gating:** this is editor-architecture-scope build (uuid identity + serialization +
picker + /api) → gated on operator go/no-go on this inception. The rail reply carries design
positions + a request for the contract; the BUILD lands on operator prioritization.

## Dialogue Log

- **2026-07-20 — operator heads-up (Dimitri):** "the off-page connectors in AEF are not
  connected; AEF agent captured a number of processes; expect the AEF agent to contact you
  for this." → Registered as this inception; read-only survey done.
- **2026-07-20 — AEF contact (rail offset 107, T-2571):** full seam proposal (above).
  Disambiguates IW-1 toward a real machine-linkage gap: off-page connectors are "name-only
  visuals — no machine link to the referenced workflow, and no capture when the referenced
  workflow doesn't exist yet." 832 positions on Q1-Q3 drafted; **held for operator steer
  before committing on the rail** (seam was operator-steered on the AEF side).
