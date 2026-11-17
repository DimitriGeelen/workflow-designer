# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Apply T-1212's fresh green reviewer verdicts (three reviewers, 2026-11-17)"
JOB_TASK="T-1063"
JOB_WHY="Job 152 found T-1212's October verdict stale (the work changed after it was judged), so it was not applied.
I re-ran the reviewer: three independent reviewers judged it green on 2026-11-17. My session may not edit a human-owned
task whose agent side is closed, so the apply runs from yours. No judgement is asked of you: it records theirs, and
re-checks each verdict before applying it. Nothing is pushed: I push and close T-1212 afterwards."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1212 is partial-complete in active/" 'grep -q "^status: work-completed" .tasks/active/T-1212-downgrade-e-gw-outgoing--e-xml-gw-outgoi.md'
}

steps() {
    step "Apply T-1212's green reviewer verdicts (fw reviewer verdict apply) and show what it did" \
        '.agentic-framework/bin/fw reviewer verdict apply T-1212'
    step "Commit what the apply changed (T-1212's task file and .context/reviews/applied.jsonl)" 'do_commit'
}

do_commit() {
    local p=".tasks/active/T-1212-downgrade-e-gw-outgoing--e-xml-gw-outgoi.md .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the step above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: T-1212's green reviewer verdicts applied (fresh panel 2026-11-17; operator job 153)" -- $p \
        && git log --oneline -1
}
