# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
JOB_TITLE="Sidecar keeps 832's own TermLink key by itself (SIDECAR_RAIL_IDENTITY=1, AEF T-4311), then restart it on that key"
JOB_TASK="T-1203"
JOB_WHY="Job 059's upgrade restarted the sidecar receiver at 15:25 UTC with a clean environment (no
TERMLINK_IDENTITY_FILE at all), so AEF mail is signed with the shared host key again: the same regression as job 048
(T-1204), and a per-job export cannot prevent it. be.3 brings the structural fix, AEF T-4311: with
SIDECAR_RAIL_IDENTITY=1 the sidecar itself signs with RAIL_IDENTITY_FILE (already set in .framework.yaml to 832's
key), whatever environment it was started from, and keeps reading DMs addressed to the old host key
(SIDECAR_HOST_DM_TRANSITION, default on), so nothing addressed to the old fingerprint is lost. 832 already signs
with this key everywhere else, so this changes no address AEF uses. Step 1 sets the switch and commits it; step 2
restarts the receiver, supervisor and watcher and checks each runs with the key; step 3 is the coverage check.
Mail arriving in the seconds the receiver is down falls back to the hub inbox. Nothing is pushed."

ROOT=/opt/832-Workflow-designer
K="$ROOT/.context/secrets/termlink-identity.key"
FP=05c467b46a0bdf5e
OUT="$ROOT/.context/runme/061-sidecar-own-key-structural"

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
    check "no uncommitted edits to .framework.yaml" 'git diff --quiet -- .framework.yaml'
    check "the key exists, mode 600, and resolves to $FP without creating anything" '[ -f "$K" ] && [ "$(stat -c %a "$K")" = 600 ] && TERMLINK_IDENTITY_NO_CREATE=1 TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create 2>/dev/null | grep -q "$FP"'
    check ".framework.yaml RAIL_IDENTITY_FILE points at that key" 'grep -q "^RAIL_IDENTITY_FILE: \.context/secrets/termlink-identity\.key$" .framework.yaml'
    check "the vendored sidecar has the T-4311 switch (lib/sidecar/identity.py)" 'grep -q "SIDECAR_RAIL_IDENTITY" .agentic-framework/lib/sidecar/identity.py'
    check "this launcher exports the key to job steps (T-1204)" '[ "${TERMLINK_IDENTITY_FILE:-}" = "$K" ]'
    check "the sidecar receiver is running (it will be restarted)" '.agentic-framework/bin/fw sidecar receiver status 2>/dev/null | grep -q "^receiver running"'
}

steps() {
    step "Set SIDECAR_RAIL_IDENTITY=1 (fw config set) and commit .framework.yaml" 'do_switch'
    step "Restart the sidecar receiver (stops the supervisor and watcher first); verify all three carry the key" 'do_restart'
    step "Run the coverage check (only this Claude session may still FAIL, until you restart it through claude-fw)" 'do_coverage'
}

do_switch() {
    .agentic-framework/bin/fw config set SIDECAR_RAIL_IDENTITY 1 || return 1
    [ "$(.agentic-framework/bin/fw config get SIDECAR_RAIL_IDENTITY 2>/dev/null | tail -1)" = 1 ] || { echo "the switch did not read back as 1"; return 1; }
    git add -- .framework.yaml && git commit -q -m "T-1203: SIDECAR_RAIL_IDENTITY=1 — the sidecar signs with RAIL_IDENTITY_FILE itself (AEF T-4311), whatever env it is started from (operator job 061)" && git log --oneline -1
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
    echo "Expected: FAIL only for this Claude session (its registration, or its MCP server), until you restart it through claude-fw."
    ! printf '%s\n' "$out" | grep -E '^  FAIL' | grep -v -E 'MCP server pid [0-9]+ \(live\)|this session \(live\)|session registration' | grep -q .
}
