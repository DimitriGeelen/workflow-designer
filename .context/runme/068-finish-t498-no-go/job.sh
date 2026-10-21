# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Finish job 067: record T-498's NO-GO again and commit all five decisions"
JOB_TASK="T-1065"
JOB_WHY="Job 067 recorded the four GOs (T-279, T-280, T-282, T-1213), then failed at step 5. The decide for T-498
moved it from captured to started-work, but the file was back at captured a moment later, so the closing update was
refused ('captured -> work-completed'). The likely cause is a framework race: the move to started-work launches a
background scorer that rewrites the task file. T-498's NO-GO text is in the file, but the task is not closed, and
step 6 (the commit) never ran, so the four GOs are staged, not committed. This job starts T-498 first and waits until
its status holds before deciding, so the scorer is done before the decide runs. Then it records the NO-GO (the same
text as 067; a second decide replaces the Decision block) and commits the five tasks. The race goes to AEF.
fw inception sweep is NOT used: it would also force-close T-1219, whose GO is still held by a completion gate.
Nothing is pushed."

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "only job 067's four GO records are staged" 'staged_only_go'
    check "the four GOs are closed in completed/ with GO recorded" 'gos_closed'
    check "T-498 is active, captured, an inception" 't498_open'
    check "T-498's review marker from job 067 is still there (fw task review now says 'already decided')" '[ -f .context/working/.reviewed-T-498 ]'
}

steps() {
    step "Start T-498 and wait until its status holds at started-work" 'start_and_settle'
    step "T-498: NO-GO (premise withdrawn)" 'decide T-498 no-go "Operator withdrew the premise (T-498 lines 119-123: oh i was confused); T-1065 triage"'
    step "Commit the five decided tasks (only their files)" 'commit_decided'
}

decide() { .agentic-framework/bin/fw inception decide "$1" "$2" --rationale "$3"; }

DECIDED_RE='^(\.tasks/(active|completed)/T-(279|280|282|1213|498)-|\.context/episodic/T-(279|280|282|1213|498)\.yaml$)'

staged_only_go() {
    local extra
    extra=$(git diff --cached --name-only | grep -vE "$DECIDED_RE")
    [ -z "$extra" ] || { echo "also staged: $extra"; return 1; }
}

gos_closed() {
    local t f
    for t in T-279 T-280 T-282 T-1213; do
        f=$(ls .tasks/completed/"$t"-*.md 2>/dev/null | head -1)
        [ -n "$f" ] || { echo "$t is not in completed/"; return 1; }
        grep -q '^\*\*Decision\*\*: GO' "$f" || { echo "$t has no GO recorded"; return 1; }
    done
}

t498_open() {
    local f
    f=$(ls .tasks/active/T-498-*.md 2>/dev/null | head -1)
    [ -n "$f" ] || { echo "T-498 is not active"; return 1; }
    grep -q '^workflow_type: inception' "$f" || { echo "T-498 is not an inception"; return 1; }
    grep -q '^status: captured$' "$f" || { echo "T-498 is not captured: $(grep -m1 '^status:' "$f")"; return 1; }
}

t498_status() { grep -m1 '^status:' .tasks/active/T-498-*.md | sed 's/status:[[:space:]]*//'; }

start_and_settle() {   # the same status for 3 checks in a row, 2 s apart, within 30 s
    local i same=0
    .agentic-framework/bin/fw task update T-498 --status started-work --reason "job 068: finish the NO-GO job 067 recorded" || return 1
    for i in $(seq 1 15); do
        sleep 2
        if [ "$(t498_status)" = started-work ]; then same=$((same+1)); else same=0; fi
        [ "$same" -ge 3 ] && { echo "T-498 holds at started-work"; return 0; }
    done
    echo "T-498 did not hold at started-work (now: $(t498_status)); stopping before the decide"
    return 1
}

commit_decided() {
    local p
    for p in ':(glob).tasks/active/T-498-*.md' ':(glob).tasks/completed/T-498-*.md' .context/episodic/T-498.yaml; do
        git add -A -- "$p" 2>/dev/null || true   # each alone: one unmatched pathspec must not drop the others
    done
    git diff --cached --name-only | grep -vE "$DECIDED_RE" \
        | while read -r p; do git restore --staged -- "$p"; done
    git diff --cached --name-only
    if git diff --cached --quiet; then echo "nothing to commit"; return 0; fi
    FW_SWITCH_FOCUS=1 .agentic-framework/bin/fw git commit -m "T-1065: operator's jobs 067 and 068 record the remaining inception decisions (T-279/T-280/T-282 GO per PD-400; T-1213 GO per PD-399; T-498 NO-GO)" && git log --oneline -1
}
