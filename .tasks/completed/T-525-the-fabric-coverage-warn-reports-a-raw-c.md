---
id: T-525
name: "the fabric coverage WARN reports a raw count that rises while coverage improves, and cannot distinguish source growth from card deletion"
description: >
  the fabric coverage WARN reports a raw count that rises while coverage improves, and cannot distinguish source growth from card deletion

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
created: 2026-08-15T15:22:43Z
last_update: 2026-08-15T15:36:18Z
date_finished: 2026-08-15T15:36:18Z
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

# T-525: the fabric coverage WARN reports a raw count that rises while coverage improves, and cannot distinguish source growth from card deletion

## Context

`audit.sh:1542` warns `Fabric: <registered> registered, <unregistered> unregistered (of <watched>
watched)` whenever `unregistered > 0`. The **existence** of this warning is not the defect — the
`watch-patterns.yaml` header records it as the standing WARN the operator's T-344 `[REVIEW]`
explicitly accepted, and "fixing" it away would overturn a ratified decision. What the warning
**says** is the defect.

**Measured from this project's own audit history**, oldest first:

| date | registered | watched | unregistered | coverage |
|---|---|---|---|---|
| 08-08 | 17 | 161 | 147 | 10.6% |
| 08-10 | 35 | 186 | 154 | 18.8% |
| 08-12 | 40 | 209 | 172 | 19.1% |
| 08-13 | 40 | 217 | 180 | 18.4% |
| 08-14 | 40 | 222 | 185 | 18.0% |
| 08-15 | 54 | 240 | 189 | 22.5% |

**Coverage more than doubled while the headline number rose 147 → 189.** The figure the operator
reads moves in the opposite direction from the property it is about, because `unregistered` is a
difference between two independently moving quantities and only one of them is under anyone's
control on a given day. T-345 already fixed one instance of exactly this confusion in this same
check — it used to print "(coverage growing)" against a rising unregistered count, framing
regression as good news. The severity was corrected then; the *number* was not.

**The blind spot that makes it more than cosmetic.** Because only the difference is reported,
these two are indistinguishable in the audit output:
  - twenty new source files were added and not carded (ordinary, expected, and what the standing
    WARN was accepted to cover)
  - twenty existing cards were **deleted**

T-524 established that cards are load-bearing rather than documentation: a card that stops
participating changes what `update-task.sh` resolves and makes its own file report as
unregistered. Card loss is therefore a real failure mode, and today nothing separates it from
routine growth. The 08-12 → 08-14 window is the honest illustration: `registered` sat flat at 40
across three audits while `watched` grew 209 → 222, which IS drift — and it reads identically to
the 08-15 row, where 14 cards were added.

**Scope.** Reporting only. This task does not change the severity, does not change the accepted
threshold, and does not register any cards — the question of whether the watch set is right stays
where T-524 left it. Vendored (`.agentic-framework/`); G-008 in-tree fix + `upstream: fix`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The warning reports coverage, not just a difference.** The message carries the ratio
      alongside the counts, so a reader can tell 54/240 from 40/222 without doing arithmetic on
      two numbers that both moved.

- [x] **Card loss is distinguishable from source growth.** The check compares `registered`
      against the previous audit's value and says so explicitly when it has FALLEN. Two states
      that need different responses must not print the same line.

- [x] **First run, or no comparable prior audit, ABSTAINS rather than inventing a delta.**
      "I have no previous value" must not render as "no change" (PL-205) — a fabricated zero
      delta would be a claim about history the instrument cannot support.

- [x] **Severity is unchanged and the accepted decision is untouched.** Still `warn`, still gated
      on `unregistered > 0`, still no FAIL. Confirmed by the audit's own summary counts before
      and after: 19 pass / 3 warn / 0 fail. Changing severity here would overturn the operator's
      T-344 `[REVIEW]` under the guise of a reporting fix.

- [x] **Teeth (PL-206): red for the NAMED reason.** A mutation-based teeth script proves the
      card-loss branch fires on a constructed drop in `registered` and NOT on a run where only
      `watched` grew — the discrimination is the whole deliverable, so a leg asserting merely
      that some warning appeared would pass on an instrument that warns unconditionally, which
      is what it already does.

- [x] **A negative leg may not pass by silence** (L from T-524). Any leg asserting a branch did
      NOT fire must also assert the run produced output and reached the check — otherwise a
      broken audit satisfies it for free.

- [x] **Hermetic.** Fixtures under `mktemp`; working tree byte-identical after a run, asserted
      with `git status --porcelain` rather than inspected.

- [x] **Wired** into `tests/run-bridge-tests.sh`, and a fabric card written for any new tool —
      carrying `location:`, the field T-522/T-524 were about.

- [x] **Divergence declared** in `.agentic-framework/.vendor-divergence.yaml` with
      `upstream: fix`, so a re-vendor cannot silently restore count-only reporting.

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
# T-525: `fw audit` itself is deliberately NOT a line here. It exits 1 on warnings and
# this project has three standing accepted ones, so a raw audit run would fail the gate
# for reasons that have nothing to do with this task — and the three warnings are global
# moving state besides (T-508's learning). The teeth run the audit four times with
# controlled history and assert the branch taken each time, which is the property this
# task is responsible for.
python3 tools/_t525-fabric-coverage-teeth.py
python3 tools/_t517-vendor-divergence-teeth.py
.agentic-framework/bin/fw fabric validate
grep -q "^location:" .fabric/components/tools-_t525-fabric-coverage-teeth.yaml
grep -q "_t525-fabric-coverage-teeth.py" tests/run-bridge-tests.sh
grep -q "agents/audit/audit.sh" .agentic-framework/.vendor-divergence.yaml

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

**Symptom:** the audit's fabric coverage line reported `N registered, M unregistered (of W
watched)` and nothing else. Measured over this project's own audit history, coverage went
**10.6% → 22.5% while the headline number went 147 → 189** — the figure the operator reads moved
in the opposite direction from the property it describes, for six consecutive audits.

**Root cause:** `unregistered` is a *difference* between two independently moving quantities
(`watched` grows as source is added; `registered` grows only when someone writes a card), and
only one of them is under anyone's control on a given day. Reporting the difference alone makes
the number a function of tree growth more than of carding. The absence of the ratio is what makes
it unreadable; the absence of a direction is what makes it undecidable.

**Why structurally allowed:** the warning was *correct* and had been *accepted*. The
`watch-patterns.yaml` header records it as the standing WARN the operator's T-344 `[REVIEW]`
ratified, and the audit's trend analysis has flagged it three times in fourteen days. An accepted
recurring warning is the ideal hiding place for a reporting defect: everyone has agreed in
advance that it will be there, so nobody reads the number. T-345 had already corrected one
instance of this same confusion in this same check — it printed "(coverage growing)" against a
rising unregistered count, framing regression as good news — and fixed the *severity* without
touching the *number*. This is the second half of that finding, not a new one.

**What the blindness cost, concretely:** these two produced an identical line —
  - twenty new source files added and not carded (the ordinary case the WARN was accepted for)
  - twenty existing cards **deleted**

T-524 established one task earlier that cards are load-bearing rather than documentation: a card
that stops participating changes what `update-task.sh` resolves, and makes its own file report as
unregistered. So card loss is a real failure mode that the audit could not distinguish from
routine growth. The 08-12 → 08-14 window shows the ambiguity live: `registered` sat flat at 40
across three audits while `watched` grew 209 → 222 — genuine drift, reading identically to the
08-15 row where 14 cards were added.

**Prevention (distinct from the fix):** `tools/_t525-fabric-coverage-teeth.py`, wired into the
bridge suite, drives the check four times with controlled history and pins **which branch was
taken** each time. No leg may assert merely that a fabric warning appeared — the pre-change code
satisfied that on every run for every input, which is exactly why the defect survived. Two legs
assert a branch was *not* taken and therefore also require the coverage line to exist first,
applying T-524's lesson that a negative assertion is satisfied by silence. Leg 6 guards the
sovereignty edge: severity must stay WARN across every branch, so a reporting fix cannot
overturn the operator's ratified T-344 decision as a side effect. Verified by mutation —
reverting to raw counts makes the teeth exit 2 with a refusal naming the missing line, which is
non-zero (so the suite catches it) and honest that nothing was evaluated.

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

### 2026-08-15T15:22:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-525-the-fabric-coverage-warn-reports-a-raw-c.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-df31db19
- **Timestamp:** 2026-08-15T15:37:18Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T15:36:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
