# Operator job for tools/runme-launcher.sh. DEFINITIONS ONLY: the launcher refuses a job that runs
# anything when loaded. Steps run from the project root, each after the operator's y/N.
JOB_TITLE="Switch 832 to its own TermLink key (T-1203): sessions env, fw rail setting, sidecar receiver restart"
JOB_TASK="T-1203"
JOB_WHY="Your T-1151 GO, the rollout (AEF: 'set it yourselves for now'; their upstream change is AEF T-4311). The key
05c467b46a0bdf5e exists and is backed up. Three steps the agent may not do itself:
 1. .claude/settings.json gains an 'env' block with TERMLINK_IDENTITY_FILE. The file is protected (B-005) because it
    registers the enforcement hooks; the step adds ONLY 'env' and proves the hooks are byte-identical (the
    enforcement baseline hashes the hooks block, and fw doctor must still say 'intact').
 2. fw config set RAIL_IDENTITY_FILE to the same key, so 'fw rail' signs with it.
 3. The sidecar receiver is restarted with the variable exported, so AEF mail is signed with 832's key. Mail that
    arrives during the few seconds it is down falls back to the hub inbox and is not lost.
Afterwards: restart this Claude session (exit, then claude-fw) so sessions and the TermLink MCP server pick up the
key; the agent then runs tools/_t1203-identity-coverage.sh, which must show no FAIL. Rollback is one step each:
remove the env block, unset the setting, restart the receiver without the variable."

ROOT=/opt/832-Workflow-designer
K="$ROOT/.context/secrets/termlink-identity.key"
FP=05c467b46a0bdf5e
S="$ROOT/.claude/settings.json"
OUT="$ROOT/.context/runme/046-switch-832-termlink-identity"

# Read fw doctor's whole output before matching: `doctor | grep -q` exits at the first match, SIGPIPEs doctor, and
# under pipefail reads as a failure (the dry-run hit exactly that).
baseline_intact() {
    local out; out=$(.agentic-framework/bin/fw doctor 2>&1)
    printf '%s\n' "$out" | grep -q "Enforcement baseline intact"
}

hooks_hash() {
    python3 -c "import json,hashlib,sys;print(hashlib.sha256(json.dumps(json.load(open(sys.argv[1])).get('hooks',{}),sort_keys=True).encode()).hexdigest())" "$1"
}

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the key exists, mode 600, and resolves to $FP without creating anything" '[ -f "$K" ] && [ "$(stat -c %a "$K")" = 600 ] && TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create 2>/dev/null | grep -q "$FP"'
    check ".claude/settings.json has no env block yet" '! python3 -c "import json,sys;sys.exit(0 if \"env\" in json.load(open(\"$S\")) else 1)"'
    check ".claude/settings.json is committed (a clean starting point to diff against)" 'git diff --quiet HEAD -- "$S"'
    check "fw doctor: enforcement baseline intact before the change" 'baseline_intact'
    check "the sidecar receiver is running (it will be restarted)" '.agentic-framework/bin/fw sidecar receiver status 2>/dev/null | grep -q "^receiver running"'
    check "the coverage check exists" '[ -x tools/_t1203-identity-coverage.sh ]'
}

steps() {
    step "Add ONLY an env block (TERMLINK_IDENTITY_FILE) to .claude/settings.json; prove the hooks are unchanged" 'do_settings'
    step "fw config set RAIL_IDENTITY_FILE $K; fw rail status must read state: project" 'do_rail'
    step "Restart the sidecar receiver with TERMLINK_IDENTITY_FILE exported; verify its environment" 'do_receiver'
    step "Run the coverage check (sessions and the MCP server stay FAIL until you restart this Claude session)" 'do_coverage'
}

do_settings() {
    local before after
    before=$(hooks_hash "$S") || return 1
    python3 - "$S" "$K" <<'PY' || return 1
import json, sys, os
path, key = sys.argv[1], sys.argv[2]
d = json.load(open(path))
if "env" in d:
    sys.exit("settings.json already has an env block; not touching it")
out = {"env": {"TERMLINK_IDENTITY_FILE": key}}
out.update(d)
tmp = path + ".t1203.tmp"
with open(tmp, "w") as f:
    json.dump(out, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
PY
    after=$(hooks_hash "$S") || return 1
    [ "$before" = "$after" ] || { echo "the hooks block changed — restoring"; git checkout -- "$S"; return 1; }
    baseline_intact || { echo "fw doctor no longer says the baseline is intact — restoring"; git checkout -- "$S"; return 1; }
    git diff --stat -- "$S"
    echo "ok  env block added; hooks byte-identical (sha256 $before); enforcement baseline intact"
}

do_rail() {
    .agentic-framework/bin/fw config set RAIL_IDENTITY_FILE "$K" || return 1
    .agentic-framework/bin/fw rail status | tee "$OUT/rail-status.txt"
    grep -q 'state: *project' "$OUT/rail-status.txt" || { echo "fw rail status does not read state: project"; return 1; }
    echo "ok  fw rail signs with the project key"
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
    bash tools/_t1203-identity-coverage.sh | tee "$OUT/coverage.txt"
    echo
    echo "Expected now: FAIL only for 'this session (live)' / 'MCP server pid … (live)' (or NOT RUNNING), until you"
    echo "restart this Claude session (exit, then claude-fw). Everything else must be OK."
    ! grep -E '^  FAIL' "$OUT/coverage.txt" | grep -v -E 'this session \(live\)|MCP server pid [0-9]+ \(live\)' | grep -q .
}
