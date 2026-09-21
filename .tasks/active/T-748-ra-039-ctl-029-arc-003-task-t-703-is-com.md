---
id: T-748
name: "RA-039: CTL-029 arc-003 task T-703 is completable but not closed"
description: >
  Audit reports [WARN] CTL-029: T-703 has all Agent ACs ticked but status='started-work'.
  T-703 is itself arc-003 remediation task RA-007.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [audit-remediation, cycle-1]
components: []
related_tasks: []
arc_id: arc-003
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T07:58:51Z
last_update: '2026-09-21T20:24:53Z'
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
  - ts: '2026-09-21T08:00:51Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 0
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=0
      (no-signal); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T08:01:03Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 5
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=5 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 6
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/task-create/create-task.sh,.context/project/concerns.yaml);
      tier=2 (no-signal); effort=6 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-748: RA-039: CTL-029 arc-003 task T-703 is completable but not closed

## Context

### Verbatim tool output

```
[WARN] CTL-029: T-703 has all Agent ACs ticked but status='started-work' — completable, not closed
```

### The invariant that is not held

T-703 is arc-003's own remediation task RA-007 (101→107 observations pending for more than 7 days). Every Agent acceptance criterion on it is ticked and none is outstanding, yet it is neither closed nor parked: it is `owner: human` and `status: started-work`. The invariant not held is that a task with no outstanding agent work should not be occupying an in-progress state. The structural point is sharper than the warning: the remediation arc has begun generating the findings it exists to remediate, and it cannot clear them itself, because completing an `owner: human` task is not delegated to the agent.

### Root-cause links

One class of four, same root cause. Siblings: T-747 (RA-006), T-749 (RA-012), T-750 (RA-027).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] **BLOCKED — operator-only by this criterion's own words.** T-703 is `owner: human`
      with one open Human AC — *"[REVIEW] Rule on the drain path for the 82
      carried-by-completed-task items"* — queued at `/review/T-703`. Completing an
      `owner: human` task and changing ownership away from human are both outside agent
      authority, and this AC says so itself.

      **It is already in its correct terminal-pending state.** Its own landing commit says
      so in those words: `d82b77a7` — *"T-703 lands partial-complete (owner human, drain
      ruling queued at /review/T-703)"*. There is nothing to reach; it arrived.
- [ ] **BLOCKED — downstream of AC1, and the section name is wrong.** CTL-029 runs under
      `compliance` / `oe-daily`, not `quality`. Third instance in this cycle of an RA-*
      criterion naming a section that does not own its check (T-745 AC1 said `structure`,
      T-747 AC2 said `quality`). Recorded as a generation pattern, not corrected in place.
- [x] **Stated separately, and it is the same defect as T-747's — filed once, at G-075.**

      The question this AC names — should an agent-produced task be born `owner: human` with
      zero Human ACs — **is already closed at the generator.** `create-task.sh:138` refuses
      `--owner human` without `--human-ac` (T-767, operator ruling on SQ-2, 2026-09-21), and
      T-703 itself now carries a real `[REVIEW]` criterion. The originating condition is
      gone and the finding persists, so the defect is in the check.

      **CTL-029 cannot see the partial-complete state.** Its predicate reads only the
      `### Agent` sub-section and fires on `unticked == 0 and ticked > 0`; it never inspects
      `### Human` and never reads `owner:`. CLAUDE.md prescribes exactly the state it
      misreads, and CTL-029's own comment names that state as what it means to exclude.

      **T-703 is the sharper instance of the two.** T-702 had to be shown to be
      partial-complete by inspection; T-703's landing commit uses the term itself —
      *"T-703 lands partial-complete (owner human, drain ruling queued at /review/T-703)"*.
      A check reporting that task as "completable, not closed" is contradicting the commit
      that produced the state.

      **Filed as G-075, not decided, and deliberately not filed twice.** One root cause
      across all four of this cycle's CTL-029 findings (T-747/RA-038, T-748/RA-039,
      T-749/RA-012, T-750/RA-027) gets one register entry — filing it per-instance would
      manufacture four gaps from one defect and make the register count the symptom rather
      than the cause. T-748's contribution to G-075 is the second, stronger instance, which
      is recorded in the entry's scope line.

      Whether partial-complete should be silent or reported under its own label with an
      ageing threshold is a design question about the operator's queue, and it stays theirs.

## Verification

python3 -c "import yaml; c=yaml.safe_load(open('.context/project/concerns.yaml'))['concerns']; assert any(x.get('id')=='G-075' for x in c if isinstance(x,dict)), 'G-075 missing'"
python3 -c "import glob,sys; f=glob.glob('.tasks/active/T-703-*.md')[0]; h=open(f,encoding='utf-8').read().split('### Human')[1]; sys.exit(0 if '- [ ]' in h else 1)"
grep -q 'requires --human-ac' .agentic-framework/agents/task-create/create-task.sh

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
     fw inception decide T-748 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T07:58:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-748-ra-039-ctl-029-arc-003-task-t-703-is-com.md
- **Context:** Initial task creation

test -f /opt/832-Workflow-designer/.tasks/active/$(cd /opt/832-Workflow-designer/.tasks/active && ls | grep -m1 '^T-703-') || test -n "$(ls /opt/832-Workflow-designer/.tasks/completed/ | grep -m1 '^T-703-')"

### 2026-09-21T15:35:15Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
