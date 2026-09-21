# T-762 — Audit remediation, cycle 3

**Arc:** arc-003 · **Container:** T-762 · **Predecessors:** T-744 (cycle 1), T-761 (cycle 2)
**Date:** 2026-09-21

Cycle 3 is the mandate's verification step: *"Verification of a task is the re-run of
the audit in the next cycle, not your own assertion that it is fixed."*

The re-run confirmed cycle 2's diagnosis mechanically. It also showed that two of the
three questions cycle 2 asked have answers cycle 2 would not have predicted.

---

## 0. The baseline

```
.agentic-framework/bin/fw audit            # full scope, default 600s timeout
  Pass 176 / Warn 29 / Fail 1
  elapsed 121s        (start 09:28:37Z, record written 09:30:38Z)

.agentic-framework/bin/fw audit --section oe-daily
  exit 1, elapsed 18s
```

**Coverage is 19 of 19 sections.** Unlike cycle 2's, **this record is committed** —
`.context/audits/2026-09-21.yaml`, `sections: "all"` — so cycle 4 can diff against it.
That is the direct consequence of RA-052 below.

---

## 1. What the re-run verified

Cycle 2 asked three questions of cycle 3. All three have answers.

### Q1 — Does the full run now complete inside the 600s self-kill?

**Yes — 121s, against 687s in cycle 2.** No `FW_AUDIT_TIMEOUT` override was needed.

### Q2 — Does CTL-013 still report T-093?

**No. It does not mention T-093 at all.** Every CTL-013 line the run emitted:

```
[PASS] CTL-013: T-744 verification re-run: 6/6 pass
[PASS] CTL-013: T-755 verification re-run: 4/4 pass
[PASS] CTL-013: T-739 verification re-run: 10/10 pass
```

Occurrences of the string `T-093` anywhere in the cycle-3 audit output: **0**.

### Q3 — Is the gallery-mirror divergence unchanged?

**Yes, unchanged and still failing:**

```
$ diff -q src/aef-workflow-designer.html build/gallery/designer.html
STILL DIVERGED — condition unchanged
```

### What those three answers mean together

Nothing was fixed. No code changed between cycle 2 and cycle 3.

T-744 and T-755 completed, which pushed T-093 out of CTL-013's three-task recency
window (`audit.sh:3622` — `ls -t | head -3`). The four full test suites in T-093's
`## Verification` block simply stopped being run.

This is a **clean mechanical confirmation of T-755's causal chain**. The chain predicted
that the 687s runtime came from evaluating T-093's suites; remove T-093 from the window
and the runtime should collapse. It collapsed by a factor of 32 on the section
(578s → 18s) and 5.7× on the full run (687s → 121s). The diagnosis was right, and it
was verified by re-run rather than by assertion — which is what the mandate asks for.

It is also three new findings, because the same measurement says the audit's numbers
improved for reasons that have nothing to do with the project.

---

## 2. Findings

| ID | Sev | Check / mechanism | Observed vs expected | Task | BVP |
|---|---|---|---|---|---|
| RA-052 | — | audit record retention (T-677) | the only 19-of-19 baseline this project produced was overwritten by a same-scope run before it was ever committed; `git log` on the path is empty | **T-763** | 73 (lv) |
| RA-053 | — | CTL-013 recency window | RA-047's warning vanished while RA-047's condition is unchanged; disappearance is indistinguishable from repair | **T-764** | 61 (lv) |
| RA-054 | — | CTL-013 `eval` cost | 18s vs 578s, same section, same day, no code change — with a 600s silent self-kill downstream | **T-765** | **116 (hv-lc)** |

RA-053 and RA-054 share a root cause — CTL-013 evaluating completed tasks'
verification blocks over a three-item recency window. Per the one-finding-one-task
rule they are kept as separate records, linked in both bodies, not merged.

### RA-052 — the audit lost its own baseline

```
$ git log --oneline --all -- .context/audits/2026-09-21.yaml
(no output)
$ git ls-files --error-unmatch .context/audits/2026-09-21.yaml
UNTRACKED — never committed
```

T-677 says `.context/audits/` holds the last run of each date per scope, and that
earlier runs live in git history. The second half is a promise about a different
system: git holds only what was committed. Cycle 2's record was written, never
committed, and overwritten ~2 hours later.

The retention design has an **unstated precondition** — commit before the next
same-scope run on the same date — and nothing enforces it.

The cost was immediate. Cycle 3 cannot diff its finding set against cycle 2's. Warn
fell 31 → 29; one of the two is accounted for (RA-053) and **the second cannot be
attributed to anything**, because the record it would be attributed against is gone.
That unattributed delta is stated here as unattributed rather than guessed at.

### RA-053 — a spot-check that cannot distinguish repair from aging-out

CTL-013 checks the three most recently completed tasks. The trade is deliberate; its
own comment reads *"Full re-run of all verification is expensive; check latest 3"*.
The defect is not the window — it is that a finding's disappearance looks exactly like
its repair.

RA-047's condition cannot be cleared: doing so requires rebuilding `build/gallery/`,
which T-102 and T-105 are blocked on and which this project has ruled against. So the
warning did not go away because someone fixed it. It went away because two unrelated
tasks completed.

**RA-047/T-756 is therefore not closed.** Closing it on the strength of the warning
disappearing would be precisely the error this finding describes.

### RA-054 — the audit's runtime is not a property of the project

```
cycle 2:  fw audit --section oe-daily            578s
cycle 3:  fw audit --section oe-daily             18s

cycle 2:  FW_AUDIT_TIMEOUT=3000 fw audit         687s   Pass 175 / Warn 31 / Fail 1
cycle 3:  fw audit                               121s   Pass 176 / Warn 29 / Fail 1
```

CTL-013 `eval`s arbitrary shell drawn from whichever three tasks are most recent, so
the audit's cost is unbounded by anything the audit controls. Variance alone would be
a nuisance. What makes it a defect is the 600s watchdog downstream (RA-046/T-755),
which SIGTERMs the audit's own process group and emits no summary and no interpretable
exit code when it fires.

So completing one ordinary task whose verification block happens to run test suites can
push the whole audit past its own kill threshold, silently, with no relationship to the
change that did it. That failure mode is not hypothetical — it is OBS-358, which stood
unexplained from 2026-09-20 until cycle 2.

---

## 3. Correction to cycle 2's own record

Cycle 2 recorded that oe-daily *"clears the 600s self-kill by 22 seconds"*.

**That was wrong.** There is no stable margin to clear. The number moves by an order of
magnitude on task-completion order; the margin is not a property of the audit at all.
The claim is corrected here and in T-765's body rather than edited out of cycle 2's
document — a superseded record is evidence, an edited one is a lost trail.

---

## 4. Reconciliation — findings in = tasks out

The re-run reported 30 individual findings (29 WARN + 1 FAIL). Every one maps to a
task that already exists.

| Finding | Owner |
|---|---|
| Fabric 78/379 cards with no edges | T-745 (RA-036) |
| T-741 missing Updates section | T-746 (RA-037) |
| Uncommitted changes present | T-701 (RA-005) |
| 36 urgent observations pending | T-702 (RA-006) |
| 107 observations pending >7d | T-703 (RA-007) |
| T-250 no research artifact | T-759 (RA-050) |
| T-587 no research artifact | T-760 (RA-051) |
| CTL-029 ×14 (T-041…T-681) | T-709 … T-722 |
| CTL-029 ×4 (T-702, T-703, T-708, T-723) | T-747 … T-750 |
| D2 review queue, 10 tasks >30d | T-723 (RA-027) |
| D5 lifecycle, 12 anomalies | T-724 (RA-028) |
| D13 inception limbo, 3 tasks | T-725 (RA-029) |
| arc-001 past threshold (0.8125) | T-728 (RA-032) |
| arc-002 past threshold (0.9259) | T-757 (RA-048) |

```
Individual findings observed this cycle .................. 33
  reported by the audit run ............................... 30  (all reconciled to existing tasks)
  produced by cross-cycle comparison ...................... 3   (RA-052 … RA-054 → T-763 … T-765)
  unreconciled ............................................ 0
```

**Zero findings remain outside the arc.** All three new tasks carry `arc_id: arc-003`,
set through `fw arc tag`, never by hand.

Note the shape of this cycle's yield: **the audit run itself produced nothing new.**
Every genuinely new finding came from comparing one cycle's record against the next —
which is exactly the capability RA-052 says the project nearly lost.

---

## 5. Scores, quadrant, and what was worked

| Task | BVP | Cost | Quadrant | Disposition |
|---|---|---|---|---|
| **T-765** | **116** | **1.7** | **hv-lc (Q1)** | **worked and completed this cycle** |
| T-763 | 73 | — | — | parked (lv) |
| T-764 | 61 | — | — | parked (lv) |

T-765 is the first Q1 item this arc has produced that is **not blocked on an operator
decision**. The rest of the project's Q1 set is:

| Task | BVP | Why it cannot be picked up |
|---|---|---|
| T-700 | 125 | last AC deliberately reserved to the operator (G-007) |
| T-345 | 112 | `owner: human`, zero unticked Agent ACs |
| T-422 | 112 | resolution is "whichever remedy the operator picks"; AEF instructed the hooks not be hand-added |
| T-443 | 106 | `owner: human` |
| T-702 | 101 | `owner: human` — and is itself RA-006, one of this arc's findings |
| T-703 | 101 | `owner: human` — and is itself RA-007 |
| T-696 | 100 | blocked on a Human ruling |

T-765 was executable because its acceptance criteria are recording, quantification and
question-filing by construction, and it explicitly forbids the one action that would
constitute an architectural decision (changing `FW_AUDIT_TIMEOUT`, which would hide the
variance rather than measure it).

No score was adjusted upward by the producer and no BVP calibration parameter was
touched. Cost remains undefined for T-763 and T-764 — F8 needs a `blast_radius` a task
that has changed no file cannot have, already owned as **T-738**, itself parked by the
rule it breaks.

---

## 6. Sovereign questions — new this cycle

| ID | Question | Raised by |
|---|---|---|
| **SQ-5** | Should a dated audit record be protected from same-scope overwrite before it is committed — by a pre-run commit, write-if-absent, content-addressed naming — or is losing an uncommitted baseline an acceptable cost? This changes retention semantics, which the operator owns. | RA-052 / T-763 |
| **SQ-6** | Should a spot-check that covers only part of its population report its own coverage, so that a finding leaving the window is distinguishable from a finding repaired? E.g. *"checked 3 of N completed; T-093 last checked 2026-09-21, last verdict WARN."* | RA-053 / T-764 |
| **SQ-7** | Should CTL-013 time-box or sandbox the shell it `eval`s, and should the 600s watchdog report rather than kill silently? | RA-054 / T-765 |

Carried forward, still open: **SQ-1** (does this project deploy as a Ring20 swarm
service), **SQ-2** (should an agent-produced task be born `owner: human` with zero
Human ACs), **SQ-3** (the review queue is the binding constraint), **SQ-4** (can a
check carry a recorded exemption).

**Seven Sovereign questions are now open and none is decided.** Where a fix required an
architectural ruling, the task was parked and the question filed — per the mandate's
no-scope-drift constraint.

---

## 7. Delta across three cycles

| | Cycle 1 | Cycle 2 | Cycle 3 |
|---|---|---|---|
| Baseline coverage | section-scoped, unmeasured | 19 of 19 | 19 of 19 |
| Record committed | n/a | **no — lost** | **yes** |
| Full-run elapsed | — | 687s (killed at 600s until overridden) | 121s |
| Findings observed | 32 | 33 | 33 |
| New tasks | 13 | 3 | 3 |
| Unreconciled | 0 | 0 | 0 |
| Completed | 0 | 1 (T-755, BVP 101) | 1 (T-765, BVP 116) |
| Sovereign questions | SQ-1…SQ-3 | +SQ-4 | +SQ-5…SQ-7 |

**Three cycles are complete.** That is one of the mandate's stop conditions.

### What the three cycles actually established

Cycle 1 reconciled findings against a baseline of unknown coverage. Cycle 2 discovered
the baseline was 18 of 19 sections and that full runs had been dying against the
audit's own watchdog. Cycle 3 verified that diagnosis, and found that the audit's
improvement between cycles was largely an artifact of its own sampling window.

The through-line across all three: **nearly every finding this arc produced is a defect
of a check, not of the project.** Of 38 distinct findings across three cycles, the ones
that turned out to be real problems in the product are a small minority. The rest are
checks that look in the wrong directory, checks excluded from the runs that would
surface them, checks that warn about conditions the project has ruled against
clearing, and checks whose verdicts change when unrelated tasks complete.

That is a finding about the audit as an instrument, and it is the thing worth taking to
the operator ahead of any individual remediation task.

### What remains

15 remediation tasks from cycles 1–2 and 2 from cycle 3 stay parked, all scored below
the value boundary, none picked up — including the quick ones, per the mandate's
explicit prohibition on picking up a low-value task because it is cheap.

The binding constraint is unchanged and is **SQ-3**: the human review queue is 67 deep
with 10 inception decisions outstanding, oldest 72 days, and every remaining Q1 item in
the project sits behind it. The remediation arc cannot unblock itself.
