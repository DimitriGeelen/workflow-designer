---
id: T-630
name: "P-011 reported 'Verification: 2/4 passed' and still returned PASS, completing the task"
description: >
  P-011 reported 'Verification: 2/4 passed' and still returned PASS, completing the task

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
created: 2026-08-29T15:10:44Z
last_update: 2026-08-29T15:13:57Z
date_finished: 2026-08-29T15:13:57Z
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

# T-630: P-011 reported 'Verification: 2/4 passed' and still returned PASS, completing the task

## Context

Observed completing T-629, in the gate's own output:

    === Verification Gate (P-011) ===
    Running 4 verification command(s)...
      PASS: bash tools/_t629-g067-remedy-reachable.sh
      PASS: bash tools/_t628-g020-remedy-reachable.sh
    Verification: 2/4 passed ✓

Two of four commands produced neither a PASS nor a FAIL line, and the gate reported PASS
and completed the task. `verify_fail` stayed 0, and the summary at update-task.sh:1238
is reached whenever `verify_fail` is 0 — it never compares `verify_pass` against
`verify_total`, so a command that is silently never run is indistinguishable from one
that passed. The fraction was printed, in green, next to a tick.

MECHANISM. The runner is `while IFS= read -r cmd; do … eval "$cmd" … done <<< "$verify_cmds"`
(update-task.sh:1189-1220). `eval` inherits the loop's stdin, which IS the herestring
holding the remaining commands. Any verification command that reads stdin consumes the
rest of the list. Those lines were already counted in `verify_total` (computed by `wc -l`
before the loop), so they show up in the denominator and never run.

WHY THIS MATTERS BEYOND THE COSMETIC. It is a false green in the gate that exists to
prevent false greens, and it degrades in the worst possible direction: the more
verification commands a task declares, the more of them a single stdin-reading command
can swallow — and the tick still appears. A task can pass P-011 having executed only its
first command. This is 010's @772 observation ("a runner that executes nothing and a
runner whose every command passed produce the same summary") in a form where the summary
even shows the discrepancy and passes anyway.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] A verification command that reads stdin no longer consumes the commands after it:
      every declared command runs
- [x] `verify_pass + verify_fail == verify_total` is enforced, not assumed. If they
      disagree the gate FAILS rather than printing a fraction with a tick — an
      unexplained gap is a defect in the runner, not a pass
- [x] The green summary line cannot be reached while `verify_pass < verify_total`
- [x] `tools/_t630-p011-stdin-swallow.sh` reproduces the original defect against a
      pinned copy of the pre-fix runner, and shows the fixed runner surviving it
- [x] The prober uses an INVENTED fixture — a verification block whose first command
      reads stdin — which occurs nowhere in our corpus of task files
- [x] T-629's own four-command block, replayed through the fixed runner, reports 4/4

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

# The four commands below are T-629's block verbatim — the one that reported "2/4
# passed" through the pre-fix runner. If this gate now reports 5/5, the fix is proven
# in production and not only against the pinned model in the prober.
bash tools/_t630-p011-stdin-swallow.sh
bash tools/_t629-g067-remedy-reachable.sh
bash tools/_t628-g020-remedy-reachable.sh
bash tools/_t386-drift-remedy-reachable.sh
bash -n .agentic-framework/agents/task-create/update-task.sh

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

**Symptom:** P-011 printed `Verification: 2/4 passed ✓` and completed T-629. Two declared
commands produced neither a PASS nor a FAIL line.

**Root cause:** The runner loop is fed by a herestring and `eval`s each command without
redirecting stdin, so `eval` inherits the loop's own stdin — the list of remaining
commands. Any verification command that reads stdin consumes the rest. `verify_total` is
computed by `wc -l` before the loop, so swallowed lines stay in the denominator and never
run. `verify_fail` stays 0, and the green summary is reached on `verify_fail == 0` alone.

**Why structurally allowed:** two independent omissions had to coincide, and each is
individually defensible. The missing `< /dev/null` is an easy oversight. The summary
never comparing `verify_pass` to `verify_total` is the load-bearing one: it made "never
executed" and "passed" the same outcome. Either alone is survivable — the redirect
without the check leaves any other skip route silent, the check without the redirect
turns the swallow into a loud failure. Neither was present. And the corpus could not have
caught it: no task file we have declares a stdin-reading verification command, so there
was no negative to trip over. It took writing a task whose verification ran four
sub-probers to produce one.

**Prevention:** `tools/_t630-p011-stdin-swallow.sh` pins the pre-fix runner as text and
reproduces the defect against it every run, so the teeth cannot expire the way a
`git show HEAD~1:` anchor does. Distinct from the fix: the fix stops stdin-swallowing,
the reconciliation guard refuses a pass verdict for ANY cause of a missing verdict, and
the prober fails if either half is ever removed from the live gate.

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

### 2026-08-29 — the gate that exists to prevent false greens was producing one

Found by accident: T-629 completed and the summary line said `2/4 passed ✓`. Nothing
alerted; the tick was green and the task moved to completed/. The number was printed
correctly and the verdict drawn from it was wrong.

Worth recording as a shape rather than an incident: A DENOMINATOR IS EVIDENCE ONLY IF
SOMETHING COMPARES IT TO THE NUMERATOR. Printing `2/4` while returning pass is strictly
worse than printing nothing, because it looks like reporting. Three peers converged on
the same family this week from three directions — 010's vacuous `## Verification` (@772
item 5), 577's `!`-inverted leg that passed when the guard crashed (@774 item 5), and
this. In all three the instrument reported success while measuring less than it claimed,
and in all three the tell was the same question: what would this print if it had no
information at all?

Second, smaller, from the prober: my pinned model of the runner initially omitted the
whitespace-trim the real gate performs, and that omission silently removed the very gap
the reconciliation leg was written to detect. A MODEL OF A RUNNER MUST INCLUDE THE STEPS
THAT CREATE THE FAILURE MODE, or it will confirm the fix against a shape that cannot
fail.

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

### 2026-08-29T15:10:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-630-p-011-reported-verification-24-passed-an.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0a5d20af
- **Timestamp:** 2026-08-29T15:14:11Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T15:13:57Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
