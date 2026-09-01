# T-664 — The approvals queue has an inflow the agent operates and an outflow only the operator can

**Date:** 2026-09-01
**Status:** finding; the remedy is a design change and is not taken here.

## The question that prompted this

> "Everything in an approval route is I don't defer, no go. So there can be nothing
> blocking right? Defer cannot be blocking, no go can be blocking. It's a blocker in
> itself that's not doing it."

Correct, and it exposes a category error I had been making in every status report.

A **no-go** blocks — something was decided, and dependent work is dead by that decision.
A **defer** parks, with a revisit date (`revisit_at:`, T-1451; G-053 scans them daily).
An **unticked checkbox** is neither. It is the absence of a decision. Reporting it as
"blocked on operator ruling" converts *nobody has ruled* into a status, and converts the
agent's own choice not to press into a property of the world.

## What is actually in the queue

Measured 2026-09-01 via `fw task verify`:

| | |
|---|---|
| unticked Human `[REVIEW]` ACs | **61** |
| distinct tasks carrying them | **53** |
| of those that are a recorded no-go | **0** |
| of those that are a recorded defer | **0** |

Every one of the 61 is in the fourth state: undecided. Not one is blocking in the sense
that a decision made it so.

## The structural cause: the queue has no agent-operable outflow

The queue renders exactly one bit per item — the checkbox — and only the operator may
flip it (CLAUDE.md: *NEVER check a `### Human` AC*). That rule is right and is not in
question here. The consequence is that **every mechanism that adds to the queue is
available to the agent, and the only mechanism that removes from it is not.**

### Inflow, agent-operated

Rulings routinely exist first as prose and are later *promoted* into ACs, which is a net
add. T-209's own Human AC records the pattern and counts it:

> This ruling has existed since the task was filed — as prose in `## Context`, not as an
> AC. So a task waiting on your decision has been reading as in-progress agent work,
> invisible to `fw task verify` and to the review queue. **That is the fourth instance of
> this mis-filing (T-340 AC1, T-341 AC1, T-358)**, and it is filed here rather than fixed
> silently.

Each promotion is individually correct — the ruling really was invisible. Collectively
they are an inflow with no matching outflow.

### Outflow, operator-only — including for decisions that no longer exist

A decision can stop existing. When it does, the checkbox still cannot be cleared by the
agent, so a dissolved decision renders identically to a live one.

**Confirmed instance: T-579.** Its own file says, in an Agent AC:

> **ANSWER: the pin was not moved. It was removed, so the decision this AC reserved for
> the operator no longer exists.** T-581 replaced `BASELINE_REF` with 11 recorded goldens
> under `tests/goldens/third-party/`. Ticked on dissolution, not on a ruling.

And it draws the general lesson:

> **The general form, because it cost several sessions:** routing to the operator is not
> automatically the conservative move. It converts a design question into a queued
> decision, and **a queued decision looks identical whether it is genuinely sovereign or
> merely unexamined.** The test that would have caught it here is cheap — *if I measure
> this, does the decision survive?* — and the answer was no.

Meanwhile the **Human** AC at line 150 of the same file still reads
`- [ ] [REVIEW] **Choose the new BASELINE_REF for the third-party byte-identity gate.**`
with no mention that the question was deleted. The answer is in the task; it is not in
the thing the queue renders. So T-579 has sat in the operator's queue as a live ruling
since the day it stopped being one.

**Scope of this claim:** one confirmed instance, not a population. Candidates were
screened by grepping the 53 queued tasks for dissolution language (18 hit); ten were
template boilerplate (`disposition: answered | deferred | dissolved`), and T-209, T-422
and T-432 were read and are **genuine live decisions** whose dissolution language refers
to other things. No population claim is made here.

## Negative result: prose ACs cannot be classified by keyword

A keyword classifier over the 61 AC bodies was written and **discarded rather than
shipped**. It placed T-341, T-358 and T-579 in a "taste" bucket because their bodies
contain the word "reads", and it missed T-579's dissolution entirely — the dissolution
text lives in an *Agent* AC while the Human AC restates the question cleanly. Recorded as
a negative result so the next attempt does not repeat it: the bucket a decision belongs
in is not recoverable from its prose.

## The missing representation (T-664's named finding)

Of the four states an item can be in — **never-presented**, **deferred**,
**waiting-on-an-external-fact**, **dissolved** — the queue can express **none** of them.
It has one bit, and that bit means "ticked". The state that is most expensive to omit is
**dissolved**, because it is the only one that will never resolve on its own: a
never-presented item can be presented, a deferred item has a revisit date, an external
wait ends when the fact arrives. A dissolved decision waits forever for a ruling that has
no subject.

**Not built here.** Giving the agent any way to clear a checkbox would breach the
sovereignty rule that makes the queue trustworthy. The remedy is a representation that
sits *beside* the checkbox — an agent-writable "the subject of this ruling no longer
exists, here is the evidence" that the operator confirms in a batch — and choosing it is
itself the operator's call. Filed, not taken.
