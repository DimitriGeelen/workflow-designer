# arc-005 · process-instances — scope

**Modelled processes you can instantiate and watch**

**Status:** DRAFT — not started. `fw arc start process-instances` is deliberately not run
until the operator ratifies §1–§4. Authored under T-874, 2026-09-27.

---

## 1. The arc questions

### A1 — Goal, as something a user observes

> An operator opens `task-lifecycle` in the designer, sees it marked as a **template** rather
> than an actionable work-plan, creates an **instance** of it bound to a real task number, and
> watches that instance advance node by node as the task moves — with an out-of-order advance
> **refused** and written to the audit log.

### A2 — Trace to project purpose

| project goal | how this arc advances it |
|---|---|
| **G2** class distinguishable from instance | S1 ships the marker. Directly. |
| **G3** an instance knows its class | S2 defines and builds the binding. Directly. |
| **G4** execution observable and guarded | S3 (refusals) + S4 (the view). Directly. |
| G5 second tenant | enabled, not delivered — Sprind can only model instances once instances exist |
| G6 idea→implementation round-trip | protected — S1 stops the promote path instantiating a picture |

An arc that could not name a goal here would be a new goal to ratify or should not open. This
one names three.

### A3 — Type

**BOUNDED.** It has a coherent closing event: the A1 demo fires end to end. It is not an
ongoing obligation.

(Contrast `arc-003`, which this project should re-mark **CONTINUOUS** — see the purpose doc
§4. That is a separate change and not carried here.)

### A4 — Exit

`fw arc close process-instances --demo <path>` with wire-level evidence of A1: a recorded
run showing the template marker read, an instance created against a real task id, at least
one legitimate advance accepted, and **at least one illegitimate advance refused with its
audit-log line**. The refusal is the load-bearing half — an execution view that only ever
shows success has not demonstrated a guard.

### A5 — Per-task check

Every task below carries this in its own body, asked **at creation and again at arc review**:

> *Does this task deliver arc purpose (A1) and project purpose (§2 of the purpose doc)?*

Not asked at every close: at close the answer is reflexively yes, because the work is done.

### A6 — Has it bitten?

**Not yet — the arc has not started.** This section is a ledger, updated at each arc review
with the count of A5 **no** answers and what happened to each (cut / rescoped / re-parented).

**If this section still reads "0 no answers" at arc close, the review must say so explicitly
and treat A5 as decoration rather than governance.** That clause is carried verbatim in
principle from `sprind:pickup` offset 7 and is the single most important line in this
document.

---

### Why a new arc rather than more of arc-001

arc-001 is *"Workflow Designer as AEF's process-authoring surface"* — its headline mechanic is
about **authoring**: a human draws a process, AEF turns it into governed work, existing work
renders back as a map. Instantiation and execution monitoring are not authoring. A template
being *drawn* is arc-001; a template being *run against real work and watched* is a different
observable and needs its own demo.

The counter-argument, stated because it is real: T-279–T-282 (the July package's open gap
tasks) are currently tagged `arc:designer-authoring-surface`, so arc-001 has been the de-facto
home for this work — and it has sat untouched there since 2026-07-28. Being an unstarted
minority inside a 31-task authoring arc is part of why. A separate arc with its own goal and
its own A6 ledger is the change most likely to alter that outcome.

**This re-parents scope away from arc-001 and is therefore the operator's call, not ours**
(§5.2). Nothing has been moved: T-279–T-282 keep their arc-001 tags and their criteria.

## 2. What is already true (so the arc is not re-deriving it)

Measured 2026-09-27 against the live tree.

- The 24 corpus maps **are** the classes: `task-lifecycle`, `inception-lifecycle`,
  `inception-review`, `arc-lifecycle`, `verification-gate`, `tier0-escalation`,
  `release-pipeline`, …
- Step content is **largely captured already**: `aef:decisionInput` ×102, `aef:io` ×56,
  `aef:decisionOutputs` ×46, `aef:output` ×31, `aef:artifactsWrites` ×21,
  `aef:contextReads` ×19, `aef:input` ×12, plus `aef:meta` `decisionOwner` ×54, `guard`,
  `exitCode`, `state`, `terminalKind`, `triggeredBy`, `autoTrigger`.
- `aef:workflowMeta` carries `version, uuid, title, schemaVersion, id, default` — and
  **no `kind`**.
- There is **no** instance record, **no** binding, **no** gated setter (SD-10, verbatim).
- One hairline of the eventual mechanism exists: `update-task.sh:249` names the enforcing
  node (`tl_archive`) in the map when a task-lifecycle gate trips.
- Round-trip identity is delivered and guarded (V3 / G-002) — S1 must not break it.

## 3. Slices and build tasks

### S1 — A class is declarable, and nothing instantiates a picture *(buildable now)*

Revives **T-213**, GO'd 2026-07-21 and unbuilt for 68 days. Its live defect: AEF's
`fw bpmn promote` mints real `owner:human` tasks from illustrative nodes (their L-504 /
T-2548–9).

| task | deliverable |
|---|---|
| **B1 · T-875** | `aef:workflowMeta kind=` — closed enum `{documentation, work-plan}`, **default UNSET**, additive and frozen-v1 safe. Absent/unknown `kind` round-trips byte-identical. Validator rule + conformance test. Exactly as T-213's IW-1/IW-2/IW-3 disposed it. |
| **B2 · T-876** | Corpus backfill: mark the 24 AEF maps `documentation`. Control leg: an unmarked map still round-trips byte-identical, so the guard proves the default is inert. |
| **B3 · T-877** | Seam notice to AEF: the marker exists, here is its shape, their promote path is theirs to change. Rail post, no code. |

**On the enum, and this is a deliberate restraint.** T-213 disposed the values as
`{documentation, work-plan}` with a note that a third (e.g. `template`) may be added later
additively. `kind` answers *"is this map illustrative or actionable"*. That is **not** the
class/instance axis: an instance is a distinct object with identity and state that
*references* a template. Conflating them by quietly widening a ruled enum would bury a real
modelling question inside a build task. So S1 ships the enum as ruled, and whether
class/instance needs `kind` at all is S2's question.

### S2 — An instance exists and knows its class *(inception first)*

The genuinely unresolved part. **SD-10 was never decided** — "no binding, no instance files,
no gated setter".

| task | deliverable |
|---|---|
| **B4 · T-878** | **Inception:** what is an instance, where does its identity live, and what binds it to a real entity (`T-NNN`, an inception id, a sprint item)? One question, one go/no-go. Must state the storage home, the identity scheme, and whether the binding is authored or derived. |
| **B5 · T-880** | *(post-GO)* the instance record itself + `fw` verb to create one |
| **B6 · T-881** | *(post-GO)* resolution both ways: given `T-873` name its template and node; given a template list its live instances |

**T-878 (B4) is an inception and not a build task on purpose.** Filing B5/B6 as build tasks now would
be exactly the G-020 failure this project has a rule against — a detailed spec read as
authorisation. T-880/T-881 are filed `captured`, `horizon: later`, and say in their own bodies that a NO-GO or a different design means they are **deleted or rewritten, not adapted**.

### S3 — Advancing an instance is guarded *(inception first)*

Revives **SD-8**'s ladder — `advisory` (today, by convention) → `guided` (the target) →
`strict` (out of scope) — and success criterion **V7**, still NOT STARTED.

| task | deliverable |
|---|---|
| **B7 · T-879** | **Inception:** the guided-mode ladder. This is the live half of the captured **T-279** — which currently bundles SD-8, SD-10 *and* SD-11 and therefore violates "one inception = one question". Proposal: **split T-279**, leaving it as the SD-8 ladder question, with SD-10 going to B4 and SD-11 (humanTouchpoint) deferred out of this arc. |
| **B8 · T-882** | *(post-GO)* `advance` with validation against the template, refusal on an illegitimate transition |
| **B9 · T-883** | *(post-GO)* the three V7 refusals, each landing in the audit log: out-of-order advance · skipped human gateway · unmet input contract |

### S4 — The operator can see where an instance is *(gated on S2+S3)*

| task | deliverable |
|---|---|
| **B10 · T-884** | Designer renders instance state over its template: current node, completed nodes, the node a refusal fired on |

This is the half that makes the other three visible, and it is the demo in A4.

### Out of scope, named with reasons

| item | why not here |
|---|---|
| **pseudocode carrier + audience lenses** (SD-14 → T-281) | serves **G1** (capture completeness), not G2/G3/G4. Its own arc. It is the one gap in G1 and should not wait long. |
| **callActivity + ioMapping** (SD-9 → T-282) | composition, serves G1/G6 |
| **Workflow Fabric / process-dependency graph** (SD-15 → T-280) | a graph *over* processes; needs instances to exist first |
| **second tenant / Sprind** (G5) | enabled by this arc, delivered after it |
| **`strict` mode** (framework drives execution) | explicitly out per SD-8; anything that actually *runs* is arc-002/EWCR |
| **humanTouchpoint** (SD-11) | bundled into T-279 today; deferred deliberately, not forgotten |

## 4. Risks

1. **S1 breaks round-trip identity.** V3/G-002 is a delivered, guarded property. Mitigated by
   B2's control leg — an unmarked map must round-trip byte-identical, proving the default is
   inert. This is the risk most likely to cause real damage.
2. **The frozen standard.** `aef-bpmn-mapping-v1` Part I is frozen and not ours to edit.
   `kind` is additive on `aef:workflowMeta` and T-213 disposed it as frozen-v1 safe — but the
   claim is re-checked in B1 rather than inherited.
3. **AEF owns the promote path.** S1 makes the marker available; it cannot make AEF read it.
   B3 is a notice, and the defect only closes when they act. **State this rather than claim
   the defect closed at B3.**
4. **S2 may come back NO-GO.** If instances cannot be bound without hand-maintenance, G3 and
   G4 collapse and the honest outcome is that this is documentation tooling. The purpose doc
   §P5 names that as a stop condition. The arc must be allowed to produce that answer.
5. **Inception-to-build decay.** This project's measured rate is **26 of 30 GO decisions with
   no successor filed** — including T-213's, unbuilt 68 days, and T-685's, 15. B4 and B7 are
   inceptions; on GO, their build tasks must be filed in the same session.

## 5. What the operator is asked to ratify

1. §1 A1–A4 — goal, trace, bounded, exit.
2. **The T-279 split** (B7) — one inception carrying three SD questions becomes one question.
3. **S1 ships T-213's enum as ruled**, with class/instance deferred to S2's question.
4. That T-880/T-881/T-882/T-883/T-884 stay `captured`/`later` and contingent until their
   inception returns GO.
5. **Arc type support.** A3 marks this arc BOUNDED, but `lib/arc.sh` has **no type field at
   all** — `fw arc close` demands demo evidence from every arc and `abandon` is the only other
   exit. BOUNDED/CONTINUOUS is therefore a modelling proposal recorded in prose, not a state
   the tooling can hold. Making it real is a framework change and is **not** in arc-005.

## 6. Task manifest

| slice | task | state | gate |
|---|---|---|---|
| S1 | **T-875** kind marker schema + validator | captured / now | ready |
| S1 | **T-876** corpus backfill + inert-default control | captured / now | after T-875 |
| S1 | **T-877** seam notice to AEF | captured / now | after T-875 |
| S2 | **T-878** inception — what is an instance | captured / now | ready |
| S3 | **T-879** inception — SD-8 ladder (T-279 split) | captured / now | after T-878 |
| S2 | T-880 instance record | captured / later | T-878 GO |
| S2 | T-881 two-way resolution | captured / later | T-878 GO |
| S3 | T-882 guarded advance | captured / later | T-878 + T-879 GO |
| S3 | T-883 three V7 refusals audited | captured / later | T-879 GO |
| S4 | T-884 designer instance view | captured / later | T-878 + T-879 GO |

Ready to start on ratification: **T-875, T-878**. Everything else is sequenced behind one of
those two.
