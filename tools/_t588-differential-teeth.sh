#!/usr/bin/env bash
# T-588 — teeth for the extractor differential. Does it FAIL when it should?
#
# The differential's headline result is "upstream is defective, ours is correct". A tool
# that cannot reach any other conclusion says that whatever it reads. So: mutate a COPY
# three ways and require a specific non-zero outcome each time.
#
# EVERY MUTATION REWRITES A LINE THE INTERPRETER REACHES. Appending garbage to a shell
# script tests the tail of a file no early-exiting interpreter parses — that is how T-499's
# first mutation collected ten green legs from a tool it had just declared dead.
#
# Exit: 0 all mutations caught · 1 a mutation went undetected

set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$REPO/tools/_t588-verification-extractor-differential.sh"
UP="${T588_UPSTREAM:-}"

if [ -z "$UP" ] || [ ! -f "$UP/lib/verification-port.sh" ]; then
  echo "CANNOT LOOK: set T588_UPSTREAM to an upstream clone. No mutation was tested."
  exit 2
fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0

# T588_REPO is what makes a copy in /tmp still read the REAL sources. Without it every
# mutant aborts with "update-task.sh does not exist" — rc 2 for a reason that has nothing
# to do with the mutation, and two of these legs assert rc 2. Measured: all three mutants
# went green that way before this was added.
run() { T588_UPSTREAM="$UP" T588_REPO="$REPO" bash "$1" >"$TMP/out" 2>&1; echo $?; }

# An rc alone is not enough here. rc 2 means "could not look", and there are many ways to
# fail to look — including ones the mutation did not cause. So each leg also names the
# text it expects to see, and a right rc for the wrong reason is a FAIL.
leg() { # leg <name> <expected-rc> <actual-rc> <expected-substring> <what-the-mutation-breaks>
  local ok=1
  [ "$2" = "$3" ] || ok=0
  grep -qF -- "$4" "$TMP/out" || ok=0
  if [ "$ok" = "1" ]; then
    printf '  [ok  ] %-42s rc=%s  %s\n' "$1" "$3" "$5"
  else
    fail=1
    printf '  [FAIL] %-42s expected rc=%s + %q\n         got rc=%s\n         %s\n' "$1" "$2" "$4" "$3" "$5"
    sed 's/^/         | /' "$TMP/out" | head -12
  fi
}

echo "TEETH — each mutation rewrites a line the interpreter reaches"
echo

# M1 — make ours produce upstream's output. The two are then indistinguishable, and every
# "they differ" assertion downstream becomes vacuous. The CONTROL must catch this, not the
# legs: that is the whole reason the control exists.
sed 's|^  local TASK_FILE="\$1" _v_exact_ln verify_section guard$|  local TASK_FILE="$1"; upstream_extract "$TASK_FILE"; return 0|' \
  "$TOOL" > "$TMP/m1.sh"
cmp -s "$TOOL" "$TMP/m1.sh" && { echo "  [FAIL] M1 did not modify anything — the sed target moved."; fail=1; }
leg "ours made identical to upstream" 2 "$(run "$TMP/m1.sh")" \
    "cannot separate the two extractors" "control aborts; no finding is reported"

# M2 — blind the guard lift. GUARD_BODY comes back empty, so the tool is no longer testing
# our refusal path at all. It must refuse to look rather than quietly test less.
sed 's|/\^run_verification_commands\\(\\) \\{/{f=1;next}|/^__never_matches__/{f=1;next}|' \
  "$TOOL" > "$TMP/m2.sh"
cmp -s "$TOOL" "$TMP/m2.sh" && { echo "  [FAIL] M2 did not modify anything — the sed target moved."; fail=1; }
leg "our refusal guard cannot be lifted" 2 "$(run "$TMP/m2.sh")" \
    "could not lift run_verification_commands" "aborts: tests less without saying so"

# M3 — neutralise our guard so it never refuses. Fixture C then extracts a leg instead of
# refusing, which is a real behavioural regression and must surface as a FAILING LEG (rc 1),
# not as an abort — the tool could still see, it just saw something wrong.
sed 's|^  eval "\$GUARD_BODY"$|  return 0|' "$TOOL" > "$TMP/m3.sh"
cmp -s "$TOOL" "$TMP/m3.sh" && { echo "  [FAIL] M3 did not modify anything — the sed target moved."; fail=1; }
leg "our guard neutralised (never refuses)" 1 "$(run "$TMP/m3.sh")" \
    "ours refuses rather than guessing" "fixture C leg goes red"

echo
if [ "$fail" = "0" ]; then
  echo "3 passed, 0 failed — the differential can reach a conclusion other than 'all well'."
  echo
  echo "[note] M1 and M2 land on the CONTROL and the LIFT, not on a leg. That is the"
  echo "       intended split: a harness that cannot separate the two implementations, or"
  echo "       cannot load the code it claims to test, must abort rather than report."
  exit 0
fi
echo "A MUTATION WENT UNDETECTED. The differential's green run does not mean what it says."
exit 1
