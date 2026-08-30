---
id: T-635
name: "T-630's prober asserts against a model of the runner, and the model has drifted from it"
description: >
  T-630's prober asserts against a model of the runner, and the model has drifted from it

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
created: 2026-08-29T22:33:09Z
last_update: 2026-08-29T22:37:42Z
date_finished: 2026-08-29T22:37:42Z
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

# T-635: T-630's prober asserts against a model of the runner, and the model has drifted from it

## Context

OBS-323. T-630's prober pins two runner shapes as text and asserts against those. Both
end in `exit 1` where the live gate uses `return 1` (T-634), and both compute `total`
with `wc -l` BEFORE stripping blank lines where the live gate strips first
(update-task.sh:1082 filters `^\s*$` out of `verify_cmds`, and only then 1179 counts).

That second drift is not cosmetic — it is what made leg 3 green. Leg 3 feeds a
whitespace-only line to the model to manufacture a counted-but-never-run command. Against
the live gate that line is removed by the filter, so it is never in the denominator, so it
cannot leave a gap. The leg measures a scenario the gate cannot reach and reports a pass.

Reading the live runner to fix that answered a larger question than OBS-323 asked. With
`< /dev/null` at 1218 and the filter at 1082, NO Verification-block input can leave
`seen != total`: every line that survives extraction has a non-space character, so every
line produces a verdict. THE RECONCILIATION GUARD IS UNREACHABLE BY DATA. It is a
regression detector, not an input validator, and the only instrument that can exercise it
is mutation of the live source — the same conclusion T-634 reached about a different guard
in the same function.

So this is not "port leg 3 to the real gate". It is: replace a drifting model with
mutation of the thing it modelled, and state the reachability result as a measured fact
rather than leaving a green leg standing in for it.

## Acceptance Criteria

### Agent
- [x] `tools/_t630-p011-stdin-swallow.sh` drives the real `update-task.sh` against a
      throwaway PROJECT_ROOT; no pinned copy of the runner remains in the file
      — `grep -c 'runner-prefix\|runner-fixed\|VERDICT='` → 0
- [x] An anti-vacuity control completes a clean task in that sandbox first, so every
      "blocked" verdict below is a measurement and not a broken harness
- [x] The stdin-swallowing fixture (four commands, the second reads stdin) completes
      through the LIVE gate with all four reporting — the `< /dev/null` fix measured
      behaviourally, not by grepping the source for the string
      — `Verification: 4/4 passed`, task moved to `completed/`
- [x] The same fixture through a mutant with `< /dev/null` removed is refused with
      RUNNER DEFECT and the task stays in `active/` — the reconciliation guard exercised
      against the real gate for the first time
- [x] Every mutation anchor is asserted to occur exactly once and the run aborts loudly
      if it does not (a mutation that matches nothing certifies an untested fix, T-632)
      — `src.count("2>&1 < /dev/null") != 1` exits non-zero before writing the mutant
- [x] `--skip-verification` does not buy past RUNNER DEFECT, measured against the mutant
      (the only route by which that guard is reachable)
- [x] The unreachability claim is measured, not asserted: a whitespace-only verification
      line is shown absent from the live gate's denominator
      — live gate prints `Running 2 verification command(s)` for a 3-line block
- [x] The prober passes, and `tools/_t634-guard-verdict-reaches-caller.sh` still passes
      (same function, shared exit path) — 11/11 and 8/8

Added beyond the original scope, because the reachability finding needed it:
- [x] The general claim's structural premise is pinned — the runner loop is asserted to
      have exactly one verdict-free skip path, so a second one added later reddens this
      file instead of silently expiring its header. Counter shown to discriminate (2→2,
      comment-only→0).

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

bash tools/_t630-p011-stdin-swallow.sh
bash tools/_t634-guard-verdict-reaches-caller.sh

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

**Symptom:** `tools/_t630-p011-stdin-swallow.sh` reports 6/6 while one of its legs
measures a scenario the gate it guards cannot reach.

**Root cause:** the prober asserts against a pinned textual MODEL of the runner rather
than the runner. The model was faithful when written and has since drifted in two places
(`exit 1` vs `return 1`; `total` counted before vs after blank-line stripping). The second
drift is the one that matters: it is the only reason leg 3's fixture produces a gap at all.

**Why structurally allowed:** nothing checks a model against the thing it models. The
file's own header argues for the pinned copy on good grounds — a pre-fix reproduction read
from git history starts testing the fix against itself one commit later (AEF rail-463) —
and that argument is correct for the PRE-fix shape while being wrong for the POST-fix one.
Mutation of the live source has neither weakness, and it was already available: T-634 used
it on the same function four commits earlier.

**Prevention:** the rewritten prober holds no copy of the runner. Its teeth come from
mutating the live file, so any future drift in the gate is drift in the instrument too,
and the anchor-uniqueness assertions turn a moved line into a loud abort rather than a
silent green.

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

### 2026-08-29T22:33:09Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-635-t-630s-prober-asserts-against-a-model-of.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1a4847d6
- **Timestamp:** 2026-08-29T22:37:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T22:37:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
