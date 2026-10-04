#!/usr/bin/env bash
# _t1047-session-start-alerts-gate.sh — does the no-task gate admit /resume's mail check, and ONLY it?
#
# T-1046 shipped scripts/session-start-alerts.sh for the /resume skill's step 7 and tested it by
# running it directly — never through check-active-task.sh — so it missed that the gate BLOCKED it
# with no focused task, which is exactly when /resume runs. This drives the real predicates in the
# order check-active-task.sh:321-324 applies them (a write pattern first, then is_bash_safe_command).
#
# Each ADMIT case is also run against HEAD~'s pre-T-1047 safe-commands.sh (passed as $1, or taken
# from the commit before the arm landed) and must be BLOCKED there: the arm is what changed the
# verdict, not something else. BLOCK cases are the controls: a same-named script elsewhere, another
# script under scripts/, a redirect, and `bash -n` (the arm it shares must keep working).
# Exit 0 = all pass.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
LIB="$ROOT/.agentic-framework/agents/context/lib/safe-commands.sh"
BEFORE_REF="${1:-}"
pass=0; fail=0

verdict() {  # $1 = lib path, $2 = command → prints ADMIT or BLOCK, as the gate decides with no task
    PROJECT_ROOT="$ROOT" bash -c '
        source "$1" >/dev/null 2>&1 || { echo LIBFAIL; exit; }
        if has_bash_write_pattern "$2"; then echo BLOCK
        elif is_bash_safe_command "$2"; then echo ADMIT
        else echo BLOCK; fi' _ "$1" "$2"
}

check() {  # $1 = expected, $2 = command, $3 = lib (default: live)
    local got; got=$(verdict "${3:-$LIB}" "$2")
    if [ "$got" = "$1" ]; then pass=$((pass+1)); echo "PASS  $1  $2${3:+  [pre-fix lib]}"
    else fail=$((fail+1)); echo "FAIL  want $1 got $got  $2${3:+  [pre-fix lib]}"; fi
}

ADMIT=(
  "bash scripts/session-start-alerts.sh --limit 10"
  "bash scripts/session-start-alerts.sh --mark-seen"
  "scripts/session-start-alerts.sh"
  "./scripts/session-start-alerts.sh --limit 5"
  "bash $ROOT/scripts/session-start-alerts.sh --limit 10"
  "[ -x scripts/session-start-alerts.sh ] && bash scripts/session-start-alerts.sh --limit 10"
  "timeout 300 bash scripts/session-start-alerts.sh --limit 5"
)
BLOCK=(
  "bash /tmp/x/scripts/session-start-alerts.sh"
  "/tmp/x/scripts/session-start-alerts.sh"
  "bash scripts/other.sh"
  "bash scripts/session-start-alerts.sh > /tmp/out"
  "bash ../other/scripts/session-start-alerts.sh"
)

for c in "${ADMIT[@]}"; do check ADMIT "$c"; done
for c in "${BLOCK[@]}"; do check BLOCK "$c"; done
check ADMIT "bash -n tools/runme-watch.sh"

# The arm is what changed the verdict: every ADMIT case is BLOCKED by the pre-fix library.
if [ -z "$BEFORE_REF" ]; then
    BEFORE_REF=$(git -C "$ROOT" log --format=%H -n1 -S'_fw_is_session_start_alerts' -- \
        .agentic-framework/agents/context/lib/safe-commands.sh 2>/dev/null)
    [ -n "$BEFORE_REF" ] && BEFORE_REF="$BEFORE_REF~1" || BEFORE_REF=HEAD   # uncommitted: HEAD is pre-fix
fi
PRE=$(mktemp); trap 'rm -f "$PRE"' EXIT
if git -C "$ROOT" show "$BEFORE_REF:.agentic-framework/agents/context/lib/safe-commands.sh" > "$PRE" 2>/dev/null \
   && ! grep -q '_fw_is_session_start_alerts' "$PRE"; then
    for c in "${ADMIT[@]}"; do check BLOCK "$c" "$PRE"; done
else
    fail=$((fail+1)); echo "FAIL  cannot obtain a pre-fix safe-commands.sh at $BEFORE_REF"
fi

# End to end: the REAL hook, in a throwaway initialized project whose focus is null (the state
# /resume starts in). Needs .framework.yaml and a focus file, or the hook bootstraps open and
# admits everything (found by this leg's control passing on the first attempt).
E2E=$(mktemp -d); trap 'rm -f "$PRE"; rm -rf "$E2E"' EXIT
mkdir -p "$E2E/.context/working" "$E2E/.tasks/active"
cp "$ROOT/.framework.yaml" "$E2E/"
printf 'current_task: null\n' > "$E2E/.context/working/focus.yaml"
ln -s "$ROOT/.agentic-framework" "$E2E/.agentic-framework"
hook() {  # $1 = expected rc (0 admit, 2 block), $2 = command
    local rc
    python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$2" \
        | (cd "$E2E" && PROJECT_ROOT="$E2E" CLAUDE_PROJECT_DIR="$E2E" \
           bash "$ROOT/.agentic-framework/agents/context/check-active-task.sh" >/dev/null 2>&1)
    rc=$?
    if [ "$rc" = "$1" ]; then pass=$((pass+1)); echo "PASS  hook rc=$rc  $2"
    else fail=$((fail+1)); echo "FAIL  hook want rc=$1 got rc=$rc  $2"; fi
}
hook 0 "bash scripts/session-start-alerts.sh --limit 10"
hook 0 "bash scripts/session-start-alerts.sh --mark-seen"
hook 2 "bash scripts/other.sh"
hook 2 "bash scripts/session-start-alerts.sh > /tmp/o"

echo; echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
