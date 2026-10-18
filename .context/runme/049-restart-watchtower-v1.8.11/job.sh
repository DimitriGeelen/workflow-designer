# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Restart Watchtower on AEF v1.8.11 WITH our local fixes"
JOB_TASK="T-1204"
JOB_WHY="Job 048 upgraded the framework to AEF v1.8.11 without restarting Watchtower. Our local fixes are now
re-applied and committed (36 clean, 2 merged; divergence register OK), so Watchtower can restart on the complete
code. Until it does it keeps serving the previous version (fw doctor: 'Watchtower process predates its own source').
A restart takes Watchtower down for a few seconds; reload any open page afterwards (an unsent form would be lost).
Same port (3013). v1.8.11 no longer touches the firewall by itself (T-4297): if it prints a 'sudo ufw allow'
line, that is advice only; nothing is changed. Nothing is committed or pushed."

PORT=3013

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "framework is v1.8.11" '[ "$(tr -d "[:space:]" < .agentic-framework/VERSION)" = 1.8.11 ]'
    check "Watchtower is running on $PORT" '.agentic-framework/bin/fw watchtower status >/dev/null 2>&1'
    check "the re-applied local fixes are committed" 'git diff --quiet HEAD -- .agentic-framework/web .agentic-framework/lib .agentic-framework/agents'
    check "the inline map page template is present" '[ -f .agentic-framework/web/templates/designer_open.html ]'
}

steps() {
    step "Restart Watchtower on port $PORT, then check it is newer than its web code and answering" 'do_restart'
    step "Check the inline map page answers with the full-width rule, and /cron answers" 'do_check'
}

do_restart() {
    .agentic-framework/bin/fw watchtower restart --port "$PORT" || return 1
    sleep 3
    local pid start newest
    pid=$(tr -d '[:space:]' < .context/working/watchtower.pid)
    start=$(date -d "$(ps -o lstart= -p "$pid")" +%s) || { echo "cannot read the start time of pid $pid"; return 1; }
    newest=$(find .agentic-framework/web -type f -printf '%T@\n' | sort -n | tail -1 | cut -d. -f1)
    [ "$start" -ge "$newest" ] || { echo "Watchtower pid $pid still predates .agentic-framework/web"; return 1; }
    curl -sf --max-time 60 "$(.agentic-framework/bin/fw watchtower url)/" >/dev/null || { echo "Watchtower does not answer /"; return 1; }
    echo "ok  Watchtower restarted (pid $pid), answering at $(.agentic-framework/bin/fw watchtower url)"
}

do_check() {
    local base; base=$(.agentic-framework/bin/fw watchtower url)
    curl -sf --max-time 60 "$base/designer/open?load=%2Fapi%2Fversion%3Fid%3Daudit-process%26v%3D1" | grep -q 'main#content:has(#dsg-stage)' \
        || { echo "the inline map page is missing or lacks the full-width rule"; return 1; }
    echo "ok  $base/designer/open answers with the full-width inline page"
    local t0 t1
    t0=$(date +%s); curl -sf --max-time 60 "$base/cron" >/dev/null || { echo "/cron does not answer within 60 s"; return 1; }
    t1=$(date +%s); echo "ok  $base/cron answers ($((t1 - t0)) s)"
}
