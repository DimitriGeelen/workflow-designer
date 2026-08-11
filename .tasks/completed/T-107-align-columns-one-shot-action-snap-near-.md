---
id: T-107
name: "Align columns one-shot action: snap near-aligned connected nodes to shared centre-x"
description: >
  T-092 Phase C option 7: a one-shot 'Align columns' action (mirror of the shipped align-rows T-094) that snaps near-aligned connected nodes to a shared centre-x, zeroing the ~21 column near-miss pairs (survey finding 4) and removing the hidden doglegs T-073 only masks at render time. Geometry-mutating action (undoable, PD-044: explicit-action only), wired into the Clean composite. No stored geometry mutated by any render pass.

status: work-completed
workflow_type: build
owner: human
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T18:54:24Z
last_update: 2026-07-29T15:39:17Z
date_finished: 2026-07-05T19:09:36Z
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

# T-107: Align columns one-shot action: snap near-aligned connected nodes to shared centre-x

## Context

T-092 Phase C option 7 (survey `docs/reports/T-092-routing-layout-survey.md`, finding 4:
~21 column near-miss pairs — sequential/connected nodes whose x-centres are 1–14px apart,
producing hidden doglegs that T-073's straightening only *masks* at render time). This adds
a one-shot **Align columns** action, the x-axis mirror of the shipped align-rows (T-094,
`alignRowsLane`). Key difference from rows: columns are **connectivity-based** — only nodes
linked by a near-vertical edge (endpoints' centre-x within tolerance) may be snapped to a
shared centre-x; unconnected nodes that merely share an x must NOT be forced (a horizontal
flow chain has large centre-x deltas, so its edges never qualify — the tolerance filter
selects vertical relationships automatically).

Geometry-mutating **explicit action only** (PD-044: never a render pass), undoable via the
shared `lastTidy` single-step revert, with the same measure-after-move collision revert as
align-rows. **Scope boundary:** this ships the standalone action only. It is deliberately
NOT wired into the Clean composite (`cleanLayout`) this task, because that would make the
baked corpus (T-101) no longer a Clean fixpoint and force a 24-map re-bake — exactly the
path that introduced the T-105 label-collision regression. Clean-integration + re-bake is a
separate, explicitly-deferred follow-up.

## Acceptance Criteria

### Agent
- [x] New `alignColumns()` function: union-find builds connected components from edges whose endpoints are near-x-aligned (`|cx(src) − cx(tgt)| ≤ 14`), then snaps each ≥2-node component to its members' median centre-x
- [x] Measure-after-move collision revert (mirror `alignRowsLane`): a component whose snap increases node-rect intersections reverts — verified: harvest-pipeline overlaps 0 before → 0 after
- [x] Undoable via the shared `lastTidy` — verified: harvest pair aligned (541,541) → Ctrl+Z → exact originals (544,538); `undoTidy` made axis-aware so x-records revert (y stays intact)
- [x] A one-shot "⁙ Align columns" toolbar button added beside "✨ Clean layout", reporting nodes moved
- [x] Horizontal-flow chains provably NOT collapsed: on session-handover (0 col near-misses, 0 near-x edges) `alignColumns()` moves **0** nodes. (Note: release-pipeline is NOT a pure-horizontal control — the T-092 table lists it with 3 col near-misses; it correctly moves 6 nodes fixing those, its horizontal flow having large-Δx edges that never union.)
- [x] Column near-misses measurably reduced: harvest-pipeline **5 → 0** pairs (`0 < |Δcx| ≤ 14`), moved 7 nodes
- [x] Render-only w.r.t. the shipped corpus: NOT wired into `cleanLayout`; `git diff` shows only `src/aef-workflow-designer.html` (+ gallery mirror); no `examples/**` changed
- [x] `src/aef-workflow-designer.html` byte-identical to `build/gallery/designer.html` — `diff -q` PASS
- [x] Before/after screenshots READ (`.playwright-mcp/t107-pair-before.png` vs `t107-pair-after2.png`): the "Dir exists?"→"No such dir" edge goes from a 6px dogleg to dead-straight into the node centre; horizontal flow (Resolve→gate→exists) undisturbed; no new overlap

### Human
- [x] [REVIEW] Align columns straightens vertical connected runs without disturbing horizontal flow
  **Steps:**
  1. Serve the gallery (`tools/serve-gallery.sh`) and open a map with visible column wobble (e.g. harvest-pipeline)
  2. Click "Align columns"; observe the vertically-connected nodes snap to a shared column and their connecting edges straighten
  3. Ctrl+Z and confirm it fully reverts; open release-pipeline and confirm clicking it changes nothing (already a clean horizontal flow)
  **Expected:** Vertical doglegs disappear (edges become straight); no nodes overlap; horizontal chains and lane bands unchanged; one Ctrl+Z reverts
  **If not:** Note which nodes moved wrongly or which overlap appeared

## Recommendation

**Recommendation:** GO

**Rationale:** Clean, bounded x-axis mirror of the shipped align-rows (T-094), reusing its
proven median-snap + measure-after-move + lastTidy-undo machinery. Connectivity-gated so it
only straightens genuine vertical relationships and never collapses horizontal flow.
Explicit-action only and not wired into Clean, so the baked corpus is untouched (sidesteps
the T-105 re-bake/label-collision risk). Verified end-to-end with numbers and read
screenshots.

**Evidence:**
- Code: `src/aef-workflow-designer.html` — `alignColumns()` + axis-aware `undoTidy` + "⁙ Align
  columns" toolbar button.
- harvest-pipeline: col near-misses 5 → 0 (moved 7, overlaps 0→0); session-handover: moves 0;
  release-pipeline: moves 6 (its 3 legit near-miss pairs); undo restores exact originals.
- Screenshots read: `.playwright-mcp/t107-pair-before.png` (6px dogleg) vs `t107-pair-after2.png`
  (dead-straight edge into node centre).
- Deferred (documented): wiring into the Clean composite + 24-map re-bake is a separate
  follow-up (avoids the T-105 regression path).

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

# Editor JS mirrored byte-identical into the gallery build artifact.
diff -q src/aef-workflow-designer.html build/gallery/designer.html
# Corpus untouched: this action does not re-bake or wire into Clean.
test -z "$(git diff --name-only -- 'examples/aef-processes/*.workflow.yaml' 'examples/aef-processes/rendered/*.bpmn')"

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

### 2026-07-05T18:54:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-107-align-columns-one-shot-action-snap-near-.md
- **Context:** Initial task creation

### 2026-07-05T19:09:36Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1b0bed5d
- **Timestamp:** 2026-07-29T13:13:36Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#9 (Agent)** — Before/after screenshots READ (`.playwright-mcp/t107-pair-before.png` vs `t107-pair-after2.png`): the "Dir exists?"→"No such dir" edge goes from a 6px dogleg to dead-straight into the node centre; hor
  - **AC-verify-mismatch** (narrow, heuristic) — `path=playwright-mcp/t107-pair-before.png in: Before/after screenshots READ (`.playwright-mcp/t107-pair-before.png` vs `t107-pair-after2.png`): the "Dir exists?"→"No such dir" edge goes from a 6px`
