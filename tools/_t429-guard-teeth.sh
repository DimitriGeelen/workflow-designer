#!/usr/bin/env bash
# _t429-guard-teeth.sh — prove the abstention census discriminates, and prove it on the
# row it originally got wrong.
#
# T-429.
#
# ONE TREE, ALL FOUR VERDICTS
# ---------------------------
# Every verdict is asserted against a SINGLE scratch tools/ directory. Four directories
# would all pass on a classifier returning a per-directory constant — the shape the T-427
# provenance bug had, and the reason T-428's fixture is heterogeneous too.
#
# THE ROW THAT MATTERS IS U1
# --------------------------
# `[ "$fail" -eq 0 ] || exit 1` is the verdict line every suite in this repo already ends
# on. It contains a tally, a comparison against zero, and a non-zero exit — every token a
# guard has. It fires when `fail` is NON-zero and is therefore silent in exactly the case
# this instrument audits. The first census called it GUARDED and reported 16 false
# negatives. That row is here permanently, and M1 re-installs the old logic to prove the
# leg still bites.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
REAL="$PWD"
CENSUS="$REAL/tools/_t429-abstention-census.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0

check() {   # check <label> <expected> <actual>
  if [ "$2" = "$3" ]; then
    printf '  PASS  %s\n' "$1"; pass=$((pass+1))
  else
    printf '  FAIL  %s\n        expected [%s] got [%s]\n' "$1" "$2" "$3"; fail=$((fail+1))
  fi
}

verdict() {   # verdict <root> <filename> [census]
  T429_ROOT="$1" python3 "${3:-$CENSUS}" 2>/dev/null \
    | awk -v f="$2" '$1==f {print "UNGUARDED"; found=1} END {if (!found) print "GUARDED-OR-ABSENT"}'
}

count() {   # count <root> <bucket-label> [census] — takes the LAST field, because the
            # census's own lines are prose ("counter-bearing suites: 4") and keying on $2
            # silently returned the word "suites:" as a count. A test harness that reads a
            # label as a number is the same family as everything else in this file.
  T429_ROOT="$1" python3 "${3:-$CENSUS}" 2>/dev/null \
    | awk -v k="$2" '$1==k {print $NF; exit}'
}

exitcode() { T429_ROOT="$1" python3 "${2:-$CENSUS}" >/dev/null 2>&1; echo $?; }

# ---------------------------------------------------------------- fixture
mkfix() {
  local d="$1/tools"; mkdir -p "$d"

  # G1 — a real guard: zero-branch takes a non-zero exit.
  cat > "$d/g1-guarded.sh" <<'SH'
pass=0; fail=0
run() { pass=$((pass+1)); }
if [ $(( ${pass:-0} + ${fail:-0} )) -eq 0 ]; then echo "ABSTAINED" >&2; exit 2; fi
[ "$fail" -eq 0 ] || exit 1
SH

  # G2 — the same guard written the other way round: non-zero tested, exit on its negation.
  cat > "$d/g2-guarded-gt.sh" <<'SH'
pass=0; fail=0
run() { pass=$((pass+1)); }
[ "$pass" -gt 0 ] || exit 2
[ "$fail" -eq 0 ] || exit 1
SH

  # U1 — THE ROW. Verdict line only. Every token of a guard, none of the meaning.
  # BOTH tallies are incremented on purpose: the first draft of this fixture only
  # incremented `pass`, so `fail` was not a tally, the classifier's alternation never
  # contained it, and U1 came out UNGUARDED for a reason that had nothing to do with the
  # branch logic under test. M1 was green against a leg that was passing by accident.
  cat > "$d/u1-verdict-only.sh" <<'SH'
pass=0; fail=0
run() { if [ "$1" = ok ]; then pass=$((pass+1)); else fail=$((fail+1)); fi; }
echo "  pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
SH

  # U2 — announces the condition and returns success anyway. Printing is not guarding.
  cat > "$d/u2-prints-only.sh" <<'SH'
pass=0; fail=0
run() { pass=$((pass+1)); }
[ $(( pass + fail )) -eq 0 ] && echo "warning: nothing ran"
[ "$fail" -eq 0 ] || exit 1
SH

  # N1 — no tally at all. Not a suite in this sense; must not be a finding.
  cat > "$d/n1-no-counter.sh" <<'SH'
echo hello
exit 0
SH
}

echo "=== T-429 abstention census teeth ==="
echo

mkfix "$WORK/base"

echo "V — four verdicts, one scratch tools/"
check "V1 real guard is not reported"                 "GUARDED-OR-ABSENT" "$(verdict "$WORK/base" g1-guarded.sh)"
check "V2 -gt 0 || exit form is also a guard"         "GUARDED-OR-ABSENT" "$(verdict "$WORK/base" g2-guarded-gt.sh)"
check "V3 verdict line alone is UNGUARDED"            "UNGUARDED"         "$(verdict "$WORK/base" u1-verdict-only.sh)"
check "V4 printing without exiting is UNGUARDED"      "UNGUARDED"         "$(verdict "$WORK/base" u2-prints-only.sh)"
check "V5 no-counter file is not a finding"           "GUARDED-OR-ABSENT" "$(verdict "$WORK/base" n1-no-counter.sh)"
check "V6 counter-bearing denominator is 4 of 5"      "4"                 "$(count "$WORK/base" 'counter-bearing')"
check "V7 findings exit 1"                            "1"                 "$(exitcode "$WORK/base")"

echo
echo "C — a tree with nothing wrong exits 0 and says PASS"
mkdir -p "$WORK/clean/tools"
cp "$WORK/base/tools/g1-guarded.sh" "$WORK/clean/tools/"
check "C1 all-guarded tree exits 0" "0" "$(exitcode "$WORK/clean")"
CLEAN="$(T429_ROOT="$WORK/clean" python3 "$CENSUS" 2>/dev/null | grep -c '^PASS')"
check "C2 all-guarded tree says PASS" "1" "$CLEAN"

echo
echo "L — cannot-answer must not read like nothing-found"
mkdir -p "$WORK/empty/tools"
check "L1 tools/ with no .sh exits 2, not 0" "2" "$(exitcode "$WORK/empty")"
mkdir -p "$WORK/notools"
check "L2 missing tools/ exits 2"            "2" "$(exitcode "$WORK/notools")"

echo
echo "D — the census must print its own denominator (it audits that defect)"
DENOM="$(T429_ROOT="$WORK/base" python3 "$CENSUS" 2>/dev/null | grep -c 'examined  *[0-9]* of [0-9]* file')"
check "D1 examined-of-total line present" "1" "$DENOM"

echo
echo "M — disable one discrimination; the named leg must go red"

# M1: the ORIGINAL classifier — tokens near each other, branch ignored. U1 must flip.
sed 's/if zero and fires_on_true:/if zero or nonzero:/' "$CENSUS" > "$WORK/m1.py"
check "M1 branch-blind matching hides the verdict-line row" \
  "GUARDED-OR-ABSENT" "$(verdict "$WORK/base" u1-verdict-only.sh "$WORK/m1.py")"

# M2: stop requiring a non-zero exit in the controlled region. U2 (prints, never exits)
# must flip to guarded. The sed is anchored on the CURRENT expression — an earlier version
# of this leg still referenced a line the fix had deleted, so it matched nothing and the
# leg tested nothing while reading green.
sed 's|if not re.search(r"\\bexit\\s+\[1-9\]", controlled):|if False:|' "$CENSUS" > "$WORK/m2.py"
check "M2 ignoring the exit requirement hides the prints-only row" \
  "GUARDED-OR-ABSENT" "$(verdict "$WORK/base" u2-prints-only.sh "$WORK/m2.py")"

echo
echo "  pass=$pass fail=$fail"

# T-429 abstention guard — this file is subject to its own finding.
if [ $(( ${pass:-0} + ${fail:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
[ "$fail" -eq 0 ] || exit 1
