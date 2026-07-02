# T-023 — healing-loop: v2-schema friction report

```yaml
task: T-023
type: dogfood-friction-report
generated: examples/aef-processes/healing-loop.workflow.yaml
ground_truth: agents/healing/healing.sh, lib/diagnose.sh, lib/resolve.sh
validator: tools/validate-workflow.py  # exit 0 (after fixing one real YAML catch)
authored: 2026-07-03
prior_slices: [T-021-inception-lifecycle, T-022-task-lifecycle]
```

## What this is

Third dogfood slice. We generated a workflow for the **healing loop** — AEF's
antifragile recovery process, auto-triggered when a task hits `issues` — from its
vendored implementation, then validated it. (First pass failed on a genuine YAML
parse error in an `aef` list; the judge caught it, we fixed it, exit 0 — a small
but real datapoint that the standalone validator earns its place.)

The healing loop adds a dimension the first two slices did not stress:
**advisory execution**. The whole diagnose stage (classify → lookup → suggest)
is best-effort (`|| true`, non-blocking) and *binds nothing* — it emits a
recommendation and the human chooses whether/how to act. That is the AEF
authority model expressed as **node semantics**: initiative-lane nodes produce
advice, authority-lane nodes bind. v2 has no way to say so (F9).

Two new frictions (F9, F10). Four recur (F1, F3, F5, F7) — and **F3 and F5 are
now 3/3 across all slices**, which moves them from "systemic" to "load-bearing
v3 requirements."

## The process (ground truth)

Auto-triggered on task → `issues|blocked` (`update-task.sh:1687`, wrapped
`|| true` → advisory). Stages: **classify** (keyword-scoring →
{code, dependency, environment, design, external, unknown}, `diagnose.sh:5-21`)
→ **lookup** (RAG over `patterns.yaml` + episodic, `find_similar_patterns`) →
**suggest** (renders the Error Escalation Ladder A/B/C/D, all four shown;
`diagnose.sh:157-204`). Then a **human** picks a rung and applies a fix, and
**resolve** (`resolve.sh:74-140`) appends a pattern (FP-NNN) + learning (L-NNN) +
task note — the "strengthen from failure" step — after which the task is manually
returned to `started-work`. Ownership → swimlanes: agent advises (read-only),
human decides + acts, framework records. That mapped cleanly; the gaps are below.

## NEW friction

### [F9] No advisory/binding authority marker on a node or its output — r3 §3.2 / SD-8 · seam S4
The diagnose nodes (classify, lookup, suggest) **produce recommendations and
change no state** — they are advisory, and the whole sub-process is best-effort
(`|| true`). The resolve/resume nodes **bind** (write memory, change status).
This advisory-vs-binding split is the authority model at node granularity
(initiative produces advice; authority binds), and it is the product's core
differentiator — yet v2 has no field for it. We carried it as `aef.advisory:
true`, out of band. Without it, a consumer cannot tell a node that *suggests* a
fix from one that *applies* it — a governance-critical distinction.
- **v3 need:** a node/output authority marker (`authority: advisory|binding`, or
  derive it from the lane's authority level) that a strict runner honours (an
  advisory node may be skipped; a binding node may not).
- **Relation:** T-021 F2 (workflow-level execution.mode) is the coarse form;
  F9 is the per-node form and ties directly to the lane authority already in
  the schema — arguably the highest-value new construct so far.

### [F10] No first-class datastore / knowledge-base resource — r3 §2.5 / SD (Fabric) · seam S5
Lookup **reads** a persistent knowledge base (`patterns.yaml`, episodic memory,
via RAG); resolve **writes** two stores (`patterns.yaml`, `learnings.yaml`) plus
the task note. These are not workflow data (`io.inputs/outputs`) — they are
reads/writes against **framework memory stores** that outlive any run. v2 models
per-edge data flow but has no concept of a durable datastore/knowledge resource a
node binds to. We carried it as free-form `aef.reads` / `aef.writes` lists. The
entire antifragile mechanism (learning accretes into shared memory) is
structurally invisible.
- **v3 need:** a first-class datastore/resource type (a node declares
  `reads`/`writes` against named stores), aligning with the Component Fabric /
  Workflow Fabric (seam S5) so store references resolve and drift is detectable.

## RECURRING friction

### [F3↺↺] No per-node determinism marker — r3 P4 · seam S3/S1 — **3/3 slices**
classify (keyword scoring) and lookup (semantic RAG) are **stochastic**; suggest,
resolve, resume are **deterministic** fw-verbs. Third consecutive process to mix
them with no first-class marker. **Present in every process mapped so far** —
this is now a load-bearing v3 requirement, not a nicety.

### [F5↺↺] Auto-triggers / sub-process boundaries; no callActivity / onTransition — r3 SD-9 · seam S8 — **3/3 slices**
Healing *is* the sub-process T-022's F5 pointed at (fired on `issues`), and it in
turn hands back to the task lifecycle at resume (a second cross-process boundary).
Neither the inbound trigger nor the outbound handback is a first-class
composition node. **3/3 slices** — v3 needs `callActivity` + `onTransition`.

### [F1↺] Human decision → outgoing-edge mapping not first-class — r3 SD-11 · seam S6
The 4-way ladder choice (A/B/C/D) is a human decision that directs the recovery;
carried again as `aef.decisionOutputs`, with the act/skip fork modelled as a
plain gateway. 3rd distinct human-decision shape across slices (go/no-go/defer;
partial-complete; ladder rung) — all the same missing construct.

### [F7↺] State-machine / cyclic re-entry vs flow — r3 SD-2 · seam S2
Healing can fire repeatedly (a task may re-enter `issues`), and the advisory-only
exit leaves the state machine without recording — a state/transition property, not
a flow property. Same paradigm gap as T-022.

## Map to r3 SDs and the T-020 seam catalogue

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| F9 advisory/binding node marker | new | §3.2 / SD-8 | S4 | T-023 |
| F10 datastore / knowledge resource | new | §2.5 / Fabric | S5 | T-023 |
| F3 determinism marker | ↺ **3/3** | P4 | S3/S1 | T-021,22,23 |
| F5 callActivity / onTransition | ↺ **3/3** | SD-9 | S8 | T-021,22,23 |
| F1 human decision→edge | ↺ | SD-11 | S6 | T-021,22,23 |
| F7 state-machine vs flow | ↺ | SD-2 | S2 | T-022,23 |

## Conclusion

Three processes mapped, three clean validations, zero generation failures — the
generation logic is robust across linear-flow, cyclic-state-machine, and
advisory-recovery shapes. Friction remains pure carrying-capacity. The
cross-slice picture is now the real deliverable:

- **F3 and F5 are 3/3** — universal across every AEF process. v3 MUST have a
  determinism marker and a callActivity/onTransition construct.
- **F1 is 3/3 in substance** (three different human-decision shapes, one missing
  construct — decision-outputs→edges).
- **F9 (advisory/binding node authority)** is the standout new finding: it
  encodes the AEF authority model into node semantics and is the product's
  differentiator; it should be a first-class v3 field, likely derived from lane
  authority.

**Feeds:** M1 (validator → v3 structural parity) and Lock-1 schema-v3, with a
now-evidence-backed priority order: F3, F5, F1 (universal) → F9 (authority
semantics) → F7 (state machine), F8 (gate-sets), F10 (datastores).
**Next dogfood candidates:** tier0-escalation, arc-lifecycle, assumption
validation.
