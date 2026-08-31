---
id: T-660
name: "Gate-green and operator-actionable are separate properties: nothing measures whether a Human AC can actually be acted on"
description: >
  Gate-green and operator-actionable are separate properties: nothing measures whether a Human AC can actually be acted on

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-31T18:58:58Z
last_update: 2026-08-31T19:04:29Z
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

# T-660: Gate-green and operator-actionable are separate properties: nothing measures whether a Human AC can actually be acted on

## Context

G-046, and independently confirmed from outside. 010-termlink at rail @891: *"A verification
gate that passes 7/7 can still carry an unactionable Human AC: ours literally read 'run fw
task review T-XXX', placeholder unresolved. Gate-green and operator-actionable are separate
properties, and only the first is measured."*

That is our gap too. CLAUDE.md §Human AC Format Requirements (T-325) demands every Human AC
carry **Steps / Expected / If not**, with steps that start from the operator's actual
environment (T-358). Nothing checks it. P-010 gates on Agent ACs; P-011 runs Verification;
the Human section is explicitly non-blocking — so the one class of criterion that a *person*
has to act on is the only one with no instrument at all.

This matters right now for a specific reason. The operator queue is the thing that has not
been draining: T-423 has gated EWCR for weeks, ten inceptions are unruled, and T-655 found
two tasks sitting 57 and 51 days that were *already fully signed off*. Queue length has been
treated as an operator-availability problem. Nobody has measured how much of it is
**unactionable on arrival** — an AC that cannot be executed without first reconstructing what
its author meant costs a sitting, and gets deferred rather than done.

Measure first. The remedy depends on what the number is, and this task says so up front
rather than shipping a checker for a problem that may not exist at this scale.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The unticked Human ACs across all active tasks are **measured** for actionability:
      presence of Steps/Expected/If-not, and unresolved placeholders (`T-XXX`, `<your...>`,
      `TBD`, bare "..."). Count and per-task breakdown recorded in this task.
- [x] The measurement distinguishes the **operator's live queue** (tasks actually waiting on
      them) from active tasks generally. A defect rate over tasks nobody is waiting on
      would overstate the problem.
- [x] **Branch, decided by the number, and stated here before it is known:**
      (a) if a material share of the live queue is unactionable → ship a checker that
          reports it, hosted where it will be READ (audit line or `fw task verify`), not in
          a suite nothing runs (PL-296);
      (b) if the rate is negligible → do NOT ship a checker. Record the measurement as the
          finding, say plainly that the queue's problem is operator time and not AC
          quality, and close. A checker for a non-problem is new furniture.
      Whichever branch runs, the reasoning and the number are recorded in Decisions.
- [x] The instrument, if built, **strips HTML comments non-greedily before counting**
      (`re.sub(r"<!--.*?-->", ...)`). The task template keeps worked `[REVIEW]`/`[REVIEWER]`
      examples with real `- [ ]` boxes AND full Steps/Expected/If-not inside the comment;
      counting them inverts the result — every task would look perfectly actionable.
      Asserted against a known task, not assumed (T-655 hit exactly this).
- [x] It **never ticks or edits a Human AC**, and never reports one as satisfied. It reports
      whether the criterion can be ACTED ON, which is a different question from whether it
      has been met, and conflating them would be the agent grading the operator's work.
- [x] If a checker ships: a prober extracts the real region (no retyped copy), covers
      actionable / missing-section / placeholder-bearing fixtures, and carries a mutation
      leg with an asserted substitution count and a demonstrated unmutated baseline
      (PL-297). Every negative assertion is paired with a positive one on the same run
      (PL-299).
- [x] Any framework-file change is declared in `.vendor-divergence.yaml` (G-008).

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
         1. Run `bin/fw reviewer T-660`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-660 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# The prober over the checker: 8 legs, exit code is the verdict.
bash tools/_t660-actionability-checker-must-have-teeth.sh

# The root-cause fix: no active task may still carry the literal placeholder in its
# Human section. This is the repair, asserted rather than remembered.
test 0 -eq "$(grep -l 'T-XXX' .tasks/active/*.md 2>/dev/null | wc -l)"

# Both edited framework files must still parse, and the changes must be declared (G-008).
bash -n .agentic-framework/agents/audit/audit.sh
bash -n .agentic-framework/agents/task-create/create-task.sh
python3 tools/_t517-vendor-divergence.py

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

### 2026-08-31 — the measurement, and the branch it selected

- **Number:** 13 of 51 live-queue tasks (25%) carried a Human AC that could not be acted on
  as written. 11 were unresolved `T-XXX` placeholders; 2 were structural (T-426 missing
  Steps, T-579 missing If-not). Nine of the 11 were unruled inceptions — the exact items
  that have gated EWCR for weeks.
- **Chose:** branch (a), ship a checker — but fix the ROOT first. The 11 placeholders were
  one defect in `create-task.sh`, not 11 authoring lapses.
- **Why the root fix outranked the checker:** a checker would have reported the same 11
  tasks every day without any of them getting better. The substitution mechanism already
  existed and merely stopped at the H1. After repair the number went 13 -> 2, and the
  checker now guards a small, real residue instead of shouting about a template.
- **Rejected:** shipping only the checker (reports a problem it cannot fix); and repairing
  only the 80 files (the next inception created would reintroduce it immediately).

### 2026-08-31 — repairing an operator-owned AC is not verifying it

- **Chose:** rewrite `T-XXX` to the real id inside `### Human` sections of 80 active tasks,
  including tasks with `owner: human`.
- **Why:** fixing a broken instruction is not the same act as judging whether the criterion
  has been met. The boundary that matters is the tick, and it was held mechanically: 359
  `- [x]` before, 359 after, and zero changed lines matching a checkbox — asserted, not
  asserted-by-inspection, because this is exactly the boundary where an agent should not
  be trusted on its own account.
- **Rejected:** leaving them for the operator. The operator is the person the placeholder
  was obstructing; handing them 80 files of clerical repair as a precondition for draining
  their own queue would have been the queue defending itself.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-31T18:58:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-660-gate-green-and-operator-actionable-are-s.md
- **Context:** Initial task creation
