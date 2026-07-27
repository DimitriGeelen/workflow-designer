---
id: T-082
name: "Edge-label placement pass: measure-after-move for edge labels"
description: >
  Extend T-077 adjustLabelPlacements (node labels) to EDGE labels: candidate positions along the emptiest stretch of the polyline, real getBBox measurement, never overlap node id badges or other labels (PD-030 measure-after-move). Evidence: context-memory evaluation 2026-07-04 — 11 label-over-edge + 6 label-over-label hits, ~15/17 involve edge labels ('agent captures knowledge during work' x e_03 + 2 badges; 'learning' clipped behind gateway; '3+ applications -> graduate' x 2 badges). Corpus sweep before/after required.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-04T13:52:06Z
last_update: 2026-07-04T15:17:42Z
date_finished: 2026-07-04T15:16:23Z
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

# T-082: Edge-label placement pass: measure-after-move for edge labels

## Context

Edge labels are placed by `edgeLabelPos()` (src/aef-workflow-designer.html:3181) at the midpoint of the longest horizontal/vertical segment using ESTIMATED char widths and zero collision awareness. T-077's `adjustLabelPlacements()` post-pass (line 2029) fixed node labels with real getBBox measurement (PD-030 measure-after-move) but never touched edge labels. Operator's context-memory evaluation (2026-07-04) found ~15 of 17 label collisions involve edge labels. This task extends the measured post-pass to edge labels: candidates along the rendered polyline, scored by real getBBox against edge segments, node boxes, node label/badge texts, and already-placed edge labels; the halo rect follows the final text position.

## Acceptance Criteria

### Agent
- [x] A measured edge-label post-pass exists (`adjustEdgeLabelPlacements()` or equivalent) that runs AFTER the node-label pass, generates candidate positions along each edge's rendered polyline, scores each candidate by real getBBox against (a) all rendered edge segments, (b) node boxes, (c) node-label / id-badge / io-badge texts, (d) edge labels already placed this pass — first zero-score candidate wins, otherwise strictly-better-than-default minimum; ties keep the default placement
      Evidence: `adjustEdgeLabelPlacements()` in src/aef-workflow-designer.html (called at end of renderNodes after `adjustLabelPlacements()`); candidates = 2 distance tiers x 5 fractions per horizontal segment, lateral pair per vertical segment, longest segments first; obstacles exactly (a)-(d).
- [x] The label halo rect is repositioned from the MEASURED final text bbox (not the estimate), so rect and text never separate
      Evidence: halo rect (`data-elr`) repositioned from `box(t)` of the final placement for EVERY labeled edge, including uncontested ones — fixes PL-008 estimate drift too.
- [x] Corpus sweep with one shared browser-side measurement function, run before and after the change: total measured edge-label collisions across all corpus maps strictly decreases, and context-memory's edge-label-involved hits drop to <= 2 (from ~15); before/after counts recorded in this task's Updates
      Evidence: 141 -> 28 corpus-wide (-80%); context-memory 14 -> 2; label-over-label 7 -> 0; per-category and per-map numbers in Updates 2026-07-04.
- [x] Serialization untouched: editor XML round-trip stays byte-identical on context-memory plus 2 control maps (placement is render-only)
      Evidence: buildBpmnXml(parse(X)) === X across parse->render->build cycles (STABLE on context-memory, task-lifecycle, tier0-escalation); `git diff src/` contains 0 lines touching buildBpmnXml/parseBpmnXml/aefExtensionXml/yaml paths. (Note: bridge-emitted .bpmn was never byte-par with editor-emitted XML — the invariant is editor-XML stability, verified.)
- [x] All existing suites green: bridge tests, validator selftest + corpus validate, editor-bridge structured parity, lane-band checks; gallery copy re-synced (diff -q clean)
      Evidence: bridge 31/31, validator 34/34, all 6 editor/bridge parity tests PASS, geometry sweep 24 clean, gallery designer.html synced.

### Human
- [ ] [REVIEW] Edge labels read cleanly on the live gallery — no label sitting on top of a line, badge, or another label at the hotspots from your 2026-07-04 evaluation
  **Steps:**
  1. Open http://192.168.10.107:8834/ and view the context-memory map
  2. Check the previous hotspots: "agent captures knowledge during work" near e_03, "learning" near the gateway, "3+ applications -> graduate"
  3. Skim 2-3 other maps (task-lifecycle, git-commit-flow) for new label collisions
  **Expected:** Edge labels sit in clear space beside/above their edge; halo rect hugs the text
  **If not:** Note which map + which label; screenshot the spot

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

grep -q "function adjustEdgeLabelPlacements" src/aef-workflow-designer.html
grep -q 'data-el' src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
python3 tests/test_editor_bridge_structured_parity.py
python3 tests/test_editor_bridge_meta_parity.py
python3 tests/test_editor_bridge_field_coverage.py
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy, 0 new-fail"
test -f .playwright-mcp/t082-context-memory-zoom.png
test -f .playwright-mcp/t082-verification-gate.png

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

### 2026-07-04 — Node obstacle boxes: shape-only, not nodeVisualBottom
- **Chose:** Edge-label scorer blocks node SHAPE boxes (+2px) only; the text band below label-below nodes is covered by measured nodeTexts bboxes instead.
- **Why:** nodeVisualBottom blocks a full-node-width band 16-30px deep under every node, but the id badge inside it is narrow and centred — measured text bboxes free the usable space beside it. Switching cut residual collisions 65 -> 28.
- **Rejected:** Reusing nodeVisualBottom (as the node-label pass does) — too conservative for this pass; left labels stuck on dense maps.

### 2026-07-04 — Strict-best fallback instead of forced relocation
- **Chose:** When no zero-score candidate exists, keep the best-scoring one; keep the default when nothing beats it. Two distance tiers (hug the line / one label-height out) rather than unlimited drift.
- **Why:** A label pushed far from its edge is worse than a label with one residual overlap — attribution beats purity. The remaining 28 corpus hits are all in intrinsically over-dense corridors (verification-gate mid-chain, error-escalation ladder) where the fix is density/halo work (T-083/T-085), not more drift.
- **Rejected:** Larger candidate radii and label wrapping — wrapping is out of T-082 scope and drift breaks edge attribution.

## Visual Verification

Screenshots in .playwright-mcp/ (taken via Playwright element capture, read and inspected):
- t082-context-memory-full.png — full map after pass
- t082-context-memory-zoom.png — hotspot cluster: "agent captures knowledge during work" + "pattern (failure/success/workflow)" in clear corridor, "learning"/"decision" clean; 2 residuals visible ("3+ applications -> graduate" kisses prj_2_add badge; "framework auto-fires" clips start-event circle)
- t082-verification-gate.png — densest map (32 -> 9): periphery labels all clean, residuals confined to the over-tight mid gateway chain; no label-over-label anywhere

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T13:52:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-082-edge-label-placement-pass-measure-after-.md
- **Context:** Initial task creation

### 2026-07-04T14:33:05Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-04 — build complete: measured edge-label post-pass [agent]
- **Action:** Implemented `adjustEdgeLabelPlacements()`; tagged edge label text/halo with data-el/data-elr; synced gallery copy.
- **Sweep numbers (same measurement function, all 24 corpus maps):**
  - BEFORE: total 141 (seg 53, node 23, node-text 58, label-label 7); 17 maps with hits; worst: verification-gate 32, error-escalation-ladder 27, task-gate 16, context-memory 14
  - AFTER: total 28 (seg 9, node 13, node-text 6, label-label 0); 7 maps with hits; verification-gate 9, error-escalation-ladder 8, task-gate 5, context-memory 2
  - context-memory residuals: "3+ applications -> graduate" x prj_2_add badge, "framework auto-fires" x start-event box — both strict-best fallbacks on boxed-in short edges
- **Round-trip:** editor-XML build STABLE across parse->render->build on context-memory/task-lifecycle/tier0-escalation; 0 serialization lines in diff.
- **Gotcha:** gallery page served a CACHED designer.html after cp — first post-change sweep silently measured OLD code (identical numbers were the tell); cache-buster query string required before re-measuring.

## Recommendation

**Recommendation:** GO
**Rationale:** Corpus-wide measured edge-label collisions down 80% (141 -> 28), label-over-label eliminated, the operator's top evaluation hotspots (context-memory) reduced to 2 least-bad residuals; zero serialization or geometry impact; all suites green.
**Evidence:**
- Sweep: 141 -> 28 total; context-memory 14 -> 2; label-over-label 7 -> 0 (numbers in Updates)
- Screenshots: .playwright-mcp/t082-context-memory-{full,zoom}.png, t082-verification-gate.png (read and inspected)
- Suites: bridge 31/31, validator 34/34, editor/bridge parity 6/6, geometry sweep 24 clean

### 2026-07-04T15:16:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c2d17e1f
- **Timestamp:** 2026-07-27T21:20:10Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
