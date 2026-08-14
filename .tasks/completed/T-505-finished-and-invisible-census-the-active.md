---
id: T-505
name: "Finished and invisible: census the active tasks whose ACs are all ticked but which never transitioned"
description: >
  Finished and invisible: census the active tasks whose ACs are all ticked but which never transitioned

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
created: 2026-08-14T20:26:52Z
last_update: 2026-08-14T20:33:09Z
date_finished: 2026-08-14T20:33:09Z
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

# T-505: Finished and invisible: census the active tasks whose ACs are all ticked but which never transitioned

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] AC1 — `tools/_t505-finished-invisible-census.py`. Derived: 68 files scanned from
      `.tasks/active/*.md`, 68 with a countable AC block, 0 skipped. Zero is distinguished
      from unparseable — a task with an AC heading but no checkboxes is SKIPPED with that
      reason printed, never counted as "all ticked" (an empty box set is vacuously complete,
      which is the PL-151 / `every()`-over-empty shape in a third costume).
      The population is DERIVED, not hand-listed: an instrument enumerates every task
      in `.tasks/active/`, counts its `## Acceptance Criteria` checkboxes split by the
      `### Agent` / `### Human` sub-headings, and reports the ones where the count is > 0 and
      every box is ticked while `status` is not `work-completed`. A zero count must be
      distinguishable from "no checkboxes found" — PL-151, `grep -c` exits 1 on zero.
- [x] AC2 — `DENOMINATOR: 68 task file(s) scanned, 68 with a countable AC block, 0 skipped`
      prints on every run, before any verdict, and the tool REFUSES (exit 2) rather than
      reporting a clean board when the parsed count is 0. Refusal path exercised against an
      empty fixture: exit 2, "Nothing was measured; this is not a pass."
      The instrument states its own denominator on every run (tasks scanned, tasks with
      parseable AC blocks, tasks skipped and why). A census that prints only its hits cannot
      be told apart from one whose scan was empty — the T-503/T-233 `every()`-over-empty shape.
- [x] AC3 — Both directions run, on real data and on fixtures, results below. Real: T-264
      (5/5, 1/1, `started-work`) IS reported; T-433 and T-340, both with an unticked Human
      AC, are NOT — and the tool demonstrably *sees* them, since they are inside the
      denominator of 68. Fixture (`T505_ROOT`, the tool's designed relocation path — the
      subject is the task tree, not the tool's own location, which is why this is not the
      T-495 trap): all-ticked reported, one-unticked declined, template-comment case
      reported. Third fixture measured separately: without comment-stripping it shows 4
      boxes / 2 unticked and would be EXCLUDED; with it, 2 boxes / 0 unticked and correctly
      included. The stripping is load-bearing and now measured rather than claimed.
      Teeth demonstrated by negative control, not asserted: a task known to be in the
      finished-and-invisible state (T-264 — 5/5 Agent, 1/1 Human, `status: started-work`) is
      reported, AND a task known NOT to be in it (one with an unticked Human AC, e.g. T-433)
      is NOT reported. Both directions run and recorded, because a census that lists
      everything and a census that lists the right things read identically on a hit.
- [x] AC4 — Delivered in the session message and in the table below: every row carries its
      Agent/Human AC counts, status, owner and which of the two states it is in. Verification
      outcomes attached where already obtained rather than claimed for all 17: T-264 re-run
      in full today (4 static legs + 8-leg CDP harness, green); T-041 / T-101 / T-102
      pre-flighted green under T-502 (4/4, 5/5, 2/2). The other thirteen carry their recorded
      state only, and that is stated rather than papered over.
      The result is handed to the operator as a list with per-task evidence (AC counts
      and the `## Verification` outcome where cheap to obtain), not as a bare task-id list.
      Per the Human Task Completion Rule, "batch-close stale tasks" is exactly what this must
      not become — each row must carry the evidence that justifies closing THAT task.
- [x] AC5 — Zero tasks transitioned by this task. No `--status work-completed` was run
      against any of the 17, no ownership changed, no Human AC ticked. The tool has no
      close mode and the docstring says why building one would be the forbidden thing.
      Nothing is closed by this task. Every task the census finds is `owner: human` or
      carries a Human AC; transitioning them is not delegated. The deliverable is the list and
      the evidence, and the commands are put in front of the operator.

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

# --- T-505 ---
# The census runs and establishes a population. Exit 2 (refusal) and exit 0 (verdict) are
# distinct states; this leg fails on either a crash or a refusal.
python3 tools/_t505-finished-invisible-census.py
# It has a standing caller, so it cannot go dark the way T-355's probe did (PL-161).
grep -q '_t505-finished-invisible-census.py' tests/run-bridge-tests.sh
# Positive control on real data: T-264 is in the finished-and-invisible set.
out=$(python3 tools/_t505-finished-invisible-census.py --json 2>&1); echo "$out" | grep -q '"task": "T-264"'
# Negative control on real data, and this is the leg that makes the one above mean
# something: T-433 carries an unticked Human AC, sits inside the same denominator, and
# must NOT appear. A census that listed everything would pass the positive leg alone.
out=$(python3 tools/_t505-finished-invisible-census.py --json 2>&1); ! echo "$out" | grep -q '"task": "T-433"'
# The unwired-guard backlog did not grow by adding this tool.
python3 tools/_t451-unwired-guard-census.py --ratchet
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"

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

### 2026-08-14 — 17 of 68. A quarter of the active board is finished and unlisted [agent]

**Result.** 68 task files in `.tasks/active/`, 68 with a countable AC block, 0 skipped.
**17 have every acceptance criterion ticked and are still sitting in `active/`.**

    never-transitioned (status: started-work, ACs complete)   15
      T-041  T-101  T-102  T-105  T-125  T-195  T-200  T-228
      T-264  T-293  T-309  T-344  T-357  T-402  T-440
    transitioned-but-not-archived (status: work-completed)     2
      T-093  T-178

Four of them — **T-200, T-344, T-402, T-440** — carry *no Human AC at all*. There is nothing
for anyone to review; their Agent ACs are complete and they were simply never transitioned.
They are `owner: human`, so closing them is still not delegated, but they are the cheapest
rows here: pure bookkeeping, no judgement required.

**Why none of this was visible.** `fw task verify` enumerates tasks by their UNCHECKED Human
ACs — the right surface for "what does the operator still owe", and structurally unable to
answer the complement. A task drops out of that listing at the exact moment it becomes
closable. T-264 is the sharpest witness: built 2026-07-27, reviewer verdict PASS, Human
`[REVIEW]` ticked *by the operator*, and its full Verification block re-run green today
(4 static legs + the 8-leg CDP harness). Eighteen days invisible, listed by nothing.

**This is the third instance of one shape in two days, and that is the reason it was worth
building an instrument rather than reporting T-264 alone.** T-209 and T-353 carry DEFER
rulings as prose, which no instrument scans (PL-145). T-340 carries a correctly-recorded
ruling in a task that never moved to `owner: human`, so no queue lists it (T-487, today).
Here, seventeen tasks are complete and unlisted. Same class each time: **the record is
right and the surface that would show it is looking somewhere else.**

**What this task deliberately did not do.** No task was closed, no ownership changed, no
Human AC ticked. The tool has no close mode. Seventeen rows is exactly the size at which
"batch-close stale tasks" becomes tempting and it is the move the Human Task Completion
Rule names as forbidden — each row needs its own evidence, and I have that evidence for
four of them (T-264 re-run today; T-041/T-101/T-102 pre-flighted under T-502) and not for
the other thirteen. Stated rather than smoothed over.

**Scope honesty.** The census was not on the arc. It came out of picking up T-264 as arc
work and finding it already built — and T-228, the alternative I had offered for the same
slot, is in the list too. Two of two candidate build tasks were already finished. That is
the argument for measuring the population before choosing the next one, which is what this
is; the arc work resumes after it.

### 2026-08-14T20:26:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-505-finished-and-invisible-census-the-active.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-50bdacf0
- **Timestamp:** 2026-08-14T20:35:04Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 12
     - evidence: `out=$(python3 tools/_t505-finished-invisible-census.py --json 2>&1); ! echo "$out" | grep -q '"task": "T-433"'`

### 2026-08-14T20:33:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
