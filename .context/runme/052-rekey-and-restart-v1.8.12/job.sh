# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="After v1.8.12: put the sidecar back on 832's TermLink key, then restart Watchtower on the new code"
JOB_TASK="T-1208"
JOB_WHY="Job 051 upgraded the framework to v1.8.12 (done, rc=0); the agent has re-applied 832's 37 local fixes (all
clean, tests green, committed). Two things are left, both yours:
1. During the upgrade, at 13:32 UTC, the sidecar receiver, supervisor and watcher were restarted WITHOUT 832's key,
   although the launcher exported it (who restarts them is not yet found; AEF T-4311, in their next regular release,
   makes the sidecar read the key from project config and ends this class). The session-start check caught it.
   Step 1 restarts the stack from this launcher, which does carry the key, and verifies all three.
2. Watchtower still runs the pre-upgrade code. Step 2 restarts it on port 3013 (a few seconds down; reload any open
   page). Step 3 checks the inline map page and /cron answer.
Mail arriving while the receiver is down falls back to the hub inbox and is not lost. Nothing is committed or pushed."

ROOT=/opt/832-Workflow-designer
K="$ROOT/.context/secrets/termlink-identity.key"
FP=05c467b46a0bdf5e
PORT=3013

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "framework is v1.8.12" '[ "$(tr -d "[:space:]" < .agentic-framework/VERSION)" = 1.8.12 ]'
    check "the re-applied local fixes are committed" 'git diff --quiet HEAD -- .agentic-framework/web .agentic-framework/lib .agentic-framework/agents'
    check "the key exists, mode 600, and resolves to $FP without creating anything" '[ -f "$K" ] && [ "$(stat -c %a "$K")" = 600 ] && TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create 2>/dev/null | grep -q "$FP"'
    check "this launcher exports the key to job steps (T-1204)" '[ "${TERMLINK_IDENTITY_FILE:-}" = "$K" ]'
    check "Watchtower is running on $PORT" '.agentic-framework/bin/fw watchtower status >/dev/null 2>&1'
}

steps() {
    step "Restart the sidecar stack with 832's key; verify receiver, supervisor and watcher all carry it" 'do_rekey'
    step "Restart Watchtower on port $PORT, then check it is newer than its web code and answering" 'do_restart'
    step "Check the inline map page and /cron answer, and the identity coverage has no FAIL" 'do_check'
}

env_key() { tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null | sed -n 's/^TERMLINK_IDENTITY_FILE=//p'; }

do_rekey() {
    .agentic-framework/bin/fw sidecar receiver stop || return 1
    .agentic-framework/bin/fw sidecar receiver start --agent 832-Workflow-designer || return 1
    sleep 3
    local pid sup wat bad=0
    pid=$(.agentic-framework/bin/fw sidecar receiver status 2>/dev/null | sed -n 's/^receiver running: pid=\([0-9]*\).*/\1/p')
    sup=$(cat .context/sidecar/watcher/supervisor.pid 2>/dev/null)
    wat=$(cat .context/sidecar/watcher/watcher.pid 2>/dev/null)
    for p in "receiver:$pid" "supervisor:$sup" "watcher:$wat"; do
        local n=${p%%:*} i=${p#*:}
        if [ -z "$i" ] || [ ! -d "/proc/$i" ]; then echo "FAIL  $n is not running"; bad=1; continue; fi
        if [ "$(env_key "$i")" = "$K" ]; then echo "ok    $n pid $i runs with 832's key"; else echo "FAIL  $n pid $i has TERMLINK_IDENTITY_FILE='$(env_key "$i")'"; bad=1; fi
    done
    return $bad
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
    curl -sf --max-time 60 "$base/cron" >/dev/null || { echo "/cron does not answer within 60 s"; return 1; }
    echo "ok  $base/cron answers"
    local out; out=$(bash tools/_t1203-identity-coverage.sh)
    printf '%s\n' "$out" | tail -12
    ! printf '%s\n' "$out" | grep -E '^  FAIL' | grep -v -E 'this session \(live\)|MCP server pid [0-9]+ \(live\)' | grep -q .
}
