# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Close T-368: tick both boxes through the reviewer (your 'a' on box 2; box 1's 0.9.0 is long released)"
JOB_TASK="T-1063"
JOB_WHY="Box 2 (is a notation/routing revision planned?): your 'a' is recorded and the reviewer judged it green.
Box 1 (cut 0.9.0 and tell AEF?): settled long ago, 0.9.0 was tagged (designer-v0.9.0, 8cd0c5d3) and AEF now runs
0.43.0. The reviewer proposes rewording it as a record of that (step 1 shows before/after). Accepting is your call
(step 2). Then the reviewer judges box 1 again, and the green verdicts tick both boxes. Nothing is pushed."

TASK_FILE=.tasks/active/T-368-release-state-blindness-8-src-commits-ah.md
VID=V-20261118-45d4ce68

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-368's task file is committed as is" 'git diff --quiet -- $TASK_FILE'
}

steps() {
    step "Show the restatement of box 1 you are accepting (before and after); writes nothing" \
        '.agentic-framework/bin/fw reviewer restatement accept $VID --dry-run'
    step_operator "Accept it: records your decision (restatements.jsonl) and restates box 1" \
        '.agentic-framework/bin/fw reviewer restatement accept $VID && do_commit_restatement'
    step_outward "The reviewer judges box 1 again (a model call; its verdict commits itself)" \
        '.agentic-framework/bin/fw reviewer judge T-368 --criterion 1'
    step_outward "Apply the reviewer's verdicts (ticks each box only if green) and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-368 && do_commit_apply'
}

do_commit_restatement() {
    local p="$TASK_FILE .context/reviews/restatements.jsonl"
    git add -- $p && git commit -q -m "T-1063: operator accepted reviewer restatement $VID on T-368 AC1 (operator job 160)" -- $p \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$TASK_FILE .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the step above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: T-368's green reviewer verdicts applied — both boxes ticked (operator job 160)" -- $p \
        && git log --oneline -1
}
