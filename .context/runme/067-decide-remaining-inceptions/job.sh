# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Record the 5 inception decisions job 066 did not reach: 4 GO, 1 NO-GO"
JOB_TASK="T-1065"
JOB_WHY="Job 066 recorded the three DEFERs (T-184, T-185, T-186), then stopped at T-279: the GO was refused because its
hypothesis still had the template placeholder as its success clause. The agent's readiness check (fw task review) had
passed it, so that check missed it. The four GOs now carry countable success clauses (T-282 from its report; T-279
and T-280 agent-drafted first slices from the package spec, since they were never explored; T-1213 for PD-399), and
this job's preflight also checks the success-clause line itself. Each is its own step; n stops the job there.
  T-279  GO     PD-400: guided-mode guardrail (mostly AEF-side; 832 does the designer half)
  T-280  GO     PD-400: Workflow Fabric, the process-dependency graph (mostly AEF-side)
  T-282  GO     PD-400: callActivity, slice 1 round-trip ('callActivity first')
  T-1213 GO     PD-399: ownership by risk assessment, independent reviewer at every agent close
  T-498  NO-GO  you withdrew the premise ('oh i was confused', T-498 lines 119-123)
If a drafted success clause does not say what you mean, answer n there and tell the agent. The last step commits the
decided tasks. Nothing is pushed."

IDS="T-279 T-280 T-282 T-1213 T-498"
GO_IDS="T-279 T-280 T-282 T-1213"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "all five are active inceptions with no decision recorded yet" 'all_undecided'
    check "each GO's success clause is real (no template placeholder on the 'We will know' line)" 'clauses_real'
    check "the decide gate's readiness check passes for all five (fw task review)" 'all_ready'
}

steps() {
    step "T-279: GO (PD-400)" 'decide T-279 go "PD-400 (operator 2026-10-19, T-732): revive and build the guided-mode guardrail; first slice per the hypothesis, runtime half raised with AEF"'
    step "T-280: GO (PD-400)" 'decide T-280 go "PD-400 (operator 2026-10-19, T-732): revive and build the Workflow Fabric; first slice per the hypothesis, graph raised with AEF"'
    step "T-282: GO (PD-400)" 'decide T-282 go "PD-400 (operator 2026-10-19, T-732): callActivity first; slice 1 round-trip per docs/reports/T-282-callactivity.md, AEF T-4374 accepts it"'
    step "T-1213: GO (PD-399)" 'decide T-1213 go "PD-399 (operator 2026-10-19, T-1203): ownership by risk assessment at creation, independent reviewer at every agent close, escalation the only route to the operator"'
    step "T-498: NO-GO (premise withdrawn)" 'decide T-498 no-go "Operator withdrew the premise (T-498 lines 119-123: oh i was confused); T-1065 triage"'
    step "Commit the decided tasks (only their files)" 'commit_decided'
}

decide() { .agentic-framework/bin/fw inception decide "$1" "$2" --rationale "$3"; }

all_undecided() {
    local t f
    for t in $IDS; do
        f=$(ls .tasks/active/"$t"-*.md 2>/dev/null | head -1)
        [ -n "$f" ] || { echo "$t is not active"; return 1; }
        grep -q '^workflow_type: inception' "$f" || { echo "$t is not an inception"; return 1; }
        grep -q '^\*\*Decision\*\*: \(GO\|NO-GO\|DEFER\)' "$f" && { echo "$t already decided"; return 1; }
    done
    return 0
}

clauses_real() {   # the rule fw inception decide enforces for a GO, which fw task review did not catch on T-279
    local t f line
    for t in $GO_IDS; do
        f=$(ls .tasks/active/"$t"-*.md | head -1)
        line=$(grep -m1 '^We will know that we are successful when we see' "$f")
        [ -n "$line" ] || { echo "$t: no success clause"; return 1; }
        case "$line" in *'[NEEDS YOU'*|*'<measurable signal>'*) echo "$t: placeholder success clause"; return 1 ;; esac
    done
    return 0
}

all_ready() {
    local t out
    for t in $IDS; do
        out=$(.agentic-framework/bin/fw task review "$t" 2>&1)
        printf '%s\n' "$out" | grep -q 'Review marker created' || { echo "$t: no review marker"; return 1; }
        printf '%s\n' "$out" | grep -q 'not handoff-ready' && { echo "$t: not handoff-ready"; return 1; }
    done
    return 0
}

commit_decided() {
    local t
    for t in $IDS; do
        git add -A -- .tasks/active/"$t"-*.md .tasks/completed/"$t"-*.md .context/episodic/"$t".yaml 2>/dev/null
    done
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-(279|280|282|1213|498)-|\.context/episodic/T-(279|280|282|1213|498)\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1065: operator's job 067 records the remaining inception decisions (T-279/T-280/T-282 GO per PD-400; T-1213 GO per PD-399; T-498 NO-GO)" && git log --oneline -1
}
