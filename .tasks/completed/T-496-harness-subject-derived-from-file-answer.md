---
id: T-496
name: "harness subject derived from __file__ answers confidently about the wrong subject when moved"
description: >
  Three instances in one week (T-494 EXPECTED_LABEL, T-495 probe copy x2, plus AEF's independent instance at rail 617 §3): a harness that derives its subject from its own file location is copied elsewhere to serve as a counterfactual, resolves the wrong subject, and returns an exit code shaped exactly like the right answer. Fires only when someone is being careful enough to run a counterfactual. Prevention: derive-then-assert.

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
created: 2026-08-14T08:00:16Z
last_update: 2026-08-14T08:04:37Z
date_finished: 2026-08-14T08:04:37Z
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

# T-496: harness subject derived from __file__ answers confidently about the wrong subject when moved

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Context

Deriving a root from `__file__`/`BASH_SOURCE` is the CORRECT idiom — it is why the T-420
gate's expected label is derived rather than typed, and why the same one-line rule explains
both projects' labels. Nothing here argues against it. The defect is what happens when such
a harness is COPIED somewhere else, which is the one thing you do when you want to prove a
control discriminates: it silently re-derives a different root, resolves a different
subject, and returns an exit code shaped exactly like the right answer.

Three instances in one week here, plus one independently in AEF (rail 617 §3 item 2):

  T-494  the attribution gate derives EXPECTED_LABEL from basename(dirname(dirname(
         __file__))). A pre-change copy in the scratchpad expected the SESSION UUID as
         the project label and reported "the old gate blocked valid posts" — a regression
         against my own gate, about to be published.
  T-495  same move to plant a deliberate fault in a probe. PROJECT_ROOT resolved to the
         scratchpad, the census it imports was not there, and it exited 1 — the exit code
         the leg wanted, produced by an import error rather than by the assertion.
  T-495  (second) the same again minutes later, caught only because the expected output
         lines were missing rather than because the exit code was wrong.
  AEF    root resolved to `/`, the binary did not exist, one leg went red and looked
         like signal.

**The class only fires when someone is being careful.** Nobody hits it running the tool
normally. It fires precisely at the moment you decide to run a counterfactual — so the
better the method, the greater the exposure. And the wrong answer is indistinguishable
from the right one, because "differs from the current version" is what a counterfactual is
supposed to return.

Nothing about this class is registered: `concerns.yaml` and `learnings.yaml` have no entry
for it. That is unusual for this week — the previous four tasks all found the thing already
existed — and it is the reason this one is worth building rather than scheduling.

## Acceptance Criteria

### Agent
- [x] The exposed population is MEASURED and the denominator stated: how many harnesses
      derive a root from their own location AND resolve a subject beneath it, split by
      whether they verify the subject exists before using it. No hand-typed count.
      → **70 total; 42 verify the subject; 28 do not.** (Python only; the shell half is
      not measured and is stated as unmeasured below, not implied to be zero.)
- [x] The two known instances refuse instead of answering: `_t420-rail-attribution-gate.py`
      (derived label) and `_t495-prose-edge-probe.py` (derived census path). Refusal is
      exit 2 — an abstention, NOT a verdict — because exit 1 is the answer a counterfactual
      is trying to produce, and the whole defect is the two being indistinguishable.
      The gate is the exception that proves the rule: its fail-open contract is
      load-bearing for the SESSION, so its check must not wedge a real call.
      → Probe: `refuse_if_subject_missing()`, exit 2. Gate: cannot refuse (its exit
      contract has only allow=0 and block=2, and blocking on self-doubt is the session
      wedge), so it prints a loud stderr diagnostic naming the derived root and the
      derived label on every call, and keeps its contract intact.
- [x] Negative controls, each red for its own reason: the guarded harness refuses when run
      from a wrong root, and still produces its normal verdict when run in place. Run the
      counterfactual from a path SHAPED like the real one, not from the scratchpad — the
      failure this task is about is exactly what running it from the scratchpad produces.
      → Probe in place rc=0; probe copied out rc=**2** (was rc=1 on an ImportError, the
      exact collision this fixes). Gate in place: blocks unattributed (2), allows
      attributed (0), no warning. Gate copied out: **blocks the attributed post (2) that
      the in-place gate allows** — T-494's false regression reproduced on demand, now with
      stderr saying `derived label: 't496'`.
- [x] The class-level gap is REGISTERED with its measurement, and it is stated plainly
      whether a population-wide guard was built or not. Fixing two members of a 95-file
      class and calling it closed is PL-139 with the count in hand.
      → Registered as a learning and a failure pattern with the 28/70 measurement.
      **A population-wide guard was NOT built** — see Decisions.
- [x] Bridge suite still green (74 passed / 0 failed at T-495).

**Found while running the controls, and it belongs in the record:**
- [x] My own control instrument was wrong, in the task about instruments being wrong.
      `echo "$IN" | python3 gate.py 2>&1 | head -4` then reading `${PIPESTATUS[0]}` reports
      the **echo's** exit code, not the gate's — `[0]` is the first stage of a three-stage
      pipeline. It reported the gate as rc=0 where it was rc=2. Re-measured by dropping the
      pipeline entirely and reading `$?` from the stage under test.

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
#
# No pipelines below. The control that measured this task's own subject read
# ${PIPESTATUS[0]} out of a three-stage pipeline and reported the FIRST stage's exit
# code as the gate's verdict. Each line here is a single command whose own exit code
# is the verdict, which is what the errexit warning above asks for anyway.

python3 tools/_t495-prose-edge-probe.py
bash tools/_t426-gate-misfire-matrix.sh
bash tools/_t420-gate-mutation-check.sh
python3 tools/_t451-unwired-guard-census.py --ratchet

## RCA

**Symptom:** a harness copied out of the tree to serve as a counterfactual returns a
confident verdict about a different subject, and the verdict is shaped exactly like a
correct one. Four instances in a week: T-494 (gate derived the session UUID as the project
label and reported "the old gate blocked valid posts" — one step from being published as a
regression), T-495 twice (probe copies exited 1 on an ImportError, the code the leg wanted),
and AEF independently at rail 617 §3 (root resolved to `/`).

**Root cause:** the harness derives its root from `__file__`/`BASH_SOURCE` — correct, and
deliberately so; it is why the T-420 label is derived rather than typed — and then resolves
its subject beneath that root WITHOUT asserting the subject is there. Location is an input,
and it was the one input nothing validated.

**Why structurally allowed:** the class is invisible in normal operation. Run in place,
every one of these 70 harnesses is correct forever. It fires only when someone copies the
file, and the only reason to copy the file is to run a counterfactual — so exposure is
proportional to method quality. Worse, the failure's signature collides with success:
a counterfactual EXPECTS the copy to behave differently from the current version, and
`exit 1` from an ImportError is indistinguishable from `exit 1` from a failing assertion.

**Prevention:** derive-then-assert, with the abstention on an exit code the verdict cannot
produce (2, never 1) — implemented for both known instances, plus a stderr diagnostic on
the gate where the exit contract has no room for a third state. Recorded as a learning and
a failure pattern with the denominator (28 of 70 Python harnesses unguarded; shell half
unmeasured). **This is a member fix with the class named and counted, not a class
closure** — see Decisions for why a population-wide guard was refused rather than skipped.

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

### 2026-08-14 — no population-wide guard, and saying so is the point
- **Chose:** Guard the two known instances; measure and register the class; do NOT build a
  census over the other 26.
- **Why:** A guard here would have to decide, per file, whether a resolved path is a
  SUBJECT (must exist, refuse if not) or an optional output path — that is intent, and
  guessing at intent produces the confident-but-unfounded verdict T-440 was about. It
  would also be the fourth census over `tools/*` in this tree, and T-491's lesson was that
  two censuses of one population is a reintroduction shape with a different unit; the
  second one always rots.
- **Rejected:** Adding `--assert-subject` to all 28. Also rejected: a shared helper module
  — importing it requires resolving a path from `__file__`, so the helper has the defect it
  exists to fix, in every caller.
- **Stated, not implied:** 28 of 70 remain unguarded, and the SHELL half of the population
  was not measured at all. This is a member fix with the class named, not a class closure.

### 2026-08-14 — the gate warns, the probe refuses, and the difference is its exit contract
- **Chose:** Different remedies for the two instances.
- **Why:** The probe's exit codes are its own, so it can take 2 as abstention. The gate's
  are the PreToolUse contract — 0 allow, 2 block, no third — so "I doubt my own location"
  has nowhere to go. Blocking every call on self-doubt is precisely the session wedge the
  fail-open doctrine forbids. Loud on stderr, contract untouched: a harness capturing
  stderr sees it, the live hook path is unaffected because a real checkout never trips it.
- **Rejected:** Making the gate exit 2 on an implausible root. That is a wedge triggered by
  the gate's own uncertainty, which is worse than the miss it prevents.

### 2026-08-14 — exit 2, never exit 1, for the abstention
- **Chose:** The probe abstains with 2.
- **Why:** 1 is the answer the counterfactual is trying to produce. Both T-495 incidents
  exited 1 on an ImportError and that WAS the code the harness wanted, so "the leg went
  red" and "the tool could not run" were the same observable. An abstention has to use a
  code the verdict cannot produce, or it is not an abstention (T-430).
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

### 2026-08-14T08:00:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-496-harness-subject-derived-from-file-answer.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-52ee5650
- **Timestamp:** 2026-08-14T08:04:42Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-14T08:04:37Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
