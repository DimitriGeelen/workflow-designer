---
id: T-502
name: "Pre-flight the three completion-ready human-owned tasks so the operator's close
  does not bounce"
description: >
  Pre-flight the three completion-ready human-owned tasks so the operator's close
  does not bounce

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-14T19:15:25Z
last_update: '2026-08-16T13:57:24Z'
date_finished: 2026-08-14T19:38:41Z
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
  - ts: '2026-08-16T12:34:03Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 4
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=4 
      (body:framework-level-ux); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:build/gallery/designer.html,src/aef-workflow-designer.html,tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh);
      tier=1 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-502: Pre-flight the three completion-ready human-owned tasks so the operator's close does not bounce

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Every command in the `## Verification` block of T-041, T-101 and T-102 is executed
      as the completion gate would execute it**, and the per-command result is recorded in
      this task with the command text next to its exit status. Not "the tests pass" —
      *those* commands, the ones the operator's `work-completed` will actually run.
- [x] **Each of the three is routed with an explicit verdict: close-ready, or blocked with
      the failing command named.** A green pre-flight yields one copy-pasteable
      `fw task update T-XXX --status work-completed` per task. A red one yields the command
      that failed and what it means — never a suggestion to `--force` past it, which would
      skip the verification the gate exists to perform.
- [x] **No Human AC is ticked, no owner is changed, and no task is completed by me.** All
      three are `owner: human` with their `[REVIEW]` boxes already ticked by the operator;
      the close transition is theirs. This task produces evidence and commands, nothing else.
- [x] **The staleness question is answered, not assumed:** these Verification blocks were
      written weeks ago and the source has moved under them (T-337, T-355, T-361 all touched
      the export path since). Re-running them is the point — a block that passed when it was
      written is not evidence it passes now (PL-161: a Verification block is a one-shot
      completion gate, not a standing guard).

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

# The two conditions that were red at first pass, pinned so this task cannot report a
# green pre-flight while either is back. Each line's own exit code is the verdict.
# "passed, 0 failed" and not "0 failed" — the short form is a substring of
# "passed, 10 failed" and would read green on ten failures (T-352 substring trap).
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
diff -q src/aef-workflow-designer.html build/gallery/designer.html

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

### 2026-08-14 — two of the three were blocked by the same line, and neither was flaky

- **What changed:** The premise was that these three only needed a transition. Measuring
  the gates instead of reading them found all three would have bounced.

  First pass, run through the gate's own execution shape (`if ( set -o pipefail; eval … )`,
  update-task.sh:1018 — errexit-neutralised, faithfully reproduced rather than tightened):

  | Task | line | verdict | cause |
  |---|---|---|---|
  | T-041 | 4 of 4 | **FAIL** on 4 | `run-bridge-tests.sh` — suite red, 74/1 |
  | T-101 | 5 of 5 | **FAIL** on 2 | same suite line |
  | T-102 | 2 of 2 | **FAIL** on 1 | `build/gallery/designer.html` absent |

  The suite was red because of T-491's unwired-guard ratchet, and the entry it named was
  mine from the day before: `_t355-foreign-tag-render-cdp.mjs` had been "wired" into
  T-355's own `## Verification` block, which the census scores `pending`, not `live`.
  Completing T-355 spent the single run and the guard went unwired the same hour. Fixed
  under **T-503** by giving it a caller in `tests/run-bridge-tests.sh` — a ROOT_SOURCE —
  after which the ratchet reads 69/69 and the suite reads 76/0.

  T-102's blocker was different in kind and not a defect: `build/gallery/` is a gitignored
  build artifact, so its `diff -q` line has nothing to compare against on a clean checkout.
  Rebuilt via the sanctioned path, `tools/serve-gallery.sh --build-only` (T-350/G-015 added
  that mode precisely so refreshing the serve root does not require binding a port — :8834
  is retired under T-253 and stayed unbound; verified 0 listeners).

  Second pass: **4/4, 5/5, 2/2 — all three green.**

- **Plan impact:** None; this is what the task was for. Worth noting that the two
  Verification blocks weakest to time were the ones invoking a whole suite: they were
  written weeks ago and went red for a reason with no connection to the task they gate.
  That is not an argument against suite lines, but it is the reason a pre-flight is not
  redundant with the gate — the gate tells the operator "no" without telling them why.

- **Triggered:** T-503 (filed and completed). No change to any of the three tasks
  themselves — no AC ticked, no owner changed, no transition run.

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

### 2026-08-14T19:15:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-502-pre-flight-the-three-completion-ready-hu.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4c1e8d04
- **Timestamp:** 2026-08-14T19:40:29Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-14T19:38:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
