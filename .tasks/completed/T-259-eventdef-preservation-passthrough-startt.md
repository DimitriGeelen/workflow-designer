---
id: T-259
name: "eventDef preservation passthrough: start/throw hosts survive open-save round-trip"
description: >
  T-257 GO build (operator-ratified 2026-07-27): cure the save-path drop of aef:eventDef
  on startEvent + intermediateThrowEvent carriers (AEF field defect rail 201, their
  T-2620). Scope per T-257 scope fence: (1) import passthrough — adoptImportedXml
  captures kind/binding as inert aef fields on hosts the typed-catch override skips
  (no node-type change, no UI); (2) export re-emit — aefExtensionXml emits the passthrough
  aef:eventDef canonically (binding='' when absent, matching the accepted v2 catch
  normalization); (3) regression leg — open fixture v1 (tests/fixtures/aef-bpmn/t257-eventdef-roundtrip)
  then save must keep all 3 eventDefs with kinds intact (timer/message/message on
  th_obs_fire/th_signal/th_pickup). OUT: typed start/throw palette/glyphs/UI (future
  contract round), any change to the typed-CATCH override path (T-204/T-237 unchanged).
  Peer intake pre-cleared at rail 215 (host-agnostic accept); restoring throw eventDefs
  also cures the emitterless-typed-catch lint class (T-2551).

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
created: 2026-07-27T18:26:34Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-27T18:34:28Z
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
  - ts: '2026-08-16T12:33:46Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-257-eventdef-drop-site.md,src/aef-workflow-designer.html,tests/test_roundtrip_serialization.py,tests/test_t259_eventdef_preservation.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-259: eventDef preservation passthrough: start/throw hosts survive open-save round-trip

## Context

Build authorized by T-257 GO (operator, 2026-07-27). Research artifact:
docs/reports/T-257-eventdef-drop-site.md — both drop sites localized in
src/aef-workflow-designer.html (import `_catchHost` guard :9088-9099, export
EVENT_KIND gate :8735-8739). Fixture pair pinned at
tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/ (peer byte-check EXACT MATCH).

## Acceptance Criteria

### Agent
- [x] Import passthrough: adoptImportedXml captures kind/binding from `<aef:eventDef>`
      on any host where the typed-catch override does not fire (startEvent,
      intermediateThrowEvent, link-with-target, unknown kinds) as inert aef fields —
      node type and host tag unchanged, no UI surface.
- [x] Export re-emit: aefExtensionXml emits the passthrough `<aef:eventDef kind binding>`
      canonically (binding="" when absent), exactly one eventDef per carrier, and the
      typed-catch EVENT_KIND path takes precedence (no duplicate emit).
- [x] Regression leg (new CDP harness + pytest wrapper, typed-events pattern): parsing
      fixture v1 keeps th_obs_fire type startEvent + kind timer, th_signal type
      linkEventThrow + kind message, th_pickup type eventMessage (T-204 override
      untouched); re-emitted XML re-parses to the same model (passthrough fixed point);
      BITE leg proves the passthrough is driven by the aef:eventDef element.
- [x] Existing suite stays green: round-trip serialization sweep, typed-events harness,
      bridge parity tests — no behavioural change on typed-CATCH or boundary paths.
      (Note: the T-237 classification leg in _editor-behavior-verify-cdp.mjs asserted
      the superseded drop contract — updated to lock the ratified preservation
      contract instead; full bridge suite 37/37 after.)

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

# Exit codes are the verdict (wrappers return non-zero on failure, loud SKIP on missing toolchain)
python3 tests/test_t259_eventdef_preservation.py
python3 tests/test_typed_events.py
python3 tests/test_roundtrip_serialization.py

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

**Symptom:** A layout-only open→save in the designer silently stripped
`aef:eventDef` from startEvent and intermediateThrowEvent carriers while the catch
kept its (AEF field report, rail 201 / their T-2620; byte-pair fixture pinned).

**Root cause:** The T-237 catch-only override was implemented as consume-or-discard:
the importer had no preservation path for eventDefs the override didn't consume
(`_catchHost` guard, adoptImportedXml), and the exporter only emitted eventDefs
derived from typed-catch node types (EVENT_KIND gate, aefExtensionXml). Any
non-catch eventDef was destroyed at parse time and unreproducible at export time.

**Why structurally allowed:** The round-trip guard asserts fixed-point
SELF-CONSISTENCY — a consistent drop is a perfectly stable fixed point, so the
defect was invisible to it. No correctness leg covered non-catch eventDef hosts;
the T-237 behavior leg actively locked the drop in as "the decision".

**Prevention:** tests/test_t259_eventdef_preservation.py drives the real editor
runtime against the pinned peer field bytes with a BITE leg (guard proven
non-vacuous); the T-237 classification leg now locks the preservation contract,
so a regression to dropping fails two independent harnesses.

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

### 2026-07-27T18:26:34Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-259-eventdef-preservation-passthrough-startt.md
- **Context:** Initial task creation

### 2026-07-27T18:26:39Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-27T18:34:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
