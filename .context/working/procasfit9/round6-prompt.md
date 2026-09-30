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

## Previous round handback (round 6 of 9)

# procAsFit round 5 of 9 — handback

**Status:** COMPLETE. The stop condition fired on WORK, not context: the board is the same one
round 4 found fully blocked four minutes earlier, and a mechanical re-check confirms it (§2).
**Run:** 2026-09-29 08:44Z–~08:52Z, branch `bleeding-edge`, start commit `26b7ab86`.
**Commits (2, local, none pushed):** `6723041c` (T-922: commit the closed content of
T-891/T-906/T-908) · this handback (T-922).
**Filed:** nothing. **Closed:** nothing. **Parked:** nothing. **Context at stop:** well under 100K of 800K.

> Skeleton written at 08:44Z before any other action, filled at the end.

## 1. Inherited-state census

- **Dispatch timing:** round 4 finished at 08:44:23Z (`run-log.tsv`, 243 s), and this round
  started seconds later. Nothing could have changed on the board in between, and the checks
  below confirm that.
- **Half-finished units found and finished: T-891, T-906 and T-908 were closed but never fully
  committed.** Their close commits (`e14ccfb8` for T-891, `c3da49c8` for T-906, `6a483b9f`
  for T-908's move) contain **only the `git mv` rename, with 0 lines changed**
  (`git show --stat e14ccfb8` → `0 insertions(+), 0 deletions(-)`). HEAD therefore held
  `.tasks/completed/` files whose frontmatter still read `status: started-work`,
  `date_finished: null`. The working tree had the real close: `work-completed`,
  `date_finished`, the RCA, rewritten Verification legs, the confirmed BVP score, and the
  `status-update [task-update-agent]` line in Updates. That line shows the close verb had
  run. Round 2 §1 listed these as "not mine" and rounds 3–4 left them alone. I committed them
  as-is, with no content change, in `6723041c`. The commit is under T-922 because the focus
  verb refused the tasks' own ids (§7).
- **Remaining task diffs are `last_update`-only bumps** (T-669, T-737, T-826, T-889, T-897,
  T-922). Round 4 §8 F2 traced them to `fw git commit` bumping `last_update` after the commit.
  They are not status changes, so I left them.
- **Dispatch census is unreadable:** the prompt's "Tasks at started-work" line printed 39 bare
  `T`s with no ids (§8 F2). I used the register directly instead.
- **Rulings since round 4:** none. No commit touched `decisions.yaml` today. The blocker tasks
  have not changed since round 4's reads: T-811 09-26, T-358 09-26, T-341 09-26, T-840 09-26,
  T-876 09-26, T-889 09-28. T-826, T-925 and T-930 were last written by rounds 3–4 themselves.
- **Concurrency:** `claude` PID 206226 under `claude-fw` (1 h 16 m) is the orchestrator's host,
  as round 4 found. Round 4's PID 1241435 is no longer in the process list. No foreign commit
  landed in this window (`26b7ab86` → `6723041c` are consecutive).

## 2. Selection trail

**Level 1 — Project:** unchanged. `docs/832-project-purpose-and-goals.md` §3 says G0 is "not
a goal", and §7 gives arc-002 and arc-003 no goal.
**Level 2 — Arc:** unchanged. arc-005 is blocked (T-876 is held by PD-343, T-924 is `later`).
arc-001's only above-median agent task is T-889, which is Sovereign. arc-004 has nothing at
`now`/`next`.
**Level 3 — Task, re-measured, not inherited:** I re-ran round 4's join
(`fw bvp --include-proposed` × task frontmatter, filtered to `owner: agent` ∧
`horizon ≠ later`). **The top 12 are identical to round 4 §2 in id, score and status:**
T-811 189, T-358 175, T-930/T-925/T-876 142, T-840 134, T-889 133, T-341 127, T-922 124,
T-826 115, T-929/T-928 106. Each still carries round 4's verdict (Sovereign, or the objective
gate), because none of their inputs changed (§1). Everything below is `lv-lc`/`lv-hc`
(T-741 94 lv-lc down), which the mandate excludes on value.

**Result: no unit of work was selected.** Nothing was started, so no BVP scoring was dispatched.

## 3. Objectives advanced, against run start

**None of G1–G6 moved.** What changed is register integrity: three task closes that existed
only in the working tree are now in git. A clone, another worktree, or a `git show HEAD:`
reader no longer sees three finished tasks as `started-work` inside `completed/`.

## 4. Arc state

Unchanged from round 4 §4. arc-005: 12 completed, T-876 held, T-924 `later`. arc-001: T-889
Sovereign, T-901/T-424 blocked, 42 partial-completes with the human. arc-002: T-826 `issues`,
T-681 human. arc-004: nothing at `now`. arc-003: not entered.

## 5. What remains in Q1/Q2, per task, and why not done

Q1: empty (re-measured, §2). Q2 and the unquadranted above-median tasks: the same 12, each
blocked for the reason in round 4 §2's table, which this round re-checked. Nothing is "not
done for lack of time".

## 6. Sovereign questions, unresolved, priority order

Carried unchanged from round 4 §6, since no ruling has landed:
1. T-826: AC 6 vs AC 1.
2. T-925: should the bridge emit `aef:workflowMeta`?
3. T-811: decide on current evidence (T-573 partly staled the DEFER).
   `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task review T-811`
4. T-889: AC 1.
5. T-876: PD-343.
6. T-358: `A·B·C·AB·no repair`.
7. T-341 / T-353 / T-901.
8. T-840: is AEF bleeding-edge on the GitHub mirror, or authorise `--from-upstream`?
9. Are goal-less vendored framework fixes (T-930/T-929/T-928) ever in scope, or should they go
   upstream as pickups? **This round adds a fourth candidate to that question** (§8 F1): the
   close verb loses its own edits from the close commit.

## 7. Gates that refused me, and what I did instead

1. **`check-active-task`, "No active task"**, on a read-only `for … git log` loop. `fw context
   init` had cleared focus, and a `for` loop is not on the safe-commands allowlist. I ran
   `fw context focus T-922` bare and then re-ran the same read.
2. **`fw context focus T-891` → "Cannot focus T-891: it is completed, not active."** This is
   correct: focus on a completed id would block every later tool call. I committed the three
   files under the active orchestration task T-922 and named each id in the message. I staged
   only those three paths (`git diff --cached --stat` showed 3 files). No `--force`, no
   `--skip-*`, no `FW_SWITCH_FOCUS`, no bypass.

## 8. Findings surfaced

**F1 — the close path commits the rename but not the close.** In three separate closes
(T-891 09-27, T-908 09-27, T-906 09-28, across different rounds and models), the commit
carried `git mv active→completed` with the pre-close content only. The status flip,
`date_finished`, RCA, Verification rewrites and score edits stayed unstaged. Likely mechanism
(**hypothesis, not verified**): `update-task.sh` does `git mv`, which stages the rename with
the old blob, then edits the file. `fw git commit` commits the index as staged, so the later
edits never enter the commit unless someone runs `git add` again. The effect is that the
committed register disagrees with the working register, and **nothing detects it**: rounds
2–4 saw the diff and read it as noise. The fix site is vendored framework tooling, so under
the objective-gate ruling I recorded it rather than filing a build task. It belongs with
SQ 9. A cheap detector would be any `.tasks/completed/*.md` in HEAD whose `status:` is not
`work-completed`.

**F2 — the orchestrator's dispatch census drops task ids.** The line "Tasks at started-work:"
printed 39 bare `T`s. That is probably a field-split/`cut` on `T-` in the orchestrator script.
The census exists precisely so a round can find half-finished units, and in this form it
cannot. The script is orchestrator tooling under T-922. I did not modify it this round (it is
not a Q1/Q2 task, and the orchestrator is live), and I flag it for whoever maintains the run.

## 9. Cost vs estimate

No task was executed, so there is no estimate to compare. Cost was about 8 min wall-clock: the
census, one commit and one eligibility join. **Calibration input:** five rounds in a row the
binding constraint has been operator rulings. Rounds 4 and 5 each took minutes. Re-dispatching
rounds 6–9 onto an unchanged board will produce the same result.

## 10. Auditability

- **State changes:** `fw context init`; `fw context focus T-922` (the verb, twice);
  `fw context focus T-891` was refused (§7). One commit, `6723041c`, of content the close verb
  had already produced (each file's Updates carries its `task-update-agent` line). No direct
  writes to `focus.yaml`, `arc-focus.yaml` or `.next-directive.yaml`.
- **Re-runnable checks:** `git show --stat e14ccfb8` (0-line rename) · the §2 join over
  `fw bvp --include-proposed` · `git log --since=2026-09-29T08:00Z -- .context/project/decisions.yaml`
  (empty).
- **TermLink was not used.** Nothing needed scoring and there was no parallel work, so a
  `bvp-estimator` dispatch would have been decorative.
- F1's mechanism is labelled a hypothesis. The symptom (three 0-line close commits, HEAD
  `status: started-work` in `completed/`) is checked.

## 11. Stop condition

**Fired: "a Sovereign question blocks every remaining eligible path"**, together with "no arc
has eligible Q1/Q2 work". This was measured by the §2 re-join, not inherited. Nothing is
mid-task.

**For rounds 6–9:** the board will not change unless the operator rules on §6. The most useful
thing between rounds is routing §6 (and F1/F2) to the operator, not re-dispatching.


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

This is round 6 of 9. Write your handback to /opt/832-Workflow-designer/.context/working/procasfit9/round6-handback.md.

WRITE IT AS A SKELETON FIRST, BEFORE YOU START WORKING, and fill each section as you go. Do not leave it to the end. Round 2 of this run closed a task and opened another with real implementation, then died on a quota refusal with an empty handback — 26 minutes of work that no later round could see. A round with no handback file is a FAILED round regardless of what it accomplished.
