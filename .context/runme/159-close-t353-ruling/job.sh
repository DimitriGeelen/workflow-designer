# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Tick T-353's ruling box via the reviewer (your 'rubber stamp'), and restart Watchtower"
JOB_TASK="T-1063"
JOB_WHY="You called T-353's box a rubber stamp, so it went to the reviewer instead of you. The reviewer confirmed your
ruling 'a' is recorded and carried out (jobs 155/158, commit 7b2794288). One thing is yours: I corrected a stale count
in the criterion myself (16/16 -> 23 passed / 0 failed), and changing a criterion's wording is your call to record.
Step 1 shows the before/after; step 2 records your acceptance. Then the reviewer judges once more and its green ticks
the box. Last step: Watchtower restarts, because it is serving code older than 13 web/ changes (audit G-104).
Nothing is pushed."

TASK_FILE=.tasks/active/T-353-prepare-the-corpus-for-the-p-011-errexit.md
VID=V-20261117-e5fc8e02

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-353's task file is committed as is" 'git diff --quiet -- $TASK_FILE'
}

steps() {
    step "Show the restatement you are accepting (before and after); writes nothing" \
        '.agentic-framework/bin/fw reviewer restatement accept $VID --dry-run'
    step_operator "Accept it: records your decision (restatements.jsonl) and restates the criterion" \
        '.agentic-framework/bin/fw reviewer restatement accept $VID && do_commit_restatement'
    step_outward "The reviewer judges T-353's box again (a model call; its verdict commits itself)" \
        '.agentic-framework/bin/fw reviewer judge T-353 --criterion 1'
    step_outward "Apply the reviewer's verdict (ticks the box only if it is green) and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-353 && do_commit_apply'
    step_outward "Restart Watchtower so it serves current code" \
        '.agentic-framework/bin/fw watchtower restart'
}

do_commit_restatement() {
    local p="$TASK_FILE .context/reviews/restatements.jsonl"
    git add -- $p && git commit -q -m "T-1063: operator accepted reviewer restatement $VID on T-353 AC1 (operator job 159)" -- $p \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$TASK_FILE .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the step above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: T-353's green reviewer verdict applied — operator ruling 'a' box ticked (operator job 159)" -- $p \
        && git log --oneline -1
}
