# EVALUATION — AEF Process-layer proposal package (v1, 2026-07-02)

```yaml
evaluated: 2026-07-02
evaluator: product agent (832-Workflow-designer), task T-019
package: aef-workflow-process-layer-package-v1-2026-07-02
disposition: STORED + EVALUATED. Not authorization. No implementation performed.
```

## 1. What this package is

An inbound design bundle proposing the **AEF Process layer** as the *third
foundational core concept* of the framework:

1. **Governance** — structurally enforced authority (who may do what)
2. **Value** — deterministic value models / BVP (what is worth doing)
3. **Process** — explicit, typed, machine-readable representation of *how work
   flows* — simultaneously a design substrate (P1), a documentation system (P2),
   the procedural half of governance (P3), and the crystallization medium for
   stochastic→deterministic migration (P4)

It turns our Workflow Designer prototype into a governed framework subsystem.
Concretely it specifies:

- **Schema v3** — YAML-canonical (BPMN XML demoted to derived interchange);
  adds `workflow.status`/`ratified_by`, `execution.mode` (advisory/guided/
  strict), a new `callActivity` node type (10-element subset), a
  `humanTouchpoint` block on `userTask`, and optional `aef.components` Component
  Fabric refs.
- **`fw workflow` verb family** — `validate | list | show | export | import |
  ratify | deprecate | render --lens | bind | advance`.
- **Workflow Fabric** (SD-15) — a queryable process-dependency graph, peer to
  the Component Fabric (edge types: flow, call, handoff, component, path,
  inferred-dataflow).
- **Enforcement ladder** — advisory → guided → strict; guided (framework-
  validated transitions) is the arc's structural-guardrail target.
- **6-lock build plan** (schema+judge → interchange → governance lifecycle →
  fabric+contracts → dogfood → guided-mode), each ending in a Sovereign
  checkpoint.
- **Sovereign decision register** — SD-1..SD-15 (incl. WF-A..E).

## 2. Package contents & provenance

Stored intact alongside this note:

| File | What |
|---|---|
| `aef-workflow-process-layer-package-v1-2026-07-02.zip` | immutable received bundle (prototype HTML, its 4 docs, `tests/roundtrip.js`, both notes) |
| `INSTRUCTIONS-workflow-process-layer-2026-07-02.md` (r3) | THE specification — authoritative for forward work |
| `INGESTION-workflow-process-layer-2026-07-02.md` | entry point / reading order |

**Delta vs this repo (evidence gathered at ingest):**

- The bundled `prototype/aef-workflow-designer.html` is **byte-identical** to our
  `src/aef-workflow-designer.html`. The package's prototype *is* our designer.
- The four bundled docs are our `docs/designer/*` docs plus an **additive
  "VERSION NOTE" banner** (marking them prototype-v2, superseded by the v3 spec).
  No content was removed (bundle is +6/+2/+2/+19 lines, −0). They are annotated
  copies, not divergent forks.
- `tests/roundtrip.js` (BPMN round-trip smoke test, 14 nodes/16 edges, uid +
  position preservation) is **not otherwise present** in our repo — the zip is
  its only home here.

## 3. Governance status — READ THIS FIRST

**This package is a PROPOSAL, not authorization.** Its own binding notes and
CLAUDE.md §Pickup-Message-Handling (G-020) both say so:

- **ALL of SD-1..SD-15 (incl. WF-A..E) are OPEN.** Every disposition in the
  register is a *design-agent proposal*; none is Sovereign-ratified.
- "Research is not authorization." The package authorizes only **Step 0**
  (read-only discovery, Q1–Q10) and **Step 0.5** (a paper exercise:
  hand-authoring `inception-lifecycle.workflow.yaml` against the draft v3
  schema) — and only **upon Sovereign dispatch**, performed by the **framework
  agent**, in the framework repo.
- Explicitly NOT authorized by the package: schema implementation,
  `lib/workflow.sh`, any `fw` verb, repo restructuring, doc migration, prototype
  modification.

**Audience mismatch to note:** the package is addressed to "framework agent
(Claude Code) + Sovereign." Its implementation targets (`lib/workflow.sh`, `fw`
verbs, `docs/process-layer.md`, `workflows/`) live in the **AEF framework**
(`/opt/999-Agentic-Engineering-Framework`), not in this product repo. This repo
(832-Workflow-designer) owns the **prototype/designer** the spec consumes, plus
the standalone validator (§4). Forward Process-layer work is a framework-agent
arc, gated on Sovereign dispatch — not something this product agent initiates.

## 4. Relationship to this product and to recent work (T-002, T-017, T-018)

The proposal strongly **corroborates** the product's current direction:

- **§2.1 "YAML canonical, BPMN demoted to derived import/export"** is exactly the
  T-002 GO architectural baseline and the split we built in T-017 (YAML
  validator) / T-018 (BPMN-XML validator).
- **§2.4 "Validation rules (the judge's contract)" / `fw workflow validate`** is
  precisely the judge our T-017/T-018 `tools/validate-workflow.py` already
  implements for the v2 schema. Our validator is a working, tested (24/24)
  reference for the Lock 1 judge — the "producer-not-judge" separation the
  package insists on (§V6) is already realized in this repo.

**Gap analysis — what schema v3 adds that our v2 validator does not yet cover**
(useful if/when the Sovereign dispatches Lock 1; not a work list for now):

- `execution.mode` gating rules (guided/strict require all userTasks carry
  `humanTouchpoint`, all serviceTasks carry `tier`)
- `callActivity` node type + resolution/acyclicity + `ioMapping` contracts
- `humanTouchpoint.decisions` ↔ outgoing-edge-name coverage
- link-event type agreement (throw inputs ↔ catch outputs)
- `status`-dependent drift semantics (warning on proposed, drift-report-not-error
  on ratified) and `aef.components` resolution
- startEvent-no-incoming / endEvent-no-outgoing structural rules
- repo-wide (cross-file) uid uniqueness

Our validator covers the v2 core (uid/lane/edge/gateway/authority/required-field
rules + I/O upstream heuristic) in both YAML and BPMN-XML forms.

## 5. What was done under T-019 (and the boundary)

**Done:** ingested and read the package; gathered the delta evidence above;
stored the bundle durably under `docs/proposals/`; wrote this evaluation;
cleared the `1012-import/` staging inbox.

**NOT done (out of scope by the package's own gates and by G-020):** no Step 0
discovery, no Step 0.5 paper exercise, no schema v3, no `workflows/` directory,
no `lib/workflow.sh`, no `fw workflow` verb, no edits to `src/` or
`docs/designer/`, no SD dispositions. None of these are authorized here.

## 6. Recommended Sovereign next actions

1. **Confirm SD-1 / SD-2** — is Process genuinely the third foundational concept,
   and its own layer vs cross-cutting? Everything downstream gates on this.
2. **Route the arc to the framework agent, not this product agent** — the
   implementation surface is the framework repo. If/when dispatched, the correct
   first move is Step 0 (read-only discovery, Q1–Q10) + Step 0.5 (paper
   exercise), returning deliverables for register disposition before Lock 1.
3. **Feed T-017/T-018 forward as the Lock 1 judge seed** — our tested v2
   validator is a concrete starting point; §4 lists the v3 rules to add.
4. **Leave SD-1..15 to explicit ratification** — do not let the detailed spec be
   mistaken for decisions (its register status is unambiguous: all OPEN).
```
