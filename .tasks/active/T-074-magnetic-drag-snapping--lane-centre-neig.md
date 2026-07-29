---
id: T-074
name: "Magnetic drag snapping — lane centre, neighbour centres, grid, with guide lines"
description: >
  Operator-approved: while dragging a node, snap to lane centre-y, connected/nearby node centre-x/y, and a configurable grid; show brief guide lines. Snap is a magnet not a law (multi-row lanes stay possible). Updates stored positions (authoring-time).

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
created: 2026-07-04T09:43:58Z
last_update: 2026-07-04T10:13:48Z
date_finished: 2026-07-04T10:13:16Z
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

# T-074: Magnetic drag snapping — lane centre, neighbour centres, grid, with guide lines

## Context

Second piece of the operator-approved routing calmness v3 scope: T-073 straightens
near-misses at render time; this task prevents the misses at AUTHORING time. While
dragging a node with real mouse input, its centre is magnetically attracted to
(a) the horizontal centre-line of the lane it is in (y), (b) centre-x/centre-y of
connected and nearby nodes, and (c) an optional configurable grid. Brief guide
lines show what the node is snapping to. The magnet must be escapable (small
radius) so multi-row lanes and deliberate offsets stay possible. Unlike T-073,
this DOES update stored node positions — that is the point: the human is placing.
Snap preferences are editor-local (localStorage, PD-017 pattern), never document
data.

## Acceptance Criteria

### Agent
- [x] While dragging a single node, its centre snaps to: lane centre-y (verified: n_classify dropped 5px off lane centre landed delta 0); centre-x/y of connected nodes (n_resume→n_resolve delta 0) and unconnected nodes within 400px; and grid multiples when enabled (landed exactly 560/440 from a 553/447 drop). Magnet candidates take priority over grid on the same axis.
- [x] Magnet engages within SNAP_TOL (7 model px) and releases beyond it — trusted-input drag to 30px off the candidate axis landed at 29.3px (un-snapped). Grid, by contrast, quantizes unconditionally while its toggle is on (see Decisions — toleranced grid leaves dead zones).
- [x] While a snap is engaged a guide line renders along the snapped axis (g-preview children=1 mid-drag, screenshot t074-guide-during-drag.png READ and confirmed); 0 children after mouseup — no guide artifacts survive the drag.
- [x] Snapping updates the stored position: dropped node's centre-y equals the connected candidate's exactly (deltaY=0) and e_09 renders straight by exact alignment, not via T-073 tolerance.
- [x] Prefs live in localStorage `aefSnapPrefs` ({"magnet":true,"grid":false,"gridSize":20} confirmed); exported BPMN XML matches /snap/i nowhere. Defaults: magnet on, grid off, size 20.
- [x] Group drags and edge-endpoint drags unaffected: magneticSnap is called only in the single-node `drag` branch of the mousemove handler; the groupDrag block and the endpoint SNAP_RADIUS logic (T-070) are untouched by this diff.
- [x] Editor JS passes `node --check`; bridge suite 31 passed 0 failed; gallery copy refreshed.

### Human
- [ ] [REVIEW] Snapping feels helpful, not sticky
  **Steps:**
  1. Open http://192.168.10.107:8834/designer.html?load=rendered/healing-loop.bpmn
  2. Drag a task slowly near another task's row — watch for the guide line and the gentle pull
  3. Keep dragging past it — the node should release without fighting you
  4. Drop a node on a neighbour's centre line, check the connecting line is dead straight
  **Expected:** Guide lines appear/disappear cleanly; snap helps placement; you can always place off-grid/off-axis by moving a bit further
  **If not:** Note which drag felt wrong (too sticky / too weak / guide flicker) and report back

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

## Recommendation

**Recommendation:** GO
**Rationale:** All seven Agent ACs verified, every interaction claim via trusted input (page.mouse, PL-006) with exact-value assertions. The feature is authoring-time only, prefs are editor-local (PD-017 pattern), and the export was proven free of snap artifacts — no document-format or bridge-seam exposure (31/31). A first-implementation grid dead-zone bug was caught BY the trusted-input verification and fixed before completion. Remaining open item is the Human [REVIEW] AC on drag feel.
**Evidence:**
- Connected-centre snap: drop 5px off → deltaY exactly 0, edge straight by exact alignment
- Escape: drop 30px off → landed 29.3px (magnet released); lane centre snap delta 0
- Grid: 553/447 drop → 560/440 exact multiples (after dead-zone fix, see Decisions)
- Guides: 1 line mid-drag (screenshot read), 0 DOM children after mouseup
- Export: /snap/i matches nothing in buildBpmnXml output; prefs confirmed in localStorage aefSnapPrefs
- Gates: node --check clean, bridge 31 passed 0 failed, gallery copy identical

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

awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/t074-check.js && node --check /tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad/t074-check.js
grep -q "aefSnapPrefs" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"  # count-agnostic (T-305: suite grew 31->43; totals rot)

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

### 2026-07-04 — Grid quantizes unconditionally; magnet is toleranced
- **Chose:** Magnet candidates (lane/node centres) engage within SNAP_TOL=7px and release beyond; the grid, while its toggle is on, rounds every unclaimed axis to the nearest multiple with no tolerance.
- **Why:** Trusted-input testing exposed dead zones in a toleranced grid: with cell 20 and tol 7, proposals 7–10px from a multiple snapped to nothing — the grid felt "sometimes broken" (first implementation failed exactly this way at 553/447 → 7.02/7.54 from the nearest multiples). A grid is an explicit opt-in; escaping it means toggling it off, not out-dragging it.
- **Rejected:** Toleranced grid (dead zones); tolerance = gridSize/2 (that IS unconditional rounding, stated confusingly).

### 2026-07-04 — Snap in centre coordinates, single-node drags only
- **Chose:** magneticSnap operates on the dragged node's centre and is wired only into the single-node drag branch; group drags stay rigid, endpoint drags keep T-070's port snapping.
- **Why:** Centre alignment is what makes edges straight (the user's stated goal); snapping individual members of a group drag would distort the group's internal geometry mid-move.
- **Rejected:** Snapping group drags by leader node (surprising for the non-leader members); snapping node top-left (aligns nothing visible).

### 2026-07-04 — Candidate scope
- **Chose:** Connected nodes attract at any distance; unconnected nodes only within 400px; guides drawn between the aligned centres (lane guides span the pool).
- **Why:** Connected-node alignment is the high-value case regardless of distance (long straight flows); far-away unconnected nodes create invisible-cause snapping.
- **Rejected:** All nodes at any distance (mystery magnets); connected-only (misses row alignment of parallel branches).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-04T09:43:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-074-magnetic-drag-snapping--lane-centre-neig.md
- **Context:** Initial task creation

### 2026-07-04T10:07:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T10:13:16Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ff2a9820
- **Timestamp:** 2026-07-29T13:13:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
