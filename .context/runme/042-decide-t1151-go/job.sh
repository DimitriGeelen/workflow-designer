# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Record your GO on T-1151 (832 signs with its own TermLink key, option 1 with the consultation safeguards)"
JOB_TASK="T-1151"
JOB_WHY="Your decision today ('1'). 832 signs with the host key that 126 other sessions share; TermLink's own
learnings (PL-166) name per-agent keys as the fix. GO means: a project key via TERMLINK_IDENTITY_FILE at every 832
entry point (not IDENTITY_DIR, which would also move the pinned hubs), stored in .context/secrets/ (gitignored),
fail-closed launchers, a coverage probe, a both-fingerprint drain window, the new fingerprint announced to AEF, and a
feature request to TermLink for per-topic read control. This step only RECORDS the decision: no key is minted here.
Minting and the first registration with the new identity get their own jobs, with your y/N.
Findings: docs/reports/T-1151-termlink-identity.md."

T=T-1151
RATIONALE="Operator 2026-10-18: GO, option 1 with the consultation safeguards. 832 signs with host key d1993c2c3ec44c94, shared with 126 sessions (termlink whoami); 28 DM rails and the read cursors are shared host-wide. TermLink source: strong transport auth and sender binding, hub as the read trust boundary, no encryption; its PL-166 names per-agent keys as the fix. Build: TERMLINK_IDENTITY_FILE (not DIR) at every 832 entry point, key in .context/secrets/ (ignored), absolute path, fail-closed launchers, per-entry-point coverage probe, both-fingerprint drain window, key backed up, fingerprint announced to AEF; feature request to TermLink for per-topic read control. Spike first, minting by runme job. Independent reviewer: option 1. Findings: docs/reports/T-1151-termlink-identity.md"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "$T is an active inception" 'f=$(ls .tasks/active/$T-*.md) && grep -q "^workflow_type: inception" "$f"'
    check "$T has no decision recorded yet" '! grep -qE "^\*\*Decision\*\*: (GO|NO-GO)" .tasks/active/$T-*.md'
    check "the agent recommendation is GO" 'grep -q "^\*\*Recommendation:\*\* GO" .tasks/active/$T-*.md'
    check "the hypothesis is in the three-part form the decide gate requires" 'grep -q "^we will achieve" .tasks/active/$T-*.md'
    check "the research report is committed" 'git ls-files --error-unmatch docs/reports/T-1151-termlink-identity.md >/dev/null && git diff --quiet HEAD -- docs/reports/T-1151-termlink-identity.md'
}

steps() {
    step "Record GO on $T: fw inception decide $T go --rationale '…'" 'do_decide'
}

do_decide() {
    .agentic-framework/bin/fw inception decide "$T" go --rationale "$RATIONALE"
}
