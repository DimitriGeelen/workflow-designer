# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Restart Watchtower so it serves our local web fixes (re-applied after the 1146a7450 upgrade)"
JOB_TASK="T-1169"
JOB_WHY="Job 024 restarted Watchtower at 20:24:50, but our local framework fixes were re-applied after it, at 20:25:32
(commit c2badf60), including six in .agentic-framework/web (T-568 card cache, T-606 rendered AC headlines, T-547,
T-545, T-569, T-772). So the running dashboard is AEF's code without them; the bridge suite's T-568 probe caught it
(a card edit does not show on the live dashboard). A restart takes it down for a few seconds: reload any open page
afterwards; an unsent form would be lost. Same port (3013); the designer page is unaffected."

PORT=3013

preflight() {
    check "Watchtower is running on $PORT" '.agentic-framework/bin/fw watchtower status >/dev/null 2>&1'
    check "the running Watchtower predates its web code (a restart has something to do)" 'p=$(tr -d "[:space:]" < .context/working/watchtower.pid); s=$(date -d "$(ps -o lstart= -p "$p")" +%s); n=$(find .agentic-framework/web -type f -printf "%T@\n" | sort -n | tail -1 | cut -d. -f1); [ "$s" -lt "$n" ]'
}

steps() {
    step "Restart Watchtower on port $PORT, then check it is newer than its web code and answering" 'do_restart'
}

do_restart() {
    .agentic-framework/bin/fw watchtower restart --port "$PORT" || return 1
    sleep 3
    local pid start newest
    pid=$(tr -d '[:space:]' < .context/working/watchtower.pid)
    start=$(date -d "$(ps -o lstart= -p "$pid")" +%s) || { echo "cannot read the start time of pid $pid"; return 1; }
    newest=$(find .agentic-framework/web -type f -printf '%T@\n' | sort -n | tail -1 | cut -d. -f1)
    [ "$start" -ge "$newest" ] || { echo "Watchtower pid $pid still predates .agentic-framework/web"; return 1; }
    curl -sf "$(.agentic-framework/bin/fw watchtower url)/" >/dev/null || { echo "Watchtower does not answer"; return 1; }
    echo "ok  Watchtower restarted (pid $pid), newer than its web code, answering at $(.agentic-framework/bin/fw watchtower url)"
}
