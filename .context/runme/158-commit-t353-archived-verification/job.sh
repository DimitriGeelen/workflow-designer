# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Finish your T-353 ruling: verify and commit the 23 archived lines job 155 already applied"
JOB_TASK="T-1432"
JOB_WHY="Job 155 applied all 23 edits (its steps 1 and 2), then stopped at step 3 because of a bug in MY verify step:
it insisted the original lines still be there, which a correct apply removes. The edits themselves are right; the fixed
verify passes 23/23 (every new line present once, no original left, each runnable line passes today). The 13 archived
files are still uncommitted, and they are closed records your session wrote, so the commit is yours too. Two steps.
Nothing is pushed."

TASKS="T-150 T-158 T-194 T-288 T-298 T-299 T-312 T-313 T-321 T-322 T-329 T-330 T-331"
TOOL=.context/runme/155-apply-t353-archived-verification/apply_t353.py

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "exactly the 13 archived files carry uncommitted changes, 23 lines" \
        '[ "$(git diff --name-only -- .tasks/completed | wc -l)" = 13 ] && [ "$(git diff --numstat -- .tasks/completed | awk "{a+=\$1} END {print a}")" = 23 ]'
}

steps() {
    step_operator "Verify the applied lines: each new line present once, no original left, each runnable one passes" \
        'python3 $TOOL --verify'
    step_operator "Commit the 13 archived files" 'do_commit'
}

do_commit() {
    local p="" t
    for t in $TASKS; do p="$p $(ls .tasks/completed/$t-*.md)"; done
    git add -- $p && git commit -q -m "T-1432: operator's T-353 ruling 'a' applied — 23 archived Verification lines readied for the errexit gate (19 '|| true' on designed failures, 4 anchored ^VALID), applied by job 155, verified and committed by job 158" -- $p \
        && git log --oneline -1
}
