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

## Previous round handback (round 7 of 9)

# procAsFit round 6 of 9 — handback

**Status:** COMPLETE. The stop condition fired on WORK: nothing in the board's inputs has changed since round 5, and a mechanical re-join confirms it (§2).
**Run:** 2026-09-29 08:47Z–~08:52Z, branch `bleeding-edge`, start commit `9edee8c4`.
**Commits:** this handback only (T-922). **Filed / closed / parked:** nothing.
**Context at stop:** about 65K of 800K.

> Skeleton written at 08:47:19Z before any other action, filled at the end.

## 1. Inherited-state census
- **Dispatch timing:** round 5 ended at 08:47:07Z (`run-log.tsv` row 5, 164 s). This round started at 08:47:19Z.
- **No commit since round 5's handback.** `git log -3`: HEAD is `9edee8c4` (08:46:55Z).
- **Half-finished units: none.** The only `.tasks/` diffs are 6 one-line `last_update` bumps (T-669, T-737, T-826, T-889, T-897, T-922; `git diff --stat -- .tasks/` → 6 insertions and 6 deletions). This is the post-commit bump that round 4 §8 F2 identified. None of them changes a status, so I left them.
- **Rulings:** none since round 4 read the board. The last `decisions.yaml` commits today are `162afe3b` (00:05Z), `7c956b50` (07:00Z), `a29fa9db` (07:17Z) and `21d72435` (07:35Z). All are earlier build work (T-882/T-923/T-883/T-884) that predate round 4's board read at about 08:40Z.
- **Correction to round 5 §1:** round 5 said "no commit touched `decisions.yaml` today". The accurate statement is "none since 08:00Z", which matches its own re-runnable check `--since=08:00Z`. The four commits above are from earlier today. This does not change round 5's conclusion.
- **Dispatch census still prints bare `T`s** (round 5 §8 F2 is unfixed). I used the register directly.

## 2. Selection trail
**Level 1 (Project) / Level 2 (Arc):** unchanged from round 5 §2. Their inputs (goals doc, arc membership, blocker tasks) have no commit since then.
**Level 3 (Task), re-measured:** I ran `fw bvp --include-proposed`, joined it with task frontmatter, and filtered to `owner: agent` and `horizon ≠ later`. The result is **identical to rounds 4–5**: T-811 189, T-358 175, T-876/T-925/T-930 142, T-840 134, T-889 133, T-341 127, T-922 124, T-826 115 (`issues`), T-928/T-929 106. Below those is T-741 94 `lv-lc`, which is excluded on value.
**Q1 rows the filter excluded, checked individually rather than assumed:**
| Task | BVP/quad | Why ineligible |
|---|---|---|
| T-863 | 103 hv-lc | `horizon: later`. Promoting it is a priority decision (Sovereign), not mine to make |
| T-860 | 97 (unquadranted) | `horizon: later`, same reason |
| T-702 | 127 hv-lc | `owner: human` |
Every eligible row keeps the verdict round 4 §2 gave it (Sovereign-held, or objective-gated vendored framework work), because none of its inputs changed (§1).
**Result: no unit of work selected.** No BVP dispatch was needed because no unscored task was the next move.

## 3. Objectives advanced, against run start
None. G1–G6 are unchanged.

## 4. Arc state
Unchanged from round 5 §4. arc-005: T-876 held (PD-343), T-924 `later`. arc-001: T-889 Sovereign, T-901/T-424 blocked, 42 partial-completes waiting on the human. arc-002: T-826 `issues`, T-681 human. arc-004: nothing at `now`. arc-003: not entered.

## 5. What remains in Q1/Q2, per task, and why not done
Q1 eligible: empty. T-863 and T-860 are parked at `later`, and T-702 is owned by the human (§2). Q2 and the above-median unquadranted tasks: the same 12, each blocked for the reason in round 4 §2. Nothing is undone for lack of time or context.

## 6. Sovereign questions, unresolved, priority order
Carried unchanged from round 5 §6 (no ruling has landed):
1. T-826: AC 6 vs AC 1.
2. T-925: should the bridge emit `aef:workflowMeta`?
3. T-811: decide on current evidence (T-573 partly staled the DEFER). `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task review T-811`
4. T-889: AC 1.
5. T-876: PD-343.
6. T-358: `A·B·C·AB·no repair`.
7. T-341 / T-353 / T-901.
8. T-840: is AEF bleeding-edge on the GitHub mirror, or do you authorise `--from-upstream`?
9. Are goal-less vendored framework fixes (T-930/T-929/T-928, plus round 5 F1, where the close commit is missing its content) in scope, or should they go upstream?
10. **New in this round:** should T-863 (hv-lc 103, the only agent-owned Q1 task on the board) be promoted from `later`? Promoting it is the only way this run gets eligible Q1 work without a design ruling. `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task update T-863 --horizon now`

## 7. Gates that refused me, and what I did instead
None this round. `fw context focus T-922` succeeded (`Current focus: T-922`).

## 8. Findings surfaced
- **F1:** the census line is still broken (round 5 F2). The fix is the orchestrator's, not the round's.
- **F2:** re-dispatch has no marginal value. Rounds 4, 5 and 6 each re-measured the same board within minutes of each other. Rounds 7–9 will find the same result unless §6 is ruled on first. The orchestrator could skip a round when `git log <prev-round-end>..HEAD -- .context/project/decisions.yaml .tasks/` is empty apart from `last_update` bumps.

## 9. Cost vs estimate
No task was executed. Cost was about 5 min wall-clock: census, one join, one commit.

## 10. Auditability
- **State changes:** `fw context focus T-922` (verb) and one commit (this file). No direct writes to focus/arc-focus/next-directive.
- **Re-runnable checks:** `git log 9edee8c4..HEAD` · `git diff --stat -- .tasks/` · the §2 join over `fw bvp --include-proposed` · `grep -E '^(owner|horizon):' .tasks/active/T-86[03]-*.md .tasks/active/T-702-*.md`.
- **TermLink was not used:** there was nothing to score and no parallel work, so a dispatch would have been decorative.

## 11. Stop condition
**Fired: "a Sovereign question blocks every remaining eligible path"**, together with "no arc has eligible Q1/Q2 work". This was measured by the §2 re-join. Nothing is mid-task.


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

This is round 7 of 9. Write your handback to /opt/832-Workflow-designer/.context/working/procasfit9/round7-handback.md.

WRITE IT AS A SKELETON FIRST, BEFORE YOU START WORKING, and fill each section as you go. Do not leave it to the end. Round 2 of this run closed a task and opened another with real implementation, then died on a quota refusal with an empty handback — 26 minutes of work that no later round could see. A round with no handback file is a FAILED round regardless of what it accomplished.
