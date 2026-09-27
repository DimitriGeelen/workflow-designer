---
id: T-909
name: "Two T-889 order fixtures carry orphan nodes, so promoting W-XML-NODE-UNASSIGNED
  to an error would flip them invalid"
description: >
  Filed by T-891 under its own AC5, which requires the blast radius of a new error
  to be MEASURED and any corpus migration filed separately rather than smuggled in.
  MEASURED: 24 orphan flow nodes across 9 fixtures; authored corpus (examples/aef-processes/rendered,
  24 files, 306 flow nodes) has ZERO, so the product corpus AEF pins is unaffected.
  Of the 9 fixtures, 7 are ALREADY exit=2 (invalid), so an added error changes no
  verdict. Only tests/fixtures/t889-authority/order-A.bpmn and order-B.bpmn sit at
  exit=1 (warnings only) and would flip to invalid. So the true blast radius is TWO
  FIXTURES, not 24 nodes. Those two are round 2's own fixtures proving authority does
  not depend on laneSet declaration order, and they carry orphans incidentally rather
  than deliberately. Deliverable: add the missing flowNodeRefs so each fixture models
  order-independence WITHOUT also modelling orphanhood, keeping both properties separately
  testable; then W-XML-NODE-UNASSIGNED can be promoted to an error without turning
  the suite red. Asserted by tools/_t889-authority-on-the-element-teeth.sh, so that
  instrument must stay green across the change.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface]
components: [src/aef-workflow-designer.html]
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
created: 2026-09-27T19:20:47Z
last_update: 2026-09-27T20:34:40Z
date_finished: 2026-09-27T20:34:40Z
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
  - ts: '2026-09-27T20:22:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 3
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 0
      F1: 3
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=3 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L1:keyword=designer)'
    rubric_sha: e4a00f38e801
---

# T-909: Two T-889 order fixtures carry orphan nodes, so promoting W-XML-NODE-UNASSIGNED to an error would flip them invalid

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `order-A.bpmn` and `order-B.bpmn` carry a `flowNodeRef` for every flow node, so each models order-independence **without also** modelling orphanhood. Two properties, separately testable — a fixture that accidentally carries a second defect cannot distinguish which one a failure is about
- [x] Both still model what they exist to model: the two files differ ONLY in laneSet declaration order, verified by diffing them and confirming the difference is the lane order and nothing else
- [x] **`tools/_t889-authority-on-the-element-teeth.sh` stays green** — it asserts on these two fixtures, so a change to them that breaks it would trade one defect for another. Run before and after
- [x] The orphan census over `tests/fixtures/**` drops by exactly 4 (2 per file), measured not assumed — any other number means I changed something I did not intend
- [x] **Neither fixture becomes valid-with-warnings by accident**: both were `exit=1` before and their exit codes are recorded after, so the change is understood rather than merely green
- [x] This unblocks T-891 AC3/AC4 but does NOT do them — promoting `W-XML-NODE-UNASSIGNED` to an error is T-891's, and one lock at a time

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

# ── T-909 legs ──────────────────────────────────────────────────────────────
grep -qF '<bpmn:flowNodeRef>Start_1</bpmn:flowNodeRef>' tests/fixtures/t889-authority/order-A.bpmn
grep -qF '<bpmn:flowNodeRef>End_1</bpmn:flowNodeRef>' tests/fixtures/t889-authority/order-B.bpmn
# both fixtures validate fully clean, not merely warning-free
python3 tools/validate-workflow.py tests/fixtures/t889-authority/order-A.bpmn > /tmp/.t909a 2>&1
python3 tools/validate-workflow.py tests/fixtures/t889-authority/order-B.bpmn > /tmp/.t909b 2>&1
# The instrument that asserts on these two fixtures stays green. Asserted POSITIVELY on its
# own summary line rather than as an absence — "0 failed" is a fact the suite states, whereas
# "no FAIL lines" is a negation whose pattern could be typo'd into a permanent pass. The
# absence gate refused the negated form and was right to (PL-328).
timeout 300 bash tools/_t889-authority-on-the-element-teeth.sh > /tmp/.t909t 2>&1
grep -qF 'control set passed' /tmp/.t909t
# The pair still differs ONLY in lane ordering. Asserted POSITIVELY — every differing line
# matches a lane construct — rather than as "zero non-lane lines", because the negated form
# passes identically when the diff is empty, when the paths are wrong, or when the pattern is
# typo'd. Here the two counts must be EQUAL AND NON-ZERO, so an empty or broken diff fails.
test "$(diff tests/fixtures/t889-authority/order-A.bpmn tests/fixtures/t889-authority/order-B.bpmn | grep -cE '^[<>]')" -gt 0
test "$(diff tests/fixtures/t889-authority/order-A.bpmn tests/fixtures/t889-authority/order-B.bpmn | grep -E '^[<>]' | grep -cE 'lane id|flowNodeRef|laneMeta|laneSet|</bpmn:lane>')" -eq "$(diff tests/fixtures/t889-authority/order-A.bpmn tests/fixtures/t889-authority/order-B.bpmn | grep -cE '^[<>]')"

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

### 2026-09-27 — the absence gate refused two of my legs, and both rewrites are better

- **What changed:** I wrote two legs as negations — "no FAIL lines in the teeth output" and
  "zero non-lane lines in the diff". The close gate refused both: an absence assertion with
  nothing proving the search could have succeeded passes identically when the pattern is
  typo'd, the file is missing, or the diff is empty.
- **Plan impact:** both became positive claims. The teeth leg now greps the suite's **own
  verdict string** (`control set passed`) rather than the absence of failure — and I had to
  run the suite to learn what it actually prints, having first guessed `0 failed`, which it
  does not say. The diff leg now asserts lane-lines **equals** total-lines **and** total > 0,
  so an empty or broken diff fails where the negated form would have passed.
- **Triggered:** nothing new. It is PL-328 enforced at the gate instead of remembered, and it
  caught me twice in one task.

### 2026-09-27 — the fixtures went further than the AC required

- **What changed:** the AC asked that the fixtures stop carrying orphans so a promoted error
  would not flip them invalid. They went from `exit=1` to `exit=0` — fully clean, not merely
  warning-free.
- **Plan impact:** T-891 AC3 is now unblocked more cleanly than planned; the promotion cannot
  turn these red at all, rather than turning them from one non-zero state to another.
- **Triggered:** nothing. Worth noting only because "blast radius: two fixtures" turned out to
  overstate the risk once measured properly, which is the second time in this arc that a
  measured radius was smaller than the filed one.

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

### 2026-09-27T19:20:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-909-two-t-889-order-fixtures-carry-orphan-no.md
- **Context:** Initial task creation

### 2026-09-27T20:22:59Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## 2026-09-27 — 6/6. Both fixtures now model one property each.

`Start_1` and `End_1` were the two orphans in each file — claimed now by the **first-declared
lane**, which differs between A and B and is therefore the very property the pair exists to
exercise.

| | before | after |
|---|---|---|
| `order-A.bpmn` | exit 1 | **exit 0** |
| `order-B.bpmn` | exit 1 | **exit 0** |
| fixture orphan census | 24 | **20** — exactly −4, as predicted |
| `_t889-authority-on-the-element-teeth.sh` | exit 0 | **exit 0**, 0 lines mentioning fail |

Better than the AC asked for: both went to **fully clean**, not merely warning-free. That means
T-891's promotion of `W-XML-NODE-UNASSIGNED` to an error can now ship without turning anything
red — which was the whole point of filing this separately.

**The order-only property is verified, not assumed.** Diffing the two files gives 12 differing
lines; 4 are not about lanes, and all four are the `laneSet` **ids swapping position** — which
*is* the lane-order difference. So the pair still differs only in lane ordering, and it no longer
carries orphanhood as an accidental second variable. A fixture with two defects cannot tell you
which one a failure is about.

**Not done here:** promoting `W-XML-NODE-UNASSIGNED`. That is T-891 AC3, now unblocked. One lock
at a time.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-02302666
- **Timestamp:** 2026-09-27T20:34:42Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-27T20:34:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
