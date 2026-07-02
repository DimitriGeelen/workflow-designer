# Dogfood v3 design inputs — cross-slice friction synthesis

```yaml
type: design-input-synthesis
task: T-024 (refreshed through T-025 by T-026)
authored: 2026-07-03
campaign: first-dogfood (T-021 inception, T-022 task, T-023 healing, T-025 tier0)
sources:
  - docs/reports/T-021-inception-lifecycle-friction.md
  - docs/reports/T-022-task-lifecycle-friction.md
  - docs/reports/T-023-healing-loop-friction.md
  - docs/reports/T-025-tier0-escalation-friction.md
  - docs/reports/T-020-independent-product-aef-injection-boundary.md   # seam catalogue S1-S8
corpus:
  - examples/aef-processes/inception-lifecycle.workflow.yaml
  - examples/aef-processes/task-lifecycle.workflow.yaml
  - examples/aef-processes/healing-loop.workflow.yaml
  - examples/aef-processes/tier0-escalation.workflow.yaml
```

## Purpose

Four dogfood slices each generated a workflow for a **real vendored AEF
process** and validated it with the standalone judge (`tools/validate-workflow.py`).
All four passed (exit 0); the generator handled four structurally different
shapes — a mostly-linear flow (inception), a cyclic state machine (task), an
advisory recovery loop (healing), and an ambient enforcement guard (tier0) — with
zero generation failures. This document
consolidates what that exercise was *for*: the points where the current **v2
canonical schema cannot express the real process**, turned into a prioritized set
of **v3 design inputs**.

The core result is not any single friction — it is the **recurrence pattern**.
A gap that appears in one process is a candidate; a gap that appears in all three
independent processes is a load-bearing requirement. That distinction is the
synthesis's main contribution to M1 / Lock-1 prioritisation.

## Method note

Every friction is **carrying-capacity**, not structural-validity: v2 validates the
*structure* (nodes, edges, lanes, uniqueness, gateway outflow) but cannot *hold*
the semantics the process carries. Each was surfaced by being forced to stash real
process meaning in the free-form `aef:` bag — the fact that it had to go there,
with no first-class field, IS the finding. (The judge also caught a genuine YAML
error during T-023, a small confirmation that the standalone validator earns its
place independent of the schema-expressivity question.)

## Consolidated friction register (F1–F12)

Recurrence = number of the **four** slices mapped so far (T-021 inception,
T-022 task, T-023 healing, T-025 tier0) in which the friction appears.

| ID | Friction | Recurrence | r3 anchor | T-020 seam |
|----|----------|:----------:|-----------|:----------:|
| **F3** | No per-node determinism marker (agent-stochastic vs fw-verb-deterministic) | **4/4** | P4 | S3 / S1 |
| **F1** | Human decision → outgoing-edge mapping not first-class | **4/4** (4 shapes) | SD-11 | S6 |
| **F5** | Auto-triggers / sub-process boundaries — no `callActivity` / `onTransition` | **3/4** | SD-9 | S8 |
| **F7** | Lifecycle is a state machine; schema models flow (cycles as backward edges) | 2/4 | SD-2 | S2 |
| **F4** | Tier-0 human-gate semantics not a first-class gate property | 2/4 | §3.2 | S4 / S6 |
| **F8** | Transition guard / gate-SET with per-gate bypass not first-class | 2/4 | §3.2 / SD-8 | S4 / S3 |
| **F9** | No advisory/binding authority marker on a node or its output | 1/4 | §3.2 / SD-8 | S4 |
| **F2** | No workflow-level `execution.mode` (advisory\|guided\|strict) | 1/4 | SD-8 | S3 |
| **F10** | No first-class datastore / knowledge-base resource (RAG read, pattern/learning write) | 1/4 | §2.5 / Fabric | S5 |
| **F6** | No workflow governance status / `ratified_by` | 1/4 | SD-4 | S4 |
| **F11** | No ambient / boundary-interrupting guard construct (Tier-0 fires on *every* command) | 1/4 (new) | §3.2 (new SD) | S4 |
| **F12** | No single-use / expiring capability (approval-token) construct | 1/4 (new) | SD-4 / §3.2 | S4 |

### Per-friction detail (with slice provenance)

- **F3 — determinism marker (3/3).** Inception: agent files a recommendation +
  conducts exploration (stochastic) vs fw-verb create/review/decide (deterministic).
  Task: perform-work vs start/gates/finalize. Healing: classify + RAG lookup vs
  resolve/resume. *Universal.* The stochastic/deterministic frontier is exactly the
  product's injection thesis ("stop at the execution/resolution boundary") and has
  no home in v2.
- **F5 — callActivity / onTransition (3/3).** Inception: DEFER is a sub-process
  (inject stubs + revisit_at). Task: healing fires on `issues`, episodic-gen on
  `work-completed`. Healing: it *is* that sub-process, and hands back to the task
  lifecycle at resume. Auto-triggers and cross-process handoffs are everywhere;
  v2 has neither a sub-process node nor a transition hook.
- **F1 — human decision → edge (3/3, three shapes).** go/no-go/defer (inception);
  the owner=human partial-complete branch (task); the A/B/C/D ladder-rung choice
  (healing). One missing construct — decision-outputs bound to outgoing edges —
  behind three different-looking gateways.
- **F7 — state machine vs flow (2/3).** Task and healing are cyclic state machines;
  states were demoted to pass-through activities with an out-of-band `aef.state`
  tag and cycles rendered as backward edges. Governance processes are predominantly
  state machines, so this tax compounds.
- **F9 — advisory/binding node authority (new, 1/3, high value).** The healing
  diagnose stages *advise* and bind nothing (best-effort `|| true`); resolve/resume
  *bind*. This is the AEF authority model at node granularity (initiative advises,
  authority binds) — the product's differentiator — with no schema field. Likely
  derivable from lane authority.
- **F8 — transition gate-set with per-gate bypass (1/3).** The `work-completed`
  battery: R-033/P-010/P-011/G-019/T-1718, AND-composed, each `--skip-*` bypassable.
  Modelled as one opaque scriptTask. **F8 generalises F2 and F4** (both are special
  cases of "a transition carries declared, individually-overridable guards").
- **F2 / F4 — execution mode / Tier-0 gate (1/3 each).** The coarse (workflow-mode)
  and single-gate forms of the same enforcement gap F8 covers in general.
- **F10 — datastore / knowledge resource (new, 1/3).** Healing reads the pattern/
  episodic knowledge base (RAG) and writes patterns + learnings — durable stores
  outliving any run, distinct from per-edge data. The antifragile learning
  mechanism is structurally invisible. Maps to the Component/Workflow Fabric (S5).
- **F6 — status / ratified_by (1/3).** The definition's own governance lifecycle
  (proposed→ratified→deprecated, ratified=immutable) — the CRUD-symmetry guardrail
  the Sovereign flagged. Seen structurally only in inception so far but applies to
  every definition.

## Prioritized v3 / M1 roadmap

Ordered by evidence strength (universal first), then by leverage (constructs that
subsume others), then by product-differentiation value.

1. **F3 determinism marker** — universal (3/3), cheap, and the injection-line
   primitive. *M1 candidate now:* add a `determinism` (or `kind: agent|verb`) node
   field + a validator rule. Lowest-risk, highest-frequency win.
2. **F5 callActivity + onTransition** — universal (3/3). Add a `callActivity`
   node type and a transition-hook construct; unlocks composition (Workflow Fabric,
   S8) and every auto-trigger.
3. **F1 decision-outputs → edges** — universal (3/3). First-class human/decision
   node whose declared outcomes map to outgoing edges; add a validator coverage
   rule (every declared outcome has an edge; every conditional edge a declared
   outcome). Directly serves seam S6.
4. **F9 advisory/binding node authority** — new but high-leverage: encodes the
   authority model into node semantics; likely *free* from lane authority. Pair
   with a validator rule (an initiative-lane node may not be marked binding).
5. **F8 transition gate-set (subsumes F2, F4)** — one construct closes three
   frictions. A transition carries an ordered list of `{gate, rule, bypass, tier}`;
   strict runner enforces. Do this instead of F2/F4 separately.
6. **F7 state-machine representation** — larger change (paradigm). Minimum viable:
   promote `aef.state` to a schema field + a `kind: state` marker so the state
   machine is legible without a full state/transition redesign.
7. **F10 datastore / knowledge resource** and **F6 status/ratified_by** — governance
   completeness; couple to the Fabric work (S5) and the CRUD-symmetry ratification
   model respectively.
8. **F11 ambient/boundary guard** and **F12 single-use capability token** — the
   *enforcement* half of the Process-layer thesis (surfaced by the tier0 slice,
   T-025). Both map to §3.2 / SD-4 (seam S4). F11 declares a guard once and
   applies it to a node class/tier rather than hand-placing it; F12 is a
   scoped, single-use, expiring authorization a strict runner consumes. Land
   these with the F8 gate-set work — together they are "enforcement" in v3.

**M1 (validator → v3 structural parity) immediate slice:** items 1–4 are all
expressible as additive node/edge fields + validator rules on top of the existing
T-017/T-018 engine — no execution runtime required, so they stay cleanly on the
product side of the injection line. Items 5–8 are schema-shape / enforcement
changes that should land as a coordinated v3 bump.

## Coverage and next campaign

Processes mapped: **4 of ~8** high-regression candidates (inception, task,
healing, tier0). Clean-validation rate: **4/4**. Frictions catalogued: **12**
(F3 and F1 are universal at 4/4; F5 3/4; F4/F8 2/4; the rest process-specific but
all mapping to open r3 SDs). The enforcement pair F11/F12 was the tier0 slice's
new yield.

**Un-mapped dogfood candidates (next campaign):** arc-lifecycle (arc membership +
slice boundaries — likely new composition/grouping friction), assumption
validation, session handover, decommission. Each new process either hardens a
recurrence count or surfaces a genuinely new gap; both outcomes are useful.
Recommend continuing until the friction register stops growing (a "friction-dry"
signal), which is the true completion criterion for the v3 input-gathering phase.

**Hand-off (T-020 M5):** this document is the intended pickup for the framework
agent when v3 schema work begins — the friction register + roadmap are the
contract, anchored to the r3 SDs so "independent" stays "convergent."
