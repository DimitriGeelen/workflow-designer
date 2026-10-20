# Pick up here (written at the context limit, 2026-10-20)

Drafts on disk in the previous session's scratchpad (plain files, readable):
  S=/tmp/claude-0/-opt-832-Workflow-designer/572fe488-2aab-419e-ab67-999e6c4a77db/scratchpad

1. **Operator request (2026-10-20): batch selection in the runme menu.** "x"/"all" = every pending job in listed
   order; "3,1,2" / "3 1 2" / "3, 1" = those jobs in the order typed (the priority); one number = as before.
   Defaults told to the operator: each job keeps its y/N per step; the batch stops at the first job that does not
   complete; the whole batch is refused up front if any chosen job is not rehearsed / CHANGED; per-job logs+signals,
   plus a BATCH summary line.
   - Prototype: $S/rl/tools/runme-launcher.sh (real-run section rewritten: selection parsing, up-front refusal,
     run_one() in a subshell per job with its own RUNME_RUN_ID, summary). Separator fix included
     (sed -E 's/[[:space:];,]+/,/g' — "3, 1" used to become "3,,1").
   - Test: $S/rl/tests/test_t1055_runme_launcher.py adds legs 16-20 (x order, "3, 1" order, stop at failing job,
     up-front refusal on CHANGED, bad choices 1,5 and 2,2). 19/20 pass on the copy; leg 12 fails there only because
     the copy is outside a git repo (scaffold preflight checks the branch) — confirm in the repo.
   - To do: file a task (T-1226 was the planned id), copy both files into tools/ and tests/ (the test's ROOT override
     T1055_ROOT may stay or go), run the test in the repo, update CLAUDE.md's runme rule (batch), commit.
     Do it when no suite run is going.
2. **Write-up for AEF** (operator request): $S/runme-job-queue-writeup.md — complete draft. Add a section on the batch
   selection, move it to docs/reports/runme-job-queue-for-aef.md, commit + push, and send AEF (999) a short message
   with the GitHub mirror link (github.com/DimitriGeelen/workflow-designer, path docs/reports/...) asking for inclusion
   in the framework and their task id.
3. **Job 057** (upgrade AEF v1.8.12 -> v1.8.14-be.2, tag c80a8261d; contains T-4399, T-4421, T-3924, T-4454 — checked):
   draft $S/job057.sh. Create with tools/runme-new.sh upgrade-aef-v1.8.14-be.2, copy the draft, dry-run, commit;
   retire 055 (write .context/runme/055-*/retired: "superseded by 057, tagged be.2 carries all four fixes").
4. **T-1219:** job 054 recorded GO (uncommitted in the task file!) but completion failed: IW-3 defers to AEF's T-4415,
   which is not a local task. File a local follow-up ("designer fields for ref/role/cardinality/dataType after AEF
   T-4415 is ruled") mentioning T-1219, point IW-3 at it, commit, then `fw task update T-1219 --status work-completed`.
5. **Standalone suite run** was in progress (output $S/bridge19.txt, head $S/bridge19.head) to find why T-041's
   in-gate suite run was 307/1. Read it; then re-run the T-041, T-101, T-286 closes one at a time, alone; then T-125,
   T-575.
6. T-1203: apply `python3 .context/working/t1203-reg-leg.py tools/_t1203-identity-coverage.sh` (expect 1 FAIL until
   v1.8.14-be.2 is installed and the session relaunched through claude-fw).
