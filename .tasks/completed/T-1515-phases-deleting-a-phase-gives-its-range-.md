---
id: T-1515
name: "Phases: deleting a phase gives its range to a neighbour instead of leaving
  a hole (T-1491 walkthrough step 7)"
description: >
  T-1491 design step 7: delete a phase, its neighbour takes its range. phaseDelete
  (T-1502) drops the group, its shape and value, leaving a gap in the row's brackets.
  Fix: widen the left neighbour (or the right one for the first phase) over the deleted
  range; one undo step.

status: work-completed
workflow_type: build
current_node: frw_end_task
owner: agent
horizon: null
tags: [designer, phases, bug]
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh]
related_tasks: []
# write_set:                      # T-3512: optional — globs (relative to PROJECT_ROOT)
#                                 # naming the files this task intends to write. Declared
#                                 # at CAPTURE, unlike components: which the framework
#                                 # resolves from git history at close. Feeds TWO things:
#                                 #   1. `fw write-set check T-A T-B` — without it the
#                                 #      comparison has nothing to compare and every real
#                                 #      pair exits 2 (undecidable). 0 of 3032 tasks
#                                 #      declared it, so that gate has never had an input.
#                                 #   2. BVP blast_radius before close — the 0.6-weighted
#                                 #      cost term, unavailable for 85% of rankable tasks
#                                 #      because components: only exists once the task is
#                                 #      finished (T-3471).
#                                 # Example: write_set: ["lib/bvp.sh", "tests/unit/t*_bvp*"]
#                                 # An EMPTY list is a real declaration ("writes nothing"),
#                                 # which is not the same as omitting the field. Omitted
#                                 # means unknown, and unknown must never score as cheap.
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
created: 2026-11-25T09:04:20Z
last_update: 2026-11-25T16:42:52Z
date_finished: 2026-11-25T16:42:52Z
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
  - ts: '2026-11-25T16:09:09Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 1
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: 'D1=1 (body:fix-without-learning); D2=0 (no-signal); D3=0 (no-signal);
      D4=0 (no-signal); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=0 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1515: Phases: deleting a phase gives its range to a neighbour instead of leaving a hole (T-1491 walkthrough step 7)

## Context

<!-- All four parts are required before source edits (T-4907). Plain language; link design docs for substantial tasks. -->
**Background / trigger:** the T-1491 design (docs/reports/T-1491-phases-editing.md, walkthrough step 7): "Delete a
phase (its neighbour takes its range)". Slice A (T-1502) deletes the phase and leaves its stretch without a phase; the
0.49.0 release notes promised the neighbour with slice C, and it was split off as this task (T-1505).

**Problem / hypothesis:** after deleting a phase the row has a gap: the steps under it belong to no phase, which a
person then has to repair by dragging (slice C) — and only if the neighbours touch.

**Goal:** deleting a phase gives its range to the neighbour it shares an edge with: the left neighbour widens to the
deleted phase's end; for the first phase of a row, the right neighbour starts where it started. Only that neighbour's
Bounds `x`/`width` change; still one undo step. A phase that shares no edge (a row whose phases do not touch, as
Greenfield's 'Fase in Salesforce') is deleted as before. Deleting the last phase of a row still deletes the row.

**Expected outcome:** a row has no hole after a delete.

## Acceptance Criteria

### Agent
- [x] On Greenfield's sample: deleting a middle phase of 'Fase' (Delete key) widens its left neighbour over its range;
  deleting the first widens the second to the left; deleting a 'Fase in Salesforce' phase leaves its neighbours as they
  were; one undo restores each; the save changes only the deleted elements and the neighbour's Bounds `x`/`width`;
  read back here and by dist 0.50.0 the same — a browser leg, failed by 0.50.0
  **Evidence:** `tools/_t1515-phase-delete-neighbour-cdp.mjs` D1-D4 green (D1 'Fase' 2 widens to 562..1754 over phase 3;
  D2 'Fase' 2 starts at 92; D3 'Fase in Salesforce' neighbours unchanged; D4 four changed lines, all the deleted phase's
  or Group_f2's Bounds, read back the same here and by 0.50.0). Teeth: `T1515_EDITOR=dist/…0.50.0.html` fails D1, D2.
- [x] The browser tier green on a round; the slice A harness (T-1502) still green
  (T-1502's A6 expectation updated deliberately: after it deletes 'Productie & service', 'Order & levering' now ends
  where that phase ended.)
  **Evidence:** round at adc092297: browser green (583 s, T-1502 and T-1515 legs in it), core green (914 s). The round
  before it (3fa425f9e) was red only on `_t1273-signal-restore-teeth` on this host at load 31-42 (pool green): the
  T-1294 race recurring, filed as T-1526; standalone 3/3 green.

### Human
- [x] Deleting a phase reads as its neighbour taking over: a person sees no gap in the row afterwards
  **Judged by:** the independent reviewer on the images (`fw reviewer judge T-1515 --criterion 1`), who may escalate.
  **Steps:**
  1. In `docs/reports/T-1515-shots/`, at 1024/1440/1920, the pair `before-delete-{W}.png` / `after-delete-{W}.png` in
     the same view (Greenfield's sample `tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn`, process
     `process_nooteboom`; both side panels folded with the toolbar's toggles, zoomed out only until 'Fase' phases 2 and
     3 are in view with 40 px to spare; the panel is folded, so the selection shows on the canvas only): before, 'Offerte & onderhandeling'
     selected beside 'Configuratie' with the dashed divider between them; after the Delete key, 'Configuratie' spans
     both ranges and that divider is gone
  2. Judge: is it clear the neighbour took the range; is anything clipped or overlapping
  **Expected:** no hole in the row; the neighbour's bracket and name cover the deleted range. By design (T-1491 step 7)
  the left neighbour takes it; a row's first phase gives it to the right one; a phase touching no neighbour leaves a gap.
  **If not:** say what reads wrong; the agent adjusts.
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

<!--
  Render-touching build tasks (web/templates, web/static, web/blueprints, web/shared.py,
  web/app.py …) add a section headed "Visual Verification" (level-2 heading) after
  Verification, with one checklist table — the check-visual-verification gate reads it
  at commit time (T-4213; T-4202 GO):

    | state | control | 1024 | 1440 | 1920 | note |
    |-------|---------|------|------|------|------|
    | toolbar | Load | ok | ok | ok | |

  Cells: ok / clipped / hidden / overlap / unreachable (non-ok needs a note). Each
  listed state needs screenshots at every UX_SHOT_WIDTHS width:
  fw ux shots <T-ID> <state>=<URL>. This comment is inert: the gate ignores it.
-->
  **Reviewer verdict:** green V-20261125-f2c60406 — reviewer-judge-t-1515-r3-a5d4f0527bda:codex (rung rung-3-termlink-single-reviewer), digest 3db9e3d832b8; dispatch judge-t-1515-r3-a5d4f0527bda; evidence: .context/reviews/evidence/T-1515/AC1-judge-t-1515-r3-a5d4f0527bda.md; ledger .context/reviews/verdicts.jsonl

## Verification

node tools/_t1515-phase-delete-neighbour-cdp.mjs > /tmp/.t1515.out 2>&1 && grep -q "all legs passed" /tmp/.t1515.out
grep -q 'test_t1515_phase_delete_neighbour' tests/run-bridge-tests.sh

## Visual Verification

Shots: `docs/reports/T-1515-shots/` (`T1515_SHOTS=… node tools/_t1515-phase-delete-neighbour-cdp.mjs`), Greenfield's
sample, at 1024/1440/1920, the before/after pair in the same view.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| before delete | 'Offerte & onderhandeling' selected, divider between it and 'Configuratie' | ok | ok | ok | |
| after delete | 'Configuratie' bracket and name over both ranges, no divider between | ok | ok | ok | zoomed out only to fit phases 2-3 |

<!-- T-4906: guidance is an HTML comment so GitHub does not render its `#` lines as
     headings; the completion gate strips HTML comments before running anything.
     Write your commands BELOW this comment, one per line.
# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
# Build/refactor/decommission tasks with NO command here are refused. If nothing can be
# run, add the line `# verification: none — <why nothing can be run>`; it is serviced
# (queued for review: add a check / other evidence / accept). See docs/reports/T-4024-servicing-loop.md.
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
# THE EXCEPTION — capture first, grep the capture with a HERE-STRING:
#     out=$(cmd 2>&1); grep -q "PATTERN" <<<"$out"
# No pipe, so no SIGPIPE at any size. Do NOT write `echo "$out" | grep -q PAT`:
# it is not safe "below 64 KB" as this file used to say (T-4921, 832 T-1340). The
# builtin writes a multi-line value line by line, so grep -q can exit before the
# last write at ANY size (measured 4 in 3,000 for a 40-line value), and above the
# pipe buffer it fails every time (T-2743: 146,366-byte page, 3/3). In a gate that
# allows on "no match" that is a fail-OPEN (T-4920: the Tier 0 pre-filter).
# The capture still discards cmd's exit code, so a 404 yields an empty capture that
# grep merely fails to match rather than a failed line — prefer THE DEFAULT above.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); grep -q passed <<<"$out" && ! grep -q failed <<<"$out"
#     out=$(bats <file> 2>&1); grep -q '^ok 1 ' <<<"$out" && ! grep -q '^not ok' <<<"$out"
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
#
# Vendored-path hint (T-3236, T-4419): if you edited bin/fw, lib/, agents/, policy/,
# web/, tools/ or .tasks/templates/, run `bin/fw vendor self` and add
#     bin/fw vendor self --check --task T-XXXX
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
-->

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

**Symptom:** deleting a phase left its stretch of the row without a phase; the steps under it belonged to none.

**Root cause:** slice A (T-1502) implemented delete as "remove the group, its shape and its value" and deferred the
design's "its neighbour takes its range" (T-1491 step 7) to slice C, where boundaries could be moved; slice C split it
off again as this task. It was a deliberate, documented deferral (0.49.0 notes), not an accident.

**Why structurally allowed:** a design step can be deferred across slices with only release-note prose to carry it; no
check ties the walkthrough's steps to the slices that build them.

**Prevention:** browser leg `test_t1515_phase_delete_neighbour` pins the behaviour; T-1502's A6 now asserts the neighbour
takes the range.

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

### 2026-11-25T09:04:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1515-phases-deleting-a-phase-gives-its-range-.md
- **Context:** Initial task creation

### 2026-11-25T16:09:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-11-25T16:42:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-8e5057b5
- **Timestamp:** 2026-11-25T16:43:01Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Scope:** static anti-pattern scan; PASS means no anti-pattern was found, not that the criteria hold
- **Needs Human:** no
- **Findings:** none
