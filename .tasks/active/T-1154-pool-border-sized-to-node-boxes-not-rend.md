---
id: T-1154
name: "Pool border sized to node boxes, not rendered labels: contentRightEdge()/poolHeight()
  let right-most below-labels overhang the pool"
description: >
  Promoted from OBS-314 by T-1149 (observation triage, 2026-10-13). I found no task
  that sizes the pool to label extents. The only task hits are T-043, T-050 and T-255,
  which cover the box-based contentRightEdge and the page-width floor; none addresses
  label overhang. Not re-measured. The finding was kept out of T-601 on purpose and
  has no carrier. Original observation text is in .context/inbox.yaml under OBS-314.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: [observations]
components: []
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
#                                 # `fw work-on T-1154` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-13T16:20:56Z
last_update: 2026-10-17T16:17:01Z
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
  - ts: '2026-10-17T16:17:02Z'
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
      so this score has no claim to be wrong about,L1:keyword=pool); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=3 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L3:keyword=promote)'
    rubric_sha: e4a00f38e801
---

# T-1154: Pool border sized to node boxes, not rendered labels: contentRightEdge()/poolHeight() let right-most below-labels overhang the pool

## Context

OBS-314 (T-601, 2026-08-26): `contentRightEdge()` encloses the right-most node BOX (+60 margin), not its label, so a
below-label centred on the right-most node can overhang the pool border; `poolHeight()` may do the same at the bottom.
Never re-measured since. Constraint found on reading: the BPMN export writes the pool's DI width from
`contentRightEdge()` (src line ~12557), so sizing it from RENDERED text would make saved files depend on font
measurement (machine-dependent bytes; T-358 export determinism). The fix must keep the export deterministic.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Measured first on the 24-map corpus with designer 0.20.0: per map, how far any rendered node label reaches past the pool's right border and below its bottom border; numbers recorded here. If nothing overhangs, the task closes as not reproduced with that measurement — 2026-10-17, 1440 px, label size m (scratch t1154-measure.mjs): node labels past the RIGHT border in 1 of 24 maps (healing-loop +3 px, "Resolved & recorded (antifragi…"); 5 more within 1-9 px (task-lifecycle -1, session-handover -2, arc-lifecycle -8, inception-lifecycle -9, inception-review -13). Labels past the BOTTOM: none (worst -6; the lane fit already reserves below-label room, LANE_FIT_LABEL). Id badges: right +38 (session-handover), bottom up to +6 on many maps. Reproduced on the right edge; the bottom is a badge-only matter (see Decisions)
- [x] If reproduced: the DRAWN pool (border, header band, lane backgrounds) encloses every rendered node label on the right and at the bottom with a margin; no node moves — right edge: labels and badges now >= 11 px inside on all 24 maps; bottom: labels already inside (measured), badge-only overhang left by decision (see Decisions)
- [x] The BPMN export stays independent of text measurement: byte-identical across two loads and across label sizes s/m/l, and the corpus checks stay green (`_t1168-node-id-map.mjs --check`); any change in exported bytes is stated and justified here — no exported byte changes: the pad never reaches buildBpmnXml (identical with pad forced to 0; the T-1119 collaboration's pool DI width stays box-based with a 100 px pad drawn); identical across s/m/l
- [x] CDP regression test on a fixture with a long label under the right-most node and in the bottom lane; the pre-change designer fails it (control); wired into the bridge suite — `tools/_t1154-pool-label-fit-cdp.mjs` 7/7; control: pre-change designer 1/7 (long label +113 px). Bottom-lane leg dropped with the bottom decision
- [x] Screenshots at 1024, 1440 and 1920 of the fixture (fit and zoomed), read control by control in `## Visual Verification`

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
         1. Run `bin/fw reviewer T-1154`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1154 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->
- [ ] [REVIEW] The pool border visibly encloses the long label under the right-most node, and the widened pool looks intentional (header band and lanes widen with it), at every width
  **Steps:**
  1. Open the screenshots listed in `## Visual Verification` (t1154-{1024,1440,1920}-{fit,zoomed}.png)
  2. In each: the label "Resolved, recorded and promoted to a durable project learning" and its id badge end inside the pool's right border, with a visible gap; the pool header band and every lane background reach the same right edge; nothing else in the canvas or chrome is clipped or overlapped
  **Expected:** step 2 holds in all six screenshots
  **If not:** name the screenshot and what is wrong (label touching or crossing the border, a band or lane shorter than the border, a clipped control)

## Verification

node tools/_t1154-pool-label-fit-cdp.mjs > /tmp/.t1154 2>&1 && grep -q 'PASS: 7/7' /tmp/.t1154
node tools/_t1091-sticky-lanes-cdp.mjs > /tmp/.t1154s 2>&1 && grep -q 'PASS: 31/31' /tmp/.t1154s
node tools/_t601-lane-boundary.mjs > /tmp/.t1154p 2>&1 && grep -q '^PASS' /tmp/.t1154p
node tools/_t1168-node-id-map.mjs --check > /tmp/.t1154c 2>&1
grep -q '_t1154-pool-label-fit-cdp.mjs' tests/run-bridge-tests.sh

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

## Visual Verification

Screenshots from `node tools/_t1154-pool-label-fit-cdp.mjs`: map healing-loop (the corpus map that overhung) with the
right-most end event renamed "Resolved, recorded and promoted to a durable project learning", in `.playwright-mcp/`:
t1154-{1024,1440,1920}-{fit,zoomed}.png (zoomed = 160%, scrolled to the right edge). Read by the author:

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| fit | pool right border vs long label + badge | ok | ok | ok | label and frw_end_resolved end inside the border; small at fit, gap visible at 1920 |
| zoomed | pool right border vs long label + badge | ok | ok | ok | ~20 px gap between label end and border at 1024 (644 vs 664), similar at 1440/1920 |
| zoomed | pool header band, lane backgrounds, dividers | ok | ok | ok | all reach the widened border; no short band |
| zoomed | sticky lane names (T-1091) | ok | ok | ok | pinned at the left edge (scrolled right); the end event at 1024 sits partly under the strip, as T-1091 documents |
| all | toolbar, panels, fold tabs | ok | ok | ok | unchanged; "Restored your unsaved work" toast is the existing autosave notice |

## RCA

**Symptom:** a label or id badge under the right-most node could reach past the pool's right border (measured: healing-loop
label +3 px, session-handover badge +38 px; a long end-event label +113 px).
**Root cause:** the pool is sized by `contentRightEdge()` = right-most node BOX + 60 px; labels and badges are drawn after
the pool and were never measured against it.
**Why structurally allowed:** the box-based edge is shared by the BPMN export (which must stay text-measurement-free) and by
the T-601 placement scorer, so the drawing reused it; no check compared rendered text to the border (OBS-314 was noted
in T-601 and left without a carrier until T-1149's triage).
**Prevention:** `tools/_t1154-pool-label-fit-cdp.mjs` in the bridge suite checks all 24 corpus maps and a long-label fixture
against the drawn border, and that the export stays pad-free.

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

### 2026-10-17 — Widen the DRAWN pool, not contentRightEdge()
- **Chose:** after renderNodes, measure rendered labels and badges; redraw the pool wider by the overhang + 12 px
  (`poolLabelPad`). Export, T-601 placement scoring and the page-width drag keep the box edge.
- **Why:** contentRightEdge() feeds the BPMN export; text measurement there would make saved bytes depend on fonts.
  The scorer must not see the pad (it is derived from placement: feedback loop).
- **Rejected:** a character-count width estimate in contentRightEdge() (deterministic but approximate, and it would
  change exported bytes for corpus maps near the edge).

### 2026-10-17 — Bottom edge left as is
- **Chose:** no change at the bottom. Labels never overhang it (worst -6 px): the lane fit already reserves room for
  below-labels (LANE_FIT_LABEL). Only id badges reach up to 6 px below on some maps.
- **Why:** lane heights are document state (saved); growing them for a badge is a separate question, not this defect.
- **Rejected:** widening the drawn bottom lane only (the drawn and saved lane heights would disagree, and lane resize
  handles act on the saved height).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1154 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-13T16:20:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1154-pool-border-sized-to-node-boxes-not-rend.md
- **Context:** Initial task creation

### 2026-10-17T16:17:01Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)
