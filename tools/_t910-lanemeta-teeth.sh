#!/usr/bin/env bash
# _t910-lanemeta-teeth.sh — prove the aef:laneMeta denominator and self-test added by T-910
# actually BITE, by breaking them on purpose and requiring each break to be reported.
#
# WHY THIS EXISTS. T-890 measured the state this repairs: the editor's authoringDefault writer
# was suppressed ENTIRELY and _roundtrip-serialization-cdp.mjs still reported pass:true, exit 0,
# "wm-denominator: 0 unclassified / 10 written". The ten were workflowMeta's. laneMeta's four were
# outside every denominator BY CONSTRUCTION, so a green run said nothing about them. A repair for
# that cannot be trusted on the strength of a green run either — a green run is exactly what the
# defect produced. So every claim below is made by breaking something and requiring a red.
#
# EVERY MUTATION IS ASSERTED APPLIED (T-910 AC3). An unapplied mutation and a surviving mutation
# produce byte-identical results, and this corpus has scored the former as the latter twice:
# bash ${var//pat/rep} glob-interprets its pattern and silently replaces nothing. mutate() below
# therefore runs in python, asserts the replacement count is EXACTLY the number expected, and
# re-hashes the file to prove the bytes moved. A mutation that did not apply is reported as
# MUTATION SETUP BROKEN — never scored as a kill and never scored as a survival.
#
# CONTROL SET RUNS FIRST (T-910 AC5). Case 1 requires the UNMUTATED harness to pass and requires
# the failure strings the later cases grep for to be ABSENT from that clean run. Without that
# sibling, every absence assertion below could be satisfied by a typo in the pattern (PL-328) —
# a grep for a string that appears nowhere reads identically to a clean run.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 90
REPO="$PWD"
SRC="src/aef-workflow-designer.html"
MJS="tools/_roundtrip-serialization-cdp.mjs"
WORK="$(mktemp -d)"
PASS=0; FAIL=0

# ── restore-or-die ────────────────────────────────────────────────────────────────────────────
# These mutations edit tracked source in place. Leaving a mutant behind would be far worse than
# any finding this script can make, so the originals are hashed, backed up, restored on EVERY
# exit path, and the restoration is itself verified against the hash.
cp "$SRC" "$WORK/src.orig"; cp "$MJS" "$WORK/mjs.orig"
SRC_SHA="$(sha256sum "$SRC" | cut -d' ' -f1)"
MJS_SHA="$(sha256sum "$MJS" | cut -d' ' -f1)"
restore() {
  cp "$WORK/src.orig" "$SRC"; cp "$WORK/mjs.orig" "$MJS"
  local s m; s="$(sha256sum "$SRC" | cut -d' ' -f1)"; m="$(sha256sum "$MJS" | cut -d' ' -f1)"
  if [ "$s" != "$SRC_SHA" ] || [ "$m" != "$MJS_SHA" ]; then
    echo "FATAL: restore did not reproduce the original bytes — repository left mutated."
    echo "  $SRC  expected $SRC_SHA got $s"
    echo "  $MJS  expected $MJS_SHA got $m"
    echo "  originals are in $WORK — do not delete it."
    exit 91
  fi
}
cleanup() { restore; rm -rf "$WORK"; }
trap cleanup EXIT INT TERM

# mutate <file> <old> <new> <expected-count> — asserts the count, asserts the bytes moved.
mutate() {
  local f="$1" old="$2" new="$3" want="$4" before after
  before="$(sha256sum "$f" | cut -d' ' -f1)"
  OLD="$old" NEW="$new" WANT="$want" python3 - "$f" <<'PY' || return 1
import os, sys
f = sys.argv[1]; old = os.environ['OLD']; new = os.environ['NEW']; want = int(os.environ['WANT'])
s = open(f, encoding='utf-8').read()
n = s.count(old)
if n != want:
    sys.stderr.write(f"MUTATION SETUP BROKEN: expected {want} occurrence(s), found {n}\n")
    sys.exit(1)
open(f, 'w', encoding='utf-8').write(s.replace(old, new))
PY
  after="$(sha256sum "$f" | cut -d' ' -f1)"
  if [ "$before" = "$after" ]; then
    echo "    MUTATION SETUP BROKEN: $f unchanged after a replacement that reported success"
    return 1
  fi
  return 0
}

run_harness() { timeout 300 node "$MJS" > "$WORK/out.json" 2>&1; echo $?; }

# ok <label> <condition-rc> <detail>
ok()  { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

echo "=== T-910 laneMeta teeth ==="
echo

# ── CASE 1 — CONTROL (positive + the absence sibling PL-328 requires) ─────────────────────────
echo "CASE 1  control: unmutated harness is green, and the failure strings are absent from it"
rc="$(run_harness)"
ok "unmutated run exits 0 (rc=$rc)" "$([ "$rc" -eq 0 ] && echo 0 || echo 1)" "$(tail -5 "$WORK/out.json")"
grep -q '"lm_denominator_failed"' "$WORK/out.json"; ok "clean run does NOT report lm_denominator_failed" "$([ $? -ne 0 ] && echo 0 || echo 1)"
grep -q '"lm_selftest_failed"' "$WORK/out.json";    ok "clean run does NOT report lm_selftest_failed"    "$([ $? -ne 0 ] && echo 0 || echo 1)"
grep -q 'MUTATION SETUP BROKEN' "$WORK/out.json";   ok "clean run does NOT report MUTATION SETUP BROKEN" "$([ $? -ne 0 ] && echo 0 || echo 1)"
# The positive half of the sibling: these same strings MUST be findable when the thing they name
# is true. Cases 2-8 establish that; case 1 alone would be satisfied by a typo'd pattern.
grep -q '"lm_selftest"' "$WORK/out.json"; ok "clean run DOES emit the lm_selftest block (pattern is findable)" $?
grep -q '4 LIVE'        "$WORK/out.json"; ok "clean run reports all 4 laneMeta attributes LIVE"              $?
grep -q '0 NEVER-PRESENT' "$WORK/out.json"; ok "clean run reports 0 NEVER-PRESENT"                           $?
echo

# ── CASES 2-5 — suppress each attribute IN THE WRITER ─────────────────────────────────────────
# This is the T-890 mutation, repeated for all four. Each must go red NAMING the attribute.
suppress_case() {
  local label="$1" old="$2" new="$3" attr="$4"
  echo "CASE $label  writer suppresses @$attr"
  if ! mutate "$SRC" "$old" "$new" 1; then ok "mutation applied" 1 "setup broken — not scored"; echo; return; fi
  ok "mutation applied and bytes moved" 0
  local rc; rc="$(run_harness)"
  ok "harness goes RED (rc=$rc, expected non-zero)" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)" "$(head -6 "$WORK/out.json")"
  grep -q "$attr" "$WORK/out.json"; ok "the failure NAMES @$attr" $?
  # WHICH leg catches it is reported, not guessed. This assertion originally required the
  # DENOMINATOR leg and failed on @authoringDefault — correctly, because that suppression is
  # caught one leg further in, by the LMSPEC-driven round-trip projection: the attribute is still
  # derived (the writer keeps the literal, just never reaches it), still parsed, and the drop only
  # shows when emit->parse loses the value. That is the stronger catch and the one T-890 proved
  # missing, so demanding the weaker leg would have failed the repair for working better than the
  # test expected. Any of the three laneMeta legs is a pass; NONE of them is the failure.
  local leg="none"
  grep -q '"lm_denominator_failed"' "$WORK/out.json" && leg="denominator"
  grep -q '"lm_selftest_failed"'    "$WORK/out.json" && leg="mutation-selftest"
  [ "$leg" = "none" ] && grep -q '"lanes"' "$WORK/out.json" && leg="round-trip-projection"
  ok "caught by a laneMeta leg (leg=$leg)" "$([ "$leg" != "none" ] && echo 0 || echo 1)" "$(head -6 "$WORK/out.json")"
  restore
  echo
}
suppress_case 2 ' authority="${escAttr(lane.authority)}"' '' 'authority'
suppress_case 3 'abbr="${escAttr(lane.abbr || '"'"''"'"')}" ' '' 'abbr'
suppress_case 4 ' height="${lane.height || 130}"' '' 'height'
suppress_case 5 "const _ad = lane.authoringDefault ?" "const _ad = false ?" 'authoringDefault'

# ── CASE 6 — a NEW attribute added inline must not enter unclassified ─────────────────────────
echo "CASE 6  a fifth attribute added INLINE to the emission"
if mutate "$SRC" ' height="${lane.height || 130}"/>' ' height="${lane.height || 130}" t910probe="${escAttr(lane.id)}"/>' 1; then
  ok "mutation applied and bytes moved" 0
  rc="$(run_harness)"
  ok "harness goes RED (rc=$rc)" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)" "$(head -6 "$WORK/out.json")"
  grep -q 't910probe' "$WORK/out.json"; ok "the orphan is NAMED" $?
  grep -q 'NEITHER compared NOR excluded' "$WORK/out.json"; ok "reported as unclassified, not as a pass" $?
else ok "mutation applied" 1 "setup broken — not scored"; fi
restore; echo

# ── CASE 7 — a new attribute arriving through a NEW LOCAL ─────────────────────────────────────
# The carrier authoringDefault itself uses. A derivation that read only the emission line would
# miss this, which is the whole reason deriveEmittedAttrs resolves interpolated locals.
echo "CASE 7  a fifth attribute added through a NEW LOCAL (the authoringDefault carrier shape)"
if mutate "$SRC" '    const _ad = lane.authoringDefault' '    const _probe = lane.id ? ` t910local="${escAttr(lane.id)}"` : '"''"';
    const _ad = lane.authoringDefault' 1 \
   && mutate "$SRC" '"${_ad} height=' '"${_ad}${_probe} height=' 1; then
  ok "mutation applied and bytes moved" 0
  rc="$(run_harness)"
  ok "harness goes RED (rc=$rc)" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)" "$(head -6 "$WORK/out.json")"
  grep -q 't910local' "$WORK/out.json"; ok "the local-carried orphan is NAMED" $?
else ok "mutation applied" 1 "setup broken — not scored"; fi
restore; echo

# ── CASE 8 — an UNRESOLVABLE carrier must throw, not be skipped ───────────────────────────────
echo "CASE 8  an interpolation the derivation cannot resolve must STOP the run"
if mutate "$SRC" '"${_ad} height=' '"${lane.extra ? " x=1" : ""} height=' 1; then
  ok "mutation applied and bytes moved" 0
  rc="$(run_harness)"
  ok "harness goes RED (rc=$rc)" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)" "$(head -6 "$WORK/out.json")"
  grep -q 'cannot resolve' "$WORK/out.json"; ok "refuses rather than deriving a short denominator" $?
else ok "mutation applied" 1 "setup broken — not scored"; fi
restore; echo

# ── CASE 9 — anchor rot must be reported, not silently scanned around ─────────────────────────
echo "CASE 9  the emitter anchor moves"
if mutate "$MJS" "const LM_EMITTER_ANCHOR = 'const lanesToEmit =';" "const LM_EMITTER_ANCHOR = 'const lanesThatDoNotExist =';" 1; then
  ok "mutation applied and bytes moved" 0
  rc="$(run_harness)"
  ok "harness goes RED (rc=$rc)" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)" "$(head -6 "$WORK/out.json")"
  grep -q 'anchor moved' "$WORK/out.json"; ok "says the anchor moved rather than reporting clean" $?
else ok "mutation applied" 1 "setup broken — not scored"; fi
restore; echo

# ── CASE 10 — the control set itself must fire ────────────────────────────────────────────────
# Breaks the mutator into a NO-OP. The probe must report MUTATION SETUP BROKEN rather than
# scoring every attribute as a survival through a harness that cannot mutate anything.
#
# The first version of this case emptied MARK instead, which is NOT a broken mutator — it is a
# weaker one: it still rewrites authority="initiative" to authority="", the bytes still move, and
# the projection still shifts, so most attributes came back legitimately LIVE and the run went red
# for an unrelated reason (@abbr going BLIND where the derived fallback happens to equal the
# authored value). A test that goes red for the wrong reason is a test that will go green for the
# wrong reason. The mutation below makes inLaneMeta return the document UNCHANGED, which is the
# actual failure mode being guarded against.
echo "CASE 10  a broken mutator reports MUTATION SETUP BROKEN rather than scoring kills"
if mutate "$MJS" "        return { xml: xml.slice(0,m.index)+m[0].replace(re,'\$1'+MARK+'\$3')+xml.slice(m.index+m[0].length)," \
                 "        return { xml: xml," 1; then
  ok "mutation applied and bytes moved" 0
  rc="$(run_harness)"
  ok "harness goes RED (rc=$rc)" "$([ "$rc" -ne 0 ] && echo 0 || echo 1)" "$(head -6 "$WORK/out.json")"
  grep -q 'MUTATION SETUP BROKEN' "$WORK/out.json"; ok "reports MUTATION SETUP BROKEN" $?
  grep -q '"lm_selftest_failed"' "$WORK/out.json"; ok "and refuses to publish a score" $?
else ok "mutation applied" 1 "setup broken — not scored"; fi
restore; echo

echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
