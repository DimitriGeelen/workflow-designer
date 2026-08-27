---
id: T-613
name: "010-termlink's finished-and-waiting blind spot: does our /approvals enumerate owner-human tasks that are DONE and carry zero unchecked Human ACs?"
description: >
  010-termlink's finished-and-waiting blind spot: does our /approvals enumerate owner-human tasks that are DONE and carry zero unchecked Human ACs?

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-27T08:01:59Z
last_update: 2026-08-27T08:04:02Z
date_finished: 2026-08-27T08:04:02Z
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

# T-613: 010-termlink's finished-and-waiting blind spot: does our /approvals enumerate owner-human tasks that are DONE and carry zero unchecked Human ACs?

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

010-termlink at rail 606/554 offered a check and named us directly: *"832 — this is your 550
rule with the polarity flipped. You had a detector that knew and could not act. This is a
gate that acts and nothing reports it."*

Their measurement: 20 tasks their audit had reported for weeks as "every Agent AC ticked, no
Human AC outstanding, still started-work". They classified 17 as agent-closable, tried to
close 10, and all 10 refused — **the sovereignty gate keys on `owner:`, and they had keyed on
ACs.** 13 of the 20 were `owner: human` and appeared in **no queue at all**: `/approvals`
keys on `count_unchecked_human_acs`, which returns 0 for a task whose work is DONE and which
carries no Human AC.

> A queue keyed on "something is unchecked" cannot see work that is FINISHED and still needs
> a human to end it.

This task fixes nothing. It answers one question with a number: **does that population exist
here?** Zero is a fine answer and costs nothing to have. Non-zero means those tasks are
invisible to the operator today, and the fix is a separate task.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The population is counted from the field the gate actually enforces (`owner:`), not
      from AC state — that inversion is the whole point of their finding. Report the count
      whichever way it comes out, including zero.
      <br>**Evidence: the check hits.** Keyed on `owner: human` + zero unchecked Human ACs:
      **26** tasks. That raw number is wrong to report, though, and the correction matters —
      10 of the 26 are `captured` with **zero** agent ACs ticked, i.e. ordinary unstarted
      backlog, not finished work. Narrowing to the population 010-termlink actually described
      (all agent ACs ticked, at least one, none unticked): **16**.
      <br>T-041, T-093, T-101, T-102, T-105, T-125, T-178, T-195, T-200, T-228, T-264, T-293,
      T-309, T-357, T-440, T-501.
- [x] For any task found, its `/review/<id>` route is fetched and the result recorded. The
      framework prints that route when it refuses a close; 010-termlink measured every one of
      theirs answering 200 while nothing enumerated them. A surface that exists and is not
      enumerated is the defect, so both halves are measured, not just the count.
      <br>**Evidence:** all **16 of 16** `/review/T-XXX` routes answer **200** (20,608 –
      120,279 bytes). The surface exists for every one.
      <br>**But their claim does not fully transfer, and the difference is the useful part.**
      Of the 16, **12 are absent from `/approvals` and 4 are present** (T-195, T-200, T-309,
      T-501 — reached via another surface). So this is not the total blindness they measured;
      it is partial, which is worse to reason about because the queue looks like it covers
      the class.
      <br>**Control:** T-589, which carries 2 unchecked Human ACs, **is** present — so the
      queue works for its own predicate and the 12 absences are the predicate's shape, not a
      broken page. Without that control the absences would be indistinguishable from an
      `/approvals` outage.
      <br>**The one that matters:** T-200 — the release that 001-CashWeb is parked on — is in
      the finished-and-waiting population but IS surfaced. I expected it to be the punchline
      and it is not. Recording that because the reverse would have been an easy story to tell.
- [x] The second half of rail 606 is checked too: do any of our `## Verification` blocks
      invoke a **repo-wide guard runner**, where one unrelated finding gates every task's
      completion? Answered by grepping the verification blocks, not by recollection.
      <br>**Evidence: 0 hits** across every `## Verification` block in `.tasks/*/*.md` for
      `run-guard-layer|guard-layer|guards --all|run-all-guards`. Our verification blocks name
      specific commands. That half of their finding does not reach us — reported as a clean
      negative rather than left unanswered.

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

### 2026-08-27T08:01:59Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-613-010-termlinks-finished-and-waiting-blind.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-aab6257b
- **Timestamp:** 2026-08-27T08:04:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-27T08:04:02Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
