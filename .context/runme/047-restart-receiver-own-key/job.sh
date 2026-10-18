# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Restart the sidecar receiver with 832's own TermLink key (T-1203; job 046's steps 3-4)"
JOB_TASK="T-1203"
JOB_WHY="Job 046 added the settings env block (done, hooks unchanged) and stopped at step 2 on two agent errors, both
now fixed: RAIL_IDENTITY_FILE is stored correctly and fw rail reads state: project. What is left: the sidecar receiver
still runs with the host key. This job restarts it with TERMLINK_IDENTITY_FILE exported, so AEF mail is signed with
832's key; mail arriving in the few seconds it is down falls back to the hub inbox and is not lost. Then the coverage
check: everything must be OK except the running TermLink MCP server, which picks up the key when you restart this
Claude session (exit, then claude-fw)."

ROOT=/opt/832-Workflow-designer
K="$ROOT/.context/secrets/termlink-identity.key"
FP=05c467b46a0bdf5e
OUT="$ROOT/.context/runme/047-restart-receiver-own-key"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the key exists, mode 600, and resolves to $FP without creating anything" '[ -f "$K" ] && [ "$(stat -c %a "$K")" = 600 ] && TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create 2>/dev/null | grep -q "$FP"'
    check "the sidecar receiver is running (it will be restarted)" '.agentic-framework/bin/fw sidecar receiver status 2>/dev/null | grep -q "^receiver running"'
    check "the coverage check exists" '[ -x tools/_t1203-identity-coverage.sh ]'
}

steps() {
    step "Restart the sidecar receiver with TERMLINK_IDENTITY_FILE exported; verify its environment" 'do_receiver'
    step "Run the coverage check (only the running MCP server may still FAIL, until you restart Claude)" 'do_coverage'
}

do_receiver() {
    .agentic-framework/bin/fw sidecar receiver stop || return 1
    TERMLINK_IDENTITY_FILE="$K" .agentic-framework/bin/fw sidecar receiver start --agent 832-Workflow-designer || return 1
    local pid e
    pid=$(.agentic-framework/bin/fw sidecar receiver status 2>/dev/null | sed -n 's/^receiver running: pid=\([0-9]*\).*/\1/p')
    [ -n "$pid" ] || { echo "the receiver is not running after the restart"; return 1; }
    e=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | sed -n 's/^TERMLINK_IDENTITY_FILE=//p')
    [ "$e" = "$K" ] || { echo "receiver pid $pid has TERMLINK_IDENTITY_FILE='$e'"; return 1; }
    echo "ok  receiver pid $pid runs with 832's key"
}

do_coverage() {
    local out
    out=$(bash tools/_t1203-identity-coverage.sh)
    printf '%s\n' "$out" | tee "$OUT/coverage.txt"
    echo
    echo "Expected: FAIL only for 'MCP server pid … (live)', until you restart this Claude session (exit, then claude-fw)."
    ! printf '%s\n' "$out" | grep -E '^  FAIL' | grep -v -E 'MCP server pid [0-9]+ \(live\)|this session \(live\)' | grep -q .
}
