---
id: T-283
name: "App-flavored second-tenant example map (SD-12): business+technical layering"
description: >
  Package SD-12/Lock 5: one application-flavored (non-AEF-internal) example workflow
  demonstrating business-lens + technical refinement, validating the tenant-neutral
  claim (IW-6). All 24 corpus maps are AEF processes today — no second-tenant article
  exists. Author one realistic business process map conformant to mapping-v1, validate
  with tools/validate-workflow.py, add to examples/. Refinement mechanism: link events
  or collapsed subProcess as shipped; callActivity only if T-282 lands first.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [arc:designer-authoring-surface]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-28T14:53:02Z
last_update: '2026-08-16T14:33:25Z'
date_finished: 2026-07-28T16:23:32Z
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
  - ts: '2026-08-16T12:33:47Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 0
      F1: 5
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=0 (no-signal); F1=5 (prose:process-composition)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:examples/app-processes/customer-refund.workflow.yaml,examples/app-processes/rendered/customer-refund.bpmn,tools/validate-workflow.py,tools/yaml-to-bpmn.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:52Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:examples/app-processes/customer-refund.workflow.yaml,examples/app-processes/rendered/customer-refund.bpmn,tools/yaml-to-bpmn.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-283: App-flavored second-tenant example map (SD-12): business+technical layering

## Context

SD-12 gap from the package disposition (T-278): all 24 corpus maps are AEF-internal; tenant-neutrality
(IW-6) has no second-tenant test article. Author one app-flavored map (generic e-commerce customer-refund
tenant) using only shipped mechanisms: `external` lane authority for the customer, business+technical
layering via aef.constituents on the executing node (T-081 pattern, no callActivity dependency).

## Acceptance Criteria

### Agent
- [x] `examples/app-processes/customer-refund.workflow.yaml` exists, models a non-AEF tenant (no AEF concepts in lanes/nodes), and includes an `external`-authority lane plus all four authority values across lanes
- [x] Business+technical layering demonstrated: the refund-execution node carries >=3 aef.constituents (technical refinement declared first-class, not a parallel document)
- [x] `tools/validate-workflow.py` passes on the YAML with zero findings
- [x] Rendered BPMN generated via `tools/yaml-to-bpmn.py` into `examples/app-processes/rendered/` and validates as BPMN form too
- [x] Determinism markers on every node (P4 frontier convention) and userTask decisionOutputs match its outgoing edge names

## Evolution

### 2026-07-28 — promoted from later and executed same-day
- **Observed:** Filed hours earlier as horizon later; promoted under the operator's arc directive because it is the only agent-owned actionable arc task (all else is human review-wait). Built exactly to plan: no callActivity dependency needed — aef.constituents (T-081) carried the business+technical layering cleanly; `external` lane authority (validator AUTHORITIES set) carried the customer actor. Both YAML and rendered BPMN validated zero-findings on first pass — a concrete V1 (agent-generation) data point for the package scorecard.
- **Plan impact:** none; scope held (one map, examples-only). New examples/app-processes/ directory establishes the second-tenant corpus home.
- **Triggered:** nothing; T-281 (lenses) would use this map as its business-lens test article if ever GO'd.

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
test -f examples/app-processes/customer-refund.workflow.yaml
python3 tools/validate-workflow.py examples/app-processes/customer-refund.workflow.yaml
test -f examples/app-processes/rendered/customer-refund.bpmn
python3 tools/validate-workflow.py examples/app-processes/rendered/customer-refund.bpmn
grep -q 'authority: external' examples/app-processes/customer-refund.workflow.yaml
test $(grep -c 'id: c_' examples/app-processes/customer-refund.workflow.yaml) -ge 3
out=$(grep -c 'determinism:' examples/app-processes/customer-refund.workflow.yaml); test "$out" -ge 8
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

### 2026-07-28T14:53:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-283-app-flavored-second-tenant-example-map-s.md
- **Context:** Initial task creation

### 2026-07-28T16:20:32Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-28T16:20:33Z — status-update [task-update-agent]
- **Change:** horizon: now → now

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e826d4c5
- **Timestamp:** 2026-07-28T16:23:33Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#4 (Agent)** — Rendered BPMN generated via `tools/yaml-to-bpmn.py` into `examples/app-processes/rendered/` and validates as BPMN form too
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/yaml-to-bpmn.py in: Rendered BPMN generated via `tools/yaml-to-bpmn.py` into `examples/app-processes/rendered/` and validates as BPMN form too`

### 2026-07-28T16:23:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
