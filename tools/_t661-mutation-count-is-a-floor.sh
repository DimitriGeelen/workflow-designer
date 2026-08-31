#!/usr/bin/env bash
# T-661 — the shared mutation-completeness assertion must discriminate, and must NOT go
# red when a subject legitimately grows a second correct call site.
#
# The load-bearing leg is "two correct sites": that is the exact failure 999-AEF reported
# at rail @897, where their suite had been red for a while because someone did the right
# thing and added a third call site to a subject whose test pinned the count at two.
#
# Fixtures only. Never reads the real probers' subjects.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.

set -uo pipefail

PROJ="${T661_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LIB="$PROJ/tools/lib/mutation-assert.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

[ -f "$LIB" ] || { echo "COULD-NOT-MEASURE: $LIB not found" >&2; exit 3; }
# shellcheck source=/dev/null
. "$LIB"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

echo "=== T-661: mutation completeness is a floor, not an equality ==="
echo

PATTERN='^  *if \[ \$? -ne 0 \]; then'

# subject_with <n>  — a subject carrying n copies of the mutable form
subject_with() {
    # Separate `local` lines, not `local n="$1" f="...$n..."`: bash expands the whole
    # word list BEFORE performing the assignments, so `$n` is still unset there and
    # `set -u` kills the function. Same defect as T-657's make_root, made again here.
    local n="$1"
    local f="$TMP/subject-$n.sh"
    local i
    { echo '#!/usr/bin/env bash'
      for i in $(seq 1 "$n"); do
          echo "  run_check_$i"
          echo '  if [ $? -ne 0 ]; then'
          echo "      warn 'check $i failed'"
          echo '  fi'
      done
    } > "$f"
    echo "$f"
}

mutate() {  # mutate <subject> -> mutant path (the same sed the real probers use)
    local s="$1" m="$TMP/mutant-$RANDOM-$RANDOM.sh"
    sed 's|^  if \[ \$? -ne 0 \]; then|  if false; then|' "$s" > "$m"
    echo "$m"
}

# ---------------------------------------------------------------------------
echo "--- a complete single-site mutation is accepted"
S=$(subject_with 1); M=$(mutate "$S")
if OUT=$(assert_mutation_complete "$S" "$M" "$PATTERN"); then
    ok "one site mutated -> complete"
else
    bad "a genuine complete mutation was rejected: $OUT"
fi

# ---------------------------------------------------------------------------
# THE REGRESSION AEF REPORTED. Under the old `-ne 1` form this subject reports
# "MUTATION FAILED — got 2" and the leg goes red for a subject that is MORE thoroughly
# mutated than the one the assertion was written against.
echo "--- two correct sites, both mutated, must NOT be a failure"
S=$(subject_with 2); M=$(mutate "$S")
if OUT=$(assert_mutation_complete "$S" "$M" "$PATTERN"); then
    ok "two sites mutated -> complete (no upper bound; adding a correct site stays green)"
else
    bad "the equality trap survives — a fully-mutated 2-site subject was rejected: $OUT"
fi
# And prove the old form would indeed have failed it, so this leg is not vacuous.
OLD_COUNT=$(grep -c 'if false; then' "$M" || true)
if [ "$OLD_COUNT" -eq 2 ]; then
    ok "witness: the retired 'MUTATED -ne 1' assertion would have read 2 here and gone red"
else
    bad "the fixture does not reproduce the reported shape (marker count $OLD_COUNT, expected 2)"
fi

# ---------------------------------------------------------------------------
echo "--- a partial mutation is caught"
S=$(subject_with 2)
# Mutate only the first site — the half-mutation that reads like a passing subject.
M="$TMP/partial.sh"; awk 'BEGIN{d=0} /^  if \[ \$\? -ne 0 \]; then/ && d==0 {print "  if false; then"; d=1; next} {print}' "$S" > "$M"
if OUT=$(assert_mutation_complete "$S" "$M" "$PATTERN"); then
    bad "a half-mutated subject was accepted — this is the failure the count existed to prevent"
else
    echo "$OUT" | grep -q 'MUTATION INCOMPLETE' \
        && ok "partial mutation reported as incomplete, with the survivor count" \
        || bad "partial mutation rejected for the wrong reason: $OUT"
fi

# ---------------------------------------------------------------------------
# The failure the marker-count form could not see at all: the sed matched nothing because
# the subject moved, so the "mutant" is a byte-identical copy. Every downstream leg then
# compares the subject against itself and certifies teeth that are not there.
echo "--- a stale anchor is caught, and named as such"
S="$TMP/moved.sh"; printf '%s\n' '#!/usr/bin/env bash' 'if test $? -ne 0; then' '  warn x' 'fi' > "$S"
M=$(mutate "$S")
if OUT=$(assert_mutation_complete "$S" "$M" "$PATTERN"); then
    bad "a no-op mutation was accepted — the prober would certify teeth it does not have"
else
    echo "$OUT" | grep -q 'STALE ANCHOR' \
        && ok "stale anchor named distinctly from an incomplete mutation" \
        || bad "stale anchor not distinguished: $OUT"
fi

# ---------------------------------------------------------------------------
echo "--- a missing file is unmeasurable, not silently complete"
S=$(subject_with 1)
if OUT=$(assert_mutation_complete "$S" "$TMP/does-not-exist.sh" "$PATTERN"); then
    bad "a missing mutant was accepted as a complete mutation"
else
    echo "$OUT" | grep -q 'UNMEASURABLE' && ok "missing mutant -> UNMEASURABLE" \
        || bad "missing mutant rejected for the wrong reason: $OUT"
fi

# ---------------------------------------------------------------------------
# PL-299: a helper that returns non-zero unconditionally would pass every negative leg
# above. Assert the positive and negative legs are actually produced by different inputs.
echo "--- teeth: a helper that always fails must not satisfy this suite"
if assert_mutation_complete "$(subject_with 1)" "$(mutate "$(subject_with 1)")" "$PATTERN" >/dev/null; then
    ok "the accept path is reachable — the negative legs above discriminate"
else
    bad "PRECONDITION FAILED — nothing passes, so every negative leg is trivially satisfied"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
