# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Install the decision-handover guard (Stop hook) and refresh the enforcement baseline"
JOB_TASK="T-1145"
JOB_WHY="Your request after T-1094 (handed to you as ready while Watchtower said 'Not ready'): a check the agent
cannot skip. The new Stop hook reads the agent's reply as it finishes; if the reply names a Watchtower decision link
(/inception/T-XXX or /review/T-XXX) for a task that is not decision-ready, the reply is stopped and the agent must
correct it before you see it. It uses the same readiness check as 'fw task review'. It never blocks when it cannot
read something (it says so instead), and blocks at most once per reply, so it cannot loop.
Only you can register hooks (.claude/settings.json is closed to the agent). Step 1 adds one entry to the existing
Stop group; step 2 records the hook set as the new enforcement baseline (otherwise fw doctor reports CHANGED) and
commits both. Takes effect in new sessions (or after /hooks reload)."

preflight() {
    check ".claude/settings.json has no uncommitted edits" 'git diff --quiet -- .claude/settings.json'
    check "the hook and its installer are committed" 'git ls-files --error-unmatch tools/hooks/guard-decision-handover.py tools/hooks/install-decision-handover-guard.py >/dev/null 2>&1 && git diff --quiet -- tools/hooks/guard-decision-handover.py tools/hooks/install-decision-handover-guard.py'
    check "the hook's test passes (10 legs incl. teeth)" 'python3 tests/test_t1145_decision_handover_guard.py >/dev/null 2>&1'
    check "the installer would add exactly the one entry (dry run)" 'out=$(python3 tools/hooks/install-decision-handover-guard.py --dry-run 2>&1); grep -q "DRY RUN: would append to the Stop group" <<<"$out"'
}

steps() {
    step "Register the guard in .claude/settings.json (Stop group)" 'python3 tools/hooks/install-decision-handover-guard.py'
    step "Record the hook set as the new enforcement baseline, then commit settings + baseline" 'do_baseline'
}

do_baseline() {
    .agentic-framework/bin/fw enforcement baseline || return 1
    local out; out=$(.agentic-framework/bin/fw doctor 2>&1)   # capture first: grep -q on a live pipe SIGPIPEs (L-387)
    ! grep -q "Enforcement baseline CHANGED" <<<"$out" || { echo "doctor still reports CHANGED"; return 1; }
    git add .claude/settings.json .context/project/enforcement-baseline.sha256 && \
        git commit -q -m "T-1145: operator registered the decision-handover guard (Stop hook) and refreshed the enforcement baseline"
}
