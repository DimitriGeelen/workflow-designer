# T-175 — Strawman: BPMN ⇄ AEF task/inception mapping (the keystone)

**Status:** STRAWMAN for the joint design pass (T-175 IW-8) and the future child-1 inception.
**Not** a decision and **not** a build. 832-side draft to give the AEF agent something concrete to react
to. Authored from the designer's known node model; the AEF side owns the framework-concept half.

> This mapping is the keystone of arc-001 (IW-2 + IW-7): a documented BPMN ⇄ task/inception-YAML contract.
> The framework talks to the *format*; this designer is the reference editor. Forward (diagram→work) and
> reverse (record→diagram) both compile through this table.

## The designer's BPMN surface (what the editor already emits)

Node types in `src/aef-workflow-designer.html` (NODE_DEFAULTS): `startEvent`, `endEvent`, `serviceTask`,
`userTask`, `scriptTask`, `exclusiveGateway`, `parallelGateway`, `linkEventThrow`, `linkEventCatch`,
`subProcess`. Plus **lanes** (swimlanes), **sequence flows** (edges), and `aef:` extension attributes
(the editor already round-trips `aef:` namespaced data — the natural home for framework-specific fields).

## The editor's actual `aef:` vocabulary (ground truth, not assumed)

Audited from `src/aef-workflow-designer.html` (2026-07-10). The editor already round-trips a fixed set of
`aef:` extension attributes, and they cleanly partition into two classes — **this partition is itself part
of the mapping contract**, because only one class may become governed work:

**Semantic (governance-bearing — these compile into / out of task-YAML fields):**
- `aef:artifactsWrites` (`paths=…`) → a task's produced artifacts / write set
- `aef:contextReads` (`paths=…`) → a task's context read set
- `aef:decisionInput` / `aef:decisionOutputs` → a gateway's decision condition + its branches (the gate)
- `aef:io` / `aef:input` / `aef:output` → task inputs/outputs
- `aef:constituents` → a subProcess's child members (→ arc / composite children, T-081)
- `aef:workflowMeta` / `aef:laneMeta` / `aef:meta` → process-, lane-, node-level framework metadata
- `aef:link` → cross-process link (linkEvent throw/catch pairing → dependency)
- `aef:uid` → stable node identity (the round-trip key: lets reverse re-render map to forward-edit the same element)

**Presentational (diagram cosmetics — MUST NOT leak into task YAML; round-trip only within the diagram):**
- `aef:position`, `aef:anchors`, `aef:endpoint`, `aef:waypoint` — geometry
- `aef:routing`, `aef:routingHint`, `aef:forceStraight`, `aef:loopDetour` — edge-routing hints
- `aef:extensionElements` — the container wrapper

**Contract implication:** the forward compile (diagram→work) reads ONLY the semantic class; the reverse
compile (record→diagram) *writes* the presentational class (layout) but must treat it as derived, never
authoritative. `aef:uid` is the hinge that makes round-trip stable — the same element keeps identity across
forward edits and reverse re-renders. Child-1 (mapping standard) should ratify this two-class list as the
canonical extension schema; anything the AEF side needs that isn't here (e.g. `aef:horizon`,
`aef:workflow-type`, `aef:owner` — see Known Mismatches) is a *proposed addition* to the semantic class.

## Forward mapping (diagram → proposed governed work)

| BPMN element | Proposed AEF concept | Notes / `aef:` fields |
|---|---|---|
| **Process** (the whole diagram) | A proposed **task graph** (optionally an **arc** if large) | `aef:arc` on the process when the flow is a program |
| **Lane** (swimlane) | **owner / agent** for the tasks in it | human lane → `owner: human`; agent lane → `owner: agent`; named agent → assignee |
| **userTask** | Task, `owner: human` | workflow_type via `aef:workflow-type` (default: the human-facing type) |
| **serviceTask** | Task, `owner: agent`, `workflow_type: build` | agent-executed work |
| **scriptTask** | Task, `owner: agent`, `workflow_type: build\|test` | disambiguate via `aef:workflow-type` |
| **exclusiveGateway** (XOR) | A **decision / gate** — branch on a condition | outgoing edges = branches; edge label = condition. Maps to a go/no-go or a conditional transition |
| **parallelGateway** (AND) | **Fan-out / fan-in** of concurrent tasks | fork = independent tasks with no ordering dep; join = a barrier |
| **subProcess** | An **arc** or a **composite task** | reuse existing `aef:constituents` (T-081); collapsed sub-process = a child arc |
| **startEvent / endEvent** | Process boundary markers | no task; anchor the graph's entry/exit |
| **linkEventThrow / Catch** | **Cross-process reference / dependency** | maps to `related_tasks` / a dependency edge between graphs |
| **sequence flow** (edge) | **Ordering dependency** | A→B ⇒ B depends on A (`related_tasks` + sequencing) |
| **edge from a gateway** (conditional) | **Conditional transition** | carries the branch condition (edge label) |
| Node **documentation / annotation** | **Acceptance Criteria** seed | ACs have no BPMN shape; live in node metadata → enriched by the agent (IW-3) |

## Reverse mapping (AEF record → rendered process map) — IW-4

Starting from AEF's own structured record (not arbitrary code):

| AEF artifact | Rendered as |
|---|---|
| A task | A task node, typed by `workflow_type`, laned by `owner` |
| `related_tasks` / dependency | A sequence flow |
| An inception decision (go/no-go) | An exclusiveGateway with GO/NO-GO branches |
| An arc | A subProcess (collapsed) containing its constituent tasks |
| Parallel/independent tasks | A parallelGateway fan-out |
| Episodic sequence (completed task order) | The left-to-right flow ordering |

## Known mismatches / open points (for the AEF agent)

These are where BPMN has no clean counterpart — the `aef:` extension layer must carry them, and the AEF
side should confirm the canonical names:

1. **`horizon` (now/next/later)** — no BPMN concept. → `aef:horizon` node attribute.
2. **`workflow_type` granularity** (Build vs Test vs Refactor vs Decommission vs Specification vs Design) —
   BPMN task types (service/script/user) don't distinguish. → `aef:workflow-type` attribute; BPMN type only
   coarsely implies owner/automation.
3. **inception vs build** — an inception is a decision-gated exploration. → a subProcess marked
   `aef:workflow-type: inception` with a terminal gateway (the go/no-go), OR a task-node with the marker.
   Needs an AEF-side ruling.
4. **Acceptance Criteria / Verification** — no shape; node metadata. The forward flow's agent-enrichment
   step (IW-3) is where ACs get filled, so the diagram only needs to *seed* intent.
5. **Gates that are framework-structural** (G-020, P-011, sovereignty) — these are not drawn; they apply
   automatically when the proposed graph is materialised. The diagram should not try to represent them.
6. **owner precedence** — lane vs an explicit `aef:owner` on a node: which wins? Propose: node-level
   `aef:owner` overrides lane default.
7. **Emission gap (832-side, concrete):** the mapping references `aef:horizon`, `aef:workflow-type`, and
   `aef:owner`, but the editor does **not** emit these three today (**verified 2026-07-10**: `aef:horizon`,
   `aef:workflow-type`/`aef:workflowType`, `aef:owner` = 0 occurrences in `src/aef-workflow-designer.html`; it emits
   `aef:workflowMeta`/`aef:laneMeta`/`aef:meta` as generic metadata carriers, plus the semantic set above).
   So child-1 ratifies the schema and child-2 (forward bridge) must **extend the editor** to emit these
   three as first-class semantic attributes (or nest them inside `aef:meta`). This is 832-owned work, and
   it is a *build* item — it belongs in a child inception's build tasks, not in this framing inception.

## 832-owned groundwork (independent of the AEF react — safe to work out now)

These pieces are purely the editor/BPMN half of the contract. The AEF agent's answers shape the
framework-concept half (task-model receive, reverse source, ownership), but they cannot invalidate the
below — so working them out now de-risks child-1/child-2 without pre-empting the joint pass.

### G-1. Emission spec for the three missing semantic attributes (child-2 groundwork)

The editor must emit these as first-class semantic attributes on the task node's `aef:` extension (sibling
to `aef:artifactsWrites` etc.), NOT buried in free-form `aef:meta`. Proposed concrete schema — a closed
value set per attribute so forward-compile is a lookup, not free-text parsing:

| Attribute | Emitted form | Allowed values | Task-YAML field | Default when absent |
|---|---|---|---|---|
| `aef:horizon` | `<aef:horizon>now</aef:horizon>` | `now` \| `next` \| `later` | `horizon` | `now` (framework default) |
| `aef:workflow-type` | `<aef:workflow-type>build</aef:workflow-type>` | build\|test\|refactor\|decommission\|specification\|design\|inception | `workflow_type` | inferred from BPMN type (service/script→build, user→the human-facing type) |
| `aef:owner` | `<aef:owner>agent</aef:owner>` | `human` \| `agent` \| `<named-assignee>` | `owner` | lane default (human-lane→human, agent-lane→agent); node value overrides (mismatch #6) |

Forward-compile rule: node `aef:owner` **overrides** lane; absent → lane default. `aef:workflow-type`
absent → BPMN-type inference; present → authoritative. Reverse-compile writes all three from the task's
YAML so a round-tripped node re-emits identically. Editor UI: three inspector fields (dropdowns bound to
the closed value sets) — a small, contained addition, no new BPMN geometry.

### G-2. Round-trip identity — `aef:uid` is the hinge

Every node/edge carries a stable `aef:uid` (already emitted — **verified against `src/aef-workflow-designer.html`
2026-07-10**: node emit `:7740`, edge emit `:7901`, import reuse-else-generate `:8017`, id/uid separation `:7943`).
This is what makes round-trip non-destructive:
- **Reverse** (record→diagram): each task/flow renders with `aef:uid = <task-id>` (or a deterministic hash
  for edges), so re-rendering the same record twice is byte-stable.
- **Forward edit** (diagram→proposal): a node whose `aef:uid` already resolves to an existing task is a
  *modify* proposal; a node with no `aef:uid` (freshly drawn) is a *create* proposal. This is exactly how
  the forward flow distinguishes "propose a new task" from "propose a change to task T-XXX" without guessing.
- **Presentational churn is invisible to governance:** moving a node (changes `aef:position`) with the same
  `aef:uid` and same semantic attributes is a no-op for the task graph — only semantic-class deltas surface
  in the approval batch (IW-3). This is why the semantic/presentational partition + `aef:uid` together are
  the contract's core: they bound what a diagram edit can *propose*.
- **Reverse-render needs zero editor change (verified):** the import path (`:8017`) honors an *arbitrary*
  `aef:uid` value, not just editor-generated ones. So child-3 (reverse bridge) emits `aef:uid=<task-id>` in
  the BPMN it generates and the editor round-trips it as-is — identity is externally assignable today, no
  build on the 832 side for the identity mechanism. This is the strongest de-risk in the whole strawman:
  the round-trip *anchor* (IW-1) is already fully supported by the shipped editor.

### G-3. Inception marker (resolves mismatch #3 on the 832 side)

Proposed 832 representation, pending the AEF ruling: an inception is a **subProcess** with
`aef:workflow-type=inception` whose terminal element is an `exclusiveGateway` carrying
`aef:decisionInput`/`aef:decisionOutputs` = the go/no-go. This reuses existing emitted attributes
(`aef:constituents` for the sub-process members, the decision attributes for the gate) — no new shape.
The AEF side rules on whether a single task-node-with-marker is also acceptable for lightweight inceptions.

## Testable assumptions this strawman rests on

- **A:** Every AEF `workflow_type` and `owner` can be represented by (BPMN type + `aef:` extension) without
  a new BPMN shape. *(Confidence: raised med→high — the 2026-07-10 audit confirms the editor already emits a
  semantic `aef:` class carrying governance data (writes/reads/decision/io/constituents); the three missing
  attributes (horizon/workflow-type/owner) are added attributes, not new shapes. No new BPMN geometry needed.)*
- **B:** AEF's task/inception model can *receive* a BPMN-derived proposed graph (the forward compile target
  exists or is cheap to add). *(To validate with the AEF agent — question (a) on thread T-175.)*
- **C:** AEF's own record (task graph + fabric + episodic) is structured enough to reconstruct a faithful
  process map deterministically. *(To validate — question (c) on thread T-175.)*

## What this de-risks

If this table survives the joint pass roughly intact, the decomposition (IW-8) is sound: child-1 (mapping
standard) is tractable, and children 2–3 (forward/reverse bridges) are "compile through this table" rather
than open research. If it *doesn't* survive — e.g. AEF's model can't receive a BPMN-derived graph cheaply —
that's exactly the kind of finding that should reshape the decomposition before any GO.
