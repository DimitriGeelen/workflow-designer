#!/usr/bin/env bash
# T-527 — the standing invariant behind this task's fix.
#
# WHAT THIS ASSERTS: no if-guarded leg in tests/run-bridge-tests.sh discards its probe's
# output to /dev/null. When a leg fails, the suite must be able to say WHY.
#
# WHY IT EXISTS AS A SEPARATE FILE RATHER THAN A LINE IN THE SUITE:
# the check greps for a pattern that would otherwise appear in the checking line itself and
# inflate its own count. Grepping a DIFFERENT file removes the self-reference entirely
# rather than relying on a regex that happens not to match itself today.
#
# WHY AN INVARIANT AND NOT A PINNED COUNT:
# T-527's ## Verification pins `show_output` at 27, which is correct for a completion gate
# on ONE task at ONE moment. Pinning 27 HERE would be G-015 — a line asserting a global
# always-moving property, which goes red for whoever next adds a leg, for a reason that has
# nothing to do with their change. "Zero discards" is a property of the suite's authoring
# discipline and does not move as the suite grows.
#
# THE DEFECT IT PREVENTS (measured, T-526/T-527): T-326 diagnosed output-discarding, wrote
# the reason into the source, and wired the remedy into 4 legs. 23 legs added afterwards were
# copied from a discarding template. Nothing counted uses of the remedy against uses of the
# thing it remedies, and a discarding leg is byte-identical to a capturing one in every GREEN
# run — so the population grew by copy with no signal until a red arrived uninvestigable.
#
# Exit 0 clean, 1 a discarding guard was found, 2 REFUSE (the subject or the remedy is
# missing — nothing was evaluated, and that is not a pass: PL-205).

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUITE="$ROOT/tests/run-bridge-tests.sh"

# Built by concatenation so this file does not contain the literal it searches for.
SINK="/dev/nu""ll"
PATTERN="^[[:space:]]*if .*> ?${SINK}"

if [ ! -f "$SUITE" ]; then
  echo "REFUSE: subject not found: $SUITE"
  echo "This is an abstention, not a pass — nothing was evaluated."
  exit 2
fi

# Anti-vacuity (T-524's lesson: a negative assertion is satisfied by silence). "Zero legs
# discard" is trivially true of a suite with no legs and of a suite whose remedy was deleted.
# Both are checked so a clean verdict means the discipline holds, not that it is absent.
if ! grep -q '^show_output()' "$SUITE"; then
  echo "REFUSE: the remedy show_output() is not defined in $SUITE."
  echo "Zero discarding guards is vacuous if the capture helper no longer exists."
  echo "This is an abstention, not a pass — nothing was evaluated."
  exit 2
fi

guards=$(grep -cE '^[[:space:]]*if ' "$SUITE" || true)
if [ "$guards" -lt 10 ]; then
  echo "REFUSE: only $guards if-guards found in $SUITE — the suite's shape changed."
  echo "This check assumes the if-guarded leg idiom; it cannot speak about another one."
  echo "This is an abstention, not a pass — nothing was evaluated."
  exit 2
fi

hits=$(grep -nE "$PATTERN" "$SUITE" || true)

if [ -n "$hits" ]; then
  n=$(printf '%s\n' "$hits" | wc -l)
  echo "T-527 FAIL — $n if-guarded leg(s) discard their probe's output:"
  printf '%s\n' "$hits" | sed 's/^/  /'
  echo
  echo "Each of these prints a bare [FAIL] line and destroys the evidence of why."
  echo "Redirect to \"\$TMP/leg-<name>.out\" and call show_output on the failing branch only."
  exit 1
fi

echo "T-527 OK — $guards if-guards, 0 discarding, show_output defined."
exit 0
