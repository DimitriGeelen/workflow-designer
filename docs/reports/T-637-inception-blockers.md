# T-637 — what actually blocks each outstanding inception ruling

Measured 2026-08-30. Nothing here records a decision; `fw inception decide` was not
invoked. This is the evidence a ruling needs, gathered so the ruling is cheap.

## The headline

**There are ten undecided inceptions, not eight.** Handovers have carried the same eight
for weeks. Two more — T-498 and T-619 — are undecided, active, and have never appeared in
a handover, because the scan that surfaces this population selected on *"carries a revisit
date"* rather than *"was never ruled on"*. Fixed in this task; both now surface.

**No deferral trigger has fired for any of the eight.** Each carries a specific,
testable `revisit_evidence_needed` sentence. Measured one by one below: none has occurred.

**The eight were deferred in prose and never in structure.** The deferral is stated in the
commit messages that created them — *"children 3-5 registered deferred with revisit
triggers"*, *"inceptions, DEFER/later"* — and in their `revisit_evidence_needed` fields.
It is absent from `## Decision`, the only place any gate reads. So the framework has
correctly reported them as unruled ever since, and the operator has correctly read that as
a queue. Both are right; the queue is an artefact of a decision that was made and not
recorded.

*Attribution caveat:* every commit in this repo carries one git identity, agents included,
so authorship cannot establish who deferred them. What the record supports is that the
deferral was **stated at creation time**, not that the operator personally stated it. That
distinction is the operator's to close, and it is the whole content of the ruling.

## The ten, with the specific blocker

| Task | Blocker class | What specifically stands in the way | Trigger fired? |
|---|---|---|---|
| T-184 Reverse discovery | OPERATOR-ONLY | Record the DEFER. Revisit 2026-10-01 | **No** — "a concrete request to render an AEF record as an editable map": rail mentions it only in our own @695 |
| T-185 Collaboration/concurrency | OPERATOR-ONLY | Record the DEFER. Revisit 2027-01-15 | **No** — no request for two parties editing one map exists |
| T-186 Hosting and tenancy | OPERATOR-ONLY | Record the DEFER. Revisit 2027-01-15 | **No**, with one judgment call — see note below |
| T-277 Conformance key / stateKind | OPERATOR-ONLY + external | Record the DEFER. Revisit 2026-12-01 | **No** — trigger is "AEF pings the T-2652 thread with a GO"; T-2652 appears on the rail only in our own @695 |
| T-279 Guided-mode guardrail | OPERATOR-ONLY | Record the DEFER. Revisit 2026-09-15 (soonest) | **No** — trigger is an operator decision, or a third instance of a prose process being re-interpreted |
| T-280 Workflow Fabric SD-15 | OPERATOR-ONLY | Record the DEFER. Revisit 2026-12-01 | **No** — no cross-process query has gone unanswered |
| T-281 Audience render lenses | OPERATOR-ONLY | Record the DEFER. Revisit 2027-01-15 | **No** — no non-technical reader has been blocked |
| T-282 callActivity SD-9 | OPERATOR-ONLY | Record the DEFER. Revisit 2026-12-01 | **No**, and measured on our own corpus: all 24 maps use handoff or return-of-control, never call-with-return (@695 Q2) |
| **T-498** Onboarding-arc scope | OPERATOR-ONLY, **and its agent half is now closed** | One yes/no confirmation — see below | n/a |
| **T-619** Retry-safety declaration | External (AEF) + OPERATOR-ONLY | AEF has not returned a vocabulary; overturn condition unfired | n/a |

**T-186's judgment call.** T-283, *"app-flavored second-tenant example map"*, is
work-completed. T-186's trigger is "a second tenant **or** a non-local deployment
requirement". An example map is a demonstration artefact, not a tenancy requirement, so on
the trigger as written this has not fired — but it is the nearest thing to it in the tree
and the reading is yours, not mine.

## What changed on the agent's side of the line

**T-498 — its open question is now answered.** Its own recommendation was *"DEFER until
the arc set here is enumerated and the premise confirmed with the operator."* Enumerating
was never the operator's job. Measured: **this project has exactly one arc**,
`designer-authoring-surface` (arc-001, in-progress). There are no onboarding arcs here at
all. The arcs named `onboarding-shape-detection` and `onboarding-curriculum` appear on the
rail at @621 as **AEF-side** arcs. So T-498 is no longer an exploration; it is one
question: *did you mean the peer project's arcs?* If yes, T-559 puts them out of our reach
and this is NO-GO. If no, the premise needs restating.

**T-619 — "blocked on AEF" tested rather than repeated.** Its NO-GO now rests on a single
leg, ownership, with an explicit overturn: *"the moment Arc 1 returns a key name + value
set."* Measured across all 107 rail posts since the question went out at @636: **zero**
mention of the retry-safety vocabulary from AEF. 001-CashWeb replied at @637 with
corroborating evidence from their own corpus but explicitly declined to rule — *"we are a
consumer project of this vocabulary and not a party to Arc 0/1; those belong to 999 and to
your operator."* The overturn condition has not fired. Waiting is not a strategy: the
channel is extremely active and simply not engaging this question.

**The five DEFER-maturation questions at @695 have had zero engagement** across 107
subsequent posts — measured by searching every one for their subject matter (callActivity,
SD-9/14/15, conformance key, stateKind). This is not silence from an idle channel.

## What is NOT stale

Checked against the code rather than the task text, because a task file describing the
world is not the world. `callActivity` **does** appear in `src/aef-workflow-designer.html`
— one occurrence, inside a comment about telling a callActivity from a transaction. The
node type is not built. `stateKind`, render lenses and process-dependency graph: zero
occurrences. **No inception in this set is stale.** Reporting "already shipped" from the
filename list alone would have been wrong for T-282, which is why the check exists.

## Reconciliation with the T-307 briefs

`docs/reports/T-307-inception-decision-briefs.md` covers **eight** of the ten. It does not
cover T-498 or T-619, which is consistent — both postdate it. Its briefs offered the
revisit fields **conditionally**, "IF you ratify all nine as DEFER"; the condition was
never met and the fields were applied anyway (commit 7ed9643b, T-575). That is the origin
of the machinery-without-the-decision state, and it is recorded here rather than guessed.

## The operator route

All ten are one command each. Copy-pasteable, single line, from any directory:

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task review T-184
```

Then the same for T-185, T-186, T-277, T-279, T-280, T-281, T-282, T-498, T-619 — and
record each decision on the Watchtower page for that task:

```
http://192.168.10.107:3013/inception/T-184
```

Queue view: **http://192.168.10.107:3013/approvals**

Also genuinely due, and separate from the ten: **T-155** carries a recorded DEFER whose
revisit date (2026-08-21) fired nine days ago. It needs closing, not deciding.

## What this changes about the ask

Before this task the ask was "rule on eight inceptions". After it, for the eight, the ask
is narrower: **confirm a DEFER that was stated when they were created, whose trigger has
demonstrably not fired, and whose revisit dates are all still in the future** (soonest
2026-09-15, furthest 2027-01-15). The two new ones are genuinely open and each is a single
question. That is the difference between a queue and a decision.
