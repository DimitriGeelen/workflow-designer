---
id: T-724
name: "RA-028: D5 task lifecycle reports 10 cycle-time anomalies"
description: >
  Audit WARN cycle 1 2026-09-16: tasks with unusual cycle times. Every one of the
  ten is blocked on an operator decision, so the anomaly is a measurement of decision
  latency, not of agent throughput.

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: agent
horizon: null
tags: [arc-003, audit-remediation, RA-028]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-16T13:26:08Z
last_update: 2026-11-14T15:40:24Z
date_finished: 2026-11-14T15:40:24Z
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
  - ts: '2026-09-16T13:30:39Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-11-14T15:35:18Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 4
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=2 (body:learning-ref); D2=4 (body:fw-audit-or-doctor); D3=0 (no-signal);
      D4=0 (no-signal); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=0 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-16T13:30:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-724: RA-028: D5 task lifecycle reports 10 cycle-time anomalies

## Context

**Background / trigger:** the September residue audit (RA-028) saw D5 flag ten tasks as lifecycle anomalies (open
more than 7 days).
**Problem / hypothesis:** D5 cannot tell a genuinely stalled task from one blocked on a decision, so its count mixes
real neglect with legitimate waiting.
**Goal:** classify each flagged task as stalled or blocked-on-decision, naming the blocker.
**Expected outcome:** the flagged set is understood, nothing is closed just to clear the count, and whether D5 can
tell the two states apart is recorded.

**Finding RA-028** - cycle 1, 2026-09-16. Source: fw audit. Severity: WARN.

Cycle-1 baseline for regression detection: audit Pass 166 / Warn 31 / Fail 1; doctor 3 warn / 0 fail.

**Verbatim tool output:**

```
[WARN] D5: Task lifecycle - 10 anomaly(s): T-105(72d-active) T-189(66d-active) T-286(49d-active) T-309(48d-active) T-357(44d-active) T-358(43d-active) T-681(10d-active) T-341(45d-active) T-669(14d-active) T-575(26d-active)
       Evidence: Tasks with unusual cycle times detected
       Mitigation: Review flagged tasks for process issues
```

**The invariant that is not held:**

D5 measures elapsed time in active/ and reads a long tail as a process problem. For all ten flagged tasks the elapsed time is decision latency, not execution latency: each is blocked on a ruling that has not been made. The invariant the check assumes - that a task in active/ is a task being worked - does not hold here. The measurement is correct and its interpretation is wrong, which is worth recording because a check that cannot distinguish 'stalled' from 'waiting on you' will keep firing after every real fix.

**Root-cause siblings:** T-723 (RA-027), T-727 (RA-031)

**Verification is the next cycle's re-run of the originating check, not this task's own assertion that it is fixed.**

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Each of the ten tasks is classified as either genuinely stalled or blocked-on-decision, with the blocking decision named
- [x] D5 stops naming any task that has been correctly reclassified, or this task records why the check cannot distinguish the two states
- [x] No task is closed merely to clear the anomaly

**Evidence (2026-11-14).** The ten September tasks today:
| task | state now | class | blocker |
|---|---|---|---|
| T-105, T-309, T-357, T-681, T-341, T-669, T-358 | work-completed (2026-09-30 … 11-12), each on its own path | resolved | — |
| T-189 | started-work, owner human; all Agent ACs ticked | blocked-on-decision | operator `[REVIEW]` sign-off to graduate the IW-9 delta into the frozen v1 standard (v1 → v1.1) |
| T-286 | started-work, owner human; all Agent ACs ticked | blocked-on-decision | operator `[REVIEW]` of the arrow-over-badge feel, after AEF T-5108 (the badge layering upstream) |
| T-575 | started-work, owner agent (landing umbrella) | partly blocked, partly stalled | its FREE tasks need the operator's completion (the agent may not); its DEAD-PREMISE rewrites are agent work untouched since 2026-09 |
None was closed to clear the count (the seven closed through their own work, weeks before this task resumed).
**Why D5 cannot tell the states apart, measured:** D5 already means to skip partial-complete tasks (T-100122: all
Agent ACs ticked, a Human AC open), which is exactly T-189 and T-286, yet it flags them. Cause: `is_partial_complete()`
(`audit.sh` ~8442-8443, be.48) finds sections with `re.findall(r'### Agent[^\n]*\n…')`, **not anchored to line
start**; the task template's Human-section help comment contains "…should be moved to ### Agent and…", so it opens a
second "Agent" block there and counts the Human box below as an unticked Agent criterion. Run on a copy of T-189: 2
Agent blocks, 5 ticked + 1 "unticked" (the Human box) → not excluded. Reported to AEF as a bug (conversation
`832-audit-rulings`, msg 1fd137c2). Beyond that bug, D5 has no notion of "waiting on a peer or the operator" for
agent-owned tasks, so it cannot separate those from stalled ones; today it flags 54 tasks (T-731 partitions them).

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
         1. Run `bin/fw reviewer T-724`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-724 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

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

# Parked: eight of ten are blocked on operator rulings.
for t in 105 309 357 681 341 669 358; do grep -q '^status: work-completed' .tasks/completed/T-$t-*.md || exit 1; done
grep -q 'Conversion: this AC should be moved to ### Agent' .tasks/active/T-189-*.md

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

### 2026-11-14 — D5's partial-complete exclusion is broken by the task template
- **What changed:** seven of the ten closed on their own; the two human-review tasks are flagged because D5's section
  regex reads the template's help comment as an Agent section.
- **Plan impact:** the fix is AEF's (reported, msg 1fd137c2); nothing to change in 832.
- **Triggered:** the AEF bug report; the full 54-task partition is T-731's.

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
     fw inception decide T-724 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-16T13:26:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-724-ra-028-d5-task-lifecycle-reports-10-cycl.md
- **Context:** Initial task creation

### 2026-09-29T17:31:22Z — status-update [task-update-agent]
- **Change:** owner: human → agent

### 2026-11-14T15:35:17Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-11-14T15:40:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

### 2026-11-14T15:50Z — AEF fixed the D5 bug [agent]
- AEF (msg 03e9650a): "Confirmed and fixed: AEF T-5133. is_partial_complete now strips HTML comments and anchors
  ### Agent / ### Human to line start", with a test of the T-189 shape (fails on the old code) and a check that an
  unticked Agent criterion still flags; on AEF bleeding-edge 154afe1f3, shipped with their next be-tag. After 832's
  next framework upgrade, D5 should stop naming T-189 and T-286 (verify then).

## Reviewer Verdict (v1.5)

- **Scan ID:** R-bf522d76
- **Timestamp:** 2026-11-14T15:40:26Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** none
