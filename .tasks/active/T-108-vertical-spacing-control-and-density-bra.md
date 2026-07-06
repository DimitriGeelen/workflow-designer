---
id: T-108
name: "Vertical spacing control and density-branch-pitch effectiveness"
description: >
  Operator report: Density and Branch-pitch settings appear ineffective; add a working vertical-spacing control and decide their fate. See task body.

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
created: 2026-07-05T19:13:16Z
last_update: 2026-07-05T19:38:01Z
date_finished: 2026-07-05T19:36:56Z
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
- [x] New "Vertical spacing" control (numeric/slider or presets) that sets an **absolute inter-row gap** and re-spaces every lane's rows to it, growing each lane's `height` so rows don't clip — distinct from density's row-snap-threshold behaviour
  → `respaceRows(gap)` + number input `#set-row-spacing` (72–240px, step 8). Clusters lane nodes into rows by centre-y band (28px), translates each row rigidly so consecutive row centres sit `gap` apart, grows lane height to fit.
- [x] Applied live on change (re-render immediately, PL-012) and undoable in one Ctrl+Z (record moved node-y's + changed lane heights into `lastTidy`; `undoTidy` already restores y and lane heights)
  → change listener calls `respaceRows(v)` which renders immediately and records `{laneId:null, positions, laneHeights}`. Verified: one undo reverted audit-process framework lane 1512→504px, pool 1752→744px, `lastTidy` cleared.
- [x] Explicit-action/pref only — NOT a render pass; never mutates `examples/**` (PD-044). Not wired into a corpus re-bake this task
  → only the change-listener (explicit user action) and Reset call it; no render pass invokes `respaceRows`. `examples/**` untouched.
- [x] Effect is **visibly and monotonically** correct: on a multi-row map (e.g. audit-process or error-escalation-ladder), larger spacing → provably larger row-to-row gaps and taller lanes; screenshots at min vs max spacing READ and clearly different (fixes the tight≈wide / inverted-spread defect)
  → audit-process framework lane, baseline gaps `[75,42,37,74,76,58]` (ragged). 72px→`[72×6]`, lane 504px. 160px→`[160×6]`, lane 1032px. 240px→`[240×6]`, lane 1512px. Strictly monotonic. Screenshots `t108-baseline/min72/max240.png` READ — clearly different.
- [x] Density decision executed: remove the Density preset control + its `viewPrefs.density` plumbing (or repoint density to the new logic) — no dead/ineffective control left in the settings modal
  → `#set-density`, `DENSITY_PITCH`, `viewPrefs.density`, load-validation, syncSettingsUI line, change-listener, reset-default all removed. `rowPitch()` returns fixed `ROW_PITCH`. grep confirms zero `density` refs; stored prefs carry no `density` key. `t108-settings.png` READ — Density gone, Vertical spacing present.
- [x] Branch-pitch verified on a fan-out map (audit-process/harvest-pipeline) with a screenshot: keep if it visibly changes stack spacing, else remove; record the decision
  → harvest-pipeline 6-node stack: auto 80px pitch → roomy 92px (+15%/gap, ×5 = +60px). `t108-bp-auto.png` vs `t108-bp-roomy.png` READ — stack visibly taller in roomy. **KEEP** (see Decisions).
- [x] `src/aef-workflow-designer.html` byte-identical to `build/gallery/designer.html`
  → `cmp` reports identical; extracted JS passes `node --check`.
- [x] Before/after screenshots READ for every claim (per operator's standing "take more screenshots" guidance)
  → baseline, min72, max240, settings, bp-auto, bp-roomy all READ with the Read tool.

### Human
- [ ] [REVIEW] The vertical-spacing control visibly adjusts row spacing, and no ineffective control remains
  **Steps:**
  1. Serve the gallery; open a multi-row map (e.g. audit-process)
  2. Drag/change the new Vertical spacing control from min to max
  3. Confirm Density (if kept) and Branch-pitch each visibly do something, or are gone
  **Expected:** Rows spread apart / compress noticeably and monotonically; lanes grow to fit; every remaining spacing control has a visible effect
  **If not:** Note which control still appears inert

## Verification

cmp -s src/aef-workflow-designer.html build/gallery/designer.html
grep -q "function respaceRows" src/aef-workflow-designer.html
grep -q "id=\"set-row-spacing\"" src/aef-workflow-designer.html
! grep -q "viewPrefs.density\|set-density\|DENSITY_PITCH" src/aef-workflow-designer.html

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

### 2026-07-05 — Retire Density, keep Branch-pitch
- **Chose:** Remove the Density preset entirely; keep Branch-pitch.
- **Why:** Density only scaled a snap *threshold* (`DENSITY_PITCH` × `ROW_PITCH`) that Tidy/drag consult — it never re-spaced existing rows nor grew lanes, so on an already-tidy baked map tight↔wide read as inert (the operator's report; measured inverted spread tight 547 > wide 490). The new Vertical spacing control fully subsumes and surpasses its intent (absolute pitch + lane growth), so Density became redundant *and* misleading. Branch-pitch, by contrast, demonstrably works: harvest-pipeline's 6-node fan-out stack widened auto 80px → roomy 92px, visible in screenshots. It is orthogonal to Vertical spacing (tunes the gap *within* fan-out stacks during Clean, not the global inter-row pitch), so both earn their place.
- **Rejected:** (a) Repointing Density to the new logic — would keep a second, weaker vertical-spacing control competing with the explicit one. (b) Removing Branch-pitch too — it is not inert; removing a working, distinct control on suspicion would lose real capability.

### 2026-07-05 — Rigid row-shift over snap-to-row-centre
- **Chose:** Translate each detected row as a rigid group (`n.y += delta`) rather than snapping every node onto the row's exact centre-y.
- **Why:** Rigid translation preserves intra-row layout, so no *new* same-row overlap can be introduced; combined with the ≥72px clamp exceeding the tallest node (task 64px), inter-row folding is impossible either — the effect is monotonic by construction with no measure-after-move revert needed (unlike alignRows/alignColumns, which snap to a shared axis and must guard collisions).
- **Rejected:** Snap-to-centre (as alignRowsLane does) — would force intra-row nodes at differing y onto one line, risking overlaps and needing a revert path for no gain here.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Visual Verification

All screenshots taken headless (Playwright MCP, gallery :8834) and READ with the Read tool:

| Screenshot | Map | Shows |
|---|---|---|
| `t108-baseline.png` | audit-process | framework lane, ragged stack gaps `[75,42,37,74,76,58]` |
| `t108-min72.png` | audit-process | Vertical spacing 72px → uniform gaps, lane 504px |
| `t108-max240.png` | audit-process | Vertical spacing 240px → stack fanned to 240px pitch, lane grew to 1512px, no clip/overlap |
| `t108-settings.png` | (modal) | View section: **Vertical spacing** present, **Density gone**, Branch pitch retained |
| `t108-bp-auto.png` | harvest-pipeline | 6-node fan-out stack at auto (80px pitch) |
| `t108-bp-roomy.png` | harvest-pipeline | same stack at roomy (92px) — visibly taller |

Monotonicity is exact (72<160<240 → lane 504<1032<1512; gaps 72<160<240), fixing the tight≈wide / inverted-spread defect the operator reported.

## Recommendation

**Recommendation:** GO — ship.

**Rationale:** The operator's request ("a setting where I can adjust the vertical spacing" that *visibly* works) is met by the new **Vertical spacing** control — it sets an absolute inter-row gap, re-spaces every lane's rows to it, and grows lane height to fit, applied live and reverted by one Ctrl+Z. Verified strictly monotonic (unlike the old Density preset, whose effect was near-invisible and inverted). The misleading Density preset is fully removed; Branch-pitch is kept because it demonstrably widens fan-out stacks and is orthogonal to the new global control. Render-only / explicit-action; `examples/**` untouched; not wired into any corpus re-bake (PD-044).

**Evidence:**
- Monotonic re-spacing on audit-process framework lane: 72px→lane 504px, 160px→1032px, 240px→1512px; gaps uniform `[72×6]`/`[160×6]`/`[240×6]` vs ragged baseline `[75,42,37,74,76,58]`. Screenshots `t108-baseline/min72/max240.png` READ.
- One Ctrl+Z undo reverted framework lane 1512→504px, pool 1752→744px, `lastTidy` cleared.
- Density gone: grep finds zero `viewPrefs.density`/`set-density`/`DENSITY_PITCH`; stored prefs carry no `density` key; `t108-settings.png` READ (Density absent, Vertical spacing present).
- Branch-pitch kept: harvest-pipeline 6-node stack auto 80px → roomy 92px; `t108-bp-auto.png` vs `t108-bp-roomy.png` READ.
- `cmp` src == build/gallery; extracted JS passes `node --check`; verification gate 4/4 PASS.

**Suggested operator check:** open audit-process in the served gallery, dial Vertical spacing min→max, confirm rows fan apart and lanes grow; confirm Density is gone and Branch-pitch still spreads stacks.

## Updates

### 2026-07-05T19:13:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-108-vertical-spacing-control-and-density-bra.md
- **Context:** Initial task creation

### 2026-07-05T19:36:56Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
