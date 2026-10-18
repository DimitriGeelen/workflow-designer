#!/bin/bash
# T-1203 (T-1151 GO) — does every 832 entry point that runs termlink sign with 832's own key?
#
# WHAT IT DEFENDS. 832 used to sign with the host key that ~126 co-resident sessions share, so nothing it posted was
# attributable. The fix is TERMLINK_IDENTITY_FILE at every entry point. The failure mode is PARTIAL coverage: one
# process that misses the variable silently signs as the host again, and attribution splits by code path (the
# T-2904 finding AEF made on its own host). So this checks each entry point separately, and never reports a pass
# for an entry point it could not look at.
#
# Per entry point: OK | FAIL <why> | NOT RUNNING (a process that is not up right now: its config is checked, its
# live environment cannot be). Exit 1 on any FAIL. Read-only: it never creates a key (`--no-create` everywhere,
# and the variable is only ever pointed at a file this script has just seen exist).

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "CANNOT RUN: cannot cd to $ROOT"; exit 2; }
K="$ROOT/.context/secrets/termlink-identity.key"
FPF="$ROOT/.context/termlink-identity.fingerprint"
FAIL=0; OKS=0
ok()   { OKS=$((OKS+1)); printf '  OK           %-28s %s\n' "$1" "$2"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL         %-28s %s\n' "$1" "$2"; }
down() { printf '  NOT RUNNING  %-28s %s\n' "$1" "$2"; }

[ -f "$FPF" ] || { echo "CANNOT RUN: no recorded fingerprint at $FPF"; exit 2; }
FP=$(awk '/Fingerprint/{print $2}' "$FPF")
[ -n "$FP" ] || { echo "CANNOT RUN: $FPF names no fingerprint"; exit 2; }
command -v termlink >/dev/null || { echo "CANNOT RUN: termlink not installed"; exit 2; }
HOST_FP=$(env -u TERMLINK_IDENTITY_FILE -u TERMLINK_AGENT_ID -u TERMLINK_IDENTITY_DIR \
    termlink identity show --resolve --no-create 2>/dev/null | awk '/Fingerprint/{print $2}')

echo "=== T-1203 identity coverage: every entry point must sign as $FP (host key: ${HOST_FP:-?}) ==="

# 0. the key itself
if [ -f "$K" ] && [ "$(stat -c %a "$K")" = 600 ] && ! getfacl -p "$K" 2>/dev/null | grep -qE '^(user|group):[^:]'; then
    got=$(TERMLINK_IDENTITY_FILE="$K" termlink identity show --resolve --no-create 2>/dev/null | awk '/Fingerprint/{print $2}')
    [ "$got" = "$FP" ] && ok "key file" "mode 600, no extended ACL, resolves to $FP" || bad "key file" "resolves to '${got:-nothing}', expected $FP"
else
    bad "key file" "missing, not mode 600, or carries an extended ACL: $K"
fi
git ls-files --error-unmatch "$K" >/dev/null 2>&1 && bad "key file in git" "the key is TRACKED"

# 1. Claude sessions: .claude/settings.json env (config) + this process, when run from a session
v=$(python3 -c "import json;print((json.load(open('.claude/settings.json')).get('env') or {}).get('TERMLINK_IDENTITY_FILE',''))" 2>/dev/null)
[ "$v" = "$K" ] && ok "sessions (settings env)" "TERMLINK_IDENTITY_FILE set" || bad "sessions (settings env)" "TERMLINK_IDENTITY_FILE is '${v:-unset}' in .claude/settings.json"
if [ -n "${CLAUDECODE:-}" ]; then
    got=$(termlink identity show --resolve --no-create 2>/dev/null | awk '/Fingerprint/{print $2}')
    [ "$got" = "$FP" ] && ok "this session (live)" "signs as $FP" || bad "this session (live)" "signs as ${got:-?} (a session started before the switch keeps the old env: restart it)"
else
    down "this session (live)" "not run from a Claude session"
fi

# 2. TermLink MCP server: .mcp.json env (config) + live processes rooted here
v=$(python3 -c "import json;print(((json.load(open('.mcp.json'))['mcpServers'].get('termlink') or {}).get('env') or {}).get('TERMLINK_IDENTITY_FILE',''))" 2>/dev/null)
[ "$v" = "$K" ] && ok "MCP server (.mcp.json)" "TERMLINK_IDENTITY_FILE set" || bad "MCP server (.mcp.json)" "TERMLINK_IDENTITY_FILE is '${v:-unset}'"
n=0
for p in $(pgrep -f 'termlink mcp serve' 2>/dev/null); do
    [ "$(readlink "/proc/$p/cwd" 2>/dev/null)" = "$ROOT" ] || continue
    n=$((n+1))
    e=$(tr '\0' '\n' < "/proc/$p/environ" 2>/dev/null | sed -n 's/^TERMLINK_IDENTITY_FILE=//p')
    [ "$e" = "$K" ] && ok "MCP server pid $p (live)" "env set" || bad "MCP server pid $p (live)" "env is '${e:-unset}' (started before the switch: restart the session)"
done
[ "$n" = 0 ] && down "MCP server (live)" "no termlink MCP server rooted at $ROOT"

# 3. sidecar receiver daemon
pid=$(.agentic-framework/bin/fw sidecar receiver status 2>/dev/null | sed -n 's/^receiver running: pid=\([0-9]*\).*/\1/p')
if [ -n "$pid" ]; then
    e=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | sed -n 's/^TERMLINK_IDENTITY_FILE=//p')
    [ "$e" = "$K" ] && ok "sidecar receiver pid $pid" "env set" || bad "sidecar receiver pid $pid" "env is '${e:-unset}' (restart it with the variable exported)"
else
    down "sidecar receiver" "not running"
fi

# 4. runme launcher signal (runs in the operator's terminal, chooses the key itself)
k=$(bash -c '. tools/runme-signal.sh; printf %s "$RUNME_SIGNAL_KEY"' 2>/dev/null)
[ "$k" = "$K" ] && ok "runme signal" "posts with TERMLINK_IDENTITY_FILE=$K (skips the post if the key is missing)" || bad "runme signal" "key path is '${k:-?}'"

# 5. fw rail (framework setting)
st=$(.agentic-framework/bin/fw rail status 2>/dev/null | awk '/state:/{print $2}')
[ "$st" = project ] && ok "fw rail" "state: project" || bad "fw rail" "state: ${st:-?} (set RAIL_IDENTITY_FILE)"

# Dispatched workers inherit the dispatching session's env (covered by 1); cron posts nothing (T-1203 map).
echo
echo "OK $OKS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
