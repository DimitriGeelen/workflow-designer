#!/usr/bin/env bash
# _t936-bare-import-gate-teeth.sh — the bare-import PreToolUse gate refuses what its header says it
# refuses, and nothing a working command needs.
#
# WHY THIS EXISTS (T-1009, 2026-10-04): the gate's header promised it catches `import` "after
# leading whitespace, `&&`, `;`, `|` or a newline", while the code looked only at the first word of
# line 1 — so `cd x && import re` went through. No test held the promise. The controls matter as
# much as the catches: the framework's own idiom is `python3 - <<'PY'` with `import` lines in the
# heredoc body, and `python3 -c "import x"` — a gate that blocks those gets disabled, which is worse
# than the gap it closes.
#
# Exit 0 = every case as expected, 1 = a case wrong, 2 = gate not found.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="${T936_GATE:-}"
if [ -z "$GATE" ]; then
  for c in "$ROOT/.agentic-framework/agents/context/check-bare-import.sh" "$ROOT/agents/context/check-bare-import.sh"; do
    [ -f "$c" ] && { GATE="$c"; break; }
  done
fi
[ -n "$GATE" ] && [ -f "$GATE" ] || { echo "CANNOT RUN: check-bare-import.sh not found"; exit 2; }

PASS=0; FAIL=0
run() { # $1 = want (block|allow), $2 = label, $3 = command
  local payload rc got
  payload=$(CMD="$3" python3 -c 'import json,os; print(json.dumps({"tool_name":"Bash","tool_input":{"command":os.environ["CMD"]}}))')
  printf '%s' "$payload" | bash "$GATE" >/dev/null 2>&1; rc=$?
  got=allow; [ "$rc" -eq 2 ] && got=block
  if [ "$got" = "$1" ]; then PASS=$((PASS+1)); echo "  PASS  $2 -> $got"
  else FAIL=$((FAIL+1)); echo "  FAIL  $2 -> $got (want $1, rc=$rc)"; fi
}

echo "CATCHES (each one the header promises)"
run block "first word"                         "import re,io"
run block "leading whitespace"                 "   import yaml,glob,sys"
run block "after &&"                           "cd /tmp && import importlib.util"
run block "after ;"                            "echo hi; import re"
run block "after |"                            "echo x | import foo"
run block "after a newline"                    $'echo start\nimport re,io'
run block "after ||"                           "false || import re"
run block "in a subshell"                      "( import re )"

echo "CONTROLS (working commands the gate must leave alone)"
run allow "python heredoc body"                $'python3 - <<\'PY\'\nimport re, io\nprint(1)\nPY'
run allow "unquoted heredoc delimiter"         $'python3 - <<EOF\nimport json\nEOF'
run allow "python3 -c with import"             'python3 -c "import json; print(1)"'
run allow "single-quoted python -c"            "python3 -c 'import sys
print(sys.version)'"
run allow "grep for the word"                  "grep -n 'import re' tools/x.py"
run allow "echo mentioning import"             'echo "use import carefully"'
run allow "absolute path is explicit intent"   "/usr/bin/import -window root /tmp/x.png"
run allow "importlib as an argument"           "python3 -m importlib"
run allow "unrelated command"                  "ls -la"

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
