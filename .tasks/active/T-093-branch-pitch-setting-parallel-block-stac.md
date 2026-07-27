---
id: T-093
name: "Branch pitch setting: parallel-block stack spacing (auto/compact/roomy) applied by Tidy"
description: >
  T-092 GO Phase A option 1: fan-out/join branch stacks currently overlap their own nodes (pitch < 64px node height; audit-process 5-branch, harvest-pipeline 6-branch stacks). Add a branch-pitch preference (auto >= node height + 12px / compact / roomy) to editor settings, consumed by Tidy when laying out parallel blocks.

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
created: 2026-07-04T23:21:25Z
last_update: 2026-07-04T23:36:08Z
date_finished: 2026-07-04T23:34:37Z
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

# T-093: Branch pitch setting: parallel-block stack spacing (auto/compact/roomy) applied by Tidy

## Context

T-092 GO, Phase A option 1 (docs/reports/T-092-routing-layout-survey.md, Finding 1): fan-out branch stacks overlap their own nodes — the yaml-to-bpmn generator stacks 5-6 branch tasks at a pitch smaller than the 64px task height (audit-process, harvest-pipeline, read in t092 screenshots), and Tidy (tidyLane, T-079) only snaps to lane row lines, with no parallel-block awareness. Add a branch-pitch preference consumed by Tidy.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `viewPrefs` gains `branchPitch: 'auto' | 'compact' | 'roomy'` (default `auto`), persisted in localStorage `aefViewPrefs` (T-085 discipline: editor-local render/tidy pref, never serialized into the BPMN document)
- [x] Settings modal View section gains a "Branch pitch" select wired via `setViewPref('branchPitch', ...)`, restored on modal open like `set-density` (also included in Reset-to-defaults)
- [x] `tidyLane` gains a branch-stack pass: groups of >=2 same-lane nodes in one column fed by a common multi-out predecessor are respaced vertically at pitch = tallest member height + gap (auto 12px / compact 6px / roomy 28px), order preserved, centred on the stack's previous centroid; lane height grows when the respaced stack no longer fits; `undoTidy` restores node ys AND any grown lane heights in one step (Playwright-verified per lane on audit-process: restored=true for both changed lanes)
- [x] Measured on the corpus (24-map Playwright sweep): the survey's "overlap" was touching/cramped stacks — strict rect-intersections were already 0 pre-Tidy, min stack GAP was the defect. After Tidy with `auto`: audit-process gap 0px→12px, arc-lifecycle 6→12, inception-lifecycle 8→12; already-roomy stacks untouched (guard: only stacks below target pitch are respaced). Post-Tidy rect-overlaps corpus-wide: old Tidy 5, new Tidy 1 — no map worse, 4 maps strictly better; the residual 1 (inception-lifecycle n_end_go|n_end_ng) is the pre-existing row-snap class, improved from 2 by this change
- [x] Suites green + XML stable: bridge "31 passed, 0 failed", validator "34 passed, 0 failed", parity "OK:", geometry "24 clean"; per-map check in sweep: buildBpmnXml(state) byte-identical before/after toggling branchPitch pref without Tidy (xmlStable=true across all 24 — PD-044)
- [x] Gallery synced: `diff -q src/aef-workflow-designer.html build/gallery/designer.html`

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

- [x] [REVIEW] Branch stacks read cleanly after Tidy at the default pitch
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/audit-process.bpmn
  2. Click the "agent" lane header, then Tidy in the lane properties panel
  3. Look at the 5-branch stack mid-canvas; repeat for harvest-pipeline
  **Expected:** Stacked branch tasks no longer touch/overlap — clear gaps between all boxes; nothing else moved unexpectedly
  **If not:** Note which map/stack still overlaps and screenshot it

## Visual Verification

<!-- Element-level screenshots read with the Read tool before completion (CLAUDE.md §Visual Verification). -->

- `.playwright-mcp/t093-audit-tidy-auto.png` — audit-process after Tidy (auto): all 5 branch tasks separated with clear gaps (were touching in t092-audit-process.png); READ and confirmed
- `.playwright-mcp/t093-harvest-tidy-auto.png` — harvest-pipeline after Tidy: 6-branch harvest stack evenly gapped, rest of map intact; READ and confirmed
- `.playwright-mcp/t093-settings-branch-pitch.png` — settings modal, View section: "Branch pitch" select (auto) with hint text, below Density; READ and confirmed

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

out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean"
out=$(python3 tests/test_editor_bridge_structured_parity.py 2>&1); echo "$out" | grep -q "OK:"
grep -q "set-branch-pitch" src/aef-workflow-designer.html
grep -q "branchPitch" src/aef-workflow-designer.html
grep -q "branchStacksInLane" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
test -f .playwright-mcp/t093-audit-tidy-auto.png
test -f .playwright-mcp/t093-settings-branch-pitch.png

## Recommendation

**Recommendation:** GO

**Rationale:** Phase A option 1 delivered as scoped: cramped fan-out stacks now respace to the configured pitch under Tidy, spread stacks and stored geometry are untouched, and the corpus shows strict improvement over the old Tidy with zero regressions.

**Evidence:**
- 24-map Playwright sweep: post-Tidy rect-overlaps 5 (old Tidy) → 1 (new), no map worse, 4 better; cramped stack gaps 0/6/8px → 12px (auto)
- PD-044 holds: buildBpmnXml byte-identical across pref toggles without Tidy on all 24 maps
- Suites: bridge 31/31, validator 34/34, parity OK, geometry 24 clean; per-lane undo restores ys + lane height (Playwright-verified)
- Screenshots read: .playwright-mcp/t093-{audit-tidy-auto,harvest-tidy-auto,settings-branch-pitch}.png

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

### 2026-07-05 — Respace cramped stacks only, with measure-after-move revert
- **Chose:** The branch pass acts only on stacks whose current min centre-pitch is below the target, and reverts any stack whose respace increases member/non-member collisions (PD-030 discipline).
- **Why:** First implementation respaced ALL stacks unconditionally — the corpus sweep caught it planting tier0-escalation's n_consume/n_block onto n_check_approval, which deliberately sits between them (spread stacks often straddle chain nodes). Cramped-only + revert guard: 0 maps worse than old Tidy, 4 better (post-Tidy overlaps 5→1 corpus-wide), cramped gaps 0-8px→12px.
- **Rejected:** Unconditional respace (measured regression above); collision-aware re-search of alternative stack positions (Phase B/C territory — the corridor options 2/10 address the same geometry with more machinery).

### 2026-07-05 — Stack members excluded from row snap
- **Chose:** Nodes claimed by a branch stack skip the T-079 row-snap pass entirely; the stack's own pitch logic owns their y.
- **Why:** Row-snapping 5-6 stack members onto ~2 lane row lines is exactly what piles them onto each other (old Tidy created overlaps on audit-process, harvest-pipeline, error-escalation-ladder, inception-lifecycle; all gone under the new pass).
- **Rejected:** Row-snap then respace (double movement, jitter, and the row snap contributes nothing the pitch pass keeps).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T23:21:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-093-branch-pitch-setting-parallel-block-stac.md
- **Context:** Initial task creation

### 2026-07-04T23:21:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T23:34:37Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-769e6e66
- **Timestamp:** 2026-07-27T21:20:11Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
