---
id: T-903
name: "E-WORKFLOW-KIND and E-XML-WORKFLOW-KIND have failed the rule-dialect harness
  since T-875, unnoticed"
description: >
  tests/test_rule_dialect_axis.py fails with: rule E-WORKFLOW-KIND / E-XML-WORKFLOW-KIND
  is emitted by the validator but declares no carrier in RULE_CARRIERS. Both rules
  were added by T-875 (commit 39e0579d, 'the diagram-kind marker ships and validates').
  The harness has been red on them since. Discovered during T-889 when the SAME harness
  caught T-889's own new rule (E-XML-META-AUTHORITY) - T-889 fixed its own two entries
  (RULE_CARRIERS + CARRIER_CLASS + PARITY) and left these, because one bug = one task
  and these are not T-889's. Deliverable: declare carriers for both, and classify
  their parity. NOTE the meta-finding: this is the concrete harm of the pre-flight
  gap in OBS-408 - tests/run-bridge-tests.sh is one of five dependents of the shared
  harness, it takes ~15 minutes, and a task that does not run it ships a red. T-875
  did not run it.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface, false-green]
components: [src/aef-workflow-designer.html, tests/test_rule_dialect_axis.py, tests/test_rule_form_parity.py, tools/_t889-authority-on-the-element-teeth.sh, tools/validate-workflow.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T14:01:52Z
last_update: 2026-09-27T20:01:42Z
date_finished: 2026-09-27T20:01:42Z
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
  - ts: '2026-09-27T19:56:48Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L0: no signal); F3=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F1=1 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-903: E-WORKFLOW-KIND and E-XML-WORKFLOW-KIND have failed the rule-dialect harness since T-875, unnoticed

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
**Why now:** this is no longer one task's problem. `EXPECTED_GAPS` and the two unclassified
`kind` rules block **T-890, T-894 and T-903** simultaneously — one constant, three tasks, and
the harness says in its own failure text to re-derive rather than nudge it.

- [x] `E-WORKFLOW-KIND` and `E-XML-WORKFLOW-KIND` declare a carrier in `RULE_CARRIERS` and an axis, classified from what the rule actually reads — the harness's own words: until it does, *"nothing knows whether surfacing it to an author states a correctness fact or a house convention"*
- [x] Their carrier has a class in `CARRIER_CLASS`, decided from the frozen standard's §1 partition rather than from convenience
- [x] Both are classified in the form-parity registry with a reason, PAIRED or GAP — the YAML form's `workflowMeta` is checked by `E-WORKFLOW-KIND`, so this pair may genuinely be PAIRED unlike the three before it, and the answer is measured rather than assumed
- [x] **`EXPECTED_GAPS` is RE-DERIVED, not nudged.** The count changes because gaps were legitimately opened (T-890, T-894) and possibly closed (this task). Each delta is shown with its cause in `docs/reports/T-320-rule-form-parity-census.md`, in the style the existing entries use — the harness refuses a bare adjustment and is right to
- [x] Both suites go green, or every remaining failure is named with its owner. A suite left red teaches its readers to ignore it (OBS-293)
- [x] The three blocked tasks are re-checked afterwards: T-890 and T-894's own criteria must still hold, verified by re-running them, not asserted

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
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
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

### 2026-09-27 — the task was filed as two unregistered rules; it was one constant holding three tasks

- **What changed:** T-903 was filed as "two rules fail the dialect harness". By the time it was
  worked, T-890 and T-894 had each opened a legitimate parity gap and were parked on the same
  `EXPECTED_GAPS` constant. The task's real scope was not two registrations — it was one
  re-derivation that three tasks were queued behind.
- **Plan impact:** the ACs were rewritten before execution to say so. Doing the two
  registrations alone would have left the constant red and all three tasks still blocked, which
  would have read as progress while changing nothing.
- **Triggered:** nothing new. It closed T-890's and T-894's shared blocker as a side effect of
  being scoped correctly.

### 2026-09-27 — the pre-existing discrepancy had an owner all along

- **What changed:** the 11-vs-10 gap count predates every task in this run. Re-deriving found
  the cause: T-889 opened `E-XML-META-AUTHORITY`, classified it GAP correctly, filed T-902 for
  it — and never updated the constant. The gap was recorded; only the arithmetic was not.
- **Plan impact:** none to the design. It does mean the harness's ratchet has been red since
  T-889 and nothing escalated it, so the ratchet was being read as noise rather than signal —
  which is the failure mode the ratchet exists to prevent.
- **Triggered:** worth watching whether a harness that stays red across several tasks gets an
  owner automatically. Three tasks tripped over this one before anyone re-derived it.

### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-27T14:01:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-903-e-workflow-kind-and-e-xml-workflow-kind-.md
- **Context:** Initial task creation

### 2026-09-27T19:56:47Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## 2026-09-27 — both suites green, and one constant that was blocking three tasks is re-derived

**The two `kind` rules are a genuine PAIR, which is why they added no gap.** Both were built in
T-875, both read the same module-scope `WORKFLOW_KINDS` set, both refuse a value outside it —
`E-WORKFLOW-KIND` on `workflowMeta.kind`, its twin on `aef:workflowMeta/@kind`. They had been
unclassified since T-875 *purely because nobody registered them*, and that single omission was
failing two harnesses for weeks with no owner.

**Their carrier is `UNRATIFIED`, and that is the honest class rather than a convenient one.**
T-875 measured, with a control, that `aef:workflowMeta` appears **zero** times in the frozen
standard while `aef:uid` appears 8, `aef:meta` 7 and `aef:position` 1 in the same grep shape and
run. §1 partitions NODE-level attributes; §6's conformance clauses never reach document-level
metadata. **There is no document-level class to belong to.** So the reading is ours, declared as
ours, and counted — `EXPECTED_UNRATIFIED` 2 → 4. The mechanism exists precisely so a hole in the
standard stays visible instead of being absorbed by whichever class made the arithmetic work.

### EXPECTED_GAPS re-derived 10 → 13, every delta named

| # | gap | opened by |
|---|---|---|
| 11 | `E-XML-META-AUTHORITY` | **T-889** — classified GAP at the time, filed as T-902, constant never updated. **This is the whole of the pre-existing 11-vs-10 discrepancy.** |
| 12 | `E-XML-LANE-AUTHORING-DEFAULT` | T-890 |
| 13 | `W-XML-AUTHORITY-DEFAULT-MISMATCH` | T-894 |

**And it moved the other way in the same pass**: the two `kind` rules were classified `PAIRED`
and added **zero**. A ratchet that only ever rises is not a measurement.

Written into `docs/reports/T-320-rule-form-parity-census.md` with causes, and the constant
carries the arithmetic inline — the harness refuses a bare adjustment and was right to.

### Verified after, not assumed

- `test_rule_dialect_axis.py` **OK** — 55 rules, 4 unratified carriers printed
- `test_rule_form_parity.py` **OK** — 55 rules, 13 gaps, 0 out-of-scope
- T-890's and T-894's own criteria re-run and still hold: agree → 0 findings, differ → 1,
  bad `authoringDefault` → exit 2

**One false alarm of mine, checked before reporting it.** My corpus sweep counted
`context-memory.bpmn` as failing. It reports **0 errors and 7 warnings** — `W-LANE-NO-OWNER`,
the pre-existing state the T-888 ruling already documents — and exits 1 because warnings do.
The validator from six commits ago exits 1 on it identically, so it is not mine. My sweep
treated "non-zero" as "failing".

## Reviewer Verdict (v1.5)

- **Scan ID:** R-43f75304
- **Timestamp:** 2026-09-27T20:01:43Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-27T20:01:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
