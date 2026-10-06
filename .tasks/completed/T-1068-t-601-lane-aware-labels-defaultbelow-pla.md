---
id: T-1068
name: "T-601 lane-aware labels: default/below placement still lands on the lane header
  strip, and the L2 divider leg does not fail under its own poison arm"
description: >
  Independent reviewer RED (fw reviewer judge T-601; .context/reviews/evidence/T-601/AC1-judge-t-601-r1-25b7ca42497b.md).
  Needed: clear POOL_X + LANE_HEADER for below/default placement (or stop a tie restoring
  an on-header placement); a leg on the DEFAULT map asserting no event/gateway label
  line has x1 < POOL_X + LANE_HEADER; repair the L2 divider leg so it fails under
  the poison arm (score the block against the node's band); then re-review the readability
  trade on a real corpus map.

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: []
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh, tools/_t600-label-wrap.mjs, tools/_t601-lane-boundary.mjs]
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
#                                 # `fw work-on T-1068` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-06T09:49:30Z
last_update: 2026-10-06T18:41:47Z
date_finished: 2026-10-06T18:41:47Z
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
  - ts: '2026-10-06T11:15:06Z'
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
      F1: 0
    rationale: 'D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=3
      (body:component-discoverability); D4=2 (body:env-class-handled); F-RECALL=2
      (body:lightly-promoted); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=0 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1068: T-601 lane-aware labels: default/below placement still lands on the lane header strip, and the L2 divider leg does not fail under its own poison arm

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] F1: no event/gateway label line in the DEFAULT map starts left of POOL_X + LANE_HEADER (the "Investigation requested" block is nudged clear of the header strip); a leg asserts it on the default map, with a control showing the pre-fix editor fails it
- [x] F3: the divider term scores the label BLOCK, not line by line (a block split across or sitting in the next lane is penalised); `_t601 --self-test` passes again, i.e. L2 goes red when the pool term is removed
- [x] T-600/T-601/T-1067 legs still pass; screenshots of the default map's left edge and the T-601 case read; re-judged by the independent reviewer

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
         1. Run `bin/fw reviewer T-1068`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1068 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

node tools/_t601-lane-boundary.mjs --self-test
node tools/_t600-label-wrap.mjs --self-test
node tools/_t1067-side-label-wrap-cdp.mjs
node tools/_t1068-corpus-labels.mjs --self-test

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
     fw inception decide T-1068 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-06T09:49:30Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1068-t-601-lane-aware-labels-defaultbelow-pla.md
- **Context:** Initial task creation

### 2026-10-06T11:15:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-10-06T12:30Z — T-600 self-test repaired; F1/F3 met [agent]
The previous session stopped at its 95% context cap with `_t600-label-wrap.mjs --self-test` red
("L3 passed under poison"). Code search: red since T-601 itself (a51e6235, found by a binary
search over the 32 editor commits from T-600 on; 1d383648 green, adcd5af1 green, a51e6235 red).
Cause: L3 measured the first below-node of the default document, which sits at the pool's left
edge; once T-601 penalised the lane header it stays BELOW its shape, where the wrap pass sets y
explicitly and document order cannot show. The order matters only beside the shape
(adjustLabelPlacements stacks in document order). Fix: L3 now walks the below-nodes and measures
the first whose long name lands beside its shape; poison B now patches all 3 insert sites
(T-1067 added the third). Not reached by the bridge suite until this task wired it, which is why
it went unnoticed for six weeks.
Evidence: `_t600 --self-test` PASS (7 live, 4 proven failable; arm B L3 badge y=474 < 498);
`_t601 --self-test` PASS (6 live, 4 proven failable; poison L2 4 rects outside lane);
F1 control: the pre-fix editor (c44bd201) FAILS the new L6 ("Investigation requested@85.3" < 90);
`_t1067` 6/6. Screenshots read: default-left-after clears the header strip; t601-after moves the
long label off the header and divider to the right of the start event, where the outgoing edge
runs through the block. That trade is the reviewer's call (AC 3), not ticked here.

### 2026-10-06T13:05Z — independent reviewer: RED on T-601 AC1 (verdict 7d9d6f4e) [agent]
Evidence: `.context/reviews/evidence/T-601/AC1-judge-t-601-r1-b0c0fde028d9.md` (revision 403d2449).
Corpus probe over all 24 rendered maps (141 event/gateway labels; furniture read from the DOM),
pre-T-601 → HEAD: on header 13→0, outside pool 18→0, past own lane 26→9, label∩edge 93→68.
A large improvement, but RED on single labels:
- occluded by a task box where it used to be legible: session-capture n_start, git-commit-flow n_start,
  arc-lifecycle n_req (also crossed by its connector);
- NEW divider crossing: session-capture g_found. The T-1067 wrapped-block candidate is accepted when
  STRICTLY better and leaves the lane (id badge on the divider);
- cause named by the reviewer: node-box overlap costs 1 per line while header/out-of-pool costs 2, so an
  occluded placement beats a legible misplaced one; the T-1068 x-nudge is never scored.
Next (this task): weight occlusion under a node box at least as heavily as the header; score the wrapped
candidate against the node's own band (no divider crossing); score candidates after the x-nudge; add the
reviewer's corpus probe (or an equivalent) as a leg so these four labels are pinned.

### 2026-10-06T14:10Z — scorer reweighted against the reviewer's findings [agent]
Changes in `adjustLabelPlacements()`:
- every candidate is scored where it will be drawn: nudged off the header strip, unless the nudge
  HIDES more lines under a shape (then the un-nudged position is kept);
- per-line costs: edge 1, outside pool 1, header strip 2, outside own lane 2 (was 1), loose zone
  around a neighbour 1, UNDER a shape 6 (was 1), the node's own shape now counts (6);
- weights chosen by sweeping (occlusion 2-8, lane 2-4, header 1-3, nudge conditional or not) and
  comparing every label with its pre-T-601 placement, as the reviewer judged.
Corpus, reviewer's probe, 141 labels (pre-T-601 → 403d2449 → now):
under a shape 4 → 4 → **0**; header 13 → 0 → 1; lane 26 → 9 → 7; pool 18 → 0 → 3; edge crossings
93 → 68 → 79. New problems vs pre-T-601: 1 (git-commit-flow n_start hangs below into the next lane,
the trade the reviewer accepted for n_send). Sizes S and L: under 0 (was 3 and 4).
Stress (every label the 73-char sentence): under 26 → 13, lane 16 → 9, header 0 → 2.
The four named labels: session-capture n_start back left of the event (its pre-T-601 legible spot,
on the header and outside the pool: nothing else in that corner is readable); g_found one line in
its lane; git-commit-flow n_start and arc-lifecycle n_req wrapped below, legible, hanging past the
pool floor as arc n_req did before T-601. Screenshots read: docs/screenshots/T-1068/corpus/*.png.
Cost, stated: 1 label on the header again (the criterion asks for none) and 11 more edge crossings
than 403d2449. Both are the price of no hidden text; the reviewer re-judges the trade.
New leg `tools/_t1068-corpus-labels.mjs` (wired into the bridge): C1 nothing under a shape, C2 the
four named labels, C3 at most 1 header label; self-test reverts the occlusion weights and C1/C2 FAIL.
Note: placement depends on the viewport (the canvas width feeds contentRightEdge()); the leg uses
the reviewer's 1600x1000 viewport. T-601's poison D now targets the nudge inside bboxScore.

### 2026-10-06T15:30Z — reviewer AMBER (e21a395a) acted on: no label on the header [agent]
Verdict `.context/reviews/evidence/T-601/AC1-judge-t-601-r1-f1fe3c29e5ad.md`: everything from the RED
fixed, nothing regressed vs pre-T-601; one label (session-capture n_start) still on the header strip,
which the Expected rules out, and a legible wrapped-below block was available (my "nothing else is
readable" was wrong).
Cause found: the T-1067 wrapped candidates were built on `orig[0].x`, the single line's position
AFTER its 58px header nudge, so every wrapped block landed on the next task box. Fix: build on the
node's centre. With that, the conditional nudge (keep the header unless the nudge hides text) was no
longer needed and produced the remaining header labels at size L; the nudge is unconditional again.
Final weights per line: edge 1, pool 1, header 2, outside own lane 3, under a shape 10.
Corpus (141 labels, pre-T-601 → e21a395a → now): under 4 → 0 → 0; header 13 → 1 → **0**; lane
26 → 7 → 7; pool 18 → 3 → 2; crossings 93 → 79 → 76. Sizes S and L: under 0, header 0.
New problems vs pre-T-601: 3, all below blocks hanging into the next lane (n_send, accepted in the
first review; git-commit-flow n_start, accepted in the AMBER; session-capture n_start, the fallback
the AMBER prescribed). Stress run (73-char names): under 15 (pre-T-601 14, e21a395a 13), header 0.
Legs: `_t1068-corpus-labels` C3 tightened to 0 header labels; 3 poison arms (occlusion weights,
nudged rebuild, nudge removed). `_t600` arm A now removes both wrap paths (the T-1067 fallback wraps
a long name on its own now that its block is placed right). Screenshots re-read:
docs/screenshots/T-1068/corpus/*-after.png, t601-after.png.

### 2026-10-06T16:40Z — reviewer RED (cd3da166, third round) acted on: long names at the left edge [agent]
Verdict `.context/reviews/evidence/T-601/AC1-judge-t-601-r1-86196b398c7f.md`: real-name corpus clean
(0 header, 0 hidden), but Step 1 of the criterion is a LONG name at the pool's left edge. With the
operator's 73-char sentence on n_start, session-capture, context-memory and git-commit-flow hid words
under the next task box; no gate exercised that.
Cause: the T-1067 wrapped candidates ran only for single-line names; a long name is already wrapped
at the fixed width cap by wrapOverlongBelowLabels(), so that cap-wide block was never narrowed.
Fix: re-wrap candidates also for already-wrapped names, 2 to 7 lines, restoring the lines the label
came with when none wins; hidden text now costs 30 per line, so any lane overhang ranks below it.
Results, all sizes S/M/L (pre-T-601 → cd3da166 → now):
- real names: hidden 4 → 0 → 0; header 13 → 0 → 0; lane 26 → 7 → 2 (S 1, L 1); pool 18 → 2 → 0;
  crossings 93 → 76 → 67. New problems vs pre-T-601: 2 (n_send, session-capture n_start, both below
  blocks overhanging the next lane — accepted in rounds 1 and 2).
- long name on n_start: hidden 3 → 0, header 0.
- every label long (stress): hidden 14 (pre) → 15 → **0**, header 0.
Screenshots read: docs/screenshots/T-1068/longname/*.png — all three readable; the cost is a tall
block into the next lane (session-capture n_start 5 lines into FRAMEWORK AUTHORITY).
Corpus leg: C4 (every start event long) and C5 (every label long), no hidden, no header; 4 poison
arms, the 4th restores the single-line guard and fails C4.

### 2026-10-06T17:30Z — reviewer GREEN on T-601 AC1 (fourth round, 536e52d7) [agent]
Verdict V-20261006-d0449f7c, evidence `.context/reviews/evidence/T-601/AC1-judge-t-601-r1-c120c4a13422.md`;
applied to T-601 (`fw reviewer verdict apply`, owner human → agent). Bridge 248/0 on 536e52d7 (a first
run had 5 audit-reading teeth red that all passed alone and on the rerun; overlap with the 16:45/17:00
cron audits suspected, noted with fw note).
Residual, not blocking (reviewer): in the long-name fallback the last line of a wrapped block can sit in
the lane below (session-capture "during settlement" in FRAMEWORK AUTHORITY); an above-the-event or
wider-but-shorter candidate could be preferred before a line crosses a divider.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a24fa6a8
- **Timestamp:** 2026-10-06T18:42:52Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-10-06T18:41:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
