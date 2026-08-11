---
id: T-432
name: "Full fw audit reports 60 FAIL across non-structure sections - never assessed"
description: >
  The pre-push gate runs 'fw audit --sections structure' and has read 19 PASS / 3 WARN / 0 FAIL for weeks. Running the FULL audit during T-431 returned Pass 124 / Warn 33 / Fail 60. Nothing in this project has ever looked at the 60, because the only audit anyone runs is the narrow one the push hook invokes. Unknown whether they are pre-existing, cosmetic, or real. First step is a per-section breakdown, not a fix: 'fw audit' section by section, counting FAILs per section, and a statement of which sections the push gate never runs. Same family as the T-429/T-431 findings - a green that was never the whole question.

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-11T15:41:06Z
last_update: 2026-08-11T20:27:48Z
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

# T-432: Full fw audit reports 60 FAIL across non-structure sections - never assessed

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] A per-section breakdown is produced: for every section `fw audit` supports, the
      PASS/WARN/FAIL counts, recorded in the task — the whole point is the denominator, so
      a total without the split repeats the defect that motivated this task
      **DONE** — see `## Findings`. 18 sections emit output; **all 60 FAILs are in one**.
- [x] The set of sections the **push gate** runs is stated explicitly, alongside the set it
      does not, extracted from the hook rather than retyped from memory
      **DONE** — `.git/hooks/pre-push:306` reads `"$AUDIT_SCRIPT" --section structure`.
      One section of nineteen. Note the flag is `--section`, singular; this task's own
      filing said `--sections`, which is the kind of detail that must be extracted.
- [x] Each FAIL is classified as one of: pre-existing (present before this project's first
      commit to the file it names), self-inflicted, or a check that cannot pass in this
      project by design — with the evidence for the classification, not an assertion
      **DONE** — two classes, both with evidence. See `## Findings`.
- [x] Any FAIL that names a file under `.agentic-framework/` is reported upstream rather
      than fixed locally, per the vendored-tree boundary (T-427, DM 522 §1)
      **DONE — vacuously: zero of the 60 name a file under `.agentic-framework/`.** Stated
      as a measurement rather than left silent, because "nothing to report upstream" and
      "I did not look" render identically in a ticked box.
- [x] No `--force`, no `--skip-*`, and no widening or narrowing of the push gate's section
      list under agent initiative — the gate's scope is an operator decision and this task
      only measures it
      **DONE** — nothing was fixed, migrated or re-scoped. The audit ran read-only with
      `--output` pointed at scratch so it did not overwrite the tracked audit record.

<!-- SCOPE NOTE: this task MEASURES. It does not fix the 60. Deciding which of them are
     worth fixing needs the breakdown to exist first, and bundling the fix into the
     measurement is how a task with an unknown denominator becomes a task with an unknown
     size. Fixes get their own tasks, one root cause each. -->

### Human
- [ ] [REVIEW] Whether the push gate should keep running `--sections structure` only
      **Steps:**
      1. Read the per-section breakdown this task writes into `## Findings`
      2. Decide: (a) leave the gate narrow and treat the rest as advisory, (b) widen it to
         the sections whose FAILs turn out to be real, or (c) widen it fully and fix
         whatever blocks the push
      **Expected:** one of a/b/c recorded here, with a one-line reason
      **If not:** the gate stays as it is and the 60 stay unwatched, which is the status
      quo this task exists to make visible rather than to change unilaterally

## Findings

### The headline: 60 FAILs are 2 problems, not 60

    SECTION                     PASS  WARN  FAIL
    structure                     19     3     0   <-- the ONLY section the push gate runs
    task compliance                1     0     0
    task quality                   1     0     0
    git traceability               2     1     0
    enforcement                    4     0     0
    learning capture               2     0     0
    episodic memory                3     0     0
    observation inbox              1     0     0
    concerns register              2     0     0
    graduation pipeline            1     0     0
    inception research             0     3     0
    research persistence oe        5     0     0
    oe-fast: 30-minute control     4     0     0
    oe-hourly: hourly control      2     0     0
    oe-daily: daily control       73    25    60   <-- every FAIL is here
    oe-weekly: weekly control      1     0     0
    orchestrator arc               1     0     0
    arc-completion                 1     0     0
    TOTAL                        123    32    60

**17 of 18 sections are clean.** The alarming number came from reading a total without its
split — which is the same defect the T-429/T-431 work was about, committed by me in this
task's own filing description. "60 FAIL across non-structure sections" implied breadth.
There is none.

### Class 1 — CTL-030 × 59: pre-existing residue, source already plugged

Every one reads: *`T-NNN is in .tasks/completed/ but stored horizon='now'`*.

Evidence for the classification, in order:

1. **The check is sound.** `audit.sh:3665` (CTL-030, T-2162, arc-009 Slice 3) — completed
   tasks must carry null/absent horizon because render derives `past` from `_location`.
2. **The leak has a known source.** `update-task.sh:1613` auto-promotes `horizon: now` on
   `started-work` (the T-1068 invariant). Every task that is worked on gets the field set.
3. **The source is already plugged**, upstream and in this vendored copy:
   `update-task.sh:1896` writes `horizon: null` at completion, with a comment naming this
   exact defect as a prior *8-instance* CTL-030 class (T-2168/T-2180/T-2182/T-2196/…).
4. **The plug is working here, measured today.** T-427, T-429 and T-431 all completed with
   `horizon: null`.
5. **Denominator:** 374 completed tasks, **315 correct, 59 stale** — so this is 16%
   residue, not a systemic failure.

**Verdict: pre-existing, closed at source, mechanically fixable.** The remedy is a
one-time backfill of 59 completed task files. Not done here — this task measures, and
editing 59 completed records is its own task with its own blast radius.

One nuance worth recording: the 59 are **not** a contiguous historical block. 247 tasks
with *lower* IDs are clean and 68 with *higher* IDs are clean. So "everything before date
X" is the wrong model; what these 59 share is being completed in the window between the
field existing and the plug landing.

### Class 2 — D2 × 1: not a defect, a working signal

    D2: Human review queue — 2 task(s) waiting >30d: T-093(37d) T-178(31d)

This control is *designed* to fail when the queue ages. It is reporting truthfully, and it
clears when the operator reviews T-093 and T-178 — not when anything is fixed.

Counting it alongside the other 59 is itself a category error: one is stale data, the
other is a live queue. A "FAIL count" that sums them answers no question anybody has.

### What this means for the gate decision

Widening the push gate to `oe-daily` today would **block every push** until 59 completed
task files are edited — high cost, and the safety value is near zero because the records
are terminal and the source is plugged. Widening it *after* a backfill would cost nothing
and would catch the next regression of a class that has already recurred 8+ times upstream.

That ordering is a recommendation, not a decision. The Human AC below owns it.

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

### 2026-08-11T15:41:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-432-full-fw-audit-reports-60-fail-across-non.md
- **Context:** Initial task creation

### 2026-08-11T15:41:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
