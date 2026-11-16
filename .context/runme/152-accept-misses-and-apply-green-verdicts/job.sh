# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
# Supersedes job 151 (never run): the same two accepted misses, plus every unapplied green reviewer verdict (T-1063).
JOB_TITLE="Accept the two honest misses (T-897 AC3, T-922 AC1) as [~]; apply the green reviewer verdicts waiting on T-1212, T-310, T-893"
JOB_TASK="T-1063"
JOB_WHY="Two kinds of step. Only the first two ask for your judgement.
1-2. You asked AEF for a 'not met, accepted' state (T-1415); be.54 has it as 'fw task accept-miss', which refuses in my
     session by design. Two criteria were missed and can no longer be met; each task file has a 'Miss proposed' line
     with the evidence under the criterion:
       - T-897 AC3: rounds were not TermLink-spawned sessions (termlink_spawn gave a false 'ready', OBS-405); the chain ended.
       - T-922 AC1: no feasibility probe before dispatch; all nine rounds still handed back; a probe now proves nothing.
     Answer n if you do not accept a miss: that criterion stays open and nothing else changes.
4-5. Independent reviewers already judged these criteria green, and nobody applied it (T-1063 found them):
       - T-1212 AC1 (gateway warning screenshots): green from three reviewers, 2026-10-19
       - T-310 AC1 and AC3: green, 2026-10-06 and 2026-10-10
       - T-893 AC1: green, 2026-10-10
     My session may not edit a human-owned task whose agent side is closed, so the apply runs from yours. It records
     their judgement, not yours; it re-checks each verdict first and withdraws any that no longer holds.
Nothing is pushed: I push and close the tasks afterwards."

APPLY="T-1212 T-310 T-893"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "framework has accept-miss (AEF be.54)" 'grep -q "accept-miss)" .agentic-framework/bin/fw'
    check "T-897 carries its Miss proposed line" 'grep -q "^  \*\*Miss proposed:\*\*" .tasks/active/T-897-orchestrate-4-sequential-procasfit-auton.md'
    check "T-922 carries its Miss proposed line" 'grep -q "^  \*\*Miss proposed:\*\*" .tasks/active/T-922-orchestrate-9-sequential-procasfit-auton.md'
    check "T-1212, T-310, T-893 are partial-complete in active/" 'for t in $APPLY; do grep -q "^status: work-completed" .tasks/active/$t-*.md || exit 1; done'
}

steps() {
    step_operator "Accept T-897 criterion 3 (TermLink-spawned rounds) as a miss: [~] plus a ledger row" \
        '.agentic-framework/bin/fw task accept-miss T-897 --ac 3 --reason "Rounds were launched directly after termlink_spawn returned a false ready (OBS-405) and then timed out; the four-round chain ended at the weekly quota and T-922 ran the mandate. The run record lives in the task file, not a TermLink channel. Not meetable now; accepted, never counted as met."'
    step_operator "Accept T-922 criterion 1 (feasibility probe before dispatch) as a miss: [~] plus a ledger row" \
        '.agentic-framework/bin/fw task accept-miss T-922 --ac 1 --reason "No feasibility probe ran before dispatch; all nine rounds ran in order and handed back, so the failure it guards against did not occur. A probe now would measure a different machine state. Accepted, never counted as met."'
    step_operator "Commit the two accepted misses (task files and .context/reviews/accepted-misses.jsonl)" 'do_commit_misses'
    step "Apply the green reviewer verdicts on T-1212, T-310, T-893 (fw reviewer verdict apply) and show what each did" 'do_apply'
    step "Commit what the apply changed (the three task files and .context/reviews/applied.jsonl)" 'do_commit_apply'
}

do_commit_misses() {
    local p=".tasks/active/T-897-orchestrate-4-sequential-procasfit-auton.md .tasks/active/T-922-orchestrate-9-sequential-procasfit-auton.md .context/reviews/accepted-misses.jsonl"
    git add -- $p && git commit -q -m "T-897, T-922: operator accepted the proposed misses (T-897 AC3, T-922 AC1) as [~] with ledger rows (fw task accept-miss, AEF be.54 T-5181; 832 T-1415)" -- $p \
        && git log --oneline -1
}

do_apply() {
    local t
    for t in $APPLY; do
        echo "--- $t"
        .agentic-framework/bin/fw reviewer verdict apply "$t"
    done
    return 0
}

do_commit_apply() {
    local p="" t
    for t in $APPLY; do p="$p $(ls .tasks/active/$t-*.md)"; done
    p="$p .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the step above)"; return 0
    fi
    git add -- $p \
        && git commit -q -m "T-1063: green reviewer verdicts applied on T-1212, T-310, T-893 (judged 2026-10-06..19, never applied; operator job 152)" -- $p \
        && git log --oneline -1
}
