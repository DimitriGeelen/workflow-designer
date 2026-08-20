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
#
# T-527: this helper existed for weeks and was called by FOUR legs. Every other
# if-guarded leg redirected its probe to /dev/null, so T-326's reasoning above —
# written into this file, in this comment — applied to 4 legs while 23 discarded.
# Each new probe was added by copying a leg that discarded, so the defect
# propagated by the same mechanism that should have propagated the fix.
#
# Measured consequence, not inferred (T-526, N=5 on an unchanged tree): 2 of 5
# runs went red, on two different legs, neither reproducing — and BOTH failures
# were uninvestigable from their own output. One of them was the T-509 sweep,
# whose own FAIL message advertises that it "names the script and its rc", true
# only if a human re-runs it by hand, which requires the flake to still be there.
#
# Worth stating because it decides the scope: 6 of the 10 CDP legs were among the
# discarders, and those 6 are exactly the AEF-seam conformance probes. Every
# answer given to AEF on the rail rested on an instrument that left nothing behind
# when it failed. Converting only those 6 was the available shortcut and would have
# been this fix's own subject matter — a remedy landing on the instances that
# prompted it while the population grows around it. All 23 are converted.
#
# The count that filed the task was WRONG and the error is instructive: "62 legs"
# came from 66 `report FAIL` calls minus 4 `show_output` calls, which counts two
# different populations — most `report FAIL` sites are inside per-corpus loops, not
# standalone legs. A difference between two independently-moving counts cannot
# report the quantity you want, which is the exact finding of T-525 two tasks
# earlier, committed here by the person who wrote it down.
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
echo "== fw note refuses payload-losing calls (T-557, framework tooling) =="
# `fw note` used to route any unrecognised first word to the capture path, where it became
# the observation TEXT and the payload was discarded at exit 0. It destroyed 11 observations
# between 2026-08-09 and 2026-08-17, including OBS-274 — T-556's central finding, which sat
# pending+urgent for nine hours as the literal string "add" while being cited in three commit
# messages. Guarded here rather than only in the framework repo because the register is this
# project's memory intake: a silent loss here is invisible everywhere downstream, and the
# vendored copy is what actually runs. Isolated PROJECT_ROOT — never touches the live inbox.
if python3 "$ROOT/tests/test_note_capture_refuses_lost_payload.py"; then
  pass=$((pass + 1))
else
  report FAIL "fw note can silently discard an observation payload again (guard reverted in the vendored .agentic-framework, or a re-vendor overwrote it — check agents/observe/observe.sh do_capture; the fix is upstream-pending, so a framework bump can legitimately regress this)"
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
if node "$ROOT/tools/_roundtrip-serialization-cdp.mjs" > "$TMP/leg-_roundtrip-serialization-cdp.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the editor↔bridge semantic fixed point broke, or the guard's key denominator no longer matches what the emitter projects (T-490: an emitter-projected key outside KEYSPEC makes the coverage fraction a claim about the list, not the seam — run 'node tools/_roundtrip-serialization-cdp.mjs' and read denominator.problems)"
  show_output "$TMP/leg-_roundtrip-serialization-cdp.out" "_roundtrip-serialization-cdp.mjs"
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
if node "$ROOT/tools/_t355-foreign-tag-render-cdp.mjs" > "$TMP/leg-_t355-foreign-tag-render-cdp.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a BPMN element this editor does not implement is being drawn with marks that claim a type it was never given, or the foreign branch stopped running ahead of the type branches, or export stopped re-emitting the foreign tag verbatim (T-355/T-337 — run 'node tools/_t355-foreign-tag-render-cdp.mjs' for the per-leg verdict; the CONTROL leg failing instead means a NATIVE serviceTask lost its dot, which is the opposite defect)"
  show_output "$TMP/leg-_t355-foreign-tag-render-cdp.out" "_t355-foreign-tag-render-cdp.mjs"
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
if python3 "$ROOT/tools/_t505-finished-invisible-census.py" > "$TMP/leg-_t505-finished-invisible-census.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the finished-and-invisible census could not establish a population (T-505 — run 'python3 tools/_t505-finished-invisible-census.py' for the refusal reason; exit 2 means it abstained rather than returning a verdict, most likely because .tasks/active moved, the '## Acceptance Criteria' heading was renamed, or the task template stopped carrying checkboxes)"
  show_output "$TMP/leg-_t505-finished-invisible-census.out" "_t505-finished-invisible-census.py"
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
if python3 "$ROOT/tools/_t451-unwired-guard-census.py" --ratchet > "$TMP/leg-_t451-unwired-guard-census.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the unwired-guard backlog MOVED — either a standing guard lost its last live caller, or a baseline entry is now wired and tools/unwired-guard-baseline.txt is stale (run 'python3 tools/_t451-unwired-guard-census.py --ratchet' for the direction; do not silently re-baseline, a new entry is a finding to report)"
  show_output "$TMP/leg-_t451-unwired-guard-census.out" "_t451-unwired-guard-census.py"
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
if python3 "$ROOT/tools/verification-hygiene.py" > "$TMP/leg-verification-hygiene.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a NEW G-015 carrier appeared in a task's ## Verification block — a line asserting a global, always-moving property (serve-root diff, hard-coded port, or a literal count pinned to a growing population) instead of a property of the task carrying it (run 'python3 tools/verification-hygiene.py' to see which line and which kind; rewrite the line, do not re-baseline — the baseline is the grandfathered population awaiting the operator's ruling, not a place to put new ones)"
  show_output "$TMP/leg-verification-hygiene.out" "verification-hygiene.py"
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
if bash "$ROOT/tools/_t408-hygiene-teeth.sh" > "$TMP/leg-_t408-hygiene-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the G-015 hygiene ratchet's teeth failed — the guard wired one leg up can no longer be shown to fire (run 'bash tools/_t408-hygiene-teeth.sh' for the failing leg; a green ratchet with red teeth means the ratchet's green carries no information)"
  show_output "$TMP/leg-_t408-hygiene-teeth.out" "_t408-hygiene-teeth.sh"
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
# T-548: this leg's own FAIL text used to repeat the sweep's mistake — it asserted "a real
# regression in whatever that teeth script guards" for EVERY non-zero exit, so a probe killed
# by the 90s timeout was announced to the suite reader as a regression twice over. The sweep
# now discriminates by exit code and so does this, because a message that names the wrong
# cause is worse than no message: it is confident, and it points somewhere.
sweep_rc=0
bash "$ROOT/tools/_t509-instrument-sweep.sh" > "$TMP/leg-_t509-instrument-sweep.out" 2>&1 || sweep_rc=$?
if [ "$sweep_rc" -eq 0 ]; then
  # The headroom warning is a LEADING indicator and this leg redirects the sweep's output
  # to a file that is only shown on failure — so on the green runs where the warning is the
  # whole point, nobody saw it. Caught by reading this leg's own suite output after wiring
  # it, not by design: _t525 was sitting at 81s of 90s and the suite printed a bare pass.
  # Written WITHOUT an `if grep -q ... "$TMP/leg-*"` wrapper on purpose: _t527 guards that
  # shape because it is how a leg discards the evidence for its own verdict, and it flagged
  # my first draft of these three lines. The guard is right about the pattern even though
  # this use surfaces output rather than swallowing it — sed prints nothing when it matches
  # nothing, so the conditional was never needed and weakening the guard to fit my code
  # would have been the wrong trade by a wide margin.
  sed -n '/HEADROOM WARNING/,/^$/p' "$TMP/leg-_t509-instrument-sweep.out" 2>/dev/null | sed 's/^/  /'
  pass=$((pass + 1))
else
  case "$sweep_rc" in
    1) report FAIL "an instrument that passed on 2026-08-15 no longer does, or an exclusion went stale (run 'bash tools/_t509-instrument-sweep.sh' — it names the script and its rc; these are hermetic and leave the repo untouched, so this one IS a real regression in whatever that teeth script guards, not harness noise)";;
    3) report FAIL "the instrument sweep did not COVER everything it names — at least one probe was killed by the ${T509_TIMEOUT:-90}s cap (rc=124) or declined to certify (rc=2). NOT a regression: nothing is claimed about what those instruments guard, because they were never heard from. The sweep's output names each one. Do not repair this by raising T509_TIMEOUT before measuring the probe's cost — T-543 measured _t525 at 86s of 90s and its cost tracks the size of the watched tree, so the headroom would be consumed again";;
    2) report FAIL "the instrument sweep REFUSED — it could not establish a population to sweep (no tools/*teeth* found, or every script excluded). Nothing was measured, which is not a pass";;
    *) report FAIL "the instrument sweep exited $sweep_rc, which is not one of its documented codes (0 pass, 1 regression, 2 refusal, 3 incomplete). Read its output before trusting any reading of this leg";;
  esac
  show_output "$TMP/leg-_t509-instrument-sweep.out" "_t509-instrument-sweep.sh"
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
if python3 "$ROOT/tools/_t495-prose-edge-probe.py" > "$TMP/leg-_t495-prose-edge-probe.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the census edge definition changed — prose is counting as a call again, or a real invocation (string argument, composed os.path.join/pathlib path, shell call with a trailing comment) stopped counting (run 'python3 tools/_t495-prose-edge-probe.py' for the failing leg)"
  show_output "$TMP/leg-_t495-prose-edge-probe.out" "_t495-prose-edge-probe.py"
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
if bash "$ROOT/tools/_t497-census-controls.sh" > "$TMP/leg-_t497-census-controls.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the derived-root census stopped discriminating — an unguarded harness is being scored as verified, or the cd-guard is being credited as a subject check (run 'bash tools/_t497-census-controls.sh' for the failing control)"
  show_output "$TMP/leg-_t497-census-controls.out" "_t497-census-controls.sh"
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
if python3 "$ROOT/tools/_t423-position-carrier-guard.py" > "$TMP/leg-_t423-position-carrier-guard.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a flow node lost its aef:position, gained a second one, or a position turned up outside a flow node's own extensionElements — if this went red alongside a DI change, the two carriers have diverged and that is the whole point of the leg (run 'python3 tools/_t423-position-carrier-guard.py' for the node by name; rc 2 means it REFUSED — empty corpus or unparseable map — which is not a failure of the invariant but of the subject)"
  show_output "$TMP/leg-_t423-position-carrier-guard.out" "_t423-position-carrier-guard.py"
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
if timeout 300 node "$ROOT/tools/_t511-unwired-node-roundtrip.mjs" > "$TMP/leg-_t511-unwired-node-roundtrip.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a save round-trip now drops unwired flow nodes, or the probe's own negative control stopped firing — either way the answer given to AEF at rail 11879 is no longer true and they must be told (run 'node tools/_t511-unwired-node-roundtrip.mjs' for the verdict; rc 2 is a refusal — empty corpus or no chromium — not a fidelity failure)"
  show_output "$TMP/leg-_t511-unwired-node-roundtrip.out" "_t511-unwired-node-roundtrip.mjs"
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
if timeout 300 node "$ROOT/tools/_t513-thirdparty-identity-roundtrip.mjs" > "$TMP/leg-_t513-thirdparty-identity-roundtrip.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a third-party BPMN document (no aef:uid) no longer keeps a stable identity across a save round-trip, or the probe's negative control stopped firing — the answer given to AEF at rail 11885 is no longer true and they must be told (run 'node tools/_t513-thirdparty-identity-roundtrip.mjs' for the verdict; rc 2 is a refusal — the fixture stopped being third-party — not an identity failure)"
  show_output "$TMP/leg-_t513-thirdparty-identity-roundtrip.out" "_t513-thirdparty-identity-roundtrip.mjs"
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
if timeout 300 node "$ROOT/tools/_t515-external-uid-conformance.mjs" > "$TMP/leg-_t515-external-uid-conformance.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the editor no longer honours externally-assigned aef:uid values, or re-rendering stopped being byte-stable — mapping standard §6.3 is broken and AEF's reverse path depends on it (run 'node tools/_t515-external-uid-conformance.mjs' for the verdict; rc 2 is a refusal — corpus missing, or the fixture stopped being externally-shaped — not a conformance failure)"
  show_output "$TMP/leg-_t515-external-uid-conformance.out" "_t515-external-uid-conformance.mjs"
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
if python3 "$ROOT/tools/_t516-episodic-decisions-teeth.py" > "$TMP/leg-_t516-episodic-decisions-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the episodic decisions extractor regressed — phantom template entries, truncated values, or a silent cap are back, and every task closed since would carry corrupted decisions (run 'python3 tools/_t516-episodic-decisions-teeth.py' for the failing leg)"
  show_output "$TMP/leg-_t516-episodic-decisions-teeth.out" "_t516-episodic-decisions-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== aef:uid collision behaviour is unchanged (T-518, _t515 gap 1, AEF rail 11891) =="
# Characterisation, not a verdict. Two collision directions, and they are NOT symmetric:
#   D1 an authored uid equal to one the editor would MINT for another node — guarded, because
#      designer.html:9909 pre-seeds usedUids from the document before any derivation runs.
#   D2 two nodes carrying the SAME authored uid — unguarded, because the call site short-circuits
#      on the attribute and deriveUid is never entered. Measured: the duplicate survives a full
#      round-trip, on nodes and on edges, with no element dropped and no warning anywhere.
#
# Pinned rather than failed. Nobody has ratified what SHOULD happen — §6.3 invites external uid
# assignment and states no uniqueness requirement, which IS the finding. So this leg goes red on
# a CHANGE in behaviour, which is what AEF needs to hear about, rather than asserting a
# preference no standard carries.
#
# COST: ~40s, Chromium plus the gallery sidecar, same shape as _t511/_t513/_t515.
if timeout 300 node "$ROOT/tools/_t518-uid-collision.mjs" > "$TMP/leg-_t518-uid-collision.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "aef:uid collision behaviour changed, or the negative control died — if the editor now rewrites or rejects duplicate authored uids, AEF's reverse renderer will see uids it never assigned and must be told before they build on it (run 'node tools/_t518-uid-collision.mjs'; rc 2 is a refusal — corpus missing or the collision could not be staged — not a behaviour change)"
  show_output "$TMP/leg-_t518-uid-collision.out" "_t518-uid-collision.mjs"
  fail=$((fail + 1))
fi

echo
echo "== aef:uid values that are not XML-attribute-safe (T-520, _t515 gap 2) =="
# §6.3 invites AEF to assign aef:uid externally and constrains nothing about the VALUE. The uid
# rides in an XML attribute, so the character set is bounded by XML — in three ways that need
# three different remedies: escapable (& < "), normalised-and-lossy-by-spec (newline, tab), and
# unrepresentable (C0 controls, illegal in XML 1.0 anywhere).
#
# MEASURED: 8 of 11 candidates survive byte-identical, so escaping is correct. Newline and tab
# do NOT — the editor emits them RAW into the attribute, and XML attribute-value normalisation
# turns them into a space for any conforming parser. The uid AEF's side reads is not the uid we
# wrote, silently, with no error at either end.
#
# WHY THE VERDICT IS NOT TAKEN IN THE BROWSER: the first version read the result back with
# Chrome's DOMParser, which does not apply that normalisation, and reported every value intact.
# The producer's own lenient parser agreed with the defect. Verdicts now come from expat via
# tools/_t520-xml-read.py — the class of parser that reads the document on AEF's side — and the
# disagreement between the two readers is reported as evidence rather than smoothed away.
#
# Characterisation, as T-518: goes red on a CHANGE, not on the defect, because what SHOULD
# happen here is co-designed and not a test file's call.
#
# COST: ~40s, Chromium plus the gallery sidecar, same shape as _t511/_t513/_t515/_t518.
if timeout 300 node "$ROOT/tools/_t520-uid-xml-safety.mjs" > "$TMP/leg-_t520-uid-xml-safety.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "aef:uid XML-attribute safety changed, or the negative control died — a uid value that used to survive a round-trip no longer does (or vice versa), which silently re-points every record AEF keys on that uid (run 'node tools/_t520-uid-xml-safety.mjs'; rc 2 is a refusal — corpus missing, staging failed, or the plain-value control did not survive — not a behaviour change)"
  show_output "$TMP/leg-_t520-uid-xml-safety.out" "_t520-uid-xml-safety.mjs"
  fail=$((fail + 1))
fi

echo
echo "== Vendored-framework divergence matches its declared manifest (T-517) =="
# G-008 permits fixing vendored .agentic-framework/ code in-tree AND upstreaming it. The tree
# recorded that a fix happened (a commit); nothing recorded that the fix was LOCAL. Consequence
# measured: email-archive re-pinged G-AUDIT-EXCLUDE-NOT-HONORED three times over four months
# while our T-374 sat here as a tested implementation of the exact remedy they proposed.
#
# The other half is destructive rather than merely wasteful. `fw upgrade` overwrites this tree,
# and T-276's own follow-up commit reads "post-vendor repair — restore exec bits demoted by old
# do_vendor copy (5 files) + chmod secret-scan": the last re-vendor DID clobber local state and
# it was caught by hand. Eight of the 28 diverged paths carry NO content change at all, only an
# exec bit, so content review cannot see them.
#
# Two legs, deliberately separate. The instrument on the REAL tree is the live check; the teeth
# prove it can go red at all. The instrument went green on its first run, and green on a fresh
# control means nothing until a stimulus containing the fault has been fed to it (PL-206) —
# the mode-only teeth leg then caught a genuine misclassification in the instrument itself.
if python3 "$ROOT/tools/_t517-vendor-divergence.py" > "$TMP/leg-_t517-vendor-divergence.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "vendored framework divergence no longer matches .agentic-framework/.vendor-divergence.yaml — either vendored code was patched without declaring it, or a declared local fix has vanished (a re-vendor would do exactly that). Run 'python3 tools/_t517-vendor-divergence.py'; rc 2 is a REFUSAL (manifest or baseline unreachable), not a clean tree"
  show_output "$TMP/leg-_t517-vendor-divergence.out" "_t517-vendor-divergence.py"
  fail=$((fail + 1))
fi

if python3 "$ROOT/tools/_t517-vendor-divergence-teeth.py" > "$TMP/leg-_t517-vendor-divergence-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the divergence instrument stopped detecting the classes it claims to — mode-only divergence, stale entries, or an unreachable baseline refusing instead of passing (run 'python3 tools/_t517-vendor-divergence-teeth.py' for the failing leg)"
  show_output "$TMP/leg-_t517-vendor-divergence-teeth.out" "_t517-vendor-divergence-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A node nested in a subProcess keeps its uid AND its parent (T-523) =="
# Third of the four gaps _t515 names in its own does_not_cover, and the last one on our side of
# the boundary. MEASURED: a node authored inside <bpmn:subProcess> comes back with its aef:uid
# byte-identical, the sequenceFlow joining two such nodes survives and still connects them — and
# the node is HOISTED to <bpmn:process> level while the subProcess returns EMPTY. Nothing
# disappears; the scope does. That is the outcome no count-based instrument in this suite can
# see, because every count is unchanged.
#
# It also falsified a claim sitting in parseBpmnXml ("the whole interior of an accepted element
# is dropped today"), which was true of the foreign-tag branch and false for flow nodes, and had
# been quietly cited as fact for months. Comment corrected in place; the T-509 class again.
#
# Two legs on purpose. The probe measures the real tree. The teeth MUTATE the editor — restricting
# node collection to direct children, i.e. making the old comment true — and require the probe to
# go red, to go red on the NESTED arm specifically, and to leave the FLAT arm alone. Without that
# last one a red is equally explained by the mutant breaking the round-trip wholesale, and the
# probe would be taking credit for a detection it never localised.
if timeout 300 node "$ROOT/tools/_t523-subprocess-nesting.mjs" > "$TMP/leg-_t523-subprocess-nesting.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "subProcess containment behaviour changed — a nested node's uid, its connecting flow, or whether it stays nested is no longer what AEF was told (run 'node tools/_t523-subprocess-nesting.mjs'; rc 2 is a REFUSAL — no corpus, staging failed, negative control dead, or no pin file — not a behaviour change)"
  show_output "$TMP/leg-_t523-subprocess-nesting.out" "_t523-subprocess-nesting.mjs"
  fail=$((fail + 1))
fi

if timeout 600 python3 "$ROOT/tools/_t523-nesting-teeth.py" > "$TMP/leg-_t523-nesting-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the nesting probe stopped being able to detect the alternative behaviour — either the mutation target in parseBpmnXml moved (rc 2, a refusal), the probe no longer goes red on a mutant that drops nested nodes, or it no longer refuses when its pin file is absent (run 'python3 tools/_t523-nesting-teeth.py' for the failing leg)"
  show_output "$TMP/leg-_t523-nesting-teeth.out" "_t523-nesting-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A completed task still gets episodic memory, and a lost one is reported (T-522) =="
# Two tasks (T-520, T-521) were completed, moved to completed/, and lost their episodic
# summaries with no error anywhere. Root cause measured, not guessed: update-task.sh runs under
# `set -euo pipefail`, and its component auto-populate loop assigns `c_loc=$(grep "^location:"
# ... | ...)`. A fabric card lacking `location:` makes grep exit 1, pipefail carries it through
# the pipe, and the ASSIGNMENT kills the whole script — after the task file has been moved, so
# completion looks successful while every stage below the abort silently never runs. Timeline
# pins it: two location-less cards landed at 12:13:39Z and the next two completions (12:13:59Z,
# 13:34:03Z) lost their episodics; T-519 at 11:53:42Z did not.
#
# The reason this is a SUITE leg and not just a one-line patch is the detection story. T-1169
# (warn when the generator yields nothing) and T-1860 (log every invocation) both already
# existed, and both live INSIDE the block that never executed — a control downstream of the
# branch that fails cannot report that failure. T-1374 fixed one instance of this identical
# abort in this identical block and did not carry the guard to the neighbouring lines. So the
# leg tests the WATCHDOG as much as the fix: mutate the guard back out, and the run must lose
# the episodic AND say so by name.
if python3 "$ROOT/tools/_t522-episodic-reachability-teeth.py" > "$TMP/leg-_t522-episodic-reachability-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "task completion can lose its episodic memory silently again — either the pipefail guard in update-task.sh's component loop was reverted, the EXIT-trap watchdog was replaced by a second trap (bash keeps only the last), or the watchdog now alarms on the designed partial-complete skip (run 'python3 tools/_t522-episodic-reachability-teeth.py'; rc 2 is a REFUSAL — the mutation target is missing, so the legs were never evaluated — not a pass)"
  show_output "$TMP/leg-_t522-episodic-reachability-teeth.out" "_t522-episodic-reachability-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A malformed component card is DETECTED, not merely survived (T-524) =="
# The other half of T-522. That task made a card missing `location:` non-FATAL by guarding the
# assignment; it did not make one VISIBLE. After the fix such a card is simply inert — it stops
# participating in component resolution and nothing anywhere says so. Trading a loud failure for
# a quiet one is not the same as fixing it.
#
# `fw fabric validate` was the natural detector and had been a stub since T-191: it printed
# "Deep validation not yet implemented" for every card and then `return 0`. The prose was honest,
# the exit code was not, so `fw fabric validate && echo ok` reported success for work never done
# (PL-205, PL-178). It now checks the fields real readers assume — id, name, location, each
# justified by a cited consumer — plus YAML parseability and id uniqueness, and REFUSES with rc 2
# rather than passing when it evaluates nothing.
#
# The teeth measure the downstream harm rather than asserting it: a card without `location:`
# contributes nothing to the `registered` set drift builds at lib/drift.sh:25, so drift reports
# that card's own file as UNREGISTERED and the printed remedy is `fw fabric scan` — which would
# mint a SECOND card for one file. Silence that manufactures duplicates. That leg is why
# `location` is required rather than merely conventional.
if python3 "$ROOT/tools/_t524-fabric-validate-teeth.py" > "$TMP/leg-_t524-fabric-validate-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "malformed component cards can go undetected again — either fw fabric validate regressed to a stub that returns 0, it stopped naming the offending card and field, it lost the refusal path (rc 2 on an empty register or an unknown component id, which must not look like a pass), or it now flags valid cards too (run 'python3 tools/_t524-fabric-validate-teeth.py' for the failing leg; rc 2 is a REFUSAL — the fabric agent is absent — not a pass)"
  show_output "$TMP/leg-_t524-fabric-validate-teeth.out" "_t524-fabric-validate-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== The fabric coverage WARN can tell card LOSS from source growth (T-525) =="
# The warning itself is correct and deliberate — watch-patterns.yaml records it as the standing
# WARN the operator's T-344 [REVIEW] accepted. What it SAID was the defect: `unregistered` is a
# difference between two independently moving quantities, so it rises whenever the tree grows
# even while coverage improves. Measured over this project's own audit history, coverage went
# 10.6% -> 22.5% while the headline number went 147 -> 189. T-345 fixed the SEVERITY of exactly
# this confusion in exactly this check and left the number alone.
#
# The blind spot: "twenty files added and not carded" and "twenty cards DELETED" printed the same
# line, and T-524 established cards are load-bearing rather than documentation.
#
# No leg may assert merely that a fabric warning appeared — the pre-change code satisfies that on
# every run for every input. Each leg pins WHICH branch was taken, and the two legs that assert a
# branch was NOT taken also prove the check produced a line, because a negative assertion is
# satisfied by silence (the vacuous-leg failure caught one task earlier in T-524).
if python3 "$ROOT/tools/_t525-fabric-coverage-teeth.py" > "$TMP/leg-_t525-fabric-coverage-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the fabric coverage warning stopped discriminating — either it regressed to raw counts with no ratio, card loss now reads the same as source growth, an absent history renders as 'no change' instead of abstaining, or the severity moved off WARN and overturned the T-344 [REVIEW] as a side effect (run 'python3 tools/_t525-fabric-coverage-teeth.py'; rc 2 is a REFUSAL — either this repo emitted no coverage line so the message shape changed, or T-549's fixture no longer lands in the same arm of the check that the real tree does and has drifted from what it stands in for; in both cases nothing was evaluated and it is not a measured failure)"
  show_output "$TMP/leg-_t525-fabric-coverage-teeth.out" "_t525-fabric-coverage-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== Every leg still captures its own failure output (T-527) =="
# The standing form of T-527's fix. T-326 wired the remedy into 4 legs and wrote the reason
# into this file; 23 legs added afterwards were copied from a discarding template anyway,
# because a discarding leg and a capturing one are byte-identical in every GREEN run. This
# leg is the signal that was missing for that whole period. It asserts the INVARIANT (zero
# discards) rather than a leg count, so it does not go red for whoever next adds a leg.
if bash "$ROOT/tools/_t527-capture-invariant.sh" > "$TMP/leg-_t527-capture-invariant.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a bridge-suite leg discards its probe's output again, or the capture helper itself went missing (run 'bash tools/_t527-capture-invariant.sh' — it prints the offending line numbers; rc 2 is a REFUSAL, meaning show_output() is gone or the suite's leg idiom changed, so nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t527-capture-invariant.out" "_t527-capture-invariant.sh"
  fail=$((fail + 1))
fi

echo
echo "== Hermeticity assertions are scoped to their subject, not the tree (T-532/T-533) =="
# A probe asserting "I left the tree as I found it" is right to do so; asserting it over the
# WHOLE repository is not, because any unrelated writer — cron on a 15-minute timer, a handover
# commit, a concurrent agent — reddens it while it passes standalone. That is what made this
# suite non-deterministic (T-526's 2-of-5 reds) and it cost a full investigation to localise.
# Measured population was 2, one copy-family propagated in 28 minutes; both are scoped now.
# This leg is what stops the third copy, since the template is the previous task's teeth script.
if python3 "$ROOT/tools/_t532-hermeticity-scope-census.py" > "$TMP/leg-_t532-hermeticity-scope-census.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a probe asserts hermeticity over the whole tree again, so it will go red whenever anything else writes to the repo during its window and green when run standalone (run 'python3 tools/_t532-hermeticity-scope-census.py' — it names the file; rc 2 is a REFUSAL, meaning the census disagrees with its own hand-derived ground truth or the corpus vanished, so nothing was evaluated)"
  show_output "$TMP/leg-_t532-hermeticity-scope-census.out" "_t532-hermeticity-scope-census.py"
  fail=$((fail + 1))
fi

echo
echo "== The D2 review-queue line names only tasks meeting the bar it states (T-534) =="
# The FAIL message printed a >30d COUNT against a list holding the >14d tier too, so it read
# "2 task(s) waiting >30d: ... T-325(14d)" — a bar stated in the string that the instrument
# does not hold (PL-159). Invisible unless BOTH tiers are populated, which is why it survived
# and why this probe drives all three. It runs the real audit.sh through the TASKS_DIR seam
# against a synthetic queue, so it asserts the subject rather than a re-implementation.
# --section discovery, not oe-daily: D2 lives inside the discovery guard (audit.sh:3915), and
# the section run costs ~8s where a full run costs 81s to reach the same line.
if python3 "$ROOT/tools/_t534-d2-queue-tier-teeth.py" > "$TMP/leg-_t534-d2-queue-tier-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the D2 review-queue line names a task that does not meet the threshold it states, or a tier's count disagrees with its own list (run 'python3 tools/_t534-d2-queue-tier-teeth.py' — it names the offending task; rc 2 is a REFUSAL, meaning no D2 line was emitted at all or it no longer parses, so nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t534-d2-queue-tier-teeth.out" "_t534-d2-queue-tier-teeth.py"
  fail=$((fail + 1))
fi

echo "== The trend detector aggregates an issue whose numbers move (T-535) =="
# The counter keyed on the verbatim rendered check string, so a check embedding its own
# measurement minted a fresh key every run and could never reach count>=3. On this project's real
# 9-audit window the fabric edges warn was present in 9 of 9 audits and exactly one line was ever
# promoted — the one whose reading held still for three days. The detector fired on STASIS while
# labelled recurrence. This drives the real audit.sh through the new AUDITS_DIR seam against a
# corpus dated RELATIVE TO TODAY (the reader has a 14-day window; pinned dates would age out into
# a silent "no repeated issues", which reads exactly like health). The over-merge leg is the one
# to watch: the obvious repair, s/[0-9]+/N/, fuses CTL-028 with CTL-029 and invents a recurrence
# across two different controls, which is worse than the defect it fixes.
if python3 "$ROOT/tools/_t535-trend-key-teeth.py" > "$TMP/leg-_t535-trend-key-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the audit trend detector either fails to aggregate an issue whose numbers move, or it merges two distinct controls that differ only in digits (run 'python3 tools/_t535-trend-key-teeth.py' — it names the failing leg; rc 2 is a REFUSAL, meaning no trend section was produced or the corpus promoted nothing, so nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t535-trend-key-teeth.out" "_t535-trend-key-teeth.py"
  fail=$((fail + 1))
fi

echo "== A task's location and its frontmatter status cannot silently disagree (T-536) =="
# CTL-028 was never broken — it fired 263 times over 14 days and nobody saw one of them, because
# audit.sh:3721 gates it on `compliance || oe-daily` while the pre-push hook runs `--section
# structure` only (hooks.sh:839, trimmed by T-862 before T-1882's comment claimed otherwise).
# This drives the control through the TASKS_DIR seam against a SYNTHETIC tree with a planted
# disagreement, so what is asserted is the control's ability to see rather than the real tree's
# current cleanliness — the latter is a global always-moving property (G-015) that would go red
# for someone else's mistake and green when the control is deleted. Under the red arm the mutant
# prints "All completed/ tasks have frontmatter status: work-completed": a broken control reads
# as health, which is why leg 1 asserts the finding instead of trusting silence.
if python3 "$ROOT/tools/_t536-status-desync-teeth.py" > "$TMP/leg-_t536-status-desync-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a task in .tasks/completed/ whose frontmatter says otherwise is no longer detected, or a correctly-closed task is flagged (run 'python3 tools/_t536-status-desync-teeth.py' — it names the failing leg; rc 2 is a REFUSAL, meaning CTL-028 emitted nothing at all on --section compliance, so nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t536-status-desync-teeth.out" "_t536-status-desync-teeth.py"
  fail=$((fail + 1))
fi

echo "== A control id names exactly one control (T-538) =="
# T-538: a control id in audit.sh must map to exactly ONE control. Two do not — CTL-029 is
# defined twice (T-1903 at :3639, oe-daily only, remedy `fw task archive-eligible`; T-2055 at
# :3772, compliance||oe-daily, remedy `fw task update --status work-completed`). Their status
# predicates are disjoint so neither control is WRONG; the id is what is broken, and one real
# oe-daily run emits 21 lines under it carrying two different remedies.
# The discriminator is INTERLEAVING, not line distance: nine other ids emit several `pass` lines
# from adjacent if/elif arms and must stay clean, so a "pass sites more than N lines apart" rule
# would need a threshold nobody can justify. An id whose emissions are split by ANOTHER id's
# emissions cannot be one if/elif chain. Leg 2 asserts the nine look-alikes stay clean, which is
# what stops leg 1 passing on a detector that flags everything.
# Ratchet is deliberately one-directional: a NEW collision is red, a RESOLVED one only prints.
# The id namespace is AEF's upstream, so a guard that went red when they fixed it would be
# telling them not to.
if python3 "$ROOT/tools/_t538-control-id-collision.py" > "$TMP/leg-_t538-control-id-collision.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a NEW audit.sh control-id collision appeared, or the interleaving discriminator stopped separating two controls from one control's several pass arms (run 'python3 tools/_t538-control-id-collision.py' — it names the failing leg and prints the run boundaries so the verdict can be checked by eye; rc 2 is a REFUSAL, meaning the pass/warn/fail emission grammar moved and nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t538-control-id-collision.out" "_t538-control-id-collision.py"
  fail=$((fail + 1))
fi

echo "== Every watching gap's closure gauge returns a verdict the reader accepts (T-539) =="
# A gap's closure_check_command is the mechanical half of its closure condition. audit.sh's
# check_gap_triggers (T-382) covers the PROSE half — decision_trigger present, under the key
# `fw gaps` renders — and nothing covered whether the COMMAND says anything readable.
# The contract is in lib/gaps.py:run_closure_gauge and is stricter than it looks: exit 0 AND
# stdout parsing as pure JSON AND a verdict/ready key. rc is the "did the gauge run" channel,
# NOT the open/closed state — G-038 signalled "stranded" through rc 1 and had its perfectly
# good JSON verdict discarded for it.
# Measured when this was written: 2 of 6 gauges were unreadable, and BOTH were written by this
# agent — G-039 by copying G-038's shape an hour earlier. Conformance-by-imitation copies the
# neighbour's non-conformance, so this drives the REAL reader rather than reimplementing its
# parsing; a reimplementation would encode the same misunderstanding that caused the defect.
# Failing safe is why it went unnoticed: UNKNOWN is never READY, so nothing can be wrongly
# closed — the gauge just silently becomes incapable of ever reporting success.
if python3 "$ROOT/tools/_t539-gap-closure-gauge-conformance.py" > "$TMP/leg-_t539-gap-closure-gauge.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a watching gap's closure gauge no longer returns a verdict lib/gaps.py can read, so that gap can never be closed through the register and renders indistinguishably from a broken gauge (run 'python3 tools/_t539-gap-closure-gauge-conformance.py' — it names the gap and its first output line; rc 2 is a REFUSAL, meaning no watching gap carries a closure command at all, so nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t539-gap-closure-gauge.out" "_t539-gap-closure-gauge-conformance.py"
  fail=$((fail + 1))
fi

echo "== The three product BVP drivers discriminate rather than score zero (T-541) =="
# T-540 measured that a BVP driver with no dedicated handler falls through to
# score_free_driver, which substring-matches the driver's OWN ID in the task body: 0 of 55
# non-inception tasks scored non-zero. The failure is silent — `fw bvp` prints a column of
# zeros exactly as confidently as it prints real scores, and the driver's weight buys nothing.
# T-541 wrote the three handlers; this leg defends the properties a green `fw bvp` cannot show:
# each handler is still WIRED into the dispatch table (checked behaviourally, via the
# fallback's own evidence fingerprint), ALIVE (fires on at least one task), SELECTIVE (silent
# on at least one — a driver that fires on everything sorts nothing), GRADED (>=3 distinct
# non-zero levels, guarding the D1 shape where weight 9 buys a binary flag), free of DEAD
# LEVELS (one gate-word-free fixture per rubric level — the PL-203 shape, where a level's
# trigger is missing from the entry gate and no input can ever return it), and
# BOILERPLATE-BLIND (scoring the task template's comment text alone must return 0, which
# score_d3_usability fails on 37 of 58 tasks).
# The level fixtures are mutation-verified: against a copy whose entry gate is not derived
# from the ladder, they produce 11 findings; against the real file, none.
if python3 "$ROOT/tools/_t541-bvp-driver-handler-teeth.py" > "$TMP/leg-_t541-bvp-driver-handlers.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a product BVP driver handler is dead, vacuous, ungraded, unwired, has an unreachable rubric level, or is scoring the task template rather than the task (run 'python3 tools/_t541-bvp-driver-handler-teeth.py' — it names the driver and the property; rc 2 is a REFUSAL, meaning the handlers or the corpus are missing so nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t541-bvp-driver-handlers.out" "_t541-bvp-driver-handler-teeth.py"
  fail=$((fail + 1))
fi

echo "== The BVP cost axis measures surface rather than defaulting to cheapest (T-542) =="
# blast_radius carries weight 0.6 in F8 — the dominant term — and was derived from
# `components:` alone, which is empty on every non-completed task here. Every non-inception
# task therefore scored 0 via `no-components`: a blind read wearing the CHEAPEST value on
# the scale, which is precisely what an HV/LC filter promotes on. T-2189 had already named
# this shape ("always returns 0, making inceptions look artificially cheap") and repaired
# inceptions only; the same sentence was true of 100% of the non-inception corpus.
# The legs hold GRADED (>=3 distinct values, guarding the binary collapse), HONEST ABSENCE
# (nothing knowable => the key is OMITTED, not 0 and not null, so compute_cost's existing
# 'absent' branch drops the task OUT of the ranking), MEASURED-NOT-MENTIONED (a named path
# that does not exist must not raise cost — the existence check is what makes a rename stop
# counting), and DECLARATION-WINS (an explicit components: list still beats the body scan).
# Mutation-verified: dropping the existence check, returning 0 for a blind read, and
# disabling the fallback each produce findings from the specific leg that owns them.
if python3 "$ROOT/tools/_t542-cost-blast-radius-teeth.py" > "$TMP/leg-_t542-cost-blast-radius.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the BVP cost axis has collapsed to a flag, is reporting a blind read as the cheapest value, is counting filenames it never checked exist, or is overruling an author's declared components (run 'python3 tools/_t542-cost-blast-radius-teeth.py' — it names the leg and the property; rc 2 is a REFUSAL, meaning a fixture path moved or PROJECT_ROOT resolved elsewhere so nothing was evaluated — not a measured pass)"
  show_output "$TMP/leg-_t542-cost-blast-radius.out" "_t542-cost-blast-radius-teeth.py"
  fail=$((fail + 1))
fi

echo "== The session cookie is named for the port actually bound (T-544) =="
# web/app.py scopes SESSION_COOKIE_NAME by port on purpose — RFC 6265 does not scope
# cookies by port, so two Watchtowers on one host otherwise share a cookie slot and each
# overwrites the other's session. The defence was reading the WRONG port: the name came
# from Config.PORT (FW_PORT, else 3000) and `--port` only moves the socket, while
# create_app() runs at module import before argparse exists. Measured: AEF's instance on
# :3000 and this project's on :3012 both emitted fw_session_3000, and since each signs
# with its own .fw-secret-key neither could decode the other's — session empty,
# _csrf_token None, every state-changing POST 403 as "Session expired" on a freshly
# loaded page. A guard naming the wrong port reads as protection in review and lets the
# failure present as an expired session rather than as a collision.
# Measured end-to-end, not read: the leg boots a real instance on a real non-default port
# and reads the real Set-Cookie, because the defect was source that looked correct.
# Mutation-verified — reverting the fix makes it emit fw_session_3000 on a port in the
# 57000s and both legs go red.
if python3 "$ROOT/tools/_t544-session-cookie-port-teeth.py" > "$TMP/leg-_t544-session-cookie-port.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the Watchtower session cookie is no longer named for the port it binds, so two instances on one host share a cookie slot and CSRF 403s on both (run 'python3 tools/_t544-session-cookie-port-teeth.py'; rc 2 is a REFUSAL — the instance never answered or set no cookie, so nothing was measured and it is not a pass)"
  show_output "$TMP/leg-_t544-session-cookie-port.out" "_t544-session-cookie-port-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A 403 is written for the client that asked for it (T-545) =="
# The operator's Approve toast read "Session expired — Workflow designer
# (function(){var t=localStorage.getItem('wt-theme');" — not a garbled message but a
# whole HTML document being scraped. The 403 handler rendered the full T-2309 page
# (66456 bytes) to an hx-post, and htmx-toast.js extracts its message with
# .replace(/<[^>]*>/g,'') — a TAG stripper, which removes <title>/<script> tags and keeps
# the text inside them, so the page title and the theme bootstrap's JS source became the
# error message. Two properties are pinned because fixing one leaves the defect: the
# SHAPE (a fragment, not a document) and the CONSEQUENCE (what the shipped toast
# expression actually produces from that body). The consequence leg reads the real regex
# out of htmx-toast.js rather than re-typing it, so it cannot keep passing after the
# real one changes. Leg 5 exists because the first draft of the fix exempted HX-Boosted
# requests to protect T-2309's recovery UI and was wrong: five routes post a plain
# <form method=post> under hx-boost and kept the defect. Leg 6 re-reads the fact the
# whole design rests on — htmx 2.0.4 ships {code:"[45]..",swap:false}, so a 4xx is never
# swapped and the body only ever reaches the toast. Mutation-verified against three
# mutants; reverting the branch reproduces the operator's string verbatim.
if python3 "$ROOT/tools/_t545-error-shape-teeth.py" > "$TMP/leg-_t545-error-shape.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a 403 to an htmx/API caller is a full HTML document again, so the toast scrapes page-title and script text instead of an actionable message (run 'python3 tools/_t545-error-shape-teeth.py'; rc 2 is a REFUSAL — the app would not import or the stimulus could not be established, so nothing was measured and it is not a pass)"
  show_output "$TMP/leg-_t545-error-shape.out" "_t545-error-shape-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== An operator's rationale is stored as the operator wrote it (T-547) =="
# Three rejections in .context/bvp-driver-proposals.jsonl carry
# "Reject%20rationale%20(%E2%89%A530%20chars%20%E2%80%94%20why%20is..." as the operator's
# recorded reason. XHR forbids non-ASCII header values, so htmx (htmx.min.js, `Cn`) retries
# a rejected setRequestHeader with encodeURIComponent AND sets a companion
# HX-Prompt-URI-AutoEncoded:true to declare it did — htmx is correct here. Both bvp.py
# routes read HX-Prompt raw and ignored that declaration, so one em-dash or curly
# apostrophe filed percent-encoded bytes as the audit record; a pure-ASCII rationale
# round-trips fine, which is why it went unseen. Both directions are pinned because
# fixing one creates the other: an UNCONDITIONAL unquote() turns a rationale a human
# typed as "covers 50%20 of cases" into "covers 50  of cases", so the decode has to be
# gated on htmx's own declaration. Leg 3 pins ORDERING — decode before the ≥30 R6 floor,
# or the floor measures the inflated encoded form and passes a 26-character rationale.
# Leg 4 covers `--remove`, which is SOVEREIGN: there the rationale IS the record of a
# policy edit. Leg 5 re-reads the companion-header mechanism out of htmx and REFUSES if
# it is gone, because the conditional decode would then be dead code while every other
# leg stayed green. Leg 6 pins the POPULATION rather than the two sites known today —
# exactly one raw read of the header may exist, the one inside the helper — because a fix
# applied only to the cases that prompted it is T-509's shape and this is the fourth time
# it has come round. Hermetic by construction: the ledger writer and the fw CLI are
# captured, not run, so no audit row is appended and no driver register is touched.
# Mutation-verified against four mutants (never-decode, always-decode, remove-route-only,
# third-route-reads-raw); each is caught by exactly the leg that owns it, and the
# single-route mutant localises to the SOVEREIGN endpoint by name.
if python3 "$ROOT/tools/_t547-hx-prompt-decode-teeth.py" > "$TMP/leg-_t547-hx-prompt-decode.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an operator's hx-prompt rationale is being stored percent-encoded again, or a literal percent sign is being destroyed by an unconditional decode — on /api/bvp/driver/reject or the SOVEREIGN /api/bvp/driver/remove (run 'python3 tools/_t547-hx-prompt-decode-teeth.py'; rc 2 is a REFUSAL — the app would not import or htmx's companion-header contract could not be re-read, so nothing was measured and it is not a pass)"
  show_output "$TMP/leg-_t547-hx-prompt-decode.out" "_t547-hx-prompt-decode-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== The sweep tells 'it broke' apart from 'I never found out' (T-548) =="
# _t509 counted every non-zero exit as a regression and announced each as "an instrument that
# passed on 2026-08-15 no longer does … a real regression in the thing it guards". Two codes
# make that false. 124 is GNU timeout's: T-543 measured _t525 at 86.04s against a 90s cap,
# passing 7/7 standalone, so it crosses whenever the machine is busy and the reader was sent
# hunting a fabric-coverage bug that does not exist. rc=2 is an ABSTENTION, and the sweep's
# own exclusion list already argued that case — for one file, BY NAME — reasoning about a
# property but writing it into a filename exemption, so every other abstaining probe was
# still called a regression. T-509's shape inside T-509's own tool. The classifier now
# discriminates: 0 passed, 1 regressed, 3 incomplete (did-not-finish or abstained), and
# incomplete is still non-zero because an uncovered instrument is not a green. The probe
# drives the REAL sweep over synthetic probes with known exit codes in a mktemp tree, and
# pins the WORDS as well as the codes — the defect was never in the arithmetic, it was in
# the sentence, so a probe checking only rc would have stayed green throughout. Leg 5 was
# red on its first run against my own fix: the regression branch exited before the
# uncovered section printed, so a timeout in the same run as a regression was swallowed by
# the louder finding. Mutation-verified against four mutants (124-as-regression,
# 2-as-regression, incomplete-softened-to-pass, headroom-warning-removed).
if python3 "$ROOT/tools/_t548-sweep-classification-teeth.py" > "$TMP/leg-_t548-sweep-classification.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the instrument sweep has stopped distinguishing a regression from a probe that never finished or declined to certify — or it has started calling an uncovered sweep green (run 'python3 tools/_t548-sweep-classification-teeth.py'; rc 2 is a REFUSAL — the sweep's wording or exclusion list could not be parsed, so nothing was measured and it is not a pass)"
  show_output "$TMP/leg-_t548-sweep-classification.out" "_t548-sweep-classification-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A stale anchor rebinds onto the archive of its own past (T-550) =="

# T-344's denominator guard read the audit's two coverage counts out of the WHOLE report with
# `head -1`. T-525 changed the finding's wording, so its anchor stopped matching the live line
# — and bound instead to the TREND ANALYSIS section, which reprints recurring findings from
# the last 14 days in the shape they had when recorded. It compared a fortnight-old aggregate
# against today's drift count and reported a disagreement that did not exist. The guard's own
# comment shows the silence case WAS anticipated; a report that summarises its own history
# gives a stale anchor something to match, so it never falls silent. Mutation-verified: legs
# 1-4 all go red against the pre-T-550 parse.
if python3 "$ROOT/tools/_t550-audit-parse-anchor-teeth.py" > "$TMP/leg-_t550-audit-parse-anchor.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the T-344 denominator guard is reading the wrong line of the audit again — either a trend-analysis echo of a superseded message is being taken for today's coverage finding, or a real disagreement between the two coverage checks has stopped being reported, or the guard fell silent instead of abstaining when its anchor went stale (run 'python3 tools/_t550-audit-parse-anchor-teeth.py'; rc 2 is a REFUSAL — the guard no longer honours T344_AUDIT_TRANSCRIPT, so the legs would have driven a live audit instead of the recorded report and agreed with themselves for the wrong reason)"
  show_output "$TMP/leg-_t550-audit-parse-anchor.out" "_t550-audit-parse-anchor-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A cheaper stimulus is not a deleted test (T-549) =="

# ── T-549: the fixture legs still have teeth ────────────────────────────────────────────────
# T-549 took _t525 from 86.04s to ~24.6s by moving its four branch legs off this repository
# and onto a 20-file fixture. That is a change to the STIMULUS, and a stimulus can be built —
# without anyone intending it — so that the legs it drives can no longer go red (PL-206). This
# leg breaks the audit's coverage branch three ways in a COPIED framework and requires _t525 to
# notice each one on the correct leg. Its control run matters as much as its mutations: an
# unmutated copy must come back green, or every red is the copy mechanism rather than a leg.
if python3 "$ROOT/tools/_t549-fabric-coverage-mutation-teeth.py" > "$TMP/leg-_t549-coverage-mutation.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "_t525's cheap fixture legs no longer detect a broken fabric coverage check — a deliberately mutated branch (card loss printed as flat, growth printed as card loss, or an abstention printed as flat) did not turn the corresponding leg red, so that leg's green certifies nothing (run 'python3 tools/_t549-fabric-coverage-mutation-teeth.py'; rc 2 is a REFUSAL — audit.sh no longer contains the branch text this probe mutates, or the unmutated control was not green, so nothing was measured and it is not a pass)"
  show_output "$TMP/leg-_t549-coverage-mutation.out" "_t549-fabric-coverage-mutation-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== An exit code is not an account of what happened (T-551) =="

# ── T-551: the sweep keeps what each probe said ─────────────────────────────────────────────
# _t509 redirected every probe to /dev/null, so a run yielded one integer per probe and
# nothing else. Three instruments have now failed ONLY inside a full sweep and passed every
# standalone attempt afterwards — _t523 (rc=1), _t366 (rc=2), _t344 leg 2 — and not one byte
# was kept from any of them, while _t523 alone prints nine named legs when run by hand. For
# that class, "run it directly for its own output" is advice that cannot be taken: running it
# directly is exactly what does not reproduce it. These legs drive the REAL sweep over
# synthetic probes with known exit codes and known sentinels and require each sentinel to
# reach the sweep's own report — for regressions, abstentions and kills alike — bounded, with
# the bound stated, quiet on green, and with no capture files left behind. Mutation-verified:
# 5 of 7 legs go red against the reconstructed pre-T-551 redirect.
if python3 "$ROOT/tools/_t551-sweep-capture-teeth.py" > "$TMP/leg-_t551-sweep-capture.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the instrument sweep has gone back to discarding what its probes say — a failing, abstaining or killed probe's own output is no longer reaching the sweep's report, or the capture is unbounded, silently truncated, leaking into green runs, or leaving temp directories behind (run 'python3 tools/_t551-sweep-capture-teeth.py'; rc 2 is a REFUSAL — the sweep's EXCLUDE list could not be parsed so the fixture tree tripped the stale-exclusion exit before the run loop, and nothing was measured)"
  show_output "$TMP/leg-_t551-sweep-capture.out" "_t551-sweep-capture-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== The gate named the wrong subsystem for two maps (T-448) =="

# ── T-448: the fixpoint gate's verdict comes from the diff ──────────────────────────────────
# bake-clean-layout --check fails for two unrelated reasons — the layout is not a fixpoint, or
# the emitter changed under a corpus nobody re-baked — and T-448 made the verdict say which.
# It said it from the driver's `moved` counter, which the file's own T-300 comment calls an
# unreliable proxy THREE LINES ABOVE the call site, naming audit-process and
# error-escalation-ladder as the case. Those are the exact two maps it mislabelled: both
# report moved>0 and both re-emit with the same +2/-1 serialization delta as the other 22, no
# geometry at all. The verdict now reads the diff. Mutation-verified against three mutants
# (counter-based rule, no comment-stripping, never-implicate-layout). Driven directly against
# classify_drift() rather than through the gate, which needs a headless browser and 24 maps.
if python3 "$ROOT/tools/_t448-drift-classification-teeth.py" > "$TMP/leg-_t448-drift-classification.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the Clean-fixpoint gate is naming the wrong subsystem again — either an in-editor 'moved' count with no geometry in the diff is being reported as a LAYOUT failure, or a real geometry change (aef:position or dc:Bounds) has stopped being reported as one, or a geometry marker appearing inside an XML comment is being counted as a coordinate (run 'python3 tools/_t448-drift-classification-teeth.py'; rc 2 is a REFUSAL — bake-clean-layout.py no longer exposes classify_drift/changed_lines, so nothing was measured)"
  show_output "$TMP/leg-_t448-drift-classification.out" "_t448-drift-classification-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A hermeticity check that cannot pass on Mondays (T-552) =="

# ── T-552: _t525's write-set assertion is content-addressed, not status-letter-addressed ────
# _t525 leg 7 claims the probe leaves .context/audits as it found it. T-533 scoped that to the
# subject's write-set, which was right; the comparand was `git status --porcelain`, which was
# wrong in both directions. Porcelain reports status LETTERS, so rewriting an already-dirty
# file is invisible — measured, .context/audits/2026-08-16.yaml moved f42311649879 ->
# 47b2499bdbf7 with byte-identical porcelain — and that covers BOTH files the audit writes on
# every run after the first of the day. In the other direction a CREATE reads as a violation,
# and the first audit of any day creates <today>.yaml, so the leg was guaranteed red once every
# 24 hours (OBS-273, found as the sweep's rc=1 on 2026-08-17 against a standalone 8/8).
# Now a path->digest map judged against the paths the subject declares it writes, ANDed with
# proof that the subject wrote at least one of them so a crashed audit cannot read as hermetic.
# Driven against the pure function rather than through _t525, which costs ~61s and a real audit
# run, and which cannot be made to cross midnight on demand.
if python3 "$ROOT/tools/_t552-writeset-hermeticity-teeth.py" > "$TMP/leg-_t552-writeset-hermeticity.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the audit-probe hermeticity assertion has stopped discriminating — either the first audit of a day or a run crossing midnight is being reported as a violation again, or a rewritten historical audit / a fabricated report / a deletion / an audit that never ran is being reported as hermetic (run 'python3 tools/_t552-writeset-hermeticity-teeth.py'; rc 2 is a REFUSAL — tools/_writeset_hermeticity.py no longer exposes write_set_violations/declared_writes_observed, so nothing was measured)"
  show_output "$TMP/leg-_t552-writeset-hermeticity.out" "_t552-writeset-hermeticity-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== The hermeticity census still sees a real one after it stopped seeing prose (T-558) =="

# ── T-558: the T-532 census went from 1 finding to 0, and so would deleting it ───────────
# T-558 taught _t532 to blank Python docstrings before classifying, the way it already blanked
# `#` comments under T-533. That removed its single WHOLE-TREE finding — tools/_writeset_
# hermeticity.py, a module with no subprocess call of any kind, flagged on the strength of a
# docstring explaining the porcelain comparand it REPLACED. "1 finding -> 0 findings" is also
# what deleting the classifier produces, so the two are separated here rather than asserted:
# a real unscoped before/after assertion is planted in the scanned directory and must be
# flagged AND must still drive rc=1, while the same words in a docstring must not be.
# Mutants live under tools/ because that is what the census scans — one written elsewhere is
# never read, and a leg that runs no code reads as a pass (PL-206, and the T-557 mutation run
# where mutants died on a path error and the exit 1 was mistaken for a detection).
if python3 "$ROOT/tools/_t558-hermeticity-census-teeth.py" > "$TMP/leg-_t558-hermeticity-census.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the hermeticity-scope census has stopped discriminating — either prose in a docstring is being read as an invocation again, or a REAL unscoped before/after 'git status' assertion is no longer detected, or a detected one no longer fails the census (run 'python3 tools/_t558-hermeticity-census-teeth.py'; rc 2 is a REFUSAL — the census is missing or a previous run left mutant residue in tools/, so nothing was measured)"
  show_output "$TMP/leg-_t558-hermeticity-census.out" "_t558-hermeticity-census-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "== A Verification leg that asserts ABSENCE is satisfied by silence (T-560) =="

# ── T-560: two directions of the same mistake, one of them invisible ─────────────────────
# A P-011 leg asserting something is NOT present goes green when its pattern is broken —
# mis-quoted, shell-expanded before grep sees it, or aimed at a path that does not exist.
# The assertion and its own failure are the same observable and the gate cannot tell them
# apart. Two legs were caught mis-quoted in one session (T-501 leg 2, T-301 leg 4) and BOTH
# were caught only because they asserted PRESENCE. The census counts the population where
# the identical mistake is silent, and ratchets on the UNCONTROLLED subset so the corpus's
# ~81 historical instances do not hold the suite permanently red (OBS-293: a leg that is
# always red teaches readers to rerun rather than to look).
# These teeth exist because "81 uncontrolled" is indistinguishable from "flags everything"
# and from "control detector always returns NONE" unless something pins both edges. Leg 2
# is the load-bearing one: an absence assertion WITH a positive control must not be flagged.
if python3 "$ROOT/tools/_t560-absence-census-teeth.py" > "$TMP/leg-_t560-absence-census.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the absence-assertion census has stopped discriminating — either an uncontrolled absence leg is no longer flagged, or a leg carrying a positive control is now flagged (which makes the tool noise rather than a gate), or exceeding the ratchet baseline no longer exits 1, or T560_TASK_ROOT leaked and the census is reading a synthetic tree (run 'python3 tools/_t560-absence-census-teeth.py'; rc 2 is a REFUSAL — the census is missing, so nothing was measured)"
  show_output "$TMP/leg-_t560-absence-census.out" "_t560-absence-census-teeth.py"
  fail=$((fail + 1))
fi

echo
echo "bridge round-trip: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
