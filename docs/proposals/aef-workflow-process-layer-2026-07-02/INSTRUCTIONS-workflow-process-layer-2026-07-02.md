# INSTRUCTIONS-workflow-process-layer-2026-07-02.md

```yaml
status: proposed            # Sovereign ratification required before any implementation
authored: 2026-07-02
revised: 2026-07-02 (r3 — handover package: + P4 crystallization framing, Step 0.5 paper exercise, regression-pain dogfood catalog, Workflow Fabric §2.6/SD-15)
author: design-agent (Claude, chat context) with Sovereign (Dimitri)
consumes:
  - aef-workflow-designer.html (prototype, v2 schema, round-trip verified)
  - docs/aef-workflow-designer/{README,schema,user-guide,architecture}.md
supersedes: none
binding_notes:
  - Research is not authorization. Nothing in this document authorizes implementation.
  - Producer-not-judge applies throughout: the designer/generator never certifies its own output.
  - One lock at a time: design and ratify each lock before opening the next.
  - Discovery before design: Step 0 is read-only and must complete before Lock 1 design is finalized.
```

---

## 0. Purpose and framing

### 0.1 What this is

Productization of the AEF **Process layer**: the explicit, typed, composable,
machine-readable representation of how work flows.

The Process layer serves **three purposes**, in increasing order of ambition:

- **P1 — Design substrate.** The workflow surface is where flows are designed
  *functionally* (what the business process does and why), *logically*
  (sequencing, decisions, data contracts), and *technically* (endpoints,
  scripts, bindings). One governed artifact, three lenses; audiences get
  filtered views of the same source. This eliminates the classic three-document
  drift (business requirements vs design doc vs implementation) and puts the
  workflow at the core of the application development practice built on AEF.

- **P2 — Systematic documentation of business and application logic.** All AEF
  internal processes, and later all application processes built with AEF, are
  documented as validated, versioned, composable workflow definitions —
  replacing tribal knowledge and drift-prone prose.

- **P3 — Procedural guardrail for agent execution.** A workflow bounds an agent
  executing a business or technical procedure: which steps, in which order,
  which gateways require a human, what data contract each step satisfies, and
  what tier authority the agent holds *at that step*. This completes the
  governance symmetry:
  - verb gates = structural enforcement at the **action** level
  - workflows  = structural enforcement at the **procedure** level

  Workflow-scoped tier grants give the agent a precise, pre-ratified,
  auditable authority envelope ("tier 2 because you are at node agt_3 of
  ratified procedure refund-process") — contextual authority instead of
  blanket authority.

- **P4 — Crystallization medium for stochastic→deterministic migration.**
  Every process starts LLM-improvised (stochastic) and hardens toward
  deterministic execution. The workflow layer is what makes that hardening
  possible, visible, and irreversible:
  - *possible* — the enforcement ladder (§0.3): prose → advisory → guided →
    per-step hardening → strict
  - *visible* — the lane model encodes the frontier: hardening a step IS
    moving a node from the Agent lane (serviceTask, Initiative, stochastic)
    to the Framework lane (scriptTask, Authority, deterministic). The
    swimlane diagram is the stochastic/deterministic map; version history
    documents the trajectory. Candidate Measure-layer metric: determinism
    ratio = deterministic nodes / executable nodes, per process over time.
  - *irreversible* — ratified versions are the ratchet: no silent regression
    to prose-interpretation; changes are versioned and re-ratified.

  This addresses the observed failure mode directly: processes defined in
  prose are re-interpreted stochastically on every execution, so fixes
  (prompt patches) never lock in — the source of repeated regressions in
  inception routing, exception handling, task creation, tier-0 escalation,
  and knowledge leveling. In one sentence: **Governance made authority
  explicit; Value made priority explicit; Process makes the
  stochastic/deterministic boundary explicit and movable.**

The prototype (single-file HTML BPMN-subset designer) proved the
representation: two-identifier model, typed I/O contracts, lane-based
authority mapping, routing, off-page connectors, XML round-trip. This
instruction set turns the proof into a governed AEF subsystem.

### 0.2 The foundational claim (PENDING SOVEREIGN CONFIRMATION)

Working framing: Process is the **third foundational core concept** of AEF:

1. **Governance** — structurally enforced authority (who may do what)
2. **Value** — deterministic value models / BVP (what is worth doing)
3. **Process** — explicit typed representation of work flow (how work happens),
   which is simultaneously the design substrate (P1), the documentation system
   (P2), and the procedural half of governance (P3)

All three convert implicit/behavioral knowledge into explicit, structural,
machine-actionable artifacts.

Why the agent-era version of this can work where classic BPM/MDD failed:
model-driven development died in the model-to-execution gap (models drifted
from code; engines were too rigid for reality). With agents as executors, the
workflow specifies the *invariants* (order, gates, authority, contracts) and
the agent fills the judgment gaps within them. The model does not need to
specify everything to be enforceable.

### 0.3 Enforcement ladder (SD-8)

Workflows declare an execution mode; the framework provides machinery per rung:

| Mode | Meaning | Machinery | When |
|---|---|---|---|
| `advisory` | Agent reads workflow as guidance; nothing enforced | none (prompt-level) | day one, dogfood |
| `guided` | Framework tracks instance state; agent must request transitions; framework validates each against the definition; violations refused + audited | instance files + `fw workflow advance` | Lock 6 |
| `strict` | Framework drives execution node-by-node | `fw workflow run` | future arc (out of scope) |

Advisory alone is discipline, not structure, and is insufficient as an
endpoint. Guided mode is the minimal structural guardrail and the target of
this instruction set.

### 0.4 Success criteria (validation of intent)

- **V1 Agent-generation**: fresh agent + schema doc + prose description →
  ≥90% first-pass `fw workflow validate` success.
- **V2 Human-legibility**: unfamiliar reader answers process questions
  correctly from the rendered diagram.
- **V3 Round-trip**: YAML ↔ memory ↔ BPMN XML, identity-preserving.
- **V4 Dogfood coverage**: ≥5 core AEF processes documented and validated in
  the first arc (§5 catalog).
- **V5 Composition**: ≥1 real cross-workflow handoff pair AND ≥1 callActivity
  refinement validate end-to-end including type agreement.
- **V6 Judge separation**: `fw workflow validate` catches seeded defects the
  permissive editor allows.
- **V7 Guardrail (guided mode)**: an out-of-order `fw workflow advance`, a
  skipped human gateway, and an unmet input contract are each refused and land
  in the audit log.
- **V8 Business legibility**: the business-view rendering (technical fields
  filtered) lets a non-technical stakeholder answer what/who/when questions
  about the process correctly.
- **V9 Drift detection**: renaming/deleting a component referenced by a
  ratified workflow produces a drift report (not a validation failure);
  the same on a proposed workflow produces a validation warning.

---

## 1. Step 0 — Read-only discovery (framework agent, before any design)

Scope: READ-ONLY. No file creation, no fixes, no refactors. Produce
`DISCOVERY-workflow-process-layer-<date>.md` answering:

- **Q1**: Where do process-like definitions live today? (`agents/dispatch/*.md`
  templates, arc templates, `.tasks/templates/`, policy files.) Inventory with
  paths. What would workflows subsume vs coexist with?
- **Q2**: fw CLI conventions for a new verb family (inspect `lib/arc.sh`,
  verb-gate wiring, `--i-am-human`/`--from-watchtower` gate pattern, audit-log
  JSONL conventions, §ACD evidence-gate location for reuse).
- **Q3**: Machine-readable schema conventions (`policy/*.yaml` style, existing
  YAML validation approach, schema-version fields, validator dependency:
  yq/python/bats-tested bash?).
- **Q4**: `fw dispatch` resolution path today — exact call chain. What would
  "task follows workflow" touch? What is the natural home for a
  `workflow:` binding in task frontmatter? (SD-3/SD-10 grounding.)
- **Q5**: Cross-reference indexing today (Component Fabric `fw fabric deps`) —
  can the composition registry (linkId pairing + callActivity resolution +
  component reverse index) reuse it or must it be new? **Critical sub-question
  for SD-13: are fabric component IDs stable identifiers across scans, or
  derived-per-scan?** If unstable, workflow `components:` refs need paths or a
  stable-alias layer — report the ID scheme and its stability guarantees.
- **Q6**: Ratification machinery available for reuse (arc driver-decision
  gate, `--demo` close gate, `status:` frontmatter on handoffs). Which pattern
  fits workflow ratification?
- **Q7**: `fw recall` indexing — will `workflows/**/*.yaml` be picked up
  as-is, or does the indexer need a content-type addition?
- **Q8**: Test conventions — which bats tier must cover new lib code?
- **Q9**: Watchtower touchpoint surface — what exists today for surfacing a
  decision to the human (views, notification hooks)? What minimal metadata
  must a userTask carry for Watchtower to route it? (SD-11 grounding.)
- **Q10**: Instance-state precedent — does anything today track per-task
  live state in `.context/working/` (arc-focus pattern)? Confirm the
  autonomy-integrity constraint: instance files that gate agent authority
  must live OUTSIDE the agent's writable surface or behind a gated setter
  (P-03 lesson applies directly — a guardrail the agent can edit is not a
  guardrail).

First line of the discovery note:
`Discovery: workflow process layer. Q1–Q10 disposed. Blocking surprises: <none|list>.`

### 1.1 Step 0.5 — Paper exercise: inception-lifecycle (before Lock 1 freezes schema)

Using the Step 0 discovery of the *actual* inception process (Q1 inventory +
targeted read of inception routing/approval as implemented today), hand-author
`inception-lifecycle.workflow.yaml` against the DRAFT v3 schema — on paper,
before any validator code exists.

Purpose: cheapest possible schema pressure test. Friction found here changes
v3 before Lock 1 freezes it. This follows the established pattern (define the
state set on paper first) and selects the process with the worst
execution-regression history as the first test article.

Rules:
- Ground truth is the repo, not reconstruction from prior conversations.
  The chat-context strawman (register → VoI scoring → Sovereign priority →
  read-only discovery → disposition gateway [go|no-go|defer] → Sovereign
  ratification → status transition) is a HYPOTHESIS to be corrected against
  Q1 findings, not a template to confirm.
- Mark every node with its current determinism status (agent-improvised vs
  existing fw verb) — this produces the first determinism-frontier snapshot.
- Record every point where the draft schema cannot express reality cleanly;
  these are Lock 1 design inputs, listed verbatim in the exercise note.
- Producer-not-judge: the authored file is reviewed by the Sovereign against
  the lived process before it counts as the reference article.

Deliverable: the draft workflow file + a short friction note
(`NOTE-schema-friction-inception-<date>.md`). Both feed Lock 1.

---

## 2. Specification (target state, schema v3)

### 2.1 Canonical representation: YAML

**BPMN XML is demoted to derived import/export format.** The canonical,
repo-committed, agent-facing form is YAML. One file per workflow.

Proposed location (subject to SD-2/SD-5): `workflows/<id>.workflow.yaml`.

```yaml
# workflows/investigate.workflow.yaml
workflow:
  id: investigate
  title: Investigate
  version: "3"                 # content version, manual bump
  schema_version: 3
  status: proposed             # proposed | ratified | deprecated   (SD-4)
  ratified_by: null            # sovereign id + date when ratified
  description: >
    Decompose a question, gather context, synthesize findings,
    route to human review.
  source: agents/dispatch/investigate.md
  tier_default: 2
  execution:
    mode: advisory             # advisory | guided | strict   (SD-8)

lanes:
  - id: human
    name: "Human · Sovereignty"
    abbr: hum
    authority: sovereignty
    height: 130
  # ...

nodes:
  - uid: n_a3f7c0b2
    type: startEvent
    name: Investigation requested
    slug: investigation
    lane: framework
    position: { x: 280, y: 96 }
    aef:
      triggeredBy: "fw dispatch investigate ${task_id}"
      contextReads: ".tasks/active/${task_id}.md"
    io:
      outputs:
        - { name: task_id, type: task_id }
        - { name: run_id,  type: string }

  # userTask with human touchpoint (SD-11)
  - uid: n_9921bd07
    type: userTask
    name: Human review & route
    lane: human
    position: { x: 1050, y: 88 }
    aef:
      tier: 0
      humanTouchpoint:
        surface: watchtower            # watchtower | cli | notification
        view: "watchtower:/investigate/runs/${run_id}"
        contextBundle:
          - ".context/working/investigate-${run_id}/report.md"
        decisions: [dispatch, abandon] # each maps to an outgoing edge name
        timeout:
          after: "72h"
          escalate: notify             # notify | auto-route:<edge-name>
    io:
      inputs:
        - { name: report_path, type: path, required: true }

  # callActivity: business step refined by a technical sub-workflow (SD-9)
  - uid: n_5cd0e871
    type: callActivity
    name: Build context bundle
    lane: framework
    position: { x: 400, y: 80 }
    aef:
      calledWorkflow: context-bundle-build     # workflow id, awaited return
      ioMapping:
        inputs:  { task_id: task_id }          # caller-name: callee-input-name
        outputs: { bundle: bundle_path }       # callee-output-name: caller-name
      components:                              # Component Fabric linkage (SD-13)
        - "comp:lib/context.sh"                # fabric ids; optional; agent-inferred,
        - "comp:policy/context-bundle.yaml"    # human-confirmed
    io:
      inputs:  [ { name: task_id, type: task_id, required: true } ]
      outputs: [ { name: bundle,  type: ref } ]

edges:
  - uid: e_b91dcf04
    source: n_a3f7c0b2         # uid references, never displayIds
    target: n_c40e8a5d
    ports: { source: E, target: W }      # optional
    routing:                              # optional, all subkeys optional
      detourY: 165.0
      hints: { seg_mid: 20.0 }
      waypoints: []
    name: null
    condition: null
```

Schema v3 changes from prototype v2:
- YAML canonical form (above); BPMN XML export/import only
- `workflow.status` + `workflow.ratified_by` (governance surface, SD-4)
- `workflow.execution.mode` (enforcement ladder, SD-8)
- New node type `callActivity` — synchronous sub-workflow invocation with
  awaited return and explicit I/O mapping (SD-9). Distinct from link events
  (asynchronous transfer, no return). Ten-element subset total.
- `humanTouchpoint` block on `userTask` (SD-11): surface, view, context
  bundle, decision enum (must map onto outgoing edge names), timeout policy
- `aef.components` — optional Component Fabric refs on nodes (SD-13):
  agent-inferred, human-confirmed; business-node component sets derived by
  rollup through callActivity, never stored twice
- `position` and `routing` nested objects
- displayIds NEVER serialized — always computed; uid is the only stored
  identity (unchanged principle)

### 2.2 The three lenses (P1) — views, not separate files

A single workflow file carries all three design layers; renderers filter:

| Lens | Fields shown | Audience |
|---|---|---|
| functional / business | lanes, node names, gateways + decision labels, humanTouchpoint.decisions, descriptions | business stakeholder, Sovereign review |
| logical | + io contracts, conditions, link events, callActivity refs | designer, reviewing agent |
| technical | + endpoints, contextReads/artifactsWrites, tiers, routing, components | implementing agent, operator |
| pseudocode | linearized logical lens: if/else for XOR, parallel blocks for AND, calls for callActivity, component refs as comments (SD-14) | executing agent (advisory/guided view), PR reviewers (deterministic, diffable) |

Pseudocode is strictly **one-way derived** — never authored, never parsed
back; a second source of truth would re-open the drift problem this layer
closes. Irreducible graphs render best-effort: detected loop-backs as
`until`/`while`, undetectable ones as labeled `→ continue at <label>` —
never silently restructured. Generation is deterministic (same workflow →
byte-stable output) so diffs are reviewable. In guided mode, the rendering
for a bound task marks the current instance node ("YOU ARE HERE").

Granularity refinement across files uses `callActivity` (business step →
technical sub-workflow), not duplicated parallel documents. One source, no
drift.

### 2.3 Handoff and call contracts (composition)

**Link events** (`linkEventThrow`/`linkEventCatch`), asynchronous transfer:
- throw `targetWorkflow` must resolve; exactly one matching catch per linkId
- type agreement: throw inputs ↔ catch outputs, name-matched, types equal or
  policy-widened

**callActivity**, synchronous with return:
- `calledWorkflow` must resolve; callee must have exactly one startEvent and
  ≥1 endEvent
- `ioMapping.inputs` must satisfy every required input of the callee's
  startEvent outputs contract; `ioMapping.outputs` must reference callee
  endEvent inputs
- Cycle detection: callActivity graphs must be acyclic (error)

### 2.4 Validation rules (the judge's contract)

`fw workflow validate <file|id> [--strict]` — severity error unless noted:

- Unique uids; edges resolve; lanes resolve; abbrs unique
- exclusiveGateway: ≥2 outgoing; conditions/default coverage (warning gaps)
- Required inputs satisfiable (lock-1: graph-global approximation, documented)
- startEvent no incoming; endEvent no outgoing; link events per §2.3
- callActivity per §2.3 including acyclicity
- userTask with `humanTouchpoint.decisions` must have an outgoing edge whose
  name matches each decision (error), and no unmapped decision edges (warning)
- `execution.mode: guided|strict` requires: all userTasks carry
  humanTouchpoint; all serviceTasks carry tier (error) — a guardrail with
  unspecified authority is not ratifiable
- Handoff/call target resolution: warning for proposed, error for ratified
- schema_version supported; unknown fields warning (forward compat)

Exit codes: 0 valid, 1 errors, 2 warnings-only.

### 2.5 Component Fabric linkage (SD-13)

`aef.components` links process to structure. Rules:

- **Optional.** Meaningful mostly on serviceTask/scriptTask/callActivity at
  technical depth. Never required for a valid workflow; required-ness may be
  raised per-workflow by policy later, not by schema.
- **Resolution semantics by status.** On `status: proposed` workflows,
  unresolvable refs are validation *warnings*. On `status: ratified`
  workflows, unresolvable refs are **drift reports, not validation errors** —
  ratified process definitions are immutable and must not fail validation
  because code evolved. Drift lands in the drift channel (`fw fabric drift`
  integration or `fw workflow validate --drift`), for Sovereign disposition
  (re-ratify with updated refs, or accept).
- **Rollup, not duplication.** A business-lens node's effective component set
  is derived by rollup through its callActivity chain; only leaf technical
  nodes store refs.
- **Agent-inferred, human-confirmed.** The endpoint string typically names
  the component; agents propose `components:` annotations, the validator
  checks resolution, the human confirms at ratification. Annotation is never
  blind ceremony.
- **Derived reverse index.** The composition registry (§3.1.3) gains
  component → workflow/node edges, enabling process blast-radius:
  "which processes flow through this component."
- **Guardrail scope (guided mode).** At a node carrying `components:`, the
  agent's authority envelope is (tier at node) ∩ (declared components).
  Envelope claims remain valid only for ratified workflows.
- **BVP hook.** Component sets of a bound workflow's remaining nodes feed the
  blast-radius term of the cost composite for the bound task.

### 2.6 Workflow Fabric (SD-15 — PENDING SOVEREIGN CONFIRMATION incl. WF-A..E)

A queryable dependency graph over the process layer, peer and structurally
analogous to the Component Fabric: where the Component Fabric maps code
structure, the Workflow Fabric maps process structure. It is the promotion of
the composition registry (§3.1.3) from internal index to first-class fabric.

**Addressable entities (qualified, stable):**
- workflow: `wf:<workflow-id>`
- step: `wf:<workflow-id>#<node-uid>`
- lane instance: `wf:<workflow-id>#lane:<lane-id>`
- authority role: `role:<authority>` (sovereignty | authority | initiative |
  external) — lanes have dual identity: the per-workflow instance AND the
  cross-workflow role. Role-level queries are a named deliverable: "every
  step across every process where this role is the actor" = the Sovereign
  workload surface, computed rather than remembered.

**Edge types (v1, bounded set):**
- `flow` — intra-workflow sequence (from edges)
- `call` — callActivity caller→callee
- `handoff` — linkEventThrow→Catch across workflows
- `component` — step→Component Fabric ref (SD-13)
- `path` — declared contextReads/artifactsWrites claims
- `dataflow` (INFERRED) — derived writer→reader coupling from overlapping
  path claims after template-variable normalization to wildcards. Every edge
  carries provenance `declared|inferred`; inferred edges are the coupling
  nobody declared — precisely the rot vector explicit composition is blind to.

**Direction convention:** the changed thing is upstream of the impacted
thing. Callee upstream of caller; thrower upstream of catcher; writer
upstream of reader; component upstream of the step using it.
`blast-radius(X)` = transitive downstream closure. This enables the
cross-domain traversal that exists nowhere today: code change → component →
steps → workflows → dependent workflows → human touchpoints affected.

**Drift semantics:** uniform with §2.5 — every declared dependency type
(called workflow, handoff target, component, path claim) is warning on
proposed, drift-report-not-error on ratified.

**Sub-decisions (all OPEN, proposed dispositions):**

| ID | Question | Proposed |
|----|----------|----------|
| WF-A | One graph or two? | One conceptual graph; implementation (extend Component Fabric store vs separate store + join layer) decided by Q5 findings — not pre-decided against unread ground truth |
| WF-B | Lane dual identity | Both addressing modes; role-level query (Sovereign workload surface) is a named v1 deliverable |
| WF-C | Inferred dataflow edges in v1? | In, confidence-marked `inferred`; fuzzy-matching improvements deferred |
| WF-D | Addressing + uniqueness | Qualified scheme as above; validator adds cheap repo-wide uid-uniqueness check as belt-and-braces |
| WF-E | Lock placement | Lock 4 absorbs as Fabric v1 (it was already the registry lock); instance-level edges (running tasks downstream of node X) deferred until Lock 6 instance state exists; cross-repo namespacing (D4 pressure) flagged, deferred |

---

## 3. Architecture

### 3.1 Components

1. **`lib/workflow.sh`** (per Q2 conventions) — verb family:
   - `fw workflow list | show <id> | validate <id|file> [--strict]`
   - `fw workflow export <id> --format bpmn` / `import <file.bpmn>`
   - `fw workflow ratify <id> --i-am-human` / `deprecate <id> --i-am-human --successor <id|none>`
   - `fw workflow render <id> --lens business|logical|technical|pseudocode`
     (text/markdown rendering per §2.2; pseudocode deterministic and
     one-way per SD-14; SVG later)
   - Lock 6 adds: `fw workflow bind <task> <id>` and
     `fw workflow advance <task> --to <node-uid> [--decision <name>]`
2. **Designer (existing HTML prototype)** — visual surface. Bridge via BPMN
   import/export at the repo boundary (Lock 2); direct YAML in-designer later.
3. **Composition registry** — derived index of link pairs + call graph +
   component→workflow/node reverse edges (§2.5)
   (`.context/derived/workflow-links.yaml` or Component Fabric per Q5).
4. **Instance state (Lock 6, guided mode)** — per SD-10:
   - task frontmatter: `workflow: <id>` (binding)
   - live state: `.context/working/workflow-instances/<task>.yaml`
     (current node uid, history of transitions with timestamps + actor)
   - transitions ONLY via `fw workflow advance`, which validates the move
     against the definition (legal edge, condition satisfiable, human gates
     not skippable by agents, required inputs present) and appends to
     `.context/audits/workflow-transitions.jsonl`
   - **Autonomy-integrity constraint (Q10)**: instance files gate agent
     authority; they must not be free-writable by the agent. Same cage
     pattern as the P-03 remediation — higher-privilege lays the cage,
     agent uses only the gated setter (`advance`). If the autonomy-integrity
     Lock 1 cage lands first, reuse it; if not, this lock inherits the
     requirement and must not ship a bypassable guardrail.
5. **Docs** — designer docs migrate into the repo docs tree; `schema.md`
   rewritten for v3 YAML-canonical; new `docs/process-layer.md` states the
   foundational framing + the three purposes + the enforcement ladder
   (post SD dispositions).

### 3.2 Governance integration (SD-4 dependent)

- Workflows carry `status: proposed` at creation; only Sovereign ratifies.
- Ratified workflows immutable in place: change = version bump + re-ratify
  (mechanism per Q6 conventions, SD-6).
- Guided/strict mode requires `status: ratified` — an unratified guardrail
  cannot bound an agent (validation error on bind).
- `fw workflow ratify` refuses under `$CLAUDECODE=1` without
  `--i-am-human`/`--from-watchtower`; audit
  `.context/audits/workflow-lifecycle.jsonl`.
- Tier semantics under guided mode: node tier is the agent's authority
  envelope while at that node; the envelope claim is only valid for ratified
  workflows (this is what makes workflow-scoped tiers safe to honor).

### 3.3 Explicitly OUT of scope

- `fw workflow run` (strict mode execution) — separate future arc
- Designer rewrite off the browser sandbox — file bridge only
- Watchtower UI build-out for touchpoints — schema carries the metadata now;
  surface wiring is a Watchtower-side task
- Auto-layout / import of non-AEF BPMN — best-effort only

---

## 4. Build plan — locks (one at a time; each ends with Sovereign checkpoint)

### Lock 1 — Canonical schema + judge  ← FOUNDATION
Preconditions: SD-1..SD-14 disposed; Step 0 discovery complete; Step 0.5
paper exercise complete (inception draft + friction note consumed as design
input).
- Schema v3 YAML finalized against Q3 conventions AND Step 0.5 friction
  findings (incl. execution.mode, humanTouchpoint, callActivity, components)
- `fw workflow validate` (§2.4; bats per Q8) + `list|show`
- `investigate` converted to `workflows/investigate.workflow.yaml`
  (status: proposed) as first canonical file
- Exit: V6 passes; investigate validates clean
- Checkpoint: ratify schema v3 + validation rules

### Lock 2 — Interchange (BPMN bridge)
- export/import per prototype v2 namespace; uid-preserving; foreign-BPMN
  fresh-uid fallback with warning
- Round-trip test YAML → XML → YAML (V3)
- Exit: designer-saved file imports clean; export opens in designer
- Checkpoint: interchange fidelity confirmed

### Lock 3 — Governance lifecycle
- status enforcement; ratify/deprecate with agent gates + audit JSONL;
  ratified-immutability (SD-6)
- Exit: agent cannot ratify; bypass attempt audited
- Checkpoint: lifecycle rules ratified

### Lock 4 — Workflow Fabric v1 + contract validation
- Fabric per §2.6: entities, bounded edge-type set (flow, call, handoff,
  component, path, inferred dataflow), qualified addressing, role-level
  queries; implementation shape per Q5 findings (WF-A)
- §2.3 rules wired into validate; component resolution + drift-report channel
  per §2.5; first real handoff pair AND first real callActivity refinement
  authored + validated (V5)
- Exit: unmatched linkId, type mismatch, call cycle, and a renamed-component
  drift case each caught (V9); role-level query returns the Sovereign
  workload surface across ≥2 workflows
- Checkpoint: composition + fabric semantics confirmed

### Lock 5 — Dogfood arc + lens proof
- Author + validate the 5-process catalog (§5) as proposed workflows;
  annotate `components:` where sensible (agent-inferred, human-confirmed)
- Author ONE application-flavored example workflow with business+technical
  layering via callActivity (SD-12)
- `fw workflow render --lens` for all four lenses incl. pseudocode; verify
  pseudocode determinism (two runs byte-identical) and loop-back handling on
  the investigate workflow; run V1, V2, V8; record
- Sharpen schema from friction; this is where the concept earns
  "foundational" or gets demoted
- Checkpoint: ratify first process set; disposition on docs/process-layer.md

### Lock 6 — Guided-mode guardrail (instance tracking)
Preconditions: Lock 3 (only ratified workflows bind); Q10 cage disposition.
- `fw workflow bind|advance` per §3.1.4; instance files caged per
  autonomy-integrity constraint; transitions audited
- Human-gate protection: agent cannot advance through a userTask node;
  only `--i-am-human`/`--from-watchtower` (or Watchtower decision capture)
  advances it
- Exit: V7 passes (out-of-order refused; skipped human gate refused; unmet
  contract refused; all audited)
- Checkpoint: guided mode ratified; strict mode formally deferred to run arc

---

## 5. Dogfood catalog (Lock 5 targets)

**Selection principle:** prioritize the processes with the worst
execution-consistency history — the ones that produced repeated regressions
and reiterations when defined in prose. Those are where the workflow layer
proves or fails its thesis (P4). If explicit workflows do not reduce
regression on these, the foundational claim is wrong and we want to know
early.

1. **inception-lifecycle** — proposal → registration → VoI scoring →
   Sovereign priority → read-only discovery → disposition gateway →
   Sovereign ratification → status transition. (First article; drafted in
   Step 0.5, corrected and validated here.)
2. **exception-handling** — detection → classification → escalation routing →
   resolution → learning capture. (High regression history.)
3. **task-creation** — capture → classification → BVP estimation →
   confirmation → activation. (High regression history.)
4. **tier0-escalation** — tier-0 trigger → halt → human notification →
   disposition → resume/abort + audit. (Pure governance process; human
   gateways throughout.)
5. **knowledge-leveling** — capture → classification (universal vs
   framework-specific) → graduation criteria check → level promotion →
   ratification. (Knowledge pyramid; repeated-reiteration history.)
6. **arc-lifecycle** — draft → driver decision gate → in-progress → close
   (--demo gate) → ratified learnings. (Retained: exercises the §ACD gate
   pattern as workflow.)
7. **(SD-12 example)** one application-flavored workflow demonstrating
   business lens + callActivity refinement into a technical sub-workflow.

For each: mark every node's determinism status at authoring time
(agent-improvised vs fw verb) to produce the initial determinism-frontier
snapshot per process. Friction encountered while expressing these IS the
primary schema-quality signal.

Deferred to follow-on (still valuable, lower regression pressure):
dispatch-lifecycle, bvp-scoring-realization, termlink-lock-process,
acmm-rescan-cycle.

---

## 6. Sovereign decision register (consolidated)

| ID | Decision | Proposed disposition | Gates |
|----|----------|---------------------|-------|
| SD-1 | Identity of core concepts #1/#2 | Governance + Value | Lock 1 framing, docs |
| SD-2 | Process: new layer vs cross-cutting | (open; r2 framing strengthens "own layer" reading) | Directory layout, docs home |
| SD-3 | Arc↔workflow relation | template vs instance; task follows workflow | Q4 design, Lock 6, future run |
| SD-4 | Normative vs descriptive | Normative for AEF core processes | Lock 3 scope |
| SD-5 | Canonical file location | `workflows/` at repo root | Lock 1 |
| SD-6 | Ratified immutability mechanism | in-file version bump + re-ratify | Lock 3 |
| SD-7 | BVP drivers for this arc | candidate arc-scoped driver: process-legibility (defer to driver session) | arc creation |
| SD-8 | Enforcement ladder | schema supports advisory/guided/strict from v3; guided built in Lock 6; strict deferred | Lock 1 schema, Lock 6 |
| SD-9 | callActivity node type | yes — sync call with return + ioMapping; 10-element subset | Lock 1 schema, Lock 4 |
| SD-10 | Instance state home | task frontmatter binding + caged instance file in .context/working/workflow-instances/; advance-only transitions | Lock 6 |
| SD-11 | Human touchpoint spec | yes — humanTouchpoint block on userTask (surface/view/contextBundle/decisions/timeout); Watchtower wiring later | Lock 1 schema, Q9 |
| SD-12 | Application-practice scope | dogfood first; one application example in Lock 5; application rollout = follow-on arc | Lock 5 |
| SD-13 | Component Fabric linkage | yes — optional `aef.components` refs; agent-inferred, human-confirmed; rollup via callActivity; drift-report (not error) on ratified; reverse index in registry; guardrail scope = tier ∩ components in guided mode | Lock 1 schema, Lock 4, Q5 |
| SD-14 | Pseudocode lens | yes — fourth render lens; strictly one-way derived; deterministic/diffable; loop-back best-effort structuring with labeled fallback; guided-mode HERE-marker | Lock 5, Lock 6 nicety |
| SD-15 | Workflow Fabric | yes — per §2.6 incl. WF-A..E sub-decisions; Lock 4 becomes Fabric v1 | Lock 4, Q5 |

**REGISTER STATUS (as of handover, 2026-07-02): ALL of SD-1..SD-15 (incl.
WF-A..E) are OPEN. The dispositions above are design-agent PROPOSALS only —
none have been Sovereign-ratified. Step 0 and Step 0.5 may proceed without
dispositions; Lock 1 may not.**

---

## 7. First line of the Lock 1 handoff on delivery

`Lock 1: workflow process layer foundation. Schema v3 + fw workflow validate|list|show shipped. investigate.workflow.yaml canonical. V6 pass: <y/n>. Open: <list>.`
