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

---

## Spike 1 — the rate. Answered IW-1 and IW-4, and refuted my own first measurement.

### The number that matters: the queue grows about +4 per week, net

Stock measurement — open `[REVIEW]`/`[REVIEWER]`/`[RUBBER-STAMP]` criteria in `.tasks/active/`, counted
at the first commit of each week, HTML comments stripped so template examples do not inflate it:

| date | open | Δ |
|---|---|---|
| 2026-07-06 | 34 | |
| 2026-07-27 | 67 | +33 over 3 weeks |
| **2026-08-03** | **21** | **−46 — a batch was cleared** |
| 2026-08-31 | 64 | +43 |
| 2026-09-21 | 79 | +15 |
| 2026-09-28 | 84 | +5 |

**IW-1 answered: it is a rate, not a one-off.** 34 → 84 over twelve weeks, roughly +4/week net. But it
is a *mild* rate, not a runaway, and one week in August went **−46** — so batch clearing demonstrably
works and has been done before. That single data point matters more than the trend: the backlog is not
structurally unclearable, it is unattended.

**IW-4 partially answered.** The −46 event shows the queue is cleared in bursts, not FIFO. So age is
evidence of *when someone last sat down with it*, not of per-item neglect. A 42-day median measured
during a quiet stretch says less than it appears to.

### My first measurement was unusable, and the reason is worth more than the number

I first measured *flow* — criteria added vs ticked in `git log -U0` over `.tasks/`:

    open criteria ADDED    1801
    ticked ADDED            104      => "answer rate 0.06"

**That 0.06 is wrong and I nearly reported it.** The arithmetic does not close: 1801 created minus 213
removed minus 104 ticked should leave ~1484 open, and only 79–84 are. The missing ~1400 left
`.tasks/active/` when their tasks completed — and a task completion is a `git mv`, which appears in the
diff as a **rename with no content lines**. So the flow method cannot see criteria leaving, and it
counts a re-worded criterion as a new one.

Two lessons, both already this corpus's recurring theme:

1. **A flow measurement over a corpus that MOVES its files needs to account for the moves.** Mine
   counted arrivals and was blind to departures, which makes every ratio it produces meaningless in
   one direction only — the alarming one.
2. **The stock measurement is immune to it.** Counting what exists at a point in time cannot be fooled
   by renames. When flow and stock disagree, stock wins unless the flow accounting is closed.

Recorded rather than deleted because "1801 vs 104" is exactly the kind of figure that would have been
quoted onward, and it is an artefact of my method rather than a fact about the corpus.

### Verdict on the spike-1 gate

The exploration plan said a negative here is a NO-GO for the whole task. It is **not** negative:
production does materially exceed answering (2.5× growth in twelve weeks). So spike 2 — the
load-bearing IW-2 read — is warranted, and proceeds.
