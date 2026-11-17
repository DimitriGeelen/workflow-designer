# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Apply your T-353 ruling ('a'): fix 23 verification lines in 13 archived tasks, as proven"
JOB_TASK="T-1432"
JOB_WHY="You ruled 'a' on T-353 today: the archived tasks' verification lines may be edited so they are ready for the
stricter command gate. Archived task files are closed records, so the edit runs from your session, not mine.
What changes: 23 single lines in 13 files under .tasks/completed/ (T-150, T-158, T-194, T-288, T-298, T-299, T-312,
T-313, T-321, T-322, T-329, T-330, T-331). Nothing else. 19 lines get '|| true' on a command that is meant to fail
(so the line's verdict rests on its assertion); 4 get 'grep -q \"^VALID\"' instead of 'grep -q \"VALID\"' (which also
matched INVALID). Every change was re-proven today by T-353's own probes (19/19, 23/23), and the 22 runnable new
lines all pass. Step 1 shows each line before anything is written. Nothing is pushed."

TASKS="T-150 T-158 T-194 T-288 T-298 T-299 T-312 T-313 T-321 T-322 T-329 T-330 T-331"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "the 13 archived task files are unmodified" 'for t in $TASKS; do git diff --quiet -- .tasks/completed/$t-*.md || exit 1; done'
}

steps() {
    step "Show the 23 edits (old and new line each) and check every original occurs exactly once; writes nothing" \
        'python3 tools/_t1432-apply-t353.py --check'
    step_operator "Apply the 23 edits to the archived task files (closed records: your session)" \
        'python3 tools/_t1432-apply-t353.py --apply'
    step_operator "Verify: every new line present, no original left, each runnable new line passes today" \
        'python3 tools/_t1432-apply-t353.py --verify'
    step_operator "Commit the 13 files" 'do_commit'
}

do_commit() {
    local p="" t
    for t in $TASKS; do p="$p $(ls .tasks/completed/$t-*.md)"; done
    git add -- $p && git commit -q -m "T-1432: operator's T-353 ruling 'a' applied — 23 archived Verification lines readied for the errexit gate (19 '|| true' on designed failures, 4 anchored ^VALID), as re-proven by T-353's probes (operator job 155)" -- $p \
        && git log --oneline -1
}
