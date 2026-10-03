#!/usr/bin/env bash
# _t3746-allowlisted-writes-fixture.sh — allowlisted "read-only" verbs that WRITE must not pass the
# no-task gate, and the reads that merely LOOK like writes must still pass. (832 T-1005 → AEF T-3746)
#
# Subject: agents/context/lib/safe-commands.sh, composed exactly as the PreToolUse task gate
# (check-active-task.sh) composes it to let a command run with no active task: ALLOWED iff
# has_bash_write_pattern says no AND is_bash_safe_command says yes.
#
# On 1.7.740 as shipped, grep/sed/sort/awk/uniq were allowlisted as reads while each has a form
# that writes a file: `2> f`, `&> f`, sed's `w` command, sort -o / --output, awk's in-program
# `print > "f"` / `print | cmd` / system(), and uniq IN OUT. 832 closed them in its vendored copy
# (6fc8e737, c31857a3, 6c3cbd39, 27ba4c0e, b87b1409) and verified end to end through the real hook.
# This file is that matrix, made repeatable. The READ half matters as much: a write check that
# fires on `grep -n ">>" f` or `echo "a > b"` gets the allowlist bypassed in practice.
#
# Usage: bash _t3746-allowlisted-writes-fixture.sh [path/to/safe-commands.sh]
# Exit 0 = matrix as expected, 1 = a row wrong, 2 = subject not found.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="${1:-}"
if [ -z "$LIB" ]; then
  if [ -f "$ROOT/FRAMEWORK.md" ]; then _order="$ROOT/agents/context/lib $ROOT/.agentic-framework/agents/context/lib"
  else _order="$ROOT/.agentic-framework/agents/context/lib $ROOT/agents/context/lib"; fi
  for d in $_order; do [ -f "$d/safe-commands.sh" ] && { LIB="$d/safe-commands.sh"; break; }; done
fi
[ -n "$LIB" ] && [ -f "$LIB" ] || { echo "CANNOT RUN: safe-commands.sh not found"; exit 2; }

PASS=0; FAIL=0
check() { # $1 = want (write|read), $2 = command
  local rc got
  LIBF="$LIB" CMD="$2" bash -c 'source "$LIBF" >/dev/null 2>&1
    if type has_bash_write_pattern >/dev/null 2>&1 && has_bash_write_pattern "$CMD"; then exit 1; fi
    is_bash_safe_command "$CMD"' >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq 0 ]; then got=read; else got=write; fi
  if [ "$got" = "$1" ]; then PASS=$((PASS+1)); printf '  PASS  %-5s %s\n' "$1" "$2"
  else FAIL=$((FAIL+1)); printf '  FAIL  %-5s %s   (judged %s)\n' "$1" "$2" "$got"; fi
}

echo "subject: $LIB"
echo "WRITES — must NOT pass as a read"
check write 'echo x > out.txt'                         # control: the plain redirect every gate catches
check write 'grep pattern file.txt 2> err.log'
check write 'grep pattern file.txt &> all.log'
check write "sed -n 'w out.txt' file.txt"
check write "sed -n '/x/w out.txt' file.txt"
check write 'sort -o out.txt file.txt'
check write 'sort --output=out.txt file.txt'
check write "awk '{print > \"o.txt\"}' file.txt"
check write "awk '{print | \"sh\"}' file.txt"
check write "awk 'BEGIN{system(\"touch x\")}'"
check write 'uniq in.txt out.txt'

echo "READS — must still pass"
check read  'grep -n ">>" file.txt'
check read  'echo "a > b"'
check read  'grep -c "x>y" file.txt'
check read  'grep pattern file.txt 2>/dev/null'
check read  'grep pattern file.txt 2>&1'
check read  'sort file.txt'
check read  'uniq file.txt'
check read  "awk '{print \$1}' file.txt"
check read  "sed -n '1,5p' file.txt"
check read  'cat file.txt'

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
