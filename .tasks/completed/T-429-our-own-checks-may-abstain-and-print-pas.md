---
id: T-429
name: "Our own checks may abstain and print PASS - denominator audit"
description: >
  Our own checks may abstain and print PASS - denominator audit

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: [tools/_t418-mutation-check.sh, 
      tools/_t419-carrier-mutation-check.sh, tools/_t420-gate-mutation-check.sh, 
      tools/_t421-drift-mutation-check.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-11T14:06:58Z
last_update: '2026-08-16T12:33:58Z'
date_finished: 2026-08-11T14:27:37Z
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
  - ts: '2026-08-16T12:33:58Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-429: Our own checks may abstain and print PASS - denominator audit

## Context

AEF reported at DM offset 529 §4 that a guard of theirs had **never evaluated a single
task** — it required a field its own introducing commit had added, so its coverage was
11/1325 rows (0.8%) — and it printed `no tasks stalled at threshold 5`, which is the
same sentence a guard that had cleared 300 tasks would print. Their generalisation:

    a verdict must never print without its denominator

That is the same family as this project's own PL-150 ("a report delivered to the wrong
venue and a report never written are the same observable") and T-428's `live == 0`. It
arrived as their finding about their code. This task asks the reciprocal question about
ours, by measurement rather than by agreeing with them: **can any of our instruments
print a pass-shaped verdict having examined nothing?**

The specific local suspicion, which is self-implicating: our mutation/teeth suites end on
`[ "$fail" -eq 0 ] || exit 1`. A suite in which *no leg ran at all* has `fail=0` and
therefore exits 0 — including `tools/_t428-disposition-mutation-check.sh`, written in the
previous session, whose entire purpose is to prove an instrument can move.

## Acceptance Criteria

### Agent
- [x] A census instrument enumerates every `tools/*.sh` suite that keeps a pass/fail
      counter and classifies each as GUARDED (its exit path asserts legs actually ran) or
      UNGUARDED, and it prints its own denominator (examined N of M) so the census cannot
      commit the defect it is auditing
- [x] The census is proven discriminating against a fixture containing both a guarded and
      an unguarded suite in ONE tree — not one fixture per verdict (T-427/T-428: a
      per-file constant passes separate fixtures)
- [x] At least one real UNGUARDED suite is FORCED into the zero-leg condition and its
      actual exit code and printed output are recorded — measured, not inferred from
      reading the exit line
- [x] `tools/_t428-disposition-mutation-check.sh` is in the census and its verdict is
      recorded whichever way it falls
- [x] Every suite the census reports UNGUARDED is either fixed, or listed by name in the
      task with the reason it was left — no silent truncation, no "top N"
- [x] The fix is proven: a fixed suite with its legs disabled exits non-zero, and the same
      suite unmodified still exits 0 (both directions, so the guard cannot be a blanket fail)
- [x] No file under `.agentic-framework/` is modified (asserted in Verification)

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

## Findings

### The measurement

    counter-bearing suites in tools/    35
      guarded before this task           0
      guarded after                     22
      refused, named below              13
    (the census now reports 36 / 23 — it counts this task's own teeth suite,
     which carries the guard it audits for)

**Zero.** Not a guard with thin coverage — no suite in this project had one. Every one ends
on `[ "$fail" -eq 0 ] || exit 1`, and a suite whose legs never ran has `fail=0`.

### Proven by behaviour, not by reading exit lines

`tools/_t429-zero-leg-probe.sh` neuters a suite's assertion helper — found, not assumed:
the first function whose body increments a variable by one — and runs the real file:

    _t428-disposition-mutation-check.sh   before: exit 0, "  pass=0 fail=0"
    _t421-drift-mutation-check.sh         before: exit 0, last line printed was
      "refuses to answer rather than pass when an input is missing."
    _t420-gate-mutation-check.sh          before: exit 0, last line printed was
      "It is not an all-block or an all-allow."

Both of those sentences are true. Both were printed by a run that asserted nothing. The
last one is the summary line of a gate audit.

After the guard, all three: `exit 2`, `ABSTAINED — no legs ran; this is not a pass.` and
unmodified they are still green (`pass=16 fail=0` for T-428's).

### Three defects found inside the instruments built here

1. **The census's first classifier called the verdict line a guard.** It matched `-eq 0`
   near `exit 1`. That line fires when `fail` is NON-zero and is silent in exactly the
   audited case: every token of a guard, the opposite meaning. It reported 16 false
   GUARDED. Fixed by keying on operator AND connective; leg V3 holds it.
2. **The second classifier credited an exit it did not control.** A 4-line proximity
   window — and the statement after a zero-test is, in every one of these files, the
   verdict line's own `|| exit 1`. So a suite that merely PRINTED "nothing ran" and
   returned success classified as guarded. Fixed by extracting the region the test
   actually governs; leg V4 exists for this.
3. **The applier's first fix would have manufactured its own alarm — and it shipped.**
   For fails-only suites it injected a leg counter into the first function whose body
   increments something, which in those files is `fail()`, the failure reporter. A leg
   count driven by the failure reporter reads zero on a fully clean run, so the guard
   would have fired on **every green suite**. `bash -n` caught the syntax accident that
   came with it (one-liner helpers swallow the injected line's comment, taking `}` with
   it) and said nothing about the semantic one.

   **Nine files reverted on the syntax error. Two did not, because on those the injection
   stayed syntactically valid** — `_t418-mutation-check.sh` and
   `_t419-carrier-mutation-check.sh` were written, passed `bash -n`, and were committed in
   `06e8c58` **broken**: `t429_legs: unbound variable` on the first leg, under `set -u`. A
   runtime error is invisible to a syntax check, and I had already written the sentence
   claiming revert-on-failure made the draft cost nothing.

   Caught by **re-running the suites**, which is the verification step whose whole purpose
   is this and which nothing forced me to do. Both restored from `HEAD~1`, both exit 0
   again, and both now sit in the refused list where they always belonged.

Items 1 and 2 are the same class AEF reported at DM 529 §3 (`_git_commit_count_since`
grepping a whole commit message for a task id). Named back to them at 530 as
**mention-vs-instance**: a predicate answering *is the thing named here* when the question
was *is this the thing*.

### The 13 suites deliberately NOT fixed

Twelve tally **only failures**: `_t350-build-only-probe`, `_t400-schema-teeth`,
`_t408-hygiene-teeth`, `_t410-secret-artifact-teeth`, `_t411-census-teeth`,
`_t412-announced-pair-teeth`, `_t414-mutation-check`, `_t416-mutation-check`,
`_t416-qualifier-residue-teeth`, `_t418-attribution-teeth`, `_t418-mutation-check`,
`_t419-carrier-mutation-check`. In those, a clean run and an empty run are identical in the
file's own state, so the guard cannot be written from what is there. Adding a leg counter
means reading how each suite is structured — a judgement per file, which is what defect 3
above proves an applier must not attempt. `_t353-repair-probe` has no identifiable verdict
block.

Carried forward as **T-430**, one suite at a time, each verified in both directions.

Filed as a follow-up rather than forced: an unverified fix to an abstention bug is the same
family as the bug.

### Verification coverage, stated rather than implied

- **Both directions, behaviourally** (legs neutered → exit 2; unmodified → exit 0):
  `_t428-disposition-mutation-check`, `_t421-drift-mutation-check`,
  `_t420-gate-mutation-check`.
- **Still green after the edit, re-run and measured:** `_t344-watch-set-denominator`,
  `_t345-fabric-check-agreement`, `_t350-teeth`, `_t352-teeth`,
  `_t373-defer-revisit-blindspot`, `_t374-audit-honors-exclude`,
  `_t386-drift-remedy-reachable`, `_t387-manifest-fields`, `_t392-drift-shadow-probe`,
  `_t426-gate-misfire-matrix` — all exit 0.
- **Static check only** (`bash -n` + census, and nothing more is claimed):
  `_t351-teeth`, `_t351-shutdown-probe`, `_t352-p011-errexit-probe`,
  `_t381-focus-gate-wedge`, `_t385-python-c-gate-bypass`, `_t389-release-envelope`,
  `_t390-capture-verbs-nulltask`, `_t391-p011-multiline-guard`, `_t396-release-tag-state`.
  These start servers or mutate live focus, task and tag state. `_t351-teeth` was in the
  first re-run batch and had to be killed — it drives `_t351-shutdown-probe`, which stops
  and restarts a real server, and it outlived its own 240s timeout. Re-running the rest is
  a side effect this task has no mandate for.

The two files damaged by the applier's first draft were in the **static-only** column at
the time they were committed. Being in that column is exactly how they got there.

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

bash tools/_t429-guard-teeth.sh
bash tools/_t429-zero-leg-probe.sh tools/_t428-disposition-mutation-check.sh
bash tools/_t428-disposition-mutation-check.sh
python3 tools/_t429-abstention-census.py > /tmp/.t429-verify.out 2>&1; test $? -ne 2
git diff --quiet HEAD -- .agentic-framework

# Note on line 2: the probe exits 0 only when the suite REFUSES to pass with no legs, so
# its own exit code is the verdict and no `; grep` chain is needed (T-352 errexit trap).
# Note on line 4: the census exits 1 while 13 suites remain refused-by-design, so the
# assertion is `not 2` — it must be able to ANSWER, and a future unparseable tools/ tree
# must not read as "nothing found" (same shape as T-428's exit-2 discipline).

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

### 2026-08-11T14:06:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-429-our-own-checks-may-abstain-and-print-pas.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7d577252
- **Timestamp:** 2026-08-11T14:27:43Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-11T14:27:37Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
