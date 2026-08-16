---
id: T-086
name: "Migrate remaining constituents-like x-* sites: tier0-escalation x-sources,
  task-lifecycle x-gates"
description: >
  Follow-up to T-081 (found by its completion gate sweeping the whole corpus): two
  more FC-11-style collapsed nodes still declare constituents via the x-* scalar workaround
  — tier0-escalation n(?) aef.x-sources (2 approval sources) and task-lifecycle completion
  node aef.x-gates (5 gates with skip-flags). Migrate both to first-class aef.constituents
  entries per the T-081 pattern (keep node types; constituents legal on any node —
  PD decision in T-081). fabric-blast-radius x-seeAlso is NOT constituents (a see-also
  pointer) — leave it. Regenerate the 2 rendered .bpmn, corpus suites must stay green.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-04T14:31:48Z
last_update: '2026-08-16T13:58:48Z'
date_finished: 2026-07-04T14:35:18Z
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
  - ts: '2026-08-16T12:33:35Z'
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
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:15Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 6
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:examples/aef-processes/rendered/task-lifecycle.bpmn,examples/aef-processes/rendered/tier0-escalation.bpmn,examples/aef-processes/task-lifecycle.workflow.yaml,examples/aef-processes/tier0-escalation.workflow.yaml);
      tier=2 (no-signal); effort=6 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:48Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 6
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:examples/aef-processes/rendered/task-lifecycle.bpmn,examples/aef-processes/rendered/tier0-escalation.bpmn,examples/aef-processes/task-lifecycle.workflow.yaml,examples/aef-processes/tier0-escalation.workflow.yaml);
      tier=2 (no-signal); effort=6 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-086: Migrate remaining constituents-like x-* sites: tier0-escalation x-sources, task-lifecycle x-gates

## Context

Follow-up to T-081 (its completion-gate corpus sweep surfaced two more FC-11 sites still on the x-* scalar workaround). Same migration pattern as T-081: first-class `aef.constituents`, node types unchanged (PD-036: constituents legal on any node). `fabric-blast-radius` x-seeAlso stays — it is a see-also pointer, not constituents.

## Acceptance Criteria

### Agent
- [x] task-lifecycle completion-gate node: `x-gates` (5 gates, each with its skip-flag) → `aef.constituents` entries with `ref` carrying policy id + skip-flag; `x-gates` key removed; surrounding T-062 comment updated
- [x] tier0-escalation approval-check node: `x-sources` (2 approval sources) → `aef.constituents` entries with `ref` carrying the path; `x-sources` key removed
- [x] Both rendered .bpmn regenerated and carrying `<aef:constituents>`; no other rendered file changes
- [x] Suites stay green: bridge 31/31, validator corpus exit 0, lane-bands 24 clean; no x-checks/x-sources/x-captures/x-gates keys remain anywhere in the corpus

## Verification

grep -q "c_sovereignty" examples/aef-processes/task-lifecycle.workflow.yaml
grep -q "c_cli_approval" examples/aef-processes/tier0-escalation.workflow.yaml
grep -q "aef:constituent " examples/aef-processes/rendered/task-lifecycle.bpmn
grep -q "aef:constituent " examples/aef-processes/rendered/tier0-escalation.bpmn
! grep -n "x-checks:\|x-sources:\|x-captures:\|x-gates:" examples/aef-processes/*.workflow.yaml | grep -v ":\s*#" | grep -v "#.*x-" | grep -q .
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean"
python3 tools/validate-workflow.py examples/aef-processes/task-lifecycle.workflow.yaml --quiet
python3 tools/validate-workflow.py examples/aef-processes/tier0-escalation.workflow.yaml --quiet


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

### 2026-07-04T14:31:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-086-migrate-remaining-constituents-like-x--s.md
- **Context:** Initial task creation

### 2026-07-04T14:33:21Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-04T14:35:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
