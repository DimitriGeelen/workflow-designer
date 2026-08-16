---
id: T-469
name: "Pre-negotiate the T-423 seam re-pin with AEF so the arc's first seam-touching
  step is not blocked on coordination when T-340 is ruled"
description: >
  Pre-negotiate the T-423 seam re-pin with AEF so the arc's first seam-touching step
  is not blocked on coordination when T-340 is ruled

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
created: 2026-08-12T20:01:53Z
last_update: '2026-08-16T13:58:56Z'
date_finished: 2026-08-12T20:06:39Z
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
  - ts: '2026-08-16T12:34:00Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:docs/reports/T-469-t423-seam-repin-blast-radius.md,docs/standards/aef-bpmn-forward-compile-v1.md,docs/standards/aef-bpmn-mapping-v1.md,tests/fixtures/aef-bpmn/boundary-events.bpmn);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-469-t423-seam-repin-blast-radius.md,docs/standards/aef-bpmn-forward-compile-v1.md,docs/standards/aef-bpmn-mapping-v1.md,tests/fixtures/aef-bpmn/boundary-events.bpmn);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-469: Pre-negotiate the T-423 seam re-pin with AEF so the arc's first seam-touching step is not blocked on coordination when T-340 is ruled

## Context

Deliverable: `docs/reports/T-469-t423-seam-repin-blast-radius.md`. Asked on the rail at
**offset 581** (four questions: what they pin, whether they regenerate the 7 export-authored
fixtures, re-pin cost + lead time, preferred announcement shape). Recorded here so a later
window can tell an unanswered question from an unasked one.

Zero bytes of either corpus were touched — leg 2 pins the pre-task tree hash `3443f813ab1ea6b5`
so this task cannot become a way of starting T-423 before its ruling lands.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The pin surface is ENUMERATED from our side with a count, not described: which of our
      artifacts AEF pins by sha, where those pins live on their side, and exactly how many
      corpus maps change bytes when T-423 lands. A re-pin request that cannot state its own
      blast radius is asking the peer to do our measuring (PL-084).
- [x] The measurement distinguishes what we can verify from what we are taking on their word
      (PL-033/PL-034). Our own guard checking our own corpus is internal self-consistency and
      cannot detect a broken promise at the seam; say which half is which rather than
      presenting a single confidence.
- [x] NOTHING IS EMITTED, MIGRATED OR RE-PINNED BY THIS TASK. T-423 is blocked behind T-340's
      ruling and this task must not become a way of starting it early. Deliverable is a
      question and a measurement, not a byte change to any corpus map. Verified mechanically:
      the 24 corpus maps are byte-identical before and after.
- [x] The rail question is posed so it is answerable BEFORE the ruling — i.e. it asks about
      their re-pin PROCESS and its lead time, not about whether we should emit DI. Asking
      them to weigh in on the ruling would route a sovereignty decision through the peer,
      which is not theirs and not mine.
- [x] Posted to AEF with producer attribution, and the task records what was asked so a later
      window can tell an unanswered question from an unasked one.

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

# 1. The deliverable exists and separates the two corpora rather than conflating them.
test -f docs/reports/T-469-t423-seam-repin-blast-radius.md && /usr/bin/grep -qF 'There are two corpora' docs/reports/T-469-t423-seam-repin-blast-radius.md

# 2. NOT ONE BYTE of either corpus moved. This task measures a future change; if it ever
#    starts making one, this leg is what says so. Baseline taken before any work: 3443f813ab1ea6b5
test "$(git ls-files -s examples/aef-processes/rendered/*.bpmn tests/fixtures/aef-bpmn/*.bpmn | sha256sum | cut -c1-16)" = "3443f813ab1ea6b5"

# 3. The three high-cost artifacts are safe for the SOUND reason (they lack the exporter's
#    unconditional trailer), not because a table says so. Re-derived here, not restated.
! /usr/bin/grep -lq 'BPMN DI (visual layout) omitted' tests/fixtures/aef-bpmn/typed-events.bpmn tests/fixtures/aef-bpmn/boundary-events.bpmn tests/fixtures/aef-bpmn/inception-gonogo.bpmn 2>/dev/null

# 4. ...and the probe can see the marker at all, so leg 3 is not passing because the string
#    changed or the paths are wrong (PL-084 — a negative assertion needs a positive control).
test "$(git ls-files 'tests/fixtures/aef-bpmn/*.bpmn' | while read -r f; do /usr/bin/grep -lq 'BPMN DI (visual layout) omitted' "$f" 2>/dev/null && echo x; done | wc -l)" = "7"

# 5. The counts the report asserts are the counts on disk.
test "$(git ls-files 'examples/aef-processes/rendered/*.bpmn' | wc -l)" = "24" && test "$(git ls-files 'tests/fixtures/aef-bpmn/*.bpmn' | wc -l)" = "20"

# 6. The frozen standard still names the fixture path this task reasoned about — if that
#    reference moves, the report's standard-exposure analysis is stale.
/usr/bin/grep -qF 'tests/fixtures/aef-bpmn/inception-gonogo.bpmn' docs/standards/aef-bpmn-mapping-v1.md

# 7. The frozen standard was not edited by this task (it must not be, under agent control).
git diff --quiet HEAD -- docs/standards/aef-bpmn-mapping-v1.md docs/standards/aef-bpmn-forward-compile-v1.md

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

### 2026-08-12T20:01:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-469-pre-negotiate-the-t-423-seam-re-pin-with.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d87ee8c9
- **Timestamp:** 2026-08-12T20:06:40Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T20:06:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
