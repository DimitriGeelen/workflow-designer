#!/usr/bin/env bash
# _t826-kind-rule-axes-teeth.sh — do the TWO diagram-kind rules satisfy the T-820
# classification axes, and is the enum a closed set rather than a blanket error?
#
# WHY THIS FILE EXISTS RATHER THAN A CALL TO tools/_t820-rule-axes.sh, which is
# what T-826's AC5 names. That runner is WHOLE-SUITE and reads no argument: T-826
# proved by control that `... E-WORKFLOW-KIND`, `... E-TOPLEVEL-MISSING` and
# `... E-NOT-A-REAL-RULE` produced byte-identical output. Four of its five axes
# are red on rules belonging to T-889/T-890/T-894/T-902/T-909 (OBS-440), so its
# verdict can say nothing about these two rules in either direction. It now
# refuses an argument (leg 13) instead of implying otherwise; the per-rule modes
# it would need are T-927.
#
# So every axis leg here is RULE-SCOPED: it asks whether the axis names OUR rule,
# not whether the axis passes. A grep for absence is worthless without a control
# proving the same grep finds something, so each absence leg (5, 7, 9, 11) is
# paired with a presence control (6, 8, 10, 12) pointed at a rule that IS still
# failing. If those controls ever pass, the absence legs have stopped measuring.
#
# Exit: 0 all legs pass | 1 any leg failed

set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 1
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }

Y=tests/fixtures/invalid/E-WORKFLOW-KIND.yaml
X=tests/fixtures/invalid/E-XML-WORKFLOW-KIND.bpmn

echo "=== T-826: the two diagram-kind rules, rule-scoped against the five T-820 axes ==="

# ---------------------------------------------------------------- the fixtures
# leg 1/2: each fixture is a WITNESS -- it fires its own rule and nothing else.
# "and nothing else" matters: a fixture that also trips three unrelated rules is
# a witness for all of them and pins this rule to their fate.
for pair in "1:$Y:E-WORKFLOW-KIND" "2:$X:E-XML-WORKFLOW-KIND"; do
    n="${pair%%:*}"; rest="${pair#*:}"; f="${rest%%:*}"; rule="${rest##*:}"
    out="$(python3 tools/validate-workflow.py "$f" 2>&1)"; rc=$?
    got="$(printf '%s\n' "$out" | grep -oE '\[[A-Z0-9-]+\]' | tr -d '[]' | sort -u | tr '\n' ' ')"
    if [ "$rc" -ne 0 ] && [ "$got" = "$rule " ]; then
        ok "leg $n: $(basename "$f") fires exactly $rule (rc=$rc)"
    else
        bad "leg $n: $(basename "$f") expected exactly $rule, rc!=0" "rc=$rc findings: ${got:-(none)}"
    fi
done

# leg 3: ABSENCE CONTROL, and it is the load-bearing one. T-213 IW-3, re-derived
# under T-875, says an ABSENT kind is LEGAL and not a warning -- the UNSET default
# is inert. Strip the attribute and both forms must go clean. This also proves
# legs 1/2 test the VALUE and not the mere presence of the key, which is the
# difference between a vocabulary rule and a required-field rule.
sed 's/, kind: overlord//' "$Y" > "$TMP/absent.yaml"
sed 's/ kind="overlord"//' "$X" > "$TMP/absent.bpmn"
a_y="$(python3 tools/validate-workflow.py "$TMP/absent.yaml" 2>&1)"; ay=$?
a_x="$(python3 tools/validate-workflow.py "$TMP/absent.bpmn" 2>&1)"; ax=$?
if [ "$ay" -eq 0 ] && [ "$ax" -eq 0 ]; then
    ok "leg 3: kind absent -> BOTH forms clean (T-213 IW-3: UNSET is inert, not a finding)"
else
    bad "leg 3: absent kind was flagged -- the UNSET default is not inert" \
        "yaml rc=$ay xml rc=$ax"
fi

# leg 4: PRESENCE CONTROL. A legal enum member must also go clean, or leg 1/2
# would be satisfied by a rule that rejects the ATTRIBUTE rather than the VALUE.
sed 's/kind: overlord/kind: documentation/' "$Y" > "$TMP/legal.yaml"
sed 's/kind="overlord"/kind="documentation"/' "$X" > "$TMP/legal.bpmn"
l_y=$(python3 tools/validate-workflow.py "$TMP/legal.yaml" >/dev/null 2>&1; echo $?)
l_x=$(python3 tools/validate-workflow.py "$TMP/legal.bpmn" >/dev/null 2>&1; echo $?)
if [ "$l_y" -eq 0 ] && [ "$l_x" -eq 0 ]; then
    ok "leg 4: kind=documentation -> BOTH forms clean (the enum is CLOSED, not blanket)"
else
    bad "leg 4: a legal enum member was rejected" "yaml rc=$l_y xml rc=$l_x"
fi

# ------------------------------------------------- axis 5: pass reachability
PR="$TMP/pass-reach.txt"
timeout 900 python3 tests/test_check_pass_reachability.py > "$PR" 2>&1
if ! grep -qE "'E-WORKFLOW-KIND'|'E-XML-WORKFLOW-KIND'" "$PR"; then
    ok "leg 5: pass-reachability names NEITHER kind rule as unwitnessed"
else
    bad "leg 5: a kind rule is still unwitnessed" "$(grep -m1 'fire on NO corpus' "$PR")"
fi
if grep -q "'E-META-AUTHORITY'" "$PR"; then
    ok "leg 6: CONTROL -- the same grep DOES find E-META-AUTHORITY (T-902's, still unwitnessed), so leg 5 can fail"
else
    bad "leg 6: CONTROL BROKEN -- leg 5's grep finds nothing at all, so its silence proves nothing" \
        "if T-902's rule gained a fixture, repoint this control at another still-failing rule"
fi

# ------------------------------------------------- axis 3: anchorability
AN="$TMP/anchor.txt"
timeout 900 python3 tests/test_finding_anchorability.py > "$AN" 2>&1
if ! grep -q "E-XML-WORKFLOW-KIND" "$AN"; then
    ok "leg 7: anchorability names E-XML-WORKFLOW-KIND nowhere (classified, and not in disagreement)"
else
    bad "leg 7: anchorability still names E-XML-WORKFLOW-KIND" "$(grep -m1 'E-XML-WORKFLOW-KIND' "$AN")"
fi
if grep -q "E-XML-META-AUTHORITY" "$AN"; then
    ok "leg 8: CONTROL -- the same grep DOES find E-XML-META-AUTHORITY (T-902's, still unclassified), so leg 7 can fail"
else
    bad "leg 8: CONTROL BROKEN -- leg 7's grep finds nothing, so its silence proves nothing"
fi

# ------------------------------------------- axis 4: cross-form agreement
CF="$TMP/crossform.txt"
timeout 900 python3 tests/test_harness_cross_form_agreement.py > "$CF" 2>&1
if ! grep -qE "NEW DISAGREEMENT E-WORKFLOW-KIND|E-WORKFLOW-KIND is PAIRED" "$CF"; then
    ok "leg 9: cross-form reports E-WORKFLOW-KIND neither undeclared nor absent from PAIRS"
else
    bad "leg 9: cross-form still faults E-WORKFLOW-KIND" "$(grep -m1 'E-WORKFLOW-KIND' "$CF")"
fi
if grep -q "NEW DISAGREEMENT E-NODE-LANE" "$CF"; then
    ok "leg 10: CONTROL -- the same grep DOES find E-NODE-LANE's undeclared disagreement (T-909's), so leg 9 can fail"
else
    bad "leg 10: CONTROL BROKEN -- leg 9's grep finds nothing, so its silence proves nothing"
fi

# --------------------------------- the DOC-META class, measured not declared
# axis 3 returns early on the four rules T-889/T-890/T-894/T-902 left
# unclassified, so its "declared vs observed" stage never runs and the DOC-META
# claim is unverified by the axis itself. This leg runs that stage by stubbing
# ONLY those four foreign rows -- stated plainly, because a stub that is not
# named is a lie -- and asserts OUR row agrees with what documents resolve to.
run_anchor_stage3() {   # $1 = class to declare for E-XML-WORKFLOW-KIND
    python3 - "$1" <<'PY' 2>&1
import re, sys, os, importlib.util
cls = sys.argv[1]
root = os.getcwd()
src = open("tests/test_finding_anchorability.py", encoding="utf-8").read()
src = src.replace('ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))',
                  'ROOT = %r' % root)
# the four foreign unclassified rows, and the one row T-909 left stale
src = src.replace('    "E-XML-WORKFLOW-KIND":       "DOC-META",',
                  '    "E-XML-WORKFLOW-KIND":       %r,\n'
                  '    "E-XML-LANE-AUTHORING-DEFAULT": "LANE",\n'
                  '    "E-XML-META-AUTHORITY":      "NODE",\n'
                  '    "E-XML-NODE-UNASSIGNED":     "NODE",\n'
                  '    "W-XML-AUTHORITY-DEFAULT-MISMATCH": "LANE",' % cls)
src = src.replace('    "W-XML-NODE-UNASSIGNED":     "NODE",\n', '')
spec = importlib.util.spec_from_loader("_anchor_probe", loader=None)
mod = importlib.util.module_from_spec(spec)
mod.__file__ = os.path.join(root, "tests", "_anchor_probe.py")
exec(compile(src, mod.__file__, "exec"), mod.__dict__)
mod.main()
PY
}
S3="$(run_anchor_stage3 DOC-META)"
if ! printf '%s\n' "$S3" | grep -q "E-XML-WORKFLOW-KIND"; then
    ok "leg 11: with only the four foreign rows stubbed, DOC-META AGREES with what documents resolve to"
else
    bad "leg 11: DOC-META disagrees with the documents" "$(printf '%s\n' "$S3" | grep -m1 'E-XML-WORKFLOW-KIND')"
fi
S3W="$(run_anchor_stage3 DOC)"
if printf '%s\n' "$S3W" | grep -q "E-XML-WORKFLOW-KIND *declared DOC"; then
    ok "leg 12: CONTROL -- declaring it DOC instead is caught as a disagreement, so leg 11 can fail"
else
    bad "leg 12: CONTROL BROKEN -- a deliberately wrong class was NOT caught, so leg 11 proves nothing" \
        "$(printf '%s\n' "$S3W" | tail -3)"
fi

# ------------------------------------------- the runner, and the erasure pin
bash tools/_t820-rule-axes.sh E-WORKFLOW-KIND >/dev/null 2>"$TMP/refusal.txt"; rr=$?
if [ "$rr" -eq 2 ] && grep -q "takes no arguments" "$TMP/refusal.txt" \
   && grep -q "E-WORKFLOW-KIND" "$TMP/refusal.txt"; then
    ok "leg 13: _t820-rule-axes.sh REFUSES a rule argument (rc=2) and names the argument it got"
else
    bad "leg 13: the whole-suite runner still accepts a rule id and returns a verdict about other rules" "rc=$rr"
fi

# leg 14: the ERASURE pin. tools/yaml-to-bpmn.py emits no <aef:workflowMeta>, so
# the XML rule cannot be reached through the bridge -- which is why the cross-form
# entry is BRIDGE_REPAIRED/ERASURE and why the .bpmn fixture is hand-authored.
# Pinned so that T-925 fixing the bridge FAILS here and forces that entry to be
# re-read rather than quietly outlived.
python3 tools/yaml-to-bpmn.py "$Y" > "$TMP/bridged.bpmn" 2>/dev/null
wm="$(grep -c "workflowMeta" "$TMP/bridged.bpmn")"
xb=$(python3 tools/validate-workflow.py "$TMP/bridged.bpmn" >/dev/null 2>&1; echo $?)
if [ "$wm" -eq 0 ] && [ "$xb" -eq 0 ]; then
    ok "leg 14: the bridge emits 0 workflowMeta and the bridged doc is clean -- ERASURE, as declared (T-925)"
else
    bad "leg 14: the bridge's workflowMeta behaviour CHANGED (occurrences=$wm, xml rc=$xb)" \
        "re-read the E-WORKFLOW-KIND entry in BRIDGE_REPAIRED: if the carrier now survives, this is a real pair to compare, not an erasure"
fi

# leg 15: a COUPLING check, NOT a round-trip proof, and the distinction is the
# point. T-886 closed the aef:workflowMeta round-trip hole with a denominator
# DERIVED from the emitter rather than hand-listed (deriveEmittedAttrs, T-910's
# shared version), so `kind` is covered by construction the moment the emitter
# pushes it -- there is no list for anyone to forget. This leg asserts exactly
# that coupling holds: the emitter pushes kind into `wmAttrs`, and the guard's
# derivation reads `wmAttrs`. It does NOT re-run the browser guard, and does not
# claim to: byte-identity is T-886's delivered and separately verified property.
pushes_kind=$(grep -c 'wmAttrs.push(`kind=' src/aef-workflow-designer.html)
reads_wmattrs=$(grep -c 'wmAttrs.join' tools/_roundtrip-serialization-cdp.mjs)
absent=$(grep -c 'wmAttrs.push(`zzznotanattr=' src/aef-workflow-designer.html)
if [ "$pushes_kind" -ge 1 ] && [ "$reads_wmattrs" -ge 1 ] && [ "$absent" -eq 0 ]; then
    ok "leg 15: COUPLING -- emitter pushes kind into wmAttrs and the guard derives from wmAttrs (control: an invented attr name scores 0)"
else
    bad "leg 15: the kind attribute is no longer coupled to T-886's derived denominator" \
        "emitter pushes=$pushes_kind guard reads wmAttrs=$reads_wmattrs control=$absent"
fi

echo
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
