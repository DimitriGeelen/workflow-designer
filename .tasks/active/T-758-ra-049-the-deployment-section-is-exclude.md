---
id: T-758
name: "RA-049: the deployment section is excluded from every default audit run"
description: >
  audit.sh:5228 guards the deployment section with [ -n "$SECTIONS" ] && should_run_section
  deployment. It is the ONLY section with that guard; all 18 others use the bare form
  which runs when SECTIONS is empty. So deployment never runs unless explicitly named,
  and RA-042..045 are four FAILs living in a section no routine audit, cron entry
  or pre-push check ever executes.

status: started-work
workflow_type: refactor
owner: agent
horizon: now
tags: [audit-remediation, cycle-2]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T08:47:42Z
last_update: 2026-09-21T08:54:20Z
date_finished:
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
  - ts: '2026-09-21T08:49:29Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 0
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=0
      (no-signal); D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F2=0 
      (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T08:49:29Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 3
      effort: 7
      blast_radius: 1
    rationale: blast_radius=1 (paths:.agentic-framework/agents/audit/audit.sh); 
      tier=3 (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-758: RA-049: the deployment section is excluded from every default audit run

## Context

### Verbatim tool output

```
# audit.sh:5228 — the deployment section
if [ -n "$SECTIONS" ] && should_run_section "deployment"; then

# every other section, e.g. audit.sh:489
if should_run_section "structure"; then

# audit.sh:363
should_run_section() {
    [ -z "$SECTIONS" ] && return 0
    echo ",$SECTIONS," | grep -q ",$1,"
}
```

### The invariant that is not held

`should_run_section` returns true when `$SECTIONS` is empty — that is how a bare
`fw audit` runs everything. The deployment section is the **only** one of nineteen
that adds `[ -n "$SECTIONS" ] &&` in front of it, which inverts the default: it runs
*only* when someone names it explicitly, and is skipped by every unqualified run.

Measured this cycle. The complete 19-section run (`FW_AUDIT_TIMEOUT=3000 fw audit`,
687s, Pass 175 / Warn 31 / Fail 1) contains **zero** occurrences of the string
`deploy`. A run scoped with `--section deployment` reports **four FAILs**.

So RA-042, RA-043, RA-044 and RA-045 are four FAILs that have never appeared in any
audit record, any cron run, or any pre-push check, and never will. They were found
only because this cycle enumerated the section list by hand and ran each one.

The guard is explicit, so somebody wrote it deliberately — most plausibly because
deployment checks are meaningless for a project that does not deploy, and would FAIL
noisily forever. If that is the reason, the mechanism is still wrong: it makes the
check invisible rather than not-applicable, and an invisible check cannot tell you it
stopped being relevant. The distinction matters because it is exactly SQ-1.

### Root-cause links

Parent of RA-042/T-751, RA-043/T-752, RA-044/T-753, RA-045/T-754 — all four live in the section this finding says never runs. Bears directly on SQ-1.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] The intent behind the `[ -n "$SECTIONS" ]` guard is established from history (`git log -S` on that line, or the task that introduced it) rather than inferred from the code alone.
- [ ] If the guard is deliberate, the section is made *explicitly* not-applicable for this project through a named mechanism a reader can find — not left silently skipped. If it is accidental, the guard is removed and the four FAILs become visible findings with owners.
- [ ] Either way, `fw audit --help` or the section list states which sections a bare `fw audit` actually runs. Today it advertises nineteen and runs eighteen.
- [ ] No check is weakened and no scaffolding is created to silence the four FAILs. Whether this project deploys at all is SQ-1 and stays with the operator.

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

grep -q '\[ -n "\$SECTIONS" \] && should_run_section "deployment"' .agentic-framework/agents/audit/audit.sh
test "$(grep -cE '\[ -n "\$SECTIONS" \] && should_run_section' .agentic-framework/agents/audit/audit.sh)" -eq 1

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
     fw inception decide T-758 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T08:47:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-758-ra-049-the-deployment-section-is-exclude.md
- **Context:** Initial task creation

### 2026-09-21T08:54:20Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
