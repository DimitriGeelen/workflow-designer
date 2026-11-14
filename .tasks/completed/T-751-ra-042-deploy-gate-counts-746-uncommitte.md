---
id: T-751
name: "RA-042: deploy gate counts 746 uncommitted source files"
description: >
  Audit deployment section reports [FAIL] Deploy gate: 746 uncommitted source file(s).
  Shares a root cause with RA-005/T-701 but is a different check.

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: agent
horizon: null
tags: [audit-remediation, cycle-1]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T07:59:09Z
last_update: 2026-11-14T11:52:39Z
date_finished: 2026-11-14T11:52:39Z
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
  - ts: '2026-09-21T08:00:52Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 (no-signal); 
      F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-11-14T11:51:46Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 1
      F2: 1
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=2 (body:learning-ref); D2=0 (no-signal); D3=0 (no-signal); D4=0
      (no-signal); F-RECALL=1 (body:episodic-only); F2=1 (body/components:component-fabric-incidental);
      F4=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F3=0 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L0: no signal); F1=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T08:01:04Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 5
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/audits/2026-08-30.yaml,.context/audits/2026-09-05-structure.yaml);
      tier=2 (no-signal); effort=5 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-751: RA-042: deploy gate counts 746 uncommitted source files

## Context

**Background / trigger:** the September residue audit (RA-042) ran the opt-in deployment section, which reported
"746 uncommitted source file(s)".
**Problem / hypothesis:** the count mixes framework housekeeping (retention-sweep deletions, episodic refreshes) with
real source, so it does not mean what it says.
**Goal:** split the count by class and state the genuine-source residue.
**Expected outcome:** a number later cycles can compare against, and the gate question settled.

### Verbatim tool output

```
[FAIL] Deploy gate: 746 uncommitted source file(s)
       Evidence: .context/audits/2026-08-30.yaml
                 .context/audits/2026-09-05-structure.yaml
```

### The invariant that is not held

The deploy gate counts every uncommitted tracked file as a blocker. 746 is not 746 pieces of unfinished work: the overwhelming majority are deletions under `.context/audits/cron/` performed by the 7-day retention sweep, which is a cron job's output and not the agent's to commit (T-571). The gate cannot currently distinguish machine-generated churn from human work in progress, so its count is not a measure of deploy readiness.

### Root-cause links

Shares a root cause with RA-005 (T-701, '100 real files modified and uncommitted') — different check, same underlying condition. Kept as a separate record per the one-finding-one-task rule.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The 746 is decomposed by class with the command that produced each count: retention-sweep deletions, audit-record modifications, and genuine source changes.
- [x] Either the deploy gate excludes the retention-sweep class and reports a count that means what it says, or a Sovereign question is filed proposing that change — the gate is NOT weakened to make the number smaller.
- [x] The residual genuine-source count is stated, and is the number any later cycle compares against.

**Evidence (2026-11-14).** The gate's own command (`audit.sh` deployment section):
`git diff --name-only HEAD -- '*.py' '*.sh' '*.yml' '*.yaml' 'Dockerfile'` now counts **918**. Split with
`git diff --name-status HEAD -- <same pathspecs>`, grouped by status and the first two path parts:
| class | count |
|---|---|
| retention-sweep deletions (`D .context/audits/cron/…`) | 758 |
| episodic records modified by the framework (`M .context/episodic/…`) | 127 |
| component cards modified (`M .fabric/components/…`) | 15 |
| other `.context` housekeeping (`audits` 4 M, `working` 6 D + 2 M, `project` 3 M, `approvals` 3 D) | 18 |
| **genuine source** (`git diff --name-only HEAD -- src tools tests`, code only) | **0** |
(The one `tests/` path is `tests/.run-history.tsv`, a run log, not code.) The residual genuine-source count is **0**; a
later cycle compares against that.
**The gate:** the question became broader than this task asked. The operator ruled T-1413 **NO-GO** (job 137, commit
ea646ec85): 832 is not a deployed service, so the deployment section (opt-in, `--section deployment` only) is out of
scope for 832 altogether. No Sovereign question about the gate's counting is needed any more, and the gate was not
changed or weakened. The uncommitted framework-maintained files themselves are T-701's subject.

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
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
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
grep -q '^\*\*Decision\*\*: NO-GO' .tasks/completed/T-1413-*.md

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

### 2026-11-14 — the gate left 832's scope
- **What changed:** the count was split (918 today, 0 genuine source), and the operator's NO-GO (T-1413; first ruled
  as PD-296 via T-766 in October) put the whole deployment section out of 832's scope.
- **Plan impact:** no gate change and no Sovereign question are needed any more.
- **Triggered:** nothing new; the uncommitted housekeeping files stay T-701's subject.

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
     fw inception decide T-751 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T07:59:09Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-751-ra-042-deploy-gate-counts-746-uncommitte.md
- **Context:** Initial task creation

test "$(cd /opt/832-Workflow-designer && git status --porcelain | grep -c '^ D .context/audits/cron/')" -gt 0

### 2026-11-14T11:51:45Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-14T11:52:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-23c460d5
- **Timestamp:** 2026-11-14T11:52:41Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** none
