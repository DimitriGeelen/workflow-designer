# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Restart Watchtower on AEF be.3 with our local fixes, so it serves designer 0.24.0"
JOB_TASK="T-1223"
JOB_WHY="Job 059 upgraded the framework to AEF v1.8.14-be.3 without restarting Watchtower, so the running process
still serves designer 0.23.0 although the vendored 0.24.0 file is in place and matches the pin (fw designer: PRESENT,
sha256 a42f16b3). Our local fixes are re-applied and committed (divergence register OK), and the full bridge run on
this tree is green (308/0). A restart takes Watchtower down for a few seconds; reload any open page afterwards (an
unsent form would be lost). Same port (3013). Nothing is committed or pushed."

PORT=3013
DESIGNER=0.24.0

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "framework is be.3 (version_sha 346c4ed33)" 'grep -q "^version_sha: 346c4ed330ff14afc60d215ea9b117efe94489cc$" .framework.yaml'
    check "Watchtower is running on $PORT" '.agentic-framework/bin/fw watchtower status >/dev/null 2>&1'
    check "the re-applied local fixes are committed" 'git diff --quiet HEAD -- .agentic-framework/web .agentic-framework/lib .agentic-framework/agents'
    check "the vendored designer $DESIGNER is present and matches its pin" '.agentic-framework/bin/fw designer 2>/dev/null | grep -q "PRESENT"'
    check "the inline map page template is present" '[ -f .agentic-framework/web/templates/designer_open.html ]'
}

steps() {
    step "Restart Watchtower on port $PORT, then check it is newer than its web code and answering" 'do_restart'
    step "Check /designer serves $DESIGNER and the inline map page answers" 'do_check'
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
    curl -sf --max-time 60 "$base/designer" | grep -q "$DESIGNER" || { echo "/designer does not serve $DESIGNER"; return 1; }
    echo "ok  $base/designer serves $DESIGNER"
    curl -sf --max-time 60 "$base/designer/open?load=%2Fapi%2Fversion%3Fid%3Daudit-process%26v%3D1" | grep -q 'main#content:has(#dsg-stage)' \
        || { echo "the inline map page is missing or lacks the full-width rule"; return 1; }
    echo "ok  $base/designer/open answers with the full-width inline page"
}
