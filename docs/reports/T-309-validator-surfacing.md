# T-309 — Surfacing validator findings in the designer: exploration

**Task:** T-309 (inception) · **Opened:** 2026-07-29 · **Status:** frame filled, exploration not yet run

Written per C-001: the artifact is created before the research and grown as findings arrive. What is
below the line is what has actually been established; everything else is still a question.

## The one question

The workflow validator's rules already exist and are already trusted. Should they reach the person
authoring a map in the designer — and if so, where, how, and with what authority?

## What is already established (before any exploration)

These were verified while filing the task, not assumed:

1. **The rules exist on both serialization paths.** `tools/validate-workflow.py` has two validator
   classes — `Validator` (YAML, from line 101) and `XmlValidator` (BPMN, from line 644). Rules
   observed: `E-GW-OUTGOING` (exclusiveGateway needs ≥2 outgoing, ERROR), `W-GW-AMBIGUOUS` (>1
   unconditioned outgoing edge), `W-PGW-CONDITION` (condition on a parallel fork — "did you mean an
   exclusiveGateway?"), `W-PGW-NOOP`, `W-PGW-UNBALANCED`, `W-UNREACHABLE`, `W-DEADEND`, plus
   constituents and required-I/O checks. The validator suite is green at **34 passed, 0 failed**, and
   its test names confirm the XML mirrors carry the same rule ids (`W-XML-PGW-CONDITION`,
   `W-XML-UNREACHABLE`, …).

   *Correction worth recording:* an initial reading of this — from seeing `healing-loop.bpmn`
   validate clean while its YAML source also validated clean — suggested the BPMN path lacked the
   semantic rules entirely. That was wrong. Running the validator suite showed the XML mirrors are
   present and tested; `healing-loop` is simply clean, because its only gateway has two properly
   conditioned outgoing edges. The gap is reach, not coverage.

2. **The editor has no validation surface.** A grep of `src/aef-workflow-designer.html` for
   `validate` returns only unrelated hits (a zoom-mechanism comment, waypoint invalidation, a routing
   bounding-box helper). Nothing calls the validator; nothing displays a finding.

3. **"Nodes need at least one connection" is already covered.** An orphan node trips both
   `W-UNREACHABLE` (not forward-reachable from any startEvent) and `W-DEADEND` (no endEvent reachable
   backward). `linkEventCatch` is seeded as an additional forward entry point and `linkEventThrow` as
   a backward terminus, so off-page connectors do not false-positive.

4. **The triggering example is NOT caught by any current rule.** `fw_3_failure` — an
   `exclusiveGateway` labelled "failure type?" with six outgoing branches (external, dependency,
   unknown, design, environment, code) all targeting the single node `fw_4_lookup`. Exclusive is the
   semantically correct gateway here: a failure has one type, and a parallel gateway would activate
   all six branches at once. The smell is the immediate reconvergence — six branches that differ in
   nothing downstream are a data field, not a decision. No rule covers "XOR whose outgoing flows all
   share one target".

5. **The map is not ours.** `fw_3_failure` does not appear anywhere in this repo. Neither do
   `aef-task-lifecycle`, `aef-tier0-escalation` or `draft-knowledge-leveling`; our corpus carries the
   unprefixed `task-lifecycle` and `tier0-escalation`. These are AEF-authored maps reaching us
   through the gallery, so any rule that fires here fires on peer content — a rail conversation under
   the T-559 contract+fixture seam, not a purely local feature.

## Open questions

Filed on the task as IW-1..IW-5 (where findings surface / how the rules reach the browser / advisory
vs blocking / whether the missing rule is part of the deliverable / what the corpus baseline is).
Dispositions and evidence land here as the exploration runs.

**IW-5 is sequenced first deliberately.** If ordinary corpus maps already light up with warnings, the
feature is dead on arrival however well it is built, and every other question becomes moot. Measure
before designing.

---

## Findings

*(empty — exploration not yet run)*

## Recommendation

*(empty — no recommendation until the spikes above have run. Filing-time advisory was GO on the
problem being worth solving; that is not a substitute for a priced recommendation.)*
