# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Record 8 inception decisions you already made (T-1065 triage): 3 DEFER, 4 GO, 1 NO-GO"
JOB_TASK="T-1065"
JOB_WHY="The T-1065 queue triage found eight inceptions whose go/no-go you have ALREADY ruled elsewhere, but the
decision was never recorded on the task, so they still sit in your queue. Recording a decision is Tier 0, so it is
your job. Each is its own step, in this order; answering n stops the job there (the ones before it stay recorded,
nothing after it runs), so if you disagree with one, tell the agent and it writes you a job without it.
  T-184, T-185, T-186  DEFER  your DEFER of 2026-07-11 (recorded in T-175)
  T-279, T-280, T-282  GO     PD-400 (2026-10-19): 'revive and build T-279 ... T-280 ... T-282; callActivity first'
  T-1213               GO     PD-399 (2026-10-19): ownership by risk assessment, independent reviewer at every agent close
  T-498                NO-GO  you withdrew the premise ('oh i was confused', T-498 lines 119-123)
The last step commits the decided tasks, so nothing is left staged for the next job. Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "all eight are active inceptions with no decision recorded yet" 'all_undecided'
    check "the decide gate's own readiness check passes for all eight (fw task review)" 'all_ready'
}

steps() {
    step "T-184: DEFER" 'decide T-184 defer "Operator DEFER 2026-07-11, recorded in T-175 (T-1065 triage)"'
    step "T-185: DEFER" 'decide T-185 defer "Operator DEFER 2026-07-11, recorded in T-175 (T-1065 triage)"'
    step "T-186: DEFER" 'decide T-186 defer "Operator DEFER 2026-07-11, recorded in T-175 (T-1065 triage)"'
    step "T-279: GO (PD-400)" 'decide T-279 go "PD-400 (operator 2026-10-19, T-732): H1 reversed, revive and build T-279/T-280/T-282, callActivity first"'
    step "T-280: GO (PD-400)" 'decide T-280 go "PD-400 (operator 2026-10-19, T-732): H1 reversed, revive and build T-279/T-280/T-282, callActivity first"'
    step "T-282: GO (PD-400)" 'decide T-282 go "PD-400 (operator 2026-10-19, T-732): H1 reversed, revive and build T-279/T-280/T-282, callActivity first"'
    step "T-1213: GO (PD-399)" 'decide T-1213 go "PD-399 (operator 2026-10-19, T-1203): ownership by risk assessment at creation, independent reviewer at every agent close, escalation the only route to the operator"'
    step "T-498: NO-GO (premise withdrawn)" 'decide T-498 no-go "Operator withdrew the premise (T-498 lines 119-123: oh i was confused); T-1065 triage"'
    step "Commit the decided tasks (only their files)" 'commit_decided'
}

IDS="T-184 T-185 T-186 T-279 T-280 T-282 T-1213 T-498"

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
    git diff --cached --name-only | grep -vE '^(\.tasks/(active|completed)/T-(184|185|186|279|280|282|1213|498)-|\.context/episodic/T-(184|185|186|279|280|282|1213|498)\.yaml$)' \
        | while read -r p; do git restore --staged -- "$p"; done
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1065: operator's job 066 records 8 inception decisions already ruled (T-184/185/186 DEFER; T-279/280/282 GO per PD-400; T-1213 GO per PD-399; T-498 NO-GO)" && git log --oneline -1
}
