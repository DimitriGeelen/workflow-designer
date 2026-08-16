---
id: T-454
name: "Approvals queue regrew to 14 NO-REC of 32 handed-over tasks while its guard
  could not run"
description: >
  The consequence T-450/T-451 uncovered rather than the defect. tools/_norec-verify.py
  last ran 2026-07-22 at 0 NO-REC (T-236's sweep) and could not run again, because
  its only call site is that completed task's Verification block. Measured 2026-08-12:
  450 task files examined, 32 carry pending Human ACs, 14 of those have no parseable
  Recommendation verdict - so the operator's review queue shows 32 items of which
  14 offer nothing actionable. The list: T-209 T-286 T-340 T-341 T-344 T-345 T-347
  T-358 T-392 T-402 T-422 T-426 T-432 T-433. Four are arc blockers whose Agent ACs
  are literally marked BLOCKED pending a REVIEW ruling (T-340 T-341 T-358 T-209),
  so the missing verdict is load-bearing for arc designer-authoring-surface. Deliverable
  is an evidence-based Recommendation block per task in the T-236 style - GO with
  cited evidence, NO-GO, or DEFER with a revisit_at - written by the agent and RULED
  by the operator. Not a batch-close: each needs its own evidence per CLAUDE.md Human
  Task Completion Rule. Sized for a fresh window; 14 tasks each needing their own
  evidence read is not a tail-end-of-session job.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_norec-verify.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T10:59:28Z
last_update: '2026-08-16T13:57:23Z'
date_finished: 2026-08-12T12:18:52Z
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
  - ts: '2026-08-16T12:33:59Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-454: Approvals queue regrew to 14 NO-REC of 32 handed-over tasks while its guard could not run

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] Each of the 14 carries a `## Recommendation` block with a parseable verdict
      (GO / NO-GO / DEFER) and **cited evidence** — a file that exists, an endpoint that
      responds, a command whose output is quoted. No verdict without evidence, per
      CLAUDE.md §Human Task Completion Rule
- [x] The four arc blockers (T-340, T-341, T-358, T-209) are done FIRST and each states
      explicitly what the operator's `[REVIEW]` ruling would unblock, since their Agent
      ACs are marked BLOCKED pending it
- [x] Every DEFER carries a `revisit_at` date — a DEFER without one is invisible to the
      G-053 daily scan and is how T-155 ended up parked with nothing to fire on
      — **VACUOUS, and saying so rather than ticking it silently.** The 14 verdicts came
      out GO ×11, NO-GO ×1 (T-344), ABSTAIN ×2 (T-341, T-358). **Zero DEFERs**, so this
      criterion ranges over an empty set and its tick carries no information. A green
      computed from a population of nothing is the exact defect (G-034) that produced this
      whole task, and it would be a poor joke to close the task by committing it.

- [x] **The verdict distribution is stated, not just the pass count.** GO 11 / NO-GO 1 /
      ABSTAIN 2 / DEFER 0. Added during the work: an all-GO sweep and a considered sweep
      are indistinguishable from `rc 0`, and 14-for-14 GO would have been the signal that
      I was clearing a queue rather than reading it.
- [x] `python3 tools/_norec-verify.py` returns rc 0 with a line naming the scope, and the
      scope shows 32-or-more with pending Human ACs — i.e. the queue is CLEAN, not EMPTY.
      An rc 0 whose `with pending Human ACs` count has *fallen* means tasks were closed
      rather than given verdicts, which is the opposite of the deliverable
- [x] No `### Human` AC is ticked and no task is closed by this work — writing the
      recommendation is the agent's half; ruling on it is the operator's

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

# 1. The queue carries no SILENT gap. rc 0 is the whole verdict of this line.
python3 tools/_norec-verify.py
# 2. THE TRAP-PIN. rc 0 above is only a win if the SUBJECT population held. An rc 0 whose
#    "with pending Human ACs" count has FALLEN means tasks were closed rather than given
#    verdicts — the batch-close this task exists to argue against. 32 was the count when
#    the work started; >= 32 means clean, < 32 means emptied.
n=$(python3 tools/_norec-verify.py 2>&1 | grep -oE '[0-9]+ with pending Human ACs' | grep -oE '^[0-9]+'); test "$n" -ge 32
# 3. The ABSTAIN vocabulary extension survives. Without it, a task where withholding a
#    recommendation is the CORRECT agent behaviour can satisfy the guard only by
#    manufacturing one — which happened once, live, during this task (see T-341).
grep -q "GO|NO-GO|DEFER|ABSTAIN" tools/_norec-verify.py
# 4. The guard still refuses an unreadable corpus rather than reporting it clean (T-450).
#    Run from an empty directory: rc must be 2, never 0.
R="$PWD"; D=$(mktemp -d); (cd "$D" && python3 "$R/tools/_norec-verify.py" > /tmp/.t454-refuse.out 2>&1); test $? -eq 2
grep -q "REFUSING" /tmp/.t454-refuse.out

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

### 2026-08-12T10:59:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-454-approvals-queue-regrew-to-14-no-rec-of-3.md
- **Context:** Initial task creation

### 2026-08-12T11:00:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4c506099
- **Timestamp:** 2026-08-12T12:18:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T12:18:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
