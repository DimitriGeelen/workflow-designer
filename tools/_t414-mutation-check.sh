#!/usr/bin/env bash
# _t414-mutation-check.sh — prove the two new provenance legs can actually go red.
#
# A leg that has never failed is not known to be capable of failing. T-413's AEF-INCIDENTAL
# leg was red once, before the fix, and that run is committed as
# tests/fixtures/aef-inbound/_t413-first-run.txt — but a committed text file proves nothing
# about the leg as it stands TODAY. This reverts the T-414 fix on a COPY of src and asserts
# that exactly the right legs turn red against it.
#
# The four pre-existing legs must stay GREEN on the mutant. That half matters as much: it
# shows the two new legs are measuring the narrowing itself rather than some incidental
# damage the mutation happens to cause.
#
# Nothing under version control is modified — the mutant lives in a temp dir and the probe
# reads it through T406_SRC.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src/aef-workflow-designer.html"
PROBE="$ROOT/tools/_t406-doc-comment-provenance-cdp.mjs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== T-414 mutation check ==="

python3 - "$SRC" "$TMP/mutant.html" <<'PY' || exit 2
import sys
src = open(sys.argv[1], encoding="utf-8").read()
# The shape rule, reverted to the T-406 prefix test it replaced.
old = """    const lines = data.split('\\n').map(l => l.trim()).filter(l => l.length > 0);
    const nothingButTrailer = lines.length === 1 && lines[0].startsWith(DI_TRAILER_PREFIX);
    if (!someoneElsesDocument && nothingButTrailer) return null;"""
new = """    if (!someoneElsesDocument && data.trim().startsWith(DI_TRAILER_PREFIX)) return null;"""
n = src.count(old)
if n != 1:
    # Not a pass/fail of the fix — the anchor moved and this check is no longer measuring
    # anything. Loud, because a silently-unanchored mutation check reports a false green.
    print("ERROR: mutation anchor matched %d times, expected 1. The fix was edited and this"
          " check must be re-anchored before it means anything." % n, file=sys.stderr)
    sys.exit(2)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(old, new))
print("  mutant built — T-414 shape rule reverted to the T-406 prefix test")
PY

out="$TMP/mutant.out"
T406_SRC="$TMP/mutant.html" node "$PROBE" > "$out" 2>&1
rc=$?

fails=0
legs=0
# T-430: a fails-only tally cannot separate "the mutant was caught" from "the loops never
# ran" — a mutation step that silently produced no output leaves fails=0 and exits 0, and
# the caller records the mutation check as passed. `legs` counts the comparisons actually
# made. Named note_leg() rather than leg() because `leg` is the loop variable below.
note_leg() { legs=$((legs + 1)); }
fail() { note_leg; echo "FAIL: $*" >&2; fails=$((fails + 1)); }

note_leg
if [ "$rc" -eq 0 ]; then
  fail "the probe PASSED against a mutant with the fix reverted. Whatever the legs are
     measuring, it is not this fix."
fi

for leg in "AEF-INCIDENTAL" "OURS+RATIONALE"; do
  note_leg
  if grep -q "FAIL $leg" "$out"; then
    echo "  ok  $leg goes red on the mutant"
  else
    fail "$leg stayed green with the fix reverted — the leg cannot detect the defect
     it was written for."
  fi
done

for leg in "CONTROL" "STAMPED" "OURS  " "UNKNOWN" "AEF-CLEAN"; do
  note_leg
  if grep -q "FAIL  *$leg" "$out"; then
    fail "pre-existing leg '$leg' went red on the mutant. The two new legs are then not
     isolating the narrowing — the mutation is breaking something else as well."
  fi
done
echo "  ok  all 5 pre-existing legs stay green on the mutant (the change is isolated)"

echo
# T-430 abstention guard — before the verdict, or the verdict answers first.
if [ $(( ${legs:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "MUTATION CHECK FAIL — $fails" >&2
  exit 1
fi
echo "MUTATION CHECK PASS — $legs/8 legs: both new legs bite, and only they do"
