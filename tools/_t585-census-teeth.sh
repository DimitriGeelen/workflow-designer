#!/usr/bin/env bash
# T-585 — teeth for the Human-AC visibility census.
#
# WHY THIS EXISTS SEPARATELY FROM THE CENSUS'S OWN CONTROL. The census runs six fixtures
# before it sweeps, and aborts if they do not classify correctly. That control proves the
# DETECTOR discriminates. It does not prove the ABORT works — a control whose failure path
# is broken is indistinguishable from a control that passed, and the census would then
# print "FINDINGS: none" over an unmeasured tree. So these legs mutate a COPY of the tool
# and assert the copy exits 2 and refuses to sweep.
#
# Mutating a copy, never the shipping file: T-576's probe would have destroyed the evidence
# for its own diagnosis by editing its subject in place. T585_REPO exists so the copy still
# reads the real predicate and the real task tree.
#
# THE MUTATIONS ARE CHOSEN TO EXECUTE. Appending garbage to a script is not a mutation test
# — bash parses incrementally and a syntax error after the last reachable `exit` is a static
# failure and a runtime non-event (measured on T-499). Each `sed` below rewrites a line the
# interpreter reaches on every run.
#
# Exit: 0 all legs bit · 1 a leg did not bite · 2 the subject is missing (refusal, not a pass)

set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOL="$ROOT/tools/_t585-human-ac-visibility-census.py"

if [ ! -f "$TOOL" ]; then
    echo "REFUSING TO CERTIFY: $TOOL is missing. Nothing was mutated, so nothing was"
    echo "measured — a 0 here would mean 'the teeth are fine' about a tool that is gone."
    exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0

leg() {
    # leg <name> <expected_rc> <actual_rc> <note>
    if [ "$2" -eq "$3" ]; then
        printf '  [ok  ] %-38s rc=%s  %s\n' "$1" "$3" "$4"; pass=$((pass + 1))
    else
        printf '  [FAIL] %-38s rc=%s (wanted %s)  %s\n' "$1" "$3" "$2" "$4"; fail=$((fail + 1))
    fi
}

run() { T585_REPO="$ROOT" python3 "$1" "${@:2}" >/dev/null 2>&1; echo $?; }

cp "$TOOL" "$TMP/intact.py"

# CONTROL FIRST, AND IT ABORTS. Every leg below asserts a NON-ZERO exit, so all of them
# are satisfied by a tool that is merely broken. If the unmutated copy cannot reach 0, the
# mutations prove nothing and must not be reported as if they had.
rc=$(run "$TMP/intact.py")
if [ "$rc" -ne 0 ]; then
    echo "TEETH BROKEN: an unmutated copy of the census exits $rc, not 0."
    echo "Every leg below asserts a non-zero exit and would be satisfied by that alone,"
    echo "so they are NOT run. Nothing has been measured."
    exit 2
fi
echo "  [ok  ] CONTROL/intact copy sweeps clean    rc=0"

# 1. Blind the block finder. This is the shape a broken census takes in practice: it sees
#    nothing and reports a clean corpus. The positive fixtures must catch it.
sed 's|for m in LOOSE_HUMAN.finditer(body):|for m in []:|' "$TOOL" > "$TMP/blind.py"
leg "detector blinded" 2 "$(run "$TMP/blind.py")" "control aborts, sweep skipped"

# 2. Stop stripping HTML comments. The template's commented [REVIEW] example then counts,
#    which would flag nearly every task in the tree — noise that gets a gate ignored.
sed -e 's|    text = COMMENT.sub("", text)|    pass|' \
    -e 's|^    open_at = text.find("<!--")|    open_at = -1|' "$TOOL" > "$TMP/nocomment.py"
leg "comment stripping removed" 2 "$(run "$TMP/nocomment.py")" "template example no longer ignored"

# 3. Replace the live predicate with a local stub. The census would still run and still
#    report zero findings; only the cross-check against `fw review-queue` can see it.
sed 's|^    from web.shared import count_unchecked_human_acs, parse_frontmatter|    from web.shared import parse_frontmatter\n    count_unchecked_human_acs = lambda b: 0|' \
    "$TOOL" > "$TMP/stub.py"
leg "predicate replaced by local stub" 1 "$(run "$TMP/stub.py" --cross-check)" "cross-check reports DISAGREE"

# 4. Same stub, plain sweep — MEASURED, and the measurement corrected the guess. The note
#    here first said the sweep would be blind to a substituted predicate and that only leg 3
#    could see it. Running it says otherwise: rc 2, because the NEG "correctly sectioned"
#    fixture calls that same predicate, and a stub turns a plainly visible AC into an
#    apparently invisible one. So a substituted predicate is caught by two independent nets.
#    Printed as a note rather than asserted, because it is leg 3's job to hold that line.
rc=$(run "$TMP/stub.py")
printf '  [note] %-38s rc=%s  %s\n' "stub, sweep only" "$rc" \
    "second net: the NEG fixture calls the same predicate and the control aborts"

echo
echo "legs: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
