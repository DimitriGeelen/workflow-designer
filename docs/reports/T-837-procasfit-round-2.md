# T-837 procAsFit round 2 — handback

**Worker:** TermLink `pa0924r2` (per the dispatch header; I cannot independently confirm the
dispatch mechanism from inside the session — round 1 asserted a mechanism claim it could not
back up either way, and that was flagged as false. I make no claim about my own dispatch
mechanism beyond what the orchestrator's header states.)

**Chain input:** round 1's result (`docs/reports/T-837-procasfit-round-1.md`, commits
`d53b3689`..`4e373663`). Round 0's result (2026-09-23, commits `d91e4ebf`/`e68a057d`/`29ef957c`)
was round 1's input. This report is the final link — T-837's own ACs describe exactly two
chained rounds.

**Round 2 commits:** `41f6d59d` (T-746), `5524f5b1` (T-749/T-750), `b1c9f7e5` (17-task scoring
batch).

---

## Selection — stated before execution, per unit of work

**Objective → arc → task → quadrant, each time:**

1. **T-746** (RA-037, arc-003, agent, Q-unscored at pickup). Chosen because round 1's handback
   named the 18-task unscored pool as "the remaining candidate pool" and flagged RA-series
   siblings as suspected low-value — but round 1 explicitly left them uninvestigated. Verifying
   and, where legitimate, closing the cheapest of these was the obvious first move: real defect
   (audit `[WARN]` still firing), single-file fix, no design ambiguity. Selected over the other
   16 non-RA candidates specifically because it required no Sovereign judgment call.
2. **T-749/T-750** (RA-040/041, arc-003, agent, Q1 hv-lc once scored). Same reasoning, next
   cheapest. Turned out NOT closeable — see below — but the investigation itself surfaced a
   structural finding (four owner:human tasks with zero Human ACs) worth more than the task's
   own completion would have been.
3. **The 17-task scoring batch** (T-241/246/294/553/554/555/564/573/577/582/583/584/622/784/
   822/832/834). Chosen because round 1's central finding was that these 18 (now 20, see below)
   tasks were *unscored*, not *low-value* — "scored before started" meant investigating them was
   itself the next legitimate unit of work, not a shortcut around the ladder.

No task was executed before being scored through the estimator, per the mandate's "scored
before started" binding. The two exceptions (T-746, and the T-749/T-750 investigation) were
scored via `fw bvp estimate-cost` with grounded `components:` before any file outside the task's
own YAML was touched.

---

## Verify-before-trust: the enumeration was wrong again

Round 1's list of 18 unscored agent-owned tasks was **incomplete**, exactly as round 1 itself
warned it might be (it had already corrected round 0's undercount of 5). Direct measurement —
`owner:` and `cost_estimate_proposed.blast_radius` state read from every active task file, not
from `fw bvp --quadrant` — found **20**, not 18:

```
T-241 T-246 T-294 T-553 T-554 T-555 T-564 T-573 T-577 T-582 T-583 T-584
T-622 T-746 T-749 T-750 T-784 T-822 T-832 T-834
```

Round 1's list was missing **T-555** and **T-822**, both genuinely agent-owned, `captured`,
`cost_estimate_proposed.blast_radius` absent. No enumeration method used across three rounds
now (round 0's, round 1's `fw bvp --quadrant`, round 1's own corrected list) has been complete
on the first pass. Recording this as the pattern itself, not just this instance: **any future
round should re-derive this count from source rather than inherit it.**

---

## What got done

### T-746 — closed (work-completed, 3/3 ACs, 2/2 verification legs)

T-741 was the only task file (0 of 681 completed, 0 of the other 154 active) missing the `##
Updates` heading — confirmed by direct population scan, not assumed. Fixed by adding the
heading in place (T-741's substantive content, including its own Decisions, was untouched).
`fw audit --section compliance` no longer reports T-741. The task's own AC3 asked whether this
was a one-off or a class; the population scan answered definitively: one-off. Completion was
refused once by the Evolution-log gate (T-1718, arc-tagged build task) — I filled a real entry
rather than using `--skip-evolution`.

### T-749 / T-750 — investigated, scored, left parked (not closed)

Both ask whether T-708 / T-723 (arc-003's own remediation tasks RA-012/RA-027) can reach a
terminal state. Both have **all three Agent ACs ticked** but sit at `status: started-work` and
`owner: human` with **zero `### Human` AC bullets** — confirmed directly, not estimated. Their
own AC text bars the agent from closing them or reassigning ownership, so **this is a structural
block, not a gate I failed to clear**: no verb available to me reaches "closed." I recorded the
evidence (all ACs ticked, nothing outstanding) so the operator can close both with one command
each: `fw task update T-708 --status work-completed` and the same for T-723.

**The structural finding, checked directly across all 16 tasks CTL-029 named this cycle**
(T-041, T-101, T-102, T-105, T-189, T-209, T-286, T-293, T-309, T-344, T-345, T-357, T-402,
T-681, T-708, T-723): exactly **four** are `owner: human` with **zero** Human AC bullets —
T-189 (tracked by T-713/RA-017), T-286 (T-715/RA-019), T-708 (T-749/RA-040), T-723
(T-750/RA-041). The other twelve each carry a genuine Human AC, so `owner: human` is doing real
work on those. This is a Sovereign question (**SQ-5**, below), not something I ruled on.

### 17-task scoring batch — grounded `components:`, re-scored, all resolve `lv-lc`

For each of the remaining 17 previously-unscored tasks, I read the actual referenced code (not
the task's own prose) before writing `components:` — e.g. read `src/aef-workflow-designer.html`
lines 10030–10096 to confirm T-573's premise (the panel's Emits field is a scalar-only textarea;
the structured exporter only fires on `Array.isArray`; T-570 already fixed the *preservation*
half, leaving only the *shape* half, which is what T-573 is actually about); read the port-dot
render/click code at line 4192–4237 for T-294; confirmed `tools/_t364-byteid-precondition-teeth.py`
and `tools/_t361-export-trailer-cdp.mjs` (T-583's two examples) are both genuinely deleted, so
no single existing file grounds that task — it needs a new instrument, correctly reflected by
citing the sweep runner it would plug into rather than inventing a false precision.

**Every one of the 17 — plus T-749 and T-750 — resolved to `lv-lc`** once scored with grounded
evidence. None reached `hv-lc` or `hv-hc`. This extends round 1's own suspicion (the RA-series
siblings T-751–764 all sit `lv-lc`) from three tasks to the **entire 20-task unscored pool**.
Per the mandate ("Low-value tasks are out of scope for this run regardless of how cheap they
are"), none of these 20 is eligible for execution this run. They are no longer sitting in
unscored limbo, which is itself the point: a low-value-but-scored task can be found and skipped
by every future selection pass; an unscored one is invisible to all of them, which is exactly
the defect round 0 discovered and rounds 1–2 have now closed out for the full backlog.

I did not force any of the three genuinely tool-building tasks (T-555, T-577, T-583) toward a
higher score by listing multiple speculative components — the estimator's `blast_radius` ladder
reads `len(components)`, and inflating that list with files I had not verified would be exactly
the "scoring by estimate wearing the scorer's clothes" defect the dispatch brief named as the
one thing not to do. Each got the single file I actually read and could defend.

### Two tasks flagged their own Sovereign questions during scoring, not built

- **T-822** (usage histogram) states its own privacy question in its body: recording what a
  human does with the editor, in their own localStorage, is a different kind of fact than
  T-821's fault ring (conditions the software hit). I did not treat "low-value, so skip" as the
  reason to not build it — the deeper reason is that it needs an operator ruling before an agent
  should record human behaviour at all, low-value or not.
- **T-784** (value-review round 1, GATHERER role) is `started-work` from a prior session and
  carries **mandatory `[ASK]` gates explicitly marked "not to be answered by the agent."** I did
  not advance its phases — doing so without knowing whether the Phase 1 `[ASK]` was already
  answered by the operator would risk exactly the producer-not-judge violation the task's own
  description warns against. Left untouched; its state is for the operator or a session with
  visibility into whether Phase 1 was actioned.

---

## Full Q1/Q2 audit — every agent-eligible slot, checked directly

Round 1 said "all other Q1/Q2 tasks are owner: human except three already-exhausted plus the
two we closed" — true in conclusion but **incomplete in its own accounting**: it never
enumerated four other owner:agent Q1/Q2 tasks that were also blocked. I checked all of them
directly rather than re-stating round 1's list:

| Task | Quadrant | State | Why it's not eligible this round |
|---|---|---|---|
| T-696 | hv-lc (Q1) | started-work | Blocked on a Human AC (round 0 finding, unchanged) |
| T-745 | hv-hc (Q2) | issues | Failed twice, G-074 (round 0 finding, unchanged) |
| T-785 | hv-hc (Q2) | issues | Blocked on T-353's open operator ruling (whether an agent may edit a `.tasks/completed/` Verification block) — 4/5 ACs met, 5th correctly left BLOCKED not failed |
| T-811 | hv-hc (Q2) | started-work | Blocked on SQ-1 (endpoint semantics, frozen standard) |
| T-155 | hv-hc (Q2) | captured, horizon:later | DEFERRED via a recorded inception decision (2026-09-23) — properly parked, not stuck |
| T-358 | hv-hc (Q2) | started-work | Blocked on T-835's unresolved design question (authority-on-element vs authority-on-lane) |
| T-341 | hv-hc (Q2) | started-work | Same block as T-358 — both named explicitly in T-835's own ACs as the downstream unblocks |

All seven are genuinely blocked, each for a stated, checkable reason — not silently stuck. **No
agent-eligible Q1 or Q2 task in any of the three arcs (arc-001, arc-002, arc-003) is currently
workable.** T-835 itself (the task that would unblock T-358/T-341) scores `lv-lc` once measured
with `--include-proposed`, so working it further this round would be exactly the "low-value work
to stay busy" the mandate rules out — I left it as I found it (already `started-work` from a
prior session; I did not touch its content).

This satisfies the mandate's first stop condition: **all Q1/Q2 work in every active arc is
either complete or blocked, and the unscored pool that could have hidden more of it has now
been fully measured and resolves to low-value.**

---

## Sovereign questions

**SQ-5 (new, raised this round):** should `owner: human` ever be assignable to an agent-created
task with an empty `### Human` AC section? Four current tasks (T-189, T-286, T-708, T-723) hit
exactly this: all Agent ACs ticked, nothing for a human to judge, yet stuck because closing an
`owner: human` task is not delegated to the agent under any circumstance (correctly — this is
not a request to change that). Two shapes of remedy exist and I am not choosing between them:
(a) task-creation tooling refuses `owner: human` when the Human AC section is empty at creation
time, or (b) these four (and any future instance) get reassigned to `owner: agent` by the
operator once confirmed to carry no genuine human-judgment criterion. Evidence for either
decision is in T-749/T-750's Updates sections.

**Unchanged from rounds 0/1** (not re-litigated): SQ-0 (inception scoring agent-unsatisfiable),
SQ-1 (endpoint's three semantics, blocks T-811), SQ-2 (read-only sufficiency, 18 text carriers),
SQ-3 (timer/timerSpec naming drift), SQ-4 (12 structured carriers' panel shape). Also unchanged:
T-835's own open design question (authority-on-element vs authority-on-lane), which is a
Sovereign question in substance even though it is tracked as a task rather than an SQ number.

**Surfaced but not filed as new SQs, because the task itself already states them as open and
agent-unanswerable:** T-822's privacy/telemetry question (recording human behaviour), and
T-784's Phase 1/Phase 5 `[ASK]` gates.

---

## Gates that refused me, and what I did instead

1. **T-1718 Evolution-log gate**, on `fw task update T-746 --status work-completed`. T-746 is
   arc-tagged (`arc_id: arc-003`) and its `## Evolution` section was template-only. I did not use
   `--skip-evolution`; I wrote a real entry (population-check result: one-off, not a class) and
   retried. Passed clean the second time.
2. **check-active-task PreToolUse hook**, repeatedly, on plain read-only `Bash` calls (`fw bvp
   --quadrant`, `fw audit`) made before focus was set, and again on tasks whose status was
   `captured` rather than `started-work`. Not a gate I disagreed with — I set focus (`fw context
   focus T-837`) and ran `fw work-on T-XXX` each time before proceeding, which is the documented
   unblock path, not a bypass.
3. **No Tier 0/2 boundary was approached.** No `--force`, `--skip-*` beyond the one documented
   retry above, `--i-am-human`, or `FW_*` override was used anywhere this round.
4. **Human-ownership completion**, structurally, on T-708/T-723 (via T-749/T-750). Not a gate I
   hit and routed around — there is no verb that lets the agent close an `owner: human` task, by
   design, and I did not look for one. Recorded as evidence for the operator instead.

---

## Cost-vs-estimate

T-746 had no meaningful prior estimate (blast_radius was `absent` until scored this round). Once
scored (`components: [1 file]` → blast_radius=1, tier=2, effort=5), actual effort matched: one
`Edit` to add a heading, one audit re-run, one Evolution entry. No surprises.

**Calibration note worth feeding back:** the cost estimator's `score_blast_radius` (T-542,
`estimator.py:2744`) computes blast_radius from **`len(components:)`** on a fixed 0/1/3/5/7/9
ladder — it does *not* query `fw fabric impact` for the listed file's actual dependent count.
A task whose single cited file has 14 registered dependents (as `src/aef-workflow-designer.html`
does — verified via `fw fabric deps`) scores identically to a task whose single cited file has
zero. This is a known, documented tradeoff in the estimator's own docstring (count, not fabric
weight, by design — T-542), not a bug I'm reporting blind. But it means **every one of this
round's 19 single-component scores landing at blast_radius=1 is an artifact of "I could ground
exactly one file," not evidence that the underlying defects are all equally small** — T-573 and
T-294 in particular touch a file with the largest fan-out in the repo. Future scoring rounds
should read this ladder's docstring before treating a `lv-lc` verdict on a single-file task as
low actual impact; it is a low *evidence-count* verdict, and the two can diverge.

---

## What remains, and what the next session should pick up

**Immediately actionable by the operator, zero investigation required:**
- `fw task update T-708 --status work-completed` and `fw task update T-723 --status
  work-completed` — both have all Agent ACs ticked, evidence recorded in T-749/T-750.
- SQ-5 above needs a ruling (tooling fix vs. case-by-case reassignment) before the next round of
  CTL-029 findings repeats this shape a fifth and sixth time.

**Not started, and correctly not started:**
- All 20 newly-scored tasks are `lv-lc` and out of scope per the mandate's value gate. They are
  no longer unscored, which was this round's actual job.
- T-835 (unblocks T-358/T-341) is `lv-lc` itself; continuing it this round would have been
  low-value work chosen to stay busy, which the mandate rules out. It remains `started-work`
  from a prior session, untouched by me.
- T-784's Phase 2+ (GATHERER role) was not advanced — its `[ASK]` gates are explicitly
  not-agent-answerable and I could not confirm Phase 1 had already been cleared by the operator.

**This is the last of the two chained rounds T-837 specifies.** No further TermLink dispatch is
implied by this report. If work continues, it re-enters at Level 2 (arc selection) with a fresh
`fw bvp --include-proposed` re-measurement — per this round's own finding, do not inherit either
round's task list without re-deriving the count.

---

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
