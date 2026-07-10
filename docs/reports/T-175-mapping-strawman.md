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

## Testable assumptions this strawman rests on

- **A:** Every AEF `workflow_type` and `owner` can be represented by (BPMN type + `aef:` extension) without
  a new BPMN shape. *(Confidence: medium — the extension layer is designed for exactly this.)*
- **B:** AEF's task/inception model can *receive* a BPMN-derived proposed graph (the forward compile target
  exists or is cheap to add). *(To validate with the AEF agent — question (a) on thread T-175.)*
- **C:** AEF's own record (task graph + fabric + episodic) is structured enough to reconstruct a faithful
  process map deterministically. *(To validate — question (c) on thread T-175.)*

## What this de-risks

If this table survives the joint pass roughly intact, the decomposition (IW-8) is sound: child-1 (mapping
standard) is tractable, and children 2–3 (forward/reverse bridges) are "compile through this table" rather
than open research. If it *doesn't* survive — e.g. AEF's model can't receive a BPMN-derived graph cheaply —
that's exactly the kind of finding that should reshape the decomposition before any GO.
