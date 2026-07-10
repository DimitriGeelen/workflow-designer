# T-155 Inception — Hierarchical tree grouping for the Open-project map browser

**Status:** exploration (awaiting operator input on IW-1/IW-2, then GO/NO-GO/DEFER)
**Task:** T-155 (inception) · **Created:** 2026-07-10 · **Owner:** agent → decision: human

> C-001 thinking-trail artifact. Started before research; updated incrementally. The operator
> floated tree-grouping *tentatively*, so this inception surveys the design space and produces a
> recommendation for a go/no-go rather than building.

## Problem

`openProjectModal` renders every saved/corpus workflow as a **flat grid of cards**. As the number
of workflows grows this becomes hard to scan. The operator floated reorganizing it into a
**hierarchical / tree-style grouping**. Question: what grouping, what UI, and does it need new
stored metadata — or can it be derived from what we already have?

## What data we already have (candidate grouping keys)

From this session's work on the browser (`/api/list`, versions, delete), each "map" carries:

| Signal | Source | Grouping potential |
|--------|--------|--------------------|
| **Source class** — corpus baseline vs user-saved | corpus = `examples/aef-processes/rendered/<id>.bpmn`; saved = `.editor-versions/<id>/` | Cheap, obvious top-level split ("Shipped examples" vs "My workflows"). Zero storage change. |
| **id / naming convention** | the id string (e.g. `arc-*`, `frw_*`, `hum_*`) | Prefix-based buckets. Cheap, but relies on naming discipline; ids aren't a deliberate taxonomy. |
| **Handoff graph** | `linkEventThrow`/`linkEventCatch` nodes carry `aef.targetWorkflow` | Cluster workflows that link to each other. Semantically rich, but requires parsing every map's bpmn to build the graph (cost) and clusters may be non-obvious to the user. |
| **Explicit folder/tag** | *does not exist yet* — would need a new metadata field | Most flexible & user-controlled, but requires: a metadata field, a save/serialize round-trip, server support, and UI to assign. Largest build. |

## Design axes

### Axis A — grouping key (IW-1)
- **A1 Source class** (corpus vs saved) — trivial, high clarity, no storage.
- **A2 Id prefix** — cheap, derived; weak taxonomy.
- **A3 Handoff-graph clusters** — rich, derived, higher compute; UX legibility risk.
- **A4 Explicit folders/tags** — most powerful, but needs persisted metadata (schema + server + UI).

### Axis B — UI form (IW-2)
- **B1 Grouped sections** — one level of collapsible headers over the *existing* card grid. Small,
  additive change to `openProjectModal`. Delivers most of the "scannability" win.
- **B2 Full tree** — arbitrary-depth expandable tree (folders within folders). Much larger build;
  only justified if A4 (explicit nested folders) is chosen.
- **B3 Sidebar filter + flat grid** — a facet/filter rail (by source, by prefix) that narrows the
  existing grid. Cheap, familiar, avoids a tree entirely.

### Axis C — storage (IW-3)
- **C1 Derive-only** — grouping computed from existing data (source/id/handoff). No schema change,
  no round-trip risk. Compatible with A1/A2/A3 + B1/B3.
- **C2 Persisted metadata** — new folder/tag field per workflow, round-tripped through save +
  server. Required only for A4/B2. Touches the serialization round-trip guard (G-002) and the
  server `/api/save`/`/api/list` — a meaningfully larger, riskier change.

## Preliminary recommendation (to confirm with operator)

**Lean: A1 (source class) + optionally A2 (id prefix) as a second level, rendered as B1 (grouped
collapsible sections) over the existing grid, C1 (derive-only, zero storage change).**

Rationale:
- Delivers the scannability win (the actual pain) at a fraction of the cost of a full tree.
- No serialization/server changes → no round-trip risk, no new failure surface (Reliability).
- Purely additive to `openProjectModal`; reuses the existing card renderer, hover-zoom, delete, etc.
- Leaves the door open: if the operator later wants true user-defined folders (A4/B2/C2), that is a
  separate, larger initiative filed as its own task(s) after seeing B1 in use.

**Explicitly NOT recommended now:** A4 + B2 + C2 (user-defined nested folders with persisted
metadata) as a first step — it is a subsystem-scale change (schema + round-trip + server + UI) for
a feature the operator only floated tentatively. Ship the cheap derived grouping first; let real
use tell us whether explicit folders are worth the storage complexity.

## Open Questions (mirror of task ## Open Questions)

- **IW-1 grouping key** → recommend A1 (+maybe A2). *Needs operator confirmation.*
- **IW-2 UI form** → recommend B1 (grouped sections). *Needs operator confirmation.*
- **IW-3 storage** → recommend C1 (derive-only). Strongly preferred; avoids schema/round-trip.

## Proposed decision

**DEFER pending operator input on IW-1/IW-2.** Once confirmed (expected: A1+B1+C1), this is a
small, bounded build — file it as one build task ("grouped sections in openProjectModal, derived
from source class"), not a subsystem redesign. If the operator instead wants A4/B2/C2 (explicit
folders), treat that as a separate larger initiative with its own inception on the storage model.

## Dialogue Log

- 2026-07-10 — Inception created (converted from a parked build task). Operator directive was the
  standing "proceed as seen fit … focus on browsing/storage/retrieval of versions." Artifact seeded
  from prior-session knowledge of the browser's data model; no operator dialogue yet. Next step:
  present this survey + recommendation for a GO/NO-GO/scope decision.
