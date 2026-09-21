---
id: T-744
name: "Audit remediation cycle 1: reconcile live audit+doctor findings against arc-003"
description: >
  Audit remediation cycle 1: reconcile live audit+doctor findings against arc-003

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T07:55:23Z
last_update: '2026-09-21T20:25:09Z'
date_finished: 2026-09-21T08:51:53Z
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
cost_estimate_proposed:
  - ts: '2026-09-21T20:25:09Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:docs/reports/T-744-cycle1-findings.md); 
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-744: Audit remediation cycle 1: reconcile live audit+doctor findings against arc-003

## Context

Cycle 1 of an audit-remediation run. `arc-003` already exists and already holds
RA-001..RA-035 from a previous run of the same mandate, so this is cycle N+1, not a
cold start: the job is to re-run audit + housekeeping in full, diff against that
baseline, and open one task per *new* finding and per *regression* — not to re-open
findings that are already owned.

Two surface facts this cycle had to resolve before it could run, both recorded here
because the mandate forbids inventing verbs:

- **`fw housekeeping` does not exist in this build** (`Unknown command: housekeeping`).
  The real housekeeping surface is `fw doctor` — and arc-003's own name says "every
  audit and *doctor* finding". This cycle used `fw doctor` and records the substitution
  rather than inventing the verb.
- **There is no `bvp-estimator` TermLink worker in this build.** `.agentic-framework/agents/`
  has no such agent. `fw bvp estimate` is the scorer (heuristic v1, writes
  `bvp_scores_proposed:`, explicitly NOT sovereignty-bearing). Scoring therefore runs
  through the verb, not through a dispatched worker.

`fw audit` cannot be run whole — a full run hangs (OBS-358) — so sections were run in
timeout-boxed batches. Which sections completed, and which did not, is part of AC 5:
a pass-set baseline that does not state its own coverage is a baseline that overclaims.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Cycle-1 findings table exists at `docs/reports/T-744-cycle1-findings.md`, one row per individual FAIL and per individual WARN, each row carrying: stable ID, source (audit|doctor), severity as the tool reported it, the check that fired, the artifact implicated, and the observed-vs-expected delta.
- [x] Every row in the table is reconciled to exactly one task: either an existing arc-003 task (cited by RA-id and T-id) or a task newly created in this cycle. Reconciliation is stated as an explicit count — findings in = tasks out — and the count of unreconciled findings is zero.
- [x] Every task newly created in this cycle resolves to arc `arc-003` via its `arc_id:` field, set through `fw arc tag` (not by hand), and carries the verbatim tool output that produced its finding.
- [x] Every task newly created in this cycle carries a BVP score written by `fw bvp estimate` (i.e. a `bvp_scores_proposed:` block), with rationale recorded before the score, not after.
- [x] The audit sections that could not be run to completion in this cycle are named in the findings table with the reason, so the pass-set baseline states its own coverage rather than implying it is total.

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

test -f docs/reports/T-744-cycle1-findings.md
grep -qE 'unreconciled \.+ 0' docs/reports/T-744-cycle1-findings.md
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-74[5-9]-*.md' -o -maxdepth 1 -name 'T-75[0-7]-*.md' | xargs grep -l '^arc_id: arc-003' | wc -l)" -eq 13
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-74[5-9]-*.md' -o -maxdepth 1 -name 'T-75[0-7]-*.md' | xargs grep -l '^bvp_scores_proposed:' | wc -l)" -eq 13
test "$(find .tasks/active .tasks/completed -maxdepth 1 -name 'T-74[5-9]-*.md' -o -maxdepth 1 -name 'T-75[0-7]-*.md' | xargs grep -l 'Verbatim tool output' | wc -l)" -eq 13
grep -q 'Coverage is 19 of 19 sections' docs/reports/T-744-cycle1-findings.md

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
     fw inception decide T-744 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T07:55:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-744-audit-remediation-cycle-1-reconcile-live.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-851f51e4
- **Timestamp:** 2026-09-21T08:51:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T08:51:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
