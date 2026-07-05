---
id: T-106
name: "Routing margin setting: reserved periphery band for loop-back edges"
description: >
  T-092 Phase C option 3: expose a routing-margin preference (none/8/16px) that widens the reserved periphery band orthoLoopBack() uses for loop-back/long-run edges, so they skirt the content instead of sharing a corridor with row-2 nodes (survey finding 5). Editor-local pref like straightening/channel-sep; render-only, no stored geometry mutation (PD-044 trivially safe).

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
created: 2026-07-05T18:36:00Z
last_update: 2026-07-05T18:36:00Z
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

# T-106: Routing margin setting: reserved periphery band for loop-back edges

## Context

T-092 Phase C option 3 (survey: `docs/reports/T-092-routing-layout-survey.md`, finding 5).
`orthoLoopBack()` (src line ~3458, from T-076/PD-029) routes loop-back / long-run edges
around the content periphery, clamped to a hardcoded `LANE_MARGIN = 12` from the lane
border. When the lane band is too tight, the periphery candidate is dropped and the bar
falls back into the body, sharing a corridor with row-2 nodes (finding 5). This task adds
an editor-local **routing-margin** preference (none/normal/roomy) that widens the reserved
periphery band so loop-backs get a wider exclusive channel. Render-only — no stored
geometry mutation (PD-044 trivially safe). Must re-render live on change (PL-012: a pref
that only affects future actions reads as inert — my own T-104 lesson).

## Acceptance Criteria

### Agent
- [ ] New editor-local pref `routingMargin` (none=0 / normal=8 / roomy=16px, default `normal`) added, persisted the same way as straightening-tolerance / channel-separation prefs; survives reload
- [ ] A "Routing margin" control is added to the Routing section of the settings modal, styled like the existing straightening/channel-sep controls
- [ ] `orthoLoopBack()` consumes the pref: the effective lane/periphery margin = baseline + `routingMargin`, so loop-back bars sit in a wider reserved band; `none` reproduces the current baseline (`LANE_MARGIN = 12`) exactly — pure additive, no behaviour change at `none`
- [ ] Changing the setting re-renders immediately (live apply, PL-012) — no reload/re-import required
- [ ] Render-only: `git diff --name-only` shows only `src/aef-workflow-designer.html` and its `build/gallery/designer.html` mirror — no `examples/**/*.workflow.yaml` or `rendered/*.bpmn` changed (PD-044)
- [ ] `src/aef-workflow-designer.html` is byte-identical to `build/gallery/designer.html`
- [ ] Element screenshots of a loop-back-dense map (task-lifecycle "gate failed — resume" run) at margin none / normal / roomy are taken AND READ, confirming the bar visibly moves outward and clears row-2 nodes at roomy, with no regression to non-loop edges

### Human
- [ ] [REVIEW] Routing-margin setting visibly reserves a wider periphery band; loop-backs stop cutting through row-2 nodes at roomy, and non-loop edges are unaffected
  **Steps:**
  1. Serve the gallery (`tools/serve-gallery.sh`) and open `task-lifecycle` (or any map with a loop-back "resume/rework" edge)
  2. Open Settings → Routing → Routing margin; switch none → normal → roomy and watch the loop-back cross-bar
  **Expected:** The loop-back bar moves outward toward the lane edge as the margin increases and, at roomy, clears the row-2 nodes it previously ran alongside; straight/forward edges are unchanged
  **If not:** Note which map/edge still overlaps and at which margin setting

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

# Editor JS must be mirrored byte-identical into the gallery build artifact.
diff -q src/aef-workflow-designer.html build/gallery/designer.html
# Render-only guarantee: no corpus geometry changed by this task.
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

### 2026-07-05T18:36:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-106-routing-margin-setting-reserved-peripher.md
- **Context:** Initial task creation
