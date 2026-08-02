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

# T-326: print the captured output of a leg that FAILED, and only then.
#
# This suite used to discard leg output with `>/dev/null 2>&1`, so a failing leg
# emitted `[FAIL] <message>` and nothing else. That is survivable for a
# deterministic failure — re-run it and read the output. It is fatal for an
# intermittent one: the run that failed leaves no evidence of its own cause, so
# the flake is reproducible-only and never diagnosable. Observed 2026-08-01 when
# test_bridge_seam_roundtrip.py failed once inside this runner and passed twice
# immediately after (T-326).
#
# Failure-only by design: a suite that prints every leg's stdout buries the
# signal it exists to surface.
show_output() {
  local file="$1" label="$2"
  [ -s "$file" ] || { printf '      (no output captured from %s)\n' "$label"; return; }
  printf '      --- captured output of %s (last %d lines) ---\n' "$label" "$SHOW_OUTPUT_LINES"
  tail -n "$SHOW_OUTPUT_LINES" "$file" | sed 's/^/      | /'
  printf '      --- end %s ---\n' "$label"
}
SHOW_OUTPUT_LINES="${SHOW_OUTPUT_LINES:-40}"

# ---- declared corpus warnings (T-331) --------------------------------------
#
# A corpus map that emits WARNs is normally a defect in the map. This one is a
# defect in the STANDARD's coverage, and it is not mine to close: context-memory
# lanes its nodes by memory TYPE (Working / Project / Episodic), not by actor,
# so all three lanes carry authority="none". IW-9 (mapping-v1 §3) makes the lane
# the sole authority-of-record, so those tasks have no derivable owner and
# W-LANE-NO-OWNER fires seven times. Whether a non-actor lane axis is legitimate
# is a v1.1 question recorded on T-189 for the operator; re-laning the map here
# would decide it silently and destroy the counterexample.
#
# Declared ANSWERABLY, per T-329: the entry states the rule and the exact count,
# and the checks below fail if the map validates CLEAN (the exception outlived
# its cause), if any ERROR appears, if a rule other than the declared one fires,
# or if the count moves. A bare skip-list entry would be answerable to nothing —
# which is the class of defect this very rule exists to close.
DECLARED_WARN_MAP="context-memory"
DECLARED_WARN_RULE="W-LANE-NO-OWNER"
DECLARED_WARN_COUNT=7
DECLARED_WARN_TASK="T-189 (v1.1: may a lane axis be non-actor?)"

shopt -s nullglob
files=("$CORPUS"/*.workflow.yaml)
if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: no corpus files found in $CORPUS"
  exit 1
fi

for f in "${files[@]}"; do
  base="$(basename "$f" .workflow.yaml)"
  bpmn="$TMP/$base.bpmn"
  if ! python3 "$BRIDGE" "$f" --out "$bpmn" >"$TMP/.out" 2>&1; then
    report FAIL "$base — bridge conversion failed"
    show_output "$TMP/.out" "bridge $base"
    fail=$((fail + 1))
    continue
  fi
  if python3 "$VALIDATOR" "$bpmn" >"$TMP/.out" 2>&1; then
    if [ "$base" = "$DECLARED_WARN_MAP" ]; then
      report FAIL "$base — validates CLEAN but is declared to emit ${DECLARED_WARN_COUNT}× ${DECLARED_WARN_RULE}"
      printf '      the declared exception has outlived its cause. If %s was\n' "$base"
      printf '      re-laned, remove the declaration; if the rule changed, say so.\n'
      printf '      Cited open question: %s\n' "$DECLARED_WARN_TASK"
      fail=$((fail + 1))
      continue
    fi
    report PASS "$base — converts + validates clean"
    pass=$((pass + 1))
  elif [ "$base" = "$DECLARED_WARN_MAP" ] && ! grep -q "^ERROR" "$TMP/.out"; then
    got_declared="$(grep -c "\[$DECLARED_WARN_RULE\]" "$TMP/.out" || true)"
    got_total="$(grep -c "^WARN  \[" "$TMP/.out" || true)"
    if [ "$got_declared" -ne "$DECLARED_WARN_COUNT" ] || [ "$got_total" -ne "$DECLARED_WARN_COUNT" ]; then
      report FAIL "$base — declared ${DECLARED_WARN_COUNT}× ${DECLARED_WARN_RULE} only; got ${got_declared} of that rule and ${got_total} warning(s) total"
      show_output "$TMP/.out" "validator $base"
      fail=$((fail + 1))
    else
      report PASS "$base — ${DECLARED_WARN_COUNT}× ${DECLARED_WARN_RULE}, declared (${DECLARED_WARN_TASK})"
      pass=$((pass + 1))
    fi
  else
    report FAIL "$base — emitted BPMN did not validate clean"
    # T-326: print the CAPTURED output of the run that failed. This used to
    # re-invoke the validator to get something to show, which is right exactly
    # once: under any nondeterminism the second run can print a different — or
    # clean — result than the run whose verdict is being explained.
    show_output "$TMP/.out" "validator $base"
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
echo "== the re-pinned shared fixtures stay zero-semantic (T-314) =="
# Both 832-owned fixtures declared 'human' first while drawing the human node
# below the agent nodes — the same authoring defect AEF found in their generator,
# in the artifact we handed them as the producer contract. Repaired by laneSet
# reorder only. This leg pins the facts the reorder was proven not to touch
# (membership, heights) plus the order it did change, and that both still
# validate clean — geometry AND capacity, since bands are cumulative heights.
if python3 "$ROOT/tests/test_t314_fixture_repin.py"; then
  pass=$((pass + 1))
else
  report FAIL "T-314 re-pinned fixtures drifted — the shared producer contract may no longer be what AEF pins"
  fail=$((fail + 1))
fi

echo
echo "== an under-declared lane band is grown, not the nodes moved (T-315) =="
# The sibling case to T-310 and the one it answers wrongly: when a lane's own
# declared members spill past its own bottom edge, the map is not contradicting
# itself about WHO — it under-declared a height. Moving the nodes repairs that by
# destroying an authored layout; growing the band preserves every position. The two
# separate on T-313's composition result (heights can contain a map exactly when it
# is ordering-clean), so this leg pins BOTH halves: the grow on a clean map, and the
# stand-down on a dirty one — where T-310's behaviour must stay byte-identical
# because that fixture is in front of the operator for review.
if python3 "$ROOT/tests/test_t315_lane_grow_on_import.py"; then
  pass=$((pass + 1))
else
  report FAIL "lane grow-on-import regressed — an under-declared band may again be 'repaired' by relocating the operator's nodes (T-315 class)"
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
echo
echo "== Previously-unrun legs (T-316, AEF rail 347/349) =="
# These nine were on disk, passing, and named by NO runner — several of them
# guarding the seam this arc depends on. They were green when finally run by
# hand, which is why the condition survived: a suite nobody runs cannot report a
# failure, so its silence is indistinguishable from health. All nine were
# verified green BEFORE this wiring, so this is a wiring change and not a quiet
# absorption of unknown state.
#
# Paths are written out in full so the T-316 guard below sees the literal
# `tests/<name>` invocation form. It deliberately does NOT match a bare
# basename: a token in a comment or an echo string would satisfy that, which is
# the prose-in-the-haystack class this arc has now hit three times.
orphan_legs=(
  "tests/test_forward_fixtures.py|forward-compile fixture contract"
  "tests/test_roundtrip_serialization.py|round-trip serialization is no longer a semantic fixed point"
  "tests/test_mapping_standard_conformance.py|frozen governance meta-keys drifted from the mapping standard"
  "tests/test_validate_iw9.py|IW-9 validator rules (W-TYPE-LANE-MISMATCH / E-INCEPTION-NOT-SOVEREIGN) regressed"
  "tests/test_release_immutability.py|release immutability guard (G-007) — a pinned VERSION was mutated"
  "tests/test_bridge_seam_roundtrip.py|bridge emissions are being silently dropped on editor import"
  "tests/test_designer_export_contract.py|designer export contract — an owner-bearing node lost its authority carrier"
  "tests/test_designer_owner_derived.py|designer owner-derived guard — an editable owner override reappeared (IW-9)"
  "tests/test_designer_render.py|designer render-check — render, T-177 markers, or inspector dropdowns broke"
)
for leg in "${orphan_legs[@]}"; do
  legfile="${leg%%|*}"
  legmsg="${leg#*|}"
  legpath="$ROOT/$legfile"
  if [ ! -f "$legpath" ]; then
    report FAIL "orphan leg names a file that does not exist: $legfile"
    fail=$((fail + 1))
    continue
  fi
  if python3 "$legpath" >"$TMP/.legout" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "$legmsg ($legfile)"
    show_output "$TMP/.legout" "$legfile"
    fail=$((fail + 1))
  fi
done

echo
echo "== Gateway branch-ambiguity parity (T-317) =="
# W-XML-GW-AMBIGUOUS: the BPMN path had no counterpart to the YAML path's
# W-GW-AMBIGUOUS, so the designer — which speaks BPMN — would have been shown
# the weaker rule set (T-309 prerequisite). Pins the boundary at exactly one
# unconditioned outgoing edge, both directions.
if python3 "$ROOT/tests/test_t317_gw_ambiguous_parity.py"; then
  pass=$((pass + 1))
else
  report FAIL "gateway branch-ambiguity parity broke — the two validator classes drifted, the boundary moved, or the corpus census changed (T-317)"
  fail=$((fail + 1))
fi

echo
echo "== XML node-type vocabulary drift (T-321) =="
# The XML flow-node vocabulary is DERIVED from NODE_TYPES via a translation table
# plus one declared extension. The translation is a hand-copy (the validator stays
# standalone), so this asserts it still agrees with BOTH emitters — the bridge and
# the designer. Agreement with one is not agreement.
if python3 "$ROOT/tests/test_xml_node_type_vocab.py"; then
  pass=$((pass + 1))
else
  report FAIL "XML node-type vocabulary drifted from an emitter — the validator would reject bytes our own toolchain writes, or admit an element nothing can produce (T-321)"
  fail=$((fail + 1))
fi

echo
echo "== Rule-form parity guard (T-320) =="
# T-317 generalized: a rule on one validator form and not the other lets files on
# the unguarded form assert a cleanliness nothing ever evaluated. Every emitted
# rule must carry a parity classification (ids scraped from the emit sites, so the
# table cannot drift from the code), OUT-OF-SCOPE classifications are re-measured
# against the corpus every run, and the 11 known gaps are a COUNTED tolerance.
if python3 "$ROOT/tests/test_rule_form_parity.py"; then
  pass=$((pass + 1))
else
  report FAIL "rule-form parity broke — a rule was added to one form with no parity decision, an out-of-scope classification stopped being true, or the known-gap count moved (T-320)"
  fail=$((fail + 1))
fi

echo
echo "== Rule dialect axis (T-325 / T-309 IW-1b) =="
# A second axis over the same rule set: is a finding a correctness claim, a house
# convention, or a layout remark? Derived from the frozen standard's normative
# carrier partition — NOT from corpus firing rates, which is the T-323 mistake
# one level up. Polarity is proven behaviourally against real fixtures, so a
# wrong label fails rather than computing a wrong class from a wrong premise.
if python3 "$ROOT/tests/test_rule_dialect_axis.py"; then
  pass=$((pass + 1))
else
  report FAIL "rule dialect axis broke — a rule declares no carrier, a carrier drifted from the frozen standard's §1 partition, or a declared polarity stopped matching what the rule actually does (T-325)"
  fail=$((fail + 1))
fi

echo
echo "== Harness emitter fidelity (T-327) =="
# Every <bpmn:*> element a harness synthesises must be one our EMITTERS can
# produce. Otherwise the harness proves the consumer handles a document shape
# that never occurs and says nothing about the shape it does — which is worse
# than an absent guard, because an absent guard does not report. Permitted set
# is DERIVED from both emitters (XML_NODE_TYPES + their own scaffolding
# literals), never hand-written: after T-324 no corpus file contains
# linkEventThrow, so a corpus-derived check would have nothing left to say about
# it while the emitters still cannot produce it.
if python3 "$ROOT/tests/test_harness_emitter_fidelity.py"; then
  pass=$((pass + 1))
else
  report FAIL "a harness synthesises a <bpmn:*> element neither emitter can produce, or a declared tolerance stopped describing the tree (T-327)"
  fail=$((fail + 1))
fi

echo
echo "== Cross-form behavioural agreement (T-328) =="
# The parity guard (T-320) classifies a rule PAIRED by regex over each validator
# class's source span — it never validates a document, so PAIRED proves both
# forms NAME a rule and never that they AGREE about when it fires. This leg
# drives the SAME document through both forms and compares VERDICTS. Three
# outcomes, not two: asserting "the forms must agree" reports working code as
# broken wherever the bridge legitimately REPAIRS the defect, so bridge-repair
# is declared per pair and never inferred from "the XML form said nothing" —
# inferring it is how a real coverage hole gets absorbed as a repair.
if python3 "$ROOT/tests/test_harness_cross_form_agreement.py"; then
  pass=$((pass + 1))
else
  report FAIL "two implementations of a PAIRED validator rule disagree on the same document, or a declared tolerance/repair stopped describing the tree (T-328)"
  fail=$((fail + 1))
fi

echo
echo "== Check-pass reachability (T-333, AEF OBS-124) =="
# The dual this arc had NOT instrumented. Teeth, discrimination probes and
# PAIRED_SAME_ID all attack the VACUOUS pass (a check that never evaluates).
# AEF's 19-hook bug was the other one: the check's PASSING state was
# unreachable, so it failed on 100% of runs and read as decoration. A validator
# rule is not an assertion in a suite — it is a predicate over documents, and it
# can fire on every document that exists without any suite noticing, because
# firing is not failing. This asks, per rule, whether BOTH branches are
# reachable on real inputs, with form-scoped denominators.
if python3 "$ROOT/tests/test_check_pass_reachability.py"; then
  pass=$((pass + 1))
else
  report FAIL "a validator rule fires on every document of its form (unreachable passing state, AEF OBS-124), or the never-witnessed declaration stopped describing the tree (T-333)"
  fail=$((fail + 1))
fi

echo
echo "== Finding anchorability (T-335, T-309 IW-1a) =="
# Whether a finding can be POINTED AT decides where findings can surface in the
# designer — a gutter marker needs the finding to name something that exists on
# the canvas at a position, and 8 of 23 rules do not. The classification table
# is hand-written, so without this it is a declaration answerable only to itself
# (KNOWN_DISAGREEMENTS before T-330). Population read from source by ast, table
# total (an unclassified rule is a hard fail), and every declared class checked
# against corpus + on-disk fixtures + the BRIDGED documents — omitting the
# bridged form is what made the first pass under-report verification by 2×.
if python3 "$ROOT/tests/test_finding_anchorability.py"; then
  pass=$((pass + 1))
else
  report FAIL "a validator rule is unclassified for anchorability, or its declared anchor class stopped agreeing with the documents, or the never-witnessed row moved (T-335 — the IW-1a numbers in docs/reports/T-309-validator-surfacing.md are now wrong)"
  fail=$((fail + 1))
fi

echo
echo "== Input fidelity: load→save preserves content (T-338, G-016) =="
# The tree's other export-safety instrument (_t308-export-byte-identity-cdp.mjs)
# is DIFFERENTIAL: it compares working-tree output against git-ref output, over
# 24 well-formed maps. A defect present in BOTH versions is byte-identical and
# therefore green, and malformed input is outside its denominator entirely —
# T-337 (import silently deletes a flow node whose tag is outside the importer's
# allowlist) survived in exactly that intersection. This supplies the missing
# direction, output vs INPUT, over a population the corpus cannot express. The
# lossy-tag set is MEASURED every run and compared with the expected set, so a
# new vocabulary gap fails AND a gap that closes fails rather than being absorbed.
if node "$ROOT/tools/_t338-input-fidelity-cdp.mjs"; then
  pass=$((pass + 1))
else
  report FAIL "a load→save round trip stopped preserving content, or the set of BPMN tags that lose content changed in either direction (T-338/G-016 — if a gap CLOSED, update EXPECTED_LOSSY in tools/_t338-input-fidelity-cdp.mjs so the improvement is recorded)"
  fail=$((fail + 1))
fi

echo
echo "== Runner-orphan guard (T-316) =="
# The guard for the class above: any collectable test file (test_*.py, *_test.py,
# *.bats) that this runner does not invoke is a finding. Checks membership in
# THIS runner specifically, not in the union of runners — a file named only by
# check-corpus-node-cuts.sh would read as wired while the suite everyone
# actually calls never touches it (reachability is not completeness, AEF 349).
if python3 "$ROOT/tests/test_t316_runner_orphans.py"; then
  pass=$((pass + 1))
else
  report FAIL "a collectable test file is not invoked by this runner, or the orphan guard's own negative controls broke (T-316)"
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
