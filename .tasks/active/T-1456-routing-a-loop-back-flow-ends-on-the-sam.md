---
id: T-1456
name: "Routing: a loop-back flow ends on the same side as the step's outgoing flow
  (arrowheads overlap) and detours through a foreign lane (Greenfield 6)"
description: >
  Split from T-1449 (docs/reports/T-1449-greenfield-layout-repro.md, Greenfield msg
  ef63bb29 item 6). On the Greenfield fixture: the 'wel' flow from gateway Redesign
  ends on the RIGHT side of Opportunity/Solution at (681,318), 4 px from that step's
  outgoing flow at (681,314), so the arrowheads overlap; its route dips to y 381 inside
  the Novis lane though both ends are in Tacton. Expected: an incoming flow does not
  end on a side an outgoing flow leaves from (or keeps a clear gap), and a flow between
  two steps of one lane does not cross into another lane when a route inside the lane
  exists.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: []
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
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-11-19T22:56:13Z
last_update: 2026-11-20T09:34:27Z
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
  - ts: '2026-11-20T09:34:11Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 2
      F3: 0
      F1: 0
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=2 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=0 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L0: no signal)'
    rubric_sha: e4a00f38e801
---

# T-1456: Routing: a loop-back flow ends on the same side as the step's outgoing flow (arrowheads overlap) and detours through a foreign lane (Greenfield 6)

## Context

<!-- All four parts are required before source edits (T-4907). Plain language; link design docs for substantial tasks. -->
**Background / trigger:** Greenfield msg ef63bb29 item 6, reproduced by T-1449
(`docs/reports/T-1449-greenfield-layout-repro.md`) on `tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn`:
the 'wel' flow (Flow_11, gateway Redesign -> Opportunity/Solution, both in lane Tacton) ends on the RIGHT side of
Opportunity/Solution 4 px from that step's outgoing flow (arrowheads overlap), and dips to y 381 inside lane Novis.

**Problem / hypothesis:** two candidate causes, to be told apart by a probe before any fix:
(H1) the loop-back router (`orthoLoopBack`) always adds its two fallback detour heights even when they lie outside
the lanes the flow connects, and Tacton is too tight for a clamped height below the gateway's label; (H2) the flow
carries Greenfield's own DI waypoints (y 378, inside Tacton in THEIR coordinates: lanes 170 px), which the designer
keeps while it lays the lanes out at its own heights, so the stored bend falls into Novis. Neither explains the
side choice alone: the router does not look at which sides other flows already use.

**Goal:** a flow whose two ends share a lane stays inside that lane when a route inside it exists, and an incoming
flow does not end on the side (and at the point) an outgoing flow of the same step leaves from.

**Expected outcome:** on the Greenfield fixture the 'wel' loop stays in Tacton and its arrowhead is clear of
Opportunity/Solution's outgoing flow; corpus maps' routing otherwise unchanged except where it had the same faults.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The cause is named from a probe of the drawn geometry (H1, H2 or another), recorded in the task with the numbers.
      Evidence: ## RCA — H1 (crossings by bar height for 'wel': 208-272 -> 0 inside Tacton, 376-400 -> 0 in Novis;
      interior penalty 10 vs closeness 0.28); H2 ruled out (no waypoints in the designer); the arrowhead from the
      straight outgoing flow being snapped back to the centre line (4 px).
- [x] On the Greenfield fixture, at 1024/1440/1920, the 'wel' path's every point lies inside lane Tacton, and its
      end on Opportunity/Solution is on a different side from that step's outgoing flow's start, or >= 12 px from it.
      Evidence: `_t1456` F1/F2 at all three widths: ys 309..256..302 inside 192-322; 12 px from the outgoing start.
- [x] Across the 24 corpus maps and the Greenfield fixture: no flow between two steps of one lane leaves that lane
      when a route inside exists, and no incoming end lies within 8 px of an outgoing start on the same step side
      (counts before/after recorded; none new).
      Evidence: before L 4, S 1; after L 0, S 0 (C1). Excused and listed: git-commit-flow 'blocked' (route set by
      the author), task-gate 're-issue' (every bar inside its lane cuts a step), upgrade-process 'dry-run' (known,
      T-1459). All 340 drawn flows compared: 18 change, none that was straight bends.
- [x] A CDP harness checks both on the fixture and the corpus, is a browser-tier leg, and fails on the 0.44.0
      designer; the existing routing harnesses stay green.
      Evidence: `tools/_t1456-routing-lanes-sides-cdp.mjs` (F1-F3 x3 + C1), leg `test_t1456_routing_lanes_sides`; on
      0.44.0 7 legs fail. Fallout fixed at its causes: label-clearance (56 -> 0, the narrowed rule), authority marker
      (_t1069, measures real ends), saved bytes (_t1129 E, _t1447 N5: the 16 re-routed edges named). On the pool the
      harness needed one browser per load (the pool's TasksMax=256, T-1463).
- [x] `bash tools/person-sees-gate.sh` exits 0 and the browser tier is green.
      Evidence: person-sees exit 0 on 5b6dad258 (label-clearance 0); browser tier for 30a2041d7 green on the pool as two
      shards (pool-w1 78/0, pool-w2 73/0) and here 151/0 (build/tiergate/tier-browser.runs.log 14:53Z).

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
- [ ] [REVIEW] The changed routes read better than before: the Greenfield 'wel' loop, and the two corpus maps whose
  routes changed most.
  **Why you:** whether a route reads well (crossings against staying inside the lanes) is a judgement on images.
  **Judged by:** the independent reviewer on the images (`fw reviewer judge T-1456 --criterion 1`), who may escalate.
  **Steps:**
  1. `docs/reports/T-1456-shots/greenfield-wel-{1024,1440,1920}-{before,after}.png`: after, the 'wel' loop runs inside
     lane Tacton (above the steps, not through Novis) and its arrowhead on Opportunity/Solution stands clear of that
     step's outgoing flow (12 px; before 4 px, overlapping).
  2. `docs/reports/T-1456-shots/task-lifecycle-rework-1440-{before,after}.png`: 'gate failed — rework' before ran under
     the last lane, through the "+ Add another lane" strip, its label colliding with that button; after it runs inside
     the lanes it connects, along the top, label clear, crossing two flows' lines. Judge which reads better.
  3. `docs/reports/T-1456-shots/task-gate-block-1440-{before,after}.png`: unchanged on purpose (a short side keeps its
     even spread).
  **Expected:** after reads at least as well as before in each pair, and better for 'wel'.
  **If not:** name the pair and what reads worse; the agent adjusts the rule and re-measures.

## Verification

node tools/_t1456-routing-lanes-sides-cdp.mjs
grep -q "test_t1456_routing_lanes_sides" tests/run-bridge-tests.sh

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

## RCA

**Lane (H1, measured 2026-11-20).** `orthoLoopBack` scores bar heights by crossings x100 + interior penalty 10 (content
above AND below the bar) + closeness. Inside Tacton every bar has Salesforce steps above it (interior 10); the
always-added fallback "just below the lower step" (y 381) lies in Novis with nothing below it (interior 0, closeness
0.28). Crossings by height for 'wel': y 208-272 -> 0 (inside Tacton), 280-368 -> 3, 376-400 -> 0 (Novis). Leaving
the connected lanes cost nothing. The same fault on the corpus: git-commit-flow 'blocked' (a detour height set in the
file, clamped below the lane), task-gate 're-issue' (every bar inside its 96 px lane cuts a step), upgrade-process
'dry-run' (another class: T-1459). H2 (Greenfield's DI waypoints kept) was ruled out: the flow has no waypoints in the
designer; its file bends are kept only for saving (diKept).

**Arrowhead.** `spreadOffset` spaced every end on a side at the 'middle' pitch (8 px), so an incoming end sat 4 px from
an outgoing start; the outgoing flow runs straight and straightening snaps it back to the centre line, so only the
incoming end ever moved.

**Also found (separate tasks):** T-1460 (lanes redrawn at 130 px on import, steps hang 24 px into the next lane),
T-1459 (a flow into its target's far side drawn as a loop through the target's own box).

## Decisions

### 2026-11-20 — Two scoring changes, measured against every drawn flow of the corpus
- **Chose:** (1) a bar outside the lanes the flow connects costs 50 (more than an interior bar's 10, less than one
  cut step's 100); (2) on a side that mixes incoming and outgoing ends, and ONLY where the ends as they actually land
  (a straight end snapped onto the centre line, the rest at the even spread) put an incoming end closer than the
  pitch to an outgoing one: the straight ends keep their place (else the outgoing ones) and the others move out an
  arrowhead (12 px) beside them, where that fits on the side.
- **Why:** each was tried and measured on all 340 drawn flows (24 corpus maps + the fixture). A first version (wider
  pitch for mixed sides) bent 7 straight flows; "incoming always yields" bent straight incoming flows; clamping on a
  short side put two ends on one point (task-gate); re-spreading EVERY mixed side at 16 px (then 12) moved
  aef-task-lifecycle's 'shelved' label onto flow tl_e15 (person-sees label-clearance: 56 errors). The real fault is
  only the snap: the even spread puts a straight end off-centre, straightening pulls it back, and its neighbour is
  left half a pitch away (Greenfield 4 px). The final rule changes 18 of 340 flows, bends none that was straight,
  adds no close pair or lane exit, and label-clearance is clean.
- **Rejected:** forbidding a foreign lane outright (where every in-lane bar cuts a step, leaving is the lesser fault);
  entering the far side (top) for a loop from above (a deeper port change; not needed once the ends are apart).

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

### 2026-11-19T22:56:13Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1456-routing-a-loop-back-flow-ends-on-the-sam.md
- **Context:** Initial task creation

### 2026-11-20T09:34:09Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-11-20T09:34:27Z — status-update [task-update-agent]
- **Change:** horizon: now → now
