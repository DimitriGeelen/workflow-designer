# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Restart the sidecar stack on 832's own TermLink key again (job 048's upgrade restarted it without)"
JOB_TASK="T-1204"
JOB_WHY="Job 048's fw upgrade restarted the sidecar receiver, supervisor and watcher at 20:23 UTC from your
terminal, which has no TERMLINK_IDENTITY_FILE, so AEF mail is signed with the shared host key again. The new
session-start check caught it ('TermLink identity: ... sidecar receiver ... env is unset'). The launcher now
exports the key for every job step (only when the key file exists), so this job is a plain stop and start of the
receiver; future upgrade jobs keep the key by themselves. Mail arriving in the few seconds it is down falls back
to the hub inbox and is not lost. Then the coverage check: only the running MCP server may still FAIL, until you
restart Claude (exit, then claude-fw)."

ROOT=/opt/832-Workflow-designer
K="$ROOT/.context/secrets/termlink-identity.key"
FP=05c467b46a0bdf5e
OUT="$ROOT/.context/runme/050-rekey-receiver-after-upgrade"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the key exists, mode 600, and resolves to $FP without creating anything" '[ -f "$K" ] && [ "$(stat -c %a "$K")" = 600 ] && TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create 2>/dev/null | grep -q "$FP"'
    check "this launcher exports the key to job steps (T-1204)" '[ "${TERMLINK_IDENTITY_FILE:-}" = "$K" ]'
    check "the sidecar receiver is running (it will be restarted)" '.agentic-framework/bin/fw sidecar receiver status 2>/dev/null | grep -q "^receiver running"'
}

steps() {
    step "Restart the sidecar receiver (stops the supervisor and watcher first); verify all three carry the key" 'do_restart'
    step "Run the coverage check (only the running MCP server may still FAIL, until you restart Claude)" 'do_coverage'
}

env_key() { tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null | sed -n 's/^TERMLINK_IDENTITY_FILE=//p'; }

do_restart() {
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

do_coverage() {
    local out
    out=$(bash tools/_t1203-identity-coverage.sh)
    printf '%s\n' "$out" | tee "$OUT/coverage.txt"
    echo
    echo "Expected: FAIL only for 'MCP server pid … (live)', until you restart this Claude session (exit, then claude-fw)."
    ! printf '%s\n' "$out" | grep -E '^  FAIL' | grep -v -E 'MCP server pid [0-9]+ \(live\)|this session \(live\)' | grep -q .
}
