#!/usr/bin/env bash
# _t419-carrier-mutation-check.sh — the competing-carrier leg read the brief's table
# back correctly on its first run. That is when a check is least trustworthy: a row
# that has never been observed moving is not known to be capable of moving, and two
# of the three rows assert an ABSENCE, which is also what a broken detector reports.
#
# T-419. Two mutations, one per direction, each against a real edit to the designer
# source rather than to the detector:
#
#   M1  delete the `aef:position` emission          geometry  GENERATED -> NONE
#       (this is literally what T-357 proposes)
#   M2  emit a rival carrier for documentation      element-content  NONE -> GENERATED
#
# For each: the named row must move, and the OTHER carrier rows must not. A mutation
# that moves every row proves nothing about the row it was aimed at (T-416 §b).
#
# The mutation is applied to a COPY and handed to the harness via T338_DESIGNER_SRC;
# the tracked source is never edited.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src/aef-workflow-designer.html"
HARNESS="$ROOT/tools/_t338-input-fidelity-cdp.mjs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0

# Verdict for one carrier row out of the harness's JSON. Reads the row by id rather
# than by position, so adding a case cannot silently re-point an assertion.
row_verdict() { # row_verdict <json-file> <row-id>
  python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
for r in d.get("carrier", []):
    if r["id"] == sys.argv[2]:
        print(r["verdict"]); sys.exit(0)
print("ROW-ABSENT")
' "$1" "$2"
}

run_against() { # run_against <designer-src> <out.json>
  T338_DESIGNER_SRC="$1" node "$HARNESS" --json > "$2" 2>/dev/null
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$2" 2>/dev/null
}

check() { # check <name> <mutated-src> <row-that-must-move> <expected-prefix> [reciprocal:yes|no]
  local name="$1" msrc="$2" moved="$3" want="$4" recip="${5:-yes}"
  local out="$TMP/$name.json"
  if ! run_against "$msrc" "$out"; then
    echo "FAIL: [$name] harness produced no parseable JSON — the mutation broke the run itself, so nothing was measured." >&2
    fails=$((fails + 1)); return
  fi
  local got; got="$(row_verdict "$out" "$moved")"
  case "$got" in
    "$want"*) echo "  ok  [$name] row '$moved' moved to $got" ;;
    *) echo "FAIL: [$name] row '$moved' did not move — measured '$got', wanted '$want*'. The premise this row pins can change in the source without the leg noticing." >&2
       fails=$((fails + 1)) ;;
  esac
  # Reciprocal: every OTHER carrier row must read exactly what the unmutated run read.
  # Skipped where the mutation is deliberately global (see M2) — asserting isolation
  # for a mutation that cannot be isolated would just be a leg engineered to pass.
  if [ "$recip" != "yes" ]; then
    echo "      (reciprocal not asserted for this mutation — see the M2 note)"
    return
  fi
  local other
  for other in geometry foreign-flownode element-content; do
    [ "$other" = "$moved" ] && continue
    local base_v mut_v
    base_v="$(row_verdict "$TMP/baseline.json" "$other")"
    mut_v="$(row_verdict "$out" "$other")"
    if [ "$base_v" != "$mut_v" ]; then
      echo "FAIL: [$name] reciprocal row '$other' also moved ($base_v -> $mut_v) — the mutation changed more than the fact under test, so '$moved' moving proves nothing about it." >&2
      fails=$((fails + 1))
    fi
  done
}

echo "=== T-419 competing-carrier mutation check ==="

echo "--- baseline (unmutated source) ---"
if ! run_against "$SRC" "$TMP/baseline.json"; then
  echo "FAIL: baseline run produced no parseable JSON — cannot compare anything against it." >&2
  exit 1
fi
for r in geometry foreign-flownode element-content; do
  echo "  baseline $r = $(row_verdict "$TMP/baseline.json" "$r")"
done

# --- M1: retire aef:position (the T-357 proposal, applied) ---------------------
python3 - "$SRC" "$TMP/m1.html" <<'PY' || { echo "FAIL: M1 anchor missing — re-anchor before trusting this check." >&2; exit 1; }
import sys
src = open(sys.argv[1], encoding="utf-8").read()
old = '''    out += `        <aef:position x="${node.x.toFixed(1)}" y="${node.y.toFixed(1)}"/>\\n`;'''
if src.count(old) != 1:
    print("anchor M1 matched %d times" % src.count(old), file=sys.stderr); sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(old, "    // M1: aef:position emission retired"))
PY
check m1-retire-aef-position "$TMP/m1.html" geometry CARRIER-NONE

# --- M2: start competing with content we currently only pass through -----------
# The two CARRIER-NONE rows are absence claims, and an absence is also what a broken
# probe reports. Unless the leg can be shown reporting GENERATED on a row whose
# baseline is NONE, "none" is indistinguishable from "the probe missed".
#
# This mutation is deliberately GLOBAL — an unconditional emission — so it moves all
# three rows, and its reciprocal is therefore not asserted. It answers a different
# question from M1: M1 asks "does this row move when ITS premise changes, and only
# it?"; M2 asks "can a NONE row report GENERATED at all?". Making M2 isolating would
# mean teaching the importer to consume documentation first, which is T-347's ruling
# — a real design change smuggled in as test scaffolding.
python3 - "$SRC" "$TMP/m2.html" <<'PY' || { echo "FAIL: M2 anchor missing — re-anchor before trusting this check." >&2; exit 1; }
import sys
src = open(sys.argv[1], encoding="utf-8").read()
old = '''  // uid first — the immutable internal reference; re-import keys off this.
  if (node.uid) out += `        <aef:uid value="${escAttr(node.uid)}"/>\\n`;'''
new = old + '''
  out += `        <aef:doc text=""/>\\n`;   // M2: rival carrier for documentation'''
if src.count(old) != 1:
    print("anchor M2 matched %d times" % src.count(old), file=sys.stderr); sys.exit(1)
open(sys.argv[2], "w", encoding="utf-8").write(src.replace(old, new))
PY
check m2-rival-for-documentation "$TMP/m2.html" element-content CARRIER-GENERATED no

echo
if [ "$fails" -ne 0 ]; then
  echo "MUTATION CHECK FAIL — $fails" >&2
  exit 1
fi
echo "MUTATION CHECK PASS — M1: the geometry row goes NONE when the aef:position
             emission is retired in the source, and no other carrier row moves with it.
             M2: a row whose baseline is CARRIER-NONE can report GENERATED, so its
             'none' is a measurement rather than a silent miss. M2 is global by
             construction and asserts no isolation."
