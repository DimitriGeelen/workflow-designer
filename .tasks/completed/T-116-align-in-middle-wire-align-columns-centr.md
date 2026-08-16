---
id: T-116
name: "Align-in-middle: wire Align-columns (centre-x) into Clean layout"
description: >
  Operator improvement A (align in middle) + B (connect on 90). cleanLayout() does
  per-lane tidy + align-rows (centre-y) but never align-columns (centre-x), so stacked
  nodes of different widths (e.g. gateway 48w over end-event 36w) keep a small centre-x
  offset -> vertical drops render as a tiny staircase jog instead of a dead-straight
  90 deg line. Fix: run alignColumns() (T-107, already snaps vertical-edge-connected
  nodes to shared centre-x, with measure-after-move overlap revert) as a final global
  step in cleanLayout, merged into the same lastTidy so one Ctrl+Z reverts. Align-rows
  (Y) and align-columns (X) are orthogonal axes and cannot fight. B (clean 90) falls
  out for free once centres align; residual horizontal-edge jogs are a separate follow-up.

status: work-completed
workflow_type: build
owner: human
horizon:
tags: [ui, editor, routing, layout]
components: []
related_tasks: [T-105, T-107, T-094, T-101]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T22:01:16Z
last_update: '2026-08-16T12:33:37Z'
date_finished: 2026-07-07T14:19:17Z
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
  - ts: '2026-08-16T12:33:37Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-116: Align-in-middle: wire Align-columns (centre-x) into Clean layout

## Context

Operator improvements A (align in middle) + B (connect on 90°), 2026-07-05.
Investigation (headless, live editor): the router already renders all edges
orthogonally (0 diagonal stubs on promotion-pipeline); what makes vertical drops
look unclean is a small staircase JOG, caused by stacked nodes of different widths
sharing a left-x but not a centre-x (gateway 48w over end-event 36w → 6px off).
`alignColumns()` (T-107) already snaps vertical-edge-connected nodes to a shared
centre-x and straightens the drop (verified: moved 4 nodes on promotion-pipeline,
near-miss centre-x pairs 2→0, drop rendered dead-straight into the end-event
centre). Gap: `cleanLayout()` does per-lane tidy + align-rows (centre-y) but never
align-columns (centre-x). Fix: compose align-columns into Clean. B's clean 90°
drops fall out for free; residual horizontal-edge jogs are a separate follow-up.

## Acceptance Criteria

### Agent
- [x] `alignColumns()` refactored into `alignColumnsMoves()` (applies centre-x
      snaps, returns before-x records, no lastTidy/render) + thin `alignColumns()`
      wrapper — one code path, standalone button unchanged (PL-005)
- [x] `cleanLayout()` calls `alignColumnsMoves()` as a final global step; the
      returned x-records are merged into Clean's single `lastTidy` so ONE Ctrl+Z
      reverts the whole Clean (rows + columns together) — verified: Clean changed 4
      nodes on promotion-pipeline, one undoTidy() fully restored originals
- [x] Corpus-wide validation: Clean+align run on all 24 maps → 0 node-cuts, 0 node
      overlaps, 0 mapMessiness, 0 residual near-miss centre-x pairs; node-cut gate
      still 0/24 PASS. Actively moved nodes on 12 maps (harvest 14, arc-lifecycle 9,
      release 6, cross-host 6, audit 5, error-esc 5, promotion/verification/review 4)
- [x] Headless proof: on promotion-pipeline, Clean zeroes the near-miss centre-x
      pairs (2→0) and the gateway→end-event drop renders as a single straight segment
- [x] Standalone "Align columns" button still works (returned moved=4, undo worked)
- [x] Editor JS synced byte-identical to build/gallery/designer.html

### Human
- [x] [REVIEW] Clean now aligns columns in the middle and drops connect at a clean 90°
  **Steps:**
  1. Reuse the running gallery on :8834 (or `tools/serve-gallery.sh`)
  2. Open promotion-pipeline; click Clean (✨) — or open any gateway-dense map
  3. Look at where branch edges drop from a gateway to an end-event / branch node below
  **Expected:** the drop is a single straight vertical line into the centre of the
  node below (no small staircase kink); the main chain sits on one centre-line
  **If not:** note the map + which drop still jogs

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
grep -q "function alignColumnsMoves" src/aef-workflow-designer.html
grep -q "positions.push(...alignColumnsMoves())" src/aef-workflow-designer.html
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

**Rationale:** All 6 Agent ACs are implemented and verified. `alignColumnsMoves()` is in
source and wired into the Clean layout move-set (`positions.push(...alignColumnsMoves())`).
No baseline risk: the corpus node-cut gate is 0/24 (0 regressed) and the mirror invariant
holds byte-identical. The one remaining AC is a Human REVIEW of whether Clean's centre-x
alignment *reads* right — subjective taste that needs the operator's eye.

**Evidence:**
- Mirror invariant: `diff -q src/aef-workflow-designer.html build/gallery/designer.html` → identical
- `grep -c "function alignColumnsMoves"` → 1 (present); `grep -c "positions.push(...alignColumnsMoves())"` → 1 (wired)
- Corpus node-cut gate: `tests/check-corpus-node-cuts.sh` → 24 unchanged, 0 regressed, total cuts 0 (baseline 0)

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-05T22:01:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-116-align-in-middle-wire-align-columns-centr.md
- **Context:** Initial task creation

### 2026-07-07T14:19:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-37547994
- **Timestamp:** 2026-07-29T13:13:37Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
