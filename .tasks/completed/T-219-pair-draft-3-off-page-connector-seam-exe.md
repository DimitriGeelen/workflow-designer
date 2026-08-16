---
id: T-219
name: "Pair-draft #3: off-page connector seam exemplar (resolved + ghost + legacy
  legs) — AEF T-2571 byte-fixture"
description: >
  Pair-draft #3: off-page connector seam exemplar (resolved + ghost + legacy legs)
  — AEF T-2571 byte-fixture

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-21T07:41:22Z
last_update: '2026-08-16T13:58:51Z'
date_finished: 2026-07-21T18:22:18Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-218-offpage-connector-pairing.md,tests/fixtures/aef-bpmn/offpage-seam.bpmn,tests/test_corpus_fixture_pins.py,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:51Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:docs/reports/T-218-offpage-connector-pairing.md,tests/fixtures/aef-bpmn/offpage-seam.bpmn,tests/test_corpus_fixture_pins.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-219: Pair-draft #3: off-page connector seam exemplar (resolved + ghost + legacy legs) — AEF T-2571 byte-fixture

## Context

Pair-draft #3 of the AEF collaboration loop (arc: designer-authoring-surface) — the shared
byte-fixture for the **off-page connector seam** (AEF T-2571, contract v0 ratified, see
`[[aef-integration-rail]]` + `docs/reports/T-218-offpage-connector-pairing.md`). A canonical-
dialect BPMN process that exercises all three ratified `<aef:link>` legs in one diagram:
one **resolved** `workflowRef` (→ a real live uuid on AEF's store — compile resolves silent
per the T-217 taxonomy), one **ghost** `workflowRef` (→ an unresolved uuid — exercises
`ghosts[]` + `referenced_by` + AEF's S4 task-mint), and one **legacy** `targetWorkflow="<slug>"`
with no `workflowRef` (exercises AEF's import-alias / resolve-by-name + migrate-advisory).
832 authors + validates clean + byte-pins; AEF compiles + runs it through
`test_offpage_seam_lifecycle.py` + sha-guards. Design-dialogue-class fixture work (NOT the
gated T-218 editor build). Delivered pattern mirrors T-214/T-215.

**Dependency:** the resolved leg needs a real live uuid — requested from AEF on the rail
(offset 114). Structure + validation proceed now with a placeholder uuid; final byte-pin +
delivery gated on AEF's `{id,uuid}` reply.

**Finalization rehearsal (2026-07-21, on a temp copy — committed fixture untouched):**
- Swapping the resolved placeholder for a realistic v4 uuid → validator returns `VALID … no
  findings`. **No uuid-format sensitivity** — finalization is a single `sed` swap of
  `11111111-1111-4111-8111-111111111111` → AEF's real uuid, then re-validate.
- Sizes: raw ≈ 10002 B, **base64 ≈ 13336 B > 12288 single-message threshold → delivery NEEDS
  2-part chunking** (split at midpoint → PART 1/2 + PART 2/2, `printf '%s%s' p1 p2 | base64 -d
  | sha256sum` == pin BEFORE posting). AC-6's "chunked if >12KB b64" is therefore CONFIRMED
  chunked, not conditional.
- Post-reply steps, in order: (1) `sed` swap the resolved uuid; (2) re-run
  `tools/validate-workflow.py` (expect clean); (3) `sha256sum` the final bytes; (4) add
  `"offpage-seam.bpmn": "<sha>"` to `FULL_SHA` in `tests/test_corpus_fixture_pins.py` (harness
  is already generic — one dict entry, no other wiring); (5) `python3
  tests/test_corpus_fixture_pins.py` (expect pass); (6) deliver rail-inline in 2 concat-verified
  chunks.

## Acceptance Criteria

### Agent
- [x] `tests/fixtures/aef-bpmn/offpage-seam.bpmn` authored in canonical dialect: 3 authority-typed lanes (human·sovereignty / framework·authority / agent·initiative) with `aef:laneMeta`, `aef:uid` + `aef:position` on every flow node, `aef:uid` on every sequenceFlow, `aef:workflowMeta schemaVersion="2"`
- [x] Carries all three ratified link legs: (a) resolved `<aef:link workflowRef="1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7" name="aef-task-lifecycle"/>` (AEF's recommended live uuid, rail 118), (b) ghost `workflowRef="22222222-…"` (unresolved), (c) legacy `targetWorkflow="review-map"` NO workflowRef
- [x] Validates CLEAN under `tools/validate-workflow.py` (exit 0, no findings)
- [x] Resolved leg's `workflowRef` == a real live uuid from AEF's store (aef-task-lifecycle 1f9b5f0c, rail offset 118) — NOT a placeholder
- [x] Byte-pinned (sha256 `0bc15bfac81d80cc13df527a09056dda6170def304d5a43c038bb504b691449d`) into `tests/test_corpus_fixture_pins.py` `FULL_SHA` + guard passes 3/3
- [x] Delivered to AEF rail-inline (chunked, concat-verified to the pin BEFORE posting) — **DONE 2026-07-21: fixture re-verified byte-intact against pin (FIXTURE-OK); base64 (13352 B) split at midpoint into 6676+6676; `printf '%s%s' p1 p2 | base64 -d | sha256sum` == 0bc15bfac8…449d (CONCAT-VERIFY-OK) BEFORE posting; posted PART 1/2 → rail offset 120, PART 2/2 → offset 121 (topic dm:0e7ee6cad65137fc:6a646ce8b1bc6560, both in_reply_to 119, mentions AEF). Awaiting AEF `fw bpmn` compile + sha-guard verdict.**

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/offpage-seam.bpmn
# all three link legs present (resolved workflowRef, ghost workflowRef, legacy targetWorkflow-no-workflowRef)
# NB: gate runs each line as its OWN shell under set -u — no cross-line $out; each grep is self-contained (see T-220)
grep -q 'aef:link workflowRef=' tests/fixtures/aef-bpmn/offpage-seam.bpmn
grep -q 'aef:link targetWorkflow=' tests/fixtures/aef-bpmn/offpage-seam.bpmn
# byte-pin guard passes (includes offpage-seam.bpmn once pinned)
python3 tests/test_corpus_fixture_pins.py

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-21T07:41:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-219-pair-draft-3-off-page-connector-seam-exe.md
- **Context:** Initial task creation

### 2026-07-21T18:22:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
