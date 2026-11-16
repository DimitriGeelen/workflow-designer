# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Accept the two honest misses (T-897 AC3, T-922 AC1) as [~], and apply T-1212's three green reviewer verdicts"
JOB_TASK="T-897"
JOB_WHY="You asked AEF for a 'not met, accepted' state (T-1415); be.54 has it as 'fw task accept-miss', which refuses in my
session by design. Two criteria were missed and can no longer be met; each has a 'Miss proposed' line with the evidence
under it in its task file:
  - T-897 AC3: rounds were not TermLink-spawned sessions (termlink_spawn gave a false 'ready', OBS-405); the chain ended.
  - T-922 AC1: no feasibility probe before dispatch; all nine rounds still handed back; a probe now proves nothing.
Answer n to a step if you do not accept that miss: the criterion then stays open, nothing else changes.
The last steps apply T-1212's reviewer verdicts: three independent reviewers judged its screenshot criterion green on
2026-10-19 (claude-code, codex, opencode). My session cannot apply them, because a task whose agent side is closed may
not be edited from it. No judgement is asked of you there; it records theirs. Nothing is pushed: I push afterwards."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "framework has accept-miss (AEF be.54)" 'grep -q "accept-miss)" .agentic-framework/bin/fw'
    check "T-897 carries its Miss proposed line" 'grep -q "^  \*\*Miss proposed:\*\*" .tasks/active/T-897-orchestrate-4-sequential-procasfit-auton.md'
    check "T-922 carries its Miss proposed line" 'grep -q "^  \*\*Miss proposed:\*\*" .tasks/active/T-922-orchestrate-9-sequential-procasfit-auton.md'
    check "T-1212 is partial-complete in active/" 'grep -q "^status: work-completed" .tasks/active/T-1212-downgrade-e-gw-outgoing--e-xml-gw-outgoi.md'
}

steps() {
    step_operator "Accept T-897 criterion 3 (TermLink-spawned rounds) as a miss: [~] plus a ledger row" \
        '.agentic-framework/bin/fw task accept-miss T-897 --ac 3 --reason "Rounds were launched directly after termlink_spawn returned a false ready (OBS-405) and then timed out; the four-round chain ended at the weekly quota and T-922 ran the mandate. The run record lives in the task file, not a TermLink channel. Not meetable now; accepted, never counted as met."'
    step_operator "Accept T-922 criterion 1 (feasibility probe before dispatch) as a miss: [~] plus a ledger row" \
        '.agentic-framework/bin/fw task accept-miss T-922 --ac 1 --reason "No feasibility probe ran before dispatch; all nine rounds ran in order and handed back, so the failure it guards against did not occur. A probe now would measure a different machine state. Accepted, never counted as met."'
    step_operator "Commit the two accepted misses (task files and .context/reviews/accepted-misses.jsonl)" 'do_commit_misses'
    step "Apply T-1212's green reviewer verdicts (fw reviewer verdict apply) and show what it did" 'do_apply_t1212'
    step "Commit T-1212's applied verdicts" 'do_commit_t1212'
}

do_commit_misses() {
    local p=".tasks/active/T-897-orchestrate-4-sequential-procasfit-auton.md .tasks/active/T-922-orchestrate-9-sequential-procasfit-auton.md .context/reviews/accepted-misses.jsonl"
    git add -- $p && git commit -q -m "T-897, T-922: operator accepted the proposed misses (T-897 AC3, T-922 AC1) as [~] with ledger rows (fw task accept-miss, AEF be.54 T-5181; 832 T-1415)" -- $p \
        && git log --oneline -1
}

do_apply_t1212() {
    .agentic-framework/bin/fw reviewer verdict apply T-1212
    grep -n "Independent screenshot review" .tasks/active/T-1212-downgrade-e-gw-outgoing--e-xml-gw-outgoi.md | head -2
}

do_commit_t1212() {
    local p=".tasks/active/T-1212-downgrade-e-gw-outgoing--e-xml-gw-outgoi.md .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the step above)"; return 0
    fi
    git add -- $p \
        && git commit -q -m "T-1212: reviewer verdicts applied (three green, 2026-10-19 panel run-t-1212-46f0aaeb3e)" -- $p \
        && git log --oneline -1
}
