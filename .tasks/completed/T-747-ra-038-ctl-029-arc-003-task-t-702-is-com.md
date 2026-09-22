---
id: T-747
name: "RA-038: CTL-029 arc-003 task T-702 is completable but not closed"
description: >
  Audit reports [WARN] CTL-029: T-702 has all Agent ACs ticked but status='started-work'.
  T-702 is itself arc-003 remediation task RA-006.

status: work-completed
workflow_type: build
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
created: 2026-09-21T07:58:48Z
last_update: 2026-09-22T22:11:25Z
date_finished: 2026-09-22T22:11:25Z
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
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/task-create/create-task.sh,.context/project/concerns.yaml);
      tier=2 (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-747: RA-038: CTL-029 arc-003 task T-702 is completable but not closed

## Context

### Verbatim tool output

```
[WARN] CTL-029: T-702 has all Agent ACs ticked but status='started-work' — completable, not closed
```

### The invariant that is not held

T-702 is arc-003's own remediation task RA-006 (34→36 urgent observations still pending in the inbox). Every Agent acceptance criterion on it is ticked and none is outstanding, yet it is neither closed nor parked: it is `owner: human` and `status: started-work`. The invariant not held is that a task with no outstanding agent work should not be occupying an in-progress state. The structural point is sharper than the warning: the remediation arc has begun generating the findings it exists to remediate, and it cannot clear them itself, because completing an `owner: human` task is not delegated to the agent.

### Root-cause links

One class of four, same root cause. Siblings: T-748 (RA-007), T-749 (RA-012), T-750 (RA-027).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **RESOLVED (T-833) — was: BLOCKED — operator-only by this criterion's own words.** T-702 is `owner: human`
      with one open `[REVIEW]` Human AC, queued at `/review/T-702`. Completing an
      `owner: human` task and changing ownership away from human are both outside agent
      authority, and this AC says so itself. Marked BLOCKED rather than left looking merely
      undone, so the task reads as waiting rather than as unstarted (same convention as
      T-340, T-358).

      **Nothing for the operator to do here beyond the existing review.** T-702 is already
      in its correct terminal-pending state; it is CTL-029 that is wrong about it. See AC3.
- [x] **RESOLVED (T-833) — was: BLOCKED — downstream of AC1, and the section name is wrong.** CTL-029 does not
      live in `--section quality`; it runs under `compliance` / `oe-daily` (audit.sh, the
      CTL-029 block). Same defect shape as T-745's AC1, which named `--section structure`
      for a check that is not in it — these RA-* criteria were written from the warning text
      and inherited a section attribution that was never checked.

      Recorded rather than silently corrected, because two independent instances in one
      cycle is a pattern in how this arc's tasks were generated, not a typo.
- [x] **Stated separately — and the generic defect is not the one this AC names.**

      **The anticipated defect is already closed, at the generator.** "Should an
      agent-produced task be born `owner: human` with zero Human ACs" was answered by T-767
      and enforced in code: `create-task.sh:138` refuses `--owner human` without
      `--human-ac` — *"BLOCKED: --owner human requires --human-ac"*, Policy: T-767, operator
      ruling on SQ-2, 2026-09-21. I hit that gate live today while probing an unrelated bug.
      The instances were remediated too: T-702 and T-703 each now carry a real Human AC.

      **So the condition that produced these four findings no longer exists, and the
      findings persist. That is the actual generic defect, and it is in the check.**

      CTL-029's predicate selects the `### Agent` sub-section, counts ticked/unticked in it,
      and fires on `unticked == 0 and ticked > 0`. **It never reads the `### Human` section
      and never reads `owner:`.** So it cannot distinguish an abandoned task from one that
      has correctly partial-completed to the operator — which CLAUDE.md prescribes verbatim:
      *"When agent ACs pass but human ACs remain unchecked, the task enters partial-complete:
      stays in active/ with owner: human."*

      T-702 is in exactly that state, deliberately, since commit `e854f069` — *"T-702 handed
      to the operator (R-033 refused agent completion; review queued at /review/T-702)"*.

      The remedy the warning prints seals it: `bin/fw task update T-702 --status
      work-completed`, addressed to whoever reads the audit, on a task the agent may not
      complete. The check instructs its most automatable reader to do the one thing that
      reader is forbidden to do.

      **Filed as G-075, not decided.** Whether partial-complete should be silent or reported
      under its own label with an ageing threshold is a design choice about what the
      operator's queue shows. Its closure condition requires BOTH directions — the
      partial-complete task stops appearing AND a genuinely abandoned one still does —
      because a check that stopped reporting everything would satisfy the first alone.

      One gap for all four siblings (T-747/RA-038, T-748/RA-007, T-749/RA-012, T-750/RA-027):
      same root cause, registered once.

## Resolution (T-833)

**The finding was wrong about the task, and the defect was in the control.** This task's own
AC3 already said so — *"T-702 is already in its correct terminal-pending state; it is CTL-029
that is wrong about it."* What was missing was the fix, not the diagnosis.

CTL-029 fired on `unticked == 0 and ticked > 0` across the `### Agent` section alone, reading
neither `owner:` nor `### Human`. It could not distinguish an abandoned task from one that had
correctly partial-completed to the operator — the state CLAUDE.md prescribes verbatim. T-702 is in
exactly that state, deliberately.

Fixed in `.agentic-framework/agents/audit/audit.sh` (T-833): the control now skips a task that
is `owner: human` AND carries at least one unticked criterion under `### Human`. Narrow by
construction, with four control branches proving it still fires on an abandoned agent-owned
task, on an `owner: human` task whose Human ACs are all ticked, and on `owner: human` with no
`### Human` section at all.

T-702 WAS NOT CLOSED and did not need to be. Its `[REVIEW]` criterion is classified `taste` by
`tools/_t770-delegation-boundary.py` — *"genuine human judgement... never convertible"* — so no
reviewer verdict could have closed it either. The operator authorised reviewer-gated closure for
low-risk items; this was not one, and the correct answer was to stop manufacturing the warning.

Declared as a vendor divergence and upstreamed to AEF under G-008 — this is framework
behaviour, not project-local policy.

## Verification

python3 -c "import yaml; c=yaml.safe_load(open('.context/project/concerns.yaml'))['concerns']; assert any(x.get('id')=='G-075' for x in c if isinstance(x,dict)), 'G-075 missing'"
grep -q 'requires --human-ac' .agentic-framework/agents/task-create/create-task.sh
python3 -c "import glob,sys; f=glob.glob('.tasks/active/T-702-*.md')[0]; t=open(f,encoding='utf-8').read(); h=t.split('### Human')[1]; sys.exit(0 if '- [ ]' in h else 1)"

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

### 2026-09-23 — the finding was valid, its premise was not, and the fix was one level up

- **What changed:** this task was filed as "T-702 is completable but not closed", implying the
  remedy was to close T-702. It is not. T-702 is `owner: human` in the partial-complete state
  CLAUDE.md prescribes, and its one open criterion is `[REVIEW]` — classified `taste` by the
  delegation boundary, *"genuine human judgement... never convertible"*. No agent action and
  no reviewer verdict could ever have closed it. **The remedy the task named did not exist.**
- **Plan impact:** the deliverable moved from "close T-702" to "stop the control from
  manufacturing a warning that cannot be acted on". AC3 had already reached that conclusion
  and stopped at the diagnosis; T-833 supplied the fix — CTL-029 now reads `owner:` and the
  `### Human` section, which it never did.
- **What that says about the generator:** this task and its sibling T-748 were produced from the
  warning TEXT rather than from the condition. Two tasks, both unactionable by construction,
  both correctly marked BLOCKED by the agent that picked them up rather than forced green.
  Marking them blocked was right; leaving the control alone was the gap.
- **Triggered:** T-833 (the CTL-029 fix, its four control branches, and the vendor-divergence
  declaration), plus an upstream request to AEF under G-008 — this is framework behaviour and
  every project vendoring it inherits the same undoable warnings.



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
     fw inception decide T-747 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T07:58:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-747-ra-038-ctl-029-arc-003-task-t-702-is-com.md
- **Context:** Initial task creation

test -f /opt/832-Workflow-designer/.tasks/active/$(cd /opt/832-Workflow-designer/.tasks/active && ls | grep -m1 '^T-702-') || test -n "$(ls /opt/832-Workflow-designer/.tasks/completed/ | grep -m1 '^T-702-')"

### 2026-09-21T15:32:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-bb0f7639
- **Timestamp:** 2026-09-22T22:11:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T22:11:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
