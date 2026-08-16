---
id: T-533
name: "scope the two whole-tree hermeticity assertions to their subjects write-sets
  and wire the T-532 census"
description: >
  T-532 measured the population at 2: _t524-fabric-validate-teeth.py leg 10 and _t525-fabric-coverage-teeth.py
  leg 7 both compare whole-tree git status --porcelain across their own run, so any
  other writer in the repo reddens them and they pass standalone. Demonstrated under
  T-527. One copy-family, source _t524, propagated in 28 minutes. Fix is to scope
  each snapshot to the paths its own subject writes, then wire tools/_t532-hermeticity-scope-census.py
  as a standing leg so the ratchet returns from 68 to 67.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T22:07:21Z
last_update: '2026-08-16T13:57:25Z'
date_finished: 2026-08-15T22:21:44Z
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
  - ts: '2026-08-16T12:34:06Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh,tools/_t524-fabric-validate-teeth.py,tools/_t525-fabric-coverage-teeth.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-533: scope the two whole-tree hermeticity assertions to their subjects write-sets and wire the T-532 census

## Context

T-532 measured the population at 2. This scopes both and wires the census.

## Results

**Write-sets derived from the subjects, not guessed.** `audit.sh` writes reports under
`.context/audits/`, with `--cron` writing the `cron/` subdirectory — a *different actor on a
15-minute timer*, so `cron/` is excluded by pathspec; including it would have rebuilt the defect
at 1/15th scale. `do_validate()` in drift.sh performs no writes at all (checked: no redirects),
and `_t524`'s fixtures live under `mktemp`, so its exposure is `.fabric` — where a regression
that started writing cards it only reads would show.

**Discrimination demonstrated on both arms, per leg:**

| script | unrelated writer elsewhere in repo | subject's own write-set dirtied |
|---|---|---|
| `_t525` leg 7 | **PASS** (was RED before this fix) | **FAIL** |
| `_t524` leg 10 | **PASS** | **FAIL** |

The invariant is preserved, not decorated — narrowing a snapshot until nothing can trip it is
PL-206, which I committed under T-527 while testing for it.

**`_t524`'s first red arm was a bad test, not a passing leg.** It runs in **1 second**; my
perturbation fired at t=3s, after the script had finished. Re-run at 0.4s → FAIL. At 0.2s it
passes, because the marker lands before the `before` snapshot and appears in both — consistent,
not contradictory.

**The census false-positived on its own fix, twice, and both were real classifier defects:**

1. Hoisting the pathspec into a `SCOPE` variable made the call site read as unscoped, because
   the census judges argv syntactically. Fixed by inlining the pathspec — the better code
   anyway.
2. After that, it still flagged both files: the fix's own explanatory comments contain
   `` `git status --porcelain` `` in backticks, and backtick is a shell-invocation prefix. A
   checker that gets more wrong as authors document the pattern it detects has exactly inverted
   incentives. Fixed by stripping whole-line comments before classifying.

**Anti-vacuity checked before believing the 0.** Reverting `_t525` to whole-tree makes the
census report 1, naming the file, rc 1; restored byte-identical, rc 0. A green census here is a
classification, not an absence.

**Suite 96 passed / 0 failed**, run with a `git status` witness before and after — tree
unperturbed. **T-451 ratchet 68 → 67**, discharging T-532's recorded movement.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Each snapshot is scoped to the paths its OWN subject writes, and the write-set is
      derived from the subject rather than guessed.** `_t525`'s subject is `fw audit`, which
      writes its report under `.context/audits/`; `_t524`'s fixtures live under `mktemp`. A
      snapshot narrowed to the wrong set is the same defect with a smaller blast radius.
- [x] **The leg still fails when its subject genuinely dirties the tree.** Narrowing a snapshot
      until nothing can trip it converts a real invariant into a decoration — PL-206, which I
      committed under T-527 while testing for it. Each rewritten leg is demonstrated red by
      making its subject write into the scoped set, and green otherwise.
- [x] **The leg no longer reddens when an UNRELATED writer touches the repo.** This is the
      defect being fixed, so it is measured directly: a persistent marker file created mid-run
      outside the subject's write-set must leave the leg green, where T-527's probe B drove the
      old form red.
- [x] **`tools/_t532-hermeticity-scope-census.py` is wired as a standing bridge-suite leg and
      goes green,** so the next copy of this shape is caught at authoring time rather than by a
      future unexplained flake. Its `GROUND_TRUTH` set is emptied in the same commit as the fix,
      since leaving both names there would make the census REFUSE (rc 2) forever.
- [x] **The T-451 unwired-guard ratchet returns to 67**, discharging the movement T-532 recorded
      with this task as its named closing condition.
- [x] Bridge suite green, and the count reported honestly rather than asserted.

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

# The census is the standing guard; it must be GREEN here (unlike T-532, where it was
# legitimately red). Both subjects must still pass their own legs.
python3 tools/_t532-hermeticity-scope-census.py
python3 tools/_t525-fabric-coverage-teeth.py > /tmp/t533-a.out 2>&1 && grep -q "7/7 legs passed" /tmp/t533-a.out
python3 tools/_t524-fabric-validate-teeth.py > /tmp/t533-b.out 2>&1 && grep -q "10/10 legs passed" /tmp/t533-b.out
bash -n tests/run-bridge-tests.sh

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

### 2026-08-15T22:07:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-533-scope-the-two-whole-tree-hermeticity-ass.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4f8d2078
- **Timestamp:** 2026-08-15T22:22:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T22:21:44Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
