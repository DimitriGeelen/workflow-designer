---
id: T-084
name: "Lane-header ellipsis: truncate vertical lane names to lane height"
description: >
  Vertical lane-header text longer than the lane height overlaps neighbouring lane headers (context-memory: 'COMPLETED HISTORIES · EPISODIC MEMORY' in a 160px lane). RESHAPED 2026-07-04 per operator request (forwarded scoping message + screenshot): full label-fit ladder instead of bare ellipsis — (1) wrap on word/'·' boundaries up to 2 parallel vertical lines within the ~28px header strip; (2) if still too long, shrink font toward an 8px floor; (3) finally ellipsize with full name via <title> tooltip. On by default, config toggle to disable (extend T-075 settings page, localStorage first slice). Auto-grow-lane rejected: a render concern must not mutate document geometry. From context-memory evaluation 2026-07-04.

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
created: 2026-07-04T13:52:07Z
last_update: 2026-07-04T15:30:10Z
date_finished: 2026-07-04T15:29:26Z
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

# T-084: Lane-header ellipsis: truncate vertical lane names to lane height

## Context

Vertical lane-header names longer than the lane height bled across neighbouring lanes (25 of 67 corpus lane labels overflowed; operator case: "COMPLETED HISTORIES · EPISODIC MEMORY" in context-memory). Per the operator's scoping (forwarded message, 2026-07-04): full label-fit ladder — wrap on '·'/word into two vertical columns, then shrink toward an 8px floor, then ellipsize with a full-name tooltip; on by default with a settings toggle; auto-grow-lane rejected (render must not mutate geometry).

## Acceptance Criteria

### Agent
- [x] A `fitLaneLabel()` ladder replaces the single rotated lane label: (1) wrap on '·' (fallback word) boundaries into two parallel vertical columns, balanced split; (2) shrink font 10 -> 9 -> 8px; (3) ellipsize at the 8px floor with the full name as an SVG <title> tooltip; lengths MEASURED via getComputedTextLength, never estimated
      Evidence: `fitLaneLabel()` in src/aef-workflow-designer.html, called from renderPool with headerG already in the DOM (measurement requirement documented inline).
- [x] Corpus sweep: 0 lane labels overflow their lane (baseline 25 of 67); ladder tier usage recorded
      Evidence: browser sweep over all 24 maps — before (laneFit off): 25/67 overflow; after: 0/67 overflow; tiers used: 25 wrapped, 1 shrunk, 1 ellipsized+tooltip.
- [x] Settings toggle: "Fit lane names" checkbox in the T-075 settings dialog (Labels section), persisted in localStorage (`aefLabelPrefs`), on by default, included in Reset-to-defaults; off restores the original single-line behaviour
      Evidence: labelPrefs store + set-lane-fit checkbox + syncSettingsUI + change listener + reset handler; toggling off in the sweep reproduced the original 25 overflows, toggling back on returned to 0.
- [x] Render-only: editor XML build STABLE (buildBpmnXml(parse(X)) === X) on context-memory + 2 controls with renderAll interleaved; lane geometry untouched
      Evidence: STABLE x3; geometry sweep 24 clean.
- [x] Suites green + gallery synced
      Evidence: bridge 31/31, validator 34/34, structured/meta parity PASS, geometry sweep 24 clean, diff -q clean.
- [x] Visual verification: lane-header screenshots read and inspected — two-column wraps sit inside their lanes, correct reading order (first column left), no bleed into neighbours
      Evidence: .playwright-mcp/t084-lane-headers.png — all three context-memory lanes ("WORKING MEMORY / SESSION-LOCAL", "PROJECT MEMORY / DURABLE CROSS-TASK", "EPISODIC MEMORY / COMPLETED HISTORIES") wrap cleanly inside their bands.

### Human
- [ ] [REVIEW] Lane names read naturally in the header strip across the corpus
  **Steps:**
  1. Open http://192.168.10.107:8834/ and view context-memory — check all three lane headers wrap into two columns inside their lanes
  2. Open the editor settings (gear button) → Labels → toggle "Fit lane names" off and on; confirm the headers revert/refit live
  **Expected:** Two-column names fit their lanes, read top-to-bottom left-column-first; toggle works
  **If not:** Note map + lane; screenshot the header strip

<!-- template guidance removed; original notes:
     Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
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

grep -q "function fitLaneLabel" src/aef-workflow-designer.html
grep -q "aefLabelPrefs" src/aef-workflow-designer.html
grep -q 'set-lane-fit' src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
python3 tests/test_editor_bridge_structured_parity.py
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy, 0 new-fail"
test -f .playwright-mcp/t084-lane-headers.png

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

### 2026-07-04 — Ladder order: wrap before shrink before ellipsize
- **Chose:** Try the balanced two-column wrap at full size first; only shrink (9 -> 8px) when wrapping alone cannot fit; ellipsize only at the floor, with the full name as <title> tooltip.
- **Why:** Operator-specified priority (forwarded scoping message): keep text at readable size as long as possible; the corpus confirms it — 25 of 27 triggered lanes resolved by wrapping alone.
- **Rejected:** Auto-grow lane height (render pass mutating document geometry — breaks the render/document seam); bare ellipsis-first (destroys information the strip has room to show).

### 2026-07-04 — Column order for rotated text
- **Chose:** First wrapped line in the LEFT column (cx-6), second in the RIGHT (cx+6).
- **Why:** For rotate(-90) text the inter-line advance direction maps to +x, so left-column-first preserves natural reading order (verified by reading the rendered screenshot, not assumed).


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

## Recommendation

**Recommendation:** GO
**Rationale:** All 25 overflowing lane labels (of 67 corpus-wide) now fit their lanes via the operator-specified ladder — 25 resolved by wrapping alone, 1 needed shrink, 1 needed ellipsis+tooltip; render-only with a working default-on settings toggle; all suites green.
**Evidence:**
- Sweep: 25/67 overflow -> 0/67; tier usage wrapped 25 / shrunk 1 / ellipsized 1
- Toggle proof: laneFit off reproduces the original 25 overflows, on returns to 0
- Round-trip STABLE x3, geometry sweep 24 clean, bridge 31/31, validator 34/34
- .playwright-mcp/t084-lane-headers.png read and inspected

## Visual Verification

- .playwright-mcp/t084-lane-headers.png — context-memory header strip: all three lane names wrap into two columns inside their bands, left-column-first reading order, no bleed.

## Updates

### 2026-07-04T13:52:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-084-lane-header-ellipsis-truncate-vertical-l.md
- **Context:** Initial task creation

### 2026-07-04T14:04:24Z — status-update [task-update-agent]
- **Change:** horizon: later → next

### 2026-07-04T15:29:20Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-04T15:29:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d1a93b91
- **Timestamp:** 2026-07-27T21:20:10Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
