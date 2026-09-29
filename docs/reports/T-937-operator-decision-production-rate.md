# T-937 — Why do agents generate operator decisions faster than any human answers them?

**Status:** inception, exploration NOT yet run. This file exists *before* the research, per C-001 — the
thinking trail IS the artifact, and conversations are ephemeral. Updated incrementally as each spike
lands, committed as it goes.

**Recommendation:** DEFER. The exploration has not run; a verdict now would be a guess in a verdict's
clothes.

---

## Problem statement

The operator holds 79 open acceptance criteria across 70 active tasks: **51 rulings, 24 reviews, 4 acts,
and zero delegable.** The zero is measured, not assumed — `fw task delegate` refused both candidates
offered to it today and was right both times.

Two attempts this week to shrink that number by reclassification failed, for the same reason: the
criteria are correctly classified. `[REVIEW]` is the right prefix for 79 of 81. The one intervention that
*did* work — T-931's ownership fix — removed 45 **stale** claims, where the field asserted a judgement
requirement already satisfied or never written. What remains is real.

So this is not a labelling or delegation problem. It is a **production-rate** problem: agents raise
operator questions faster than one human answers them. An earlier task measured a median unanswered-AC
age of **42 days** and concluded, in its own words, *"we are asking too much, and that is ours to fix
rather than theirs."* T-872 then built the docket, which lowered the cost of *access* and states outright
that it does not reduce the count.

This inception asks what neither addressed: **why is the rate what it is, and is any of it avoidable?**

## Why an inception and not a build

Three remedies are available and they differ enough in effort that picking one before measuring is the
mistake this task exists to avoid:

| remedy | true if… |
|---|---|
| Ask fewer questions | a material share of the 51 was already covered by an existing ruling → the defect is escalation discipline, and it is ours |
| Make questions cheaper to answer | the 51 are genuinely the operator's but expensively phrased → authoring standards (the docket already did the cheap version) |
| Change the settling mechanism | they are genuinely the operator's *and* already cheap → the only lever left is something other than one human answering serially |

Nothing in the corpus distinguishes these. That is the exploration.

## Open questions (IW-1 … IW-5)

Filed in the task file with confidence and disposition fields; summarised here.

- **IW-1 — rate or one-off?** Are criteria created faster than ticked over 90 days, or has the pile
  stopped growing? Everything downstream depends on it.
- **IW-2 — avoidable? (load-bearing)** Could a material share of the 51 have been settled under a ruling
  that already exists? If ~none, there is no agent-side fix and saying so plainly is the deliverable.
- **IW-3 — concentrated or spread?** Concentration admits a targeted fix; an even spread does not.
- **IW-4 — does age mean neglect or correct prioritisation?** If the oldest are the lowest-value, the
  ordering works. If the oldest are HIGH-value, that is a worse finding.
- **IW-5 — is there another settling mechanism?** Deliberately unspiked until IW-2 is settled: proposing
  new authority before showing the current authority is saturated would be a bypass looking for a reason
  (PD-302).

## Assumptions to test

| # | assumption | falsified by |
|---|---|---|
| A1 | Production rate exceeds answer rate | created-vs-ticked per week over 90 days coming out close |
| A2 | A material share of the 51 was already ruled on | a read sample where ~none map to a prior ruling |
| A3 | Backlog concentrates in a few task shapes | an even spread across workflow_type / arc / family |
| A4 | Age indicates neglect | the oldest criteria also being the lowest unblock score |

**A2 is load-bearing.** If false, the only honest recommendations concern the operator's capacity and the
framework's authoring standards — and this task must say so rather than manufacture an agent-side fix to
look useful.

## Exploration plan

1. **Rate** (30 min) — created vs ticked per week, 90 days, from git history of `.tasks/`. Answers IW-1,
   IW-4. Runs first; a negative result is a NO-GO for the whole task.
2. **Escalation reason** (60 min) — read a sample of the 51 against `decisions.yaml` and the learnings
   register. Answers IW-2. **Manual reading, not a regex.** Today's regex attempts produced 21 false
   positives by matching the Steps block instead of the verdict, and one would have offered 21 sovereign
   decisions to a reviewer. A classifier is the wrong instrument for "is this already ruled on".
3. **Shape** (30 min) — group by workflow_type, arc, originating family. Answers IW-3. Only if 1 and 2
   both come back positive.

## Technical constraints

- Git over `.tasks/` is the only history. "Created" = a `- [ ]` line appearing in a commit; "ticked" = it
  becoming `- [x]`. Neither is recorded as an event, so the rate is a **reconstruction** and its error
  bars get stated, not implied.
- Task files are renamed on completion, so per-file history needs `--follow` or the count breaks silently
  at the rename.
- `[REVIEW]` criteria can only be ticked by the operator, so a tick is a reliable signal of a human act.
  That is the cleanest measurement available and the rate spike should lean on it.
- **The corpus moves under the measurement.** Anything asserted is pinned to a commit range, never to
  "today" — the rot that took T-885's verification red for ten hours (T-3326).

## Scope fence

**IN:** why the rate is what it is; whether any share was avoidable; what the operator's real decision
load actually is.

**OUT:** answering any of the 51 (the operator's, a separate sitting) · reclassifying or delegating any
criterion (two attempts already established they are correct; a third is thrash) · proposing new
authority (a proposal to rule on, not a mechanism to build — PD-302) · building anything at all.

## Dialogue log

### 2026-09-29 — how this task came to exist

- **Operator asked** what to do about the 79-item docket. Four options offered: work through them
  together (A), pre-brief a batch of ten (B), attack the generator rather than the backlog (C), leave it
  gathered (D). B-then-A was recommended for immediate effect, with C named as the one actually worth
  doing and needing a go because it is an inception.
- **Operator chose** C.
- **Consequence:** this task explores the rate and the escalation reason. It answers none of the 51, and
  the docket remains available for a sitting whenever wanted.

## Findings

*(empty — exploration has not run)*
