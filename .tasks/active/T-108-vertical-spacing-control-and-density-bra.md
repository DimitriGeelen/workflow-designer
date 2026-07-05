---
id: T-108
name: "Vertical spacing control and density-branch-pitch effectiveness"
description: >
  Operator report: Density and Branch-pitch settings appear ineffective; add a working vertical-spacing control and decide their fate. See task body.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T19:13:16Z
last_update: 2026-07-05T19:13:16Z
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

# T-108: Vertical spacing control and density-branch-pitch effectiveness

## Context

Operator field report (2026-07-05): Density (tight/normal/wide) and Branch-pitch
(auto/compact/roomy) settings "seem not to be working" and were floated for deletion; the
operator wants a vertical-spacing setting that *visibly* works. Operator approved the plan
below ("yes proceed as suggested").

**Investigation this session (evidence):**
- Density IS wired (T-104 live-apply re-runs Clean on change) and moves some node-y's, so it
  is not dead — but switching tight↔wide on task-lifecycle is **visually near-identical**
  (screenshots `.playwright-mcp/density-tight.png` vs `density-wide.png`, READ).
- Measured total vertical spread is **non-monotonic / inverted**: tight 547 > normal 530 >
  wide 490 — "wide" produces *less* spacing than "tight".
- **Root cause:** density only tunes Clean's *row-snap threshold*; it never re-spaces rows to
  an absolute inter-row pitch and never grows lane heights. On an already-tidy (baked, T-101)
  map, re-running Clean at a new density barely relocates nodes → reads as "not working".
  Consistent with existing learning **PL-011** (settings that only affect FUTURE actions).

**Approved plan:**
1. Build a **"Vertical spacing"** control that re-spaces each lane's rows to a chosen
   absolute inter-row gap AND grows lane height to fit — applied live (PL-012), undoable
   (shared `lastTidy`, now axis-aware after T-107). This is the thing the operator asked for.
2. Once it works, **remove the misleading Density preset** (redundant with the new control).
3. **Keep Branch-pitch only if it visibly works** on a fan-out map (untested; likely fine —
   T-093 spaces stacks directly, unlike density). Verify with a screenshot before deciding;
   if it too is inert, remove it.

## Acceptance Criteria

### Agent
- [ ] New "Vertical spacing" control (numeric/slider or presets) that sets an **absolute inter-row gap** and re-spaces every lane's rows to it, growing each lane's `height` so rows don't clip — distinct from density's row-snap-threshold behaviour
- [ ] Applied live on change (re-render immediately, PL-012) and undoable in one Ctrl+Z (record moved node-y's + changed lane heights into `lastTidy`; `undoTidy` already restores y and lane heights)
- [ ] Explicit-action/pref only — NOT a render pass; never mutates `examples/**` (PD-044). Not wired into a corpus re-bake this task
- [ ] Effect is **visibly and monotonically** correct: on a multi-row map (e.g. audit-process or error-escalation-ladder), larger spacing → provably larger row-to-row gaps and taller lanes; screenshots at min vs max spacing READ and clearly different (fixes the tight≈wide / inverted-spread defect)
- [ ] Density decision executed: remove the Density preset control + its `viewPrefs.density` plumbing (or repoint density to the new logic) — no dead/ineffective control left in the settings modal
- [ ] Branch-pitch verified on a fan-out map (audit-process/harvest-pipeline) with a screenshot: keep if it visibly changes stack spacing, else remove; record the decision
- [ ] `src/aef-workflow-designer.html` byte-identical to `build/gallery/designer.html`
- [ ] Before/after screenshots READ for every claim (per operator's standing "take more screenshots" guidance)

### Human
- [ ] [REVIEW] The vertical-spacing control visibly adjusts row spacing, and no ineffective control remains
  **Steps:**
  1. Serve the gallery; open a multi-row map (e.g. audit-process)
  2. Drag/change the new Vertical spacing control from min to max
  3. Confirm Density (if kept) and Branch-pitch each visibly do something, or are gone
  **Expected:** Rows spread apart / compress noticeably and monotonically; lanes grow to fit; every remaining spacing control has a visible effect
  **If not:** Note which control still appears inert

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

### 2026-07-05T19:13:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-108-vertical-spacing-control-and-density-bra.md
- **Context:** Initial task creation
