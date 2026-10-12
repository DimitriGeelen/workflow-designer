# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Close T-1127 (element details view) and restart Watchtower on its current code"
JOB_TASK="T-1127"
JOB_WHY="Your answers today, W1 = A and W3 = A. (1) Close T-1127, the element details view: all 8 criteria met,
test 7/7 in the bridge suite, screenshots read, shipped in 0.18.0 and confirmed by Greenfield's re-test. It is owned by
you, so only you can close it. (2) Restart Watchtower: the running process dates from 2026-10-08 22:40 and 267 of its
web files changed since (framework 1.8.8 and 1.8.9, our re-applied local fixes, the T-1123 readiness fix), so the pages
you see are the 8-October framework. A restart takes it down for a few seconds — reload any open page afterwards; an
unsent form on it would be lost. Same port (3013). The designer page is unaffected (read from file on each request)."

T=T-1127
PORT=3013

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "$T is active, owned by you, every Agent criterion ticked" 'f=$(ls .tasks/active/$T-*.md) && grep -q "^owner: human" "$f" && ! sed -n "/^### Agent/,/^### Human/p" "$f" | grep -q "^- \[ \]"'
    check "$T verification passes now (details view test 7/7)" 'node tools/_t1127-element-details-cdp.mjs >/dev/null 2>&1'
    check "Watchtower is running on $PORT" '.agentic-framework/bin/fw watchtower status >/dev/null 2>&1'
}

steps() {
    step "Close $T: fw task update $T --status work-completed (runs its verification)" 'do_close'
    step "Commit the closure" 'do_commit'
    step "Restart Watchtower on port $PORT, then check it is current and answering" 'do_restart'
}

do_close() {
    .agentic-framework/bin/fw task update "$T" --status work-completed || return 1
    ls .tasks/completed/$T-*.md >/dev/null 2>&1 || { echo "$T did not move to completed/"; return 1; }
    echo "ok  $T closed"
}

do_commit() {
    git add -A .tasks/active/$T-* .tasks/completed/$T-* .context/episodic/$T.yaml 2>/dev/null
    git commit -q -m "$T: closed by the operator — element details view (W1, 2026-10-12)" || return 1
    echo "ok  closure committed $(git rev-parse --short HEAD)"
}

do_restart() {
    .agentic-framework/bin/fw watchtower restart --port "$PORT" || return 1
    sleep 3
    # NOT 'fw watchtower current': it looks in <project>/web, which a vendored project does not have, so it always
    # answers "current" (found 2026-10-12, reported to AEF). Compare the new process's start with the vendored web/.
    local pid start newest
    pid=$(tr -d '[:space:]' < .context/working/watchtower.pid)
    start=$(date -d "$(ps -o lstart= -p "$pid")" +%s) || { echo "cannot read the start time of pid $pid"; return 1; }
    newest=$(find .agentic-framework/web -type f -printf '%T@\n' | sort -n | tail -1 | cut -d. -f1)
    [ "$start" -ge "$newest" ] || { echo "Watchtower pid $pid still predates .agentic-framework/web"; return 1; }
    curl -sf "$(.agentic-framework/bin/fw watchtower url)/" >/dev/null || { echo "Watchtower does not answer"; return 1; }
    echo "ok  Watchtower restarted (pid $pid), newer than its web code, answering at $(.agentic-framework/bin/fw watchtower url)"
}
