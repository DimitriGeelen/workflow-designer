# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Record your GO on T-1118 (field approval and visibility) — replaces job 012, now rehearsed against the decide gates"
JOB_TASK="T-1118"
JOB_WHY="Your decision (R1): GO on all three builds — B1 hide empty fields, B2 field profile per project and
workflow (a filled field is never hidden), B3 suggest-as-field approved by you via runme. Job 012 was refused by
fw inception decide: the ## Hypothesis success clause was still the estimator's placeholder, and 012's
rehearsal never ran that gate. The hypothesis now names checkable signals (on the 42 service tasks in examples/:
at most 4 field rows shown by default, today 13; 0 filled fields hidden; every non-default field backed by an
approval record). Please read it in the task (or http://192.168.10.107:3013/inception/T-1118); if the wording
is yours too, the agent marks it hypothesis_source: human afterwards on your word. This job's checks run the
framework's OWN predicates (lib/task-audit.sh audit_inception_hypothesis, lib/inception-readiness.sh
inception_handoff_blockers), so a pass here means decide will not refuse on them. Decide asks once more
'Continue with the decision? [y/N]' after showing the review."

T=T-1118
RATIONALE="Operator R1 2026-10-11: GO on all three builds in order — B1 hide empty fields (median 2 of 13 service-task fields filled), B2 project + workflow field profile (most specific wins, a filled field is never hidden), B3 suggest-as-field approved by the operator via runme. Each bounded, testable, reversible; defaults reproduce today's panel. Findings: docs/reports/T-1118-fields-on-approval-and-visibility.md"

preflight() {
    check "$T is an active inception" 'f=$(ls .tasks/active/$T-*.md) && grep -q "^workflow_type: inception" "$f"'
    check "$T has no decision recorded yet" '! grep -qE "^\*\*Decision\*\*: (GO|NO-GO)" .tasks/active/$T-*.md'
    check "the agent recommendation is GO" 'grep -q "^\*\*Recommendation:\*\* GO" .tasks/active/$T-*.md'
    check "the research report and task are committed" 'git diff --quiet HEAD -- docs/reports/T-1118-fields-on-approval-and-visibility.md .tasks/active/$T-*.md'
    check "decide gate: hypothesis passes (framework predicate)" 'source .agentic-framework/lib/task-audit.sh >/dev/null 2>&1 && audit_inception_hypothesis .tasks/active/$T-*.md go'
    check "decide gate: no hand-off blockers (framework predicate)" 'source .agentic-framework/lib/inception-readiness.sh >/dev/null 2>&1 && [ -z "$(inception_handoff_blockers .tasks/active/$T-*.md)" ]'
}

steps() {
    step "Record GO on $T: fw inception decide $T go --rationale '…'" 'do_decide'
}

do_decide() {
    .agentic-framework/bin/fw inception decide "$T" go --rationale "$RATIONALE"
}
