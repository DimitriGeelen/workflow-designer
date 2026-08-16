---
id: T-177
name: "Emit aef horizon workflow-type owner as first-class semantic attributes in
  designer"
description: >
  Emit aef horizon workflow-type owner as first-class semantic attributes in designer

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
created: 2026-07-10T19:36:18Z
last_update: '2026-08-16T14:33:18Z'
date_finished: 2026-07-10T19:58:17Z
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
  - ts: '2026-08-16T12:33:41Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:18Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 2
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F2=0 
      (no-signal); F4=1 (prose:routing/geometry-incidental); F3=2 
      (prose:seam-namespace); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:18Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-175-mapping-strawman.md,src/aef-workflow-designer.html,tests/test_editor_bridge_meta_parity.py,tools/yaml-to-bpmn.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-177: Emit aef horizon workflow-type owner as first-class semantic attributes in designer

## Context

The designer is the authoring surface for AEF workflows, yet it cannot currently express the three
most basic governance fields of a task — `horizon` (now/next/later), `workflow_type` (build/test/…),
and `owner` (human/agent). Audit 2026-07-10 confirmed 0 occurrences of these in `src/`. This task adds
them so a diagram node can carry them and they round-trip through BPMN export/import. Architecturally
they join the existing scalar governance fields (`tier`, `decisionOwner`, `triggeredBy`) in the
`aef:meta` attribute block — kept in lockstep with the Python bridge's `META_KEYS` (PL-005: editor↔bridge
serialization can drift on any key; the parity test is the guard). Low-regret, standalone editor
capability that de-risks the designer-authoring-surface arc's forward-bridge (child-2) without
pre-deciding the mapping contract. See `docs/reports/T-175-mapping-strawman.md` §G-1.

## Acceptance Criteria

### Agent
- [x] `horizon`, `workflowType`, `owner` added to `FIELD_META` as `special: 'select'` fields with closed
      value sets (horizon: now/next/later; workflowType: build/test/refactor/decommission/specification/design/inception;
      owner: human/agent), and added to `AEF_FIELDS` for task-like node types (serviceTask, userTask, scriptTask, subProcess).
- [x] All three added to the editor's `metaKeys` array (export, `aefExtensionXml`) so they emit as `<aef:meta>` attributes.
- [x] All three added to the Python bridge `META_KEYS` (`tools/yaml-to-bpmn.py`) in lockstep — editor↔bridge parity preserved.
- [x] Round-trip verified: a node with the three fields set exports to `<aef:meta horizon=… workflowType=… owner=…/>` and
      re-imports (`parseBpmnXml`) with identical values — no drift, no drop. (headless: values preserved now/build/agent)
- [x] Editor↔bridge meta-parity test passes (`tests/test_editor_bridge_meta_parity.py`). (exit 0: 20 ⊆ 29)
- [x] No regression: existing round-trip (14→14 node investigate corpus) still exports/imports with identical counts. (14→14 nodes, 16→16 edges)

## Verification

# Shell commands that MUST pass before work-completed. One per line.
python3 tests/test_editor_bridge_meta_parity.py
# All three keys present in the editor metaKeys array
out=$(grep -A7 "const metaKeys" src/aef-workflow-designer.html); echo "$out" | grep -q "horizon" && echo "$out" | grep -q "workflowType" && echo "$out" | grep -q "owner"
# All three keys present in the bridge META_KEYS
grep -q "horizon" tools/yaml-to-bpmn.py && grep -q "workflowType" tools/yaml-to-bpmn.py && grep -q "owner" tools/yaml-to-bpmn.py

## Visual Verification

Screenshot: `docs/reports/assets/T-177-inspector-governance-fields.png` — the scriptTask inspector's
EXTENSIONS section rendered live (served editor, headless Chromium). Confirms the three new dropdowns
render correctly at the top of the aef: extensions block, in style, with correct labels/hints and closed
value sets: **Horizon**=now, **Workflow type**=build, **Owner**=agent. Existing fields (Tier, Endpoint,
Context reads, Artifacts writes, I/O contract) still render below with no layout regression. DOM-level
option sets also verified: horizon [now/next/later], workflowType [build/test/refactor/decommission/
specification/design/inception], owner [human/agent].

# Verification section continues below.
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

### 2026-07-10T19:36:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-177-emit-aef-horizon-workflow-type-owner-as-.md
- **Context:** Initial task creation

### 2026-07-10T19:58:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
