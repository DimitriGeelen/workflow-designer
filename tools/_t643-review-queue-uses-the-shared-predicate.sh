#!/usr/bin/env bash
# T-643 — `fw review-queue` must render the verdict the SHARED predicate returns.
#
# WHAT WENT WRONG (the thing this file exists to keep from coming back):
#   bin/fw's review-queue block does
#       sys.path.insert(0, os.environ.get("PROJECT_ROOT", "."))
#       try:    from web.shared import extract_recommendation_state, ...
#       except ImportError:   <inline re-implementation>
#   In a VENDORED install the framework lives at <project>/.agentic-framework/, so
#   web/ is NOT under PROJECT_ROOT. The import raised on every single invocation and
#   the `except` silently substituted the inline copy — which had drifted to a
#   narrower verdict vocabulary. T-579 (CLOSE) and T-609 (KEEP-OPEN) therefore
#   rendered as '?', i.e. "the agent owes a verdict", when the agent had given one
#   the library accepts.
#
#   AN ImportError THAT IS CAUGHT AND REPLACED BY A NEAR-COPY DOES NOT FAIL.
#   It substitutes a different program. Every test of the library passes; the path
#   that actually ships is the one nothing tested.
#
# THE TWO THINGS A PROBER HERE MUST NOT DO:
#   1. Retype the fallback and compare it to the library. That tests a MODEL of the
#      CLI (T-635's sin). Every leg below drives the real `fw review-queue`.
#   2. Assert the library "would work" and stop. That answers WHAT the predicate
#      decides, never WHETHER the CLI consults it. Path selection is established
#      here by INVERSION: shadow the library with a sentinel and the CLI must print
#      the sentinel; make the library unimportable and the CLI must fall back.
#      No single accident satisfies both halves.
#
# Exit 0 = all legs pass.

set -uo pipefail

# Script-relative by default. T643_PROJ overrides it so a TEETH CHECK can run a
# mutated COPY of this file from a temp dir and still point at the real project —
# without it, `$BASH_SOURCE/..` makes the copy resolve to /tmp and the run dies at
# the FATAL below, which reads like a passing teeth check and is not one. The
# `[ -x "$FW" ]` guard keeps a wrong override loud rather than silently inert.
PROJ="${T643_PROJ:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FW="$PROJ/.agentic-framework/bin/fw"
FWROOT="$PROJ/.agentic-framework"

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL  $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -x "$FW" ] || { echo "FATAL: $FW not executable"; exit 3; }

# ---------------------------------------------------------------------------
# Sandbox A — synthetic fixtures, one per verdict in the accepted vocabulary.
# ---------------------------------------------------------------------------
SB="$TMP/sandbox"
mkdir -p "$SB/.tasks/active" "$SB/web"

mkfixture() {   # $1=id  $2=verdict-text
    cat > "$SB/.tasks/active/$1-fixture.md" <<EOF
---
id: $1
name: fixture $2
status: started-work
owner: agent
workflow_type: build
---
## Acceptance Criteria
### Agent
- [x] agent side done
### Human
- [ ] [REVIEW] operator ticks this so the fixture enters the queue

## Recommendation

**Recommendation:** $2 — fixture body.
EOF
}
mkfixture T-9101 "CLOSE"
mkfixture T-9102 "KEEP-OPEN"
mkfixture T-9103 "NO_GO"
mkfixture T-9104 "GO"
mkfixture T-9105 "MAYBE"   # outside the vocabulary on purpose — must render '?'

# Strip ANSI, return "VERDICT" for a given task id (empty if the row is absent).
verdict_of() {   # $1=queue output file  $2=task id
    sed -e 's/\x1b\[[0-9;]*m//g' "$1" \
        | awk -v id="$2" '$0 ~ ("[[:space:]]" id "[[:space:]]") { print $1; exit }'
}

run_queue() {   # $1=PROJECT_ROOT  $2=fw binary  -> writes $TMP/out
    PROJECT_ROOT="$1" FRAMEWORK_ROOT="$FWROOT" "$2" review-queue > "$TMP/out" 2>&1
}

echo "=== T-643: fw review-queue must consult the shared predicate ==="
echo

# ---------------------------------------------------------------------------
echo "--- the sandbox is actually in effect (an inert fixture measures the live project)"
run_queue "$SB" "$FW"
SB_ROW=$(verdict_of "$TMP/out" T-9101)
LIVE_ROW=$(verdict_of "$TMP/out" T-579)
if [ -n "$SB_ROW" ] && [ -z "$LIVE_ROW" ]; then
    ok "queue reads the sandbox corpus (T-9101 present, live T-579 absent)"
else
    bad "SANDBOX INERT — T-9101='${SB_ROW:-missing}' live-T-579='${LIVE_ROW:-absent}'; every leg below would be measuring the real project"
fi

# ---------------------------------------------------------------------------
echo "--- the defect's precondition still holds (so the fix is load-bearing, not decorative)"
if PROJECT_ROOT="$PROJ" python3 -c "
import sys, os
sys.path = [os.environ['PROJECT_ROOT']]
import web.shared
" >/dev/null 2>&1; then
    bad "web.shared resolves from PROJECT_ROOT alone — this project is no longer vendored, so this file is testing a layout that no longer exists"
else
    ok "web.shared does NOT resolve from PROJECT_ROOT alone (vendored layout — the fallback WOULD be taken without the FRAMEWORK_ROOT insert)"
fi

# ---------------------------------------------------------------------------
echo "--- path selection, half 1: the CLI imports the library (sentinel shadow)"
# PROJECT_ROOT is inserted onto sys.path last, so it is searched FIRST: a web/shared.py
# in the sandbox shadows the framework's. If the CLI prints the sentinel, the import
# ran and its result reached the display.
cat > "$SB/web/shared.py" <<'EOF'
def extract_recommendation_state(body): return "SENTINEL"
def count_unchecked_human_acs(body): return 1
EOF
run_queue "$SB" "$FW"
V=$(verdict_of "$TMP/out" T-9101)
if [ "$V" = "SENTINEL" ]; then
    ok "library verdict reaches the display (T-9101 renders SENTINEL)"
else
    bad "CLI ignored the shared predicate — T-9101 rendered '$V', not SENTINEL (the inline fallback is still the live path)"
fi

# ---------------------------------------------------------------------------
echo "--- path selection, half 2: the fallback is what runs when the library is gone"
cat > "$SB/web/shared.py" <<'EOF'
raise ImportError("t643: library deliberately unimportable")
EOF
run_queue "$SB" "$FW"
V=$(verdict_of "$TMP/out" T-9101)
if [ "$V" = "CLOSE" ]; then
    ok "fallback path is reachable and distinguishable from the library path"
else
    bad "with the library unimportable T-9101 rendered '$V', expected CLOSE"
fi

# ---------------------------------------------------------------------------
echo "--- the fallback's vocabulary matches the library's accepted set"
# Still on the unimportable-library config: these four assertions are ABOUT the
# fallback, which is the code a real consumer project without web/ actually runs.
for pair in "T-9101:CLOSE" "T-9102:KEEP-OPEN" "T-9103:NO-GO" "T-9104:GO"; do
    id="${pair%%:*}"; want="${pair##*:}"
    got=$(verdict_of "$TMP/out" "$id")
    if [ "$got" = "$want" ]; then
        ok "fallback renders $want"
    else
        bad "fallback rendered '$got' for $id, expected $want"
    fi
done

# ---------------------------------------------------------------------------
# THE SECOND DEFECT, WHICH THE FIRST FIX UNCOVERED.
#
# Making CLOSE and KEEP-OPEN parse did not make them COUNTED. The summary
# parenthetical named its five buckets one at a time, so the two newly-readable
# verdicts fell out of the arithmetic entirely: "53 task(s) awaiting human review
# (36 GO / 10 DEFER / 2 NO-GO / 2 ? / 1 NO-REC)" — 51. A tally that does not add up
# to the total printed beside it is worse than the '?' it replaced, because '?' at
# least admitted it did not know.
#
# The invariant is arithmetic, so assert the arithmetic, not the five names.
# ---------------------------------------------------------------------------
tally_check() {   # $1=queue output file -> prints "OK n" or "MISMATCH stated=<n> summed=<m>"
    sed -e 's/\x1b\[[0-9;]*m//g' "$1" | python3 -c '
import sys, re
t = sys.stdin.read()
m = re.search(r"(\d+) task\(s\) awaiting human review\s*\(([^)]*)\)", t)
if not m:
    print("NOSUMMARY"); raise SystemExit
stated = int(m.group(1))
summed = sum(int(p.strip().split()[0]) for p in m.group(2).split("/"))
print(f"OK {stated}" if stated == summed else f"MISMATCH stated={stated} summed={summed}")
'
}

echo "--- the verdict tally accounts for every queued task"
rm -f "$SB/web/shared.py"
run_queue "$SB" "$FW"
T=$(tally_check "$TMP/out")
case "$T" in
    OK\ *)      ok "fixture queue tally balances (${T#OK })" ;;
    NOSUMMARY)  bad "no summary line in the fixture queue output — the tally leg is measuring nothing" ;;
    *)          bad "fixture queue tally does not balance: $T" ;;
esac
PROJECT_ROOT="$PROJ" FRAMEWORK_ROOT="$FWROOT" "$FW" review-queue > "$TMP/live" 2>&1
T=$(tally_check "$TMP/live")
case "$T" in
    OK\ *) ok "live queue tally balances (${T#OK })" ;;
    *)     bad "live queue tally does not balance: $T" ;;
esac

echo "--- a stated verdict does not wear the colour of 'no readable verdict'"
colour_of() {   # $1=output file  $2=task id -> the ANSI code opening that row
    grep -a "$2" "$1" | head -1 | sed -e 's/^\(\x1b\[[0-9;]*m\).*/\1/' | cat -v
}
C_CLOSE=$(colour_of "$TMP/out" T-9101)
C_KEEP=$(colour_of "$TMP/out" T-9102)
C_UNK=$(colour_of "$TMP/out" T-9105)
if [ "$(verdict_of "$TMP/out" T-9105)" != "?" ]; then
    bad "the out-of-vocabulary fixture rendered '$(verdict_of "$TMP/out" T-9105)', not '?' — the colour comparison has no baseline"
elif [ -z "$C_UNK" ] || [ -z "$C_CLOSE" ]; then
    bad "could not read row colours (CLOSE='$C_CLOSE' '?'='$C_UNK') — output may not be colourised here"
elif [ "$C_CLOSE" != "$C_UNK" ] && [ "$C_KEEP" != "$C_UNK" ]; then
    ok "CLOSE and KEEP-OPEN are visually distinct from '?'"
else
    bad "CLOSE='$C_CLOSE' KEEP-OPEN='$C_KEEP' share the '?' colour '$C_UNK' — an answered task still looks unanswered"
fi

# ---------------------------------------------------------------------------
# Sandbox B — the REAL corpus, symlinked read-only, so the two code paths can be
# compared over 90-odd genuine task bodies rather than four hand-written ones.
# ---------------------------------------------------------------------------
SB2="$TMP/corpus"
mkdir -p "$SB2/web"
ln -s "$PROJ/.tasks" "$SB2/.tasks"

verdict_table() {   # $1=PROJECT_ROOT  $2=fw binary
    PROJECT_ROOT="$1" FRAMEWORK_ROOT="$FWROOT" "$2" review-queue 2>&1 \
        | sed -e 's/\x1b\[[0-9;]*m//g' \
        | grep -oE '^[A-Z?-]+ *[0-9]+d +T-[0-9]+' \
        | awk '{ print $NF, $1 }' | sort
}

echo "--- library and fallback agree over the whole live corpus"
rm -f "$SB2/web/shared.py"
verdict_table "$SB2" "$FW" > "$TMP/lib.txt"
cat > "$SB2/web/shared.py" <<'EOF'
raise ImportError("t643: library deliberately unimportable")
EOF
verdict_table "$SB2" "$FW" > "$TMP/fbk.txt"
NROWS=$(wc -l < "$TMP/lib.txt")
if [ "$NROWS" -lt 10 ]; then
    bad "corpus comparison read only $NROWS rows — the symlinked .tasks did not take effect"
elif diff -q "$TMP/lib.txt" "$TMP/fbk.txt" >/dev/null; then
    ok "the two code paths return identical verdicts for all $NROWS queued tasks"
else
    bad "library and fallback disagree on $(diff "$TMP/lib.txt" "$TMP/fbk.txt" | grep -c '^<') task(s): $(diff "$TMP/lib.txt" "$TMP/fbk.txt" | head -4 | tr '\n' ' ')"
fi

# ---------------------------------------------------------------------------
# Teeth. A mutant fw whose inline fallback carries the SHIPPED (narrow) vocabulary.
# Every leg above that is about the fallback must go red against it; the leg about
# the library must NOT — that is what makes the mutation localized rather than a
# blunt instrument that would redden anything.
# ---------------------------------------------------------------------------
echo "--- teeth: revert the fallback vocabulary and the fallback legs must go red"
MUT="$TMP/fw-mutant"
sed -e 's/(KEEP-OPEN|NO\[-_\]GO|CLOSE|GO|DEFER)/(NO-GO|GO|DEFER)/' "$FW" > "$MUT"
chmod +x "$MUT"
if diff -q "$FW" "$MUT" >/dev/null; then
    echo "  MUTATION FAILED — vocabulary pattern not found in $FW; teeth legs are meaningless"
    FAIL=$((FAIL + 1))
else
    # Force the fallback again — the tally/colour legs above deliberately removed the
    # shadow, and a mutant of the FALLBACK judged on the LIBRARY path proves nothing.
    cat > "$SB/web/shared.py" <<'EOF'
raise ImportError("t643: library deliberately unimportable")
EOF
    run_queue "$SB" "$MUT"
    MC=$(verdict_of "$TMP/out" T-9101)
    MK=$(verdict_of "$TMP/out" T-9102)
    if [ "$MC" = "?" ] && [ "$MK" = "?" ]; then
        ok "shipped vocabulary renders CLOSE and KEEP-OPEN as '?' — the regression is detected"
    else
        bad "mutant rendered CLOSE='$MC' KEEP-OPEN='$MK' — expected '?' for both; the vocabulary legs have no teeth"
    fi

    MG=$(verdict_of "$TMP/out" T-9104)
    if [ "$MG" = "GO" ]; then
        ok "mutant still renders GO — the mutation is confined to the widened verdicts"
    else
        bad "mutant broke GO too ('$MG') — the mutation is too blunt to attribute the red legs to the vocabulary"
    fi

    cat > "$SB/web/shared.py" <<'EOF'
def extract_recommendation_state(body): return "SENTINEL"
def count_unchecked_human_acs(body): return 1
EOF
    run_queue "$SB" "$MUT"
    MS=$(verdict_of "$TMP/out" T-9101)
    if [ "$MS" = "SENTINEL" ]; then
        ok "mutant is unchanged on the library path — it mutates the fallback only"
    else
        bad "mutant altered the library path too ('$MS') — the sed hit more than the fallback"
    fi

    verdict_table "$SB2" "$MUT" > "$TMP/mut.txt"
    if diff -q "$TMP/lib.txt" "$TMP/mut.txt" >/dev/null; then
        bad "corpus comparison sees no difference under the mutant — that leg cannot fail and proves nothing"
    else
        ok "corpus comparison goes red under the mutant ($(diff "$TMP/lib.txt" "$TMP/mut.txt" | grep -c '^<') row(s) differ)"
    fi
fi

# ---------------------------------------------------------------------------
echo "--- teeth: restore the hand-listed tally buckets and the arithmetic must break"
MUT2="$TMP/fw-mutant-tally"
sed -e 's/^ordered = VERDICT_ORDER + sorted.*/ordered = ["GO", "DEFER", "NO-GO", "?", "NO-REC"]/' \
    "$FW" > "$MUT2"
chmod +x "$MUT2"
if diff -q "$FW" "$MUT2" >/dev/null; then
    echo "  MUTATION FAILED — 'ordered = VERDICT_ORDER + sorted…' not found in $FW; the tally leg has no teeth"
    FAIL=$((FAIL + 1))
else
    rm -f "$SB/web/shared.py"
    run_queue "$SB" "$MUT2"
    T=$(tally_check "$TMP/out")
    case "$T" in
        MISMATCH*) ok "hand-listed buckets drop the widened verdicts ($T) — the tally leg detects it" ;;
        OK\ *)     bad "tally still balances under the hand-listed mutant — that leg cannot fail and proves nothing" ;;
        *)         bad "tally teeth leg produced '$T'" ;;
    esac
fi

echo
TOTAL=$((PASS + FAIL))
echo "=== $PASS/$TOTAL passed ==="
[ "$FAIL" -eq 0 ] || exit 1
