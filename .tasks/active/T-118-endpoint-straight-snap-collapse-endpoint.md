---
id: T-118
name: "Endpoint straight-snap: collapse endpoint-adjacent micro-steps on axis-aligned edges"
description: >
  T-117 deferred follow-up (improvement B, fuller). After the re-bake, ~10 residual routing micro-steps remain corpus-wide: endpoint-adjacent 2-4px perpendicular steps on edges whose source and target ports are axis-aligned within tolerance. Two causes: (1) off-centre gateway source-port (diamond drop leaves ~4px off the bottom vertex while target is centred), (2) spurious corridor micro-offset (src==tgt centre but run drifts 2-4px in 2px steps for channel separation that separates nothing). Fix: extend simplifyRoutedPolyline (T-117) with an endpoint straight-snap — when first/last points are axis-aligned within tolerance and all interior vertices are within tolerance of a shared axis coordinate that lies within both node faces, collapse to a single straight run. Guarded by polylineCrossesNodes not increasing (PL-005 self-validating, PD-044 render-only). Genuine migrations (e.g. release e_15, 31px centre diff) excluded by tolerance.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [ui, editor, routing, layout]
components: []
related_tasks: [T-117, T-116, T-105]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T22:45:18Z
last_update: 2026-07-07T14:18:27Z
date_finished: 2026-07-07T14:18:06Z
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
---

# T-118: Endpoint straight-snap: collapse endpoint-adjacent micro-steps on axis-aligned edges

## Context

Improvement B ("connect on 90° for clean connection"), fuller slice — the
endpoint-adjacent micro-steps T-117 explicitly deferred. Headless census after the
T-101 re-bake (2026-07-06): ~10 residual micro-steps corpus-wide, all endpoint-
adjacent 2–4px perpendicular steps. Two causes measured:
1. **Off-centre gateway source-port** (harvest e_08, cross-host e_10): a gateway drop
   leaves ~4px off the diamond's bottom vertex while the target end-event is centred
   on the same x → a 4px step near the target. Source cx == target cx (811, 1341).
2. **Spurious corridor micro-offset** (harvest e_25, release e_13, review e_07): src
   and tgt share a centre axis (x or y) but the run drifts 2–4px in 2px increments for
   channel separation that separates it from no sibling (nearest parallel edge >140px).

Genuine migrations are OUT of scope: release e_15 (src cx 1584, tgt cx 1615 — a real
31px horizontal migration rendered as two 12px steps) must be left alone.

Fix: extend `simplifyRoutedPolyline` (T-117) with an endpoint straight-snap post-pass.

## Acceptance Criteria

### Agent
- [x] `simplifyRoutedPolyline` extended with an endpoint straight-snap
      (`endpointStraightSnap`): when the polyline's first and last points are
      axis-aligned within tolerance (`EDGE_SNAP_TOL`, 8px — renamed from SNAP_TOL to
      avoid colliding with the magnet-drag SNAP_TOL=7 at line 5277) on the minor axis
      AND every vertex lies within `EDGE_SNAP_TOL` of a shared axis coordinate that
      falls within BOTH source and target face spans, collapse to a single straight
      segment at that coordinate. Also lowered simplify's early-return 5→3 so 4-point
      micro-step polylines (which T-117 skipped) are now handled
- [x] Snap accepted ONLY if `polylineCrossesNodes` does not increase (reuse the
      T-117 self-validating guard; a step that clears an obstacle is preserved)
- [x] Genuine migrations excluded: release e_15 (endpoint dx=23px > tol) NOT snapped,
      still renders its 6-point / 2-step migration (verified headless + screenshot)
- [x] Wired into the same `buildOrthogonalPath` finalize path as T-117 (inside
      `simplifyRoutedPolyline`, applied to the transient polyline used for BOTH the
      drawn `d` string and `edge._renderedPolyline`); stored geometry untouched (PD-044)
- [x] Corpus-wide headless proof: the 5 pure-drift cases (harvest e_08/e_25,
      release e_13, cross-host e_10, review e_07) render as a single straight 2-point
      run (0 residual micro-steps); release e_15 unchanged; node-cut gate 0/24 PASS
      (0 regressed); bridge 31/31, geometry 24 clean. Only residual micro-steps across
      9 sampled maps = e_15's 2 legit migration steps
- [x] Before/after element-level screenshots READ for 2 cases: cross-host e_10
      (gateway→ERROR-event drop, now dead-straight into the event centre) and
      release e_13 vs e_15 (aligned drop snapped straight; 31px-migration drop kept
      its steps) — `t118-crosshost-e10-after.png`, `t118-release-e13-after.png`
- [x] Editor JS synced byte-identical to build/gallery/designer.html

### Human
- [ ] [REVIEW] Edges connect to node faces with a clean 90° corner, no tiny endpoint step
  **Steps:**
  1. Reuse the gallery on :8834; open harvest-pipeline and release-pipeline
  2. Look at the gateway→end-event drops (e.g. the "No" branches dropping to red end
     events) and the long vertical drops into the remote/gh tasks
  **Expected:** each connector meets the node face as one straight line — no 2–4px
  jog right before the face
  **If not:** note the map + edge that still steps (a genuine migration like the
  gh-release branch is expected to keep its single Z and is not a defect)

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
diff -q src/aef-workflow-designer.html build/gallery/designer.html
grep -q "SNAP_TOL" src/aef-workflow-designer.html
tests/check-corpus-node-cuts.sh

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

## Recommendation

**Recommendation:** GO (finalize — agent ACs complete, ship to human REVIEW)

**Rationale:** All 7 Agent ACs are implemented and verified. The endpoint straight-snap
(`SNAP_TOL` gated micro-step collapse) is present in source and part of the same
render-only `simplifyRoutedPolyline` pass as T-117/T-119, with stored geometry untouched
(PD-044). No baseline risk: the corpus node-cut gate is 0/24 (0 regressed) and the mirror
invariant holds byte-identical. The one remaining AC is a Human REVIEW of whether the
endpoint corner *reads* clean — subjective taste that needs the operator's eye.

**Evidence:**
- Mirror invariant: `diff -q src/aef-workflow-designer.html build/gallery/designer.html` → identical
- `grep -c SNAP_TOL src/aef-workflow-designer.html` → 10 references present
- Corpus node-cut gate: `tests/check-corpus-node-cuts.sh` → 24 unchanged, 0 regressed, total cuts 0 (baseline 0)

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-05T22:45:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-118-endpoint-straight-snap-collapse-endpoint.md
- **Context:** Initial task creation

### 2026-07-07T14:18:06Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b18f5798
- **Timestamp:** 2026-07-27T21:20:15Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
