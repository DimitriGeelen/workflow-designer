# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Record your GO on T-1118 (field approval and visibility: B1 hide empty fields, B2 field profile, B3 suggest and approve)"
JOB_TASK="T-1118"
JOB_WHY="Your decision today (R1, 'proceed as recommended'): GO on all three builds, in order. B1 hides empty
fields behind '+ N empty fields' (measured: a service task shows 13 fields, the corpus fills a median 2).
B2 adds a field profile per project and a per-workflow setting in the map (most specific wins; a field with a
value is never hidden). B3 adds 'Suggest as a field' on unknown keys; nothing becomes a field until you approve
it through a runme job. Findings: docs/reports/T-1118-fields-on-approval-and-visibility.md. A GO decision is
yours (Tier 0 for the agent), so it runs here. The agent then files B1-B3 as separate build tasks."

T=T-1118
RATIONALE="Operator R1 2026-10-11: GO on all three builds in order — B1 hide empty fields (median 2 of 13 service-task fields filled), B2 project + workflow field profile (most specific wins, a filled field is never hidden), B3 suggest-as-field approved by the operator via runme. Each bounded, testable, reversible; defaults reproduce today's panel. Findings: docs/reports/T-1118-fields-on-approval-and-visibility.md"

preflight() {
    check "$T is an active inception" 'f=$(ls .tasks/active/$T-*.md) && grep -q "^workflow_type: inception" "$f"'
    check "$T has no decision recorded yet" '! grep -qE "^\*\*Decision\*\*: (GO|NO-GO)" .tasks/active/$T-*.md'
    check "the agent recommendation is GO" 'grep -q "^\*\*Recommendation:\*\* GO" .tasks/active/$T-*.md'
    check "the research report is committed" 'git ls-files --error-unmatch docs/reports/T-1118-fields-on-approval-and-visibility.md >/dev/null && git diff --quiet HEAD -- docs/reports/T-1118-fields-on-approval-and-visibility.md'
}

steps() {
    step "Record GO on $T: fw inception decide $T go --rationale '…'" 'do_decide'
}

do_decide() {
    .agentic-framework/bin/fw inception decide "$T" go --rationale "$RATIONALE"
}
