# Operator job for tools/runme-launcher.sh (T-1057). DEFINITIONS ONLY.
JOB_TITLE="Refresh the hook-tamper baseline to today's reviewed .claude/settings.json"
JOB_TASK="T-1057"
JOB_WHY="fw doctor FAILs 'Enforcement baseline CHANGED'. The baseline (set by you on 2026-09-26, T-857)
guards the hooks against tampering, so only you refresh it. Every hook change since then is accounted for:
  T-1022  you enabled the bare-import gate (2026-10-04)
  T-1013  you restored the two project hooks the 1.7.740 rewrite dropped (2026-10-04)
  T-1049  the 1.8.2 upgrade added the sidecar hooks (reviewed, d698db49)
  T-1057  the 1.8.3 upgrade added check-paid-backend, check-worktree-governance-write, stop-driver (2dee46ba)
Step 1 prints the current hook list for you to look at; step 2 records it as the new baseline."

preflight() {
    check ".claude/settings.json is committed as reviewed (no uncommitted edits)" 'git diff --quiet -- .claude/settings.json'
    check "fw doctor currently reports the baseline CHANGED" '.agentic-framework/bin/fw doctor 2>&1 | grep -q "Enforcement baseline CHANGED"'
}

steps() {
    step "Show the hooks the baseline will record" '.agentic-framework/bin/fw enforcement status'
    step "Record them as the new enforcement baseline, and commit it" 'do_refresh'
}

do_refresh() {
    .agentic-framework/bin/fw enforcement baseline || return 1
    ! .agentic-framework/bin/fw doctor 2>&1 | grep -q "Enforcement baseline CHANGED" || { echo "doctor still reports CHANGED"; return 1; }
    git add .context/project/enforcement-baseline.sha256 && \
        git commit -q -m "T-1057: operator refreshed the enforcement baseline after reviewing the hooks (T-1022, T-1013, T-1049, T-1057 changes)"
}
