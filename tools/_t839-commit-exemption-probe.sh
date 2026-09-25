#!/usr/bin/env bash
# T-839 — two defects in the T-2054 post-completion commit exemption.
#
# DEFECT 1 (why the commit was blocked): _sc_is_commit_only_command matches the commit
#   POSITIONALLY at tok1/tok2/tok3. Any exec-wrapper prefix — timeout, env, nice, nohup,
#   command, stdbuf — shifts the tokens, the `case` falls through to _sc_simple_is_safe,
#   and the exemption is refused. The commit is still a commit; only its spelling moved.
#
# DEFECT 2 (why it could not be self-diagnosed): check-active-task.sh:292 emits
#   "What blocks here is a $(...) substitution sharing the line with the commit"
#   whenever the command merely CONTAINS `git commit`, with no check that a substitution
#   is present. It named the wrong cause on four consecutive attempts. PL-304: a gate
#   that refuses without naming WHICH rule it applied gets its behaviour invented by the
#   reader — and one that names the WRONG rule is worse, because the reader acts on it.
#
# Legs 1-2 are DISCRIMINATORS, not decoration: they must ALLOW. If they blocked, the
# finding would be "the exemption is dead", not "wrappers defeat it", and the remedy
# would be different. A probe whose legs all point one way cannot tell those apart.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 3
REPO=$PWD
LIB=$REPO/.agentic-framework/agents/context/lib/safe-commands.sh
HOOK=$REPO/.agentic-framework/agents/context/check-active-task.sh
[ -r "$LIB" ]  || { echo "REFUSE: cannot read $LIB"; exit 3; }
[ -r "$HOOK" ] || { echo "REFUSE: cannot read $HOOK"; exit 3; }
# shellcheck disable=SC1090
source "$LIB" 2>/dev/null || { echo "REFUSE: lib did not source"; exit 3; }
type _sc_is_commit_only_command &>/dev/null || { echo "REFUSE: predicate absent — cannot measure"; exit 3; }

PASS=0; FAIL=0
ok(){ echo "  PASS  $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL  $1"; echo "        $2"; FAIL=$((FAIL+1)); }
expect(){ # expect ALLOW|BLOCK "cmd" "label"
  local want=$1 cmd=$2 lbl=$3 got
  if _sc_is_commit_only_command "$cmd"; then got=ALLOW; else got=BLOCK; fi
  [ "$got" = "$want" ] && ok "$lbl ($got)" || no "$lbl" "got $got, want $want"
}
F="$REPO/.agentic-framework/bin/fw"

echo "=== T-839 commit-exemption probe ==="
echo "-- discriminators: these MUST allow, or the diagnosis is a different one --"
expect ALLOW "$F git commit -m \"T-1: x\""                      "bare fw git commit"
expect ALLOW "git commit -m \"T-1: x\""                          "bare git commit"
expect ALLOW "cd $REPO && $F git commit -m \"T-1: x\""           "cd && commit — cd is NOT the cause"
expect ALLOW "git add a.txt && $F git commit -m \"T-1: x\""      "the documented two-clause shape"

echo "-- DEFECT 1: exec-wrapper prefixes defeat the exemption --"
expect BLOCK "timeout 300 $F git commit -m \"T-1: x\""           "timeout wrapper"
expect BLOCK "cd $REPO && timeout 300 $F git commit -m \"T-1: x\"" "cd && timeout — the shape that stranded T-837/T-838"
expect BLOCK "env GIT_X=1 $F git commit -m \"T-1: x\""           "env wrapper"
expect BLOCK "nice $F git commit -m \"T-1: x\""                  "nice wrapper"

echo "-- the documented cause is real too; both defeat it, for different reasons --"
expect BLOCK "echo \"n=\$(wc -l < f)\"; $F git commit -m \"T-1: x\"" "\$(...) substitution (T-662, documented)"

echo "-- DEFECT 2: the block message names \$(...) unconditionally --"
# The emitting branch keys only on the command containing `git commit`. Assert that the
# guard has NO substitution test, which is exactly why it misdiagnosed a timeout wrapper.
GUARD=$(grep -n 'BASH_CMD" =~ git\[\[:space:\]\]+commit' "$HOOK" | head -1 | cut -d: -f1)
if [ -z "$GUARD" ]; then
  no "message guard located" "could not find the emitting branch — REFUSING to pass vacuously"
else
  BLOCKTXT=$(sed -n "${GUARD},$((GUARD+10))p" "$HOOK")
  if echo "$BLOCKTXT" | grep -q 'substitution sharing the line'; then
    if echo "$BLOCKTXT" | grep -qE 'BASH_CMD.*(\$\(|\\\$\()' | head -1 && \
       echo "$BLOCKTXT" | grep -vq 'echo'; then
      no "unconditional misdiagnosis" "the branch appears to test for a substitution — defect may be fixed"
    else
      ok "confirmed: the \$(...) diagnosis is emitted with no test that one is present (line $GUARD)"
    fi
  else
    no "message content" "the expected diagnosis string is absent at line $GUARD — hook text changed"
  fi
fi

echo "-- negative control: the harness can report a failure --"
if _sc_is_commit_only_command "rm -rf /"; then no "negative control" "a destructive command was ALLOWED"; else ok "negative control: non-commit command refused"; fi

echo
echo "probe: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
