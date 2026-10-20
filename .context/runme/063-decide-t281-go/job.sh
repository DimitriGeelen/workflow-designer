# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Record your GO on inception T-281 (audience lenses: slice 1, the business lens in the designer)"
JOB_TASK="T-281"
JOB_WHY="You ruled GO on T-281 today (chat), and that you read the lens maps in the designer. An inception decision is
Tier 0, so it is yours to record. GO means slice 1: a lens switch in the designer toolbar (business / logical /
technical / all), the business lens first, driven by a lens definition AEF owns (their T-4402); accepted when you
open aef-task-lifecycle in the business lens and can follow it. It is a render-only view: the saved BPMN does not
change. Logical/technical lenses and AEF's text reader follow as their own tasks; the pseudocode lens stays out.
Nothing is built by this job. Step 2 commits the closed task, so nothing is left staged for the next job."

RATIONALE="Operator GO (2026-10-20). The earlier DEFER waited for a real consumer; one exists since 2026-10-19: the operator via the onboarding curriculum (AEF msg 705e7d58), fixtures aef-task-lifecycle / aef-session-lifecycle, read in the designer. AEF T-2669 places lenses in the designer as a render-only view; AEF owns the shared lens definition (T-4402). Slice 1: lens definition shape + business lens."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "T-281 is an active inception" 'grep -q "^workflow_type: inception" .tasks/active/T-281-*.md'
    check "no decision is recorded on T-281 yet" 'decision_absent'
    check "the decide gate's own readiness check passes (fw task review: no 'not handoff-ready')" 'review_ready'
}

steps() {
    step "Record GO on T-281 (fw inception decide)" '.agentic-framework/bin/fw inception decide T-281 go --rationale "$RATIONALE"'
    step "Commit the decided (and, if complete, closed) T-281" 'commit_t281'
}

decision_absent() {
    local n
    n=$(grep -c "^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)" .tasks/active/T-281-*.md)
    [ "$n" = 0 ]
}

review_ready() {
    local out
    out=$(.agentic-framework/bin/fw task review T-281 2>&1)
    printf '%s\n' "$out" | grep -q "Review marker created" && ! printf '%s\n' "$out" | grep -q "not handoff-ready"
}

commit_t281() {
    git add -A -- .tasks/active/ .tasks/completed/ .context/episodic/ 2>/dev/null
    git diff --cached --name-only | grep -v -E '^(\.tasks/(active|completed)/T-281-|\.context/episodic/T-281\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit (decide committed it already)"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-281: GO recorded by the operator's job 063 (slice 1: business lens in the designer)" && git log --oneline -1
}
