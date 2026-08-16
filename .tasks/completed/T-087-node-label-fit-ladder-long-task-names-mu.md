---
id: T-087
name: "Node-label fit ladder: long task names must fit their rect"
description: >
  Screenshot evidence (session-handover map, frw_5_write): long node names wrap at
  14 chars but with unlimited lines and fixed 13px pitch centered on the rect — 5
  lines overflow the 64px task rect, clipped top and bottom. Apply the T-084 ladder
  to task-node labels: measured wrap to rect width -> shrink font one step -> clamp
  line count with ellipsis on the last line + full name as <title> tooltip. Render-only,
  no geometry mutation. Must be label-size-aware (T-085 S/M/L scales pitch). Operator-raised
  2026-07-04.

status: work-completed
workflow_type: build
owner: human
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-04T21:40:52Z
last_update: '2026-08-16T12:33:36Z'
date_finished: 2026-07-04T22:09:28Z
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
  - ts: '2026-08-16T12:33:36Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-087: Node-label fit ladder: long task names must fit their rect

## Context

Operator-raised 2026-07-04 (screenshot: session-handover, frw_5_write "Write handover doc + LATEST.md (Where We Are, Suggested Action)"): task labels wrap at ~14 chars with unlimited lines and fixed line pitch centered on the rect — 5 lines overflow the 64px rect, clipped top and bottom. Apply the T-084 ladder pattern to task-node labels (serviceTask/userTask/scriptTask/subProcess) as a measured post-pass: base wrap → one-step shrink (inline style per PL-009) with re-wrap → line-clamp + measured ellipsis on the last line + full name as `<title>` tooltip. Render-only; size-aware (T-085 S/M/L changes the ladder parameters).

## Acceptance Criteria

### Agent
- [x] Post-pass `fitNodeLabels()` runs after nodes are in the DOM and before the other label passes; it MEASURES rendered lines (getComputedTextLength, PL-008) and guarantees the label block fits the rect: line count within the vertical budget by construction, every line trimmed to the rect width. Corpus evidence: task-node label-overflow count (label text bbox outside rect ±2px) goes from >0 (incl. the operator-reported frw_5_write) to 0 across all 24 maps.
      Evidence: baseline 18/164 task labels overflowed at M, 62/164 at L (pre-fix gallery sweep); post-fix 0/164 at S, M and L. frw_5_write now renders 4 lines fully inside its rect with the full name as tooltip.
- [x] Ladder tiers verified reachable and honest: base wrap kept when it fits; shrink tier renders genuinely smaller text via inline style; floor tier clamps lines, ellipsizes with measured trim, and adds a `<title>` with the full name. Tier distribution reported.
      Evidence: corpus tiers at M — 122 base / 27 shrunk / 15 clamped; at L — 52 / 83 / 29; at S — 144 / 14 / 6. Zero empty label lines (a mid-build defect — width-only shrink failures produced a phantom empty line via the clamp concat — was caught by the sweep and fixed: `rest ? ... : lines`).
- [x] Size-aware: at labelPrefs.size = L the fit invariant still holds (0 task-label overflow corpus-wide); ladder parameters follow the size pref.
      Evidence: LADDER keyed by labelPrefs.size (lh 12/13/15, shrink fs 9/10/11); sweeps above at all three sizes.
- [x] Render-only: editor XML build stability x1===x2 (renderAll interleaved) on session-handover + 2 control maps; no serialization-function lines in the diff.
      Evidence: STABLE on session-handover, context-memory, verification-gate; diff touches renderNodes tail + new function only.
- [x] All suites green (bridge 31, validator 34, parity, geometry 24 clean); gallery copy synced.
      Evidence: bridge 31/31, validator 34/34, parity OK, geometry 24 clean, GALLERY-SYNCED.
- [x] Visual verification: element screenshots of the operator-reported node (session-handover frw_5_write) at size M and size L, read and inspected — text fully inside the rect, no top/bottom clipping, ellipsis only when clamped.
      Evidence: .playwright-mcp/t087-frw5-m.png (4 lines, all inside, no ellipsis needed at M), t087-frw5-l.png (shrunk 4 lines, last line "(Where We Are, Su…" ellipsized inside the rect).

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
- [x] [REVIEW] Long task names read well inside their boxes
  **Steps:**
  1. Open http://192.168.10.107:8834/ and view session-handover
  2. Look at "Write handover doc + LATEST.md (Where We Are, Suggested Action)" (frw_5_write) — previously clipped top and bottom
  3. Hover a truncated label — tooltip should show the full name
  4. In Settings, switch Label size to L and re-check the same node
  **Expected:** Text fully inside the box at M and L; ellipsis + hover tooltip where the name is clamped; nothing spills over rect borders
  **If not:** Note map + node id; screenshot the spot

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

grep -q "function fitNodeLabels" src/aef-workflow-designer.html
grep -q "fitNodeLabels();" src/aef-workflow-designer.html
grep -q "data-fitn" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305)
python3 tests/test_editor_bridge_structured_parity.py
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy, 0 new-fail"
test -f .playwright-mcp/t087-frw5-m.png
test -f .playwright-mcp/t087-frw5-l.png

## RCA

**Symptom:** Long task names ("Write handover doc + LATEST.md (Where We Are, Suggested Action)") rendered as 5+ wrapped lines overflowing the 64px task rect, clipped at both rect borders (operator screenshot, session-handover frw_5_write). 18/164 task labels affected at size M, 62/164 at L.

**Root cause:** renderNodes wrapped by char estimate with an UNLIMITED line count and fixed line pitch centered on the rect middle — no comparison of block height (lines × pitch) against rect height, and no measured width check per line.

**Why structurally allowed:** The label-fit discipline (T-084) was applied to lane headers only; no corpus invariant existed for task-rect labels, so the overflow class was invisible to every gate until a human looked at a rendered map.

**Prevention:** fitNodeLabels() enforces the fit invariant by construction on every render; the corpus sweep used here (task-label bbox vs rect ±2px at S/M/L) is recorded in this task for reuse; same sweep caught a mid-build phantom-empty-line defect before commit — measured sweeps stay the closing gate for render work (PD-030/PL-008 lineage).

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Visual Verification

Screenshots in .playwright-mcp/ (viewBox-framed element capture, read and inspected):
- t087-frw5-m.png — operator-reported node at size M: 4 lines fully inside the rect, no clipping
- t087-frw5-l.png — same node at size L: shrunk tier, last line ellipsized inside the rect, full name as tooltip

## Recommendation

**Recommendation:** GO
**Rationale:** The operator-reported clipping class is closed corpus-wide by construction: 164/164 task labels fit their rect at every label size, via the same measured-ladder pattern proven on lane headers (T-084), render-only.
**Evidence:**
- Overflow 18→0 (M), 62→0 (L), 0 at S, across 24 maps / 164 task nodes
- Tier distribution honest and reachable: M 122/27/15 (base/shrunk/clamped), L 52/83/29, S 144/14/6
- XML STABLE ×3; suites bridge 31/31, validator 34/34, parity OK, geometry 24 clean
- Screenshots of frw_5_write at M and L read and inspected

## Decisions

### 2026-07-05 — Fit post-pass over per-render fitting; one shrink step only
- **Chose:** A single post-pass (fitNodeLabels) after nodes enter the DOM, before the other label passes; ladder = base wrap → ONE shrink step → clamp+ellipsis+tooltip.
- **Why:** Measurement needs live DOM (getComputedTextLength); running before adjustLabelPlacements/adjustEdgeLabelPlacements means those passes measure the FINAL label geometry. One shrink step keeps the type scale readable — more steps would converge on unreadable text instead of admitting the name is too long (tooltip carries the truth).
- **Rejected:** Fitting inline during node render (elements not yet measurable in DOM); auto-growing rect height (document mutation from a render concern — same rejection as T-084 lane auto-grow); unlimited shrink (unreadable soup beats nothing but loses to ellipsis+tooltip).

## Updates

### 2026-07-04T21:40:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-087-node-label-fit-ladder-long-task-names-mu.md
- **Context:** Initial task creation

### 2026-07-04T22:03:12Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T22:09:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1b94bd3a
- **Timestamp:** 2026-07-29T13:13:33Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
