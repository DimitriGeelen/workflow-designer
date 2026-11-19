# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Record your 'a' on T-676 the formal way (AEF's new route), then the reviewer closes it; H1 on T-732 rides along"
JOB_TASK="T-1063"
JOB_WHY="You ruled 'a' on T-676 yesterday and declined to tick its box (a rubber stamp). AEF built the route for exactly
this (their T-5235, now in be.60): you record the ruling once with an operator-only command, and the reviewer then judges
the box against that record instead of you ticking it. Step 1 shows what is recorded; step 2 records it. The reviewer
then judges T-676, and re-checks H1 on T-732 (already green, its tick was withdrawn only because a file it cites
changed). Green verdicts tick both. Nothing is pushed."

T676=.tasks/active/T-676-p-002-blocks-resume-itself-a-session-tha.md
T732=.tasks/active/T-732-drain-the-h-register-four-open-operator-.md
RULING='a'
REF='operator in session 2026-11-18, recorded under the criterion (commit b826295ef)'

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "both task files are committed as is" 'git diff --quiet -- $T676 $T732'
    check "the vendored framework has the ruling verb (be.60)" '.agentic-framework/bin/fw reviewer ruling record --help >/dev/null'
}

steps() {
    step "Show what will be recorded for T-676's box; writes nothing" \
        '.agentic-framework/bin/fw reviewer ruling record T-676 --ac 1 --ruling "$RULING" --ref "$REF" --dry-run'
    step_operator "Record your ruling 'a' on T-676 (operator-only command) and commit the record" \
        '.agentic-framework/bin/fw reviewer ruling record T-676 --ac 1 --ruling "$RULING" --ref "$REF" && do_commit_ruling'
    step_outward "The reviewer judges T-676, and re-checks H1 on T-732 (model calls; verdicts commit themselves)" \
        '.agentic-framework/bin/fw reviewer judge T-676; .agentic-framework/bin/fw reviewer judge T-732 --criterion 1'
    step_outward "Apply the green verdicts to T-676 and T-732, and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-676; .agentic-framework/bin/fw reviewer verdict apply T-732; do_commit_apply'
}

do_commit_ruling() {
    # Only the ruling ledger (lib/recorded_ruling.py: RULINGS); a ruling counts once it is committed.
    local p=.context/reviews/recorded-rulings.jsonl
    [ -f "$p" ] || { echo "no $p after the record step; the agent will look"; return 1; }
    git add -- $p && git commit -q -m "T-1063: operator recorded ruling 'a' on T-676 AC1 through AEF's ruling route (T-5235; operator job 168)" -- $p \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$T676 $T732 .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the steps above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: green reviewer verdicts applied to T-676 and T-732 (operator job 168)" -- $p \
        && git log --oneline -1
}
