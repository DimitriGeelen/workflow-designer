---
id: T-115
name: "Horizontal spacing control (mirror of Vertical spacing)"
description: >
  Add a Horizontal spacing settings control that re-spaces pool-wide stage columns to an absolute inter-column gap, mirroring the Vertical spacing control (respaceRows/T-108) on the x-axis. Motivated by T-105: gateway/label crowding is fundamentally a horizontal-room problem; the operator needs a lever to spread columns. respaceColumns clusters all nodes into columns by centre-x, shifts each column rigidly so consecutive column centres sit gap px apart (anchored left), clamped 130-360 (>widest node 120 so columns never fold), undoable via axis-aware lastTidy.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: [ui, editor, routing, layout]
components: []
related_tasks: [T-105, T-108]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T21:53:54Z
last_update: 2026-07-29T15:39:20Z
date_finished: 2026-07-06T18:42:02Z
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

# T-115: Horizontal spacing control (mirror of Vertical spacing)

## Context

Operator request (2026-07-05): "add horizontal spacing same as vertical spacing."
The editor has a Vertical spacing control (T-108, `respaceRows`) that re-spaces each
lane's rows to an absolute inter-row gap. This adds the x-axis mirror: a Horizontal
spacing control (`respaceColumns`) that re-spaces pool-wide stage columns to an
absolute inter-column gap. Motivated by T-105 (gateway/label crowding is a
horizontal-room problem) — this gives the operator the lever to spread columns.

## Acceptance Criteria

### Agent
- [x] `respaceColumns(gap)` added: clusters all nodes into columns by centre-x
      (band 48px), shifts each column rigidly on x so consecutive column centres
      sit `gap` px apart, anchored on the leftmost column; clamp 130–360 (>widest
      node 120px so columns never fold — monotonic, mirrors respaceRows)
- [x] Global (pool-wide) clustering, NOT per-lane: a stage's nodes span lanes and
      must advance together at a handoff or the lanes shear apart
- [x] Undoable via the shared axis-aware `lastTidy` (records moved node-xs; one
      Ctrl+Z reverts) — no render pass or load mutates geometry (PD-044)
- [x] Settings UI row "Horizontal spacing" (number input 130–360 step 10) wired:
      value persisted in viewPrefs.colSpacing, change fires respaceColumns live,
      reset restores 150
- [x] Verified headless (`tools/_horizontal-spacing-verify-cdp.mjs`, 6/6): on
      verification-gate, respaceColumns(150) moves nodes and makes every consecutive
      column-centre gap exactly 150px (200px via the Settings input), preserving column
      count (no fold); one undo() restores every node-x exactly (maxDelta 0); the wired
      `#set-col-spacing` change event drives the same re-spacing live.
- [x] Editor JS synced byte-identical to build/gallery/designer.html

### Human
- [x] [REVIEW] Horizontal spacing control feels right and produces tidy layouts
  **Steps:**
  1. `cd /opt/832-Workflow-designer && tools/serve-gallery.sh` (or reuse the running :8834)
  2. Open a dense map (e.g. verification-gate, promotion-pipeline), open Settings
  3. Change "Horizontal spacing" up and down; observe columns spread/tighten
  4. Press Ctrl+Z after a change
  **Expected:** Columns re-space uniformly, lanes stay aligned at handoffs (no shear),
  one Ctrl+Z fully reverts
  **If not:** Note the map and the value where it looked wrong

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
grep -q "function respaceColumns" src/aef-workflow-designer.html
grep -q "set-col-spacing" src/aef-workflow-designer.html

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

## Recommendation

**Recommendation:** GO (accept the fix; one Human REVIEW AC remains for live confirmation)

**Rationale:** `respaceColumns` is a faithful x-axis mirror of the shipped `respaceRows`
(same clustering-by-centre, rigid-group shift, clamp, and shared axis-aware `lastTidy`
undo). Global (pool-wide) clustering keeps lanes from shearing at handoffs. The behaviour
is verified empirically, not just by a checked box — the headless verifier proves the core
contract (uniform column gaps at the requested value) and exact undo restoration.

**Evidence:**
- `tools/_horizontal-spacing-verify-cdp.mjs` — 6/6 green on verification-gate:
  `column-gaps-equal-target` (all gaps = 150), `undo-restores-all-xs` (maxDelta 0),
  `settings-input-drives-respace` (200px via `#set-col-spacing` change event),
  `column-count-preserved` (no fold), `clean-load-empty-undo-stack`.
- P-011 grep gates pass (`respaceColumns`, `set-col-spacing` present); mirror `diff -q` clean.
- Screenshot `/tmp/horizontal-spacing-full.png` READ — columns evenly spread, lanes intact,
  no visual regression.

**Human review note:** confirm in a live map that the Horizontal spacing control spreads/
tightens columns uniformly with no lane shear, and one Ctrl+Z reverts. Requires one hard
refresh (Ctrl+Shift+R) to pick up the build.

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

### 2026-07-05T21:53:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-115-horizontal-spacing-control-mirror-of-ver.md
- **Context:** Initial task creation

### 2026-07-06T18:42:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-db5ad7b8
- **Timestamp:** 2026-07-29T13:13:37Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#5 (Agent)** — Verified headless (`tools/_horizontal-spacing-verify-cdp.mjs`, 6/6): on
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_horizontal-spacing-verify-cdp.mjs in: Verified headless (`tools/_horizontal-spacing-verify-cdp.mjs`, 6/6): on`
