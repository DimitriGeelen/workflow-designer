#!/usr/bin/env bash
# T-301 — does the id/stem invariant check actually BITE?
#
# The GO asked for this by name: "a fixture that synthesises a divergent card and requires
# it to be caught". Without it the check is only ever observed passing on a corpus that
# currently satisfies it, which is indistinguishable from a check that cannot fail.
#
# It also pins the DERIVATION, which is the real subject. The first cut of the checker
# guessed the aef namespace wrong, found no authored id on any document, fell through to
# the procId leg for all 127, and reported "127 of 127 divergent" — a 100% failure rate on
# a corpus measured at 0%. An instrument that cannot be wrong in a recognisable way is the
# thing this project keeps getting burned by, so the legs below assert the derivation
# itself, not just the verdict.
#
# Exit 0 = all legs pass. Exit 3 = could not measure.
set -uo pipefail

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$PROJ/tools/_t301-id-stem-invariant.py"
[ -f "$CHECK" ] || { echo "COULD-NOT-MEASURE: $CHECK missing" >&2; exit 3; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

AEF='http://anchorpoint.framework/aef/extensions'
BPMN='http://www.omg.org/spec/BPMN/20100524/MODEL'

# doc <path> <proc-id> <proc-name> [authored-meta-id]
doc() {
    local path="$1" pid="$2" pname="$3" meta="${4:-}"
    mkdir -p "$(dirname "$path")"
    {
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        echo "<bpmn:definitions xmlns:bpmn=\"$BPMN\" xmlns:aef=\"$AEF\" id=\"Definitions_x\">"
        echo "  <bpmn:process id=\"$pid\" name=\"$pname\" isExecutable=\"true\">"
        if [ -n "$meta" ]; then
            echo "    <bpmn:extensionElements>"
            echo "      <aef:workflowMeta id=\"$meta\" version=\"1\"/>"
            echo "    </bpmn:extensionElements>"
        fi
        echo "  </bpmn:process>"
        echo "</bpmn:definitions>"
    } > "$path"
}

# Build a fixture project root. It deliberately creates ONLY tools/ — doc() makes the
# directories it needs. A corpus root that does not exist is out of scope and is skipped;
# a root that EXISTS and is empty is a shrunk scope and must be reported. The first cut
# of this helper pre-created all four roots, so every fixture tripped the empty-root leg
# and the no-op control failed. The check was right; the fixture was wrong.
mkroot() {
    local r="$TMP/$1"; shift
    mkdir -p "$r/tools"
    echo "$r"
}

run() {  # run <root> -> rc, output in $TMP/out
    T301_PROJ="$1" python3 "$CHECK" > "$TMP/out" 2>&1
    echo $?
}

echo "=== T-301: teeth on the id/stem invariant check ==="
echo

# --- leg 0: NO-OP CONTROL — an aligned corpus must pass -----------------------
R=$(mkroot clean)
doc "$R/examples/aef-processes/rendered/alpha.bpmn" "Process_alpha" "Alpha" "alpha"
doc "$R/examples/aef-processes/rendered/beta.bpmn"  "Process_beta"  "Beta"  "beta"
rc=$(run "$R")
if [ "$rc" -eq 0 ] && grep -q 'invariant holds' "$TMP/out"; then
    ok "no-op control: an aligned corpus passes (rc=0)"
else
    bad "PRECONDITION FAILED — aligned corpus does not pass (rc=$rc); every leg below is vacuous"
    sed -n '1,25p' "$TMP/out"
    echo; echo "=== $PASS passed, $FAIL failed ==="; exit 1
fi

# --- leg 1: THE LEG THE GO ASKED FOR — a divergent card is caught -------------
R=$(mkroot divergent)
doc "$R/examples/aef-processes/rendered/alpha.bpmn" "Process_alpha" "Alpha" "alpha"
# stem says 'review-copy', bytes say 'original' — the t101-review-audit-process shape
doc "$R/examples/aef-processes/rendered/review-copy.bpmn" "Process_original" "Orig" "original"
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'review-copy' "$TMP/out" && grep -q 'original' "$TMP/out"; then
    ok "a divergent card fails the check AND both ids are named"
else
    bad "divergent card not caught (rc=$rc) — the check cannot fail"
fi

# --- leg 2: the .editor-versions population, keyed by DIRECTORY ----------------
# This is the population the reported instance actually lived in, and the one the first
# T-301 pass did not measure.
R=$(mkroot storecard)
doc "$R/examples/aef-processes/rendered/alpha.bpmn" "Process_alpha" "Alpha" "alpha"
doc "$R/.editor-versions/t101-review-audit-process/v1.bpmn" "Process_audit" "Audit" "audit-process"
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 't101-review-audit-process' "$TMP/out"; then
    ok "a store card whose DIRECTORY name differs from its bytes is caught"
else
    bad "store-card divergence missed (rc=$rc) — the directory-keyed population is unguarded"
fi

# --- leg 3: DERIVATION — an authored id is used UNSANITIZED --------------------
# The authored id is machine identity and already round-trips; sanitizing it would move
# bytes on every document carrying the element. So a mixed-case authored id must be
# compared AS WRITTEN, which means a stem matching it exactly passes...
R=$(mkroot authored-raw)
doc "$R/examples/aef-processes/rendered/MixedCase.bpmn" "Process_x" "X" "MixedCase"
rc=$(run "$R")
if [ "$rc" -eq 0 ]; then
    ok "authored id is compared unsanitized (MixedCase stem == MixedCase id)"
else
    bad "authored id appears to be sanitized — a lowercasing check would move corpus bytes (rc=$rc)"
fi

# ...and a lowercase stem against a MixedCase authored id must DIVERGE.
R=$(mkroot authored-raw2)
doc "$R/examples/aef-processes/rendered/mixedcase.bpmn" "Process_x" "X" "MixedCase"
rc=$(run "$R")
if [ "$rc" -ne 0 ]; then
    ok "...and the same id lowercased in the stem is a divergence, not a match"
else
    bad "lowercase stem matched a MixedCase authored id — the comparison is case-folding (rc=$rc)"
fi

# --- leg 4: DERIVATION — procId is sanitized, and comes BEFORE procName -------
# T-563: the chain is authored || sanitize(procId) || sanitize(procName). A document with
# no authored id whose procId sanitizes to the stem must PASS...
R=$(mkroot procid)
doc "$R/examples/aef-processes/rendered/pool_customer_refund.bpmn" "Pool_customer_refund" "customer-refund"
rc=$(run "$R")
if [ "$rc" -eq 0 ]; then
    ok "procId leg sanitizes (Pool_customer_refund -> pool_customer_refund)"
else
    bad "procId sanitization wrong (rc=$rc)"
fi

# ...and the SAME document under the stem matching its procNAME must FAIL, which is
# exactly the customer-refund defect and proves procId wins over procName.
R=$(mkroot procname)
doc "$R/examples/aef-processes/rendered/customer-refund.bpmn" "Pool_customer_refund" "customer-refund"
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'pool_customer_refund' "$TMP/out"; then
    ok "procId beats procName — the live customer-refund defect reproduces from scratch"
else
    bad "procName appears to win over procId; the chain does not match src:11210 (rc=$rc)"
fi

# --- leg 5: an empty population is NOT a pass ---------------------------------
R=$(mkroot empty)
rc=$(run "$R")
if [ "$rc" -eq 3 ] && grep -q 'COULD-NOT-MEASURE' "$TMP/out"; then
    ok "a corpus with no documents is rc=3 COULD-NOT-MEASURE, not a pass"
else
    bad "empty corpus produced rc=$rc; an empty walk must never read as 'invariant holds'"
fi

# --- leg 6: a partially-empty corpus is reported, not silently skipped --------
# One populated root plus three empty ones. The populated root is fine, so a check that
# ignored empty roots would print green while asserting nothing about three quarters of
# its stated scope.
R=$(mkroot partial)
doc "$R/examples/aef-processes/rendered/alpha.bpmn" "Process_alpha" "Alpha" "alpha"
# these two EXIST but hold nothing — a shrunk scope, which is the case under test
mkdir -p "$R/build/gallery/rendered" "$R/.editor-versions"
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -q 'NOT EVALUATED' "$TMP/out"; then
    ok "an empty root is reported as NOT EVALUATED and fails, rather than being skipped"
else
    bad "empty roots silently skipped (rc=$rc) — scope shrinks without anyone being told"
fi

# --- leg 7: the baseline must not silently outlive its subject ----------------
# An entry for a divergence that no longer exists is a stale exemption; it has to be
# reported, or the ratchet becomes a permanent hole.
R=$(mkroot stale)
doc "$R/examples/aef-processes/rendered/alpha.bpmn" "Process_alpha" "Alpha" "alpha"
printf 'ghost-card | ghost-doc | an exemption whose subject is gone\n' \
    > "$R/tools/_t301-known-divergences.txt"
rc=$(run "$R")
if [ "$rc" -ne 0 ] && grep -qi 'no longer diverge' "$TMP/out"; then
    ok "a baseline entry whose divergence is gone is reported as stale"
else
    bad "stale baseline entry carried silently (rc=$rc) — the ratchet has a permanent hole"
fi

# --- leg 8: a recorded divergence is allowed, and still NAMED ------------------
R=$(mkroot recorded)
doc "$R/examples/aef-processes/rendered/alpha.bpmn" "Process_alpha" "Alpha" "alpha"
doc "$R/examples/aef-processes/rendered/review-copy.bpmn" "Process_original" "Orig" "original"
printf 'review-copy | original | recorded for this fixture\n' \
    > "$R/tools/_t301-known-divergences.txt"
rc=$(run "$R")
if [ "$rc" -eq 0 ] && grep -q 'KNOWN' "$TMP/out" && grep -q 'review-copy' "$TMP/out"; then
    ok "a recorded divergence passes but is printed every run"
else
    bad "recorded divergence either failed or went unmentioned (rc=$rc)"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
