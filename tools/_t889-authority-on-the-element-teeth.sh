#!/usr/bin/env bash
# _t889-authority-on-the-element-teeth.sh — prove the T-889 controls can actually FAIL.
#
# WHY THIS EXISTS. T-889 implements T-888 ruling clause 2: the element carries its
# authority, read DIRECTLY — never by lane membership, never by document order. Every
# claim below is a green check somewhere else; a green nobody has watched go red is not
# evidence. This is the watching.
#
# The CONTROL SET runs first and must pass before any mutant is judged. If a mutation
# does not actually apply (an anchor moved), this script prints MUTATION SETUP BROKEN and
# FAILS, rather than reading "the check didn't fire" as a clean kill (T-866 pattern).
#
# Mutants operate on COPIES in a temp tree. No tracked file is ever written.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAL="$REPO/tools/validate-workflow.py"
HTML="$REPO/src/aef-workflow-designer.html"
HARNESS="$REPO/tools/_roundtrip-serialization-cdp.mjs"
FX="$REPO/tests/fixtures/t889-authority"
MUT=0; [ "${1:-}" = "--mutation" ] && MUT=1
fail=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

for f in "$VAL" "$HTML" "$HARNESS" "$FX/t889-element-authority.bpmn" \
         "$FX/bad-vocabulary.bpmn" "$FX/order-A.bpmn" "$FX/order-B.bpmn"; do
  [ -e "$f" ] || { echo "FAIL  missing input: $f"; exit 1; }
done

# rule ids only — message wording is not the contract, the verdict is
# NOTE the shape (L-387, and the T-889 Evolution entry that records walking into it):
# `python3 ... | grep -q` under `set -o pipefail` returns the VALIDATOR's exit code, and
# this validator exits 2 on INVALID — so a matched pattern still reads as false. Capture
# first, then grep the capture. Output here is a few hundred bytes, well under the 64KB
# pipe buffer that makes the capture form itself unsafe.
ids() { local o; o="$(python3 "$1" "$2" 2>&1)"; printf '%s\n' "$o" | grep -oE '\[[A-Z0-9-]+\]' | sort | tr '\n' ' '; }
has() { local o; o="$(python3 "$1" "$2" 2>&1)"; printf '%s\n' "$o" | grep -q "$3"; }

echo "== CONTROL SET =="

# C1 — the element-level vocabulary gate fires on a value outside AUTHORITIES.
if has "$VAL" "$FX/bad-vocabulary.bpmn" "E-XML-META-AUTHORITY"; then
  echo "PASS  C1 vocabulary-gate-fires        (E-XML-META-AUTHORITY on authority=\"overlord\")"
else
  echo "FAIL  C1 vocabulary-gate-fires        (no E-XML-META-AUTHORITY)"; fail=1
fi

# C2 — clause 2 half (a): the element's OWN value is read, not its lane's.
# Fixture: lane says sovereignty, element says initiative, node is an inception subProcess.
# Element-wins => O-3 fires. Lane-wins => silent. One binary observable.
if has "$VAL" "$FX/t889-element-authority.bpmn" "E-INCEPTION-NOT-SOVEREIGN" \
   && has "$VAL" "$FX/t889-element-authority.bpmn" "source: the element"; then
  echo "PASS  C2 not-lane-membership          (O-3 fires reading the element's own value)"
else
  echo "FAIL  C2 not-lane-membership          (element value not read, or source not named)"; fail=1
fi

# C3 — clause 2 half (b): same document, laneSet order swapped, same verdict.
a="$(ids "$VAL" "$FX/order-A.bpmn")"; b="$(ids "$VAL" "$FX/order-B.bpmn")"
if [ "$a" = "$b" ]; then
  echo "PASS  C3 not-document-order           (identical rule ids across laneSet order)"
else
  echo "FAIL  C3 not-document-order           (A=[$a] B=[$b])"; fail=1
fi

# C4 — C3 IS NOT VACUOUS. A pass on C3 only means something if document order COULD have
# changed the answer. Build a lane-reading mutant of the validator and require the pair to
# DIFFER under it. Without this, C3 passes on a fixture where order is irrelevant — which
# is exactly what the first draft of this control did (measured, T-889 Evolution).
python3 - "$VAL" "$TMP/lane-reading.py" <<'PY' || { echo "FAIL  C4 MUTATION SETUP BROKEN (could not build lane-reading mutant)"; exit 1; }
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src, encoding='utf-8').read()
needle = """            authority = (
                elem_authority
                if elem_authority is not None
                else node_authority.get(nid)
            )"""
if s.count(needle) != 1:
    sys.exit(1)
open(dst, 'w', encoding='utf-8').write(
    s.replace(needle, "            authority = node_authority.get(nid)"))
PY
la="$(ids "$TMP/lane-reading.py" "$FX/order-A.bpmn")"; lb="$(ids "$TMP/lane-reading.py" "$FX/order-B.bpmn")"
if [ "$la" != "$lb" ]; then
  echo "PASS  C4 order-control-has-teeth      (lane-reading DOES flip: A=[$la] B=[$lb])"
else
  echo "FAIL  C4 order-control-has-teeth      (order changes nothing even under lane-reading — C3 is vacuous)"; fail=1
fi

# C5/C6 — the two static halves of "first-class, not carriage".
if grep -q "'authority'\]" "$HTML"; then
  echo "PASS  C5 authority-in-metaKeys        (emitter projects it as a named key)"
else
  echo "FAIL  C5 authority-in-metaKeys"; fail=1
fi
if grep -qE "^  (serviceTask|userTask|scriptTask|subProcess):\s+\['authority'," "$HTML"; then
  echo "PASS  C6 authority-offered-in-panel   (AEF_FIELDS exposes the writer)"
else
  echo "FAIL  C6 authority-offered-in-panel"; fail=1
fi

[ "$MUT" -eq 1 ] || { echo; [ "$fail" -eq 0 ] && echo "control set passed (run with --mutation for the kills)" || echo "CONTROL SET FAILED"; exit "$fail"; }

echo
echo "== MUTATION SET =="
mkdir -p "$TMP/m1/tools" "$TMP/m1/src"
# The harness imports ./_cdp-attach.mjs; copy every tools/*.mjs so the mutant tree is a
# working copy rather than a broken one whose import error would masquerade as a kill.
cp "$REPO"/tools/*.mjs "$REPO"/tools/*.py "$TMP/m1/tools/"; cp "$HTML" "$TMP/m1/src/"

# M1 — delete the editor's authority key from the emitter's metaKeys. The round-trip
# guard derives its denominator FROM the emitter (T-886), so it must notice by itself.
python3 - "$TMP/m1/src/aef-workflow-designer.html" <<'PY' || { echo "FAIL  M1 MUTATION SETUP BROKEN (metaKeys anchor moved)"; exit 1; }
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
if s.count("    'authority'];") != 1:
    sys.exit(1)
open(p, 'w', encoding='utf-8').write(s.replace("    'authority'];", "    ];"))
PY
# SETUP CONTROL for M1: the UNMUTATED copy in this same temp tree must reach a clean
# denominator first. Without this, any breakage in the copy (a missing import, a missing
# fixtures dir — both hit during T-889's own build) produces a non-zero exit that would
# read as a kill. The mutant must fail for ITS reason, not for the tree's.
mkdir -p "$TMP/m0/tools" "$TMP/m0/src"
cp "$REPO"/tools/*.mjs "$REPO"/tools/*.py "$TMP/m0/tools/"; cp "$HTML" "$TMP/m0/src/"
m0rc=0
( cd "$TMP/m0" && ROUNDTRIP_FIXTURES_DIR="$REPO/tests/fixtures/aef-bpmn" \
    timeout 300 node tools/_roundtrip-serialization-cdp.mjs ) > "$TMP/m0.json" 2>&1 || m0rc=$?
# Require a clean EXIT, not merely the absence of one error string. The first draft of
# this control grepped only for "denominator_failed" — and a copy that died on a missing
# sidecar sailed through it, which is the exact false-green the control exists to stop.
if [ "$m0rc" -ne 0 ]; then
  echo "FAIL  M1 MUTATION SETUP BROKEN        (unmutated copy does not pass: rc=$m0rc)"
  head -c 300 "$TMP/m0.json"; echo; exit 1
fi

m1out="$TMP/m1.json"; m1rc=0
( cd "$TMP/m1" && ROUNDTRIP_FIXTURES_DIR="$REPO/tests/fixtures/aef-bpmn" \
    timeout 300 node tools/_roundtrip-serialization-cdp.mjs ) > "$m1out" 2>&1 || m1rc=$?
if [ "$m1rc" -ne 0 ] && grep -q "does not project" "$m1out"; then
  echo "PASS  M1 emitter-writer-deleted       (guard red: KEYSPEC covers a key the emitter dropped)"
else
  echo "FAIL  M1 emitter-writer-deleted       (rc=$m1rc — guard did not notice the dropped key)"
  head -c 300 "$m1out"; echo; fail=1
fi

# M2 — delete the validator's ELEMENT-level read (fall back to lane membership).
# Killed by C2: the inception fixture must stop firing O-3.
if has "$TMP/lane-reading.py" "$FX/t889-element-authority.bpmn" "E-INCEPTION-NOT-SOVEREIGN"; then
  echo "FAIL  M2 validator-element-read-deleted (O-3 still fires — C2 is not what proves the read)"; fail=1
else
  echo "PASS  M2 validator-element-read-deleted (O-3 goes silent — C2 is what proves the read)"
fi

# M3 — delete the element-level vocabulary gate. Killed by C1.
python3 - "$VAL" "$TMP/no-vocab.py" <<'PY' || { echo "FAIL  M3 MUTATION SETUP BROKEN (vocabulary-gate anchor moved)"; exit 1; }
import sys, re
src, dst = sys.argv[1], sys.argv[2]
s = open(src, encoding='utf-8').read()
m = re.search(r'\n            if elem_authority is not None and elem_authority not in AUTHORITIES:\n'
              r'                self\.err\(\n(?:.*\n)*?                \)\n', s)
if not m:
    sys.exit(1)
open(dst, 'w', encoding='utf-8').write(s[:m.start()] + '\n' + s[m.end():])
PY
if has "$TMP/no-vocab.py" "$FX/bad-vocabulary.bpmn" "E-XML-META-AUTHORITY"; then
  echo "FAIL  M3 vocabulary-gate-deleted      (still fires — C1 is not what proves the gate)"; fail=1
else
  echo "PASS  M3 vocabulary-gate-deleted      (goes silent — C1 is what proves the gate)"
fi

echo
[ "$fail" -eq 0 ] && echo "T-889 teeth: all legs passed" || echo "T-889 teeth: FAILURES above"
exit "$fail"
