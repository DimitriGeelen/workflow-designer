# AEF Workflow Schema

Authoritative reference for the workflow file format produced by the AEF workflow
designer. Read this when authoring workflow files by hand, generating them from
an agent, or writing a validator.

This document describes the *contract*. For implementation details of the
designer itself, see [architecture.md](architecture.md). For the on-canvas
editing experience, see [user-guide.md](user-guide.md).

---

## 1. The two-identifier model

Every node and every edge carries **two identifiers**:

- **`uid`** — immutable, internal, never user-facing in conversation.
- **`displayId`** — computed, human-readable, mutable, shown on canvas.

The two layers exist because the values different audiences need are
incompatible. Edges in storage need to point at something that never changes
or every rename breaks the graph. Humans authoring the file need readable
references like `agt_2_decompose`, not opaque hex strings. The solution is to
have both, with each layer doing the job it's good at.

### 1.1 `uid` — the storage contract

`uid` is the actual key that other parts of the workflow reference. Edges
store `source` and `target` as uids. Future runtime systems (audit logs,
execution traces) persist uids. Anything that needs identity-over-time
keys off uid.

**Format**: `<prefix>_<8 hex chars>` — `n_a3f7c0b2` for nodes, `e_b91dcf04`
for edges. Random; collision probability is negligible for any plausible
workflow size. Never edited by users.

**When generated**: on node creation. Once assigned, never changes.

**When emitted in XML**: as `<aef:uid value="…"/>` inside the
`<bpmn:extensionElements>` block on every node and edge.

### 1.2 `displayId` — the human contract

`displayId` is what people see and reference in conversation. It's computed
from three inputs and recomputed whenever any of them changes.

**Format for nodes**: `<lane.abbr>_<seq>_<slug>`

```
agt_2_decompose
└─┬─┘ │ └───┬───┘
 lane │     slug from name
      └─ spatial position within lane (left-to-right by x)
```

**Format for edges**: `flow_<seq>` — sequential by edge creation order
(stable; deleted edges leave gaps). Edges don't get richer displayIds
because the meaningful identifier on an edge is its `name` label
(`sufficient`, `abandon`, `insufficient · loop`), not a manufactured
descriptor.

**Recomputation triggers**:

- Node moved to a new lane → lane abbr in the displayId changes
- Node moved horizontally past another node in same lane → seq changes for
  both nodes
- Node renamed (and `slugManual` is false) → slug changes
- Node's `slug` field edited directly → slug changes
- Lane's `abbr` field edited → all nodes in that lane recompute

**When recomputation happens**: only at commit moments — after a drag
release, after a property edit, after an add/delete. *Not* during
in-progress drags. This keeps the canvas labels stable while you're
manipulating, with the update landing when you let go.

**When emitted in XML**: as `bpmn:id` attribute on every BPMN element.

---

## 2. Lane abbreviations

Every lane carries a 3-character `abbr` field used as the prefix in node
displayIds. Default derivation: first three alphanumeric characters of the
lane's name, lowercased.

```
human     → hum
framework → frw
agent     → agt
```

**Uniqueness**: enforced across lanes in the same workflow. If a derived
candidate collides with an existing lane's abbr, the system tries
two-character bases with digit suffixes (`hu2`, `hu3`) until unique.

**User-editable**: yes. The properties panel exposes the field. Editing
sets a `abbrManual` flag on the lane; subsequent name changes don't
auto-update the abbr.

**Constraints**: any string is accepted but the conventional shape is
3 characters, lowercase, alphanumeric. Longer abbreviations work but
clutter the canvas.

---

## 3. Workflow file structure (YAML canonical form)

The designer produces BPMN XML as its export format, but the canonical
representation in AEF is YAML. Both forms carry the same information; the
YAML is recommended for source control and for hand-authoring.

```yaml
workflowMeta:
  id: investigate          # workflow identifier (slug)
  version: 1               # schema version (see §8)
  source: agents/dispatch/investigate.md   # optional pointer to origin
  tier_default: 2          # default action tier for unspecified nodes

pool:
  id: Pool_investigate
  name: investigate

lanes:
  - id: human
    name: Human · Sovereignty
    abbr: hum
    authority: sovereignty
    height: 130
  - id: framework
    name: Framework · Authority
    abbr: frw
    authority: authority
    height: 130
  - id: agent
    name: Agent · Initiative
    abbr: agt
    authority: initiative
    height: 320

nodes:
  - uid: n_a3f7c0b2
    type: startEvent
    name: Investigation requested
    slug: investigation
    lane: framework
    x: 280
    y: 96
    aef:
      triggeredBy: fw dispatch investigate ${task_id}
      contextReads: .tasks/active/${task_id}.md
    io:
      outputs:
        - { name: task_id, type: task_id }
        - { name: run_id,  type: string }

edges:
  - uid: e_b91dcf04
    source: n_a3f7c0b2     # uid, not displayId
    target: n_c40e8a5d
    sourcePort: E          # optional; default 'auto'
    targetPort: W
    # name, condition, waypoints, detourY, routingHints — all optional
```

The minimal valid workflow has `workflowMeta`, `pool`, `lanes` (at least one),
and `nodes` and `edges` (both can be empty).

---

## 4. Node types

The designer supports an eight-element BPMN subset, each mapping to a specific
AEF concept.

| Type | Shape | Default lane | AEF meaning |
|---|---|---|---|
| `startEvent` | Circle | framework | Workflow entry point — typically a dispatch trigger or external event |
| `endEvent` | Circle (heavy) | framework | Terminal state — emits a completion event |
| `serviceTask` | Rectangle | agent | Work performed by an agent (Initiative authority) |
| `userTask` | Rectangle | human | Work performed by a human (Sovereignty authority) |
| `scriptTask` | Rectangle | framework | Work performed by the framework runtime (Authority authority) |
| `exclusiveGateway` | Diamond | agent | Decision point — exactly one outgoing path taken |
| `parallelGateway` | Diamond (`+`) | agent | Fan-out or join — all paths taken |
| `linkEventThrow` | Hollow circle (chevron →) | framework | Off-page connector: hands off to another workflow |
| `linkEventCatch` | Hollow circle (chevron ←) | framework | Off-page connector: receives a handoff from another workflow |
| `sequenceFlow` | Arrow | — | Edge connecting two nodes |

The mapping between task type and lane is a *convention*, not a constraint. A
`serviceTask` can sit in the framework lane if the workflow author has reason
to. The lane prefix in the displayId reflects actual lane membership; the type
prefix in the slug (when auto-derived) reflects type.

### 4.1 Required fields per node

All nodes require:

- `uid` (auto-generated)
- `type` (one of the seven node types above)
- `name` (display label)
- `lane` (a valid lane id)
- `x`, `y` (canvas coordinates in pixels)

Optional but conventional:

- `slug` (auto-derived from name; user can override)
- `slugManual` (boolean; `true` if user has edited slug directly)
- `aef` (object with type-specific fields; see §4.3)
- `io` (object with `inputs` and `outputs` arrays; see §4.4)

### 4.2 Node-type-specific fields

The `aef:` extension namespace carries the AEF-specific metadata. Which fields
apply depends on node type.

| Field | startEvent | endEvent | serviceTask | userTask | scriptTask | exclusiveGateway | parallelGateway | linkEventThrow | linkEventCatch |
|---|---|---|---|---|---|---|---|---|---|
| `tier` | — | — | ✓ | ✓ | ✓ | — | — | — | — |
| `agentType` | — | — | ✓ | — | — | — | — | — | — |
| `endpoint` | — | — | ✓ | ✓ | ✓ | — | — | — | — |
| `contextReads` | ✓ | — | ✓ | — | ✓ | — | — | — | — |
| `artifactsWrites` | — | — | ✓ | — | ✓ | — | — | — | — |
| `triggeredBy` | ✓ | — | — | — | — | — | — | — | — |
| `emits` | — | ✓ | — | — | — | — | — | — | — |
| `decisionInput` | — | — | — | — | — | ✓ | — | — | — |
| `decisionOwner` | — | — | — | — | — | ✓ | — | — | — |
| `decisionOutputs` | — | — | — | ✓ | — | — | — | — | — |
| `targetWorkflow` | — | — | — | — | — | — | — | ✓ | ✓ |
| `linkId` | — | — | — | — | — | — | — | ✓ | ✓ |

Fields used by multiple node types:

- **`tier`** — action authority tier (0, 1, 2, 3). Workflow-level `tier_default`
  applies when unspecified.
- **`endpoint`** — what executes this step. Format depends on the task type:
  - `serviceTask`: agent prompt path (`agents/dispatch/skills/decompose.md`) or
    framework command (`fw recall ${query} --scope code`)
  - `userTask`: watchtower view URL (`watchtower:/investigate/runs/${run_id}`)
  - `scriptTask`: framework command (`fw report write investigate --run ${run_id}`)
- **`contextReads`** / **`artifactsWrites`** — comma-separated path globs the
  step reads from / writes to. These are *filesystem* contracts, distinct from
  the typed I/O in §4.4.
- **`agentType`** — for serviceTask only: `primary` | `termlink-worker` | `human`.
  Identifies the executor.
- **`decisionInput`** — for exclusiveGateway only: an expression that
  evaluates to the routing key (`${findings.confidence}`).
- **`decisionOwner`** — for exclusiveGateway only: who makes the decision —
  `agent` | `human` | `framework`. Almost always implied by lane membership,
  but explicit for cases where lane and decision authority diverge.
- **`decisionOutputs`** — for userTask only: comma-separated enum of possible
  human decisions (`dispatch, abandon, reinvestigate`). Each value typically
  corresponds to an outgoing edge `name`.
- **`triggeredBy`** — for startEvent only: free-form description of what
  triggers entry (`fw dispatch investigate ${task_id}`).
- **`emits`** — for endEvent only: event name(s) emitted on completion
  (`event:investigate.ready`).
- **`targetWorkflow`** — for link events only: id of the workflow on the
  other side of the handoff. A `linkEventThrow` in workflow A with
  `targetWorkflow = "investigate"` and `linkId = "X1"` is matched by a
  `linkEventCatch` in workflow B (where B's `workflowMeta.id` is `investigate`)
  with the same `linkId`.
- **`linkId`** — for link events only: identifier that pairs a throw with its
  matching catch across workflows. Convention: short uppercase code (`X1`,
  `RESULT`, etc.).

### 4.3 The I/O contract (typed data flow)

Distinct from `contextReads` / `artifactsWrites` (filesystem operations), the
`io` block declares the typed data contract between steps:

```yaml
io:
  inputs:
    - { name: findings, type: ref, required: true }
    - { name: run_id,   type: string, required: true }
  outputs:
    - { name: report_path, type: path }
    - { name: audit_entry, type: ref }
```

**Type vocabulary**: `string`, `number`, `boolean`, `ref`, `path`, `task_id`,
`arc_id`, `list`, `object`. The vocabulary is extensible; new types can be
added without schema-breaking changes.

**Required vs. optional**: `required: true` declares the input must be present.
The framework will refuse to dispatch a step missing required inputs.

**Which node types carry I/O**:

| Type | inputs | outputs |
|---|---|---|
| `startEvent` | — | ✓ |
| `endEvent` | ✓ | — |
| `serviceTask` | ✓ | ✓ |
| `userTask` | ✓ | ✓ |
| `scriptTask` | ✓ | ✓ |
| `exclusiveGateway` | ✓ | — (decision is routing, not data) |
| `parallelGateway` | — | — |
| `linkEventThrow` | ✓ | — (data leaves into the target workflow) |
| `linkEventCatch` | — | ✓ (data arrives from the throwing workflow) |

---

## 5. Lanes

```yaml
lanes:
  - id: human
    name: Human · Sovereignty
    abbr: hum
    authority: sovereignty
    height: 130
```

**Required fields**: `id`, `name`, `authority`, `height`. The `abbr` is
auto-derived but persisted for stability.

**`authority`** — one of: `sovereignty`, `authority`, `initiative`,
`external`, `none`.

- `sovereignty` — humans only. Decisions that require human judgment or
  rule-of-three authority (per AEF's authority model).
- `authority` — framework operations. Deterministic actions the framework
  executes on behalf of the user.
- `initiative` — agent operations. Probabilistic actions an agent proposes
  or executes.
- `external` — third-party systems. Operations performed by something
  outside the AEF runtime (an API, a webhook target).
- `none` — pool-level lanes that don't carry authority semantics
  (purely visual grouping).

The authority value tints the lane background subtly on canvas and is
serialized in `aef:laneMeta`. Future validation rules will likely cross-check
node types against lane authority (e.g. warn if a `userTask` is in an
`initiative` lane).

**`height`** — pixel height of the lane band on canvas. Persisted because
visual layout is part of the workflow's affordances; an editor reopening the
file should see the same canvas the author left.

---

## 6. Edges

```yaml
edges:
  - uid: e_b91dcf04
    source: n_a3f7c0b2     # uid of source node
    target: n_c40e8a5d     # uid of target node
    name: sufficient       # optional label, rendered on canvas
    condition: ${findings.confidence >= 0.7}   # optional, exclusiveGateway only
    sourcePort: E          # optional; default 'auto'
    targetPort: W
    # Routing overrides — all optional
    waypoints: []          # explicit polyline points; if non-empty, router honors them
    detourY: 165.0         # for loop-back edges; absolute Y of the cross-bar
    routingHints:          # per-segment perpendicular offsets
      seg_mid: 20.0
```

### 6.1 Required vs. optional

Required: `uid`, `source`, `target`.

Everything else is optional. A minimal edge:

```yaml
edges:
  - uid: e_b91dcf04
    source: n_a3f7c0b2
    target: n_c40e8a5d
```

### 6.2 Ports

`sourcePort` and `targetPort` specify which side of each node the edge
anchors to. Eight cardinal/diagonal values are supported:

```
N, NE, E, SE, S, SW, W, NW
```

Plus `auto` (the default when omitted) which lets the router pick whichever
side faces the other endpoint.

### 6.3 Routing fields and their precedence

When multiple routing override fields are present, precedence is:

1. **`waypoints`** (if non-empty) — explicit manual polyline. The router
   draws orthogonal segments between consecutive waypoints, with stubs
   from each anchor to the first/last waypoint.
2. **`detourY`** — for loop-back-detected edges. Specifies the absolute
   Y of the horizontal cross-bar; the router computes everything else
   around it, clamped to lane bounds.
3. **`routingHints`** — per-segment perpendicular offsets keyed by role
   name (`seg_first`, `seg_mid`, `seg_last`). Applied to the
   auto-computed corners; the edge stays auto-routed.
4. **None of the above** — pure auto-routing.

If `waypoints` is non-empty, `detourY` and `routingHints` are ignored —
manual routing is a complete override.

### 6.4 Routing hint roles

The auto-router classifies each computed path into one of five topologies:

- `T0` — straight line, no corners
- `T1_HV` — one corner, source horizontal then target vertical
- `T1_VH` — one corner, source vertical then target horizontal
- `T2_H` — two corners on a shared Y (parallel horizontal stubs)
- `T2_V` — two corners on a shared X (parallel vertical stubs)

Each topology has a fixed set of interior segments named by stable role:

- `seg_first` — the segment immediately after the source stub
- `seg_mid` — the middle segment (T2 only)
- `seg_last` — the segment immediately before the target stub

A `routingHints[role]` value is a number representing perpendicular pixel
displacement. Positive = down or right depending on segment orientation;
negative = up or left.

**Topology stability**: when the geometry changes such that the topology
shifts (e.g. a port re-pin changes T2 to T1), role-keyed hints that no
longer apply are silently ignored. The edge routes from scratch in the new
topology. No errors, no migration; if the user wants the visual back, they
re-drag in the new topology.

### 6.5 Conditions

`condition` is meaningful only on edges leaving an `exclusiveGateway`.
Format: an expression string referencing the gateway's `decisionInput` or
upstream outputs.

```yaml
- uid: e_xxx
  source: <GW_sufficient>
  target: <Script_writeReport>
  name: sufficient
  condition: ${findings.confidence >= 0.7}
```

The framework runtime evaluates conditions at decision time and follows
exactly one outgoing edge (whichever condition is true; or an unconditioned
edge marked as default).

---

## 7. BPMN XML representation

The designer's **Save** action emits a `.bpmn` file with the workflow encoded
in BPMN 2.0 XML, augmented with an `aef:` extension namespace for the
AEF-specific fields.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions
    xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:aef="http://anchorpoint.framework/aef/extensions">

  <bpmn:process id="Pool_investigate" name="investigate">

    <bpmn:laneSet id="LaneSet_investigate">
      <bpmn:lane id="human" name="Human · Sovereignty">
        <bpmn:extensionElements>
          <aef:laneMeta abbr="hum" authority="sovereignty"/>
        </bpmn:extensionElements>
        <bpmn:flowNodeRef>frw_1_investigation</bpmn:flowNodeRef>
        ...
      </bpmn:lane>
      ...
    </bpmn:laneSet>

    <bpmn:serviceTask id="agt_1_decompose" name="Decompose problem">
      <bpmn:extensionElements>
        <aef:uid value="n_a3f7c0b2"/>
        <aef:meta tier="2" agentType="primary"/>
        <aef:endpoint>agents/dispatch/skills/decompose.md</aef:endpoint>
        <aef:contextReads paths=".context/working/.../bundle.yaml"/>
        <aef:artifactsWrites paths=".context/working/.../sub-questions.yaml"/>
        <aef:io>
          <aef:input name="bundle" type="ref" required="true"/>
          <aef:output name="sub_questions" type="list"/>
        </aef:io>
      </bpmn:extensionElements>
      <bpmn:incoming>flow_2</bpmn:incoming>
      <bpmn:outgoing>flow_3</bpmn:outgoing>
    </bpmn:serviceTask>

    <bpmn:sequenceFlow id="flow_13" name="insufficient · loop"
                       sourceRef="agt_8_sufficient" targetRef="agt_1_decompose">
      <bpmn:conditionExpression
          xsi:type="bpmn:tFormalExpression"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        ${findings.confidence &lt; 0.7}
      </bpmn:conditionExpression>
      <bpmn:extensionElements>
        <aef:uid value="e_b91dcf04"/>
        <aef:loopDetour y="165.0"/>
      </bpmn:extensionElements>
    </bpmn:sequenceFlow>

  </bpmn:process>
</bpmn:definitions>
```

### 7.1 Identifier mapping

- `bpmn:id` attributes → displayId (`agt_1_decompose`, `flow_13`)
- `<aef:uid value="…"/>` → uid (`n_a3f7c0b2`)
- `sourceRef` / `targetRef` on `<bpmn:sequenceFlow>` → displayId of the
  linked node
- `<bpmn:flowNodeRef>` inside `<bpmn:lane>` → displayId

Re-import (when implemented) will key off `aef:uid` to preserve identity
across edits made in external BPMN tools.

### 7.2 The aef: extension namespace

| Element | Where | Purpose |
|---|---|---|
| `aef:uid` | inside any extensionElements | Internal stable identifier |
| `aef:meta` | inside node extensionElements | Carries tier, agentType, decisionOwner, triggeredBy, emits as attributes |
| `aef:endpoint` | inside node extensionElements | Endpoint text (multi-line capable) |
| `aef:contextReads` | inside node extensionElements | `paths="…"` attribute |
| `aef:artifactsWrites` | inside node extensionElements | `paths="…"` attribute |
| `aef:decisionInput` | inside exclusiveGateway extensionElements | Expression text |
| `aef:decisionOutputs` | inside userTask extensionElements | `values="…"` attribute |
| `aef:io` | inside node extensionElements | Wraps `aef:input` and `aef:output` |
| `aef:input` / `aef:output` | inside `aef:io` | `name=`, `type=`, optional `required=` |
| `aef:laneMeta` | inside lane extensionElements | `abbr=`, `authority=`, `height=` |
| `aef:anchors` | inside sequenceFlow extensionElements | `sourcePort=`, `targetPort=` |
| `aef:routing` | inside sequenceFlow extensionElements | Wraps `aef:waypoint` elements |
| `aef:waypoint` | inside `aef:routing` | `x=`, `y=` coordinates |
| `aef:loopDetour` | inside sequenceFlow extensionElements | `y=` absolute coordinate |
| `aef:routingHint` | inside sequenceFlow extensionElements | `role=`, `offset=` |
| `aef:workflowMeta` | inside process extensionElements | `id=`, `version=`, `schemaVersion=`, `title=`, `description=`, `source=`, `tier_default=` |
| `aef:position` | inside node extensionElements | `x=`, `y=` — node canvas coordinates (preserved for round-trip) |
| `aef:link` | inside intermediateThrowEvent / intermediateCatchEvent | `targetWorkflow=`, `linkId=` — off-page connector to another workflow |

### 7.3 Validation

For a workflow to be valid:

- Every `bpmn:id` must be unique within the document
- Every `aef:uid` must be unique within the document
- Every `sourceRef` and `targetRef` must resolve to a node's `bpmn:id`
- Every node's `lane` must match a lane in the `bpmn:laneSet`
- Every required input must have a corresponding upstream output of compatible type
- Every `exclusiveGateway` must have at least two outgoing edges; conditions must be mutually exclusive (or default-marked)

Validation is not currently enforced by the designer — it will produce
invalid files if you create one. A future `fw workflow validate` command
is the planned enforcement point.

---

## 8. Schema versioning

The workflow file carries two version markers:

- **`workflowMeta.version`** — the *content* version of this specific workflow.
  Free integer or string; the author bumps it manually when the workflow's
  semantics change. Defaults to `"1"`.
- **`workflowMeta.schemaVersion`** — the *schema* version this file conforms
  to. Currently `2`. Maintained by the editor; users don't edit this.

### 8.1 Schema version history

**v2** (current)
- Added `aef:workflowMeta` element on `<bpmn:process>` carrying `id`,
  `version`, `schemaVersion`, `title`, `description`, `source`, `tier_default`
- Added `aef:position` element on every node for canvas layout round-trip
- Added `aef:link` element on `<bpmn:intermediateThrowEvent>` and
  `<bpmn:intermediateCatchEvent>` for off-page connectors
- Added `linkEventThrow` and `linkEventCatch` node types

**v1**
- Initial release. Eight-element BPMN subset, two-identifier model, routing
  extensions.

### 8.2 Compatibility policy

- **Additive changes** (new optional fields, new aef: elements) → no version bump
- **Breaking changes** (renamed fields, removed elements, changed semantics)
  → version bump, with migration notes in CHANGELOG when one exists

Until `fw workflow run` ships and external consumers exist, the schema is
considered pre-v1 and may change without ceremony. Once external runtime
exists, version bumps become contractual.

The designer's import path (when implemented) will read the version and apply
forward migrations as needed.

---

## 9. The relationship between AEF concepts and this schema

A few mappings worth being explicit about, since they often confuse newcomers:

- **The three-role authority model** (Sovereignty / Authority / Initiative)
  maps to the `authority` field on lanes. It's *not* the same as `tier`
  (action authority 0–3 on individual nodes).
- **Tier** is per-node and describes how much autonomy the executor has for
  that specific step — not who's executing it. A `serviceTask` in the agent
  lane (Initiative authority) can be tier 0 (read-only), tier 1 (proposes),
  tier 2 (acts with confirmation), or tier 3 (acts autonomously).
- **The manifest-maturity ladder** (Exploration → Stabilization → Automation)
  is the dimension along which a workflow representation evolves. This
  designer occupies the Stabilization tier. Dispatch markdown templates are
  Exploration; `fw workflow run` execution will be Automation.
- **The Four Constitutional Directives** (Antifragility, Reliability, Usability,
  Portability) are values, not levels. They don't map to schema fields; they
  inform design decisions about what fields exist at all.
