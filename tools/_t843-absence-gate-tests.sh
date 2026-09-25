#!/usr/bin/env bash
# T-843 — tests for the uncontrolled-absence-assertion close gate.
#
# WRITTEN AND RUN BEFORE THE IMPLEMENTATION EXISTED, on the operator's directive to build on
# tests. Its first run is recorded in T-843 failing for the right reason (predicate not
# found) rather than passing vacuously. A suite only ever run after its code cannot tell
# "the code works" from "the suite asserts nothing" — the exact class this gate is for.
#
# FIXTURE TASK IDS ARE T-843, this task's own. A literal T-1 in a fixture makes the
# focus-drift gate read it as the action's target and refuse the write (learned in T-842).
#
# CONTRACT UNDER TEST — two single-purpose predicates, mirroring the house style of
# find_port_literals / find_unjudged_test_runs (print offenders, empty means clean):
#
#   find_uncontrolled_absence_legs  "$cmds"  -> prints legs classified NONE by the census
#   find_unparseable_absence_legs   "$cmds"  -> prints absence legs whose pattern cannot be
#                                               extracted; these are NOT EVALUATED, and the
#                                               call site must neither pass nor fail them
#
# THE GATE MUST MIRROR THE CENSUS, NOT REINVENT IT. Only NONE blocks. EXISTENCE-controlled
# legs are weakly controlled and the census does not count them, so the gate must not
# either — a gate stricter than its own census would make the two disagree, and then the
# corpus number and the close decision mean different things.

set -uo pipefail
REPO="${T843_REPO_ROOT:-/opt/832-Workflow-designer}"
LIB="$REPO/.agentic-framework/lib/verification-absence.sh"
PASS=0; FAIL=0; N=0
say(){ N=$((N+1)); printf '%s %d - %s\n' "$1" "$N" "$2"; }
ok(){  PASS=$((PASS+1)); say ok "$1"; }
bad(){ FAIL=$((FAIL+1)); say "not ok" "$1"; }

if [ ! -f "$LIB" ]; then
    bad "PRE: $LIB does not exist yet — implementation not written"
    printf '\n# passed %d, failed %d\n' "$PASS" "$FAIL"
    echo "# RED FOR THE RIGHT REASON: the lib is absent, so every behavioural test below"
    echo "# would be asserting over a function that does not exist. This is the recorded"
    echo "# pre-implementation state required by T-843's first AC."
    exit 1
fi
# PROJECT_ROOT is how the lib finds the classifier. Without it the lib degrades to
# reporting nothing — which is correct behaviour but makes every test below vacuous.
export PROJECT_ROOT="$REPO"
# shellcheck source=/dev/null
source "$LIB"
for fn in find_uncontrolled_absence_legs find_unparseable_absence_legs; do
    if type "$fn" &>/dev/null; then ok "PRE: $fn is defined"; else bad "PRE: $fn is NOT defined"; fi
done
if [ "$FAIL" -ne 0 ]; then
    printf '\n# passed %d, failed %d\n' "$PASS" "$FAIL"
    echo "# RED FOR THE RIGHT REASON: predicate missing."
    exit 1
fi

if _fw_absence_classifier_available; then
    ok "PRE: the classifier resolved — the tests below are measuring something"
else
    bad "PRE: classifier NOT found. Every 'expect empty output' test below would pass vacuously."
    printf '\n# passed %d, failed %d\n' "$PASS" "$FAIL"
    echo "# REFUSING TO REPORT ON A SUITE THAT CANNOT MEASURE. This guard exists because the"
    echo "# first run of this file passed tests 4, 6 and 7 with no classifier present: they"
    echo "# assert empty output, and a predicate that cannot run reports empty output."
    exit 1
fi

# ── helpers ───────────────────────────────────────────────────────────────────
# hits <fn> <block> -> number of non-empty output lines
hits(){ local o; o="$($1 "$2")"; [ -z "$o" ] && echo 0 || printf '%s\n' "$o" | grep -c . ; }

# ── 1. an uncontrolled absence leg is reported ────────────────────────────────
B1="! grep -q 'T-843' .context/working/.gate-bypass-log.yaml"
[ "$(hits find_uncontrolled_absence_legs "$B1")" -eq 1 ] \
  && ok "bare bang-grep with no control is reported" \
  || bad "bare bang-grep with no control was NOT reported"

# ── 2. a PATTERN-controlled leg is NOT reported ───────────────────────────────
# Sibling's OWN grep pattern is the same string, which is what the census requires.
B2="grep -q 'T-843' docs/nonexistent-but-parsed.md
! grep -q 'T-843' .context/working/.gate-bypass-log.yaml"
[ "$(hits find_uncontrolled_absence_legs "$B2")" -eq 0 ] \
  && ok "PATTERN-controlled leg is not reported" \
  || bad "PATTERN-controlled leg WAS reported — gate stricter than its census"

# ── 3. a control whose pattern merely APPEARS nearby must NOT count ───────────
# The over-crediting bug the census header documents: mention is not invocation.
B3="python3 -c \"print('T-843 appears here as prose')\"
! grep -q 'T-843' .context/working/.gate-bypass-log.yaml"
[ "$(hits find_uncontrolled_absence_legs "$B3")" -eq 1 ] \
  && ok "a pattern MENTIONED in a sibling does not count as a control" \
  || bad "a mere mention was credited as a control — the documented over-crediting bug"

# ── 4. a non-absence block produces nothing (negative control) ────────────────
# Without this, "empty output means clean" could be a function that prints nothing ever.
B4="git diff --quiet HEAD -- README.md
python3 -c \"import yaml; yaml.safe_load(open('policy/value-drivers.yaml'))\"
grep -q 'hello' README.md"
[ "$(hits find_uncontrolled_absence_legs "$B4")" -eq 0 ] \
  && ok "a block with no absence legs reports nothing" \
  || bad "a block with no absence legs reported something"

# ── 5. empty input ────────────────────────────────────────────────────────────
[ "$(hits find_uncontrolled_absence_legs "")" -eq 0 ] \
  && ok "empty block reports nothing" || bad "empty block reported something"

# ── 6. NOT EVALUATED: an absence leg whose pattern cannot be extracted ────────
# Must be reported by the unparseable predicate and NOT by the uncontrolled one.
# This is the constraint T-843 refuses to ship without.
# An unquoted variable genuinely defeats GREP_PAT (verified: "$(cat f)" IS extracted as a
# literal, so the obvious fixture was readable and this test failed for the right reason).
B6='! grep -q $T843_PATTERN some-file.txt'
u=$(hits find_unparseable_absence_legs "$B6")
c=$(hits find_uncontrolled_absence_legs "$B6")
[ "$u" -ge 1 ] && ok "unparseable absence leg IS reported as NOT EVALUATED" \
               || bad "unparseable absence leg was NOT reported as NOT EVALUATED"
[ "$c" -eq 0 ] && ok "unparseable absence leg is NOT counted as uncontrolled (would be a false FAIL)" \
               || bad "unparseable absence leg was counted as uncontrolled — blocks a close for the wrong reason"

# ── 7. the parseable-but-uncontrolled case is not swallowed by predicate 6 ────
[ "$(hits find_unparseable_absence_legs "$B1")" -eq 0 ] \
  && ok "a plainly parseable leg is not mislabelled NOT EVALUATED" \
  || bad "a parseable leg was mislabelled NOT EVALUATED — would hide a real finding"

# ── 8. ANTI-DRIFT: the gate must agree with the census on a real corpus file ──
# L-533: run THIS expression, not a re-typed copy. If the predicate and the census ever
# disagree on the same input, the corpus number and the close decision mean different
# things — and that divergence is exactly what a re-implementation in bash would cause.
REAL="$REPO/.tasks/completed/T-842-pin-the-commit-checkpoint-exemption-the-.md"
if [ -f "$REAL" ]; then
    census_n=$(python3 "$REPO/tools/_t560-absence-assertion-census.py" 2>/dev/null \
               | grep -c "T-842-pin-the-commit-checkpoint" || true)
    block=$(sed -n '/^## Verification/,/^## RCA/p' "$REAL")
    gate_n=$(hits find_uncontrolled_absence_legs "$block")
    if [ "$census_n" -eq "$gate_n" ]; then
        ok "gate agrees with census on a real file (both $gate_n)"
    else
        bad "gate and census DISAGREE on a real file (census $census_n, gate $gate_n)"
    fi
else
    bad "anti-drift test could not run: fixture file absent (NOT a pass)"
fi

printf '\n# passed %d, failed %d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
