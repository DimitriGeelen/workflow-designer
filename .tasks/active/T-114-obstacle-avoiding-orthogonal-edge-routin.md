---
id: T-114
name: "Obstacle-avoiding orthogonal edge routing for residual node-cuts"
description: >
  Obstacle-avoiding orthogonal edge routing for residual node-cuts

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
created: 2026-07-05T21:07:06Z
last_update: 2026-07-05T21:07:06Z
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

# T-114: Obstacle-avoiding orthogonal edge routing for residual node-cuts

## Context

Build authorised by the **T-112 GO decision** (docs/reports/T-112-node-cut-router-inception.md).
The corpus has 27 node-cut incidences, 74% in harvest-pipeline + error-escalation-ladder.

**Failure mode (diagnosed, T-112 §3 + T-114 spike):** ALL residual cuts are loop-back
detours (`isLoop:true`) in fan-out/fan-in patterns around a vertical stack of sibling nodes.
To reach a node in the *middle* of the stack, `orthoLoopBack`'s arrival leg runs down the
*centre* of the node column (e.g. harvest e_11 leg at x≈1211 inside boxes at x=1160–1262),
passing through the siblings between the detour band and the target. Band selection cannot
fix this — any vertical approach to a mid-stack node from above/below clips siblings; the
target must be approached from the **side** in a clear channel. That is precisely what an
obstacle-avoiding grid router does, and why a targeted `orthoLoopBack` patch would fail.

**Design:** add a grid-based orthogonal A* router, invoked at the `needsLoop` branch of
`routeOrthogonalSegment` (src:~3636) **only when** `orthoLoopBack`'s result still crosses a
node. Build a coarse grid over the diagram bounds, block node-occupied cells (+ margin),
A* from source-stub to target-stub with orthogonal moves + a turn penalty (clean paths).
Use the A* path **only if it strictly reduces crossings**; otherwise **fall back** to today's
`orthoLoopBack` output. Conservative + additive: clean routes are untouched (PL-005), no
stored geometry mutated — it computes the transient `_renderedPolyline` only (PD-044-safe).

**Validation:** the T-113 census harness is the gate — corpus cuts must drop with **zero
regression** on any map, and `mapMessiness()` must not rise.

## Acceptance Criteria

### Agent
- [ ] A grid-based orthogonal A* obstacle router exists in the editor (pure function:
      stubs + node rects → orthogonal polyline avoiding non-endpoint node boxes)
- [ ] It is invoked at the `needsLoop` branch **only when** `orthoLoopBack`'s result still
      crosses a node, and is used **only if** it strictly reduces crossings (else fallback)
- [ ] Corpus node-cuts drop materially: harvest-pipeline and error-escalation-ladder each
      reduced by ≥50% incidences; corpus total ≤ 14 (from 27)
- [ ] **Zero regression:** no map's cut count increases (T-113 harness), and `mapMessiness()`
      does not rise on any map
- [ ] No stored geometry mutated — router computes `_renderedPolyline` only, runs in render
      pass (PD-044); `src/aef-workflow-designer.html` == `build/gallery/designer.html`
- [ ] T-113 baseline refreshed to the improved counts (the gate stays rot-proof)

### Human
- [ ] [REVIEW] Rerouted fan/join edges look clean, not contorted
  **Steps:**
  1. Open http://localhost:8834/designer.html?load=rendered/harvest-pipeline.bpmn
  2. Look at the fan-out (fork→harvest nodes) and fan-in (harvest nodes→join) edges
  3. Compare against the before/after screenshots attached to this task
  **Expected:** No edge passes through an unrelated node box; rerouted edges take sensible
  side channels (not wild zig-zags or excessive detours)
  **If not:** Note which edge looks wrong; the router's turn-penalty / grid pitch can be tuned

## Verification

# Shell commands that MUST pass before work-completed. One per line.
bash tests/check-corpus-node-cuts.sh
diff -q src/aef-workflow-designer.html build/gallery/designer.html
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

### 2026-07-05T21:07:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-114-obstacle-avoiding-orthogonal-edge-routin.md
- **Context:** Initial task creation
