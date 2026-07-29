---
id: T-109
name: "Distribute evenly action equalise horizontal row gaps"
description: >
  Distribute evenly action equalise horizontal row gaps

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
created: 2026-07-05T19:43:08Z
last_update: 2026-07-05T19:50:29Z
date_finished: 2026-07-05T19:49:55Z
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

# T-109: Distribute evenly action equalise horizontal row gaps

## Context

Phase C option 8 from the T-092 routing/layout survey (`docs/reports/T-092-routing-layout-survey.md`):
"Distribute evenly — equalise gaps in a row / stack." The remaining Phase C options
are 4 (row-alignment-mode) and 5 (structural-straightening) — both modify Tidy's
core behaviour (higher regression risk, overlap with the align-rows/align-columns
actions already shipped as T-094/T-107). This task takes option 8's **horizontal**
case only: a standalone one-shot toolbar action that, for each lane row of ≥3
row-mates, equalises the horizontal gaps between them (keeping the leftmost and
rightmost anchored), zeroing uneven chain rhythm.

The **vertical** case of option 8 (equalise gaps in a fan-out stack) is deliberately
out of scope: it is already served by Branch pitch (T-093) and Vertical spacing
(T-108, `respaceRows`). Distributing horizontally is the novel, non-redundant part.

Follows the proven collision-safe/undoable pattern of Align rows (T-094) and Align
columns (T-107): cluster → measure-after-move revert on collision → record moved
node-x's into the shared axis-aware `lastTidy` (T-107) so one Ctrl+Z reverts.
Explicit-action only — NOT a render pass, never mutates `examples/**` (PD-044).

## Acceptance Criteria

### Agent
- [x] New `distributeEvenly()` function + toolbar button that, per lane, clusters nodes into rows by centre-y (same band as align-rows) and for each row of ≥3 nodes equalises the horizontal edge-to-edge gaps, keeping the leftmost and rightmost node fixed (classic "distribute horizontal spacing")
  → `distributeEvenly()` added after `alignColumns`; `#btn-distribute` toolbar button ("↔ Distribute evenly") + handler after btn-align-cols. Uses `ROW_SPACING_BAND` (28px) for row clustering.
- [x] Only redistributes rows whose gaps are currently **uneven** (gap spread beyond a small tolerance) and whose even-gap is ≥ 0 (nodes fit the span); rows already evenly spaced or too tight are left untouched
  → `EVEN_TOL = 2px` skip-if-even guard; `evenGap < 0` skip-if-too-tight guard. Verified: 2nd consecutive run on an evened map moves **0** nodes (idempotent).
- [x] Collision-safe: measure-after-move — if the redistribution introduces a node overlap the row reverts (mirrors align-rows/align-columns)
  → `collisions() > collBefore` reverts the row. (No revert triggered in tests since redistributing within an unchanged span with non-negative gaps can't add overlap — guard is belt-and-suspenders.)
- [x] Undoable in one Ctrl+Z: moved node-x's recorded into `lastTidy` (`{laneId:null, positions:[{id,x}], laneHeight:null}`); `undoTidy` already restores x (axis-aware since T-107)
  → Verified: one `undoTidy()` reverted evened `[52,52,52]` → perturbed `[8,8,140]`, `lastTidy` cleared.
- [x] Explicit-action only — NOT invoked by any render pass or pref change; never mutates `examples/**` (PD-044); not wired into `cleanLayout` this task
  → only `#btn-distribute` onclick calls it; grep confirms no render-pass/`cleanLayout` reference. `examples/**` untouched.
- [x] Verified on a chain-bearing map: a row with uneven gaps becomes evenly spaced (gap variance → ~0), extremes unmoved, measured before/after; a control map with already-even rows moves 0 nodes
  → error-escalation-ladder framework top row (start→set-status→gateway→DOCTRINE-A), perturbed to gaps `[8,8,140]` (spread 132) → `distributeEvenly()` → `[52,52,52]` (spread 0). Leftmost x 90→90 and rightmost right-edge 550→550 **unchanged**. "Already-even" proven by idempotent 2nd run = 0 moves.
- [x] Before/after screenshots READ showing the row rhythm evened out, no overlaps introduced (operator's standing "take more screenshots" guidance)
  → `t109-baseline.png`, `t109-uneven.png`, `t109-evened.png`, `t109-toolbar.png` READ — gateway visibly moves from bunched-left to even mid-row, extremes fixed, edges reroute cleanly, no overlap.
- [x] `src/aef-workflow-designer.html` byte-identical to `build/gallery/designer.html`; extracted JS passes `node --check`
  → `cmp` identical; `node --check` OK.

### Human
- [ ] [REVIEW] The Distribute evenly button visibly evens out uneven horizontal spacing without breaking layout
  **Steps:**
  1. Serve the gallery; open a map with a multi-node row (e.g. task-lifecycle or error-escalation-ladder)
  2. Click the "Distribute evenly" toolbar button
  3. Observe the row spacing; press Ctrl+Z
  **Expected:** Row-mates become evenly spaced (equal gaps), leftmost/rightmost stay put, no nodes overlap; Ctrl+Z restores the prior spacing in one step
  **If not:** Note which row still looks uneven or which node jumped/overlapped

## Verification

cmp -s src/aef-workflow-designer.html build/gallery/designer.html
grep -q "function distributeEvenly" src/aef-workflow-designer.html
grep -q "btn-distribute" src/aef-workflow-designer.html

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

### 2026-07-05 — Horizontal-only; opt 8 over opt 4/5
- **Chose:** Implement option 8 (distribute evenly) as a standalone **horizontal** one-shot action; leave options 4 (row-alignment-mode) and 5 (structural-straightening) for later.
- **Why:** Opts 4 and 5 both modify Tidy's *core* behaviour (regression risk across the 24-map corpus, and functional overlap with the align-rows/align-columns actions already shipped as T-094/T-107). Opt 8 as a standalone action is self-contained, collision-safe by construction, and fully screenshot-verifiable — the best value/risk ratio of the remaining Phase C set. Horizontal-only because the *vertical* case (equalise a fan-out stack) is already served by Branch pitch (T-093) and Vertical spacing (T-108, `respaceRows`) — building it again would duplicate logic.
- **Rejected:** Opt 4/5 now (higher risk, deferred). A vertical distribute (redundant with T-093/T-108). A selection-based distribute (inconsistent with the global align-rows/-columns actions, which operate on all lanes).

### 2026-07-05 — Redistribute within the existing span (anchor extremes)
- **Chose:** Keep the leftmost and rightmost node fixed; equalise only the interior gaps within the unchanged span.
- **Why:** Anchoring the extremes means the row's overall footprint never changes, so the action can't push a row into its neighbours or grow the pool — and because interior nodes keep their left-to-right order inside a span that already held them at non-negative gaps, no *new* overlap can arise (the measure-after-move guard is then just insurance). This mirrors the classic "distribute horizontal spacing" of design tools and matches operator intuition.
- **Rejected:** Distributing to a fixed absolute gap (would change the span → risk collisions with neighbours, and is really a re-space, not a distribute).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Visual Verification

Headless (Playwright MCP, gallery :8834), all READ with the Read tool:

| Screenshot | Shows |
|---|---|
| `t109-baseline.png` | error-escalation-ladder as loaded |
| `t109-uneven.png` | framework top row perturbed to gaps `[8,8,140]` (gateway bunched left) |
| `t109-evened.png` | after Distribute evenly → gaps `[52,52,52]`, gateway spread to mid-row, start & DOCTRINE-A extremes unmoved, edges rerouted, no overlap |
| `t109-toolbar.png` | the "↔ Distribute evenly" toolbar button |

Numeric: spread 132→0; leftmost x 90→90, rightmost right-edge 550→550; 2nd run 0 moves (even-guard); one Ctrl+Z reverts `[52,52,52]`→`[8,8,140]`.

## Recommendation

**Recommendation:** GO — ship.

**Rationale:** Completes the align/distribute action family (Align rows T-094 = y-snap, Align columns T-107 = x-snap, Vertical spacing T-108 = y-pitch, and now Distribute evenly = x-gap) with the lowest-risk remaining Phase C option. The action is collision-safe by construction (redistributes within an unchanged span, extremes anchored), undoable in one Ctrl+Z on the shared axis-aware `lastTidy`, and explicit-action only — no render pass or pref touches it, `examples/**` untouched (PD-044). Verified end-to-end on error-escalation-ladder: a row perturbed to a ragged `[8,8,140]` snapped to a perfect `[52,52,52]` with extremes fixed, and a second run correctly did nothing.

**Evidence:**
- Uneven→even: gaps `[8,8,140]` (spread 132) → `[52,52,52]` (spread 0); extremes anchored (x 90→90, right-edge 550→550). Screenshots `t109-uneven.png`/`t109-evened.png` READ.
- Even-guard/idempotent: 2nd consecutive run moved 0 nodes.
- Undo: one `undoTidy()` reverted to `[8,8,140]`, `lastTidy` cleared.
- Toolbar button click → "↔ Distributed 3 nodes — Ctrl+Z reverts".
- `cmp` src == build/gallery; extracted JS passes `node --check`; verification gate 3/3.

**Suggested operator check:** open a chain-bearing map, drag one node in a 3+ row off-rhythm, click **↔ Distribute evenly**, confirm the row's gaps equalise and Ctrl+Z restores.

## Updates

### 2026-07-05T19:43:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-109-distribute-evenly-action-equalise-horizo.md
- **Context:** Initial task creation

### 2026-07-05T19:49:55Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a6c7fec7
- **Timestamp:** 2026-07-29T13:13:36Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
