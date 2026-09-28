#!/bin/bash
# T-890 (arc-001) — AC6: the round-trip guard goes RED when the editor stops writing
# aef:laneMeta authoringDefault.
#
# HISTORY. On 2026-09-27 this exact mutation left _roundtrip-serialization-cdp.mjs
# pass:true, exit 0: T-886's derived denominator stopped at the element boundary and
# laneMeta was outside it BY CONSTRUCTION (OBS-416). T-910 added the laneMeta
# denominator. This suite is the demonstration T-890's AC6 asks for, made repeatable:
# suppress the writer, prove the suppression applied, observe the guard refuse and
# NAME the attribute, restore the tree and prove it byte-identical.
#
# The mutation is real (the live src is edited and restored) because the guard reads
# src/aef-workflow-designer.html at a fixed path; a copy would test a copy. The restore
# is on an EXIT trap and verified by cmp, and the suite refuses to start if the tree is
# already dirty at that path relative to the backup it takes.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
GUARD="$ROOT/tools/_roundtrip-serialization-cdp.mjs"
SRC="$ROOT/src/aef-workflow-designer.html"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t890.XXXXXX")"
BAK="$WORK/designer.html.bak"
cp "$SRC" "$BAK"
restore() { cp "$BAK" "$SRC"; cmp -s "$BAK" "$SRC" || echo "RESTORE FAILED — src/aef-workflow-designer.html differs from its backup at $BAK (kept)"; }
trap 'restore; cmp -s "$BAK" "$SRC" && rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

WRITER="const _ad = lane.authoringDefault ? \` authoringDefault=\"\${escAttr(lane.authoringDefault)}\"\` : '';"
grep -qF "$WRITER" "$SRC" || {
    echo "TEETH BROKEN — the authoringDefault writer line was not found in src (it moved or was rewritten)."
    echo "This probe can no longer test what it claims to test. Not reporting a pass."
    exit 4; }
grep -q 'checkLmDenominator' "$GUARD" || { echo "TEETH BROKEN — no laneMeta denominator in the guard (T-910)."; exit 4; }

echo "=== T-890 teeth: laneMeta authoringDefault is round-trip guarded ==="
# ── control: the unmutated tree is green and laneMeta has a denominator that names the attribute
base=$(node "$GUARD" --denominators-only 2>&1); rc=$?
if [ $rc -eq 0 ] && echo "$base" | grep -q '"authoringDefault"' && echo "$base" | grep -q '"denominators_only": true'; then
    ok control_baseline_green_and_attribute_in_denominator
else bad control_baseline_green_and_attribute_in_denominator "rc=$rc $(echo "$base" | tail -3)"; fi

# ── mutation: suppress the writer, and prove the suppression applied before scoring anything
python3 - "$SRC" "$WRITER" <<'PY'
import sys
p, writer = sys.argv[1], sys.argv[2]
s = open(p, encoding="utf-8").read()
assert s.count(writer) == 1, "writer line count != 1"
open(p, "w", encoding="utf-8").write(s.replace(writer, "const _ad = '';  // T-890 MUTANT: writer suppressed", 1))
PY
if cmp -s "$BAK" "$SRC" || ! grep -q 'T-890 MUTANT: writer suppressed' "$SRC"; then
    echo "MUTATION SETUP BROKEN — the writer suppression did not apply; a guard verdict now would be about the unmutated tree."
    exit 1
fi
ok mutation_applied_and_proven

mut=$(node "$GUARD" --denominators-only 2>&1); mrc=$?
if [ $mrc -ne 0 ] && echo "$mut" | grep -q 'authoringDefault'; then
    ok guard_goes_red_and_names_the_attribute
else bad guard_goes_red_and_names_the_attribute "rc=$mrc $(echo "$mut" | grep -i 'summary\|problem' | head -3)"; fi
echo "$mut" | grep -q 'compares aef:laneMeta attribute(s) the emitter does not write: authoringDefault' \
    && ok refusal_is_the_dead_coverage_finding || bad refusal_is_the_dead_coverage_finding "$(echo "$mut" | grep -i 'problem' | head -2)"

# ── restore and prove it
restore
cmp -s "$BAK" "$SRC" && ok tree_restored_byte_identical || bad tree_restored_byte_identical "src differs from backup"
after=$(node "$GUARD" --denominators-only 2>&1); arc=$?
[ $arc -eq 0 ] && ok guard_green_again_after_restore || bad guard_green_again_after_restore "rc=$arc"

echo; echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
