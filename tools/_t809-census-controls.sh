#!/usr/bin/env bash
# _t809-census-controls.sh — does the frozen-meta census actually work?
#
# T-809. The census (tools/_t809-frozen-meta-census.py) exists because
# test_mapping_standard_conformance.py reports OK while comparing two Python lists and
# never opening a document. Replacing one unexercised check with another would be no gain
# at all, so this exercises it — in throwaway copies, never the live corpus.
#
# FOUR BRANCHES. The first two are the pair that matters:
#
#   A  coverage FALLS   -> census must FAIL        (the ratchet has teeth)
#   B  coverage RISES   -> census must SEE it      (the ratchet is not vacuous)
#   C  corpus EMPTY     -> census must FAIL        (cannot-measure is not a pass)
#   D  corpus UNTOUCHED -> census must PASS        (so A/C mean something)
#
# WHY B EXISTS, and it is the whole reason this file is separate rather than a one-liner.
# A census that counted NOTHING — wrong namespace, wrong element list, a typo in the key
# names — would pass A and C for free, and would sit in the suite looking like a guard
# forever. B is the anti-vacuity leg: it proves the census can still SEE a key.
#
# B ALSO CAUGHT ITS OWN FIRST DRAFT, which is why its stimulus is fussy. The first version
# injected horizon into the first <aef:meta> in a file; that landed on a <bpmn:startEvent>,
# which is not task-like, so the census correctly ignored it and the control failed. The
# census was right and the STIMULUS was wrong — PL-206: "a control that CAN fail is still
# worthless if its stimulus was built so it never fires." The injection is therefore
# anchored to a task-like element, and the branch fails loudly if it cannot find one.
#
# Exit: 0 all four branches behaved | 1 a branch disagreed | 3 could not set up

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CENSUS="$REPO/tools/_t809-frozen-meta-census.py"
BASELINE="$REPO/tools/_t809-frozen-meta-baseline.txt"
CORPUS="$REPO/examples/aef-processes/rendered"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
cannot(){ printf 'COULD-NOT-MEASURE: %s\n' "$1" >&2; exit 3; }

[ -f "$CENSUS" ]   || cannot "census not found: $CENSUS"
[ -f "$BASELINE" ] || cannot "baseline not found: $BASELINE"
compgen -G "$CORPUS/*.bpmn" >/dev/null || cannot "no corpus documents under $CORPUS"

# Fresh copy per branch. Each branch mutates its own; the live tree is never written to.
mk() {
    SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/t809-ctl-XXXXXX")"
    mkdir -p "$SANDBOX/examples/aef-processes/rendered" "$SANDBOX/tools"
    cp "$CORPUS"/*.bpmn "$SANDBOX/examples/aef-processes/rendered/" 2>/dev/null
    cp "$CENSUS" "$BASELINE" "$SANDBOX/tools/"
}
run_census() { T809_REPO_ROOT="$SANDBOX" python3 "$SANDBOX/tools/_t809-frozen-meta-census.py" 2>&1; }
cleanup() { [ -n "${SANDBOX:-}" ] && rm -rf "$SANDBOX"; }
trap cleanup EXIT

echo "=== T-809 census controls ==="

# --- D: untouched copy must PASS. Run first: if the baseline branch is broken, every
# other verdict below is meaningless and should not be reported as evidence.
mk
if run_census >/dev/null 2>&1; then
    ok "D untouched corpus -> census PASSES (baseline is live)"
else
    bad "D untouched corpus should PASS" "baseline branch broken — A/B/C prove nothing; stopping"
    cleanup; echo; echo "PASS=$PASS FAIL=$FAIL"; exit 1
fi
cleanup

# --- A: strip one frozen key -> coverage falls -> must FAIL.
mk
_f="$(grep -l 'tier=' "$SANDBOX/examples/aef-processes/rendered/"*.bpmn 2>/dev/null | head -1)"
if [ -z "$_f" ]; then
    bad "A setup" "no corpus file carries a tier= attribute to strip"
else
    perl -0pi -e 's/ tier="[^"]*"//' -- "$_f"
    if run_census >/dev/null 2>&1; then
        bad "A stripped key should FAIL" "census still exited 0 — the ratchet is inert"
    else
        ok "A coverage fell -> census FAILS"
    fi
fi
cleanup

# --- B: add a frozen key to a TASK-LIKE node -> census must see the count rise.
mk
_injected="$(python3 - "$SANDBOX/examples/aef-processes/rendered" <<'PY'
import glob, re, sys
TASKLIKE = ["task","userTask","serviceTask","scriptTask","manualTask",
            "businessRuleTask","sendTask","receiveTask","callActivity","subProcess"]
# Anchored to a task-like OPEN TAG followed by a meta element: the census counts per
# task-like node, so injecting anywhere else is a stimulus that cannot fire.
pat = re.compile(r'(<bpmn:(?:' + '|'.join(TASKLIKE) + r')\b[^>]*>.*?)(<aef:meta )', re.S)
for f in sorted(glob.glob(sys.argv[1] + "/*.bpmn")):
    s = open(f).read()
    s2, n = pat.subn(lambda m: m.group(1) + '<aef:meta horizon="now" ', s, count=1)
    if n:
        open(f, "w").write(s2)
        print(f.split("/")[-1])
        sys.exit(0)
sys.exit(1)
PY
)"
if [ -z "$_injected" ]; then
    bad "B setup" "could not find a task-like node carrying <aef:meta> to inject into"
else
    if run_census | grep -q 'horizon: 0 -> 1'; then
        ok "B coverage rose -> census SEES it (not vacuous; injected into $_injected)"
    else
        bad "B added key should be COUNTED" \
            "census did not report horizon 0 -> 1 after injection into $_injected — it may be counting nothing"
    fi
fi
cleanup

# --- C: empty corpus must FAIL rather than report clean.
mk
rm -f "$SANDBOX/examples/aef-processes/rendered/"*.bpmn
if run_census >/dev/null 2>&1; then
    bad "C empty corpus should FAIL" "census reported clean over zero documents"
else
    ok "C empty corpus -> census FAILS (cannot-measure is not a pass)"
fi
cleanup

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
