#!/usr/bin/env bash
# Test suite for tools/yaml-to-bpmn.py (the YAML→BPMN render bridge, T-040).
#
# Asserts, for every examples/aef-processes/*.workflow.yaml:
#   - the bridge converts it to BPMN-XML (exit 0)
#   - the emitted BPMN-XML validates CLEAN under tools/validate-workflow.py
#     (exit 0) — the bridge is self-checking: its output must satisfy the same
#     XmlValidator that guards the BPMN export form.
#
# This is the round-trip contract: canonical YAML → BPMN → validator-clean.
# Exit 0 iff all corpus files round-trip clean.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRIDGE="$ROOT/tools/yaml-to-bpmn.py"
VALIDATOR="$ROOT/tools/validate-workflow.py"
CORPUS="$ROOT/examples/aef-processes"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

report() { printf '  [%s] %s\n' "$1" "$2"; }

shopt -s nullglob
files=("$CORPUS"/*.workflow.yaml)
if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: no corpus files found in $CORPUS"
  exit 1
fi

for f in "${files[@]}"; do
  base="$(basename "$f" .workflow.yaml)"
  bpmn="$TMP/$base.bpmn"
  if ! python3 "$BRIDGE" "$f" --out "$bpmn" >/dev/null 2>&1; then
    report FAIL "$base — bridge conversion failed"
    fail=$((fail + 1))
    continue
  fi
  if python3 "$VALIDATOR" "$bpmn" >/dev/null 2>&1; then
    report PASS "$base — converts + validates clean"
    pass=$((pass + 1))
  else
    report FAIL "$base — emitted BPMN did not validate clean"
    python3 "$VALIDATOR" "$bpmn" 2>&1 | head -3
    fail=$((fail + 1))
  fi
done

echo
echo "== editor namespace consistency (T-044) =="
if python3 "$ROOT/tests/test_editor_namespace_consistency.py"; then
  pass=$((pass + 1))
else
  report FAIL "editor aef: namespace drifted from canonical"
  fail=$((fail + 1))
fi

echo
echo "== editor extension shape consistency (T-053) =="
if python3 "$ROOT/tests/test_editor_extension_shape_consistency.py"; then
  pass=$((pass + 1))
else
  report FAIL "editor aef: field shape drifted from bridge (element text vs attribute)"
  fail=$((fail + 1))
fi

echo
echo "== editor↔bridge field coverage (T-059) =="
if python3 "$ROOT/tests/test_editor_bridge_field_coverage.py"; then
  pass=$((pass + 1))
else
  report FAIL "bridge drops an editor-readable aef field present in the corpus"
  fail=$((fail + 1))
fi

echo
echo "== editor↔bridge aef:meta parity (T-060) =="
if python3 "$ROOT/tests/test_editor_bridge_meta_parity.py"; then
  pass=$((pass + 1))
else
  report FAIL "bridge META_KEYS drops a scalar key the editor writes to <aef:meta>"
  fail=$((fail + 1))
fi

echo
echo "== bridge aef.x-* passthrough + loud-drop (T-061) =="
if python3 "$ROOT/tests/test_bridge_aef_passthrough.py"; then
  pass=$((pass + 1))
else
  report FAIL "bridge aef.x-* passthrough broken or unknown keys dropped silently"
  fail=$((fail + 1))
fi

echo
echo "== editor↔bridge structured-key parity (T-063) =="
if python3 "$ROOT/tests/test_editor_bridge_structured_parity.py"; then
  pass=$((pass + 1))
else
  report FAIL "editor and bridge disagree on structured aef keys (import/export drift)"
  fail=$((fail + 1))
fi

echo
echo "== designer→AEF promote contract (T-206) =="
if python3 "$ROOT/tests/test_promote_contract.py"; then
  pass=$((pass + 1))
else
  report FAIL "designer .bpmn export drifted from the AEF promote contract (uid / lane-authority / manifest-tuple / source_bpmn_sha)"
  fail=$((fail + 1))
fi

echo
echo "== two-lane joint promote fixture contract (T-208) =="
if python3 "$ROOT/tests/test_two_lane_joint_contract.py"; then
  pass=$((pass + 1))
else
  report FAIL "two-lane joint fixture drifted from the promote contract (uid / both-lane owner derivation / manifest-tuple / source_bpmn_sha)"
  fail=$((fail + 1))
fi

echo
echo "== typed intermediate events: correctness + bite (T-204) =="
if python3 "$ROOT/tests/test_typed_events.py"; then
  pass=$((pass + 1))
else
  report FAIL "typed event error/timer/message decode/encode broke (type or aef:eventDef binding drift)"
  fail=$((fail + 1))
fi

echo
echo "== typed-event fixture contract: sha-pin + shape (T-212, browser-independent) =="
# Byte-pin + aef:-extension shape guard for the shared typed-event/boundary fixtures AEF
# cross-validates against (rail 88/89). Pure Python — runs even when test_typed_events.py
# skips for lack of chromium, so the shared byte contract is never silently unguarded.
if python3 "$ROOT/tests/test_typed_event_fixture_contract.py"; then
  pass=$((pass + 1))
else
  report FAIL "typed-event fixture drifted from the pinned source_bpmn_sha or aef:eventDef shape (fixture edited? re-pin + notify AEF)"
  fail=$((fail + 1))
fi

echo
echo "== pair-draft corpus fixture pins: sha + validator-clean (T-216, browser-independent) =="
# Byte-pin + validator-clean guard for the pair-draft diagrams AEF cross-holds byte-exact
# (session-handover rail 92; dispatch-loop rail 99+101). Pure Python — no editor harness
# covers these hand-authored dialect exemplars, so without this a silent edit breaks AEF's
# cross-validation with no local signal (the drift class T-212 closed, extended to pair-drafts).
if python3 "$ROOT/tests/test_corpus_fixture_pins.py"; then
  pass=$((pass + 1))
else
  report FAIL "pair-draft corpus fixture drifted from its pinned source_bpmn_sha or stopped validating clean (fixture edited? re-pin + notify AEF)"
  fail=$((fail + 1))
fi

echo
echo "== editor behavior suite: T-234 jump-no-poison + T-237 classification (G-010/T-238) =="
# Standing behavior legs for the two field-found 0.3.1 blockers — hermetic sidecar +
# isolated chromium (tools/_editor-behavior-verify-cdp.mjs). Prints a LOUD SKIP line
# when chromium/node is absent (T-212 convention — never silently unguarded).
if python3 "$ROOT/tests/test_editor_behavior.py"; then
  pass=$((pass + 1))
else
  report FAIL "editor behavior leg failed — jump-autosave poisoning or eventDef/link classification regressed (T-234/T-237 class)"
  fail=$((fail + 1))
fi

echo
# Corpus geometry sweep (T-052): every authored map's nodes must sit inside their
# lane bands, modulo the exact legacy allowlist. Guards against new maps silently
# straddling bands — the G-019 blindness found in T-050.
if bash "$ROOT/tests/check-corpus-geometry.sh"; then
  pass=$((pass + 1))
else
  report FAIL "corpus geometry sweep — a non-legacy map straddles bands or the allowlist is stale"
  fail=$((fail + 1))
fi

echo
echo "bridge round-trip: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
