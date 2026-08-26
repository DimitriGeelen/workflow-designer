#!/usr/bin/env bash
# _t591-roundtrip-teeth.sh — prove _roundtrip-serialization-cdp.mjs can actually FAIL on the
# EWCR Arc-0 pilot fixture, rather than merely being green on it.
#
# WHY THIS EXISTS. T-591 found that the harness's identity-hinge gate could not fail: it counted
# aef:uid on the PARSED model, and parseBpmnXml MINTS an identity for anything arriving without
# one (src/aef-workflow-designer.html:10284 — deliberate, so third-party BPMN can be imported).
# Deleting one of the pilot fixture's nine <aef:uid> elements still yielded missingNodeUid 0 and
# ok:true. The replacement leg (undeclaredUid) reads the SOURCE, and this script is the control
# that keeps it honest: it poisons a COPY and requires the harness to go red.
#
# A green leg nobody has watched go red is not evidence. This is the watching.
#
# Exits 0 only if BOTH directions hold:
#   clean copy    -> harness exits 0   (accepts a conformant fixture)
#   poisoned copy -> harness exits 1   (rejects a fixture relying on minted identities)
# Poisons a COPY only. The tracked fixture is never written to — its sha256 is pinned in
# docs/research/executable-workflow/source-manifest.sha256 and in T-590's acceptance criteria.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FX="$REPO/docs/research/executable-workflow/fixtures/ewcr-pilot-human-gate-script-human-gate.bpmn"
HARNESS="$REPO/tools/_roundtrip-serialization-cdp.mjs"

[ -f "$FX" ]      || { echo "FAIL  pilot fixture missing: $FX"; exit 1; }
[ -f "$HARNESS" ] || { echo "FAIL  harness missing: $HARNESS"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/clean" "$TMP/poisoned"
cp "$FX" "$TMP/clean/pilot.bpmn"
cp "$FX" "$TMP/poisoned/pilot.bpmn"

# Poison: delete exactly one <aef:uid .../> element, forcing the parser to mint that identity.
python3 - "$TMP/poisoned/pilot.bpmn" <<'PY' || exit 1
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
m = list(re.finditer(r'\s*<aef:uid value="[^"]*"\s*/>', s))
if len(m) < 2:
    print(f"FAIL  expected >=2 aef:uid elements to poison, found {len(m)}")
    sys.exit(1)
open(p, 'w', encoding='utf-8').write(s[:m[0].start()] + s[m[0].end():])
PY

rc_clean=0
ROUNDTRIP_FIXTURES_DIR="$TMP/clean" timeout 300 node "$HARNESS" >"$TMP/clean.json" 2>&1 || rc_clean=$?
rc_poison=0
ROUNDTRIP_FIXTURES_DIR="$TMP/poisoned" timeout 300 node "$HARNESS" >"$TMP/poison.json" 2>&1 || rc_poison=$?

fail=0
if [ "$rc_clean" -eq 0 ]; then
  echo "PASS  clean-copy-accepted            (rc 0)"
else
  echo "FAIL  clean-copy-accepted            (rc $rc_clean — the conformant fixture was rejected)"
  head -c 400 "$TMP/clean.json"; echo; fail=1
fi

if [ "$rc_poison" -ne 0 ]; then
  echo "PASS  poisoned-copy-rejected         (rc $rc_poison)"
else
  echo "FAIL  poisoned-copy-rejected         (rc 0 — THE GATE IS VACUOUS: a fixture with a"
  echo "      deleted aef:uid was accepted, so the identity leg is not measuring the source)"
  fail=1
fi

# The poison must be visible in the numbers, not merely in the exit code — a harness that
# rejected for some unrelated reason would satisfy the exit-code check while proving nothing.
python3 - "$TMP/clean.json" "$TMP/poison.json" <<'PY' || fail=1
import json, sys
def one(p):
    d = json.load(open(p))
    return d["fixtures"][0]
try:
    c, x = one(sys.argv[1]), one(sys.argv[2])
except Exception as e:
    print(f"FAIL  could not read harness verdicts: {e}")
    sys.exit(1)
ok = True
if not (c.get("undeclaredUid") == 0 and c.get("declaredUids") == c.get("expectedUids")):
    print(f"FAIL  clean-declares-all-identities  declared={c.get('declaredUids')} "
          f"expected={c.get('expectedUids')} undeclared={c.get('undeclaredUid')}")
    ok = False
else:
    print(f"PASS  clean-declares-all-identities  ({c.get('declaredUids')}/{c.get('expectedUids')})")
if not (x.get("undeclaredUid") == 1):
    print(f"FAIL  poison-attributed-to-identity  undeclaredUid={x.get('undeclaredUid')} "
          f"(expected exactly 1 — the harness went red for the wrong reason)")
    ok = False
else:
    print("PASS  poison-attributed-to-identity  (undeclaredUid 1)")
sys.exit(0 if ok else 1)
PY

if [ "$fail" -eq 0 ]; then
  echo "4/4 T-591 teeth legs passed"
  exit 0
fi
echo "T-591 teeth legs FAILED"
exit 1
