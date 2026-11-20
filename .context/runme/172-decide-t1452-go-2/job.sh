# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
# --dry-run rehearses every `step` in a clone of HEAD; a step that acts outside the repo (push, tag push, /etc,
# model calls, host services), or needs such a step's result, is `step_outward "<what>" '<cmd>'` instead.
# A verb only the operator may run (fw inception decide, …), which refuses in the agent's session, is
# `step_operator "<what>" '<cmd>'` (T-1324): listed as operator only, never rehearsed, run for real like any step.
JOB_TITLE="Record your GO on the faster test gate (T-1452): split the browser tier over the pool workers now"
JOB_TASK="T-1452"
JOB_WHY="(Replaces 171: that run was refused because the task's hypothesis was still the template; it is written now,
and this job checks it first.) You answered '1, adopt the split now' (2026-11-20). Recording an inception decision is a
command only you may run, so it is this one step. What it records: GO for lever B (the browser tier split over pool-w1
and pool-w2, about 12 min instead of 22-24, every leg the same in 3 of 3 balanced trials), with the full run kept on
the pool as a non-gating shadow so a disagreement still shows; lever A (dropping the local run for designer changes)
stays in shadow, both machines keep gating. Nothing is pushed; the agent then builds the gate change (T-1462)."

T=T-1452
TASKF=".tasks/active/T-1452-faster-test-gate-designer-changes-on-the.md"
RATIONALE="Operator's ruling '1, adopt the split now' (2026-11-20, in session). Lever B met its step-0 expectation in all 3 balanced trials (11.8, 11.9/11.7, 12.0 min submit to verdict vs 22.4-23.7 min whole; slowest shard 48-50% of the whole's compute; every leg the same result, C1-C3 pass; docs/reports/T-1452-faster-test-gate.md). Adopted at 3 runs instead of 10, with the full run kept on the pool as a non-gating shadow: a leg that differs is reported and stops the push, and the remaining runs are still collected. Lever A deferred: fewer than 10 designer runs and one disagreement (the pool caught the A3 defect the local run passed), so both machines keep gating."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-1452 is an active inception" 'grep -q "^workflow_type: inception" "$TASKF"'
    check "T-1452 is committed as is" 'git diff --quiet -- "$TASKF"'
    check "its recommendation reads GO" 'grep -q "^\*\*Recommendation:\*\* GO" "$TASKF"'
    check "its hypothesis is written (not the template)" '! grep -q "<measurable signal>" "$TASKF" && grep -q "^We will know that we are successful when we see every split run" "$TASKF"'
}

steps() {
    step_operator "Record GO on T-1452 (fw inception decide; only you may run it)" \
        '.agentic-framework/bin/fw inception decide $T go --rationale "$RATIONALE"'
}
