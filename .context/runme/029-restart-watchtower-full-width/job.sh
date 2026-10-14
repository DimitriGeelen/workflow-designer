# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Restart Watchtower: the inline designer page uses the full window width (T-1175)"
JOB_TASK="T-1175"
JOB_WHY="Your feedback 2026-10-14 'use the full width when available': the page that shows a map inline in Watchtower now
spans the window (13px from each edge) instead of Watchtower's centred column; checked at 1024/1280/1440/1920 and
judged green by an independent reviewer. The running Watchtower serves the old page until it restarts.
Note: the designer's toolbar fix (nothing cut off) is in the designer itself and reaches Watchtower with release 0.20.0;
until then the inline view still shows 0.19.1's toolbar. A restart takes Watchtower down for a few seconds: reload any
open page afterwards; an unsent form would be lost. Same port (3013)."

PORT=3013

preflight() {
    check "Watchtower is running on $PORT" '.agentic-framework/bin/fw watchtower status >/dev/null 2>&1'
    check "the running Watchtower predates its web code (a restart has something to do)" 'p=$(tr -d "[:space:]" < .context/working/watchtower.pid); s=$(date -d "$(ps -o lstart= -p "$p")" +%s); n=$(find .agentic-framework/web -type f -printf "%T@\n" | sort -n | tail -1 | cut -d. -f1); [ "$s" -lt "$n" ]'
    check "the full-width page is committed" 'git diff --quiet HEAD -- .agentic-framework/web/templates/designer_open.html'
}

steps() {
    step "Restart Watchtower on port $PORT, then check it is newer than its web code and answering" 'do_restart'
    step "Check the live inline page carries the full-width rule" 'do_check'
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
    echo "ok  Watchtower restarted (pid $pid), answering at $(.agentic-framework/bin/fw watchtower url)"
}

do_check() {
    local base; base=$(.agentic-framework/bin/fw watchtower url)
    curl -sf "$base/designer/open?load=%2Fapi%2Fversion%3Fid%3Daudit-process%26v%3D1" | grep -q 'main#content:has(#dsg-stage)' \
        || { echo "the inline page has no full-width rule"; return 1; }
    echo "ok  open $base/designer and open a map: it spans the window"
}
