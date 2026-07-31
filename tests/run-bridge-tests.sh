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
echo "== eventDef preservation passthrough: start/throw survive open-save (T-259) =="
# Correctness guard against the rail-201 field defect — drives the real editor
# against the pinned AEF peer bytes (t257-eventdef-roundtrip/v1). The fixed-point
# round-trip harness CANNOT catch a consistent drop; this leg can (BITE-proven).
if python3 "$ROOT/tests/test_t259_eventdef_preservation.py"; then
  pass=$((pass + 1))
else
  report FAIL "start/throw aef:eventDef preservation regressed — layout-only save drops typed-event semantics again (T-2620 class)"
  fail=$((fail + 1))
fi

echo
echo "== bare catch event renders neutrally when unbound (T-308, T-244 GO path b) =="
# The AEF-operator misread: a bare <intermediateCatchEvent> decodes to
# linkEventCatch via the REVERSE_TYPE fallback and wears handoff UI whose target
# fields can never bind. Presentation-only fix — this leg pins BOTH halves: the
# neutral presentation AND the zero export surface (node type unchanged, no
# <aef:link> acquired, second save byte-identical), so a future "improvement"
# that reaches for a new node type or a persisted intent marker (path (a), a
# dialect change AEF would have to ratify) fails here first.
if python3 "$ROOT/tests/test_t308_bare_catch_render.py"; then
  pass=$((pass + 1))
else
  report FAIL "bare catch event stopped rendering neutrally, or the fix grew an export surface (T-308/T-244 class)"
  fail=$((fail + 1))
fi

echo
echo "== declared lane beats conflicting geometry (T-310) =="
# A map can declare a node in lane A while its <aef:position> draws it in lane B's
# band (AEF's generator emitted exactly this). Both truths used to survive import,
# and the first drag resolved the contradiction in favour of PIXELS — silently
# rewriting WHO owns the step. This leg pins the reconciliation (declared lane
# wins, agreeing nodes untouched, idempotent), the notice that makes it non-silent,
# and the laneAtY null contract that stops the void adopting nodes into lane[0].
if python3 "$ROOT/tests/test_t310_lane_position_conflict.py"; then
  pass=$((pass + 1))
else
  report FAIL "lane/position conflict handling regressed — membership may again be decided by pixels (T-310 class)"
  fail=$((fail + 1))
fi

echo
echo "== authored doc block survives the round-trip (T-311) =="
# The leading comment child of <bpmn:definitions> carries the map's rationale and
# AEF's corpus_spec treats it as SEMANTIC. We used to drop it at parse and never
# re-emit, so the first UI save destroyed it — and the one comment we DID emit, our
# own DI trailer, was then adopted as the rationale by their reader (5 of their 11
# maps, 2 promoted). This leg pins capture, verbatim re-emission in LEADING position,
# stability across re-import and undo, and the guard that keeps our boilerplate from
# ever being mistaken for an authored doc.
if python3 "$ROOT/tests/test_t311_doc_comment_roundtrip.py"; then
  pass=$((pass + 1))
else
  report FAIL "authored doc block regressed — the rationale may again be destroyed on save (T-311 class)"
  fail=$((fail + 1))
fi

echo
echo "== lane/geometry agreement rule (T-312) =="
# T-310 taught the DESIGNER to reconcile a lane/geometry conflict at import, but
# repair only happens where the designer is in the loop — maps travel between us
# and AEF as bytes and get promoted without ever being opened. This leg pins the
# VALIDATOR half: the predicate settled with AEF at rail 339 (adopted verbatim),
# its extremal witness pair, the crossing-count split between a zero-semantic
# laneSet reorder and an authority call, equal-y as a crossing, SKIP-not-PASS on
# unpositioned maps, and the origin-freeness that keeps us out of the band
# reconstruction that produced 7 phantom mismatches on their side.
if python3 "$ROOT/tests/test_t312_lane_geometry.py"; then
  pass=$((pass + 1))
else
  report FAIL "lane/geometry agreement rule regressed — declaration-vs-drawing disagreement may again pass both toolchains (T-312 class)"
  fail=$((fail + 1))
fi

echo
echo "== lane capacity rule (T-313) =="
# Ordering (T-312) compares lanes against each other and is structurally blind to a
# lane that cannot contain its OWN members. This leg pins the capacity half:
# occupancy rather than height (a 48px gateway occupies 66, more than a 64px task),
# the lowest node chosen by BOTTOM EDGE rather than by y, containment rather than
# the Clean fixpoint — including the fit-but-untidy cases we and AEF deliberately
# both stay silent about — and the coverage guard that derives the occupancy table
# from the renderer's own constants so the palette cannot outgrow it silently.
if python3 "$ROOT/tests/test_t313_lane_capacity.py"; then
  pass=$((pass + 1))
else
  report FAIL "lane capacity rule regressed — a lane may again draw past its own band edge undetected (T-313 class)"
  fail=$((fail + 1))
fi

echo
echo "== annotation seam v0: aef:ready/aef:annotate loop (T-258, T-250 GO) =="
# Embeds the real editor in an iframe host (AEF Watchtower topology): ready
# handshake per render, badge intake + unknown-uid/spoof rejection, display-only
# invariants (BPMN clean, thumbnail strip, wipe-on-render, drop-on-doc-switch).
if python3 "$ROOT/tests/test_t258_annotation_seam.py"; then
  pass=$((pass + 1))
else
  report FAIL "annotation seam loop broke — ready handshake, badge intake, or a display-only invariant regressed (T-250 contract)"
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
echo "== endpoint reconnect reachability: handles above node bodies, real-input drag (T-293, G-003) =="
# The field-found frw_11_harvest case — endpoint grab halos must win the hit-test
# on the node border (isolated chromium, real Input.dispatchMouseEvent; also
# guards the T-286+T-293 canvas layer order).
if python3 "$ROOT/tests/test_t293_endpoint_reach.py"; then
  pass=$((pass + 1))
else
  report FAIL "endpoint reconnect reachability regressed — handle shadowed by node body/port dot or layer order broken (T-293/G-003 class)"
  fail=$((fail + 1))
fi

echo
echo "== save-target guard set: collision notice + blur/Enter commit + mismatch confirm (T-264, T-263 GO) =="
# The three guards from the rail-225 scratch-copy overwrite incident — hermetic
# sidecar + isolated chromium (tools/_t264-save-target-guards-cdp.mjs), 8 legs
# incl. the BITE proving the mismatch confirm reads state, not string echo.
if python3 "$ROOT/tests/test_t264_save_target_guards.py"; then
  pass=$((pass + 1))
else
  report FAIL "save-target guard regressed — collision notice, ID commit-on-blur/Enter, or load-source mismatch confirm (T-264/T-263 class)"
  fail=$((fail + 1))
fi

echo
echo "== lane compaction: fit lanes to content, exact Clean fixpoint (T-125, T-122 pairs) =="
# The dominant operator-correction rule — 24-map headless sweep asserting
# vertical-only, fixpoint convergence, band containment, no new overlaps,
# exact undo, and pair-map height ceilings (tools/_t125-lane-compaction-cdp.mjs).
if python3 "$ROOT/tests/test_t125_lane_compaction.py"; then
  pass=$((pass + 1))
else
  report FAIL "lane compaction regressed — fixpoint, containment, overlap, undo, or a pair-map height ceiling (T-125/T-122 class)"
  fail=$((fail + 1))
fi

echo
echo "== DEAD-leg census contract: aef:meta-note-attrs-only scan (T-304, rail 325) =="
# Pins the pair-round-4 honesty convention before dead-leg maps get adopted at
# promotion: census reads only aef:meta note attrs (raw grep over-counts — the
# PL-060 phantom-census class), fixture sha-pinned to AEF's rail-325 announcement.
if python3 "$ROOT/tests/test_dead_leg_census.py"; then
  pass=$((pass + 1))
else
  report FAIL "DEAD-leg census contract broke — fixture drifted, census/owner mismatch, or corpus gained DEAD legs undeliberately (T-304, rail 325)"
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
