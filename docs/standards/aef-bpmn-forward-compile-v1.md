# AEF Forward-Compile Spec — BPMN(+aef:) → proposed task/inception graph — v1

**Version:** 1.1 (2026-07-12) · **Status:** 832-side support deliverable for the AEF-led forward bridge

> **v1.1 (2026-07-12):** IW-9 authority-collapse graduated (mapping-v1 v1.1, T-189) — `owner` is derived from
> the lane `authority`, no node-level override (§3B.1/§3B.2/§2); O-1 = lane-wins + WARN; O-3 = inception go/no-go
> MUST be human-laned (§8). Matches AEF's Child-2 compiler (T-2531), built to this collapse from day one.
**Arc:** designer-authoring-surface (child-2, forward bridge) · **Origin:** T-183
**Derives from:** `docs/standards/aef-bpmn-mapping-v1.md` (child-1, frozen v1) — this document adds no new
contract; it specifies the *expected output* of compiling a v1-conformant diagram, so the AEF translator
has an unambiguous target and a reference corpus to test against.

## 1. Scope & division of labour

Child-2 (the forward bridge: diagram → agent-enriched **proposed** task graph → one sovereignty approval →
governed work) is **AEF-led**. AEF owns the translator, the enrichment pass, and the sovereignty gate.

This document is 832's supporting half:
- **the input contract** — what a v1-conformant BPMN carries (§2), guarded by `tests/test_forward_fixtures.py`;
- **the forward-compile mapping** — the deterministic diagram→proposal rules (§3), derived from v1 §3/§5;
- **the reference corpus** — `tests/fixtures/aef-bpmn/*.bpmn`, authentic editor output (§5);
- **the modify-vs-create rule** — how `aef:uid` splits modify from create proposals (§4).

**No translator is built here.** The generative direction, enrichment, and the approval gate are AEF's.

## 2. Input contract (what the compiler may rely on)

A conformant input is any BPMN diagram that passes the v1 conformance requirements (`aef-bpmn-mapping-v1.md`
§6). Concretely, the reference editor `src/aef-workflow-designer.html` emits, and the compiler may rely on:

- **`aef:uid`** on every flow node and every sequence flow (v1 §5) — the identity hinge.
- **`aef:meta`** carrying governance scalars as attributes (v1 §2/§3): `tier`, `agentType`,
  `horizon`, `workflowType` (frozen; `owner` is **no longer author-supplied** in v1.1 — it is derived from the
  lane `authority`, see §3B.1), plus editor-vocabulary keys (`state`, `gate`, `triggeredBy`,
  `decisionOwner`, `terminalKind`, `note`, `softFail`, `guard`, `external`, `exitCode`, …). Every key the
  editor emits is within the bridge `META_KEYS` whitelist (guarded by `test_editor_bridge_meta_parity.py`).
- **Lanes** with `aef:laneMeta authority="sovereignty|authority|initiative|external"` — the **sole** owner source (v1.1, IW-9).
- **Process-level `aef:workflowMeta`** (`id`, `version`, `tier_default`, `title`).
- **Structured semantic elements** (v1 §1, semantic class): `aef:io`/`aef:input`/`aef:output`,
  `aef:endpoint`, `aef:artifactsWrites`, `aef:contextReads`, `aef:decisionInput`/`aef:decisionOutputs`,
  `aef:constituents`, `aef:link`.
- **Presentational elements** (v1 §1, presentational class): `aef:position`, `aef:anchors`,
  `aef:routingHint`, `aef:waypoint`, `aef:loopDetour`, … — the forward compile **MUST ignore these**; a
  diagram that differs only in presentational data MUST compile to the identical proposal.

## 3. Forward-compile mapping (diagram → proposed governed work)

The output is a **proposal**, never silently-authored work (v1 §3; IW-1/IW-3). The compile is deterministic;
enrichment (ACs, refined descriptions) is a separate AEF pass over the proposal.

### 3.1 Structural

| BPMN construct | Proposed AEF artifact | Rule |
|---|---|---|
| `bpmn:process` (+ `aef:workflowMeta`) | One proposed task graph; an **arc** when it is a program (`aef:arc`, or a multi-lane process with a subProcess) | `workflowMeta.tier_default` seeds the tier default (v1 Part II, provisional). |
| `bpmn:laneSet` / `bpmn:lane` | Owner assignment for member nodes | `authority=sovereignty` → `owner: human`; `authority=initiative` → `owner: agent`; `authority=authority` → framework/agent; `authority=external` → external actor (no task authored). |
| `bpmn:userTask` | Task, `owner: human` | `workflow_type` from `aef:meta workflowType` if present, else human-facing. |
| `bpmn:serviceTask` | Task, `owner: agent`, `workflow_type: build` | agent-executed. |
| `bpmn:scriptTask` | Task, `owner: agent`, `workflow_type: build\|test` | disambiguate via `aef:meta workflowType`. |
| `bpmn:exclusiveGateway` | Decision / gate | outgoing edges = branches; branch label / `conditionExpression` = condition; `aef:meta decisionOwner` = who decides; `aef:decisionInput` = the tested value. |
| `bpmn:parallelGateway` | Fan-out (fork = independent tasks) / fan-in (join = barrier) | forked branches carry no ordering dependency between siblings. |
| `bpmn:subProcess` | Arc or composite task | `aef:constituents` = members; nested flow nodes compile as child tasks. |
| `bpmn:startEvent` / `bpmn:endEvent` | Process boundary markers | **no task.** `endEvent` `aef:meta terminalKind` records the terminal semantics; `aef:meta emits` records an event. |
| `bpmn:intermediateCatchEvent` (+ `aef:eventDef kind=..`) | Trigger annotation on the flow | **no task itself.** `kind` (error/timer/message) comes from `aef:eventDef`, never the tag; `binding` records the trigger — error→`status:issues`, timer→cron/`horizon`, message→bus topic (T-204). |
| `bpmn:sequenceFlow` A→B | Ordering dependency | **B depends_on A.** |
| node `documentation` / annotation | Acceptance-criteria seed | filled by the AEF enrichment step (v1 Part II — AC-seeding is provisional). |

**owner is the lane authority (IW-9, v1.1):** `owner` is derived from the member lane's `aef:laneMeta authority` via the collapse map (`sovereignty→human`, `initiative→agent`, `authority→agent`, `external→no task`). There is **no** node-level `aef:meta owner` override.

### 3.2 Scalar field mapping (`aef:meta` → task-YAML)

Per v1 §2, on each proposed task:

| `aef:meta` key | task-YAML field | note |
|---|---|---|
| `horizon` | `horizon` | default `now` when absent |
| `workflowType` | `workflow_type` | else inferred from BPMN node type |
| ~~`owner`~~ *(derived)* | `owner` | **derived from lane `authority` (§3.1); no node-level override** |
| `tier` | enforcement tier | else `workflowMeta.tier_default`, else project default |
| `agentType` | agent assignment | default `primary` |

`horizon` and `workflowType` are **authored-optional** — they appear only when the author set them; their
absence is not a conformance defect (the reference process fixtures legitimately omit them).

### 3.3 Structured-element carry-over

The semantic-class elements travel onto the proposed task as context, not as new governance:
`aef:endpoint` → the command/pointer; `aef:artifactsWrites` → declared outputs; `aef:contextReads` → declared
inputs; `aef:io`/`aef:input`/`aef:output` → typed I/O; `aef:decisionInput`/`aef:decisionOutputs` → the
decision's tested value and branch set. These inform enrichment; they are not re-interpreted as task fields.

## 4. Identity — modify vs. create (v1 §5)

`aef:uid` is the round-trip hinge and the sole modify/create discriminator:

- A node whose `aef:uid` **resolves to an existing task** (e.g. `aef:uid="T-042"`, or a uid the AEF record
  already maps to a task) is a **modify** proposal — the compile targets that task, not a new one.
- A node whose `aef:uid` **does not resolve** (a fresh editor-minted `n_…` uid) is a **create** proposal.
- Edges use `aef:uid` (`e_…`) for stable dependency identity across re-compiles.
- Because `aef:uid` is externally assignable (v1 §5), a reverse-rendered diagram (child-3) round-trips back
  through this same compile as modify proposals with no special-casing.

The compiler therefore emits, per node, a `{proposal: create|modify, target: <task-id|null>, uid: <aef:uid>}`
tuple alongside the mapped fields.

## 5. Reference corpus (`tests/fixtures/aef-bpmn/`)

The corpus is **5 fixtures**: **4 authentic editor-emitted diagrams**, curated to cover every v1 §3 row
present in the editor vocabulary, **plus 1 hand-authored inception fixture** (`inception-gonogo.bpmn`) that
exercises the *provisional* **G-3 inception marker** (mapping-v1 Part II — ratified AEF-side, **pending
Dimitri's v1.1 graduation**; hand-authored, not editor-emitted, not frozen). All 5 are guarded by
`tests/test_forward_fixtures.py` (parse; `aef:uid` on every node+edge; every `aef:meta` key within the bridge
whitelist; `tier`/`agentType`/owner-via-lanes exercised).

| Fixture | Source | Exercises |
|---|---|---|
| `arc-lifecycle.bpmn` | editor-emitted | userTask, serviceTask, scriptTask, exclusiveGateway (human decision), 3 lanes (hum/frw/agt), start/end events, sequence-flow chain, `aef:io`/`aef:endpoint`/`aef:artifactsWrites`/`aef:decisionInput` |
| `harvest-pipeline.bpmn` | editor-emitted | **parallelGateway** fan-out/fan-in, dense scriptTask chain, multiple exclusiveGateways |
| `investigate.bpmn` | editor-emitted | parallelGateway + exclusiveGateway with `aef:decisionInput`, userTask + serviceTask mix, loop-back edge |
| `resume-status.bpmn` | editor-emitted | **subProcess** (composite), scriptTask chain, exclusiveGateway |
| `inception-gonogo.bpmn` | **hand-authored** (provisional) | Positive inception case for slice-3 detection: collapsed **`subProcess`** with `aef:meta workflowType="inception"` in a **sovereignty** lane (owner derives to human), `aef:constituents` members, go/no-go gateway **implied at the boundary** (T-081 phase-1 — no child gateway). Embodies the *provisional* **G-3 marker** (mapping-v1 Part II, pending v1.1 graduation) — **not** editor-emitted, **not** frozen. |

### 5.1 Worked example — `arc-lifecycle.bpmn` → proposed graph

Lanes: `human`=sovereignty, `framework`=authority, `agent`=initiative. `workflowMeta.tier_default=2`.
The compile proposes an **arc** (`arc-lifecycle`) with these member tasks (create proposals — all uids are
fresh `n_…`, none resolve to an existing task):

| uid | BPMN node | proposed type / owner | tier | depends_on (via edge) |
|---|---|---|---|---|
| `n_req` | startEvent `agt_1_arc` | *boundary marker* (no task) | — | — |
| `n_create` | scriptTask `agt_2_create` | build / agent | 1 | n_req |
| `n_start` | scriptTask `agt_3_start` | build / agent | 1 | n_create |
| `n_tag` | serviceTask `agt_4_tag` | build / agent | 1 | n_start |
| `n_bvp` | serviceTask `agt_5_bvp` | build / agent | 1 | n_tag |
| `n_approve_driver` | userTask `hum_1_approve` | human-facing / **human** | 0 | n_bvp |
| `n_work` | serviceTask `agt_6_work` | build / agent | 2 | n_approve_driver |
| `n_review` | scriptTask `agt_7_emit` | build / agent | 1 | n_work |
| `n_close_decide` | userTask `hum_2_close` | human-facing / **human** | 0 | n_review |
| `n_route` | exclusiveGateway `hum_3_close` | **decision** (decisionOwner=human) | — | n_close_decide |
| `n_close` | scriptTask `frw_2_close` | build / agent | 1 | n_route `close` branch |
| `n_abandon` | scriptTask `frw_1_abandon` | build / agent | 1 | n_route `abandon` branch |
| `n_end_closed` / `n_end_abandoned` | endEvents | *boundary markers* (no task) | — | — |

The gateway `n_route` yields a decision with two branches (`${decision=='close'}` → `n_close`,
`${decision=='abandon'}` → `n_abandon`), owner `human`. The whole graph is presented as **one proposal** for
a single sovereignty approval (§6) — nothing is authored until approved.

## 6. Proposal & sovereignty (non-negotiable)

The forward compile **proposes**; it never creates tasks directly. Per the framework's Core Principle and
IW-1/IW-3: the entire mapped graph is surfaced for **one batch sovereignty approval**; on approval the AEF
side authors the tasks (create) and/or updates them (modify). This preserves "nothing gets done without a
task" — the diagram is a proposal surface, not an authoring bypass. Enrichment (ACs, descriptions) happens
between compile and approval and is AEF-owned.

## 7. Editor-emission confirmation (832 side is ready)

`src/aef-workflow-designer.html` already emits the full v1 semantic vocabulary and a stable, externally
assignable `aef:uid` on every node and edge. No editor change is required for child-2's 832 side. Evidence:

- `tests/test_editor_bridge_meta_parity.py` (T-060) — editor `metaKeys` ⊆ bridge `META_KEYS` (green).
- `tests/test_mapping_standard_conformance.py` (T-182) — frozen v1 governance keys honored by editor + bridge (green).
- `tests/test_forward_fixtures.py` (T-183) — the reference corpus is v1-conformant (green).

## 8. Open items (AEF rulings, tracked on v1 Part II)

Deferred to AEF and pending on termlink thread T-175; on ruling they graduate into a v1.1 of both standards:
- **Enrichment output format** — the exact proposed-task-YAML shape and the AC-seed field.
- **Inception marker shape (G-3)** — **GRADUATED to v1.1** (mapping-v1 §7; 832 sovereign GO, T-195). The form is a
  collapsed `subProcess` + `aef:meta workflowType="inception"` in a sovereignty lane, with the go/no-go
  **implied at the boundary** (no child gateway); a gateway-less task-node is not acceptable. **O-3 (v1.1):** the
  go/no-go boundary MUST be sovereignty(human)-laned — the compiler asserts this and fails fast on a malformed
  inception. See §5 (`inception-gonogo.bpmn`) and mapping-v1 §7.
- **`tier` default** — canonical absent-value default vs. `workflowMeta.tier_default`.
