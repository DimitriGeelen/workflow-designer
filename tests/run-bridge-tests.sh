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
  # T-473: NOT source_bpmn_sha. That is a provenance field AEF's own promote tool writes
  # into AEF's corpus meta (keyed by our IW-2 contract) — it pins nothing of ours. These are
  # plain byte digests of two fixtures AEF vendored off the rail and guards by digest on
  # their side (SHA_832_TYPED / SHA_832_BOUNDARY, rail 584 Q1). "Notify AEF" is right; the
  # label was not, and this message is the plausible origin of T-423's false cost model.
  report FAIL "typed-event fixture drifted from its pinned byte digest or aef:eventDef shape (fixture edited? re-pin here + announce on the rail: one line, path + old -> new — AEF vendors these two by digest)"
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
  # T-474: NOT source_bpmn_sha — see the note at :206. Plain byte digests; AEF vendors
  # offpage-seam (their 832/pair-draft-3) and s4-exemplar by digest on their side.
  report FAIL "pair-draft corpus fixture drifted from its pinned byte digest or stopped validating clean (fixture edited? re-pin here + announce on the rail before the bytes land: one line, path + old -> new)"
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
  "tests/test_emitted_comment_claims.py|exported bytes carry a claim about an external party, or the emitter duplicates the trailer (T-361)"
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
echo "== Editor seam is a semantic fixed point, per-key (T-187/T-488/T-489/T-490, G-002) =="
# This is the tree's ONLY true semantic round trip through the real editor runtime
# (parse→emit→parse→emit, asserting proj(m1)===proj(m2)), and until T-490 it ran in no
# suite at all. It was written for T-187, sharpened by T-480/T-482/T-483, rebuilt by
# T-488 and extended by T-489 — every one of those a hand-run invocation whose green
# expired the moment the session ended. PL-161 names the shape: a probe that only ever
# runs when someone remembers it is a completion-gate artifact, not a guard. The tell was
# that its own inbox entries (OBS on the `break`, on the divergent METAKEYS copies) were
# written by agents reading the file, never by the file failing.
#
# It carries its own negative controls and refuses to publish a verdict when they do not
# hold, so a green here is not vacuous. Three gated conditions: the denominator is DERIVED
# from the emitter and must have no orphans (T-490), no projected key may survive mutation
# of its own wire carrier without moving the projection (BLIND), and at least one key must
# actually be exercised (PL-084 — zero LIVE is vacuity, not safety).
if node "$ROOT/tools/_roundtrip-serialization-cdp.mjs" > /dev/null; then
  pass=$((pass + 1))
else
  report FAIL "the editor↔bridge semantic fixed point broke, or the guard's key denominator no longer matches what the emitter projects (T-490: an emitter-projected key outside KEYSPEC makes the coverage fraction a claim about the list, not the seam — run 'node tools/_roundtrip-serialization-cdp.mjs' and read denominator.problems)"
  fail=$((fail + 1))
fi

echo
echo "== Lane-origin partition is total and separable (T-358) =="
# The import-loss instruments above all measure SUBTRACTION — content that went in
# and did not come out. This measures the opposite direction: structure that comes
# out having never gone in. Opening a third-party file with no lanes fabricates our
# 3-lane skeleton and lands every node in lanes[0], which is `authority: sovereignty`
# — so the saved document positively asserts that a stranger's tasks are human-
# sovereign, in governance metadata their tool has no concept of.
#
# Three distinct causes reached that default with byte-identical output: input had no
# laneSet; laneSet present but empty; laneSet[0] empty while a LATER one carried the
# lanes (our T-348 first-only read — the only case where the data was there and we
# discarded it). This leg pins that they stay separable. It does NOT assert which
# default is correct: that is T-341's ruling and belongs to the operator.
if node "$ROOT/tools/_t358-lane-provenance-cdp.mjs"; then
  pass=$((pass + 1))
else
  report FAIL "the lane-origin partition stopped being total or separable — two causes of a fabricated lane set now share one verdict, or the negative control was itself defaulted (T-358)"
  fail=$((fail + 1))
fi

echo
echo "== Foreign nodes disclose rather than impersonate (T-355, T-337) =="
# T-337 made the importer PRESERVE elements outside our allowlist and re-emit them
# verbatim. The canvas then drew them through the ordinary type branches, so a
# <bpmn:callActivity> acquired the serviceTask's blue dot and an <inclusiveGateway>
# the exclusive X — the reader was told what the element IS by marks this editor had
# no basis to paint. Preservation shipped without disclosure. T-355 gave foreign nodes
# their own branch, ahead of every type branch, so the misleading marks are never
# painted rather than painted and covered.
#
# WHY THIS LEG EXISTS AT ALL, which is the part worth reading (T-503):
# this probe was first "wired" into T-355's own `## Verification` block. That satisfies
# the ratchet's report but not its point: P-011 runs a Verification block ONCE, at
# `--status work-completed`, so completing T-355 SPENT the only run and the guard went
# unwired again the same hour. The census classifies that state `pending`, never `live`
# (tools/_t451-unwired-guard-census.py — ROOT_SOURCES is the authority, and a task file
# is not in it). This runner already carries the identical lesson forty lines up for
# _roundtrip-serialization-cdp.mjs (T-490, PL-161) and the mistake was repeated anyway.
# Two instances is a pattern: a completion gate is not a guard, and the only durable
# remedy is a caller that re-executes without a task completing.
if node "$ROOT/tools/_t355-foreign-tag-render-cdp.mjs" > /dev/null; then
  pass=$((pass + 1))
else
  report FAIL "a BPMN element this editor does not implement is being drawn with marks that claim a type it was never given, or the foreign branch stopped running ahead of the type branches, or export stopped re-emitting the foreign tag verbatim (T-355/T-337 — run 'node tools/_t355-foreign-tag-render-cdp.mjs' for the per-leg verdict; the CONTROL leg failing instead means a NATIVE serviceTask lost its dot, which is the opposite defect)"
  fail=$((fail + 1))
fi

echo
echo "== Finished-and-invisible census still has a population (T-505) =="
# This leg does NOT assert the backlog is zero. It was 17 of 68 when the census was
# written, and gating on zero would paint the suite permanently red over a bookkeeping
# queue only the operator can drain — the mistake T-491 solved for the unwired-guard
# backlog by gating on MOVEMENT instead of on the count.
#
# What it asserts is that the census can still range over the task corpus at all. The
# instrument refuses with exit 2 when .tasks/active is missing or holds no *.md, and
# refuses again when no task file yields a countable AC block — so a scan broken by a
# template change, a heading rename or a relocated task tree fails here loudly instead of
# reporting "0 finished-and-invisible", which is what a broken scan and a clean board
# both look like from the outside.
#
# The leg also exists so the census has a caller that re-executes without a task
# completing (PL-161). Wired in the same change that created the tool rather than after
# it: T-503 was the repair for exactly that omission, and T-491's ratchet counts a tool
# with no root caller as backlog the moment it lands in tools/.
if python3 "$ROOT/tools/_t505-finished-invisible-census.py" > /dev/null; then
  pass=$((pass + 1))
else
  report FAIL "the finished-and-invisible census could not establish a population (T-505 — run 'python3 tools/_t505-finished-invisible-census.py' for the refusal reason; exit 2 means it abstained rather than returning a verdict, most likely because .tasks/active moved, the '## Acceptance Criteria' heading was renamed, or the task template stopped carrying checkboxes)"
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
echo "== Unwired-guard ratchet over tools/ (T-451 census, T-491 ratchet) =="
# The complement of T-316 above: that leg guards test FILES this runner collects, this
# one guards tools/ INSTRUMENTS — the things a task's Verification block calls once, at
# completion, after which nothing in the tree can re-run them (PL-161).
#
# The census has been correct and unscheduled since T-451. Its only live caller was the
# G-035 gap gauge in lib/gaps.py, which runs when somebody asks — so it measured a real
# and growing backlog and told nobody. One step milder than the class it measures: not
# unrunnable, just unwatched. T-490 and T-448 are two instances found by hand in the
# interval; the census had both.
#
# Gated on MOVEMENT, not on the count: the raw exit code is 1 on a pre-existing backlog,
# so wiring that directly would paint the suite permanently red and the red would carry no
# information. Fails when the backlog GROWS (a standing guard just lost its last caller)
# and equally when it SHRINKS (the baseline now lies and must be tightened) — PL-004
# prescribed exactly this, allowlist WITH stale-entry detection, and only the allowlist
# half was ever built.
if python3 "$ROOT/tools/_t451-unwired-guard-census.py" --ratchet > /dev/null; then
  pass=$((pass + 1))
else
  report FAIL "the unwired-guard backlog MOVED — either a standing guard lost its last live caller, or a baseline entry is now wired and tools/unwired-guard-baseline.txt is stale (run 'python3 tools/_t451-unwired-guard-census.py --ratchet' for the direction; do not silently re-baseline, a new entry is a finding to report)"
  fail=$((fail + 1))
fi

echo
echo "== G-015 verification-hygiene ratchet, now watched (T-508) =="
# verification-hygiene.py was line 130 of the unwired-guard baseline the leg above ratchets:
# correct, tested by 15 teeth legs, and called by NOTHING. In the interval since its
# baseline was written (2026-08-09) its own population drifted — serve-root-diff 75 -> 76
# and, once the third carrier kind landed, 17 population-pinned legs it had never seen.
# Nobody was told, because nobody ran it. Same shape as the T-451 census one leg up, which
# is why this leg exists rather than another census: the fix for an unwatched instrument is
# a caller, not a second instrument.
#
# Gated the same way, on MOVEMENT: the tool exits 1 only for a carrier OUTSIDE the
# grandfathered baseline, so the 105 pre-existing carrier lines cannot paint the suite red
# while the population still awaits the operator's G-015 leg-1 ruling. What it catches is
# the next one written.
if python3 "$ROOT/tools/verification-hygiene.py" > /dev/null; then
  pass=$((pass + 1))
else
  report FAIL "a NEW G-015 carrier appeared in a task's ## Verification block — a line asserting a global, always-moving property (serve-root diff, hard-coded port, or a literal count pinned to a growing population) instead of a property of the task carrying it (run 'python3 tools/verification-hygiene.py' to see which line and which kind; rewrite the line, do not re-baseline — the baseline is the grandfathered population awaiting the operator's ruling, not a place to put new ones)"
  fail=$((fail + 1))
fi

echo
echo "== …and its teeth, also now watched (T-508) =="
# The leg above is a guard. This is the proof the guard FIRES — PL-070: teeth prove a guard
# fires, and a guard whose teeth never run is a guard nobody has checked. _t408-hygiene-teeth.sh
# had no live caller either (only task files and episodics reference it), so wiring the
# ratchet without wiring its teeth would ship the exact defect this task diagnosed.
# ~4s, which is why it is a suite leg and not a per-commit hook.
#
# NOTE, and it is a finding rather than an aside: this is the ONLY teeth script the suite
# runs. Every other tools/_t*-teeth.sh in this repo is in the same unwatched state this
# task found verification-hygiene.py in. Not fixed here — one task, one deliverable — but
# it is now written down somewhere that runs.
if bash "$ROOT/tools/_t408-hygiene-teeth.sh" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the G-015 hygiene ratchet's teeth failed — the guard wired one leg up can no longer be shown to fire (run 'bash tools/_t408-hygiene-teeth.sh' for the failing leg; a green ratchet with red teeth means the ratchet's green carries no information)"
  fail=$((fail + 1))
fi

echo
echo "== Instrument sweep: every runnable teeth script, every run (T-509) =="
# T-508 wired ONE teeth script and observed it was the only one. Measured under T-509:
# 24 exist, 22 had no standing caller, and 19 PASS TODAY — so the naming convention that
# excuses every *teeth* file from the unwired-guard census as "one-shot by design" is false
# for 19 of 24. PL-192 (T-495) already said an instrument excused by its own watchdog's
# naming convention must be scheduled deliberately; this applies it to the population
# instead of to the one probe that prompted it.
#
# COST, measured end-to-end rather than estimated: the suite went 103s -> 168s, +65s /
# +63%. The sweep alone times at 44s; the extra ~20s is contention, which is why the number
# quoted here is the SUITE delta and not the tool's own stopwatch — the first version of
# this comment said "+44s (+43%)" from the standalone timing and was wrong about the thing
# a reader actually cares about. Material, and a real trade-off: it buys standing coverage
# of 19 instruments that were running nowhere. To reverse it, delete this leg — one line, no
# other coupling. T509_TIMEOUT tunes the per-script ceiling.
#
# The first sweep already paid for itself: _t364-t308-teeth.py's control is red — maps=24
# identical=0 drifted=24. CORRECTED 2026-08-15 (T-510): this comment first said the teeth
# script's "own stored reference shas went stale". It stores no shas. run() passes
# REF="3bf37909~1" to _t308, so the comparison is CURRENT BUILD vs A PINNED GIT REF, and
# every one of the 24 maps drifts by EXACTLY +51 bytes — T-399's producer-identity line
# (18 spaces + exporter="aef-workflow-designer" + newline). So the red is EXPECTED, not a
# regression: the control's identical=24 stopped being true the moment T-399 landed. It is
# excluded BY NAME WITH A REASON rather than silently skipped, because the repair is NOT a
# mere re-pin — moving BASELINE_REF past T-364 makes the injected fixture comparable, so
# `unusable` goes to 0 and the teeth go red for the opposite reason. The script's own
# docstring prescribes a NEW genuinely-unstable injection, and choosing that is a decision.
# Same for _t350/_t351, which drive live servers and one of which has a documented
# repo-deletion incident in its own header.
if bash "$ROOT/tools/_t509-instrument-sweep.sh" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an instrument that passed on 2026-08-15 no longer does, or an exclusion went stale (run 'bash tools/_t509-instrument-sweep.sh' — it names the script and its rc; these are hermetic and leave the repo untouched, so a red here is a real regression in whatever that teeth script guards, not harness noise)"
  fail=$((fail + 1))
fi

echo
echo "== Census edge DEFINITION controls (T-495) =="
# The ratchet above guards the COUNT. This guards the DEFINITION the count is derived
# from, and those are not the same assertion: `strip_prose()` deciding that a call is
# prose moves every number in the census at once, in whichever direction the bug leans,
# and the ratchet would report that as a backlog movement with a confident cause attached.
#
# Wired here rather than left in T-495's `## Verification` on purpose. A Verification block
# runs once, at completion, and then the file it guards is unguarded — the exact class the
# census next door exists to count (PL-161). Worse, this file is named `-probe.py`, so the
# census's own one-shot-by-design convention would EXCUSE it and never report it dark. An
# instrument that its own watchdog is built to overlook has to be scheduled deliberately.
#
# Plain mode, not --discriminate: that mode diffs against `git show HEAD:` and is only
# meaningful from a tree whose HEAD predates T-495. Post-commit it compares the census to
# itself, so it is an authoring-time proof, not a standing one. The probe says so itself.
if python3 "$ROOT/tools/_t495-prose-edge-probe.py" > /dev/null; then
  pass=$((pass + 1))
else
  report FAIL "the census edge definition changed — prose is counting as a call again, or a real invocation (string argument, composed os.path.join/pathlib path, shell call with a trailing comment) stopped counting (run 'python3 tools/_t495-prose-edge-probe.py' for the failing leg)"
  fail=$((fail + 1))
fi

echo
echo "== Derived-root census controls (T-497) =="
# Guards that the derived-root census SEPARATES guarded from unguarded, not that its
# number is any particular value. The count is a backlog and moves legitimately; the
# discrimination must not move at all.
#
# Control C is the one that earns its place: `cd "$(dirname "$0")/.." || exit 2` is the
# dominant shell idiom here and it guards the one step that cannot fail — copy the file
# anywhere and `cd <somewhere>/..` still succeeds, then every relative subject is missing.
# If the census ever credits that as verification, ~4 files silently move to "safe".
if bash "$ROOT/tools/_t497-census-controls.sh" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the derived-root census stopped discriminating — an unguarded harness is being scored as verified, or the cd-guard is being credited as a subject check (run 'bash tools/_t497-census-controls.sh' for the failing control)"
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
echo "== The geometry carrier has exactly one carrier (T-423) =="
# Adopts AEF's instrument rather than only their answer: they pin
# test_di_drop_has_a_competing_carrier, a guard asserting the RIVAL carrier still exists so
# that deleting it is loud. This is ours. Step 3 of T-357 adds bpmndi:BPMNShape/dc:Bounds as
# a SECOND home for a node's geometry; the failure being guarded is not "DI is wrong" but DI
# landing while aef:position quietly stops being emitted for some nodes — two geometries,
# disagreeing, with nothing saying so.
#
# WIRED BEFORE THE EMITTER EXISTS, ON PURPOSE. A guard written at the same time as the
# change it guards was written against the new behaviour and proves nothing. Landing it now
# records the invariant while it is still true, so the day the emitter moves it the red
# comes from the corpus rather than from someone's memory of what used to hold.
#
# It asserts NO COUNT. The obvious leg is `nodes == 306 && positions == 306` and that is
# G-015 / PL-200's exact class — a line pinned to a growing population, which falsifies
# itself the first time a map is added and teaches the next reader to bump the number.
# Everything in it is emptiness-shaped (zero missing, zero strays) or -ge-shaped (at least
# one map, at least one node per map). The anti-vacuity leg is not decoration: without it,
# deleting the corpus turns the guard green.
#
# Its teeth are NOT wired separately here — tools/_t423-position-carrier-teeth.py is picked
# up by the T-509 instrument sweep above by name, which is the standing caller T-509 built
# the sweep to provide. Verified: population 24 -> 25, runnable 19/19 -> 20/20.
if python3 "$ROOT/tools/_t423-position-carrier-guard.py" > /dev/null; then
  pass=$((pass + 1))
else
  report FAIL "a flow node lost its aef:position, gained a second one, or a position turned up outside a flow node's own extensionElements — if this went red alongside a DI change, the two carriers have diverged and that is the whole point of the leg (run 'python3 tools/_t423-position-carrier-guard.py' for the node by name; rc 2 means it REFUSED — empty corpus or unparseable map — which is not a failure of the invariant but of the subject)"
  fail=$((fail + 1))
fi

echo
echo "== Unwired flow nodes survive a save round-trip (T-511, AEF rail 11833 Q2) =="
# Wired because I ASSERTED this to AEF on the rail at 11879 — "unwired flow nodes survive,
# element id does not, identity travels on aef:uid" — and an assertion made to a peer that
# nothing re-checks is exactly the class this project keeps cataloguing. If a later change
# starts dropping unwired nodes, the first thing that should happen is this going red, not
# AEF discovering our claim was stale.
#
# The census caught it before I did: adding the probe moved the T-451 unwired-guard ratchet
# 67 -> 68 within minutes of the commit, naming _t511 as a standing guard with no live
# caller. Wiring is the honest resolution; baselining it would have parked a regression
# guard for a property a peer project depends on.
#
# COST: ~40s — it spawns Chromium plus the gallery sidecar. Precedent is _t338, which the
# suite already runs the same way. To reverse: delete this leg, one line, no other coupling.
if timeout 300 node "$ROOT/tools/_t511-unwired-node-roundtrip.mjs" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a save round-trip now drops unwired flow nodes, or the probe's own negative control stopped firing — either way the answer given to AEF at rail 11879 is no longer true and they must be told (run 'node tools/_t511-unwired-node-roundtrip.mjs' for the verdict; rc 2 is a refusal — empty corpus or no chromium — not a fidelity failure)"
  fail=$((fail + 1))
fi

echo
echo "== Identity survives a third-party import with no aef:uid (T-513, AEF rail 11882) =="
# Same reasoning as the T-511 leg above, one step further out. AEF asked at 11882 for the
# case _t511 explicitly did NOT cover — a document arriving with no aef:uid at all — because
# that is where identity being DERIVED from the element id stops being stable. The answer we
# send them is "yes, a uid is minted on first save and survives re-import", and that answer
# is only worth what re-checks it.
#
# Guards two properties a change could break independently: that a uid is minted at all for a
# third-party document, and that re-opening the saved file yields the SAME uid. The second is
# the one that matters — minting a fresh uid per save would look fine in any single export.
#
# COST: ~40s, Chromium plus the gallery sidecar, same shape as _t511 and _t338 above.
if timeout 300 node "$ROOT/tools/_t513-thirdparty-identity-roundtrip.mjs" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a third-party BPMN document (no aef:uid) no longer keeps a stable identity across a save round-trip, or the probe's negative control stopped firing — the answer given to AEF at rail 11885 is no longer true and they must be told (run 'node tools/_t513-thirdparty-identity-roundtrip.mjs' for the verdict; rc 2 is a refusal — the fixture stopped being third-party — not an identity failure)"
  fail=$((fail + 1))
fi

echo
echo "== Externally-assigned aef:uid is honoured — mapping standard §6.3 (T-515) =="
# The mapping standard's §6 conformance requirement 3 — "carries a stable,
# externally-assignable aef:uid on every node and edge" — had no machine check. T-182 built
# test_mapping_standard_conformance.py but it guards §2 only, the frozen governance meta-key
# list. §5 turns requirement 3 into a promise made to AEF specifically: "a reverse renderer
# needs no editor change for identity." That sentence licenses them to build against us.
#
# Guards the two halves separately because they fail independently: the editor must honour
# uids it did not mint (nodes AND edges — two different emit paths), and re-rendering must be
# byte-stable, since an editor that honours a uid once but perturbs the file on every save
# breaks the reverse path just as surely.
#
# COST: ~40s, Chromium plus the gallery sidecar, same shape as _t511/_t513 above.
if timeout 300 node "$ROOT/tools/_t515-external-uid-conformance.mjs" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the editor no longer honours externally-assigned aef:uid values, or re-rendering stopped being byte-stable — mapping standard §6.3 is broken and AEF's reverse path depends on it (run 'node tools/_t515-external-uid-conformance.mjs' for the verdict; rc 2 is a refusal — corpus missing, or the fixture stopped being externally-shaped — not a conformance failure)"
  fail=$((fail + 1))
fi

echo
echo "== Episodic decisions extractor: no phantoms, no truncation, no silent cap (T-516) =="
# Guards a fix to VENDORED framework code (G-008 permits in-tree fix + upstream). The old
# extractor parsed the Decisions section line-by-line, so the task template's own multi-line
# HTML comment was emitted as a real decision on every task close — 363 of 448 episodics
# here, 81% — and any value wrapping onto a continuation line was cut at the first newline.
#
# Wired rather than left to the *teeth* naming convention: T-509 measured that convention
# and found it false for 19 of 24 scripts, which had no standing caller at all. This guards
# episodic memory, one of the framework's three memory types, so it gets a real caller.
if python3 "$ROOT/tools/_t516-episodic-decisions-teeth.py" > /dev/null 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the episodic decisions extractor regressed — phantom template entries, truncated values, or a silent cap are back, and every task closed since would carry corrupted decisions (run 'python3 tools/_t516-episodic-decisions-teeth.py' for the failing leg)"
  fail=$((fail + 1))
fi

echo
echo "bridge round-trip: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
