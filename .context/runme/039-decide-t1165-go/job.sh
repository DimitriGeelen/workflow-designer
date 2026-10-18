# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Record your GO on T-1165 (rule-dialect axis: a 4th class CONVENTIONAL, option 1)"
JOB_TASK="T-1165"
JOB_WHY="Your decision today ('1'): GO, option 1 with the additions. The standard is silent on graph shape, yet
13 rules about it (disconnected flow, missing start/end events, unreachable and dead-end steps, parallel-gateway
balance, both forms) are labelled UNIVERSAL in the kit. They become CONVENTIONAL, derived from a per-rule citation
the test checks against the standard (a missing citation means CONVENTIONAL). Additions from the outside review: a
'basis' column in the kit, a stricter citation check (normative keyword, closed list of other grounds), and any of
the 18 well-formedness rules that cannot cite a basis surfaces as a finding. AEF and the independent reviewer both
picked option 1; AEF requires none of the 13 and wants a non-normative v1.x note in the standard.
Findings: docs/reports/T-1165-conventional-dialect-class.md. A GO decision is yours, so it runs here. The agent then
files the build as its own task."

T=T-1165
RATIONALE="Operator 2026-10-18: GO, option 1 (new class CONVENTIONAL) with the review additions. mapping-v1 section 6 is silent on graph shape; 31/63 rules derive UNIVERSAL from structure alone, 13 with no normative basis. Build: per-rule citation verified against the standard (normative keyword, closed list of non-standard grounds), missing citation derives CONVENTIONAL; basis column in the kit; uncited well-formedness rules surface as findings; kit re-calibrated; 13 class changes and a v1.x note proposed to AEF. AEF (msg f1f5ef6f) and an independent reviewer both chose option 1. Bounded, reversible (a label, no stored data), assertable. Findings: docs/reports/T-1165-conventional-dialect-class.md"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "$T is an active inception" 'f=$(ls .tasks/active/$T-*.md) && grep -q "^workflow_type: inception" "$f"'
    check "$T has no decision recorded yet" '! grep -qE "^\*\*Decision\*\*: (GO|NO-GO)" .tasks/active/$T-*.md'
    check "the agent recommendation is GO" 'grep -q "^\*\*Recommendation:\*\* GO" .tasks/active/$T-*.md'
    check "the research report is committed" 'git ls-files --error-unmatch docs/reports/T-1165-conventional-dialect-class.md >/dev/null && git diff --quiet HEAD -- docs/reports/T-1165-conventional-dialect-class.md'
}

steps() {
    step "Record GO on $T: fw inception decide $T go --rationale '…'" 'do_decide'
}

do_decide() {
    .agentic-framework/bin/fw inception decide "$T" go --rationale "$RATIONALE"
}
