# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Restart Watchtower on its current code (then close T-1127 on its review page)"
JOB_TASK="T-1139"
JOB_WHY="Your answer W3 = A. The running Watchtower dates from 2026-10-08 22:40; 15 of its web files changed content
since (framework 1.8.8 and 1.8.9, our re-applied local fixes), so the pages you see are the 8-October framework.
'fw watchtower current' cannot tell — it looks in <project>/web, which a vendored project does not have (T-1139) —
so this job checks against .agentic-framework/web itself. A restart takes it down for a few seconds: reload any open
page afterwards; an unsent form would be lost. Same port (3013); the designer page is unaffected.
AFTERWARDS (W1 = A): close T-1127 yourself on http://192.168.10.107:3013/review/T-1127 — a task you own is closed by
you approving it there, not by any command (job 016 stopped on exactly that, nothing changed)."

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
    echo "    next: close T-1127 at $(.agentic-framework/bin/fw watchtower url)/review/T-1127"
}
