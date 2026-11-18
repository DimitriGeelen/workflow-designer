# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Finish job 163: T-596's rewording (trimmed to fit), then the reviewer ticks T-596 and T-732"
JOB_TASK="T-1063"
JOB_WHY="Job 163 did its main part: condition 3 is approved (974003222) and the checker reads as tested. It stopped at
step 4 because the reviewer's proposed wording for T-596 is 407 characters and the framework accepts at most 400.
This job accepts the SAME rewording trimmed to 346 characters (step 1 shows before/after; nothing is added or
removed in meaning), then the reviewer judges T-596 and T-732 and green verdicts tick them. Nothing is pushed."

T732=.tasks/active/T-732-drain-the-h-register-four-open-operator-.md
T596=.tasks/active/T-596-arc-0-exit-gate-is-uncheckable-the-opera.md
VID596=V-20261118-7571175e
TEXT596='[REVIEW] Confirm the register read H1 and H3 as **open** when T-596 landed (33b7d204d, 2026-08-26), that each became `resolved` only by an operator ruling (H1 under T-732, H3 under T-830), and that `tools/_t596-arc0-exit-gate.sh` exits non-zero and prints `BLOCKED` for clause 3, naming exactly the questions still open (H5, H6 at this revision).'

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "both task files are committed as is" 'git diff --quiet -- $T732 $T596'
    check "condition 3 is already approved (job 163 step 2 ran)" 'grep -q "in: 832 T-732 (operator ruling" docs/research/executable-workflow/arc-0-exit-clauses.yaml'
}

steps() {
    step "Show T-596's box before and after the trimmed rewording; writes nothing" \
        '.agentic-framework/bin/fw reviewer restatement accept $VID596 --dry-run --text "$TEXT596"'
    step_operator "Accept it (records your decision) and commit" \
        '.agentic-framework/bin/fw reviewer restatement accept $VID596 --text "$TEXT596" && do_commit_restatement'
    step_outward "The reviewer judges T-596 and T-732 again (model calls; verdicts commit themselves)" \
        '.agentic-framework/bin/fw reviewer judge T-596 && .agentic-framework/bin/fw reviewer judge T-732'
    step_outward "Apply the green verdicts to T-596 and T-732, and commit" \
        '.agentic-framework/bin/fw reviewer verdict apply T-596; .agentic-framework/bin/fw reviewer verdict apply T-732; do_commit_apply'
}

do_commit_restatement() {
    local p="$T596 .context/reviews/restatements.jsonl"
    git add -- $p && git commit -q -m "T-1063: operator accepted reviewer restatement $VID596 on T-596 AC1, trimmed to the 400-char limit (operator job 164)" -- $p \
        && git log --oneline -1
}

do_commit_apply() {
    local p="$T596 $T732 .context/reviews/applied.jsonl"
    if git diff --quiet -- $p; then
        echo "apply changed nothing: nothing to commit (the agent will look at the steps above)"; return 0
    fi
    git add -- $p && git commit -q -m "T-1063: green reviewer verdicts applied to T-596 and T-732 (operator job 164)" -- $p \
        && git log --oneline -1
}
