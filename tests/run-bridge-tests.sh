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
#
# T-1288: --tier core|browser|sweep|all (default all: every leg, as before). Each leg is a function registered by
# one `leg <tier> <name> <fn>` line, which is the only place its tier is declared; tools/_t1288-tiers.sh holds the
# tier rules (hermetic core, retry-once for browser timeouts, tests/quarantine.yaml) and
# tools/_t1288-tier-guard.py fails a leg with no tier. The leg bodies are the pre-T-1288 code, unindented on
# purpose: the census and capture checks over this file read its lines at column 0.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../tools/_t1288-tiers.sh
. "$ROOT/tools/_t1288-tiers.sh"
t1288_parse_args "$@"
t1288_hermetic "$0" "$@"
t1288_private_tmpdir
BRIDGE="$ROOT/tools/yaml-to-bpmn.py"
VALIDATOR="$ROOT/tools/validate-workflow.py"
CORPUS="$ROOT/examples/aef-processes"
TMP="$(mktemp -d)"
# T-1183 (P-015): everything this suite starts writes its temp files INSIDE $TMP, which the traps below remove on
# every exit. node tmpdir(), python tempfile, bash mktemp and headless Chromium's own org.chromium.Chromium.* folder
# all follow TMPDIR. Before this, ~112 browser tests (91 kill Chromium hard, 38 never remove their profile) left
# their folders in the host's shared /tmp: 1877 Chromium folders in 3 days.
export TMPDIR="$TMP"

# T-1211: one editor-readiness budget for every CDP probe (each reads CDP_READY_MS, else its own 20-30 s default).
# A full run keeps the host busy and a different probe used to miss its fixed 20 s each time (_t1060, then _t1194),
# while each passed alone. 90 s is several times the slowest cold load seen, and still a bound: a real hang fails.
# An operator's own value wins.
export CDP_READY_MS="${CDP_READY_MS:-90000}"

# T-1081: no leg reads the suite's stdin. When the suite runs under an agent or a pipe, that stdin
# is a pipe nobody closes, and any stray reader (a fileless `sed`, an accidental command
# substitution in heredoc prose) blocks until the leg's timeout — a 600 s hang reported as a red
# with nothing captured, which passes when the leg is run alone. /dev/null makes every leg see
# what it sees standalone: end of input.
exec </dev/null

pass=0
fail=0

# ── T-813 (value review F-03): run history ──────────────────────────────────────────────
#
# THE PROBLEM THIS SOLVES, in the review's words: this suite runs 131 passed / 7 failed and
# "no test-run artefact exists anywhere in the tree, so the age of the 7 failures is
# unknowable — UNMEASURED, not zero." Seven failures that might be seven days old or seven
# weeks old are not the same finding, and nothing could tell them apart. The same absence is
# why F-09's golden drift has no knowable age either.
#
# WHY AN EXIT TRAP AND NOT A LINE AT THE END. A line after the last check records only runs
# that reach it: a leg that calls `exit`, a Ctrl-C at minute nine of a twelve-minute suite, a
# SIGTERM from a future scheduler's timeout — all would leave no trace, and the gap would be
# invisible because the file would still look like a clean history. The runs most worth
# recording are exactly the ones a tail-of-script recorder drops.
#
# RECORDS EVERY OUTCOME, deliberately including red ones. A history that only captures green
# runs answers the opposite of the question being asked.
#
# The trap CHAINS the pre-existing TMP cleanup rather than replacing it — bash keeps one
# handler per signal, so adding a second `trap ... EXIT` would silently discard the first and
# leak a temp dir per run.
_T813_START=$(date +%s)
_T813_HISTORY="$ROOT/tests/.run-history.tsv"

_T813_RECORDED=0
_t813_record() {
    # ONCE PER RUN. A signal handler that re-raises (below) lets the EXIT trap fire too, so
    # without this guard every interrupted run wrote TWO records — one with the signal's
    # code and one with the shell's final status. Found by the control, not by reading:
    # a duplicated row would silently double the run count and make "how long has it been
    # red" answerable only by a human noticing the pairs.
    [ "$_T813_RECORDED" = "1" ] && return 0
    _T813_RECORDED=1
    [ "$T1288_LIST" = 1 ] && return 0   # T-1288: --list-legs runs nothing, so it records nothing
    local rc=$1
    local dur=$(( $(date +%s) - _T813_START ))
    local sha
    sha=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    # Tab-separated lines, appended. Append-only and never rewritten: this is a record of
    # what happened, not a cache of the current state. T-1288: the first six columns are as
    # before; tier, flaky and quarantined follow, and a --tier all run adds one row per tier
    # after its all-row (t1288_history_rows).
    t1288_history_rows "$rc" "$dur" "$sha" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        >> "$_T813_HISTORY" 2>/dev/null || true
}

trap '_t813_record "$?"; t1288_cleanup; rm -rf "$TMP"' EXIT
# INT/TERM are not covered by EXIT in every bash configuration when the shell is killed
# outright; re-raising after the handler preserves the true exit status for a caller.
trap '_t813_record 130; t1288_cleanup; rm -rf "$TMP"; trap - INT; kill -INT $$' INT
trap '_t813_record 143; t1288_cleanup; rm -rf "$TMP"; trap - TERM; kill -TERM $$' TERM

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
# T-967/T-973: a SECOND declared rule on the same map, declared just as answerably.
# W-XML-DISCONNECTED fires once: the operator saw by eye on 2026-10-01 that this map is two
# disjoint flows in one pool (session start -> persisted; complete -> stored), which is why
# the rule exists at all. Whether that is two processes or one with a missing link is a
# modelling question for the map's owner, not something to settle by drawing an edge here.
# The total must equal the sum of both counts, so any third rule still fails.
DECLARED_WARN_RULE2="W-XML-DISCONNECTED"
DECLARED_WARN_COUNT2=1
DECLARED_WARN_TASK2="T-967 (two disjoint flows, operator-observed)"

shopt -s nullglob
files=("$CORPUS"/*.workflow.yaml)
if [ "${#files[@]}" -eq 0 ]; then
  echo "ERROR: no corpus files found in $CORPUS"
  exit 1
fi

# T-1288: the quarantine (tests/quarantine.yaml), and the static tier guard: every leg is registered by a
# `leg <tier> ...` line with a known tier, and no counted check runs outside a registered leg.
t1288_load_quarantine
if [ "$T1288_LIST" = 0 ] && ! python3 "$ROOT/tools/_t1288-tier-guard.py" --static "$0" > "$TMP/leg-_t1288-guard.out" 2>&1; then  # T-1288: every tier
  report FAIL "a leg has no tier, or a counted check runs outside a registered leg (run 'python3 tools/_t1288-tier-guard.py --static tests/run-bridge-tests.sh'; T-1288)"
  show_output "$TMP/leg-_t1288-guard.out" "_t1288-tier-guard.py"
  fail=$((fail + 1))
fi

_leg_001() {
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
    got_declared2="$(grep -c "\[$DECLARED_WARN_RULE2\]" "$TMP/.out" || true)"
    got_total="$(grep -c "^WARN  \[" "$TMP/.out" || true)"
    if [ "$got_declared" -ne "$DECLARED_WARN_COUNT" ] || [ "$got_declared2" -ne "$DECLARED_WARN_COUNT2" ] \
       || [ "$got_total" -ne $((DECLARED_WARN_COUNT + DECLARED_WARN_COUNT2)) ]; then
      report FAIL "$base — declared ${DECLARED_WARN_COUNT}× ${DECLARED_WARN_RULE} + ${DECLARED_WARN_COUNT2}× ${DECLARED_WARN_RULE2} only; got ${got_declared} + ${got_declared2} and ${got_total} warning(s) total"
      show_output "$TMP/.out" "validator $base"
      fail=$((fail + 1))
    else
      report PASS "$base — ${DECLARED_WARN_COUNT}× ${DECLARED_WARN_RULE} (${DECLARED_WARN_TASK}) + ${DECLARED_WARN_COUNT2}× ${DECLARED_WARN_RULE2} (${DECLARED_WARN_TASK2}), declared"
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
}
leg core "corpus-roundtrip" _leg_001
_leg_002() {

echo
echo "== editor namespace consistency (T-044) =="
if python3 "$ROOT/tests/test_editor_namespace_consistency.py"; then
  pass=$((pass + 1))
else
  report FAIL "editor aef: namespace drifted from canonical"
  fail=$((fail + 1))
fi
}
leg core "test_editor_namespace_consistency" _leg_002
_leg_003() {

echo
echo "== editor extension shape consistency (T-053) =="
if python3 "$ROOT/tests/test_editor_extension_shape_consistency.py"; then
  pass=$((pass + 1))
else
  report FAIL "editor aef: field shape drifted from bridge (element text vs attribute)"
  fail=$((fail + 1))
fi
}
leg core "test_editor_extension_shape_consistency" _leg_003
_leg_004() {

echo
echo "== editor↔bridge field coverage (T-059) =="
if python3 "$ROOT/tests/test_editor_bridge_field_coverage.py"; then
  pass=$((pass + 1))
else
  report FAIL "bridge drops an editor-readable aef field present in the corpus"
  fail=$((fail + 1))
fi
}
leg core "test_editor_bridge_field_coverage" _leg_004
_leg_005() {

echo
echo "== editor↔bridge aef:meta parity (T-060) =="
if python3 "$ROOT/tests/test_editor_bridge_meta_parity.py"; then
  pass=$((pass + 1))
else
  report FAIL "bridge META_KEYS drops a scalar key the editor writes to <aef:meta>"
  fail=$((fail + 1))
fi
}
leg core "test_editor_bridge_meta_parity" _leg_005
_leg_006() {

echo
echo "== bridge aef.x-* passthrough + loud-drop (T-061) =="
if python3 "$ROOT/tests/test_bridge_aef_passthrough.py"; then
  pass=$((pass + 1))
else
  report FAIL "bridge aef.x-* passthrough broken or unknown keys dropped silently"
  fail=$((fail + 1))
fi
}
leg core "test_bridge_aef_passthrough" _leg_006
_leg_007() {

echo
echo "== editor↔bridge structured-key parity (T-063) =="
if python3 "$ROOT/tests/test_editor_bridge_structured_parity.py"; then
  pass=$((pass + 1))
else
  report FAIL "editor and bridge disagree on structured aef keys (import/export drift)"
  fail=$((fail + 1))
fi
}
leg core "test_editor_bridge_structured_parity" _leg_007
_leg_008() {

echo
echo "== designer→AEF promote contract (T-206) =="
if python3 "$ROOT/tests/test_promote_contract.py"; then
  pass=$((pass + 1))
else
  report FAIL "designer .bpmn export drifted from the AEF promote contract (uid / lane-authority / manifest-tuple / source_bpmn_sha)"
  fail=$((fail + 1))
fi
}
leg core "test_promote_contract" _leg_008
_leg_009() {

echo
echo "== two-lane joint promote fixture contract (T-208) =="
if python3 "$ROOT/tests/test_two_lane_joint_contract.py"; then
  pass=$((pass + 1))
else
  report FAIL "two-lane joint fixture drifted from the promote contract (uid / both-lane owner derivation / manifest-tuple / source_bpmn_sha)"
  fail=$((fail + 1))
fi
}
leg core "test_two_lane_joint_contract" _leg_009
_leg_010() {

echo
echo "== typed intermediate events: correctness + bite (T-204) =="
if python3 "$ROOT/tests/test_typed_events.py"; then
  pass=$((pass + 1))
else
  report FAIL "typed event error/timer/message decode/encode broke (type or aef:eventDef binding drift)"
  fail=$((fail + 1))
fi
}
leg browser "test_typed_events" _leg_010
_leg_011() {

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
}
leg core "test_typed_event_fixture_contract" _leg_011
_leg_012() {

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
}
leg core "test_note_capture_refuses_lost_payload" _leg_012
_leg_013() {

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
}
leg core "test_corpus_fixture_pins" _leg_013
_leg_014() {

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
}
leg browser "test_t259_eventdef_preservation" _leg_014
_leg_015() {

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
}
leg browser "test_t308_bare_catch_render" _leg_015
_leg_016() {

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
}
leg browser "test_t310_lane_position_conflict" _leg_016
_leg_017() {

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
}
leg core "test_t314_fixture_repin" _leg_017
_leg_018() {

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
}
leg browser "test_t315_lane_grow_on_import" _leg_018
_leg_019() {

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
}
leg browser "test_t311_doc_comment_roundtrip" _leg_019
_leg_020() {

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
}
leg core "test_t312_lane_geometry" _leg_020
_leg_021() {

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
}
leg core "test_t313_lane_capacity" _leg_021
_leg_022() {

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
}
leg browser "test_t258_annotation_seam" _leg_022
_leg_023() {

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
}
leg browser "test_editor_behavior" _leg_023
_leg_024() {

echo
echo "== endpoint reconnect reachability: handles above node bodies, real-input drag (T-293, G-003) =="
# The field-found frw_4_harvest case — endpoint grab halos must win the hit-test
# on the node border (isolated chromium, real Input.dispatchMouseEvent; also
# guards the T-286+T-293 canvas layer order).
if python3 "$ROOT/tests/test_t293_endpoint_reach.py"; then
  pass=$((pass + 1))
else
  report FAIL "endpoint reconnect reachability regressed — handle shadowed by node body/port dot or layer order broken (T-293/G-003 class)"
  fail=$((fail + 1))
fi
}
leg browser "test_t293_endpoint_reach" _leg_024
_leg_025() {

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
}
leg browser "test_t264_save_target_guards" _leg_025
_leg_026() {

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
}
leg browser "test_t125_lane_compaction" _leg_026
_leg_027() {

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
}
leg core "test_dead_leg_census" _leg_027

section "== Previously-unrun legs (T-316, AEF rail 347/349) =="
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
  "core|tests/test_forward_fixtures.py|forward-compile fixture contract"
  "browser|tests/test_roundtrip_serialization.py|round-trip serialization is no longer a semantic fixed point"
  "core|tests/test_mapping_standard_conformance.py|frozen governance meta-keys drifted from the mapping standard"
  "core|tests/test_validate_iw9.py|IW-9 validator rules (W-TYPE-LANE-MISMATCH / E-INCEPTION-NOT-SOVEREIGN) regressed"
  "core|tests/test_release_immutability.py|release immutability guard (G-007) — a released VERSION can be overwritten, or a release path (new, idempotent, blocked, bypass) stopped working; the test names the case"
  "browser|tests/test_bridge_seam_roundtrip.py|bridge emissions are being silently dropped on editor import"
  "browser|tests/test_designer_export_contract.py|designer export contract — an owner-bearing node lost its authority carrier"
  "browser|tests/test_designer_owner_derived.py|designer owner-derived guard — an editable owner override reappeared (IW-9)"
  "browser|tests/test_designer_render.py|designer render-check — render, T-177 markers, or inspector dropdowns broke"
  "core|tests/test_emitted_comment_claims.py|exported bytes carry a claim about an external party, or the emitter duplicates the trailer (T-361)"
  # T-942 wired both of these. Each was written and left uninvoked, which is the same defect
  # twice: T-884 shipped test_gallery_instances_api.py with the /api/instances endpoint and never
  # registered it; T-941 (mine) added test_boundary_inventory_unclassified.py in the same commit
  # as a learning about instruments nothing runs. The T-316 orphan guard below caught both — it
  # is the only reason either is here, and the reason it must never be relaxed to make a red run
  # green.
  "core|tests/test_gallery_instances_api.py|the /api/instances endpoint's own contract broke (T-884)"
  "core|tests/test_t1315_notes_pick.py|the host-contract notes check no longer reads the newest release notes at or above VERSION (it demands the published notes name an endpoint that release does not use, or reads a lower version's) (T-1315)"
  "core|tests/test_t1313_sandbox_index.py|a core-tier sandbox without its own .git can again reach this repo's index (GIT_CEILING_DIRECTORIES gone from the run TMPDIR), or .context/st/ is no longer ignored (T-1313)"
  "core|tests/test_t1307_t344_lock_wait.py|_t344 no longer waits out a full audit holding the lock, or reports a lock still held as a stale anchor instead of UNMEASURED (T-1307)"
  "core|tests/test_t1303_io_lint.py|mapping v1.1 io lint (R1 update/upsert/delete without a match field, R2 undeclared prefix, R3 match field naming nothing) stopped firing, fires on its exemptions, or lost its io location (T-1303)"
  "core|tests/test_t1312_field_catalog.py|GET /api/field-catalog no longer serves a v1 catalog, refuses a malformed one whole (422), answers 404 without one, or reads a path from the request (T-1312)"
  "core|tests/test_boundary_inventory_unclassified.py|the boundary inventory's unclassified-route check stopped biting, or the real route set went unclassified (T-941)"
  "core|tests/test_session_start_alerts.py|the /resume session-start check stopped delegating mail to fw sidecar alerts correctly: output or flags lost, a NOT CHECKED / failing / missing verb read as nothing, or the runme section hidden (T-1046, T-1059)"
  "core|tests/test_t1055_runme_launcher.py|the runme launcher no longer enforces the operator's safeguards itself: a job that runs at load time, has no dry-run, changed since its dry-run, or is already done can run, or a step runs without its y/N (T-1055)"
  "core|tests/test_t1286_rehearsal.py|runme --dry-run no longer rehearses a job's steps in a throwaway clone: a step a framework gate refuses passes the dry-run, a step_outward is executed in rehearsal, or the rehearsal changed the real repo (T-1286)"
  "core|tests/test_t1050_runme_alerts.py|the session-start check no longer tells a new session that a handed-over runme.sh has nothing watching it (WATCH LOST), or misreports an in-flight / unrecorded run (T-1050)"
  "core|tests/test_t1145_decision_handover_guard.py|the Stop hook no longer blocks a reply that hands the operator an unready inception's decision link, blocks a ready or link-free reply, loops, or fails closed (T-1145)"
)
# T-1288: each entry is its own leg, its tier the entry's first field (five of these drive a browser).
_orphan_leg() {
  local legfile="$1" legmsg="$2"
  local legpath="$ROOT/$legfile"
  if [ ! -f "$legpath" ]; then
    report FAIL "orphan leg names a file that does not exist: $legfile"
    fail=$((fail + 1))
    return 0
  fi
  if python3 "$legpath" >"$TMP/.legout" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "$legmsg ($legfile)"
    show_output "$TMP/.legout" "$legfile"
    fail=$((fail + 1))
  fi
}
for _ol in "${orphan_legs[@]}"; do
  _ol_tier="${_ol%%|*}"; _ol="${_ol#*|}"
  _ol_name="orphan:$(basename "${_ol%%|*}" .py)"
  leg "$_ol_tier" "$_ol_name" _orphan_leg "${_ol%%|*}" "${_ol#*|}"
done
section ""
_leg_028() {

echo
echo "== Render check on the SOURCE, before any cut (T-1130) =="
# The release-file render check above can only pass after a cut, so before a release it always reads
# 'artifact not found' and was written off as expected. On 0.18.0 that hid a real break (B1 folded the
# governance dropdowns the check looks for) until the operator's release run stopped on it. This leg checks
# the current source the same way, on every run.
if python3 "$ROOT/tests/test_designer_render.py" --src > "$TMP/leg-render-src.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "designer render-check on the SOURCE — render, T-177 markers, inspector dropdowns or console broke; the next release cut would stop on it (run 'python3 tests/test_designer_render.py --src'; T-1130)"
  show_output "$TMP/leg-render-src.out" "test_designer_render.py --src"
  fail=$((fail + 1))
fi
}
leg browser "test_designer_render" _leg_028
_leg_029() {

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
}
leg core "test_t317_gw_ambiguous_parity" _leg_029
_leg_030() {

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
}
leg core "test_xml_node_type_vocab" _leg_030
_leg_031() {

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
}
leg core "test_rule_form_parity" _leg_031
_leg_032() {

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
}
leg core "test_rule_dialect_axis" _leg_032
_leg_033() {

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
}
leg core "test_harness_emitter_fidelity" _leg_033
_leg_034() {

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
}
leg core "test_harness_cross_form_agreement" _leg_034
_leg_035() {

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
}
leg core "test_check_pass_reachability" _leg_035
_leg_036() {

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
}
leg core "test_finding_anchorability" _leg_036
_leg_037() {

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
}
leg browser "_t338-input-fidelity-cdp" _leg_037
_leg_038() {

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
}
leg browser "_roundtrip-serialization-cdp" _leg_038
_leg_039() {

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
}
leg browser "_t358-lane-provenance-cdp" _leg_039
_leg_040() {

echo
echo "== aef:note is authorable, and no carried key is invisible (T-566) =="
# Reported independently by 999-AEF (T-2974) and 001-CashWeb (T-064): `note` round-trips
# faithfully through save/load and is displayed nowhere. The teeth run the CDP probe on
# unmutated source first (control), then three mutants. Mutant A is the shipping code and
# must redden the note legs while leaving the DISCLOSURE legs green — with `note` unlisted
# the general branch is what catches it, which is the whole design point. Mutant B is the
# "just fix note" patch: it satisfies both reporters and leaves the shape that produced
# them intact. Mutant C shows every key and puts an edit box on the derived ones (T-197).
# Wired here in the same commit that adds it — a tool called only from a task's
# Verification block becomes unwired the moment that task completes (T-568's lesson).
if python3 "$ROOT/tools/_t566-note-field-teeth.py" > "$TMP/leg-_t566-note.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "aef:note stopped being authorable in the inspector, or a carried aef: key went invisible again (T-566 — run 'python3 tools/_t566-note-field-teeth.py'; a mutant that reddens MORE than its own legs is not discriminating, and CANNOT RUN is not a pass)"
  show_output "$TMP/leg-_t566-note.out" "_t566-note-field-teeth.py"
  fail=$((fail + 1))
fi
}
leg browser "_t566-note-field-teeth" _leg_040
_leg_041() {

echo
echo "== the editor does not destroy aef:meta keys it does not name (T-570) =="
# Import reads EVERY <aef:meta> attribute into node.aef; export emitted only the metaKeys
# whitelist. A key in the document and not on that list was loaded, shown nowhere, and
# DESTROYED on the next save — measured by a real round trip, not by reading the two lists:
# determinism (16), sideEffect (2) and a scalar emits (1) did not survive, while endpoint
# (10) did, because it has its own element emitter. Mutant D is the tempting narrow fix
# (widen metaKeys by the keys the census found) and must leave carried-escaping GREEN where
# mutant A reddens it — repairing the sample and repairing the mechanism are different, and
# this leg is what tells them apart. Wired here in the same commit that adds it (T-568).
if python3 "$ROOT/tools/_t570-meta-carriage-teeth.py" > "$TMP/leg-_t570-carriage.out" 2>&1; then
  pass=$((pass + 1))
elif grep -q '^COULD NOT MEASURE' "$TMP/leg-_t570-carriage.out"; then
  # T-1060: still red, but not a verdict on the editor — the probe never ran
  report FAIL "T-570 meta-carriage teeth COULD NOT MEASURE (the probe did not run — environment, not the editor): $(grep -m1 '^COULD NOT MEASURE' "$TMP/leg-_t570-carriage.out" | cut -c1-140)"
  show_output "$TMP/leg-_t570-carriage.out" "_t570-meta-carriage-teeth.py"
  fail=$((fail + 1))
else
  report FAIL "the editor started dropping aef:meta keys it does not name, or grew a second carrier for one that has an emitter (T-570 — run 'python3 tools/_t570-meta-carriage-teeth.py'; a mutant that reddens MORE than its own legs is not discriminating, and CANNOT RUN is not a pass)"
  show_output "$TMP/leg-_t570-carriage.out" "_t570-meta-carriage-teeth.py"
  fail=$((fail + 1))
fi
}
leg browser "_t570-meta-carriage-teeth" _leg_041
_leg_042() {

# T-1060: the CDP probes wait for the ?load= map itself, not a fixed 400 ms after _appReady. On a busy
# host the old wait lost the race and two guards reported CANNOT RUN, read here as regressions.
if bash "$ROOT/tools/_t1060-slow-load-teeth.sh" > "$TMP/leg-_t1060.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a CDP probe again races the editor's ?load= fetch (a slow-loading editor makes it report CANNOT RUN), or the control no longer reaches the race (run 'bash tools/_t1060-slow-load-teeth.sh'; T-1060)"
  show_output "$TMP/leg-_t1060.out" "_t1060-slow-load-teeth.sh"
  fail=$((fail + 1))
fi
}
leg browser "_t1060-slow-load-teeth" _leg_042
_leg_043() {

# T-1061: the editor's own "deep link settled" signal, which every CDP probe now waits on.
if node "$ROOT/tools/_t1061-deeplink-settled-cdp.mjs" > "$TMP/leg-_t1061.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the editor's _deepLinkSettled signal is wrong in some state (none / adopted / failed / null-until-settled) — every CDP probe waits on it (run 'node tools/_t1061-deeplink-settled-cdp.mjs'; T-1061)"
  show_output "$TMP/leg-_t1061.out" "_t1061-deeplink-settled-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1061-deeplink-settled-cdp" _leg_043
_leg_044() {

# T-1067: a side-placed event label that collides on every side is tried as a wrapped block
# (reviewer RED on T-600: the operator's own sentence never wrapped). Control = the pre-T-1067 editor.
if node "$ROOT/tools/_t1067-side-label-wrap-cdp.mjs" > "$TMP/leg-_t1067.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a colliding event label is no longer tried as a wrapped block, the wrap preference or a short label is disturbed, or the settings controls lag the stored prefs (run 'node tools/_t1067-side-label-wrap-cdp.mjs'; T-1067)"
  show_output "$TMP/leg-_t1067.out" "_t1067-side-label-wrap-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1067-side-label-wrap-cdp" _leg_044

# T-1068: the label-placement guards for T-600 (wrap) and T-601 (pool/lane containment) were never
# wired — T-601's self-test went red unnoticed (its poison target drifted, and L2 could not fail).
# Run both in --self-test mode: the live legs AND the poison arms that prove each leg can fail.
# Each guard is named on its own line (T-1079): the unwired-guard census reads `tools/<name>` in
# executable code, and a `for` loop over bare names is invisible to it — once T-1068 closed, two of
# these read as "no live caller" although this suite runs them.
_label_guard() {
  local _lg; _lg="$(basename "$1")"
  if node "$1" --self-test > "$TMP/leg-$_lg.out" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "label-placement guard $_lg failed or its self-test no longer proves its legs can fail (run 'node tools/$_lg --self-test'; T-600/T-601/T-1068)"
    show_output "$TMP/leg-$_lg.out" "$_lg"
    fail=$((fail + 1))
  fi
}
_leg_045() {
_label_guard "$ROOT/tools/_t600-label-wrap.mjs"
}
leg browser "_t600-label-wrap" _leg_045
_leg_046() {
_label_guard "$ROOT/tools/_t601-lane-boundary.mjs"
}
leg browser "_t601-lane-boundary" _leg_046
_leg_047() {
_label_guard "$ROOT/tools/_t1068-corpus-labels.mjs"
}
leg browser "_t1068-corpus-labels" _leg_047
_leg_048() {

# T-1069 (reviewer AMBER on T-893): the authority marker stays left of the shape's top-centre, so no
# marker sits under its node's own flows (forced 'missing' and 'differs' on every corpus node), and
# every marker keeps its full text as a <title>. Self-test: the full-length form always drawn -> M1 fails.
if node "$ROOT/tools/_t1069-authority-marker-clearance-cdp.mjs" --self-test > "$TMP/leg-_t1069.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an authority marker sits under its node's own edges, lost its full-text title, or the guard stopped biting (run 'node tools/_t1069-authority-marker-clearance-cdp.mjs --self-test'; T-1069, T-893)"
  show_output "$TMP/leg-_t1069.out" "_t1069-authority-marker-clearance-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1069-authority-marker-clearance-cdp" _leg_048
_leg_049() {

# T-1088 (aef-greenfield-test T-172 #2): BPMN import makes lane abbreviations unique — three lanes
# deriving 'tac' and two with the same laneMeta abbr get distinct prefixes, node ids stay distinct,
# and the saved XML has no duplicate id (it had: tac_1_check x3, sal_1_check x2, plus their shapes).
if node "$ROOT/tools/_t1088-lane-abbr-unique-cdp.mjs" > "$TMP/leg-_t1088.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "imported lanes share an abbreviation again, so node ids collide and the saved BPMN has duplicate ids (run 'node tools/_t1088-lane-abbr-unique-cdp.mjs'; T-1088)"
  show_output "$TMP/leg-_t1088.out" "_t1088-lane-abbr-unique-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1088-lane-abbr-unique-cdp" _leg_049
_leg_050() {

# T-1089 (aef-greenfield-test T-172 #5): a map opened from a project saves as that project's next
# version. A file without aef:workflowMeta takes the project id (it saved as a NEW project process_x
# v1); a declared id is kept (T-263) and Save asks before writing elsewhere; a user import is unchanged.
if node "$ROOT/tools/_t1089-save-loaded-as-version-cdp.mjs" > "$TMP/leg-_t1089.out" 2>&1 \
   && grep -q "7/7 legs passed" "$TMP/leg-_t1089.out"; then
  pass=$((pass + 1))
else
  report FAIL "Save of a map opened from a project no longer lands as that project's next version, a declared id is overridden, or the different-project confirm is gone (run 'node tools/_t1089-save-loaded-as-version-cdp.mjs'; T-1089)"
  show_output "$TMP/leg-_t1089.out" "_t1089-save-loaded-as-version-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1089-save-loaded-as-version-cdp" _leg_050
_leg_051() {

# T-1090 (aef-greenfield-test T-172 #1): auto-routed cross-lane flows take ONE bend — an L leaving
# N/S and entering W, or leaving E when that corner is blocked; the Z only when both are; same-lane
# flows stay straight; no flow cuts a box; the Settings toggle restores the old route; DI agrees.
if node "$ROOT/tools/_t1090-cross-lane-l-routing-cdp.mjs" > "$TMP/leg-_t1090.out" 2>&1 \
   && grep -q "14/14 legs passed" "$TMP/leg-_t1090.out"; then   # T-1110: +2 mirror-L legs
  pass=$((pass + 1))
else
  report FAIL "cross-lane flows are no longer routed as a one-bend L (or an L cuts a box, the fallback/Z choice broke, the toggle no longer restores the old route, or the exported DI disagrees with the canvas) (run 'node tools/_t1090-cross-lane-l-routing-cdp.mjs'; T-1090)"
  show_output "$TMP/leg-_t1090.out" "_t1090-cross-lane-l-routing-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1090-cross-lane-l-routing-cdp" _leg_051
_leg_052() {

# T-1092 (aef-greenfield-test T-172 #6, operator option 3): authority markers are a Setting, default
# ON (T-888 clause 4); a map that declares no authority anywhere shows ONE summary in the advisory
# dock instead of a marker per element; a map that declares any authority keeps per-element markers.
if node "$ROOT/tools/_t1092-authority-summary-cdp.mjs" > "$TMP/leg-_t1092.out" 2>&1 \
   && grep -q "11/11 legs passed" "$TMP/leg-_t1092.out"; then
  pass=$((pass + 1))
else
  report FAIL "authority markers: the default is no longer ON, a no-authority map draws per-element markers instead of one summary (or the summary covers the canvas / ignores dismiss), a map with declared authority lost its markers, or the Settings toggle stopped working or persisting (run 'node tools/_t1092-authority-summary-cdp.mjs'; T-1092)"
  show_output "$TMP/leg-_t1092.out" "_t1092-authority-summary-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1092-authority-summary-cdp" _leg_052
_leg_053() {

# T-1109 (aef-greenfield-test's 0.16.0 re-test): a same-origin ?load=/api/version?id=X deep link opens as
# project X — a file without a workflow id takes X, Save writes X's next version with no confirm; a declared
# id is kept and Save asks naming X; a plain-file ?load and cross-origin sources are not project loads.
if node "$ROOT/tools/_t1109-deeplink-project-load-cdp.mjs" > "$TMP/leg-_t1109.out" 2>&1 \
   && grep -q "8/8 legs passed" "$TMP/leg-_t1109.out"; then
  pass=$((pass + 1))
else
  report FAIL "a project deep link (?load=/api/version?id=X) no longer opens as project X: the id is guessed from the file, Save asks a false 'Loaded from' confirm or writes a process_* project, or a non-project ?load is now treated as one (run 'node tools/_t1109-deeplink-project-load-cdp.mjs'; T-1109)"
  show_output "$TMP/leg-_t1109.out" "_t1109-deeplink-project-load-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1109-deeplink-project-load-cdp" _leg_053
_leg_054() {

# T-1119 (P1 of the operator's T-347 ruling): open + save of a BPMN collaboration keeps every pool (incl.
# black-box), every process not opened and every message flow with its DI; message-flow ends are re-pointed
# to the ids written on save; our pool is the participant whose processRef is the opened process.
if node "$ROOT/tools/_t1119-collaboration-roundtrip-cdp.mjs" > "$TMP/leg-_t1119.out" 2>&1 \
   && grep -q "18/18 legs passed" "$TMP/leg-_t1119.out"; then
  pass=$((pass + 1))
else
  report FAIL "a BPMN collaboration loses pools or message flows on save again, a kept message flow points at an id the save no longer writes, a flow joins one pool to itself, or the wrong participant is taken as our pool (run 'node tools/_t1119-collaboration-roundtrip-cdp.mjs'; T-1119)"
  show_output "$TMP/leg-_t1119.out" "_t1119-collaboration-roundtrip-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1119-collaboration-roundtrip-cdp" _leg_054
_leg_055() {

# T-1120 (P2): the kept pools are drawn read-only below ours and the message flows run between them (dashed,
# open circle at the source, open arrowhead at the target); a flow follows a dragged node; the exported DI
# equals the canvas (one layout); flows between the same two ends are drawn apart.
if node "$ROOT/tools/_t1120-collab-pools-drawn-cdp.mjs" > "$TMP/leg-_t1120.out" 2>&1 \
   && grep -q "7/7 legs passed" "$TMP/leg-_t1120.out"; then
  pass=$((pass + 1))
else
  report FAIL "the other pools of a collaboration are no longer drawn, a message flow lost its BPMN look, no longer follows a dragged node, lies on top of another, or the exported DI differs from the canvas (run 'node tools/_t1120-collab-pools-drawn-cdp.mjs'; T-1120)"
  show_output "$TMP/leg-_t1120.out" "_t1120-collab-pools-drawn-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1120-collab-pools-drawn-cdp" _leg_055
_leg_056() {

# T-1124 (T-1118 B1): empty Extensions fields fold into one "+ N empty fields" row; a field with a value is
# never hidden (all 42 examples/ service tasks); "Show all fields" restores the old panel; export unchanged.
if node "$ROOT/tools/_t1124-hide-empty-fields-cdp.mjs" > "$TMP/leg-_t1124.out" 2>&1 \
   && grep -q "T-1124: 10/10" "$TMP/leg-_t1124.out"; then
  pass=$((pass + 1))
else
  report FAIL "the properties panel draws empty fields again, hides a field that has a value, the fold row or 'Show all fields' broke, or the setting changes the export (run 'node tools/_t1124-hide-empty-fields-cdp.mjs'; T-1124)"
  show_output "$TMP/leg-_t1124.out" "_t1124-hide-empty-fields-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1124-hide-empty-fields-cdp" _leg_056
_leg_057() {

# T-1125 (T-1118 B2): the project field profile (field-profile.json, GET /api/field-profile) hides and pins
# fields; a hidden field with a value is still drawn and tagged; a malformed profile is refused whole;
# standalone falls back to the designer default; export unchanged.
if node "$ROOT/tools/_t1125-field-profile-cdp.mjs" > "$TMP/leg-_t1125.out" 2>&1 \
   && grep -q "T-1125: 9/9" "$TMP/leg-_t1125.out"; then
  pass=$((pass + 1))
else
  report FAIL "the project field profile is not served, not applied, hides a field that has a value, half-applies a malformed profile, or changes the export (run 'node tools/_t1125-field-profile-cdp.mjs'; T-1125)"
  show_output "$TMP/leg-_t1125.out" "_t1125-field-profile-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1125-field-profile-cdp" _leg_057
_leg_058() {

# T-1128: the field-profile write path (PUT, project and per-map scope): malformed refused whole, a profile changed
# since it was read refused 409, bad id refused, atomic, one history line per write.
if python3 "$ROOT/tools/_t1128-field-profile-server.py" > "$TMP/leg-_t1128s.out" 2>&1 \
   && grep -q "T-1128 server: 8/8" "$TMP/leg-_t1128s.out"; then
  pass=$((pass + 1))
else
  report FAIL "the field-profile write path broke — a malformed or stale profile was written, a bad id accepted, or history/atomicity lost (run 'python3 tools/_t1128-field-profile-server.py'; T-1128)"
  show_output "$TMP/leg-_t1128s.out" "_t1128-field-profile-server.py"
  fail=$((fail + 1))
fi
}
leg core "_t1128-field-profile-server" _leg_058
_leg_059() {

# T-1128: Settings → "Fields shown by default", per project and per map (map wins for the fields it mentions,
# the rest falls through); provenance shown; 409 surfaced; Cancel discards; new id starts clean; export unchanged.
if node "$ROOT/tools/_t1128-field-defaults-settings-cdp.mjs" > "$TMP/leg-_t1128.out" 2>&1 \
   && grep -q "T-1128: 9/9" "$TMP/leg-_t1128.out"; then
  pass=$((pass + 1))
else
  report FAIL "Settings no longer edits the default fields per project/map, the map no longer wins (or no longer falls through), provenance or the 409 message is lost, or a profile changes the export (run 'node tools/_t1128-field-defaults-settings-cdp.mjs'; T-1128)"
  show_output "$TMP/leg-_t1128.out" "_t1128-field-defaults-settings-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1128-field-defaults-settings-cdp" _leg_059
_leg_060() {

# T-1127: the element details view — double-click (or the panel's "All details") shows every field of the element,
# filled or empty, profile-hidden ones marked; edits land on the element; Esc/Close/backdrop close it; a handoff
# keeps its double-click jump; fits 1024x768.
if node "$ROOT/tools/_t1127-element-details-cdp.mjs" > "$TMP/leg-_t1127.out" 2>&1 \
   && awk -F'[ /]' '/^T-1127: [0-9]+\/[0-9]+$/ { if ($2 == $3 && $2 > 0) ok = 1 } END { exit !ok }' "$TMP/leg-_t1127.out"; then   # all legs, however many (T-1209 added G)
  pass=$((pass + 1))
else
  report FAIL "the element details view no longer opens, no longer shows every field, writes elsewhere than the panel, leaks keys to the canvas, or broke the handoff jump (run 'node tools/_t1127-element-details-cdp.mjs'; T-1127)"
  show_output "$TMP/leg-_t1127.out" "_t1127-element-details-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1127-element-details-cdp" _leg_060
_leg_061() {

# T-1129: every optional select offers an empty choice — an unset field must not DISPLAY (and write on change) its
# first option; export of the examples identical to 0.17.0.
if node "$ROOT/tools/_t1129-optional-select-empty-cdp.mjs" > "$TMP/leg-_t1129.out" 2>&1 \
   && grep -q "T-1129: 5/5" "$TMP/leg-_t1129.out"; then
  pass=$((pass + 1))
else
  report FAIL "an optional select lost its empty choice (an unset field would show and write a value the document does not carry), or the export moved (run 'node tools/_t1129-optional-select-empty-cdp.mjs'; T-1129)"
  show_output "$TMP/leg-_t1129.out" "_t1129-optional-select-empty-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1129-optional-select-empty-cdp" _leg_061
_leg_062() {

# T-1126 (T-1118 B3): "Suggest as a field" records a suggestion (never a field); only the operator's
# tools/field-suggestion.py approves (writing the profile's fields section, refused without approval) or rejects.
if node "$ROOT/tools/_t1126-field-suggestions-cdp.mjs" > "$TMP/leg-_t1126.out" 2>&1 \
   && grep -q "T-1126: 8/8" "$TMP/leg-_t1126.out"; then
  pass=$((pass + 1))
else
  report FAIL "field suggestions broke — a suggestion no longer records, became a field without approval, an approved field is not drawn/editable/exported, or a derived key is offered (run 'node tools/_t1126-field-suggestions-cdp.mjs'; T-1126)"
  show_output "$TMP/leg-_t1126.out" "_t1126-field-suggestions-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1126-field-suggestions-cdp" _leg_062
_leg_063() {

# T-1096: process-level data survives a save — dataObject, dataObjectReference, dataStoreReference, the tasks'
# property / dataInput / dataOutputAssociation and their DI; nothing dangles; a deleted task takes its associations.
if node "$ROOT/tools/_t1096-data-objects-roundtrip-cdp.mjs" > "$TMP/leg-_t1096.out" 2>&1 \
   && grep -q "T-1096: 13/13" "$TMP/leg-_t1096.out"; then
  pass=$((pass + 1))
else
  report FAIL "process data (data objects, data stores, data associations or their DI) is dropped on save again, a reference dangles, or a deleted task left its associations behind (run 'node tools/_t1096-data-objects-roundtrip-cdp.mjs'; T-1096)"
  show_output "$TMP/leg-_t1096.out" "_t1096-data-objects-roundtrip-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1096-data-objects-roundtrip-cdp" _leg_063
_leg_064() {

# ── T-1217: a native bpmn:linkEventDefinition (third-party link pairing) survives open and save ──
# The designer encodes link events as aef:link (T-190 IW-1) and dropped the native element, losing the pairing
# (aef-greenfield-test, 25 maps). Red against the pre-T-1217 source (legs 1, 2, 3, 5).
if node "$ROOT/tools/_t1217-native-link-definition-cdp.mjs" > "$TMP/leg-_t1217.out" 2>&1 \
   && head -2 "$TMP/leg-_t1217.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "a native linkEventDefinition is dropped or misplaced on save again, its name no longer seeds or follows the linkId, a second save differs, or a link event without one now emits one (run 'node tools/_t1217-native-link-definition-cdp.mjs'; T-1217)"
  show_output "$TMP/leg-_t1217.out" "_t1217-native-link-definition-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1217-native-link-definition-cdp" _leg_064
_leg_065() {

# ── T-1218: an unnamed start/end event stays unnamed through open and save, with its display id unchanged ──
# The import used the id as the name, so the canvas showed "StartEvent_1" and the save wrote it back
# (aef-greenfield-test, 41 maps). Red against the pre-T-1218 source (legs 1 and 6).
if node "$ROOT/tools/_t1218-unnamed-event-name-cdp.mjs" > "$TMP/leg-_t1218.out" 2>&1 \
   && head -2 "$TMP/leg-_t1218.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "an unnamed start/end event is saved with a name again (its id), its display id moved, a second save renames it, a named event lost its name, or a cleared name saved as name=\"\" (run 'node tools/_t1218-unnamed-event-name-cdp.mjs'; T-1218)"
  show_output "$TMP/leg-_t1218.out" "_t1218-unnamed-event-name-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1218-unnamed-event-name-cdp" _leg_065
_leg_066() {

# T-1218's rendered side: the canvas labels of the two unnamed events read their ids BEFORE (HEAD's source) and are
# empty AFTER, at 1024/1440/1920. Screenshots go to the run's temp dir, never into docs/.
if timeout 600 python3 "$ROOT/tools/_t1218-unnamed-event-shots.py" "$TMP/t1218-shots" > "$TMP/leg-_t1218-shots.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the canvas shows an unnamed start/end event's id as its label again, or HEAD no longer reproduces the old label (run 'python3 tools/_t1218-unnamed-event-shots.py /tmp/x'; T-1218)"
  show_output "$TMP/leg-_t1218-shots.out" "_t1218-unnamed-event-shots.py"
  fail=$((fail + 1))
fi
}
leg browser "_t1218-unnamed-event-shots" _leg_066
_leg_067() {

# ── T-1222: native BPMN event definitions survive a save; third-party boundary events stay boundary events ──
# Saves every third-party fixture through the real designer and counts *EventDefinition per kind (49 -> 3 before),
# checks referenced root elements resolve, hosts keep their tag, boundaries keep attachedToRef, and no aef:eventDef
# is added by an unedited save. The shots tool asserts the canvas (types, boundaries on hosts) at three widths.
if timeout 900 python3 "$ROOT/tools/_t1222-event-definitions-kept.py" > "$TMP/leg-_t1222.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a native event definition is lost, misplaced or dangling on save again, a boundary event lost its attachment, or an unedited save added aef:eventDef (run 'python3 tools/_t1222-event-definitions-kept.py'; T-1222)"
  show_output "$TMP/leg-_t1222.out" "_t1222-event-definitions-kept.py"
  fail=$((fail + 1))
fi
}
leg browser "_t1222-event-definitions-kept" _leg_067
_leg_068() {
if timeout 600 python3 "$ROOT/tools/_t1222-event-shots.py" "$TMP/t1222-shots" > "$TMP/leg-_t1222-shots.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "third-party event kinds render wrong again: a boundary event is not on its host, a timer/message catch lost its type, or a plain event became a link (run 'python3 tools/_t1222-event-shots.py /tmp/x'; T-1222)"
  show_output "$TMP/leg-_t1222-shots.out" "_t1222-event-shots.py"
  fail=$((fail + 1))
fi
}
leg browser "_t1222-event-shots" _leg_068
_leg_069() {

# ── T-1243: CHILD elements inside aef:input/aef:output survive open and save, adding no xmlns noise ──
# A producer's nested attribute tree, a schema reference or any extension child was dropped (T-1220 kept only
# attributes); asked by aef-greenfield-test and both external reviewers of T-1242. Red against the pre-T-1243 source.
if node "$ROOT/tools/_t1243-io-children-cdp.mjs" > "$TMP/leg-_t1243.out" 2>&1 \
   && head -2 "$TMP/leg-_t1243.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "child elements inside aef:input/aef:output are dropped, reordered or re-declared on save, a second save differs, an edited input lost them, or a plain io stopped being self-closing (run 'node tools/_t1243-io-children-cdp.mjs'; T-1243)"
  show_output "$TMP/leg-_t1243.out" "_t1243-io-children-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1243-io-children-cdp" _leg_069
_leg_070() {

# ── T-1249: every mapping v1.1 io construct is shown read-only and saved byte-exactly ──
# Slice 1 of T-1242. AEF's section-11 examples (+ process aef:meta), every tracked map with io and greenfield's VZN-T1
# (when present) keep their io bytes; the io panel shows each v1.1 construct, the workflow panel mappingVersion and the
# prefixes; a v1 io shows nothing new. Red on the pre-T-1249 source and with the display disabled (T1249_BITE=display).
if node "$ROOT/tools/_t1249-v11-io-cdp.mjs" > "$TMP/leg-_t1249.out" 2>&1 \
   && head -2 "$TMP/leg-_t1249.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "a mapping v1.1 io construct is not shown read-only, a v1 io grew a v1.1 section, or open+save changed io or process aef:meta bytes (a nameless io dropped, attributes reordered, a producer's io layout rewritten) (run 'node tools/_t1249-v11-io-cdp.mjs'; T-1249)"
  show_output "$TMP/leg-_t1249.out" "_t1249-v11-io-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1249-v11-io-cdp" _leg_070
_leg_196() {

# ── T-1301: the io attributes are editable, and a save writes exactly the edit ──
# Slice 2 of T-1242 (arc-006). Each attribute set and cleared through its own control changes exactly that attribute;
# an attribute added to a raw-layout item (greenfield's one-line style A) is written, not dropped; no mappingVersion or
# prefixes appear unasked; an undeclared prefix is hinted; ref suggests the map's refs; the editor is closed by default.
# Red on the pre-T-1301 source (T1301_SRC).
if node "$ROOT/tools/_t1301-io-edit-cdp.mjs" > "$TMP/leg-_t1301.out" 2>&1 \
   && head -2 "$TMP/leg-_t1301.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "an io attribute edit is not written exactly (dropped on a raw-layout item, another attribute or step changed, a silent mappingVersion), or the editor's controls, hint or ref suggestions are missing (run 'node tools/_t1301-io-edit-cdp.mjs'; T-1301)"
  show_output "$TMP/leg-_t1301.out" "_t1301-io-edit-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1301-io-edit-cdp" _leg_196
_leg_197() {

# ── T-1312: the ref field offers a searchable picker over the project's field catalog ──
# Against the real reference server: no catalog (404) leaves the editor as before; with one, a search under ref lists at
# most 8 hits (notation, label); a hit writes ref, and dataType only when the io has none; a re-render keeps the search;
# other steps byte-exact; the picker lies inside the editor at 1024 and 1440. Red on the 0.29.0 source (T1312_SRC).
if node "$ROOT/tools/_t1312-catalog-picker-cdp.mjs" > "$TMP/leg-_t1312.out" 2>&1 \
   && head -2 "$TMP/leg-_t1312.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "the field-catalog ref picker is missing, overwrites a producer's dataType, loses its search on a re-render, changes another step, or shows without a catalog (run 'node tools/_t1312-catalog-picker-cdp.mjs'; T-1312)"
  show_output "$TMP/leg-_t1312.out" "_t1312-catalog-picker-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1312-catalog-picker-cdp" _leg_197
_leg_198() {

# ── T-1310: the io row's and field row's "req" and "×" are legible and big enough to hit ──
# Measured in the rendered designer at 1024 and 1440: label contrast >= 4.5:1, × >= 3:1 against the effective
# background, clickable box >= 24×24 px (WCAG 2.2 target minimum). Red on the 0.30.0 source (2.84:1, 37×14.5 and 15.6×14).
if node "$ROOT/tools/_t1310-req-x-cdp.mjs" > "$TMP/leg-_t1310.out" 2>&1 \
   && head -2 "$TMP/leg-_t1310.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "an io/field row's req or × is below AA contrast or the 24×24 px target size again (run 'node tools/_t1310-req-x-cdp.mjs'; T-1310)"
  show_output "$TMP/leg-_t1310.out" "_t1310-req-x-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1310-req-x-cdp" _leg_198
_leg_200() {

# ── T-1303: after Check, a mapping v1.1 lint finding shows under the io row it names ──
# The real editor against the real server's /api/validate: each finding under its own io (input vs output, index and
# name), none on a clean io or step (that panel unchanged), drawer and canvas unchanged, a renamed io and a closed
# drawer show none, every line inside the panel at 1024 and 1440. Red on the 0.30.0 source (a, b, f).
if node "$ROOT/tools/_t1303-io-findings-cdp.mjs" > "$TMP/leg-_t1303.out" 2>&1 \
   && head -2 "$TMP/leg-_t1303.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "a Check finding on an io no longer shows under that io's row, shows under the wrong one, or changes a clean step's panel (run 'node tools/_t1303-io-findings-cdp.mjs'; T-1303)"
  show_output "$TMP/leg-_t1303.out" "_t1303-io-findings-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1303-io-findings-cdp" _leg_200
_leg_201() {

# ── T-1265: a sequence flow's conditionExpression keeps its language and id on open and save ──
# Import kept only the text, export wrote a fixed element: language="javascript" was dropped and the engine fell back
# to its default language (ring20 cloud job C, F7). Red against the pre-T-1265 source (legs 1, 3, 5).
if node "$ROOT/tools/_t1265-condition-language-cdp.mjs" > "$TMP/leg-_t1265.out" 2>&1 \
   && head -2 "$TMP/leg-_t1265.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "a conditionExpression lost its language or id on save, a second save differs, a text edit dropped the language, or a plain condition changed (run 'node tools/_t1265-condition-language-cdp.mjs'; T-1265)"
  show_output "$TMP/leg-_t1265.out" "_t1265-condition-language-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1265-condition-language-cdp" _leg_201
_leg_202() {

# ── T-1268: an aef element on a node that the designer does not read survives open and save ──
# Import read only the aef children it names, so an element a newer AEF or bridge wrote was wiped by one save (ring20
# cloud job C, F10). Red against the pre-T-1268 source (legs 1, 3).
if node "$ROOT/tools/_t1268-node-aef-children-cdp.mjs" > "$TMP/leg-_t1268.out" 2>&1 \
   && head -2 "$TMP/leg-_t1268.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "an aef element the designer does not read was dropped or reordered on a node's save, a second save differs, a rename lost it, or a plain node's extension changed (run 'node tools/_t1268-node-aef-children-cdp.mjs'; T-1268)"
  show_output "$TMP/leg-_t1268.out" "_t1268-node-aef-children-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1268-node-aef-children-cdp" _leg_202
_leg_203() {

# ── T-1325: a flow node or flow keeps the attributes and children the designer does not read ──
# T-1322 GO slice 1, T-347 ruling (a): vendor attributes/extensions, standard attributes and children, a gateway's
# default by its flow's current id, retype rule, second save stable, no designer map grows a key. Red against the
# pre-T-1325 source (legs 1-4).
if node "$ROOT/tools/_t1325-element-passthrough-cdp.mjs" > "$TMP/leg-_t1325.out" 2>&1 \
   && head -2 "$TMP/leg-_t1325.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "an element lost an attribute or child the designer does not read, a gateway's default no longer follows its flow, a retype kept the old tag's content, a second save differs, or a designer-written map grew a kept key (run 'node tools/_t1325-element-passthrough-cdp.mjs'; T-1325)"
  show_output "$TMP/leg-_t1325.out" "_t1325-element-passthrough-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1325-element-passthrough-cdp" _leg_203
_leg_204() {

# ── T-1326: process, collaboration and root content the designer does not model is kept ──
# T-1322 GO slice 2: annotations, associations (ends at current ids, dropped with their DI when an end is deleted),
# groups and their categories, documentation/attributes/extensions on process, collaboration, our pool and the root, and
# a flow's documentation. Red against the pre-T-1326 source (legs 1-4).
if node "$ROOT/tools/_t1326-process-level-kept-cdp.mjs" > "$TMP/leg-_t1326.out" 2>&1 \
   && head -2 "$TMP/leg-_t1326.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "an annotation, association, group or category, or the documentation, attributes or extensions of the process, collaboration, pool or root, or a flow's documentation, was dropped or misplaced on save; an association no longer follows its end; a second save differs; or a designer-written map grew a key (run 'node tools/_t1326-process-level-kept-cdp.mjs'; T-1326)"
  show_output "$TMP/leg-_t1326.out" "_t1326-process-level-kept-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1326-process-level-kept-cdp" _leg_204
_leg_205() {

# ── T-1327: comments among the process's children are kept, and the import notice names what a save does not keep ──
# T-1322 GO slice 3 (F11 + option C): a comment before its element (end of process when the element is gone), second
# save stable; the notice counts subprocess contents moved up, nested lanes flattened, a redrawn layout and the kept
# annotations/groups, and shows none of it for a designer-written map. Red against the pre-T-1327 source (legs 1-3).
if node "$ROOT/tools/_t1327-comments-and-notice-cdp.mjs" > "$TMP/leg-_t1327.out" 2>&1 \
   && head -2 "$TMP/leg-_t1327.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "a process comment was dropped or moved on save, a second save differs, or the import notice no longer says what a save of the file does not keep (or says it for a designer-written map) (run 'node tools/_t1327-comments-and-notice-cdp.mjs'; T-1327)"
  show_output "$TMP/leg-_t1327.out" "_t1327-comments-and-notice-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1327-comments-and-notice-cdp" _leg_205
_leg_206() {

# ── T-1327: the import notice as a person sees it, measured at 1024/1440/1920 ──
# The shot tool's own measures: the notice inside the viewport, its text not clipped, no node under it, every header
# button on screen, no notice on a designer-written map. Shots go to $TMP, not the evidence folder.
if node "$ROOT/tools/_t1327-notice-shots.mjs" "$TMP/t1327-shots" > "$TMP/leg-_t1327s.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the import notice is clipped, off-screen, over a node, pushes a header button off-screen, or shows on a designer-written map (run 'node tools/_t1327-notice-shots.mjs /tmp/out'; T-1327)"
  show_output "$TMP/leg-_t1327s.out" "_t1327-notice-shots.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1327-notice-shots" _leg_206
_leg_207() {

# ── T-1328: the T-347 instrument tells spec from foreign by the bound namespace URI ──
# No browser. bpmn-js binds the DD namespaces to omgdc/omgdi; judged by prefix spelling, its shape bounds read as a
# lost foreign extension. The self-check pins both directions (a name-based mutant fails 2 of its 7 cases).
if node "$ROOT/tools/_t347-accepted-element-content-cdp.mjs" --selftest > "$TMP/leg-_t1328.out" 2>&1 \
   && grep -q 'selftest: OK' "$TMP/leg-_t1328.out"; then
  pass=$((pass + 1))
else
  report FAIL "the T-347 instrument judges a namespace prefix by its spelling again, or no longer matches a re-prefixed vocabulary by URI (run 'node tools/_t347-accepted-element-content-cdp.mjs --selftest'; T-1328)"
  show_output "$TMP/leg-_t1328.out" "_t347-accepted-element-content-cdp.mjs --selftest"
  fail=$((fail + 1))
fi
}
leg core "_t347-instrument-selftest" _leg_207
_leg_208() {

# ── T-1271: a save keeps the nodes in the order the file declares them (job C F13) ──
# Import collected nodes one tag at a time, so a third-party file's first save regrouped them by kind, in the process
# and in each lane's flowNodeRefs. Designer-written maps must keep their own order. Red against the pre-T-1271 source.
if node "$ROOT/tools/_t1271-node-order-cdp.mjs" > "$TMP/leg-_t1271.out" 2>&1 \
   && head -2 "$TMP/leg-_t1271.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "a save reorders the flow nodes or flowNodeRefs of a file, or a designer-written map saves its nodes in another order (run 'node tools/_t1271-node-order-cdp.mjs'; T-1271)"
  show_output "$TMP/leg-_t1271.out" "_t1271-node-order-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1271-node-order-cdp" _leg_208
_leg_209() {

# ── T-1262: a save keeps a file's own definitions, collaboration and process ids, targetNamespace and isExecutable ──
# Job C F4 (and F12 through it): the process id is an engine's deployment key. Designer-written maps record nothing
# and still rename; a second open of the same file renames the designer's id only. Red against the pre-T-1262 source.
if node "$ROOT/tools/_t1262-file-identity-cdp.mjs" > "$TMP/leg-_t1262.out" 2>&1 \
   && [ "$(sed -n 2p "$TMP/leg-_t1262.out")" = '  "ok": true,' ]; then
  pass=$((pass + 1))
else
  report FAIL "a save rewrites a file's own definitions/collaboration/process id, targetNamespace or isExecutable, a second open's _v2 reaches the saved ids, or a designer-written map no longer renames (run 'node tools/_t1262-file-identity-cdp.mjs'; T-1262)"
  show_output "$TMP/leg-_t1262.out" "_t1262-file-identity-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1262-file-identity-cdp" _leg_209
_leg_210() {

# ── T-1261: the first open of a third-party file records each element's original id (job C F3) ──
# <x832:origin originalId="…"/> (urn:832-workflow-designer:origin:1), attribute-only, never replaced once recorded;
# designer-written maps gain nothing. Red against the pre-T-1261 source.
if node "$ROOT/tools/_t1261-original-id-cdp.mjs" > "$TMP/leg-_t1261.out" 2>&1 \
   && [ "$(sed -n 2p "$TMP/leg-_t1261.out")" = '  "ok": true,' ]; then
  pass=$((pass + 1))
else
  report FAIL "a third-party element's original id is not recorded (or recorded twice, replaced, or with text content), or a designer-written map gained an origin (run 'node tools/_t1261-original-id-cdp.mjs'; T-1261)"
  show_output "$TMP/leg-_t1261.out" "_t1261-original-id-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1261-original-id-cdp" _leg_210
_leg_211() {

# ── T-1264: another tool's diagram geometry is kept until the person moves the element (job C F6) ──
# Sizes, isMarkerVisible, labels, DI ids and waypoints of unmoved shapes and flows; a moved one is redrawn; edge
# sourceElement/targetElement name shapes the export contains; designer-written maps record nothing. Red against the
# pre-T-1264 source.
if node "$ROOT/tools/_t1264-imported-geometry-cdp.mjs" > "$TMP/leg-_t1264.out" 2>&1 \
   && [ "$(sed -n 2p "$TMP/leg-_t1264.out")" = '  "ok": true,' ]; then
  pass=$((pass + 1))
else
  report FAIL "another tool's unmoved shape or flow lost its geometry on save, a moved one kept it, a DI reference dangles, or a designer-written map recorded geometry (run 'node tools/_t1264-imported-geometry-cdp.mjs'; T-1264)"
  show_output "$TMP/leg-_t1264.out" "_t1264-imported-geometry-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1264-imported-geometry-cdp" _leg_211
_leg_212() {

# ── T-1331: no `command | grep -q` under pipefail (the T-1330 class) ──
# grep -q exits at its first match; a producer still writing dies of SIGPIPE and pipefail turns a found match into a
# failure, red in the suite and green standalone. Teeth (--selftest) first, then the ratchet over tools/ tests/ scripts/.
if python3 "$ROOT/tools/_t1331-pipe-grep-q-census.py" --selftest > "$TMP/leg-_t1331.out" 2>&1 \
   && python3 "$ROOT/tools/_t1331-pipe-grep-q-census.py" >> "$TMP/leg-_t1331.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a script under set -o pipefail pipes a command into grep -q again (capture the output, then grep the capture), or the census lost its teeth (run 'python3 tools/_t1331-pipe-grep-q-census.py'; T-1331)"
  show_output "$TMP/leg-_t1331.out" "_t1331-pipe-grep-q-census.py"
  fail=$((fail + 1))
fi
}
leg core "_t1331-pipe-grep-q-census" _leg_212
_leg_213() {

# ── T-1102: every node's display id is unique within its map (the display id IS the saved element id) ──
# Lane-less nodes (events inside a subprocess) shared the fallback prefix `lan` with a real lane abbreviated `lan` while each
# side numbered on its own: kitchen-sink saved two endEvents as `lan_end_event`. Red against the pre-T-1102 source.
if node "$ROOT/tools/_t1102-unique-display-ids-cdp.mjs" > "$TMP/leg-_t1102.out" 2>&1 \
   && [ "$(sed -n 2p "$TMP/leg-_t1102.out")" = '  "ok": true,' ]; then
  pass=$((pass + 1))
else
  report FAIL "two nodes share a display id (so the saved BPMN repeats an id), a designer-written map changed its ids, or a second save differs (run 'node tools/_t1102-unique-display-ids-cdp.mjs'; T-1102)"
  show_output "$TMP/leg-_t1102.out" "_t1102-unique-display-ids-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1102-unique-display-ids-cdp" _leg_213
_leg_214() {

# ── T-1333 (T-396): release-designer.sh reports the TAG state both ways ──
# TAGGED when designer-v<VERSION> exists; a loud NOT-TAGGED warning, the tag name and a one-line remedy when it does
# not (0.9.0 shipped untagged). The probe restores the release commit's tree in its clones, so source edits made after a
# release no longer turn it red. Browser tier: the script's render gate drives a browser (about 45 s).
if bash "$ROOT/tools/_t396-release-tag-state.sh" > "$TMP/leg-_t396.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "release-designer.sh no longer reports the tag state (TAGGED, or the NOT-TAGGED warning with the remedy), or the probe could not measure (run 'bash tools/_t396-release-tag-state.sh'; T-1333)"
  show_output "$TMP/leg-_t396.out" "_t396-release-tag-state.sh"
  fail=$((fail + 1))
fi
}
leg browser "_t396-release-tag-state" _leg_214

_leg_215() {

# ── T-1338: every import-notice phrase the T-1327 harness asserts is still in the designer source ──
# No browser. T-1264 reworded the notice's geometry part; the browser-tier T-1327 leg kept asserting the old phrase and
# nothing ran it before push. A rewording now fails here, in the core tier.
if node "$ROOT/tools/_t1327-comments-and-notice-cdp.mjs" --phrases > "$TMP/leg-_t1338.out" 2>&1 \
   && grep -q '"ok":true' "$TMP/leg-_t1338.out"; then
  pass=$((pass + 1))
else
  report FAIL "an import-notice phrase the T-1327 harness asserts is no longer in the designer source: the notice was reworded and the harness left behind; update NEW_PARTS in tools/_t1327-comments-and-notice-cdp.mjs (run it with --phrases; T-1338)"
  show_output "$TMP/leg-_t1338.out" "_t1327-comments-and-notice-cdp.mjs --phrases"
  fail=$((fail + 1))
fi
}
leg core "_t1327-notice-phrases" _leg_215

_leg_216() {

# ── T-1339: the validator walks into subprocess containers ──
# The designer saves another tool's nested nodes and flows inside their container (T-1266 GO, slice 1). A dangling
# reference inside a container is reported (red on the pre-T-1339 validator, which read direct children only); a nested
# node in no lane is not E-XML-NODE-UNASSIGNED; a flat process is walked exactly as before.
if python3 -m pytest -q -p no:cacheprovider "$ROOT/tests/test_t1339_validator_nesting.py" > "$TMP/leg-_t1339v.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the validator no longer sees inside a subprocess, transaction or adHocSubProcess, reports a nested node in no lane as unassigned, or walks a flat process differently (run 'python3 -m pytest tests/test_t1339_validator_nesting.py'; T-1339)"
  show_output "$TMP/leg-_t1339v.out" "test_t1339_validator_nesting.py"
  fail=$((fail + 1))
fi
}
leg core "test_t1339_validator_nesting" _leg_216

_leg_217() {

# ── T-1339: an unedited open → save keeps every node and flow in the container the file declared it in ──
# T-1266 GO, slice 1. The 4 nesting fixtures (23 nested nodes, 6 nested flows), opened as a person opens a file; each
# element's container in the export is the file's; a second save is byte-identical. Red on the pre-T-1339 source,
# which wrote every nested element at the process level.
if node "$ROOT/tools/_t1339-subprocess-nesting-roundtrip-cdp.mjs" > "$TMP/leg-_t1339.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a nested node or flow of a third-party file is saved outside its subprocess, transaction or adHocSubProcess again, or a second save differs (run 'node tools/_t1339-subprocess-nesting-roundtrip-cdp.mjs'; T-1339)"
  show_output "$TMP/leg-_t1339.out" "_t1339-subprocess-nesting-roundtrip-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1339-subprocess-nesting-roundtrip" _leg_217

_leg_218() {

# ── T-1345: edit rules for another tool's nested nodes ──
# T-1266 GO, slice 2. In the real editor: a dragged nested node keeps its container; a flow across a subprocess boundary
# is refused (connect clicks, endpoint re-anchor) with a message and no undo step; deleting a subprocess (single and
# multi-select) moves its contents to its own container, says so, and undo restores; a palette node is never nested.
# Red on the pre-T-1345 source for the refusal and delete legs.
if node "$ROOT/tools/_t1345-nesting-edit-rules-cdp.mjs" > "$TMP/leg-_t1345.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an edit of another tool's nested nodes broke a T-1266 rule: a flow across a subprocess boundary was created, a deleted subprocess took or stranded its contents silently, a drag changed a node's container, or a multi-delete cannot be undone (run 'node tools/_t1345-nesting-edit-rules-cdp.mjs'; T-1345)"
  show_output "$TMP/leg-_t1345.out" "_t1345-nesting-edit-rules-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1345-nesting-edit-rules" _leg_218
_leg_071() {

# ── T-1241: the audience lens narrows the side panel, details view and canvas, and never changes a saved byte ──
# T-281 slice 1. Business lens: 0 technical badges, 0 fields outside the business set, 0 fields the profile hides;
# switching lenses changes 0 bytes of buildBpmnXml; no lens definition = every field as before. Red on the pre-T-1241 source.
if node "$ROOT/tools/_t1241-business-lens-cdp.mjs" > "$TMP/leg-_t1241.out" 2>&1 \
   && head -2 "$TMP/leg-_t1241.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "the audience lens shows a field outside its set or one the field profile hides, a technical canvas decoration under the business lens, changes saved bytes, or breaks the no-definition case (run 'node tools/_t1241-business-lens-cdp.mjs'; T-1241)"
  show_output "$TMP/leg-_t1241.out" "_t1241-business-lens-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1241-business-lens-cdp" _leg_071
_leg_072() {

# T-1256 (label clearance) and T-1282 (?browse=1) run inside the T-1287 gate below, under a stricter pass rule
# (exit 0 AND ok AND no errors); their separate legs were removed to stop running them twice (T-1287).

# ── T-1287: the "what a person sees" gate — one entry point over the render harnesses, run before any UI review ──
# It runs, one browser at a time: _t1256 (flow/arrowhead crossings, label overlaps), _t1276 (no ellipsized task name,
# flow-label contrast), _t1278 (opening text >= 9 px, Name field, reachability, helper contrast), _t1274 (Note box
# growth), _t1176 (toolbar reach) and _t1282 (project browser: last card reachable, hover preview inside the window).
# It replaces the T-1274/T-1276/T-1278 loop (T-1279): the same harnesses, the same exit-0 rule, plus a per-check
# timeout; any harness not run is exit 2, never a pass. Red on designer-v0.25.0 (T-1287). Literal path (T-451).
if bash "$ROOT/tools/person-sees-gate.sh" > "$TMP/leg-person-sees-gate.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the what-a-person-sees gate is red or could not run a check: one of label clearance, task-name fit, the codex sweep items, Note box, toolbar reach, project browser (run 'bash tools/person-sees-gate.sh'; T-1287)"
  show_output "$TMP/leg-person-sees-gate.out" "person-sees-gate.sh"
  fail=$((fail + 1))
fi
}
leg browser "person-sees-gate" _leg_072
_leg_073() {


# ── T-1290: review findings carry map evidence; the kit checks it; calibration verdict unchanged ──
if python3 "$ROOT/tests/test_t1290_verify_findings.py" > "$TMP/leg-_t1290.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "verify-findings mislabels map evidence, the kit stopped shipping it, or a calibration replay's verdict changed (run 'python3 tests/test_t1290_verify_findings.py'; T-1290)"
  show_output "$TMP/leg-_t1290.out" "test_t1290_verify_findings.py"
  fail=$((fail + 1))
fi
}
leg core "test_t1290_verify_findings" _leg_073
_leg_074() {

# ── T-1289: every designer endpoint AEF does not serve is named in the current release notes ──
# AEF went 13-25 days without 4 designer endpoints because nothing compared the two (T-1285 spike 4). A NEW gap
# fails here until RELEASE-NOTES-<VERSION>.md tells AEF; a synthetic unnamed gap proves the check bites.
if python3 "$ROOT/tests/test_t1289_host_contract_notes.py" > "$TMP/leg-_t1289.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a designer endpoint AEF's Watchtower does not serve is not named in the current release notes, or the host contract could not be read (run 'python3 tests/test_t1289_host_contract_notes.py'; T-1289)"
  show_output "$TMP/leg-_t1289.out" "test_t1289_host_contract_notes.py"
  fail=$((fail + 1))
fi
}
leg core "test_t1289_host_contract_notes" _leg_074
_leg_075() {

# ── T-1273: an in-place mutation script cannot survive INT/TERM with its mutant ──
# On 2026-10-22 the T-509 sweep's cap TERMed _t910, whose trap handler restored and RETURNED; bash resumed and
# planted the next mutant into src. Static: every in-place bash restorer's INT/TERM trap exits, every Python
# one installs a SIGTERM handler so `finally` runs. Literal path for the unwired-guard census (T-451).
if python3 "$ROOT/tools/_t1273-mutation-signal-guard.py" > "$TMP/leg-_t1273-guard.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an in-place mutation script can return from its INT/TERM handler, or restores in Python 'finally' with no SIGTERM handler, so a timeout can leave src or a tracked file mutated (run 'python3 tools/_t1273-mutation-signal-guard.py'; T-1273)"
  show_output "$TMP/leg-_t1273-guard.out" "_t1273-mutation-signal-guard.py"
  fail=$((fail + 1))
fi
}
leg core "_t1273-mutation-signal-guard" _leg_075
_leg_076() {
# Behaviour, on dummies in a temp dir only (no real mutation script is ever killed): old patterns leave the mutant
# under `timeout 1`, fixed ones restore and run nothing after the signal, and the guard agrees with both (~5 s).
if bash "$ROOT/tools/_t1273-signal-restore-teeth.sh" > "$TMP/leg-_t1273-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the T-1273 signal patterns no longer behave as the guard assumes: a fixed dummy left its mutant or ran on after TERM, an old one did not, or the guard disagrees (run 'bash tools/_t1273-signal-restore-teeth.sh'; T-1273)"
  show_output "$TMP/leg-_t1273-teeth.out" "_t1273-signal-restore-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t1273-signal-restore-teeth" _leg_076
_leg_077() {

# ── T-1220: attributes on aef:input/aef:output beyond name/type/required survive open and save ──
# aef-greenfield-test generates aef:io from its ontology (ref/role/cardinality/dataType, AEF T-4415); the
# save used to keep only the named attributes. Red against the pre-T-1220 source (legs 1, 3, 6).
if node "$ROOT/tools/_t1220-io-extra-attrs-cdp.mjs" > "$TMP/leg-_t1220.out" 2>&1 \
   && head -2 "$TMP/leg-_t1220.out" | grep -q '"ok": true'; then
  pass=$((pass + 1))
else
  report FAIL "extra attributes on aef:input/aef:output are dropped or reordered on save again, an edited input lost them, a deleted input left them behind, a plain map changed, or a value was not escaped (run 'node tools/_t1220-io-extra-attrs-cdp.mjs'; T-1220)"
  show_output "$TMP/leg-_t1220.out" "_t1220-io-extra-attrs-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1220-io-extra-attrs-cdp" _leg_077
_leg_078() {

# T-589 / T-1132: the panel's fabric link and URL list — clickable, round-trip, no contract key added, and a map
# carrying neither field exports identically with the two fields ablated (it went stale unwired; now scheduled).
if node "$ROOT/tools/_t589-panel-links-cdp.mjs" > "$TMP/leg-_t589.out" 2>&1 \
   && grep -q "10/10 T-589 legs passed" "$TMP/leg-_t589.out"; then
  pass=$((pass + 1))
else
  report FAIL "the panel's fabric link / URL list broke, one of them joined the metaKeys contract, or a map carrying neither field no longer exports identically (run 'node tools/_t589-panel-links-cdp.mjs'; T-589, T-1132)"
  show_output "$TMP/leg-_t589.out" "_t589-panel-links-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t589-panel-links-cdp" _leg_078
_leg_079() {

# T-1131: every third-party fixture's export references only ids it contains. The byte goldens were recorded from
# the export, so a defect present at recording passes them forever — this checks validity, not bytes.
if node "$ROOT/tools/_t1131-dangling-refs-thirdparty-cdp.mjs" > "$TMP/leg-_t1131.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a third-party export references an id it does not contain (a node dropped on import while its flows are kept, or a kept element naming something not kept) — run 'node tools/_t1131-dangling-refs-thirdparty-cdp.mjs'; T-1131"
  show_output "$TMP/leg-_t1131.out" "_t1131-dangling-refs-thirdparty-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1131-dangling-refs-thirdparty-cdp" _leg_079
_leg_080() {

# T-1134: on a portal WITHOUT the field endpoints (health/list/save only — Greenfield's shape) the designer offers no
# field settings and no suggestions, and says why; every other test runs against gallery-serve.py, which has them.
if node "$ROOT/tools/_t1134-portal-without-endpoints-cdp.mjs" > "$TMP/leg-_t1134.out" 2>&1 \
   && grep -q "T-1134: 4/4" "$TMP/leg-_t1134.out"; then
  pass=$((pass + 1))
else
  report FAIL "on a project server without /api/field-profile or /api/field-suggestions the designer again offers field settings or suggestions (Save would fail there) — run 'node tools/_t1134-portal-without-endpoints-cdp.mjs'; T-1134"
  show_output "$TMP/leg-_t1134.out" "_t1134-portal-without-endpoints-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1134-portal-without-endpoints-cdp" _leg_080
_leg_081() {

# T-889 (T-888 clause 2): the editor AUTHORS element-level authority — a panel write exports
# aef:meta authority= on an element whose document carried none (a differential, 5 legs). Standing
# guard since T-889 closed (the census showed it had lost its only caller, T-889's Verification).
if node "$ROOT/tools/_t889-authority-first-class-cdp.mjs" > "$TMP/leg-_t889fc.out" 2>&1 \
   && grep -q "5/5 legs passed" "$TMP/leg-_t889fc.out"; then
  pass=$((pass + 1))
else
  report FAIL "the editor no longer authors element-level authority from the properties panel (run 'node tools/_t889-authority-first-class-cdp.mjs'; T-889, T-888)"
  show_output "$TMP/leg-_t889fc.out" "_t889-authority-first-class-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t889-authority-first-class-cdp" _leg_081
_leg_082() {

# T-1078 (reviewer follow-up on T-310): an advisory banner never covers a node, the combined
# lane-fix message wraps inside the canvas, and dismissing gives the canvas back. Self-test mode:
# the live legs plus two poison arms (no padding -> O1 fails; nowrap -> O2 fails).
if node "$ROOT/tools/_t1078-advisory-overlap-cdp.mjs" --self-test > "$TMP/leg-_t1078.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an advisory banner covers the diagram, or the lane-fix message runs off the canvas, or the guard stopped biting (run 'node tools/_t1078-advisory-overlap-cdp.mjs --self-test'; T-1078, T-310)"
  show_output "$TMP/leg-_t1078.out" "_t1078-advisory-overlap-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t1078-advisory-overlap-cdp" _leg_082
_leg_083() {

# T-1066: a [REVIEW] Human criterion must name the operator exception that keeps it from the reviewer
# (PD-302). Self-test first (the rule bites), then the live tree (new tasks comply).
if python3 "$ROOT/tools/_t1066-why-you-check.py" --self-test > "$TMP/leg-_t1066s.out" 2>&1 \
   && python3 "$ROOT/tools/_t1066-why-you-check.py" > "$TMP/leg-_t1066.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a new [REVIEW] Human criterion does not say why it needs the operator (**Why you:** one of AEF's carve-outs — act-in-the-world | the Tier-0/bypass class | sovereignty-field — or direction/large-ux, pending at AEF), the check stopped biting, or AEF changed CARVE_OUTS (run 'python3 tools/_t1066-why-you-check.py --self-test'; T-1066, T-1079, PD-357)"
  cat "$TMP/leg-_t1066s.out" >> "$TMP/leg-_t1066.out" 2>/dev/null
  show_output "$TMP/leg-_t1066.out" "_t1066-why-you-check.py"
  fail=$((fail + 1))
fi
}
leg core "_t1066-why-you-check" _leg_083
_leg_084() {

# T-1079 (PD-357): 832's delegation predicate takes every `### Human` criterion's bucket from AEF's
# `fw task classify-ac` (T-1080), so the two encodings of the boundary (G-052) must agree. Self-test first (the
# deferral and the fail-closed legs bite), then the agreement over the live tree.
if python3 "$ROOT/tools/_t770-delegation-boundary.py" --self-test > "$TMP/leg-_t770s.out" 2>&1 \
   && bash "$ROOT/tools/_t932-boundary-agreement.sh" > "$TMP/leg-_t932.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "832's delegation predicate (_t770) and AEF's (fw reviewer surface) no longer agree, or _t770's deferral to AEF stopped biting — fix _t770, AEF is normative (run 'bash tools/_t932-boundary-agreement.sh'; T-1079, G-052, PD-357)"
  cat "$TMP/leg-_t770s.out" >> "$TMP/leg-_t932.out" 2>/dev/null
  show_output "$TMP/leg-_t932.out" "_t932-boundary-agreement.sh"
  fail=$((fail + 1))
fi
}
leg core "_t770-delegation-boundary" _leg_084
_leg_085() {

echo
echo "== every key our bridge can emit survives an editor round trip (T-572) =="
# The ⊆ guard (test_editor_bridge_meta_parity.py, run above) asserts one direction and its
# docstring used to ARGUE the other direction was safe — a claim about a round trip, checked
# against the read side alone. It returned [] for 47 days while the editor destroyed nine keys
# the bridge emits. This leg checks the property instead of asserting it: the fixture is
# DERIVED from the bridge's own META_KEYS at run time, so a key added to the producer is
# covered with no edit here, and a real load→export→re-parse decides. Mutant A is the exact
# state the ⊆ guard called green; mutant B whitelists all nine known casualties and adds a
# 30th key the probe never names, which only a derived fixture can see.
if python3 "$ROOT/tools/_t572-bridge-vocabulary-teeth.py" > "$TMP/leg-_t572-vocab.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a key the bridge emits no longer survives an editor round trip, or the guard stopped discriminating (T-572 — run 'python3 tools/_t572-bridge-vocabulary-teeth.py'; a mutant that reddens MORE than its own legs, or loses a DIFFERENT key set than named, is not discriminating, and CANNOT RUN is not a pass)"
  show_output "$TMP/leg-_t572-vocab.out" "_t572-bridge-vocabulary-teeth.py"
  fail=$((fail + 1))
fi
}
leg browser "_t572-bridge-vocabulary-teeth" _leg_085
_leg_086() {

echo
echo "== the completion gate cannot pass on a block it could not read (T-574) =="
# The P-011 gate located its block with `sed -n '/^## Verification/,/^## /p'` — a PREFIX
# match — and then `[ -z "$verify_cmds" ] && return 0`. A SILENT pass, byte-identical to a
# run that executed every leg and found no fault. T-572 completed that way with all TEN of
# its legs unrun, and was caught only because its AC count was a number someone happened to
# expect differently.
#
# Two opposite shapes, both observed here one day apart: T-572 (heading glued mid-line →
# range never opens → silent pass) and T-542 (a heading that PREFIXES the real one → range
# opens early → prose fed to the shell → loud refusal). Only one announces itself, which is
# why the guard is on the SILENT one and the loud one is the control.
#
# WIRING CAVEAT, stated because omitting it would repeat this task's own defect: this suite
# has no scheduled caller (no cron, no git hook, no CI — OBS on file). Registering here is
# strictly better than leaving the probe callable only from T-574's Verification block
# (T-568), and it is still not the same as something that runs on its own.
if python3 "$ROOT/tools/_t574-p011-block-locator-teeth.py" > "$TMP/leg-_t574-p011.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the P-011 completion gate can again pass silently on an unreadable ## Verification block, or the guard stopped discriminating (T-574 — run 'python3 tools/_t574-p011-block-locator-teeth.py'; a mutant that reddens MORE than the legs it owns is not discriminating, and CANNOT RUN is not a pass)"
  show_output "$TMP/leg-_t574-p011.out" "_t574-p011-block-locator-teeth.py"
  fail=$((fail + 1))
fi
}
leg core "_t574-p011-block-locator-teeth" _leg_086
_leg_087() {

# T-945: the vendor-divergence guard must reach a surface someone reads.
#
# This probe existed, was correct, and was invoked by NOTHING — `grep -c _t657` on this file
# was 0 before now. When the 1.7.68 re-vendor deleted the audit region it watches, it went to
# rc=3 COULD-NOT-MEASURE and said so to no one, which is how four reverted local fixes sat
# unnoticed for five days (T-944). A guard on a delivery surface that has no delivery surface
# of its own is the defect it was written to prevent, one level up.
if bash "$ROOT/tools/_t657-vendor-divergence-must-reach-an-audit-line.sh" > "$TMP/leg-_t657.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the vendored-divergence verdict no longer reaches an audit line, or the rail stopped discriminating — a local fix destroyed by the next re-vendor would again be invisible for as long as nobody runs this suite by hand (T-945/T-657 — run 'bash tools/_t657-vendor-divergence-must-reach-an-audit-line.sh'; rc=3 means the rail is GONE, not that the probe is broken)"
  show_output "$TMP/leg-_t657.out" "_t657-vendor-divergence-must-reach-an-audit-line.sh"
  fail=$((fail + 1))
fi
}
leg core "_t657-vendor-divergence-must-reach-an-audit-line" _leg_087
_leg_088() {

# T-943: the contract UNDERNEATH that probe. The four states extract_verification_block must
# keep distinct, asserted against the live function rather than through the gate's printed
# words, so a change to the caller's wording cannot make this leg lie either way.
#
# Registered here for the reason the caveat above gives, and with the same caveat attached: the
# T-574 probe was ALREADY registered here on 2026-09-25 when the 1.7.68 re-vendor reverted the
# fix, and it printed "the locator is GONE" on every run for five days. Registration made the
# finding available. It did not make anyone read it — that took a release and a sweep. Wiring a
# probe into an ungated runner buys reachability, not detection (PL-363).
if bash "$ROOT/tools/_t943-heading-states.sh" > "$TMP/leg-_t943-states.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "extract_verification_block stopped distinguishing 'no ## Verification section' from 'heading present but unmatched' — a task can close again having run ZERO commands while printing a pass, or the prose-mention controls started over-firing (T-943 — run 'bash tools/_t943-heading-states.sh')"
  show_output "$TMP/leg-_t943-states.out" "_t943-heading-states.sh"
  fail=$((fail + 1))
fi
}
leg core "_t943-heading-states" _leg_088
_leg_089() {

# T-949: the GO-scope triage must stay complete as the audit's finding moves.
#
# The audit reported 27 "GO recorded, work never filed" inceptions. Measured, 22 were
# delivered and only missing a related_tasks: back-link, 2 were partial, 2 were upstream's,
# and exactly ONE was genuinely un-acted. A 27-item warning with one real item in it cannot
# be read, which is why T-835 had to re-discover one of them by hand 15 days late.
#
# The backfill dropped the finding to 5. That number will move again, so this checker does
# NOT pin 27 (T-3326 — a mutable-corpus anchor rots). It asserts the FORWARD invariant: every
# inception the audit flags right now carries a verdict in docs/reports/T-949-go-scope-triage.md,
# from a fixed vocabulary, citing an artifact. A newly-abandoned GO therefore cannot appear in
# the audit without failing here.
#
# Three subjects, deliberately ANDed into one leg because they fail for the same reason:
#   teeth      — the checker still bites (5 mutation legs + a no-op control)
#   checker    — every currently-flagged inception carries an evidenced verdict
#   --verify   — the 22 back-links the backfill wrote are still there. A re-vendor or a
#                template reset would silently wipe them, and then the finding climbs back.
if bash "$ROOT/tools/_t949-completeness-teeth.sh" > "$TMP/leg-_t949-teeth.out" 2>&1 \
   && python3 "$ROOT/tools/_t949-backfill-related-tasks.py" --verify > "$TMP/leg-_t949-links.out" 2>&1 \
   && python3 "$ROOT/tools/_t949-triage-completeness.py" > "$TMP/leg-_t949.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a GO-recorded inception is flagged by the audit with no verdict in the T-949 triage, or a verdict lost its cited evidence, or the checker itself stopped biting — an abandoned operator decision would again be invisible inside a list of false positives (T-949 — run 'bash tools/_t949-completeness-teeth.sh' then 'python3 tools/_t949-triage-completeness.py'; rc=3 means the audit report is absent, not that the triage is wrong)"
  show_output "$TMP/leg-_t949-teeth.out" "_t949-completeness-teeth.sh"
  show_output "$TMP/leg-_t949-links.out" "_t949-backfill-related-tasks.py --verify"
  show_output "$TMP/leg-_t949.out" "_t949-triage-completeness.py"
  fail=$((fail + 1))
fi
}
leg core "_t949-completeness-teeth" _leg_089
_leg_090() {


# T-301: card id == derived workflowMeta.id, across every served corpus.
#
# Two identities name the same map and only a convention keeps them equal. The store card
# id is the file stem; the document id is re-derived from the bytes inside parseBpmnXml.
# openProjectMap fetches by card id, adopts, and DISCARDS it — so one divergence produces
# both reported symptoms: an empty Versions panel and a save that forks a new project
# record under the derived id.
#
# The editor cannot produce the divergence (every editor write keys the card by
# workflowMeta.id); the STORE can, and did — t101-review-audit-process was a store-level
# copy of audit-process whose bytes still said audit-process. So the guard is a corpus
# walk, which is the whole of T-301's approved scope: an editor-side fix would protect the
# path that was never the source.
#
# The teeth prober runs first and includes the leg the GO asked for by name — a synthesised
# divergent card that must be caught — plus two legs pinning the derivation chain from
# src/aef-workflow-designer.html:11210 (authored id used UNSANITIZED; procId before
# procName). Those matter because the first cut of the checker guessed the aef namespace
# wrong and reported 127 of 127 documents divergent on a corpus measured at 0%.
if bash "$ROOT/tools/_t301-invariant-teeth.sh" > "$TMP/leg-_t301-teeth.out" 2>&1 \
   && python3 "$ROOT/tools/_t301-id-stem-invariant.py" > "$TMP/leg-_t301.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a served document's card id and its derived workflowMeta.id disagree (opening it gives an empty Versions panel and a save forks a new project), or a recorded divergence went stale, or the invariant check stopped biting (T-301/T-951 — run 'bash tools/_t301-invariant-teeth.sh' then 'python3 tools/_t301-id-stem-invariant.py'; a NEW divergence must be fixed or recorded WITH a reason in tools/_t301-known-divergences.txt, never silenced by widening the check; rc=3 means no corpus was found, not that the invariant holds)"
  show_output "$TMP/leg-_t301-teeth.out" "_t301-invariant-teeth.sh"
  show_output "$TMP/leg-_t301.out" "_t301-id-stem-invariant.py"
  fail=$((fail + 1))
fi
}
leg core "_t301-invariant-teeth" _leg_090
_leg_091() {


# T-952: the suite's own redness has to reach a reader, and the ratchet that reads it has
# to bite. _t813-suite-age.py has run daily since T-917 — correctly — into `logger` and
# nowhere else; `grep -c '_t813\|run-history'` on audit.sh was 0. Same shape as _t517
# before T-945: a correct detector with no delivery surface.
#
# ONLY THE TEETH RUN HERE. The ratchet itself lives in the audit, deliberately: inside this
# suite it would read the PREVIOUS run's history row (this run's is appended by the exit
# trap), and a risen failure count would add one more failure to the very number it is
# measuring. Instruments get proven here; verdicts get delivered by the audit.
if bash "$ROOT/tools/_t952-ratchet-teeth.sh" > "$TMP/leg-_t952-teeth.out" 2>&1 \
   && bash "$ROOT/tools/_t952-audit-rail-teeth.sh" > "$TMP/leg-_t952-rail.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the bridge-suite failure ratchet stopped discriminating, or its audit line stopped carrying the tool's verdict — suite redness would go back to dying in syslog, and a SIGTERM'd partial sweep could read as an improvement (T-952 — run 'bash tools/_t952-ratchet-teeth.sh' and 'bash tools/_t952-audit-rail-teeth.sh'; rc=3 on the rail prober means check_bridge_suite_ratchet() is GONE from audit.sh, which audit.sh's 17 local commits make likely after any re-vendor)"
  show_output "$TMP/leg-_t952-teeth.out" "_t952-ratchet-teeth.sh"
  show_output "$TMP/leg-_t952-rail.out" "_t952-audit-rail-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t952-ratchet-teeth" _leg_091
_leg_092() {


# T-955 (T-309 GO slice 1): the designer can now REACH the validator.
#
# T-309's finding was reach, not rules: ~24 XmlValidator rule ids are trusted and green,
# and a grep of src/aef-workflow-designer.html finds no validation surface at all — so
# they run here and from the CLI and never reach the person drawing the map. POST
# /api/validate is that reach, and it holds NO rule logic (no rule id appears in the
# server's executable code) so there is exactly one implementation to keep honest.
#
# Chosen over a JS port on measured grounds: this repo already maintains
# test_harness_cross_form_agreement.py because two implementations of the same rules
# drift, and that test is failing RIGHT NOW on an E-NODE-LANE disagreement. A third form
# would be strictly worse. The offline cost is precedented — save is server-only too.
if python3 "$ROOT/tests/test_t955_validate_endpoint.py" > "$TMP/leg-_t955.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the designer's route to the validator is broken or gone — findings would stop reaching the author while the rules stay green here, which is the exact gap T-309 was filed for (T-955 — run 'python3 tests/test_t955_validate_endpoint.py'; its last leg strips the route from a copy of the server and requires a 404, so a failure there means the test lost its teeth rather than the route being fine)"
  show_output "$TMP/leg-_t955.out" "test_t955_validate_endpoint.py"
  fail=$((fail + 1))
fi
}
leg core "test_t955_validate_endpoint" _leg_092
_leg_093() {

echo
echo "== Findings reach the MAP, and the three states stay distinct (T-962, T-309 slice 3) =="
# T-961 proved the designer can ASK. This proves the answer arrives where the author is
# looking: a marker on each offending node, a dock listing every finding, and — the part
# that is easy to lose — "not yet checked", "checked · no findings" and "could not check"
# rendering as three different things. T-961 made that distinction true at the function
# boundary; it dies at the pixels if an unchecked map looks like a clean one, and then
# "looks clean" stops meaning anything.
#
# Two legs guard defects already made once here:
#   * ids resolve by displayIdOf (the EXPORTED id the validator names), not n.id. Matching
#     n.id placed ZERO markers while the dock said "3 findings, 0 on the map" — every row
#     rendered perfectly and said "not on the map". No DOM assertion caught it; reading a
#     screenshot did.
#   * W-XML-GW-AMBIGUOUS (47 of AEF's 48 live gateways, 0 of ours — it reports which
#     toolchain wrote the file) is LISTED but NOT marked. Both halves asserted, because an
#     allowlist that also dropped the row would be hiding findings rather than quieting them.
#
# Teeth: T962_DESIGNER_SRC pointed at a pre-change designer exits 3 (refuses), not 0.
if python3 "$ROOT/tests/test_t962_findings_on_map.py" > "$TMP/leg-_t962.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "validator findings stopped reaching the map, or the three states collapsed into one — an unchecked map reading as a clean one is the false green this whole slice exists to prevent (T-962 — run 'python3 tests/test_t962_findings_on_map.py'; if the displayIdOf leg is the red one, markers are being placed against internal ids again and the dock will cheerfully report 'N findings, 0 on the map')"
  show_output "$TMP/leg-_t962.out" "test_t962_findings_on_map.py"
  fail=$((fail + 1))
fi
}
leg browser "test_t962_findings_on_map" _leg_093
_leg_094() {

echo
echo "== /api/save carries the validator's verdict, advisorily (T-973) =="
# Evergreen's 26 maps passed 130 saves silently because the save path never ran the
# validator. Four legs over real HTTP; the one that matters is the copy with no validator
# beside it: the save must still land, and validation must say {ok:false} with no findings
# key. A broken validator that reads as a clean map is the false green.
if python3 "$ROOT/tests/test_t973_save_findings.py" > "$TMP/leg-_t973.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "/api/save stopped reporting findings, started BLOCKING on them, or reads an unloadable validator as a clean map (T-973 — run 'python3 tests/test_t973_save_findings.py')"
  show_output "$TMP/leg-_t973.out" "test_t973_save_findings.py"
  fail=$((fail + 1))
fi
}
leg core "test_t973_save_findings" _leg_094
_leg_095() {

echo
echo "== The vendor authoring kit is complete, self-contained and immutable (T-974) =="
# What a vendor's generating agent reads instead of being told by us. Leg 3 derives the rule
# set independently of the builder; leg 8 runs the real release script against a scratch
# RELEASE_DIST, so dist/ is never touched by this suite.
if python3 "$ROOT/tests/test_t974_authoring_kit.py" > "$TMP/leg-_t974.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the authoring kit lost a rule from its checklist, names a rule that does not exist, stopped running outside this repo, or a released kit can be rewritten (T-974 — run 'python3 tests/test_t974_authoring_kit.py')"
  show_output "$TMP/leg-_t974.out" "test_t974_authoring_kit.py"
  fail=$((fail + 1))
fi
}
leg core "test_t974_authoring_kit" _leg_095
_leg_096() {

echo
echo "== The review loop ships in the kit and calibrates (T-983, T-982 GO) =="
# No LLM here: stub agents fill the KIT_GENERATOR_CMD / KIT_REVIEWER_CMD seam. The teeth are
# legs 6 and 7: calibration must FAIL for a blind reviewer and for one that flags a clean map.
if python3 "$ROOT/tests/test_t983_review_loop_kit.py" > "$TMP/leg-_t983.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the review loop's kit files, calibration set or loop.sh orchestration regressed, or calibration stopped telling a blind reviewer from a working one (T-983 — run 'python3 tests/test_t983_review_loop_kit.py')"
  show_output "$TMP/leg-_t983.out" "test_t983_review_loop_kit.py"
  fail=$((fail + 1))
fi
}
leg core "test_t983_review_loop_kit" _leg_096
_leg_097() {

echo
echo "== The learning ledger enforces its checkpoint: evidence + a calibrated cross-vendor panel (T-984, T-1006) =="
# Nothing is promoted without confirmation, and a promotion must be visible in the file it names.
# Since T-1006 confirmation is a green evidence re-run plus agree from two calibrated vendors other
# than the author's, never a person vouching for a technical claim.
if python3 "$ROOT/tests/test_t984_learning_ledger.py" > "$TMP/leg-_t984.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the learning ledger let a lesson skip its checkpoint (evidence + calibrated panel), claimed a promotion its file does not show, or duplicated a repeated lesson (T-984 — run 'python3 tests/test_t984_learning_ledger.py'; 'python3 tools/learning-ledger.py check' names the entry)"
  show_output "$TMP/leg-_t984.out" "test_t984_learning_ledger.py"
  fail=$((fail + 1))
fi
}
leg core "test_t984_learning_ledger" _leg_097
_leg_098() {

echo
echo "== Lesson confirmation: evidence + calibrated cross-vendor quorum (T-1006) =="
if bash "$ROOT/tests/test_t1006_ledger_quorum.sh" > "$TMP/leg-_t1006.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a lesson can be confirmed without green evidence, without two calibrated vendors, by an uncalibrated or fooled reviewer, or by operator assent (T-1006 — run 'bash tests/test_t1006_ledger_quorum.sh')"
  show_output "$TMP/leg-_t1006.out" "test_t1006_ledger_quorum.sh"
  fail=$((fail + 1))
fi
}
leg core "test_t1006_ledger_quorum" _leg_098
_leg_099() {

echo
echo "== A link catch draws no dead-end of its own (T-1008, ledger L20) =="
if python3 -m pytest -q -p no:cacheprovider "$ROOT/tests/test_t1008_catch_no_deadend.py" > "$TMP/leg-_t1008c.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a link catch draws its own W-(XML-)DEADEND again, or a catch reached by flow stopped being assessed (T-1008 — run 'python3 -m pytest tests/test_t1008_catch_no_deadend.py')"
  show_output "$TMP/leg-_t1008c.out" "test_t1008_catch_no_deadend.py"
  fail=$((fail + 1))
fi
}
leg core "test_t1008_catch_no_deadend" _leg_099
_leg_100() {

echo
echo "== A new kit ships only with a calibration of its own bytes (T-1008, ledger L16) =="
if bash "$ROOT/tests/test_t1008_kit_calibration_gate.sh" > "$TMP/leg-_t1008g.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the kit calibration gate passes without a record, with a FAIL, or with a record of different bytes (T-1008 — run 'bash tests/test_t1008_kit_calibration_gate.sh')"
  show_output "$TMP/leg-_t1008g.out" "test_t1008_kit_calibration_gate.sh"
  fail=$((fail + 1))
fi
}
leg core "test_t1008_kit_calibration_gate" _leg_100
_leg_101() {

echo
echo "== The designer can REACH the validator (T-961, T-309 slice 2) =="
# The other half of T-955. That leg guards the ROUTE; this one guards the editor's side of
# it — validateCurrentWorkflow() serialising the live map, posting it, and parsing the
# result — in the REAL editor, in headless chromium, served over real HTTP by the real
# gallery-serve.py from a docroot asserted byte-identical to src/.
#
# The byte-identical assertion is load-bearing: build/gallery/designer.html is a COPY
# refreshed by tools/serve-gallery.sh and ALREADY differs from src/ in this tree, so a test
# pointed at the ordinary serve root can pass against code that is not under test.
#
# The property is the SHAPE, not the happy path. An empty findings list must mean "ran, found
# nothing" and never "could not run" — those render identically if you return [] for both, and
# "looks clean" then becomes indistinguishable from "never looked". So the clean legs are
# paired with a file://-build leg and a server-killed-mid-session leg, both of which must
# return ok:false with NO findings key at all.
#
# Teeth: pointed at the pre-change designer via T961_DESIGNER_SRC it exits 3 (refuses) rather
# than passing. Chromium absence is a LOUD environment skip, never a silent green (T-212).
if python3 "$ROOT/tests/test_t961_designer_validate_reach.py" > "$TMP/leg-_t961.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the designer can no longer reach the validator, or it has started reporting 'no findings' when it simply could not look — which is the false green that makes a validation surface worse than none (T-961 — run 'python3 tests/test_t961_designer_validate_reach.py'; if the byte-identical leg is the one red, src/ and the docroot diverged and the run measured the wrong page)"
  show_output "$TMP/leg-_t961.out" "test_t961_designer_validate_reach.py"
  fail=$((fail + 1))
fi
}
leg browser "test_t961_designer_validate_reach" _leg_101
_leg_102() {

echo
echo "== The boundary inventory's drift check still bites (T-958) =="
# T-955 shipped /api/validate and classified it nowhere; the drift check caught it the same
# session, and T-958 added its ROUTE_SEMANTICS row. This leg exists because that check has
# TWO independent arms — route-in-server-not-in-report, and route-with-no-semantics-row — and
# one fix cleared both at once, so a green run cannot say which arm was load-bearing or
# whether either still works. The prober pops the row (UNCLASSIFIED must fire, naming only
# that route) and separately removes the dispatch literal from the server source (DOCUMENTED,
# NOT IN SERVER must fire), against a green control.
#
# It is wired HERE, and that is the whole point: T-884's route went unclassified for ~26 hours
# only because a sweep happened to run, and the same omission left T-884's own test unwired
# from this file (T-941, T-942, PL-363). An unscheduled check has unbounded latency. A teeth
# prober with no scheduled reader is the defect it was written to prevent.
if python3 "$ROOT/tools/_t958-boundary-row-teeth.py" > "$TMP/leg-_t958-boundary.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the editor's authority inventory can no longer detect an unclassified or undocumented route — a route shipped after this point would enter the tree unfenced and nothing would say so (T-958 — run 'python3 tools/_t958-boundary-row-teeth.py'; leg 1 red means the tree has real drift, run 'python3 tools/_t682-boundary-inventory.py' for it, while legs 3-5 red mean the CHECK lost its teeth and is now green for the wrong reason)"
  show_output "$TMP/leg-_t958-boundary.out" "_t958-boundary-row-teeth.py"
  fail=$((fail + 1))
fi
}
leg core "_t958-boundary-row-teeth" _leg_102
_leg_103() {

echo
echo "== A card's purpose is readable AND safe (T-569) =="
# The card is the only project-owned surface Watchtower's nav already reaches, and an
# autoescaped purpose made it unlinkable. Two legs pulling opposite ways: the link must
# render, and a card's <script> must not. Mutant B drops safe_mode and the LINK STILL
# WORKS — which is why "the link renders" alone would have accepted the unsafe fix.
if python3 "$ROOT/tools/_t569-card-purpose-markdown-teeth.py" > "$TMP/leg-_t569-purpose.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a component card's purpose stopped rendering markdown, or started rendering raw HTML (T-569 — run 'python3 tools/_t569-card-purpose-markdown-teeth.py'; mutant B green means safe_mode was dropped and a card can inject script into the page)"
  show_output "$TMP/leg-_t569-purpose.out" "_t569-card-purpose-markdown-teeth.py"
  fail=$((fail + 1))
fi
}
leg core "_t569-card-purpose-markdown-teeth" _leg_103
_leg_104() {

echo
echo "== Episodic memory is still readable, unattended (T-567, G-040) =="
# T-567 fixed the generator; nothing yet READS the corpus, which is the gap G-040 keeps
# open. This leg is not that closure — the gap closes when the CRON audit parses it — but
# it does mean a corrupt episodic can no longer survive a commit unnoticed. --min pins a
# floor so the check cannot pass by having nothing to check.
if python3 "$ROOT/tools/_t567-episodic-parse-check.py" --min 488 --match-git > "$TMP/leg-_t567-parse.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "episodic memory is not readable as claimed — an episodic failed to parse, or a timeline entry stopped matching the git subject it was mined from, or the corpus fell below its floor (T-567 — run 'python3 tools/_t567-episodic-parse-check.py --min 488 --match-git')"
  show_output "$TMP/leg-_t567-parse.out" "_t567-episodic-parse-check.py"
  fail=$((fail + 1))
fi
}
leg core "_t567-episodic-parse-check" _leg_104
_leg_105() {

echo
echo "== A card edit reaches the RUNNING dashboard, not just the loader (T-568) =="
# PL-148: a correct loader the live process never picked up is still a stale page. The
# probe tests the deployed Watchtower when one is reachable and spawns its own on an
# ephemeral port when none is — it must never pass by not running.
if python3 "$ROOT/tools/_t568-live-card-visibility-probe.py" > "$TMP/leg-_t568-live.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an in-place card edit did not reach the live dashboard, or no Watchtower could be reached OR started so the check never ran (T-568 — run 'python3 tools/_t568-live-card-visibility-probe.py'; exit 2 means it could not run, which is NOT a pass)"
  show_output "$TMP/leg-_t568-live.out" "_t568-live-card-visibility-probe.py"
  fail=$((fail + 1))
fi
}
leg core "_t568-live-card-visibility-probe" _leg_105
_leg_106() {

echo
echo "== An edited component card is visible to the page that shows it (T-568) =="
# Watchtower cached the parsed cards under the mtime of the DIRECTORY holding them, and
# POSIX does not move a directory's mtime when a file inside it is written. So
# `fw fabric register` invalidated and `fw fabric enrich` — our own audit's standing
# priority action — never did, for the life of the process, at HTTP 200. Mutant A is the
# shipping code and must redden the in-place-edit leg and only that one; mutant B deletes
# the caching, which also returns the right answer and must redden only the cache leg.
if bash "$ROOT/tools/_t568-fabric-card-cache-teeth.sh" > "$TMP/leg-_t568-fabric-cache.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an edit to a component card can once again be invisible to /fabric, or the cache was repaired by being deleted (T-568 — run 'bash tools/_t568-fabric-card-cache-teeth.sh'; a mutant that reddens MORE than its own leg is not discriminating and the probe is measuring its own fragility)"
  show_output "$TMP/leg-_t568-fabric-cache.out" "_t568-fabric-card-cache-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t568-fabric-card-cache-teeth" _leg_106
_leg_107() {

echo
echo "== A commit message cannot corrupt the episodic it is recorded in (T-567) =="
# mine_git_timeline wrote git subjects into a DOUBLE-quoted YAML scalar escaping only `"`,
# so any backslash before a non-escape character made the episodic unparseable. Two of 488
# were already dead — T-431 since 2026-08-11 — and nothing noticed, because the error is
# raised at generation time and the file is never read again. The round-trip leg is the
# point: a generator that emitted nothing would parse perfectly.
if bash "$ROOT/tools/_t567-episodic-yaml-safety-teeth.sh" > "$TMP/leg-_t567-episodic.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a commit message can once again corrupt the episodic that records it, or an episodic stopped matching the git subject it was mined from (T-567 — run 'bash tools/_t567-episodic-yaml-safety-teeth.sh'; mutant B green means the file parses because it is EMPTY, which is the opposite of the property)"
  show_output "$TMP/leg-_t567-episodic.out" "_t567-episodic-yaml-safety-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t567-episodic-yaml-safety-teeth" _leg_107
_leg_108() {

echo
echo "== Workflow-id sanitizer and validator agree, at every site (T-562, T-501 D2) =="
# The sanitizer was written inline three times and judged by a fourth inline regex, and
# the three disagreed with the judge — a map could be renamed to an id the save path
# would then refuse. T-562 lifted both into single helpers and closed a hole the T-501
# census could not see: the shipping rule stripped a leading `-` but not a leading `_`,
# so `_foo` survived sanitisation and failed validation. The corpus contains no such
# name, which is why the census measured 0 invalid and was right about what it read.
#
# The probe drives a real rename in a real browser rather than reading the source, and
# its leg 6 is what separates "the helper is correct" from "the call site uses it".
if node "$ROOT/tools/_t562-workflow-id-helpers-cdp.mjs" > "$TMP/leg-_t562-workflow-id-helpers.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the workflow-id sanitizer and the save validator stopped agreeing, or a call site went back to an inline copy (T-562 — run 'node tools/_t562-workflow-id-helpers-cdp.mjs'; leg 6 red alone means the HELPER is fine and a CALL SITE is unwired, which greps for the helper name will not show)"
  show_output "$TMP/leg-_t562-workflow-id-helpers.out" "_t562-workflow-id-helpers-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t562-workflow-id-helpers-cdp" _leg_108
_leg_109() {

# Mutation test for the probe above. Without it, "7/7 legs passed" is also what a probe
# asserting nothing prints. Four mutants, each a fix someone would plausibly ship; the
# C arm (helper correct, call site unwired) must redden leg 6 and only leg 6.
if bash "$ROOT/tools/_t562-workflow-id-helpers-teeth.sh" > "$TMP/leg-_t562-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the T-562 workflow-id probe stopped discriminating — a mutant survived, or the call-site arm no longer isolates wiring from correctness (run 'bash tools/_t562-workflow-id-helpers-teeth.sh')"
  show_output "$TMP/leg-_t562-teeth.out" "_t562-workflow-id-helpers-teeth.sh"
  fail=$((fail + 1))
fi
}
leg browser "_t562-workflow-id-helpers-teeth" _leg_109
_leg_110() {

echo
echo "== A document with no <aef:workflowMeta> imports with a valid, uncollapsed id (T-563) =="
# The chain was `authored id || procName || 'imported'`, and procName is a display LABEL.
# Measured before the fix: all 14 corpus documents that carry no <aef:workflowMeta>
# imported with an id the designer's own save guard rejects — `Process_1`, `EU Bank`,
# `No lane set`. Not an edge case; it was the whole fallback population.
#
# Two invariants, and the second is the one that is easy to lose. Leg 2 (all valid) is
# also satisfiable by putting `deriveSlug` in the identity slot — it collapses these 14
# onto 7 ids that ALL pass the validator, which is a silent cross-document collision
# wearing a green tick. Leg 3's distinct-count floor is what catches that. Leg 5
# reproduces the OLD chain in-page and requires it to be invalid where the new one is
# valid, so the corpus is shown to exercise the change rather than assumed to.
if timeout 400 node "$ROOT/tools/_t563-fallback-id-derivation-cdp.mjs" > "$TMP/leg-_t563-fallback-id.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "workflow-id derivation for documents with no <aef:workflowMeta> regressed (T-563 — run 'node tools/_t563-fallback-id-derivation-cdp.mjs'; it prints every document. leg 3 red alone means the ids are still VALID but COLLAPSED, which is a summariser back in the identity slot; leg 4 red means an authored id is being sanitized and export bytes are moving; rc 2 means it REFUSED — no corpus document reaches the fallback, so nothing exercised the invariant)"
  show_output "$TMP/leg-_t563-fallback-id.out" "_t563-fallback-id-derivation-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t563-fallback-id-derivation-cdp" _leg_110
_leg_111() {

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
}
leg browser "_t355-foreign-tag-render-cdp" _leg_111
_leg_112() {

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
}
leg core "_t505-finished-invisible-census" _leg_112
_leg_113() {

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
}
leg core "test_t316_runner_orphans" _leg_113
_leg_114() {

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
}
leg core "_t451-unwired-guard-census" _leg_114
_leg_115() {

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
}
leg core "verification-hygiene" _leg_115
_leg_116() {

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
}
leg core "_t408-hygiene-teeth" _leg_116
_leg_117() {

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
}
leg sweep "_t509-instrument-sweep" _leg_117
_leg_118() {

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
}
leg core "_t495-prose-edge-probe" _leg_118
_leg_119() {

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
}
leg core "_t497-census-controls" _leg_119
_leg_120() {

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
}
leg core "check-corpus-geometry" _leg_120
_leg_121() {

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
}
leg core "_t423-position-carrier-guard" _leg_121
_leg_122() {

echo
echo "== The two geometry carriers AGREE, not merely both exist (T-423) =="
# The leg above proves aef:position is PRESENT. From 389133c8 that is no longer enough:
# every export now carries dc:Bounds as well, and the presence guard stays green while the
# two drift apart — the exact failure its own docstring claims to cover. This leg is the
# other half, and it could not have been built before the emitter existed because until
# then aef:position had no rival to disagree with.
#
# WHY THE CDP PROBE AND NOT THE PYTHON GUARD DIRECTLY. The guard is pure and needs a
# document; the only documents carrying BOTH carriers are export products, since the
# rendered corpus on disk has never held DI. Wiring the guard against a checked-in witness
# would make this leg green on a snapshot — it would keep passing after the emitter changed,
# which is the staleness this whole task keeps finding elsewhere. The probe exports all 24
# maps through a real browser on every run, so the artefact under test is always the one the
# current source produces. That is also what answers AEF's question at rail 11876 as asked:
# a real artefact, with a real competitor, not a fixture built to be checked.
#
# It refreshes tests/fixtures/exported/t423-carrier-witness.bpmn on success. Exports are
# deterministic, so that file only moves when the emitter does — and when it moves, it
# should. The teeth mutate the witness rather than the live export precisely so they can run
# without a browser; they are picked up by the T-509 instrument sweep by name.
if timeout 300 node "$ROOT/tools/_t423-carrier-agreement-cdp.mjs" > "$TMP/leg-_t423-carrier-agreement.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "aef:position and dc:Bounds no longer agree, or no longer cover the same nodes, on the exported corpus — the offending node is named by id (run 'node tools/_t423-carrier-agreement-cdp.mjs'; rc 2 means it REFUSED — no export carried DI at all, or a map would not export — which says the subject is broken, not the invariant)"
  show_output "$TMP/leg-_t423-carrier-agreement.out" "_t423-carrier-agreement-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t423-carrier-agreement-cdp" _leg_122
_leg_123() {

echo
echo "== Session control probes re-executed, not merely completed (T-819) =="

# PL-161, applied to the instruments written on 2026-09-22 rather than to someone else's:
# "a completion gate is not a guard, and the only durable remedy is a caller that re-executes
# without a task completing." Every probe below was written that day to prove some OTHER
# guard had teeth, and every one was called from exactly one place — its task's ## Verification
# block, which runs once and is then archived. They were the F-08 population, authored while
# fixing F-08.
#
# ONE GROUPED LEG, NOT TEN, and the shape is measured rather than assumed: timed end to end
# they total ~9.9s against a 784s suite (1.3%), and eight of the ten are between 22ms and
# 514ms. Ten separate banners for ten sub-second checks would add noise to a suite whose
# problem (F-03) is already that nobody runs it.
#
# The loop reports WHICH probe failed, so grouping costs no diagnosability. All ten were run
# and observed green before being wired — the T-817 rule applies to my own tools too.
_t819_failed=""
# PATHS ARE LITERAL `tools/<name>`, not bare filenames joined to $ROOT at runtime, and that
# is load-bearing rather than style. _t451's edge detector is
# `re.compile(r'tools/([A-Za-z0-9_.\-]+\.(?:py|sh|mjs|js))')` — it matches the literal
# string. A composed path is its documented FALSE POSITIVE ("a caller composing the path at
# runtime is invisible, so its tool is reported unwired"). The first draft of this loop used
# "$ROOT/tools/$_ctl" and moved the standing-guard count by ZERO: the probes ran, and the
# instrument whose entire job is detecting wiring could not see it. Measured A/B, 138 both
# ways, after I had already claimed otherwise in T-817's commit message.
for _ctl in tools/_t809-frozen-meta-census.py \
            tools/_t809-census-controls.sh \
            tools/_t810-unreachable-values-census.py \
            tools/_t812-adoption-predicate-controls.py \
            tools/_t813-suite-age.py \
            tools/_t813-history-trap-controls.sh \
            tools/_t815-witness-ordering-guard.py \
            tools/_t815-witness-guard-controls.sh \
            tools/_t816-abbr-dup-controls.sh \
            tools/_t817-wiring-controls.sh; do
  case "$_ctl" in
    *.py) _runner=python3 ;;
    *)    _runner=bash ;;
  esac
  if ! timeout 120 "$_runner" "$ROOT/$_ctl" > "$TMP/leg-$(basename "$_ctl").out" 2>&1; then
    _t819_failed="$_t819_failed $_ctl"
    show_output "$TMP/leg-$(basename "$_ctl").out" "$_ctl"
  fi
done
if [ -z "$_t819_failed" ]; then
  pass=$((pass + 1))
else
  report FAIL "session control probe(s) failed:$_t819_failed — each of these asserts that some OTHER guard still discriminates, so a failure here means a guard has gone inert or its subject moved. Run the named script directly; its output names the branch that disagreed."
  fail=$((fail + 1))
fi
}
leg browser "_t819-session-controls" _leg_123
_leg_124() {

echo
echo "== Direct-manipulation gestures (T-817: wiring F-08's inventory to close part of F-07) =="

# F-07 measured that the direct-manipulation surface — click-to-place, node drag, connect
# mode, lane resize, the whole keyboard surface — is named by NO gating leg, while 131 legs
# pass. F-08 measured 118 instruments that read as standing guards with no live caller:
# "coverage that was written, ran once at task completion, and was never wired to anything
# that re-runs it."
#
# Those two findings are the same hole from opposite sides, and the fix needed no new tests.
# All eight named CDP probes were RUN before any was wired here — a probe wired on the
# strength of its filename is the F-08 condition with extra steps. What that measured:
#
#   PASS, wired below ..... _horizontal-spacing (T-115 respaceColumns), _selection-align
#                           (T-134 Align/Distribute), _edge-straighten (T-137 Straighten),
#                           _t263-save-target (T-263 save-target binding)
#   RED, DIAGNOSED IN T-818, now wired below. The line that stood here called these
#                           "FAIL on real assertions". THAT WAS WRONG, and the correction is
#                           the finding: NEITHER probe was failing an assertion about the
#                           editor. _endpoint-overlap died of a TypeError before its last
#                           step ran, because T-293 (2026-07-28) moved the endpoint halos to
#                           #g-handles and its descendant selector stopped matching — 56 days
#                           in which the drag-regression assertion could not fail because its
#                           stimulus never fired. _saveproject parked in the #save-note-modal
#                           that T-150/T-161 added on 2026-07-09/10, THREE DAYS after it was
#                           written, and reported four red steps that read as "the save path
#                           is broken" when the save had never been asked to run — 75 days.
#                           Both editor changes were deliberate and right. A probe nothing
#                           re-runs does not merely stop informing; it starts misinforming,
#                           and the reader it misinforms is the next person triaging this
#                           list. Filing them with the measurement was still correct: wiring
#                           a red probe would have moved the silence rather than ended it.
#   BLOCKED ............... _autoload, _autosave need a served gallery, and
#                           build/gallery/designer.html is dated 2026-08-14 — 39 days stale.
#                           Serving it would test old bytes (the FP-009 defect: "a faithful
#                           test of old code"), and rebuilding it is not the agent's call.
#
# Each leg loads src/ directly, so it tests what the editor IS, not a build artefact.
# Literal `tools/<name>` paths — see the note on the T-819 loop below for why this is
# load-bearing and not style.
for _probe in tools/_horizontal-spacing-verify-cdp.mjs \
              tools/_selection-align-verify-cdp.mjs \
              tools/_edge-straighten-verify-cdp.mjs \
              tools/_t263-save-target-cdp.mjs \
              tools/_endpoint-overlap-verify-cdp.mjs \
              tools/_saveproject-verify-cdp.mjs; do
  _name="$(basename "${_probe%.mjs}")"
  if timeout 180 node "$ROOT/$_probe" > "$TMP/leg-$_name.out" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "direct-manipulation probe $_probe failed — a gesture the editor IS regressed, or the probe's expectation went stale while nothing re-ran it (run 'node tools/$_probe'; its JSON names the offending element). This leg exists because F-07 found these gestures covered by nothing and F-08 found the probes for them already written and unwired."
    show_output "$TMP/leg-$_name.out" "$_probe"
    fail=$((fail + 1))
  fi
done
}
leg browser "_t817-gestures" _leg_124
_leg_125() {

echo
echo "== Those probes fail when their SUBJECT breaks and say so when their STIMULUS does (T-818) =="

# The two probes added to the loop above were red for 56 and 75 days while asserting nothing.
# Wiring them on the strength of one green run would be the same mistake that made them: a
# probe is not shown to work by passing. tools/_t818-probe-controls.sh drives both branches
# for each — the editor regressing (probe must go red) and the editor changing so the probe's
# own gesture is unreachable (probe must go red NAMING the missing stimulus, having exercised
# no subject). The second branch is the one that was absent, and PL-206 is about exactly it.
#
# ITS OWN LEG rather than a member of the T-819 loop above, because that loop's grouping is
# justified by a measured shape — "~9.9s total, eight of the ten between 22ms and 514ms" —
# and a 17s member would make that sentence false. Measured here too: 16.9s for six headless
# runs, against a 784s suite (2.2%). I had assumed minutes and was going to leave it unwired
# on that assumption; the number is why it is wired.
if timeout 300 bash "$ROOT/tools/_t818-probe-controls.sh" > "$TMP/leg-_t818-probe-controls.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the direct-manipulation probes stopped discriminating — one of them now passes with its subject deliberately broken, or goes red without naming an unreachable stimulus (run 'bash tools/_t818-probe-controls.sh'; it names the branch. rc 3 means a MUTATION no longer applies, i.e. src moved and the control is measuring nothing until updated — that is a finding about this file, not a flake)"
  show_output "$TMP/leg-_t818-probe-controls.out" "_t818-probe-controls.sh"
  fail=$((fail + 1))
fi
}
leg browser "_t818-probe-controls" _leg_125
_leg_126() {

echo
echo "== Correlations are derived, resolving, and ratifiable (T-830: H3 ruled D) =="

# The rule this replaces was TRUE, WRITTEN DOWN, AND INERT. source-manifest.yaml has
# forbidden opening a peer handoff against an unassigned correlation since 2026-08-26; a
# handoff opened anyway on 2026-08-27 and stayed open for two months, because nothing ever
# evaluated the sentence. THREE correlation values were minted by agents and carried forward
# by repetition in the meantime, and the register entry had already named that exact
# mechanism before it recurred a third time.
#
# The operator ruled option D: derive both values from the arc instead of assigning strings.
# A derived value cannot be minted by accident, cannot drift by repetition, and STOPS
# RESOLVING when the object it derives from goes away — so it fails loudly rather than
# quietly naming nothing. These two legs are what make that a property of the tree rather
# than a sentence in it.
if python3 "$ROOT/tools/_t830-correlation-gate.py" > "$TMP/leg-_t830-correlation.out" 2>&1; then
  pass=$((pass + 1))
else
  _t830_rc=$?
  if [ "$_t830_rc" -eq 2 ]; then
    report FAIL "the correlation is PROVISIONAL — assigned by an agent rather than the operator. Transport still works by design; what is refused is the COMPLETION claim, because an agent ratifying its own correlation is the entire subject of H3 (run 'python3 tools/_t830-correlation-gate.py')"
  else
    report FAIL "a correlation is unassigned, minted as a free string instead of derived, or derives from an arc that no longer resolves (run 'python3 tools/_t830-correlation-gate.py'; it names the RULE that fired). A dangling derivation is the severe one: a derived reference that cannot be checked is a minted string with extra steps, and minted strings are what H3 exists to end"
  fi
  show_output "$TMP/leg-_t830-correlation.out" "_t830-correlation-gate.py"
  fail=$((fail + 1))
fi
}
leg core "_t830-correlation-gate" _leg_126
_leg_127() {

# And the gate's own teeth — 7 branches including the negative control that the handoff rule
# must NOT fire when no handoff is open. A rule that cries wolf is one readers learn to skip,
# which is how the original sentence became inert.
if timeout 180 bash "$ROOT/tools/_t830-correlation-gate-controls.sh" > "$TMP/leg-_t830-controls.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the correlation gate stopped discriminating — an unassigned, minted or dangling value no longer turns it red, or a provisional value stopped being distinguishable from a ratified one (run 'bash tools/_t830-correlation-gate-controls.sh'; it names the branch)"
  show_output "$TMP/leg-_t830-controls.out" "_t830-correlation-gate-controls.sh"
  fail=$((fail + 1))
fi
}
leg core "_t830-correlation-gate-controls" _leg_127
_leg_128() {

echo
echo "== Failures leave evidence (T-821: F-05, the review's highest-leverage ADD) =="

# The product had 70 catch sites and no error surface: clipboard failures silent, autosave
# quota "swallowed by design", seam failures bare. D1 Antifragility is weighted 9 and its
# definition is "failures are learning events"; a bare catch is the precise inverse. It also
# capped the review — ~93 items read D (UNMEASURED) because no channel existed that could
# carry evidence even incidentally.
#
# Three legs, three different failure modes:

# 1. THE RATCHET. Every catch is instrumented or carries a written excuse with an exact
#    count. This is the PL-288 leg — "a chosen-set assertion cannot find what you forgot to
#    choose" — and it guards against the instrumented set silently shrinking back.
if python3 "$ROOT/tools/_t821-swallowed-failure-census.py" > "$TMP/leg-_t821-census.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a failure in the editor is being swallowed with no record and no stated reason, or an excuse's site count moved (run 'python3 tools/_t821-swallowed-failure-census.py'; it names each line. An excuse whose count FELL is also red — the reason on file no longer describes the tree, and left alone it would silently cover a future site it was never written for)"
  show_output "$TMP/leg-_t821-census.out" "_t821-swallowed-failure-census.py"
  fail=$((fail + 1))
fi
}
leg core "_t821-swallowed-failure-census" _leg_128
_leg_129() {

# 2. THE SURFACE. Records, shows, survives a reload, and cannot throw — plus one end-to-end
#    leg that breaks navigator.clipboard and presses the real Copy button, because testing
#    aefRecordFault directly proves the recorder and says nothing about the WIRING. That
#    distinction is what T-818 found rotted in two probes on the same day.
if timeout 240 node "$ROOT/tools/_t821-fault-surface-cdp.mjs" > "$TMP/leg-_t821-surface.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the fault surface stopped recording, showing, persisting, or became able to throw (run 'node tools/_t821-fault-surface-cdp.mjs'; its JSON names the step). recorder-never-throws red is the severe one: every caller sits inside a catch whose contract is 'never break the editor', so a throwing recorder turns each instrumented site into an editor-breaking one — strictly worse than the silence this replaced"
  show_output "$TMP/leg-_t821-surface.out" "_t821-fault-surface-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t821-fault-surface-cdp" _leg_129
_leg_130() {

# 3. THE CENSUS'S OWN TEETH. A census that only ever reports 0 on a passing tree would look
#    like coverage and add none.
if timeout 180 bash "$ROOT/tools/_t821-census-controls.sh" > "$TMP/leg-_t821-census-controls.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the swallowed-failure census stopped discriminating — a new bare catch, a de-instrumented site, or an extra copy of an excused pattern no longer turns it red, or it has started counting catches that appear in COMMENTS (run 'bash tools/_t821-census-controls.sh'; it names the branch)"
  show_output "$TMP/leg-_t821-census-controls.out" "_t821-census-controls.sh"
  fail=$((fail + 1))
fi
}
leg core "_t821-census-controls" _leg_130
_leg_131() {

echo
echo "== A save that changes nothing produces no diff (T-423 idempotence) =="
# export -> re-import -> export must be byte-identical, on every corpus map. The reason is an
# authoring one, not a purity one: if the second export differs from the first, every save
# the author makes carries noise they did not write and review of those files stops being
# possible.
#
# NOT THE SAME MEASUREMENT AS _t308 despite both saying "identical". _t308 compares this
# tree's export against a PINNED GIT REF's export of the SAME corpus input — "did my change
# move the bytes?" This one never leaves the current build and feeds the exporter its OWN
# OUTPUT. A designer can be perfectly stable against a git ref and unstable against itself.
# It is not _t308's self-stability leg either (G-023): exporting one parse twice proves the
# EXPORTER is deterministic and says nothing about whether the PARSER can read back what the
# exporter just wrote, which is exactly where this defect class lives.
#
# It became load-bearing yesterday. DI is now emitted unconditionally, so every export
# carries constructs the corpus inputs do not, and idempotence stopped being inherited from
# "the output looks like the input".
#
# Its teeth (tools/_t423-di-roundtrip-teeth.py, picked up by the T-509 sweep by name) break
# the designer on purpose in a temp copy and require this probe to notice — including the
# distinction between drift that CONVERGES and drift that keeps moving, which are different
# defects wanting different fixes.
if timeout 400 node "$ROOT/tools/_t423-di-roundtrip-idempotence-cdp.mjs" > "$TMP/leg-_t423-di-roundtrip.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "opening a corpus map and saving it unchanged now produces different bytes — every save is a spurious diff (run 'node tools/_t423-di-roundtrip-idempotence-cdp.mjs'; it names the drifting maps, the first differing line on both sides, and whether the drift CONVERGES or keeps moving. rc 2 means it REFUSED — a map would not complete the trip — and the message says whether the original or OUR OWN EXPORT was the unreadable one)"
  show_output "$TMP/leg-_t423-di-roundtrip.out" "_t423-di-roundtrip-idempotence-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t423-di-roundtrip-idempotence-cdp" _leg_131
_leg_132() {

echo
echo "== Third-party documents still emit the bytes we recorded (T-358 / T-581) =="
# THE POPULATION _t308 CANNOT REACH. _t308's "24/24 identical" is true and is entirely
# about designer-produced corpus maps — the documents that carry aef:uid. Third-party
# documents do not, the emitter mints a uid per parse, so raw equality was never runnable
# on them and its absence has been reading as coverage (G-023).
#
# WHY THIS LEG IS NEW WHILE THE TOOL IS NOT. The tool has existed since T-358 and ran
# nowhere: tools/unwired-guard-baseline.txt carried it. It could not be wired, because
# its baseline was a git ref a human typed once (`3bf37909~1`) — by 2026-08-24 it reported
# 0 identical / 11 drifted / PRECONDITION VIOLATED, and every one of those drifts was a
# change we deliberately landed. Wiring it then would have installed a permanently red
# leg whose repair was "re-pin it", i.e. restart the same clock. T-581 replaced the ref
# with 11 recorded goldens under tests/goldens/third-party/, so an accepted change is now
# a reviewable diff in git instead of a re-pin, and the leg has nothing left to go stale.
#
# NO --record HERE, EVER. Recording is how this gate's baseline moves, and a gate that
# refreshes its own baseline on green ratchets forward silently and can never report drift
# that accumulated one run at a time — the exact failure T-581 repaired. Its teeth assert
# this line's argv positively (leg d), not by grepping for the absence of a flag.
#
# rc 2 is a REFUSAL, not a drift: this build's uid minting is not deterministic within
# itself, so no golden of it means anything. rc 1 is a real difference or a missing golden.
if timeout 300 node "$ROOT/tools/_t358-byteid-thirdparty.mjs" > "$TMP/leg-_t358-byteid.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a third-party document no longer emits the bytes recorded for it (run 'node tools/_t358-byteid-thirdparty.mjs'; it names each drifting fixture and the first differing line on both sides. If the change was intended, re-record DELIBERATELY with --record and commit the golden diff as the review record — do not add --record to this suite. rc 2 means it REFUSED: uid minting went nondeterministic (T-364), so no golden means anything until that is fixed)"
  show_output "$TMP/leg-_t358-byteid.out" "_t358-byteid-thirdparty.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t358-byteid-thirdparty" _leg_132
_leg_133() {

echo
echo "== 'I cannot tell whose server that is' is not reportable as healthy or down (T-499) =="
# The vendored accessor `fw watchtower url` has three branches and all three return 0 — live,
# stale-file, and an outright guess — so no caller can distinguish a confirmed URL from an
# invented one. AEF's `_watchtower_identity_matches` fixes the identity half correctly, but it
# is a bash predicate and therefore has two answers for three questions: MEASURED, it returns
# 1 for "that server is someone else's", for "nothing is listening", AND for "our own root is
# unset", the last while probing a server that is genuinely ours and says so.
#
# tools/_t499-watchtower-ownership.sh adds the third channel additively — exit 2 for the four
# ways we can fail to KNOW, exit 1 reserved for verdicts about the target. do_url's contract is
# untouched; changing a vendored accessor that every AEF caller relies on never failing is the
# operator's call and is on /approvals, not taken here.
#
# This leg runs the TEETH rather than the tool: the tool's own exit code proves one branch per
# run, while the teeth drive all six from fixtures plus the partition between them. Its control
# runs first and aborts on failure, because every other leg in it asserts a NON-ZERO exit and
# would be satisfied by a tool that is merely broken.
if timeout 120 python3 "$ROOT/tools/_t499-ownership-teeth.py" > "$TMP/leg-_t499-ownership.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the watchtower ownership check no longer separates abstention from verdict (run 'python3 tools/_t499-ownership-teeth.py'; each leg names the case, the exit code it got, the one it wanted, and the reason token it looked for. rc 2 means the CONTROL failed — the tool could not identify a server that is ours, so nothing below it was measured and the other legs' silence is not evidence)"
  show_output "$TMP/leg-_t499-ownership.out" "_t499-ownership-teeth.py"
  fail=$((fail + 1))
fi
}
leg core "_t499-ownership-teeth" _leg_133
_leg_134() {

echo
echo "== No tool is reachable only through a JavaScript comment (T-578) =="
# _t451 decides reachability by textual reference in an EXECUTABLE position, and T-495 taught
# it to ignore prose in Python and shell. It was never taught JavaScript, so `// tools/x.py`
# and a JSDoc block both read as calls. Measured: 53 tools are referenced from JS, and ZERO
# are held by a comment alone — so the gap is real, narrow, and currently costs nothing.
#
# This leg exists because that zero is worth keeping at zero. If it moves, some live guard's
# WIRED verdict rests on a sentence a reword would delete, and _t451 would not notice.
#
# It deliberately does NOT gate the larger number the same census prints — 110 of 237 tools
# have no executable-code edge at all. That one is the subject of an open decision about what
# the ratchet should count, and pinning it here would settle that question by side effect.
#
# rc 2 is a REFUSAL: no tool referenced from JS at all means an empty population, and a pass
# on nothing is the failure this whole line of work keeps finding.
if timeout 300 python3 "$ROOT/tools/_t578-js-comment-edge-census.py" > "$TMP/leg-_t578-js-edge.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a tool is now reachable ONLY through a JavaScript comment — reword that comment and a live guard reports unwired, and _t451 does not strip JS so it will not notice (run 'python3 tools/_t578-js-comment-edge-census.py'; it names them. rc 2 means it REFUSED — no tool is referenced from JS at all, so nothing exercised the check)"
  show_output "$TMP/leg-_t578-js-edge.out" "_t578-js-comment-edge-census.py"
  fail=$((fail + 1))
fi
}
leg core "_t578-js-comment-edge-census" _leg_134
_leg_135() {

echo
echo "== Worktree isolation is denied by every route it has (T-586) =="
# The operator asked twice, in two sessions, whether we were stuck in a worktree. Both
# times: no, and this repo never has been (.git/worktrees does not exist, which is
# evidence about the whole history, not just now). The question stayed askable because
# nothing prevented it — permissions.deny was empty, so the EnterWorktree tool, the
# Agent tool's isolation:"worktree" and `git worktree add` via Bash were all reachable.
#
# Deny rules close that, and deny rules live in a JSON file one careless edit removes
# with no trace. Hence a guard: their absence otherwise looks exactly like their presence.
# Both routes are required — denying the tool while leaving the shell open is gating a
# surface instead of the capability behind it.
#
# THIS LEG IS RED UNTIL THE OPERATOR APPLIES THE RULES, and that is correct rather than
# noise. .claude/settings.json is human-review gated (B-005) because it controls the task
# gates and Tier-0 checks, so the agent cannot apply them. The failure message carries the
# one-line command; it goes green the moment that runs.
#
# rc 2 is a REFUSAL: the guard's self-test failed, meaning it could not reject a settings
# file with the rules stripped, so it never looked at the live one.
if timeout 60 python3 "$ROOT/tools/_t586-worktree-denial-guard.py" > "$TMP/leg-_t586-worktree.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a worktree-isolation route is still open — run 'python3 tools/_t586-worktree-denial-guard.py'; it names the open route and prints the single-line operator command that closes it. This is an OPERATOR edit: .claude/settings.json is gated by B-005 and the agent is blocked from writing it. rc 2 means the guard's own self-test failed, so the live file was never checked and this leg's verdict is about the guard, not the config"
  show_output "$TMP/leg-_t586-worktree.out" "_t586-worktree-denial-guard.py"
  fail=$((fail + 1))
fi
}
leg core "_t586-worktree-denial-guard" _leg_135
_leg_136() {

# ── T-621: an Agent AC that names the operator as decider is a deadlock ──────────────
#
# /approvals surfaces ### Human ACs and inception decisions. An UNCHECKED criterion under
# ### Agent whose text says the outcome is the operator's is shown to nobody, while P-010
# refuses completion because it is unchecked and the agent must not check it. The only exit
# is a bypass, which is how a governance gate becomes a formality. T-537 and T-540 sat in
# that state and appeared on no operator surface.
#
# rc 2 is a REFUSAL: either the matcher failed its own self-test (including the end-to-end
# check that a TICKED operator-mention is ignored while an unticked one is reported), or no
# task carries a '### Agent' section at all — a renamed AC split would otherwise make this
# leg pass by finding nothing to check.
if timeout 60 python3 "$ROOT/tools/_t621-operator-ac-classification-guard.py" > "$TMP/leg-_t621-operator-ac.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an operator decision is filed as an Agent AC — run 'python3 tools/_t621-operator-ac-classification-guard.py'; it names the task and the matched phrase. Move the criterion to '### Human' with Steps/Expected/If-not so /approvals shows it. rc 2 means the guard's self-test failed or no task has an '### Agent' section, so nothing was actually checked"
  show_output "$TMP/leg-_t621-operator-ac.out" "_t621-operator-ac-classification-guard.py"
  fail=$((fail + 1))
fi
}
leg core "_t621-operator-ac-classification-guard" _leg_136
_leg_137() {

echo
echo "== No unchecked Human AC is invisible to the approvals queue (T-585) =="
# T-344 carried a real unchecked [REVIEW] under `## Measurements` instead of under
# `## Acceptance Criteria`. `count_unchecked_human_acs` scopes `### Human` to the AC
# section, so it returned 0 — the same value a task with no Human ACs returns — and both
# /approvals and `fw review-queue` showed nothing. The operator found it by complaining
# that the page was empty. Nothing in the suite could have found it, because the symptom
# of this bug is an empty queue and an empty queue is also what health looks like.
#
# The census compares the population the queue surfaces against the population carrying
# an unchecked AC under any `### Human` heading, prints BOTH by task id, and classifies
# every gap by which anchor drops it. It found T-402 on its first run — a second instance
# of the same class, an A/B/C containment ruling nobody had ever been shown.
#
# rc 2 is NOT a finding, it is a REFUSAL: the six hermetic fixtures run before any repo
# file is opened, and if the detector can no longer tell a mis-sectioned Human AC from a
# correctly sectioned one, the sweep is skipped. It has to be, because the sweep asserts
# ABSENCE and a broken detector reports absence perfectly.
if timeout 120 python3 "$ROOT/tools/_t585-human-ac-visibility-census.py" > "$TMP/leg-_t585-ac-visibility.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a task carries an unchecked Human AC the approvals queue cannot see, so the operator is not being asked a question the tree thinks it asked (run 'python3 tools/_t585-human-ac-visibility-census.py'; it names the task and the anchor that drops it. rc 2 means the CONTROL failed — the detector could not separate a mis-sectioned AC from a correct one on fixtures, so the repo was NOT swept and this leg's silence is not evidence)"
  show_output "$TMP/leg-_t585-ac-visibility.out" "_t585-human-ac-visibility-census.py"
  fail=$((fail + 1))
fi
}
leg core "_t585-human-ac-visibility-census" _leg_137
_leg_138() {

echo
echo "== Every document lacking <aef:workflowMeta> gains one on export (T-565 / T-501 IW-0) =="
# T-501 IW-0 asks whether export should ALWAYS emit <aef:workflowMeta>, and is deferred with
# an exit condition naming the 24 rendered maps. All 24 already carry the element, so that
# population cannot exercise the change at all — the census reports it UNEXERCISED rather
# than passing on it, the same call T-423 makes for aef:forceStraight.
#
# The population that CAN move is the 14 corpus documents with no such element (10 under
# tests/fixtures/third-party, 4 under lane-provenance). Measured: all 14 gain one on export
# today. Always-emit is not a change to weigh, it is current behaviour — and that fact is
# what any answer to IW-0 rests on, which is why it is wired here rather than left as a
# number in a task file. If emission ever becomes conditional this goes red.
#
# rc 2 is a REFUSAL, not a pass: it fires when no corpus document lacks the element, because
# a run with nothing to check is exactly the population-pin the census exists to expose.
if timeout 400 node "$ROOT/tools/_t565-workflowmeta-emission-census.mjs" > "$TMP/leg-_t565-wfmeta.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a document that lacks <aef:workflowMeta> no longer gains one on export, so always-emit is no longer unconditional and T-501 IW-0's premise is gone (run 'node tools/_t565-workflowmeta-emission-census.mjs'; it names the documents. rc 2 means it REFUSED — no corpus document lacks the element, so nothing exercised the invariant)"
  show_output "$TMP/leg-_t565-wfmeta.out" "_t565-workflowmeta-emission-census.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t565-workflowmeta-emission-census" _leg_138
_leg_139() {

echo
echo "== Export ADDS DI and changes nothing else (T-423 additive) =="
# The AC this closes named five intent extensions with counts — forceStraight 12,
# routingHint 22, loopDetour 9, anchors 19, aef:waypoint 1. Those numbers are LINE COUNTS OF
# THE IDENTIFIER IN src/aef-workflow-designer.html, not a property of any document: four of
# the five reproduce exactly once the source comment quoting the AC is excluded, and the
# fifth (anchors) has already drifted 19 -> 20 because someone wrote "Ctrl+wheel anchors at
# the cursor" in an unrelated comment. A metric that moves when a comment is edited and
# stays still when an export drops an extension is the inverse of the AC's intent.
#
# So this leg checks the intent instead, as PER-DOCUMENT IDENTITY: every element outside the
# DI namespaces is the same tag, the same attributes and the same document position in the
# export as in the source. Adding a corpus map cannot falsify that; dropping an extension
# from one document will. Two ACs fall out of the one equality — "aef:position still written,
# nothing removed or reordered" and "the intent extensions untouched".
#
# Two of the five extensions have ZERO instances in the corpus (forceStraight, aef:waypoint)
# and the guard prints them as UNEXERCISED rather than counting them covered — a guard that
# says "untouched" about a vocabulary nothing exercises has proved nothing and goes green
# forever.
#
# The teeth run against the REAL export this probe just produced, handed over by directory,
# because damaging a hand-written stand-in would test the stand-in.
T423_ADD_EXP="$TMP/t423-additive-export"
if T423_EXPORT_OUT="$T423_ADD_EXP" timeout 400 node "$ROOT/tools/_t423-additive-export-cdp.mjs" > "$TMP/leg-_t423-additive.out" 2>&1; then
  if T423_EXPORT_DIR="$T423_ADD_EXP" timeout 600 python3 "$ROOT/tools/_t423-additive-export-teeth.py" >> "$TMP/leg-_t423-additive.out" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "the additive-export guard passed but its teeth did not — it can no longer be shown going red, so its green means nothing (run 'T423_EXPORT_DIR=<dir> python3 tools/_t423-additive-export-teeth.py'; each case names the verdict it expected)"
    show_output "$TMP/leg-_t423-additive.out" "_t423-additive-export-teeth.py"
    fail=$((fail + 1))
  fi
else
  report FAIL "export is no longer purely additive — it removed, reordered or altered something outside the DI namespaces (run 'node tools/_t423-additive-export-cdp.mjs'; it names the document, the element index and both sides of the divergence. rc 2 means it REFUSED — a map would not export, or a document would not parse — which says the subject is broken, not the invariant)"
  show_output "$TMP/leg-_t423-additive.out" "_t423-additive-export-cdp.mjs"
  fail=$((fail + 1))
fi
}
leg browser "_t423-additive-export-cdp" _leg_139
_leg_140() {

echo
echo "== exported BPMN validates against the OMG schema and carries complete DI (T-690, T-423) =="
# The subject is what the designer EXPORTS, so this reuses the artefacts the additive leg
# just produced in a real browser rather than validating the committed corpus. That choice is
# the leg's whole meaning: the 24 committed maps are known schema-invalid and pre-DI (T-691),
# so pointing this at them would report a defect nobody is fixing today, go red every run,
# and be muted within a week. Pointed at fresh exports it reports whether the EXPORTER is
# conformant, which is the property that regresses.
#
# WHY THIS EXISTS AT ALL, given the additive guard runs directly above it. That guard proves
# export ADDS DI and changes nothing else — it is a source↔export comparison and is therefore
# blind to any fault both sides share. Every corpus map emitted extensionElements after
# conditionExpression, so every export did too, so the guard was green across 113 schema
# violations. Nothing in this suite validated against the actual XSD; every check was
# name-based or byte-based, and order is exactly what a name scan discards. This leg closes
# that: the OMG schemas are vendored under tools/schemas/bpmn20 with pinned digests, and
# --verify-schemas refuses if one was edited locally.
#
# Its --self-test carries the fault that prompted it and six more, each watched red before
# the leg was wired. Run it before believing a green here.
#
# COST: ~2s. No browser — it validates files the previous leg already wrote.
# Existence test via find (no stderr to discard: the dir is checked first), so T-527's
# capture invariant can keep reading every `if … > null-sink` line as a discarded probe.
if [ -d "$T423_ADD_EXP" ] && [ -n "$(find "$T423_ADD_EXP" -maxdepth 1 -name '*.bpmn' -print -quit)" ]; then
  if timeout 120 python3 "$ROOT/tools/_t423-di-schema-validate.py" --self-test > "$TMP/leg-_t423-schema.out" 2>&1 \
     && timeout 300 python3 "$ROOT/tools/_t423-di-schema-validate.py" "$T423_ADD_EXP"/*.bpmn >> "$TMP/leg-_t423-schema.out" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "a freshly exported map is not schema-valid BPMN 2.0, or has lost its DI geometry (run 'python3 tools/_t423-di-schema-validate.py <file.bpmn>'; it prints the schema line and the geometry finding separately, because a document can satisfy the XSD and still carry no diagram. If the SELF-TEST leg is what failed, the validator itself is broken and its verdict on the corpus means nothing)"
    show_output "$TMP/leg-_t423-schema.out" "_t423-di-schema-validate.py"
    fail=$((fail + 1))
  fi
else
  # Not a pass. The exports are this leg's entire population; without them it has ranged
  # over nothing, and a silent skip is how a leg's coverage evaporates with its count intact.
  report FAIL "REFUSED — no exported maps to validate at \$T423_ADD_EXP, so nothing was checked against the schema (the additive-export leg above produces them; fix that leg first)"
  fail=$((fail + 1))
fi
}
leg browser "_t423-di-schema-validate" _leg_140
_leg_141() {

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
}
leg browser "_t511-unwired-node-roundtrip" _leg_141
_leg_142() {

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
}
leg browser "_t513-thirdparty-identity-roundtrip" _leg_142
_leg_143() {

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
}
leg browser "_t515-external-uid-conformance" _leg_143
_leg_144() {

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
}
leg core "_t516-episodic-decisions-teeth" _leg_144
_leg_145() {

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
}
leg browser "_t518-uid-collision" _leg_145
_leg_146() {

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
}
leg browser "_t520-uid-xml-safety" _leg_146
_leg_147() {

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
}
leg core "_t517-vendor-divergence" _leg_147
_leg_148() {

# T-1123: the vendored hand-off predicate (inception_handoff_blockers) asks our T-866 hypothesis gate on a
# GO recommendation, so fw task review / Watchtower never offer a GO that fw inception decide refuses.
# A re-vendor that drops the local fix (or the gate it pairs with) turns this red.
if bash "$ROOT/tools/_t1123-handoff-hypothesis.sh" > "$TMP/leg-_t1123.out" 2>&1 \
   && grep -q "T-1123: 8 passed, 0 failed" "$TMP/leg-_t1123.out"; then
  pass=$((pass + 1))
else
  report FAIL "the inception hand-off predicate no longer agrees with the decide gate on the GO hypothesis — a GO-recommended inception with an unready hypothesis would be offered to the operator and refused at decide (run 'bash tools/_t1123-handoff-hypothesis.sh'; T-1123, G-085)"
  show_output "$TMP/leg-_t1123.out" "_t1123-handoff-hypothesis.sh"
  fail=$((fail + 1))
fi
}
leg core "_t1123-handoff-hypothesis" _leg_148
_leg_149() {

if python3 "$ROOT/tools/_t517-vendor-divergence-teeth.py" > "$TMP/leg-_t517-vendor-divergence-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the divergence instrument stopped detecting the classes it claims to — mode-only divergence, stale entries, or an unreachable baseline refusing instead of passing (run 'python3 tools/_t517-vendor-divergence-teeth.py' for the failing leg)"
  show_output "$TMP/leg-_t517-vendor-divergence-teeth.out" "_t517-vendor-divergence-teeth.py"
  fail=$((fail + 1))
fi
}
leg core "_t517-vendor-divergence-teeth" _leg_149
_leg_150() {

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
}
leg browser "_t523-subprocess-nesting" _leg_150
_leg_151() {

if timeout 600 python3 "$ROOT/tools/_t523-nesting-teeth.py" > "$TMP/leg-_t523-nesting-teeth.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the nesting probe stopped being able to detect the alternative behaviour — either the mutation target in parseBpmnXml moved (rc 2, a refusal), the probe no longer goes red on a mutant that drops nested nodes, or it no longer refuses when its pin file is absent (run 'python3 tools/_t523-nesting-teeth.py' for the failing leg)"
  show_output "$TMP/leg-_t523-nesting-teeth.out" "_t523-nesting-teeth.py"
  fail=$((fail + 1))
fi
}
leg browser "_t523-nesting-teeth" _leg_151
_leg_152() {

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
}
leg core "_t522-episodic-reachability-teeth" _leg_152
_leg_153() {

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
}
leg core "_t524-fabric-validate-teeth" _leg_153
_leg_154() {

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
}
leg core "_t525-fabric-coverage-teeth" _leg_154
_leg_155() {

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
}
leg core "_t527-capture-invariant" _leg_155
_leg_156() {

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
}
leg core "_t532-hermeticity-scope-census" _leg_156
_leg_157() {

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
}
leg core "_t534-d2-queue-tier-teeth" _leg_157
_leg_158() {

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
}
leg core "_t535-trend-key-teeth" _leg_158
_leg_159() {

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
}
leg core "_t536-status-desync-teeth" _leg_159
_leg_160() {

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
}
leg core "_t538-control-id-collision" _leg_160
_leg_161() {

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
}
leg core "_t539-gap-closure-gauge-conformance" _leg_161
_leg_162() {

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
}
leg core "_t541-bvp-driver-handler-teeth" _leg_162
_leg_163() {

# ── T-931 / T-1009: `fw task delegate` makes ownership follow the open Human criteria ──
# The fix (owner flips only when no Human criterion is open, not only when this run converted
# something) was lost silently in the 1.7.740 re-vendor because no test held it. Four cases,
# one a control: an open judgement criterion must keep owner: human.
if python3 "$ROOT/tools/_t931-delegate-owner-follows-criteria.py" > "$TMP/leg-_t931-delegate-owner.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "fw task delegate no longer makes ownership follow the open Human criteria — a task with nothing open keeps owner: human, or one with an open criterion lost it (run 'python3 tools/_t931-delegate-owner-follows-criteria.py'; rc 2 means the CLI could not be run, not a pass)"
  show_output "$TMP/leg-_t931-delegate-owner.out" "_t931-delegate-owner-follows-criteria.py"
  fail=$((fail + 1))
fi
}
leg core "_t931-delegate-owner-follows-criteria" _leg_163
_leg_164() {

# ── T-1211: every CDP probe's readiness budget reads CDP_READY_MS (set above), so one value governs the whole run ──
if bash "$ROOT/tools/_t1211-cdp-ready-budget-guard.sh" > "$TMP/leg-_t1211-ready-budget.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a CDP probe hard-codes its editor-readiness budget instead of reading CDP_READY_MS, so under load it flakes on its own clock (run 'bash tools/_t1211-cdp-ready-budget-guard.sh'; rc 2 = could not measure)"
  show_output "$TMP/leg-_t1211-ready-budget.out" "_t1211-cdp-ready-budget-guard.sh"
  fail=$((fail + 1))
fi
}
leg browser "_t1211-cdp-ready-budget-guard" _leg_164
_leg_165() {

# ── T-390 / T-1205: capture verbs (fw context add-learning …) run with no active task, and the arm is load-bearing ──
# Unwired until T-1205, so when upstream reshaped the arm its mutant stopped applying and nobody saw the teeth go inert.
if bash "$ROOT/tools/_t390-capture-verbs-nulltask.sh" > "$TMP/leg-_t390-capture-verbs.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the no-task gate no longer admits the capture verbs, or the TEETH mutant stopped applying so the leg proves nothing (run 'bash tools/_t390-capture-verbs-nulltask.sh')"
  show_output "$TMP/leg-_t390-capture-verbs.out" "_t390-capture-verbs-nulltask.sh"
  fail=$((fail + 1))
fi
}
leg core "_t390-capture-verbs-nulltask" _leg_165
_leg_166() {

# ── T-640 / T-647 / T-1205: a fetch that writes a file is a write; every verdict the guard took away is priced ──
# Unwired until T-1205, so upstream replacing 832's guard (T-3222) left its mutations inert unnoticed. rc 3 is
# COULD-NOT-MEASURE (a mutation no longer applies), never a pass.
if bash "$ROOT/tools/_t640-fetchers-that-write-are-writes.sh" > "$TMP/leg-_t640-fetchers.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a curl/wget download is admitted with no task, a reader is newly blocked without being priced, or a mutation stopped applying (run 'bash tools/_t640-fetchers-that-write-are-writes.sh'; rc 3 = could not measure)"
  show_output "$TMP/leg-_t640-fetchers.out" "_t640-fetchers-that-write-are-writes.sh"
  fail=$((fail + 1))
fi
}
leg core "_t640-fetchers-that-write-are-writes" _leg_166
_leg_167() {

# ── T-936 / T-1009: the bare-import gate refuses what its header promises, and nothing else ──
# Its code had narrowed to line 1's first word while the header still promised && ; | newline.
# 8 catches and 9 controls (both heredoc forms, python -c, grep/echo mentions, absolute path).
if bash "$ROOT/tools/_t936-bare-import-gate-teeth.sh" > "$TMP/leg-_t936-bare-import-gate.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the bare-import gate (check-bare-import.sh) misses a catch its header promises, or blocks a working command such as a python heredoc (run 'bash tools/_t936-bare-import-gate-teeth.sh'; rc 2 means the gate script was not found)"
  show_output "$TMP/leg-_t936-bare-import-gate.out" "_t936-bare-import-gate-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t936-bare-import-gate-teeth" _leg_167
_leg_168() {

# ── T-1005 / AEF T-3746: allowlisted "reads" that write are refused; quoted operators are not ──
# 11 writes (incl. the echo > control) and 10 reads, composed exactly as check-active-task.sh
# composes the no-task gate. 1.7.740 as shipped scores 10/21; a re-vendor that drops our
# safe-commands.sh fixes shows up here.
if bash "$ROOT/tools/_t3746-allowlisted-writes-fixture.sh" > "$TMP/leg-_t3746-allowlisted-writes.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "an allowlisted read-only verb writes a file without being refused by the no-task gate, or a read with a quoted > is refused (run 'bash tools/_t3746-allowlisted-writes-fixture.sh'; rc 2 means safe-commands.sh was not found)"
  show_output "$TMP/leg-_t3746-allowlisted-writes.out" "_t3746-allowlisted-writes-fixture.sh"
  fail=$((fail + 1))
fi
}
leg core "_t3746-allowlisted-writes-fixture" _leg_168
_leg_169() {

# ── T-1024 / T-939: this host's machine-id (secrets-store key material) is in no tracked file ──
# The 1.7.740 re-vendor restored it silently in a vendored report; found by the T-1020 census.
# Prints paths only, never the value; its control plants a copy in a scratch repo first.
if python3 "$ROOT/tools/_t1024-machine-id-not-tracked.py" > "$TMP/leg-_t1024-machine-id.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "this host's machine-id (the secrets-store key derives from it) is in a tracked file again, or the scan's control failed (run 'python3 tools/_t1024-machine-id-not-tracked.py'; it names the files and never prints the value)"
  show_output "$TMP/leg-_t1024-machine-id.out" "_t1024-machine-id-not-tracked.py"
  fail=$((fail + 1))
fi
}
leg core "_t1024-machine-id-not-tracked" _leg_169
_leg_170() {

# ── T-1025 / T-908: fw fabric impact survives plain-string depends_on entries and refuses loudly ──
# A string entry anywhere in the corpus used to crash the traversal, and 2>/dev/null turned the
# crash into an EMPTY chain ("nothing depends on this"). Lost silently by the 1.7.740 re-vendor.
if bash "$ROOT/tools/_t1025-fabric-impact-teeth.sh" > "$TMP/leg-_t1025-fabric-impact.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "fw fabric impact crashes on a plain-string depends_on entry or prints an empty chain instead of refusing (run 'bash tools/_t1025-fabric-impact-teeth.sh')"
  show_output "$TMP/leg-_t1025-fabric-impact.out" "_t1025-fabric-impact-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t1025-fabric-impact-teeth" _leg_170
_leg_171() {

# ── T-1026 / T-866: an inception GO needs a hypothesis whose success someone could go and look at ──
# Lost silently by the 1.7.740 re-vendor (lib/task-audit.sh never declared); TEETH BROKEN until
# restored. NO-GO/DEFER untouched; research-kind inceptions keep the declared exemption.
if bash "$ROOT/tools/_t866-hypothesis-form-teeth.sh" > "$TMP/leg-_t866-hypothesis.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "fw inception decide ... go no longer requires an observable hypothesis, or the gate went missing (run 'bash tools/_t866-hypothesis-form-teeth.sh'; TEETH BROKEN means audit_inception_hypothesis is gone again)"
  show_output "$TMP/leg-_t866-hypothesis.out" "_t866-hypothesis-form-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t866-hypothesis-form-teeth" _leg_171
_leg_172() {

# ── T-1027 / T-912: fw note promote links observation <-> task, and survives a failed creation ──
# 1.7.740 wrote the literal 'promoted_to: task', ignored create-task's exit code, and hard-coded
# --owner human — which create-task now refuses without --human-ac, so promote could not succeed.
if bash "$ROOT/tools/_t1027-note-promote-teeth.sh" > "$TMP/leg-_t1027-note-promote.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "fw note promote no longer records the created task id, drops the reverse link, mis-sets the owner, or marks an observation promoted when no task was created (run 'bash tools/_t1027-note-promote-teeth.sh')"
  show_output "$TMP/leg-_t1027-note-promote.out" "_t1027-note-promote-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t1027-note-promote-teeth" _leg_172
_leg_173() {

# ── T-1028 / T-914: fw note resolve — the inbox's largest class has an exit, with a validated carrier ──
if bash "$ROOT/tools/_t1028-note-resolve-teeth.sh" > "$TMP/leg-_t1028-note-resolve.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "fw note resolve is missing, records no carrier, or writes on a refusal (run 'bash tools/_t1028-note-resolve-teeth.sh')"
  show_output "$TMP/leg-_t1028-note-resolve.out" "_t1028-note-resolve-teeth.sh"
  fail=$((fail + 1))
fi
}
leg core "_t1028-note-resolve-teeth" _leg_173
_leg_174() {

# ── T-650 / T-1037: an alias is the command it aliases (fw git commit, fw fix-learned) ──
if bash "$ROOT/tools/_t650-an-alias-is-the-command-it-aliases.sh" > "$TMP/leg-_t650-alias.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "with no task, fw git commit / fw fix-learned no longer get the verdict of git commit / fw context add-learning, or the admission widened (run 'bash tools/_t650-an-alias-is-the-command-it-aliases.sh'; T-1037)"
  show_output "$TMP/leg-_t650-alias.out" "_t650-an-alias-is-the-command-it-aliases.sh"
  fail=$((fail + 1))
fi
}
leg core "_t650-an-alias-is-the-command-it-aliases" _leg_174
_leg_175() {

# ── T-662 / T-1038: a refused null-focus commit line says why, and how to get through ──
if bash "$ROOT/tools/_t662-null-focus-commit-path-must-be-discoverable.sh" > "$TMP/leg-_t662-nullfocus.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "with no task, a refused commit line no longer names its cause and the way through, the advisory prints on unrelated blocks, or the commit path itself broke (run 'bash tools/_t662-null-focus-commit-path-must-be-discoverable.sh'; T-1038)"
  show_output "$TMP/leg-_t662-nullfocus.out" "_t662-null-focus-commit-path-must-be-discoverable.sh"
  fail=$((fail + 1))
fi
}
leg core "_t662-null-focus-commit-path-must-be-discoverable" _leg_175
_leg_176() {

# ── T-688 / T-1034: upstream debt may not grow faster than it is delivered ──
if python3 "$ROOT/tools/_t688-divergence-drain-ratchet.py" > "$TMP/leg-_t688-drain.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the divergence drain ratchet moved: more upstream fixes are undelivered than tools/_t688-divergence-drain-baseline.txt allows (mark deliveries with delivered: + delivered_ref:), or fewer (lower the baseline) (run 'python3 tools/_t688-divergence-drain-ratchet.py'; T-1034)"
  show_output "$TMP/leg-_t688-drain.out" "_t688-divergence-drain-ratchet.py"
  fail=$((fail + 1))
fi
}
leg core "_t688-divergence-drain-ratchet" _leg_176
_leg_177() {

# ── T-1039: the 13 hook-fix teeth (T-628..T-662), repaired for 1.7.740 after the T-1035 census ──
# _t650 and _t662 are wired above (T-1037/T-1038). Each tooth was re-anchored or updated, and its
# mutation (or stated negative control) was shown biting; _t639 is retired to _t1005.
T1039_TEETH=(
  'tools/_t628-g020-remedy-reachable.sh|a G-020 block names a remedy that works from the blocked state (T-628/T-3299)'
  'tools/_t629-g067-remedy-reachable.sh|a G-067 (inception open-questions) block remedy is reachable (T-629)'
  'tools/_t631-tier0-approval-reachable.sh|Tier-0 self-approval stays human-only AND the block names the operator route (T-631, rewritten by T-1039)'
  'tools/_t632-read-only-misclassification.sh|read-only commands are not refused as writes; curl -o / wget stay writes (T-632)'
  'tools/_t633-shared-tmp-sinks.sh|no tool or verification loop uses a fixed shared /tmp sink (T-633)'
  'tools/_t634-guard-verdict-reaches-caller.sh|a malformed Verification block stops completion (T-634)'
  'tools/_t636-prose-verbs-vetoed-by-their-own-text.sh|a framework verb free-prose argument is not vetoed by rm/tee in the prose (T-636)'
  'tools/_t637-inception-coverage.sh|every undecided inception reaches a reader (T-637)'
  'tools/_t638-commit-exemption-is-clause-scoped.sh|the null-focus commit exemption is judged per clause (T-638)'
  'tools/_t639-drift-gate-reads-fixtures.sh|RETIRED to _t1005 (drift target clause-scoped); fails if its successor is missing or red (T-639)'
  'tools/_t654-watchdog-detections-must-be-surfaced.sh|completion-watchdog detections are surfaced, and a completed task with no episodic is flagged (T-654)'
)
for _entry in "${T1039_TEETH[@]}"; do
  _tool="${_entry%%|*}"; _tool="${_tool#tools/}"; _why="${_entry#*|}"
  if (cd "$ROOT" && timeout 600 bash "$ROOT/tools/$_tool") > "$TMP/leg-t1039-$_tool.out" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "hook-fix tooth $_tool failed: $_why (run 'bash tools/$_tool'; T-1039)"
    show_output "$TMP/leg-t1039-$_tool.out" "$_tool"
    fail=$((fail + 1))
  fi
done
}
leg core "_t1039-hook-teeth" _leg_177
_leg_178() {

# ── T-1017: the round-trip leg counts DECLARED identities, not comment prose ──
if python3 "$ROOT/tools/_t1017-uid-count-teeth.py" > "$TMP/leg-_t1017-uid-count.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the round-trip harness's uid count no longer discriminates: a removed uid or a uid that exists only inside a comment is no longer caught, or the control fixture fails (run 'python3 tools/_t1017-uid-count-teeth.py'; exit 2 means it could not run)"
  show_output "$TMP/leg-_t1017-uid-count.out" "_t1017-uid-count-teeth.py"
  fail=$((fail + 1))
fi
}
leg browser "_t1017-uid-count-teeth" _leg_178
_leg_179() {

# ── T-1048: every design on the gallery overview page has a preview tile ──
if python3 "$ROOT/tools/_t1048-gallery-thumbs.py" > "$TMP/leg-_t1048-thumbs.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a design on the gallery overview page has no preview tile, an <img> points at a missing file, or the 'no preview' fallback broke (run 'python3 tools/_t1048-gallery-thumbs.py'; refresh tiles with 'node tools/gen-rendered-thumbs.mjs')"
  show_output "$TMP/leg-_t1048-thumbs.out" "_t1048-gallery-thumbs.py"
  fail=$((fail + 1))
fi
}
leg browser "_t1048-gallery-thumbs" _leg_179
_leg_180() {

# ── T-1047: the no-task gate admits /resume's mail check, and only this project's copy of it ──
if bash "$ROOT/tools/_t1047-session-start-alerts-gate.sh" > "$TMP/leg-_t1047-ssa-gate.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the task gate blocks scripts/session-start-alerts.sh with no focus (so /resume's mail check cannot run at session start), or admits a same-named script elsewhere or a redirect (run 'bash tools/_t1047-session-start-alerts-gate.sh')"
  show_output "$TMP/leg-_t1047-ssa-gate.out" "_t1047-session-start-alerts-gate.sh"
  fail=$((fail + 1))
fi
}
leg core "_t1047-session-start-alerts-gate" _leg_180

# ── T-1013: standing guards the unwired-guard census found with NO live caller ──
# Each asserts a standing property of this repo and passed on 2026-10-04 when it was wired
# (classification and per-tool reasons: docs/reports/T-1013-unwired-classification.md).
# Listed literally so the census (tools/_t451-unwired-guard-census.py) sees each one as called.
T1013_GUARDS=(
  'core|tools/_gallery-claim-verify.py|stdlib regression test of gallery-serve /api/save claim path (temp repo, ephemeral port)'
  'core|tools/_gallery-list-verify.py|regression test of /api/list (temp repo, real server)'
  'core|tools/_gallery-registry-verify.py|regression test of the ghost registry twin'
  'core|tools/_t1005-drift-target-clause-scoped.py|behavioural probe of the drift-gate target (T-639 re-applied, T-1023); named in the divergence register as the guard'
  'core|tools/_t467-arc-tag-source-of-truth.py|teeth for fw arc tag (T-467/T-679); named in the divergence register as the guard'
  'browser|tools/_t573-emits-panel-shape-cdp.mjs|CDP regression: the Emits panel authors the ratified structured shape'
  'core|tools/_t598-source-marker.py|static assertion: the source-end marker points forward (orient=auto)'
  'browser|tools/_t602-documentation-roundtrip.mjs|CDP regression: bpmn:documentation content survives open -> save'
  'browser|tools/_t603-multiprocess-import.mjs|CDP regression: multi-process documents keep content, loss is reported'
  'browser|tools/_t604-cdp-attach-race.mjs|scan: no CDP driver hand-rolls the page-target attach race'
  'browser|tools/_t611-review-card-steps.py|every unchecked [REVIEW] criterion renders its Steps block'   # T-1288: reads the LIVE Watchtower over the network, so not hermetic
  'core|tools/_t614-budget-threshold-drift.py|CLAUDE.mds budget ladder matches budget-gate.sh'
  'browser|tools/_t618-determinism-roundtrip-cdp.mjs|CDP regression: an authored determinism value survives a real save'
  'core|tools/_t630-p011-stdin-swallow.sh|teeth: P-011 does not count commands it never ran'
  'core|tools/_t644-ask-imports-survive-a-wrong-project-root.sh|teeth: lib/ask.py reaches its imports in a vendored install'
  'core|tools/_t646-timeline-prose-is-escaped-before-it-is-trusted.sh|teeth (security): linkify_tasks escapes prose before Markup()'
  'core|tools/_t649-completing-with-uncommitted-work-warns.sh|teeth: completing with uncommitted work warns'
  'core|tools/_t651-stray-root-files-are-caught.sh|teeth: the audit catches zero-byte redirect debris at the root'
  'core|tools/_t654-archiving-a-partial-complete-task-must-null-its-horizon.sh|teeth: an archived task does not keep horizon: now'
  'core|tools/_t656-review-queue-splits-judgement-from-the-status-flip.sh|teeth: D2 splits judgement from the status flip'
  'core|tools/_t658-p011-must-distinguish-killed-from-failed.sh|teeth: the P-011 runner distinguishes killed from failed'
  'core|tools/_t659-retention-sweep-must-not-be-agent-staged.sh|teeth: retention-sweep deletions are not swept into agent commits'
  'core|tools/_t661-mutation-count-is-a-floor.sh|teeth: the shared mutation-completeness assertion is a floor'
  'core|tools/_t674-ctl012-comment-fence.py|fence: CTL-012 ignores ACs in HTML comments and still catches real ones'
  'core|tools/_t675-budget-read-fence.py|fence: every arm of the budget safe-read'
  'core|tools/_t683-save-containment-verify.py|security regression: /api/save write containment'
  'core|tools/_t684-mutation-control.py|mutation control for the /api/save containment fence'
  'core|tools/_t687-hook-function-check.py|function check for stdin-consuming PostToolUse hooks (writes .context/working/.t687-function-baseline.json)'
  'core|tools/_t739-defer-is-not-a-decision.py|reproduces from the live tree that a DEFER keeps an inception on the decisions surface'
  'core|tools/_t767-ownership-correspondence.sh|negative control + standing measurement: ownership follows a real Human AC'
  'core|tools/_t806-corpus-sweep-guard-controls.py|regression: bake-clean-layout.py refuses unknown flags rather than rewriting the corpus'
  'core|tools/_t808-version-parity.sh|standing property: APP_VERSION in src/ equals ./VERSION'
  'core|tools/_t833-ctl029-partial-complete-controls.sh|controls: CTL-029 still catches what it should'
  'core|tools/_t836-census-empty-split-controls.sh|controls: the carrier-shape split measures'
  'core|tools/_t841-scoring-spec-controls.sh|controls: each T-841 verification leg can fail'
  'core|tools/_t842-commit-exemption-spelling-regression.sh|regression pin: the commit exemptions spelling coverage'
  'core|tools/_t843-absence-gate-integration.sh|integration: the absence close-gate fires and its named remedy clears it'
  'core|tools/_t843-absence-gate-tests.sh|tests for the uncontrolled-absence close gate'
  'core|tools/_t845-control-recogniser-tests.sh|tests for _t560s control recogniser'
  'core|tools/_t848-realization-check-tests.sh|tests for the realization-ledger checker'
  'core|tools/_t1149-triage-check.py|every observation the T-1149 triage answered stays answered, and every carrier it cites still resolves (OBS-425 class)'
  'core|tools/_t849-budget-zero-token-tests.sh|teeth: the zero-token hole in checkpoint.shs budget reader'
  'browser|tools/_t886-writer-mutation.py|mutation teeth for the round-trip guard (suppresses each writer attribute, expects red)'
  'browser|tools/_t892-lane-default-cdp.mjs|CDP regression: the lane Authoring default never re-stamps nodes'
  'browser|tools/_t911-kind-badge-verify-cdp.mjs|CDP regression: workflowMeta/@kind settable and visible (writes .playwright-mcp/t911-panel-kind-select.png)'
  'core|tools/_t1161-install-hook.sh --check|the pre-commit hook still carries 832s boundary-inventory gate line (a framework hook reinstall erases it) (T-1161)'
  'core|tools/_t1000-install-hook.sh --check|the pre-commit hook still carries 832s re-vendor gate line (a framework hook reinstall erases it) (T-1000, checked since T-1161)'
  'core|tools/_t1183-tmp-containment.sh|the suite and the instrument sweep run every test with TMPDIR in a private run dir they remove, so nothing they run leaves folders in the shared /tmp (T-1183, P-015)'
  'core|tests/test_t1159_yaml_element_authority.py|the YAML IW-9 check lets a node own aef.authority win over its lane, as the XML form does; both forms agree on 6 cases (T-1159)'
  'core|tools/_t1178-inception-template.sh|the inception template carries the hypothesis section and score fields, the schema hook and GO gate accept it, and an upgrade keeps it (T-1178)'
  'browser|tools/_t1177-panels-cdp.mjs|CDP regression: side panels fold to a notch and back, resize by drag with clamping, double-click reset, persist over reload (T-1177)'
  'browser|tools/_t1176-toolbar-reach-cdp.mjs|CDP regression: every header control visible and clickable at 1024/1200/1280/1440/1920, panels and the XML panel below the header (T-1176)'
  'core|tools/_t1171-landing-flyout-test.py|the /designer cards'"'"' thumbnail fly-out: one per thumbnail card, Open through the card link, still one ?load link per card (T-1171)'
  'core|tools/_t1172-designer-open-test.py|opening a map from /designer keeps Watchtower around it: inline page, frame with the same load value, fullscreen toggle, cards point at it (T-1172)'
  'browser|tools/_t1168-node-id-map.mjs --check|the committed corpus carries exactly the node ids the designer exports (T-1168 migration stays in step)'
  'browser|tools/_t1193-slug-readonly-cdp.mjs|the Slug field is read-only and follows the name; an exported map reloads with identical ids (T-1193)'
  'browser|tools/_t1164-lane-findings-cdp.mjs|CDP regression: lane-anchored validator findings mark the lane header (severity + pill), anchor their dock row and select the lane; marks follow the latest check; a node dragged out does not stretch the drawn pool (T-1164)'
  'browser|tools/_t1194-slug-task-id-cdp.mjs|deriveSlug skips a leading task id (T-001: Orientation -> orientation); other names keep their slug (T-1194)'
  'browser|tools/_t1154-pool-label-fit-cdp.mjs|CDP regression: the drawn pool encloses every rendered label and id badge on the right (24 maps + long-label fixture); the BPMN export stays box-based and pad-free (T-1154)'
  'browser|tools/_t1091-sticky-lanes-cdp.mjs|CDP regression: zoomed and scrolled right, lane names stay pinned at the left edge, aligned and on top; nothing pinned unscrolled; option persists; export and thumbnails unaffected (T-1091)'
  'core|tools/_t1152-stale-review-doc-teeth.py|the stale-[REVIEW]-document detector fires when task content outgrows the document, and stays silent for frontmatter sweeps, ticks, bookkeeping sections, corpus sweeps, checked/non-REVIEW/commented criteria, untracked and non-docs paths (T-1152, OBS-291)'
  'browser|tools/_t1158-witness-per-verdict-teeth.sh|the round-trip guard'"'"'s node and workflowMeta self-tests name a BLIND only where it happened (blind_in + value_before/after), LIVE fixtures apart (also_live_in); proven by one-fixture mutants that the old pooled list misnamed (T-1158, OBS-418)'
  'core|tools/_t1160-closed-record-teeth.sh|a record in completed/ moves only onto an end event (REFUSED-CLOSED, audited), the framework close and partial-complete still walk, successors is read-only; mutation run included (T-1160, OBS-437)'
  'core|tools/_t1192-teeth.sh|after an upgrade, templates identical to the vendored copy are committed, .upstream files ours contains are removed, the rest named (T-1192)'
  'browser|tools/_t1189-id-map-dir.sh|the id-map tool run on another directory (--dir, --designer 0.20.0) reproduces the T-1168 table and migration byte for byte (T-1189, for AEF T-4224)'
  'browser|tools/_t1168-step-numbers-verify-cdp.mjs|CDP regression: node ids number ACTIVITIES only, events/gateways carry a type word, ids unique and round-trip (T-1168)'
  'browser|tools/_t1155-doc-title-verify-cdp.mjs|CDP regression: tab title and XML heading name the open map, across load, switch and rename (T-1155)'
)
# T-1288: each entry is its own leg, its tier the entry's first field ('core|tools/x.py|why').
_t1013_guard() {
  local _entry="$1"
  _tool="${_entry%%|*}"; _tool="${_tool#tools/}"; _why="${_entry#*|}"
  # T-1168: an entry may carry arguments after the tool name ('tools/x.mjs --check|why').
  _args=(); case "$_tool" in *" "*) read -r _tool _rest <<< "$_tool"; read -r -a _args <<< "$_rest" ;; esac
  # T-1204: an entry outside tools/ (tests/test_t1159_…) keeps its own directory, and its output file name is
  # flattened. Before, it ran as tools/tests/… and wrote to a path with a '/', so that leg never ran at all.
  case "$_tool" in */*) _path="$ROOT/$_tool" ;; *) _path="$ROOT/tools/$_tool" ;; esac
  case "$_tool" in
    *.py)  _cmd=(python3 "$_path" "${_args[@]}") ;;
    *.sh)  _cmd=(bash "$_path" "${_args[@]}") ;;
    *.mjs|*.js) _cmd=(node "$_path" "${_args[@]}") ;;
    *) _cmd=(false) ;;
  esac
  _out="$TMP/leg-t1013-${_tool//\//_}.out"
  if (cd "$ROOT" && timeout 600 "${_cmd[@]}") > "$_out" 2>&1; then
    pass=$((pass + 1))
  elif grep -qE '^(CANNOT RUN|COULD NOT MEASURE)' "$_out"; then
    # T-1060: still red (nothing was verified), but named for what it is — the guard never got to
    # look, which is an environment/harness problem, not a regression in what it guards.
    report FAIL "standing guard $_tool COULD NOT RUN (not a verdict on the code — $(grep -m1 -E '^(CANNOT RUN|COULD NOT MEASURE)' "$_out" | cut -c1-120)): $_why (run '${_cmd[0]} ${_path#"$ROOT"/}'; wired by T-1013)"
    show_output "$_out" "$_tool"
    fail=$((fail + 1))
  else
    report FAIL "standing guard $_tool failed: $_why (run '${_cmd[0]} ${_path#"$ROOT"/}'; wired by T-1013)"
    show_output "$_out" "$_tool"
    fail=$((fail + 1))
  fi
}
for _g in "${T1013_GUARDS[@]}"; do
  _g_tier="${_g%%|*}"; _g="${_g#*|}"; _g_tool="${_g%%|*}"; _g_tool="${_g_tool%% *}"
  leg "$_g_tier" "t1013:${_g_tool##*/}" _t1013_guard "$_g"
done
_leg_181() {

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
}
leg core "_t542-cost-blast-radius-teeth" _leg_181
_leg_182() {

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
}
leg core "_t544-session-cookie-port-teeth" _leg_182
_leg_183() {

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
}
leg core "_t545-error-shape-teeth" _leg_183
_leg_184() {

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
}
leg core "_t547-hx-prompt-decode-teeth" _leg_184
_leg_185() {

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
}
leg core "_t548-sweep-classification-teeth" _leg_185
_leg_186() {

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
}
leg core "_t550-audit-parse-anchor-teeth" _leg_186
_leg_187() {

# ── T-1216: a mutant run whose control leg is red is a broken measurement, not an over-killing mutant ──
# A stand-in probe passes on the real source and reddens every leg (reproduce-drop included) on any mutant; the
# _t570 teeth must answer COULD NOT MEASURE (exit 3), not FAIL (exit 1). No browser: it runs in a second.
T1216_RC=0; T570_PROBE="$ROOT/tests/fixtures/t1216/probe-broken-measurement.mjs" python3 "$ROOT/tools/_t570-meta-carriage-teeth.py" > "$TMP/leg-_t1216.out" 2>&1 || T1216_RC=$?
if [ "$T1216_RC" = 3 ] && grep -q '^COULD NOT MEASURE: mutant A: the control leg reproduce-drop was red twice' "$TMP/leg-_t1216.out"; then
  pass=$((pass + 1))
else
  report FAIL "the T-570 teeth scored a broken measurement (control leg red under a mutant) as a verdict again (rc=$T1216_RC, want 3; run 'T570_PROBE=tests/fixtures/t1216/probe-broken-measurement.mjs python3 tools/_t570-meta-carriage-teeth.py'; T-1216)"
  show_output "$TMP/leg-_t1216.out" "_t570-meta-carriage-teeth.py (stand-in)"
  fail=$((fail + 1))
fi
}
leg core "_t1216-broken-measurement" _leg_187
_leg_188() {

# ── T-1221: guards whose only caller was an active task's Verification, wired before those tasks close ──
# _t723 stated the review-queue residue (signed-off tasks left unflipped; >30d rows each carrying a reason) only
# from T-723's Verification, so closing T-723 left it unwired (_t451 ratchet 84 -> 85). _t345 is retired to
# _t344 leg 8 (AEF T-2735 left one coverage check) and stays wired as a delegate, like _t639.
T1221_GUARDS=(
  'python3|tools/_t723-review-queue-residue.py --check|the review-queue residue: a signed-off task is left unflipped, or a >30d row has no reason (T-723)'
  'bash|tools/_t345-fabric-check-agreement.sh|RETIRED to _t344 leg 8 (audit coverage count vs an independent count); fails if its successor is missing or red (T-345, T-1221)'
)
for _entry in "${T1221_GUARDS[@]}"; do
  _run="${_entry%%|*}"; _rest="${_entry#*|}"; _cmd="${_rest%%|*}"; _why="${_rest#*|}"
  _tool="${_cmd%% *}"; _tool="${_tool#tools/}"
  _args=""; case "$_cmd" in *" "*) _args="${_cmd#* }" ;; esac
  # shellcheck disable=SC2086
  if (cd "$ROOT" && timeout 600 $_run "$ROOT/tools/$_tool" $_args) > "$TMP/leg-t1221-$_tool.out" 2>&1; then
    pass=$((pass + 1))
  else
    report FAIL "guard $_tool failed: $_why (run '$_run $_cmd'; T-1221)"
    show_output "$TMP/leg-t1221-$_tool.out" "$_tool"
    fail=$((fail + 1))
  fi
done
}
leg core "_t1221-guards" _leg_188
_leg_189() {

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
}
leg core "_t549-fabric-coverage-mutation-teeth" _leg_189
_leg_190() {

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
}
leg core "_t551-sweep-capture-teeth" _leg_190
_leg_191() {

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
}
leg core "_t448-drift-classification-teeth" _leg_191
_leg_192() {

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
}
leg core "_t552-writeset-hermeticity-teeth" _leg_192
_leg_193() {

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
}
leg core "_t558-hermeticity-census-teeth" _leg_193
_leg_194() {

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
}
leg core "_t560-absence-census-teeth" _leg_194
_leg_195() {

# ── T-1247: every CDP harness makes its Chrome profile dir with the shared helper (removed on signals, swept after SIGKILL) ──
# A load run left 548 /tmp/nodecuts-chrome-* dirs (1.9 GB): `finally` never runs on a signal. Red when a harness
# calls mkdtempSync for --user-data-dir itself; the test also kills a node process both ways and looks for leftovers.
if bash "$ROOT/tools/_t1247-profile-census.sh" > "$TMP/leg-_t1247-census.out" 2>&1 \
   && bash "$ROOT/tests/test_t1247_cdp_profile.sh" > "$TMP/leg-_t1247-test.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "a CDP harness makes its Chrome profile dir without tools/_cdp-profile.mjs, or the helper no longer removes the dir on SIGTERM / sweeps a dead owner's dir (run 'bash tools/_t1247-profile-census.sh' and 'bash tests/test_t1247_cdp_profile.sh'; T-1247)"
  show_output "$TMP/leg-_t1247-census.out" "_t1247-profile-census.sh"
  show_output "$TMP/leg-_t1247-test.out" "test_t1247_cdp_profile.sh"
  fail=$((fail + 1))
fi
}
leg core "_t1247-profile-census" _leg_195
_leg_199() {

# ── T-1239/T-1320: no LAN address enters a commit, and the gate's rewrite leaves nothing staged behind it ──
# The gate test was on disk and never run by the suite (found by T-1320). It runs the real gate and installer in a
# throwaway repo: generated text rewritten, code refused, AEF's tree and the ledgers untouched, and after a pathspec
# commit HEAD, index and worktree all hold the placeholder (before T-1320 the index kept the address, staged).
if bash "$ROOT/tests/test_t1239_lan_gate.sh" > "$TMP/leg-_t1239.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the LAN-address gate lets an address into a commit, refuses or rewrites the wrong files, or leaves the unscrubbed text staged after a pathspec commit (run 'bash tests/test_t1239_lan_gate.sh'; T-1239, T-1320)"
  show_output "$TMP/leg-_t1239.out" "test_t1239_lan_gate.sh"
  fail=$((fail + 1))
fi
}
leg core "test_t1239_lan_gate" _leg_199

# ── T-1288: the tier engine itself — tier selection, the no-tier guard, quarantine, retry-once, history rows, core's
# private TMPDIR and namespace, the pre-push installer and gate — on fixture runners, plus the full tier guard here ──
_leg_t1288() {
if python3 "$ROOT/tests/test_t1288_tiers.py" > "$TMP/leg-_t1288.out" 2>&1; then
  pass=$((pass + 1))
else
  report FAIL "the suite's tier engine broke: a tier runs the wrong legs, a leg with no tier passes, a quarantined or past-fix_by leg is scored wrongly, a browser timeout is not retried once (or a core one is), or the pre-push gate/installer misbehaves (run 'python3 tests/test_t1288_tiers.py'; T-1288)"
  show_output "$TMP/leg-_t1288.out" "test_t1288_tiers.py"
  fail=$((fail + 1))
fi
}
leg core "test_t1288_tiers" _leg_t1288

[ "$T1288_LIST" = 1 ] && { [ -z "${_T1288_NOTIER:-}" ]; exit; }
t1288_finish
echo
echo "bridge round-trip: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
