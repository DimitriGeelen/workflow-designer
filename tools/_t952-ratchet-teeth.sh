#!/usr/bin/env bash
# T-952 — does the bridge-suite ratchet bite, and does it refuse when it cannot measure?
#
# Driven by stubbed history files, never by waiting ~16 minutes for the real suite. The leg
# that matters most is the KILLED-RUN one: the real history contains rc=143 rows recording
# 16 and 12 failures from partial sweeps, and a ratchet that read the newest row would have
# announced a twenty-failure improvement against a floor of 32.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.
set -uo pipefail

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RATCHET="$PROJ/tools/_t952-bridge-suite-ratchet.py"
[ -f "$RATCHET" ] || { echo "COULD-NOT-MEASURE: $RATCHET missing" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
OLD="$(date -u -d '5 days ago' +%Y-%m-%dT%H:%M:%SZ)"

mkfix() {  # mkfix <name> <baseline-content> ; rows on stdin
    local r="$TMP/$1"
    mkdir -p "$r/tests" "$r/tools"
    printf '%s\n' "$2" > "$r/tools/_t952-bridge-baseline.txt"
    cat > "$r/tests/.run-history.tsv"
    echo "$r"
}

run() { T952_PROJ="$1" python3 "$RATCHET" > "$TMP/out" 2>&1; echo $?; }

echo "=== T-952: teeth on the bridge-suite ratchet ==="
echo

# --- leg 0: NO-OP CONTROL — floor held exactly --------------------------------
R=$(mkfix held "32 | control" <<EOF
$NOW	122	32	1	999	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -eq 0 ] && grep -q 'floor held at exactly 32' "$TMP/out"; then
    ok "no-op control: floor held at exactly 32 passes"
else
    bad "PRECONDITION FAILED — an exactly-at-floor run does not pass (rc=$rc); every leg below is vacuous"
    sed -n '1,20p' "$TMP/out"; echo; echo "=== $PASS passed, $FAIL failed ==="; exit 1
fi

# --- leg 1: a RISE fails ------------------------------------------------------
R=$(mkfix rose "32 | control" <<EOF
$NOW	119	35	1	999	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'ROSE' "$TMP/out" && grep -q '+3' "$TMP/out"; then
    ok "a rise from 32 to 35 fails and names the delta"
else
    bad "a rise did not fail (rc=$rc) — the ratchet has no teeth"
fi

# --- leg 2: a FALL passes, changes nothing, and says the floor can drop -------
R=$(mkfix fell "32 | control" <<EOF
$NOW	140	14	1	999	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -eq 0 ] && grep -qi 'can be lowered' "$TMP/out"; then
    ok "a fall passes and reports the floor can be lowered, without moving it"
else
    bad "a fall mishandled (rc=$rc) — it must pass AND not silently tighten"
fi

# --- leg 3: THE ONE THAT MATTERS — a killed run is not an improvement ---------
# Newest row is a SIGTERM'd partial sweep showing 12 failures against a floor of 32.
# Reading the newest row would report a 20-failure improvement. The last COMPLETED row
# is the 35 above it, which must fail.
R=$(mkfix killed "32 | control" <<EOF
2026-09-30T09:00:00Z	119	35	1	999	abc12345
$NOW	64	12	143	118	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'ROSE' "$TMP/out" && grep -q 'did not complete' "$TMP/out"; then
    ok "a killed (rc=143) partial sweep is discarded, not read as a 20-failure improvement"
else
    bad "killed run influenced the verdict (rc=$rc) — a partial sweep can pass as progress"
fi

# --- leg 4: a history with ONLY killed runs cannot measure -------------------
R=$(mkfix allkilled "32 | control" <<EOF
$NOW	73	16	143	321	abc12345
$NOW	64	12	143	118	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'no COMPLETED run' "$TMP/out"; then
    ok "a history of only killed runs refuses, rather than reporting the lowest count"
else
    bad "all-killed history produced rc=$rc — CANNOT MEASURE must never read as a pass"
fi

# --- leg 5: staleness fails ---------------------------------------------------
R=$(mkfix stale "32 | control" <<EOF
$OLD	122	32	1	999	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -qi 'past the 48h limit' "$TMP/out"; then
    ok "a 5-day-old run fails on staleness — a floor is not held by an untaken measurement"
else
    bad "stale history passed (rc=$rc) — a dead schedule would read as healthy"
fi

# --- leg 6: a missing history refuses ----------------------------------------
R="$TMP/nohist"; mkdir -p "$R/tools" "$R/tests"
printf '32 | control\n' > "$R/tools/_t952-bridge-baseline.txt"
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'never run' "$TMP/out"; then
    ok "a missing history refuses and says so — not zero failures"
else
    bad "missing history produced rc=$rc"
fi

# --- leg 7: a missing or garbled baseline refuses ----------------------------
R=$(mkfix nobaseline "# only a comment, no number" <<EOF
$NOW	122	32	1	999	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'no usable baseline' "$TMP/out"; then
    ok "a baseline with no number refuses rather than defaulting to something convenient"
else
    bad "unusable baseline produced rc=$rc — a default floor is a floor nobody chose"
fi

# --- leg 8: a malformed row is reported, not silently dropped ----------------
R=$(mkfix malformed "32 | control" <<EOF
this-is-not-a-row
$NOW	122	32	1	999	abc12345
EOF
)
rc=$(run "$R")
if [ "$rc" -eq 0 ] && grep -q 'malformed' "$TMP/out"; then
    ok "a malformed row is named in the output while the verdict still stands"
else
    bad "malformed row silently dropped (rc=$rc) — history looks healthier than it is"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
