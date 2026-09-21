# T-783 — Operator review queue, triaged

**Date:** 2026-09-21 · **Source:** enumerated from `.tasks/active/*.md`, not from the
handover's rendering (PL-260) · **Re-run:** `python3 tools/_t783-human-ac-queue-extract.py`

**No Human AC was ticked and no ownership was changed.** This report is evidence, not action.

---

## Start here — the two you can close in about a minute

### 1. T-586 — the work is already done, only the tick is missing

The AC asks you to apply the worktree deny rules to `.claude/settings.json`. **They are
already applied.** Two independent instruments agree:

```
$ python3 tools/_t586-worktree-denial-guard.py
LIVE: .claude/settings.json
  [denied] EnterWorktree            the EnterWorktree tool (harness-native worktree entry)
  [denied] ExitWorktree             the ExitWorktree tool
  [denied] Bash(git worktree:*)     `git worktree add` and friends via the shell
All worktree routes are denied.
exit=0

$ python3 -c "import json; print(json.load(open('.claude/settings.json'))['permissions']['deny'])"
['EnterWorktree', 'ExitWorktree', 'Bash(git worktree:*)']
```

That is exactly the AC's `**Expected:**`. **You do not need to run step 1.** Tick and close.

### 2. T-580 — the check passes

The AC's `**Expected:**` is *"step 1 prints `0`"*:

```
$ git ls-files '*.sh' | grep -v '^.agentic-framework/' \
    | xargs grep -lE '^[[:space:]]*(source|\.)[[:space:]]+[^[:space:]]+\.sh' | wc -l
0
```

Prints `0`. The AC's own **If not** clause says a non-zero result would mean the measurement
was wrong; it is zero, so the conclusion holds. Its own text notes nothing is pending on you
unless you disagree with the numbers.

> Its **If not** also carries a caveat worth keeping: *"Do not take the bump on the strength of
> this task either way."* Closing T-580 is not an argument about the vendor bump.

---

## Needs correcting before you act on it

### 3. T-596 — STALE, its premise was overtaken

The AC asks you to *"Confirm the register reads H1 and H3 correctly as **open**, not as already
answered."* **H1 is no longer open.** Measured now:

| H1 | H2 | H3 | H4 | H5 | H6 |
|---|---|---|---|---|---|
| **resolved** | resolved | **open** | resolved | **open** | **open** |

H1 was ruled resolved on 2026-09-21 (DEFERs and the NO-GO stand). Read literally, this AC asks
you to confirm a state that no longer exists. The H3 half is still valid and still open.

**Recommendation: do not tick as written.** Either the criterion is rewritten to cover H3 alone,
or it is closed as overtaken. That is a scope call, so it is left to you — but ticking it as
written would record a confirmation of something false.

### 4. T-593 — a pointer, not an independent criterion

Its whole AC is *"H2 itself remains yours to answer — it is unchanged by this task"*, and its
Steps send you to T-590. H2 is **already `resolved`** in the register. So this criterion is a
cross-reference to a question that has since been answered.

---

## The structural finding: four blocked tasks are invisible to you

The handover reports **41** tasks awaiting you. The source holds **62 tasks / 77 criteria**.
The gap reconciles exactly:

```
62 tasks with >=1 unchecked Human AC
 -  4 owner: agent        (excluded: the queue filters on owner == human)
 - 17 horizon: later      (excluded by design, CLAUDE.md)
 = 41                     <- what the handover renders
```

The `later` exclusion is deliberate. **The `owner: agent` exclusion is not, and it deadlocks
four tasks:**

| task | horizon | what it is |
|---|---|---|
| **T-341** | now | An unresolvable flowNodeRef silently reassigns the orphaned node |
| **T-358** | now | Importer FABRICATES lane and pool structure the input never had |
| T-695 | now | Task-template boilerplate is scored as if it were the task |
| T-696 | now | T-624 chose a template warning as its prevention, and twelve days later… |

Each is `owner: agent`, each is blocked on a `[REVIEW]` criterion only you can answer, and
**none appears in your queue.** T-341 and T-358 both sit in the high-value quadrant and were
classified `ac-blocked` by the selection census. The agent waits on a ruling; the ruling is not
in the operator's queue; nobody is waiting on anything they can see.

This is not a task-level defect — it is the queue's filter. Registering it as a gap is
recommended, but that is a call for you.

---

## Everything else: genuine judgement, reported and not evidenced away

**71 of 77 criteria are `[REVIEW]`.** I could not evidence them and did not try to. Reading
their Expected clauses: *"reads as a repair, not as the editor moving your work around"*,
*"is the right field name"*, *"rule which definition this table ratifies"*, *"approve go/no-go"*.
Evidence cannot substitute for any of those.

**That the TASTE set is large is the negative control.** A triage that returned EVIDENCED for
everything would be indistinguishable from one that had not done the work. Two of 77 came back
cleanly evidenced; that ratio is the honest shape of this queue.

Composition, for sizing:

| class | n | meaning |
|---|---|---|
| TASTE | ~71 | genuine judgement — your call, no shortcut exists |
| **EVIDENCED** | **2** | T-580, T-586 — check run, output above |
| STALE | 1 | T-596 — premise overtaken |
| POINTER | 1 | T-593 — resolves to an already-answered question |
| RUBBER-STAMP total | 6 | of which 2 evidenced, 2 are H3/H5 rulings, 2 above |

**Nine of the TASTE items are one repeated template criterion** — *"[REVIEW] Review exploration
findings and approve go/no-go decision"* on T-184, T-185, T-186, T-277, T-279, T-280, T-281,
T-282, T-498. All nine are `horizon: later` inceptions. They are identical boilerplate, they
each require `fw inception decide` (operator-only), and they can be handled as one batch of
decisions rather than nine separate reviews — though each decision remains distinct.

---

## The three that gate Arc-0

**T-732 carries H3, H5 and H6** — the only three open blocking rulings on our side of the
Arc-0 fence.

- **H3** — ratify the correlation identifiers. The filed recommendation is **superseded**: it
  says "the two values already in use"; there are now **three**, the third
  (`EWCR-ARC0-ATTEST-832`) minted by an agent on the rail and adopted by repetition. Worth
  knowing before you rule — an unratified value is accruing the appearance of a decision.
- **H5** — reconcile the four disclosed governance deviations. Agent evidence already measured
  2026-08-27: T-587's hand-written file is conforming against the inception template.
- **H6** — was the R6/R7 routing correct.

If the object is to move Arc-0, these three are the queue — not the other 74.
