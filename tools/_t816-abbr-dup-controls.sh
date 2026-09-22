#!/usr/bin/env bash
# _t816-abbr-dup-controls.sh — does E-XML-ABBR-DUP actually discriminate?
#
# T-816, closing the highest-carrier parity gap in tests/test_rule_form_parity.py:
# lane `abbr` is carried by 96/96 bpmn maps and, until this rule, nothing on that form
# checked it. The YAML form has checked it since the beginning.
#
# WHY THIS PROBE EXISTS AT ALL. The corpus fires this rule ZERO times — every map has
# distinct abbrs, which is the correct and expected state. So the only evidence the rule
# works is a deliberate violation: a rule that never fires against any input is
# indistinguishable from a rule that was never wired up, and the parity table would report
# the gap CLOSED either way. That is the exact shape T-309's inception warned about when it
# found the XML form carrying the weaker rule set.
#
# THREE BRANCHES, all in throwaway copies of a REAL corpus map (never a synthetic fixture —
# a hand-built document can drift from what the editor actually emits, and then the probe
# tests a shape nobody produces):
#
#   A  duplicate abbr        -> must FIRE     (the rule has teeth)
#   B  distinct abbrs        -> must be SILENT (it discriminates, rather than flagging all)
#   C  no abbr on any lane   -> must be SILENT (absence of an optional carrier is not a
#                                               violation — matches the YAML predicate's
#                                               `if abbr is not None`)
#
# B and C are not padding. Without B the rule could flag every map and still pass A; without
# C it could reject every heightless or abbr-less hand-authored map, which is a different
# defect wearing the same green.
#
# Exit: 0 all three branches behaved | 1 a branch disagreed | 3 could not set up

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$REPO/tools/validate-workflow.py"
RULE="E-XML-ABBR-DUP"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$VALIDATOR" ] || cannot "validator not found: $VALIDATOR"

# Pick a real corpus map that carries at least TWO distinct abbrs — the fixture must be
# capable of exhibiting the violation, or branch A proves nothing.
FIXTURE=""
for f in "$REPO"/examples/aef-processes/rendered/*.bpmn; do
    n=$(grep -oh 'abbr="[^"]*"' "$f" 2>/dev/null | sort -u | wc -l)
    if [ "$n" -ge 2 ]; then FIXTURE="$f"; break; fi
done
[ -n "$FIXTURE" ] || cannot \
  "no corpus map carries two distinct lane abbrs, so branch A has no fixture capable of
  producing a collision. That is a statement about the corpus, not a passing rule."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

A1=$(grep -oh 'abbr="[^"]*"' "$FIXTURE" | sed -n '1p' | sed 's/abbr="//;s/"//')
A2=$(grep -oh 'abbr="[^"]*"' "$FIXTURE" | sed -n '2p' | sed 's/abbr="//;s/"//')

fires() { python3 "$VALIDATOR" "$1" 2>&1 | grep -c "$RULE"; }

echo "=== T-816 ${RULE} controls (fixture: $(basename "$FIXTURE")) ==="

# --- B first: the untouched map must be silent. If it is not, A means nothing.
if [ "$(fires "$FIXTURE")" = "0" ]; then
    ok "B distinct abbrs -> silent (so branch A below is meaningful)"
else
    bad "B untouched corpus map should not fire $RULE" \
        "it fires on a valid map — the rule flags rather than discriminates; stopping"
    echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi

# --- A: collapse one abbr onto another -> must fire.
cp "$FIXTURE" "$WORK/dup.bpmn"
perl -0pi -e "s/abbr=\"$A2\"/abbr=\"$A1\"/" -- "$WORK/dup.bpmn"
if [ "$(fires "$WORK/dup.bpmn")" -ge 1 ]; then
    ok "A duplicate abbr ('$A2' -> '$A1') -> FIRES"
else
    bad "A duplicate abbr should fire $RULE" \
        "the rule is inert; the parity table would report the gap CLOSED regardless"
fi

# --- C: strip every abbr -> must be silent.
cp "$FIXTURE" "$WORK/noabbr.bpmn"
perl -0pi -e 's/ abbr="[^"]*"//g' -- "$WORK/noabbr.bpmn"
if [ "$(grep -c 'abbr=' "$WORK/noabbr.bpmn")" != "0" ]; then
    bad "C setup" "failed to strip abbr attributes from the copy"
elif [ "$(fires "$WORK/noabbr.bpmn")" = "0" ]; then
    ok "C no abbr anywhere -> silent (absence of an optional carrier is not a violation)"
else
    bad "C lanes without abbr should not fire $RULE" \
        "an absent optional carrier is being reported as a collision"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
