# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Install 832's regenerated crontab into /etc/cron.d (be.3's fw cron generate moved one job's minute)"
JOB_TASK="T-1226"
JOB_WHY="After the be.3 upgrade the pre-push audit reported cron drift. fw cron generate (agent, committed as part of
the push) rewrote .context/cron/agentic-audit.crontab with exactly one change: the hourly index-reindex job runs at
minute 39 instead of 20. The deployed copy in /etc/cron.d still has 20, so the audit keeps flagging it. /etc is
outside the project, so this is yours: fw cron install replaces the deployed file atomically with the generated one.
The preflight checks that the only difference is that one line; nothing else in the schedule changes."

GEN=.context/cron/agentic-audit.crontab
DEP=/etc/cron.d/agentic-audit-832-workflow-designer

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the generated crontab is committed as-is" 'git diff --quiet -- "$GEN"'
    check "the deployed crontab exists" '[ -f "$DEP" ]'
    check "the only difference is the index-reindex minute (20 -> 39), one line each way" 'only_minute_differs'
}

steps() {
    step "Install the generated crontab (fw cron install)" '.agentic-framework/bin/fw cron install'
    step "Check: the deployed file now equals the generated one" 'cmp -s <(grep -v "^#" "$GEN") <(grep -v "^#" "$DEP") && echo "deployed == generated"'
}

only_minute_differs() {
    local d
    d=$(diff <(grep -v '^#' "$GEN") <(grep -v '^#' "$DEP") | grep '^[<>]')
    [ "$(printf '%s\n' "$d" | grep -c .)" = 2 ] || return 1
    printf '%s\n' "$d" | grep -q '^< 39 \* \* \* \* .*index-reindex-hourly' || return 1
    printf '%s\n' "$d" | grep -q '^> 20 \* \* \* \* .*index-reindex-hourly'
}
