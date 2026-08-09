#!/bin/bash
# T-404 end-to-end: drive the REAL PreToolUse hook in the REAL null-focus state.
#
# The corpus in .agentic-framework/web/test_safe_commands.py pins the predicate.
# This pins the GATE — the thing that actually blocks work — because the
# predicate is only half the story: has_bash_write_pattern runs before the
# allowlist (check-active-task.sh:92) and its verdict overrides it, so a
# predicate-level pass does not by itself prove a command gets through.
#
# Both directions are asserted on purpose. A "fix" that made the gate allow
# everything would satisfy the first three checks; the last two are what
# distinguish repaired from removed.
#
# Focus is nulled here — that is the state compaction creates, and the only
# state in which this defect changes an outcome. The original file is snapshotted
# and restored via an EXIT trap, so an abort mid-run does not leave focus broken.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/.agentic-framework/agents/context/check-active-task.sh"
FOCUS="$ROOT/.context/working/focus.yaml"

[ -f "$HOOK" ]  || { echo "FAIL: hook not found: $HOOK"; exit 1; }
[ -f "$FOCUS" ] || { echo "FAIL: focus not found: $FOCUS"; exit 1; }

BAK="$(mktemp)"
cp "$FOCUS" "$BAK"
restore() { cp "$BAK" "$FOCUS"; rm -f "$BAK"; }
trap restore EXIT INT TERM

python3 - "$FOCUS" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
s = re.sub(r'^current_task:.*$', 'current_task: null', s, flags=re.M)
open(p, 'w').write(s)
PY

# Confirm we actually reached the state under test. Without this the whole run
# could pass vacuously against a still-focused gate.
grep -q '^current_task: null' "$FOCUS" || { echo "FAIL: could not null focus"; exit 1; }

run() {
    local payload
    payload=$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1")
    if printf '%s' "$payload" | bash "$HOOK" >/dev/null 2>&1; then echo ALLOW; else echo BLOCK; fi
}

fail=0
check() {
    local got
    got=$(run "$2")
    if [ "$got" = "$3" ]; then
        printf 'ok    %-34s %s\n' "$1" "$got"
    else
        printf 'FAIL  %-34s expected %s, got %s\n' "$1" "$3" "$got"
        fail=1
    fi
}

echo "--- null focus: read-only commands must pass ---"
check "stderr-suppressed read"   'cat .context/working/.budget-status 2>/dev/null'  ALLOW
check "quoted redirect operator" 'grep -n "modify\|>>\|target" script.sh'           ALLOW
check "redirect to discard sink" 'echo hi > /dev/null'                              ALLOW
# NB: the command here must be read-only on its OWN merits as well. `make 2>&1`
# is correctly BLOCKED — not by the redirect predicate (the corpus proves 2>&1 is
# not a write) but by the allowlist, because make builds things. Testing fd
# duplication needs a command that is genuinely a read.
check "fd duplication"           'git status --short 2>&1'                          ALLOW

echo "--- null focus: the /resume skill's own Step 5 command (T-404 + T-405) ---"
# The whole point of both tasks. Compaction nulls focus; this is the command the
# framework's documented recovery procedure runs first. It was blocked by two
# independent defects — redirect mis-classification (T-404) and base-command
# extraction (T-405) — so the recovery path was unrunnable in the exact state
# compaction creates.
check "resume Step 5 command"    'WURL=$(cat .context/working/watchtower.url 2>/dev/null || echo "http://localhost:3000"); curl -sf "$WURL/" > /dev/null && echo running'  ALLOW
check "env-prefix contract"      'FW_SWITCH_FOCUS=1 bin/fw work-on T-123'           ALLOW
check "multi-line read"          'grep foo bar
cat baz'                                                                            ALLOW

echo "--- null focus: genuine writes must STILL be blocked ---"
check "multi-line, unsafe line"  'grep foo bar
make install'                                                                       BLOCK
check "compound hiding a delete" 'cd /tmp && rm -rf scratch'                        BLOCK
check "write to source file"     'echo pwned > src/app.js'                          BLOCK
check "append to source file"    'echo pwned >> src/app.js'                         BLOCK
check "in-place sed on source"   'sed -i "s/a/b/" src/app.js'                       BLOCK
check "tee to source file"       'echo x | tee src/app.js'                          BLOCK

if [ "$fail" -eq 0 ]; then
    echo "PASS: gate repaired, not removed"
else
    echo "FAIL: see above"
fi
exit "$fail"
