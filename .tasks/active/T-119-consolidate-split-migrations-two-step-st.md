---
id: T-119
name: "Consolidate split migrations: two-step staircase edges to a single clean Z"
description: >
  Routing optimisation (improvement B, migrating-edge case). Headless census (2026-07-06): 22 edges across 13 corpus maps render a small node-centre migration as a TWO-step staircase (V-H-V-H-V or H-V-H-V-H with two same-direction small steps <=16px separated by a long perpendicular run) instead of a single clean Z. Extend simplifyRoutedPolyline (T-117/T-118) with consolidateStaircase: detect the 6-point same-sign small-step pattern, build shift-early and shift-late single-Z candidates, accept the first whose polylineCrossesNodes does not increase. Prototype (render-only, no source change): all 22 consolidate, node-cuts stay 0, total edge-edge crossings unchanged 9->9, 0 maps worsened; the one node-crossing-unsafe case (verification-gate e_04) is salvaged by the shift-late candidate. Render-only, stored geometry untouched (PD-044).

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [ui, editor, routing, layout]
components: []
related_tasks: [T-118, T-117, T-116]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T22:59:33Z
last_update: 2026-07-05T23:03:52Z
date_finished: null
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

# T-119: Consolidate split migrations: two-step staircase edges to a single clean Z

## Context

Routing optimisation — improvement B ("connect on 90° for clean connection") for the
migrating-edge case. When two connected nodes' centres differ by a small amount, the
orthogonal router splits the offset across the departure stub and the arrival stub,
rendering a TWO-step staircase (V-H-V-H-V or H-V-H-V-H: two same-direction small steps
≤16px separated by a long perpendicular run) instead of a single clean Z (sidestep once,
then straight). Headless census after T-118 (2026-07-06): **22 edges across 13 maps**
render this way — it's a common router output, not a one-off.

Prototype (render-only, no source change) with shift-early/shift-late candidate + the
T-117 crossing guard: all 22 consolidate to a single Z; node-cut gate stays 0; total
edge-edge crossings unchanged 9→9; 0 maps worsened. The one node-crossing-unsafe case
(verification-gate e_04, shift-early would clip a node) is salvaged by the shift-late
candidate. Fix: extend `simplifyRoutedPolyline` with a `consolidateStaircase` post-pass.

## Acceptance Criteria

### Agent
- [x] `consolidateStaircase(pts, src, tgt, baseCuts)` added: detects a 6-point (post-
      collapse) V-H-V-H-V or H-V-H-V-H polyline whose two minor-axis steps are the SAME
      sign and each ≤ `MERGE_MAX` (16px), builds a shift-early and a shift-late single-Z
      candidate, and returns the first whose `polylineCrossesNodes` ≤ baseCuts (else the
      original) — same self-validating guard as T-117/T-118 (PL-005)
- [x] Same-sign + ≤MERGE_MAX guard excludes real detours/S-bends (opposite-sign steps)
      and large intentional offsets — only small monotonic migrations consolidate
- [x] Wired into `simplifyRoutedPolyline` AFTER the interior de-jog loop and BEFORE the
      endpoint straight-snap; applied to the transient polyline feeding BOTH the drawn
      `d` string and `edge._renderedPolyline`; stored geometry untouched (PD-044)
- [x] Corpus-wide headless proof: 22 staircase edges render as a single Z (0 residual);
      node-cut gate 0/24 PASS (0 regressed); total edge-edge crossings unchanged (9→9,
      0 maps worsened); bridge 31/31, geometry 24 clean
- [x] verification-gate e_04 specifically verified: consolidated to a single Z
      "309,164 309,407 301,407 301,437" via the shift-LATE candidate (shift-early would
      clip a node and is correctly rejected by the crossing guard)
- [x] Before/after element-level screenshots READ for 2 cases: release e_15 (vertical
      migration → single-Z drop into Create GitHub Release) and audit-process
      e_discovery_join (horizontal → one sidestep into the join) —
      `t119-release-e15-after.png`, `t119-audit-discoveryjoin-after.png`
- [x] Editor JS synced byte-identical to build/gallery/designer.html

### Human
- [ ] [REVIEW] Small node-offset connectors read as one clean Z, not a double staircase
  **Steps:**
  1. Reuse the gallery on :8834; open release-pipeline and audit-process
  2. Look at connectors between nodes whose centres are slightly offset (e.g. the
     gh-release gateway→task drop; the discovery→join handoff)
  **Expected:** each is a single sidestep then a straight run — no two-step staircase
  **If not:** note the map + edge that still shows two steps

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
grep -q "function consolidateStaircase" src/aef-workflow-designer.html
grep -q "consolidateStaircase(pts" src/aef-workflow-designer.html
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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-05T22:59:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-119-consolidate-split-migrations-two-step-st.md
- **Context:** Initial task creation
