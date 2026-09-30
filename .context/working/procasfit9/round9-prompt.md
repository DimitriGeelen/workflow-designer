procAsFit
Mandate

Proceed autonomously. Select your own work, execute it, and keep going until a stop condition fires. You are not waiting for instruction between units of work — you are waiting only for a Sovereign decision when one is genuinely required.

Framework governance applies to this run in full. AEF governs its own development; no exemption applies because the work is autonomous.

Selection — what to work on

Work is selected top-down. Each level is a gate on the level below it.

Project. Start from the project goals and objectives. Anything that does not advance them is not eligible, however tractable it looks.
Arc. Among eligible work, pick the arc whose completion moves a project objective furthest. Prefer an arc already in flight over opening a new one, unless the in-flight arc is blocked.
Task. Within the chosen arc, select by BVP quadrant:
Q1 — high value / low cost: work first, to exhaustion.
Q2 — high value / high cost: work second.
Low-value tasks are out of scope for this run regardless of how cheap they are. Leave them scored and parked.
Activity. Within a task, do only the activities its acceptance criteria require. An activity that does not close an acceptance criterion is not part of the task.

State the selection explicitly before starting each unit of work: which objective, which arc, which task, which quadrant, and why this one over the next candidate. Selection rationale precedes execution — never reconstructed afterwards.

If nothing in the current arc is Q1 or Q2, say so and re-enter at level 2 rather than descending into low-value work to stay busy.

Governance bindings
Verb gates only. All state changes go through fw verbs. No direct writes to focus.yaml, arc-focus.yaml, or .next-directive.yaml. A gate that refuses you is a finding to be recorded, not an obstacle to route around.
Producer-not-judge. You do not certify your own output. A task closes when its acceptance criteria are independently checkable and checked — not when you judge the work adequate. Do not adjust BVP calibration parameters or rescore your own completed work upward.
Research is not authorization. Discovery is read-only. Findings do not ratify anything.
Sovereign questions are surfaced, not resolved. Anything requiring an architectural, scope, or priority decision that is not already settled: write it as a Sovereign question, park the task, move to the next. Do not decide it to keep momentum.
One lock at a time. Do not open a second structural change while the first is ungated. Reliable-but-ungated is the dangerous state.
Scored before started. No task is executed before it has a BVP score. If an unscored task is the obvious next move, score it first through the scorer, not by estimate.
TermLink

Use TermLink where it is the right instrument, not decoratively:

Dispatch BVP estimation to the bvp-estimator worker rather than scoring inline.
Run independent tasks concurrently where they touch disjoint paths; serialize anything touching shared state.
Carry the run record on it so state survives a context reset.

If TermLink is unavailable, or using it would obscure the audit trail, work directly and record why.

Execution loop

Per unit of work:

State the selection (objective → arc → task → quadrant) and the rationale.
Execute the activities the acceptance criteria require.
Run the check that closes each criterion. Record result, pass or fail.
Close or park the task through the proper verb.
Log: what changed, what it cost against estimate, what it surfaced.

If a task fails its acceptance criteria twice, stop working it, record the failure mode, and move on. Three attempts at the same wall is context burned, not progress.

Stop conditions

Stop at the first of:

All Q1 and Q2 tasks in the active arc are complete, and no other arc has eligible Q1/Q2 work, or
context reaches ~800k, or
a Sovereign question blocks every remaining eligible path.

Do not stop mid-task. Close or park the current task, then write the handback.

Handback
Objectives advanced, and by how much — against the state at run start.
Arc state: tasks by status and quadrant.
What remains in Q1/Q2, per task, with the reason it was not done.
Sovereign questions raised, unresolved, in priority order.
Gates that refused you, and what you did instead.
Cost-vs-estimate deltas worth feeding back into calibration.
Auditability

This run will be reviewed against the bindings above. Every claim in the handback must be traceable to a recorded check or a verb-gated state change. An assertion that something works, without the check that demonstrates it, counts as an open task and not a closed one.


---

## Previous round handback (round 9 of 9)

# procAsFit round 8 of 9 — handback

**Status:** COMPLETE. Stop condition fired: nothing has changed since round 7, and a re-measured rank shows the same result (§2).
**Run:** 2026-09-29 08:50:02Z to about 08:52Z, branch `bleeding-edge`, start commit `52f41d49`.
**Commits:** this handback only (T-922). **Filed, closed or parked:** nothing.
**Context at stop:** about 61K of 800K. `checkpoint.sh budget` gives `level: ok`, `tokens: 60688`.

> Skeleton written at 08:50:02Z, before any other action. Filled at the end.

## 1. Inherited-state census
- **No commit since round 7.** `git log 52f41d49..HEAD` is empty. HEAD is round 7's own handback commit.
- **No half-finished units.** `.tasks/` diffs are the same 6 one-line `last_update` bumps (6 insertions and 6 deletions). A grep for changed frontmatter keys other than `last_update` returns nothing.
- **No new rulings.** The newest commit touching `decisions.yaml` or `.tasks/` since 08:00Z is still `6723041c`, round 4/5's own content repair.
- **Focus:** `current_task: T-922`.
- The "Tasks at started-work: T T T …" line in the dispatch snapshot is the known F3 rendering bug. It carries no information, so I relied on git and grep instead.

## 2. Selection trail
**Level 1 (Project) and Level 2 (Arc):** unchanged from rounds 4–7, since none of their inputs has a commit (§1).
**Level 3 (Task):** I re-ran `fw bvp --include-proposed`. The scores match rounds 4–7: T-309/T-357/T-681 252, T-155/T-811 189, T-358 175, T-885 160, T-189 151, T-876/T-925/T-930 142, T-347 136, T-840 134, T-889 133. Each row keeps the eligibility verdict it was given in round 4 §2 and round 5. Those were blocked by a Sovereign ruling, owned by the human, or already held, and none of those inputs changed.
**Q1 rows, re-checked by grep:**
| Task | BVP/quad | Status / owner / horizon | Why ineligible |
|---|---|---|---|
| T-863 | 103 hv-lc | captured / agent / **later** | Promoting it is a Sovereign priority decision (SQ 10) |
| T-860 | 97 (no quadrant) | captured / agent / **later** | Same reason |
| T-702 | 127 hv-lc | started-work / **human** / now | Owned by the human |
**Result: no unit of work was selected.** No task needed a score, so I dispatched no scoring.

## 3. Objectives advanced, against run start
None. G1–G6 are unchanged.

## 4. Arc state
Same as round 7 §4:
- arc-005 has T-876 held (PD-343) and T-924 at `later`.
- arc-001 has T-889 (Sovereign), T-901 and T-424 blocked, and 42 partial-completes waiting on the human.
- arc-002 has T-826 at `issues` and T-681 with the human.
- arc-004 has nothing at `now`.

## 5. What remains in Q1/Q2, per task, and why not done
- **Q1:** nothing eligible (see the table in §2).
- **Q2 and above-median unquadranted:** the same 12 tasks, each blocked for the reason given in round 4 §2.
- Nothing is left undone for lack of time or context.

## 6. Sovereign questions, unresolved, priority order
Carried unchanged from round 7 §6, because no ruling has arrived:
1. T-826: AC 6 vs AC 1.
2. T-925: should the bridge emit `aef:workflowMeta`?
3. T-811: decide it on the current evidence. `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task review T-811`
4. T-889: AC 1.
5. T-876: PD-343.
6. T-358: `A·B·C·AB·no repair`.
7. T-341, T-353 and T-901.
8. T-840: is the GitHub mirror bleeding-edge, or do you authorise `--from-upstream`?
9. Is goal-less vendored framework work (T-930/T-929/T-928, and the gap where the close commit is missing its content) in scope?
10. Should T-863 be promoted? It is the only agent-owned Q1 task. `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-863 --horizon now`

## 7. Gates that refused me, and what I did instead
None.

## 8. Findings surfaced
- **F1, correcting round 7 F1 (a timezone misread):** `ls -la` prints local time (+02:00), not Z.
  - `round8-prompt.md` has mtime 10:49 local, which is 08:49Z. That is after round 7's handback (08:49Z) and before this round's start (08:50:02Z). The order is correct, and this round's prompt does contain round 7's handback.
  - `round9-prompt.md` has mtime 08:55 local, which is 06:55Z. It is a **stale file from an earlier orchestrator pass**, and will be overwritten when round 9 is dispatched, as round 8's was. The orchestrator has no ordering defect.
  - One real, minor issue remains: the prompt header says "Previous round handback (round 8 of 9)" above round 7's text. It uses the current round number, not the previous one. This is cosmetic.
- **F2 (minor):** in `run-log.tsv`, the `dispatched_at` column records when a round **ended**, not when it was dispatched. For example, row 6 reads 08:48:40Z, and round 7 independently gives that as round 6's end time. The column name is misleading when you audit timing.
- **F3 (repeat):** the dispatch census line "Tasks at started-work" still prints bare `T`s.
- **F4 (repeat of round 6/7 F2):** rounds 4–8 have all re-measured an identical board. Round 9 will measure it again unless §6 is ruled on first. Running it adds no value until a ruling lands.

## 9. Cost vs estimate
No task was executed. The round took about 2 minutes: census, one rank re-run, one grep and one commit.

## 10. Auditability
- **State changes:** one commit (this file). Focus was already T-922, so no verb call was needed.
- **Re-runnable checks:**
  - `git log 52f41d49..HEAD`
  - `git diff -- .tasks/ | grep '^[+-][a-z_]*:' | grep -v last_update` (empty)
  - `.agentic-framework/bin/fw bvp --include-proposed | head -22`
  - `grep -E '^(owner|horizon|status):' .tasks/active/T-86[03]-*.md .tasks/active/T-702-*.md`
  - `ls -la .context/working/procasfit9/` together with `date -u` (F1)
- **TermLink:** not used. There was nothing to score and no parallel work, so using it would have been decorative.

## 11. Stop condition
**Fired:** "a Sovereign question blocks every remaining eligible path", together with "no arc has eligible Q1/Q2 work". The rank re-run and the eligibility grep in §2 measured this. Nothing is left mid-task.


---

STATE YOU INHERIT, observed at dispatch time (git + the task register, not a claim about who left it). An earlier round of this run was cut off by a quota refusal after closing a task and opening another, so some of this may be a half-finished unit. Census it before selecting new work: finish or park what is open through the proper verb rather than leaving it uncommitted. Re-read git log yourself — this snapshot is already aging.

Tasks at started-work: T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T T 

Uncommitted paths (first 20, housekeeping excluded):
 M .context/project/metrics-history.yaml
 M .context/telemetry/bvp-sticky.jsonl
 M .tasks/active/T-669-uncontrolled-absence-assertions-rose-78-.md
 M .tasks/active/T-737-handoversh-reports-3-urgent-observations.md
 M .tasks/active/T-826-emit-the-diagram-kind-marker-the-resolvi.md
 M .tasks/active/T-889-aefmeta-authority-on-the-element--the-si.md
 M .tasks/active/T-897-orchestrate-4-sequential-procasfit-auton.md
 M .tasks/active/T-922-orchestrate-9-sequential-procasfit-auton.md
 M tests/.run-history.tsv
?? .agentic-framework/.context/audits/unit-suite/
?? .agentic-framework/.context/locks/
?? .claude/settings.json.pre-t857
?? .context/handovers/S-2026-0927-2319.discard-manifest.yaml
?? .context/handovers/S-2026-0927-2351.discard-manifest.yaml
?? .context/handovers/S-2026-0929-0843.discard-manifest.yaml
?? .context/handovers/S-2026-0929-0920.discard-manifest.yaml
?? .context/handovers/S-2026-0929-1018.discard-manifest.yaml
?? 0
?? designer-initial.png
?? importlib.util


---

This is round 9 of 9. Write your handback to /opt/832-Workflow-designer/.context/working/procasfit9/round9-handback.md.

WRITE IT AS A SKELETON FIRST, BEFORE YOU START WORKING, and fill each section as you go. Do not leave it to the end. Round 2 of this run closed a task and opened another with real implementation, then died on a quota refusal with an empty handback — 26 minutes of work that no later round could see. A round with no handback file is a FAILED round regardless of what it accomplished.
