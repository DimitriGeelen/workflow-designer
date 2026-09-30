#!/usr/bin/env bash
# T-949 — does the triage-completeness checker actually BITE?
#
# The checker passed on the real document the first time it ran clean. That is not
# evidence of teeth: a checker that always exits 0 would read identically. So drive it
# against deliberately broken fixtures and require a FAILURE from each, plus a no-op
# control proving the unbroken fixture passes (PL-339 — a mutation harness needs a
# no-op guard, or "it failed" might just mean "it always fails").
#
# Exit 0 = all legs pass. Exit 3 = could not measure.
set -uo pipefail

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="$PROJ/tools/_t949-triage-completeness.py"
TRIAGE="$PROJ/docs/reports/T-949-go-scope-triage.md"

[ -f "$CHECKER" ] || { echo "COULD-NOT-MEASURE: $CHECKER missing" >&2; exit 3; }
[ -f "$TRIAGE"  ] || { echo "COULD-NOT-MEASURE: $TRIAGE missing"  >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

# a fixture audit report naming three inceptions the triage document does cover
REPORT="$TMP/report.md"
{
  echo "# fixture"
  echo "## Findings (most recent first)"
  echo ""
  echo "- T-218 — .tasks/completed/T-218-x.md"
  echo "- T-301 — .tasks/completed/T-301-x.md"
  echo "- T-006 — .tasks/completed/T-006-x.md"
} > "$REPORT"

run() {  # run <triage-file> -> prints rc
    T949_AUDIT_REPORT="$REPORT" T949_TRIAGE="$1" python3 "$CHECKER" >"$TMP/out" 2>&1
    echo $?
}

echo "=== T-949: teeth on the triage-completeness checker ==="
echo

# --- leg 0: the NO-OP control ------------------------------------------------
# Unmutated fixture must PASS. Without this, every failure below is meaningless.
cp "$TRIAGE" "$TMP/clean.md"
rc=$(run "$TMP/clean.md")
if [ "$rc" -eq 0 ]; then
    ok "no-op control: the unmutated document passes (rc=0)"
else
    bad "PRECONDITION FAILED — unmutated document does not pass (rc=$rc); every leg below is vacuous"
    echo "--- checker said ---"; cat "$TMP/out"
    echo; echo "=== $PASS passed, $FAIL failed ==="; exit 1
fi

# --- leg 1: COVERAGE --------------------------------------------------------
# Delete T-301's verdict bullet. The audit still flags it, so the checker must object.
python3 - "$TMP/clean.md" "$TMP/no-coverage.md" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
out = re.sub(r"^- \*\*T-301\*\*.*?(?=\n- |\n#|\n\n)", "", src, flags=re.S | re.M)
assert out != src, "mutation did not land: the T-301 bullet was not matched"
open(sys.argv[2], "w").write(out)
PY
if [ $? -ne 0 ]; then
    bad "coverage mutation could not be applied — cannot test this leg"
else
    rc=$(run "$TMP/no-coverage.md")
    if [ "$rc" -ne 0 ] && grep -q 'COVERAGE' "$TMP/out"; then
        ok "removing a flagged inception's verdict fails the COVERAGE leg"
    else
        bad "verdict removed and the checker still passed (rc=$rc) — coverage has no teeth"
    fi
fi

# --- leg 2: VOCABULARY ------------------------------------------------------
# Rename a verdict heading to something undeclared. Coverage then also breaks, so
# assert specifically that the ids under it stop being classified.
sed 's/^### UNDONE.*/### PROBABLY-FINE (1) — nothing filed/' "$TMP/clean.md" > "$TMP/bad-vocab.md"
if cmp -s "$TMP/clean.md" "$TMP/bad-vocab.md"; then
    bad "vocabulary mutation did not land — '### UNDONE' heading not found"
else
    rc=$(run "$TMP/bad-vocab.md")
    if [ "$rc" -ne 0 ]; then
        ok "an undeclared verdict heading is rejected (its ids fall out of classification)"
    else
        bad "undeclared verdict heading accepted (rc=$rc)"
    fi
fi

# --- leg 3: EVIDENCE --------------------------------------------------------
# Strip T-301's bullet down to an assertion with no artifact cited. This is the leg
# that already caught two real rows in the live document, so it is known-live; the
# fixture pins it.
python3 - "$TMP/clean.md" "$TMP/no-evidence.md" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
out = re.sub(r"^- \*\*T-301\*\*.*?(?=\n- |\n#|\n\n)",
             "- **T-301** — nothing was filed against this one, I am confident.\n",
             src, flags=re.S | re.M)
assert out != src, "mutation did not land: the T-301 bullet was not matched"
open(sys.argv[2], "w").write(out)
PY
if [ $? -ne 0 ]; then
    bad "evidence mutation could not be applied — cannot test this leg"
else
    rc=$(run "$TMP/no-evidence.md")
    if [ "$rc" -ne 0 ] && grep -q 'EVIDENCE' "$TMP/out"; then
        ok "a verdict citing no artifact fails the EVIDENCE leg"
    else
        bad "unevidenced verdict accepted (rc=$rc) — evidence leg has no teeth"
    fi
fi

# --- leg 4: refuses rather than passes when it cannot measure ---------------
rc=$(T949_AUDIT_REPORT="$TMP/nonexistent.md" T949_TRIAGE="$TMP/clean.md" \
     python3 "$CHECKER" >"$TMP/out" 2>&1; echo $?)
if [ "$rc" -eq 3 ]; then
    ok "a missing audit report is rc=3 COULD-NOT-MEASURE, not a pass"
else
    bad "missing audit report produced rc=$rc; CANNOT RUN must never read as a pass"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
