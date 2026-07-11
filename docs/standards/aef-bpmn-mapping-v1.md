# AEF BPMN ⇄ task/inception-YAML Mapping Standard — v1

**Version:** 1.0 (2026-07-11) · **Status:** frozen core + provisional annex · **Arc:** designer-authoring-surface (child-1, keystone)
**Origin:** T-175 (framing inception, GO) → T-182 (child-1 build). Converged from `docs/reports/T-175-mapping-strawman.md`, validated against `src/aef-workflow-designer.html`.

## Purpose & principle

This standard defines the portable contract between a **BPMN process diagram** (with an `aef:` extension
layer) and **AEF task/inception YAML**. Per IW-7, *the framework talks to this format, not to any one editor*;
`src/aef-workflow-designer.html` is the blessed **reference implementation**, and any conformant editor can
drive the forward (diagram→proposed work) and reverse (record→diagram) loops.

**Normative language:** MUST / MUST NOT / SHOULD / MAY per RFC 2119.

Two parts:
- **Part I — Frozen (v1):** ratified and stable; changes require a version bump. Guarded by
  `tests/test_mapping_standard_conformance.py`.
- **Part II — Provisional:** proposed, pending an AEF-side ruling; MUST NOT be relied on as settled.

---

# Part I — Frozen (v1)

## 1. The two attribute classes

Every `aef:` datum is exactly one of two classes. This partition is **normative** — it bounds what a diagram
edit may propose:

- **Semantic (governance-bearing):** compiles into / out of task-YAML fields. The forward compile MUST read
  only this class. Includes the structured elements `aef:artifactsWrites`, `aef:contextReads`,
  `aef:decisionInput`/`aef:decisionOutputs`, `aef:io`/`aef:input`/`aef:output`, `aef:constituents`,
  `aef:link`, the identity key `aef:uid`, and the scalar **governance meta-keys** carried as attributes of
  `aef:meta` (§3).
- **Presentational (diagram cosmetics):** `aef:position`, `aef:anchors`, `aef:endpoint`, `aef:waypoint`,
  `aef:routing`, `aef:routingHint`, `aef:forceStraight`, `aef:loopDetour`, and the `aef:extensionElements`
  wrapper. The reverse compile MAY write these (layout) but MUST treat them as derived, never authoritative.
  A change to a presentational attribute alone MUST be a no-op for the task graph.

## 2. Governance meta-keys carried on `aef:meta`

Scalar governance fields are emitted as **attributes of the single `aef:meta` element** (not standalone
`aef:<key>` elements). The editor's `metaKeys` writer and the Python bridge's `META_KEYS` whitelist govern
this channel; the invariant *editor `metaKeys` ⊆ bridge `META_KEYS`* is enforced by
`tests/test_editor_bridge_meta_parity.py` (T-060).

The **frozen v1 governance meta-keys** — those with a defined task-YAML field mapping and a closed value set —
are the following. A conformant editor MUST emit each on task-like nodes, and the bridge MUST round-trip each:

```conformance-governance-meta-keys
horizon
workflowType
owner
tier
agentType
```

| `aef:meta` key | Task-YAML field | Allowed values | Default when absent |
|---|---|---|---|
| `horizon` | `horizon` | `now` \| `next` \| `later` | `now` |
| `workflowType` | `workflow_type` | build \| test \| refactor \| decommission \| specification \| design \| inception | inferred from BPMN type (service/script→build; user→human-facing) |
| `owner` | `owner` | `human` \| `agent` | lane default; node value overrides lane (§4) |
| `tier` | enforcement tier | `0`..`3` | project default |
| `agentType` | agent assignment | `primary` \| `termlink-worker` \| `human` | `primary` |

> Additional keys exist in the editor `metaKeys` set (gateway/sub-process-structural and editor-internal,
> e.g. `gatewayKind`, `scopeOf`, `decisionOwner`); they are covered by the parity test but are **not** part of
> the frozen v1 governance-scalar contract and MAY change without a standard bump.

## 3. Forward mapping (diagram → proposed governed work)

The forward compile produces a **proposed** task/inception graph (never silently authored — IW-1/IW-3;
approval is a separate sovereignty gate).

| BPMN element | AEF concept | Notes |
|---|---|---|
| Process (whole diagram) | Proposed task graph (arc if large) | `aef:arc` on the process when the flow is a program |
| Lane (swimlane) | owner/agent for its tasks | human lane → `owner: human`; agent lane → `owner: agent` |
| userTask | Task, `owner: human` | `workflow_type` via `aef:meta workflowType` |
| serviceTask | Task, `owner: agent`, `workflow_type: build` | agent-executed |
| scriptTask | Task, `owner: agent`, `workflow_type: build\|test` | disambiguate via `workflowType` |
| exclusiveGateway (XOR) | Decision / gate | outgoing edges = branches; edge label = condition |
| parallelGateway (AND) | Fan-out / fan-in | fork = independent tasks; join = barrier |
| subProcess | Arc or composite task | `aef:constituents` = members; collapsed = child arc |
| startEvent / endEvent | Process boundary markers | no task |
| linkEventThrow / Catch | Cross-process reference / dependency | `related_tasks` |
| sequence flow (edge) | Ordering dependency | A→B ⇒ B depends on A |
| node documentation / annotation | Acceptance-criteria seed | ACs enriched by the agent (IW-3) |

**owner precedence:** node-level `owner` MUST override the lane default; absent → lane default.

## 4. Reverse mapping (AEF record → rendered process map)

First target is AEF's own structured record (IW-4); arbitrary source parsing is out of scope for v1.

| AEF artifact | Rendered as |
|---|---|
| A task | Task node, typed by `workflow_type`, laned by `owner` |
| `related_tasks` / dependency | Sequence flow |
| Inception decision (go/no-go) | exclusiveGateway with GO/NO-GO branches |
| An arc | Collapsed subProcess containing its constituents |
| Parallel/independent tasks | parallelGateway fan-out |
| Episodic (completed order) | Left-to-right flow ordering |

## 5. Identity & round-trip — `aef:uid`

- Every node and edge MUST carry a stable `aef:uid`. It is the round-trip hinge (identity survives forward
  edits and reverse re-renders).
- **Reverse:** each rendered element MUST set `aef:uid = <task-id>` (or a deterministic hash for edges), so
  re-rendering the same record is byte-stable.
- **Forward:** a node whose `aef:uid` resolves to an existing task is a **modify** proposal; a node with no
  `aef:uid` is a **create** proposal.
- `aef:uid` is **externally assignable** — the reference editor's import path honors arbitrary `aef:uid`
  values, so a reverse renderer needs no editor change for identity.

## 6. Conformance requirements

An implementation is **v1-conformant** iff:
1. It honors the §1 two-class partition (semantic read on forward; presentational derived on reverse).
2. It emits/round-trips every frozen governance meta-key (§2) on task-like nodes.
3. It carries a stable, externally-assignable `aef:uid` on every node and edge (§5).
4. Presentational-only edits are task-graph no-ops.

The frozen governance meta-key list (§2) is machine-checked against the reference editor and bridge by
`tests/test_mapping_standard_conformance.py` (standard↔implementation parity; complements the T-060 editor↔bridge parity test).

---

# Part II — Provisional (pending AEF ruling)

These are **not** frozen. They carry the reference-implementation's proposal; the AEF side rules before they
enter a future frozen version.

- **Inception marker shape (G-3):** proposed — an inception is a `subProcess` with `aef:meta workflowType=inception`
  whose terminal element is an `exclusiveGateway` carrying `aef:decisionInput`/`aef:decisionOutputs` (the
  go/no-go), reusing `aef:constituents` for members. *Open:* whether a single task-node-with-marker is also
  acceptable for lightweight inceptions.
- **`tier` default:** the absent-value default for `tier` is project-dependent; the canonical default is
  unratified.
- **AC-seeding:** acceptance criteria have no BPMN shape; they live in node metadata and are filled by the
  forward agent-enrichment step (IW-3). The exact seed field/format is unratified.

Requested on termlink thread T-175 (2026-07-11). On ruling, these graduate to Part I under **v1.1**.

---

## Versioning & change control

- **Frozen (Part I)** changes require a version bump (`v1` → `v1.1`/`v2`) and a conformance-test update.
- **Provisional (Part II)** items may change freely until ratified.
- Each release of the reference editor is tagged `designer-v<version>`; this standard cites the editor state
  it was validated against (`0.2.0`, sha `e301986b…`).
