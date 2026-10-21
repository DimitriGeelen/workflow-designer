# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Install the regenerated audit crontab (be.2: each job line passes on its real exit code)"
JOB_TASK="T-1245"
JOB_WHY="The be.2 upgrade's fw cron generate adds '; exit \${PIPESTATUS[0]}' to every job line, so cron sees the
audit's own exit code instead of logger's (always 0). The project copy is regenerated and committed; the installed
copy in /etc/cron.d still has the old lines, so the audit reports 'Cron drift: differs from deployed'. The agent
checked that the two differ ONLY by that suffix. fw cron install writes /etc/cron.d atomically, which is outside the
project, so it is your job. Nothing else changes: same 10 jobs, same times."

CRON=/etc/cron.d/agentic-audit-832-workflow-designer
GEN=.context/cron/agentic-audit.crontab

preflight() {
    check "the committed crontab is the generated one" 'git diff --quiet -- "$GEN"'
    check "installed and generated differ only by the exit-code suffix" 'diff <(sed "s/; exit \${PIPESTATUS\[0\]}\$//" "$GEN") "$CRON" >/dev/null'
}

steps() {
    step "Install the generated crontab (fw cron install)" '.agentic-framework/bin/fw cron install'
    step "Check: installed equals generated" 'cmp "$GEN" "$CRON" && echo "installed = generated"'
}
