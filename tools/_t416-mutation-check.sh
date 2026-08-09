#!/usr/bin/env bash
# _t416-mutation-check.sh — prove the residue legs bite, by reverting to the T-412 span rule.
#
# T-412's generative leg was green throughout the entire life of this defect. That is the
# precise reason a mutation check exists here: a leg that has never failed is not known to be
# capable of failing, and the previous generation of these teeth proved exactly that.
#
# Reverts announced_pair() to the disjoint-span form on a COPY, runs the teeth against it,
# and asserts leg (c) — generative over PAIRS — turns red. Nothing tracked is modified.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/tools/tracked-secret-artifacts.py"
TEETH="$ROOT/tools/_t416-qualifier-residue-teeth.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "=== T-416 mutation check ==="

python3 - "$SRC" "$TMP/mutant.py" <<'PY' || exit 2
import sys
src = open(sys.argv[1], encoding="utf-8").read()
old = """    sec = _spans(flat, SECRECY_WORDS, whole_part_only=False)
    if not sec:
        return None

    residue = list(flat)
    for s0, s1 in sec:
        for i in range(s0, s1):
            residue[i] = "-"
    noun = _spans("".join(residue), CREDENTIAL_NOUNS, whole_part_only=True)
    if not noun:
        return None
    return sec[0], noun[0]"""
# The T-412 rule this replaced: disjoint spans, no masking.
new = """    sec = _spans(flat, SECRECY_WORDS, whole_part_only=False)
    noun = _spans(flat, CREDENTIAL_NOUNS, whole_part_only=True)
    for s0, s1 in sec:
        for n0, n1 in noun:
            if s1 <= n0 or n1 <= s0:
                return (s0, s1), (n0, n1)
    return None"""
n = src.count(old)
if n != 1:
    print("ERROR: mutation anchor matched %d times, expected 1. announced_pair() was edited;"
          " re-anchor this check before trusting it." % n, file=sys.stderr)
    sys.exit(2)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(old, new))
print("  mutant built — residue rule reverted to T-412 disjoint spans")
PY

out="$TMP/teeth.out"
SUBJECT="$TMP/mutant.py" bash "$TEETH" > "$out" 2>&1
rc=$?

fails=0
if [ "$rc" -eq 0 ]; then
  echo "FAIL: the teeth PASSED against the pre-fix rule. They are not measuring this fix." >&2
  fails=1
fi
for leg in "(a)" "(c)" "(f)"; do
  if grep -q "FAIL: $leg" "$out"; then
    echo "  ok  leg $leg goes red on the T-412 rule"
  else
    echo "FAIL: leg $leg stayed green with the fix reverted." >&2
    fails=$((fails + 1))
  fi
done
# (b) is the reciprocal — it must NOT go red, or (a)/(c) are being satisfied by the
# ANNOUNCED class collapsing rather than by the residue rule. (f) is deliberately NOT in (b):
# it is a miss this fix CLOSES, so it goes red on the mutant for a good reason, and folding
# it into (b) made this very check report the improvement as collateral damage.
if grep -q "FAIL: (b)" "$out"; then
  echo "FAIL: the reciprocal leg went red on the mutant — the mutation broke more than the
     rule under test, so (a)/(c) going red proves nothing about it." >&2
  fails=$((fails + 1))
else
  echo "  ok  reciprocal leg (b) stays green on the mutant (the change is isolated)"
fi

echo
if [ "$fails" -ne 0 ]; then
  echo "MUTATION CHECK FAIL — $fails" >&2
  exit 1
fi
echo "MUTATION CHECK PASS — the residue legs bite, and only they do"
