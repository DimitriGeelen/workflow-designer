# T-761 — Audit remediation, cycle 2

**Arc:** arc-003 · **Container:** T-761 · **Predecessor:** T-744 (cycle 1)
**Date:** 2026-09-21

Cycle 1 reconciled 32 findings into 32 task records. It did so against a baseline
that was section-scoped — a baseline nobody had ever measured the coverage of.

Cycle 2's result is that the baseline itself was wrong, and that the reason it was
wrong had been recorded as a mystery for months.

---

## 0. The baseline

```
FW_AUDIT_TIMEOUT=3000 .agentic-framework/bin/fw audit
  exit = 2
  elapsed = 687s
  Pass 175 / Warn 31 / Fail 1
```

**Coverage is 19 of 19 sections.** This is the first complete run in this project's
audit records. Every prior record in `.context/audits/` is section-scoped or a
truncated full run.

> **Record integrity note.** The counts above were read from the live run output.
> The saved record at `.context/audits/2026-09-21.yaml` **no longer holds them** — it
> was overwritten by cycle 3's run of the same scope on the same date (T-677's
> documented behaviour: "the last run of each date, per scope") **before it had ever
> been committed**. T-677 says earlier runs live in git history; this one does not,
> because nothing enforces commit-before-next-run. Filed as RA-052 in cycle 3. These
> counts are therefore reported honestly as observed-in-output and are **not**
> independently re-derivable from an artifact. That is a defect, and it is recorded
> rather than papered over.

### Why no full run had ever completed

`audit.sh` starts a watchdog that kills the audit's own process group:

```
AUDIT_TIMEOUT="${FW_AUDIT_TIMEOUT:-600}"          # audit.sh:306
( ... sleep "$AUDIT_TIMEOUT" && kill -TERM $ ... ) &   # audit.sh:346
```

The complete run needs 687s against a 600s self-kill. It was failing by **87
seconds** against a limit it imposes on itself, emitting no summary and no
interpretable exit code. Because the killer is inside the audit, nothing outside it
reports a kill — which is why OBS-358 recorded the symptom as "the full audit hangs".

Causal chain, established and then confirmed mechanically in cycle 3:

```
T-723's sweep moved T-093 into completed/
  → T-093's ## Verification block carries four full test suites
  → CTL-013 (audit.sh:3618) evals that block on every oe-daily run
  → oe-daily grows to 578s
  → full run ~687s
  → self-kill at 600s
```

Owned by **T-755 (RA-046)**, work-completed this cycle. It is the only task of the
cycle that scored above the value boundary (BVP 101, hv) and therefore the only one
worked.

---

## 1. Findings the complete baseline surfaced

Three findings that no section-scoped run, no cron run and no pre-push check had
ever produced. All three are defects **of the checks**, not of the project.

| ID | Sev | Check that fired | Observed vs expected | Task |
|---|---|---|---|---|
| RA-049 | — | section dispatch | `audit.sh:5228` guards the deployment section with `[ -n "$SECTIONS" ] &&`; the other 18 sections do not. A bare `fw audit` runs 18 of the 19 it advertises. | **T-758** |
| RA-050 | WARN | inception research artifact | warns on T-250; T-706 **ruled** the document must not be written and wrote a red leg to prevent it | **T-759** |
| RA-051 | WARN | inception research artifact | warns on T-587, whose artifact exists at `docs/research/executable-workflow/reflection-designer.md` (19,876 bytes); the check searches only `docs/reports/` | **T-760** |

### RA-049 in detail

```
# audit.sh:5228 — the deployment section
if [ -n "$SECTIONS" ] && should_run_section "deployment"; then

# every other section, e.g. audit.sh:489
if should_run_section "structure"; then

# audit.sh:363
should_run_section() {
    [ -z "$SECTIONS" ] && return 0
    echo ",$SECTIONS," | grep -q ",$1,"
}
```

`should_run_section` returns true on an empty `$SECTIONS` — that is how a bare
`fw audit` runs everything. The extra `[ -n "$SECTIONS" ] &&` inverts the default for
exactly one section: it runs *only* when named explicitly.

Measured: the complete 687s run contains **zero** occurrences of the string `deploy`.
A run scoped `--section deployment` reports **four FAILs**. So RA-042, RA-043, RA-044
and RA-045 — cycle 1's four deployment findings — have never appeared in any audit
record and never will under an unqualified run. They were found only because cycle 1
enumerated the section list by hand.

The guard is explicit, so someone wrote it deliberately. The most plausible reason is
that deployment checks are meaningless for a project that does not deploy and would
FAIL noisily forever. If so, the mechanism is still wrong: it makes the check
*invisible* rather than *not-applicable*, and an invisible check cannot tell you it
stopped being relevant. That distinction is **SQ-1**.

---

## 2. Reconciliation — findings in = tasks out

```
Individual findings observed this cycle .................. 33
  reconciled to a task created THIS cycle ................  3   (RA-049 … RA-051 → T-758 … T-760)
  reconciled to a task created in cycle 1 ................ 13   (RA-036 … RA-048 → T-745 … T-757)
  reconciled to an existing arc-003 task ................. 17
  unreconciled ........................................... 0
```

**Zero findings remain outside the arc.** All three new tasks carry
`arc_id: arc-003`, set through `fw arc tag`, never by hand.

---

## 3. Scores and quadrant placement

Scored by `fw bvp estimate` (heuristic v1, `bvp-estimator-v1-heuristic`,
`rubric_sha: e4a00f38e801`). Value boundary: **hv ≥ 100**, **lv ≤ 94**.

| Task | BVP | Cost | Quadrant | Disposition |
|---|---|---|---|---|
| T-745 | 94 | — | — | parked (lv) |
| T-747 | 91 | — | — | parked (lv) |
| T-748 | 91 | — | — | parked (lv) |
| T-746 | 79 | — | — | parked (lv) |
| T-749 | 79 | — | — | parked (lv) |
| T-750 | 79 | — | — | parked (lv) |
| T-758 | 79 | 2.2 | lv-lc | parked (lv) |
| T-757 | 74 | 1.6 | lv-lc | parked (lv) |
| T-760 | 72 | 1.9 | lv-lc | parked (lv) |
| T-752 | 69 | — | — | parked (lv) |
| T-753 | 69 | — | — | parked (lv) |
| T-754 | 69 | — | — | parked (lv) |
| T-759 | 63 | 1.9 | lv-lc | parked (lv) |
| T-756 | 54 | 2.8 | lv-lc | parked (lv) |
| T-751 | 51 | 2.9 | lv-lc | parked (lv) |

**Every open remediation task scores below the value boundary.** The highest, T-745
at 94, misses hv by six points. Under the mandate's prioritisation rule — *"Low-value
tasks stay in the arc, scored and parked. Do not pick up a low-value task because it
is quick"* — none was picked up. No score was adjusted upward by the producer and no
BVP calibration parameter was touched.

**Cost is undefined (`—`) for nine of fifteen.** F8 needs `blast_radius`, which is not
computable for a task that has not yet changed a file. That gap is already owned as
**T-738** — which is itself parked by the rule it breaks.

---

## 4. The class this cycle identified

RA-047, RA-050 and RA-051 are three instances of one shape:

> **A warning that a recorded decision has made permanently unclearable.**

- **RA-047 (T-756)** — CTL-013 reports T-093's gallery-mirror leg red. It *is* red, by
  decision: T-102 and T-105 are blocked on that drift and must not be unblocked by
  rebuilding `build/gallery/`. The only two ways to silence it are forbidden
  (rebuild) or dishonest (edit a completed task's verification block).
- **RA-050 (T-759)** — T-706 ruled the document must not be created, and wrote a red
  leg to enforce the ruling.
- **RA-051 (T-760)** — the artifact exists; the check has a hardcoded path.

Three instances is a class, not a coincidence. It is filed as **SQ-4** and is not
decided here.

---

## 5. Sovereign questions — open, in priority order

| ID | Question | Blocks |
|---|---|---|
| **SQ-1** | Does 832-Workflow-designer deploy as a Ring20 swarm service? If not, the deployment section is out of scope and the fix is to scope the check — not to scaffold files to silence four FAILs. | T-752, T-753, T-754, T-758 |
| **SQ-2** | Should an agent-produced task ever be born `owner: human` with zero Human ACs? That condition produced all four of cycle 1's CTL-029 findings, and the agent cannot clear them. | T-747–T-750 |
| **SQ-3** | The human review queue is the binding constraint: 67 Human-AC tasks, 10 inception decisions, oldest 72 days. Every Q1 item in the project is blocked behind it. | the whole Q1 set |
| **SQ-4** | Can a check carry a recorded exemption, or must the project accept permanent warnings it has ruled against clearing? | T-756, T-759, T-760 |

None is decided here. Where a fix required an architectural ruling, the task was
parked and the question filed — per the mandate's no-scope-drift constraint.

---

## 6. Q1 / Q2 state

**Q1 (hv-lc): empty.** **Q2 (hv-hc): not reachable by this arc.**

No remediation task in this cycle reached the hv boundary. The project's actual
high-value items (T-344 at BVP 167, T-358 at 157, both hv-hc) are outside arc-003 and
outside this mandate's remediation scope.

The structural finding, unchanged from cycle 1 and worth restating because it is the
binding one: **every Q1 item in the project is blocked on an operator decision** —
inception decisions the agent must never make, `owner: human` tasks with zero
unticked Agent ACs, and ACs explicitly reserved to the operator under G-007. The
remediation arc cannot unblock itself.

---

## 7. Delta versus cycle 1

| | Cycle 1 | Cycle 2 |
|---|---|---|
| Baseline coverage | section-scoped, unmeasured | **19 of 19 sections** |
| Findings observed | 32 | 33 |
| New tasks created | 13 (T-745…T-757) | 3 (T-758…T-760) |
| Unreconciled | 0 | 0 |
| Tasks completed | 0 | 1 (T-755, BVP 101) |
| Sovereign questions | SQ-1…SQ-3 | +SQ-4 |

**Closed this cycle:** T-755 (RA-046), which localised OBS-358 — open since
2026-09-20 — to a specific line of a specific file.

**Corrections made to this cycle's own record**, kept rather than quietly rewritten:

1. I attributed the 600s kill to an external shell ceiling and filed an observation
   saying so. It is the audit's own watchdog. Corrected by a follow-up observation
   rather than by editing the first — a wrong record that is superseded is evidence;
   a wrong record that is edited is a lost trail.
2. I claimed to have localised CTL-013. OBS-358 had already named CTL-013 *and*
   T-093's four suites when it was filed. Corrected on the task and in its own commit.
3. T-759 and T-760 were created with "REGRESSION" in their names. Neither is one —
   T-250's artifact was *ruled against*, T-587's *exists*. The names were left as
   created and a correction block written into each body: a task id that changes
   meaning silently is worse than one that carries its own correction.

---

## 8. TermLink assessment

Not used for this cycle's work, and the reason is recorded rather than left implicit.

- The mandate suggests dispatching BVP estimation to a `bvp-estimator` worker.
  **No such worker exists** (VS-2, cycle 1). `fw bvp estimate` is a local verb.
- Concurrency across "independent Q1 tasks on disjoint paths" has **degree one** —
  Q1 is empty. Fan-out over a single task is decoration, not parallelism.
- There is no project-internal topic. The only live rail is the AEF↔832 contract
  seam, where internal audit churn would be noise against a seam that carries
  ratification traffic.

Git carries this cycle's record and is auditable in a way a rail post is not. The
mandate's own escape clause applies: *"If TermLink is unavailable or its use would
obscure the audit trail, do the work directly and note why."*

---

## 9. What cycle 3 must check

Cycle 3 verifies this cycle by re-running the audit, not by my assertion that
anything is fixed. Specifically:

1. Does the full run now complete inside the 600s self-kill?
2. Does CTL-013 still report T-093?
3. Is the gallery-mirror divergence — RA-047's actual condition — unchanged?

Those three questions have answers, and they are not the ones this cycle expected.
They are recorded in `docs/reports/T-762-cycle3-findings.md`.
