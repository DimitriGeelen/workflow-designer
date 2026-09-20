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

---

## Measured against the corpus — 2026-09-20

Everything above this line was written from prior-session recollection of the data model. This
section is the first time the design space has been checked against the files the browser
actually lists. Three of the four candidate grouping keys do not survive it.

### The population

| | count | note |
|---|---|---|
| corpus baselines (`examples/aef-processes/rendered/*.bpmn`) | 24 | |
| user-saved (`.editor-versions/*/`, excluding `_rendered`/`_trash`) | 24 | |
| **cards the browser shows** | **48** | |
| ids present in BOTH classes | **15** | shown twice, once per source class |
| **distinct logical workflows** | **33** | |
| corpus-only | 9 | |
| saved-only | 9 | of which **7 are test scaffolding** — `claim-smoke-{legacy,ref,ref2,target,target2}`, `s4-e2e-probe`, `t229-birth-probe` |
| deepest version history | 24 versions on one map | |

### What the measurement kills

**IW-1(c) — handoff-graph clusters: DEAD, no data.** The seed text above asserts that handoff
nodes carry `aef.targetWorkflow`, "giving an implicit cross-workflow graph". That graph does not
exist in this corpus. `targetWorkflow` appears in **0 of 24** rendered files; `linkEvent` appears
in **0 of 24**. There is nothing to cluster. (The attribute is real — `aef:` extension attributes
in the corpus are `anchors, artifactsWrites, decisionInput, decisionOutputs, endpoint, io,
laneMeta, meta, output, position, routingHint, uid` — `targetWorkflow` is simply not among them,
because no corpus map uses an off-page handoff.)

**IW-1(b) — id naming convention: DEAD, no hierarchy.** Splitting all 48 ids on the first `-`/`_`
yields one prefix with 5 members (`claim`, i.e. the smoke probes), and everything else at 1 or 2.
Grouping on it produces ~20 groups over 48 items — strictly worse to browse than the flat grid.

**IW-2 — tree vs. grouped sections: the tree has nothing to be deep about.** With key (c) and (b)
gone, the only grouping key backed by data is source class, which has exactly **two** values. A
tree control over a two-valued key is a section header with extra machinery.

### What the measurement surfaces instead

**The browser's problem is not depth. It is duplication.** 48 cards over 33 distinct workflows:
15 workflows are listed twice, once as corpus baseline and once as the user's saved edit of that
same workflow. Nearly a third of the grid is the same thing shown twice under two labels. A
hierarchical tree over 48 items does not fix that — it nests it. Merging each duplicate pair into
one card that carries both a source badge and the saved-version history removes 15 cards outright
and answers the question the operator was actually reaching for ("I cannot find my workflow")
more directly than any grouping key does.

That change needs no new metadata (IW-3 answers itself: **no**), no storage-model decision, and no
tree control. It is a rendering change in `openProjectModal` over data the browser already holds.

### Revised recommendation

**NO-GO on hierarchical tree grouping as scoped.** The corpus cannot support the feature: two of
three data-derived grouping keys have no data, and the third is two-valued. Building a tree here
would be building a control for a hierarchy the corpus does not contain.

**Named successor, for the operator to rule on:** one bounded build task — *"deduplicate
`openProjectModal`: one card per distinct workflow id, with a source badge (corpus / saved /
both) and the saved-version history under it"*. Everything it needs is already in the browser's
data model. Cost estimate: **S** — single file (`src/aef-workflow-designer.html`), one render
path, no schema change, no persisted metadata, no new save path. Mandatory visual verification per
CLAUDE.md (element screenshots of `openProjectModal` across theme and density modes), which is the
majority of its cost, not the logic.

If the operator wants explicit user-assigned folders (IW-1(d)) that remains a separate, larger
initiative with its own inception on the storage model — unchanged from the assessment above.

## Dialogue Log (continued)

- 2026-09-20 — Revisit fired 2026-08-21 and was 30 days overdue. Measured the corpus for the first
  time rather than re-reading the survey. Outcome: the preliminary recommendation above (A1+B1+C1)
  survives in spirit — source class, sections, no new storage — but the *premise* of the task, that
  a hierarchy exists to expose, does not. Recommendation moved from DEFER-pending-operator-input to
  a NO-GO with a named cheaper successor, so the operator rules on a concrete alternative rather
  than being asked to supply the exploration. No operator dialogue yet; no UI built.
