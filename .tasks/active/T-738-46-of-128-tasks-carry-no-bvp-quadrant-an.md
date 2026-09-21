---
id: T-738
name: "46 of 128 tasks carry no BVP quadrant, and 18 of them are agent-owned — the
  ranker is blind to the work it is meant to order"
description: >
  fw bvp --include-proposed ranks 37 tasks and excludes 46 with quadrant '-'. Cause
  is estimator.py score_blast_radius returning None (deliberate, T-542: absent beats
  a blind 0) when components: is empty AND no target_blast_radius AND no existing
  source path is named in the body. components: is [] on 120 of 128 active tasks.
  Consequence: the Q1/Q2 selection rule cannot see 18 agent-owned tasks. Split the
  population into (A) bodies that DO name existing paths but still scored absent -
  an estimator defect - and (B) genuine declaration gaps, and propose mechanical components:
  per task without applying them.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bug, tooling, bvp]
components: [tools/_t738-rankability.py, 
      .agentic-framework/agents/termlink/bvp-estimator/estimator.py, 
      .agentic-framework/lib/bvp.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-20T10:14:05Z
last_update: 2026-09-21T21:46:24Z
date_finished:
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
  - ts: '2026-09-20T10:14:14Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-20T10:14:14Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-21T20:24:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-738: 46 of 128 tasks carry no BVP quadrant, and 18 of them are agent-owned — the ranker is blind to the work it is meant to order

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->


**PARKED 2026-09-20, not worked.** Filed and scored during an autonomous run whose selection rule excludes low-value work. `fw bvp estimate` → 61 (0.19), `estimate-cost` → 3.1 → **lv-lc**. The scorer is the judge; the task was filed because the ranker's blindness blocks selection, and it was parked because the ranker says it is not worth the run. Both facts are recorded deliberately.

**Calibration note (do not act on by rewording this body):** the estimator gave D2 (Reliability) = 0 with rationale `no-signal`, because the body names no `fw audit`/`fw doctor` invocation. A defect in the ranker that orders all other work is arguably a D2 item; the detector keys on a literal. Recorded for whoever tunes the rubric — the fix belongs in the rubric, not in this task's prose.

**Sovereign question:** may an agent declare `components:` on tasks it did not author? Doing so is the input `score_blast_radius` asks for ("the author's own declaration"), and it changes the quadrant of up to 46 tasks — i.e. it changes what the next autonomous run is permitted to work on. That is a priority decision, not a build activity.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **`tools/_t738-unrankable-task-census.py` reports all 50**, and names which evidence
      source was empty for each. It **imports the estimator's own functions** rather than
      reimplementing them — a reimplementation would measure my reading of the detector, not
      the detector.

      It also found a **third exclusion mechanism that this task's framing did not anticipate**:
      the ranker needs a VALUE score as well as a cost, so a task with no
      `bvp_scores_proposed:` has no `bvp_norm` and is dropped **even when its cost is fully
      computed**. Six were in that state. Recorded as class C.

- [x] **Class A is EMPTY — there is no estimator defect, and the first run said there were 3.**

      The first run reported T-580, T-691, T-732 as class A. That was **my tool, not the
      estimator.** `PROJECT_ROOT` falls back to `Path(__file__).parents[3]`, which in a
      VENDORED install resolves to `.agentic-framework/` rather than the project — so every
      `(root / p).is_file()` check failed and `score_blast_radius` returned `None` for
      everything. `fw` sets the env var, so it never bites in normal operation; it bit a direct
      import. The tool now pins `PROJECT_ROOT`, carries a comment saying why, and class A is 0.

      **Nothing is reported upstream as an estimator bug.** This is the second time in this
      session that checking a suspected defect before filing it prevented a false report.

- [x] **Class B proposals written to `docs/reports/T-738-unrankable-census.md`, NOT applied.**
      44 declaration gaps: **B1 = 1** with a mechanical proposal derivable from the task's own
      commits (the same signal `components:` is populated from at completion, so it is the
      proposal the framework would have made, not a new opinion about scope); **B2 = 43** with
      **no mechanical basis at all** — captured, never worked, naming nothing that exists.

      That 43-of-44 ratio is the substantive answer to this task's Sovereign question: for the
      overwhelming majority, no mechanical proposal is possible. Cost is knowable only once
      work begins, which is the circularity measured in T-781's RCA.

      Class C was the exception and WAS acted on, because it is fixable with `fw bvp estimate`
      — advisory, explicitly non-sovereignty-bearing, writes `bvp_scores_proposed:` only. Five
      of six now rank.

- [x] **The agent-owned unrankable are named individually — 17** (the task said 18; the
      population shifted as tasks completed): T-241, T-246, T-294, T-553, T-554, T-555, T-564,
      T-573, T-577, T-582, T-583, T-584, T-622, T-746, T-749, T-750, T-773. All but T-773 are
      `captured` class-B declaration gaps.

      **The result that closes T-780's RC-6b:** two class-C tasks (T-681, T-732) are arc-002's
      only live tasks. With them unranked the arc rollup had no rankable constituent and
      `fw bvp arcs` dropped the arc **silently**. After scoring:

      ```
      arc-002  ewcr-governed-delivery      in-progress  117  0.37   <- was ABSENT
      arc-001  designer-authoring-surface  in-progress  112  0.36
      arc-003  arc-003                     in-progress   88  0.28
      ```

      The focused arc was invisible and is the **highest-ranked** arc.

      **And the finding worth the operator's attention: T-732 ranks `lv-lc`, BVP 81.** It holds
      H3, H5 and H6 — the only three open rulings gating Arc-0 exit. A rule that parks
      low-value work would park the most consequential task in the project. Drivers: D1=4,
      **D2=0**, **D3=0**, D4=2; the heuristic cannot see that a task gates an arc's exit.

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
         1. Run `bin/fw reviewer T-738`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-738 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

# T-738 legs (write these when the instrument exists)
# python3 tools/_t738-rankability.py --check

## Verification

test -f docs/reports/T-738-unrankable-census.md
python3 tools/_t738-unrankable-task-census.py > /dev/null 2>&1
python3 tools/_t738-unrankable-task-census.py 2>/dev/null | grep -qE "estimator defect .*: 0"
grep -q 'PROJECT_ROOT' tools/_t738-unrankable-task-census.py
.agentic-framework/bin/fw bvp arcs 2>/dev/null | grep -q 'ewcr-governed-delivery'
! grep -rlE '^bvp_scores:' .tasks/active/

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
     fw inception decide T-738 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-20T10:14:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-738-46-of-128-tasks-carry-no-bvp-quadrant-an.md
- **Context:** Initial task creation

### 2026-09-21T21:46:24Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
