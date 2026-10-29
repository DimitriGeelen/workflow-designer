---
id: T-1102
name: "Duplicate node ids within one lane: start events inside (event) subprocesses
  rank separately and reuse <lane>_<rank>_<slug> ids of top-level nodes (kitchen-sink:
  lan_3_event x2, lan_5_event x2, lan_6_event x2, lan_8_event = startEvent + subProcess)"
description: >
  Found by T-1088 while reviewing the re-recorded third-party golden tests/goldens/third-party/kitchen-sink.bpmn.golden:
  after the lane-abbr fix 8 duplicate id attributes remain (4 node ids + their BPMNShape
  ids), all in lane 1. Duplicate ids make the saved BPMN invalid. Separate cause from
  T-1088 (lane prefix clash). Check computeDisplayId's ranking for nested nodes and
  whether a slug like 'event' from 'Event-Subprocess' can collide with an event node.

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
#                                 # `fw work-on T-1102` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-08T09:14:37Z
last_update: '2026-10-29T00:26:23Z'
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
  - ts: '2026-10-29T00:26:23Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 0
      F1: 2
    rationale: 'D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 (no-signal);
      F-RECALL=0 (no-signal); F2=0 (no-signal); F4=1 (basis: task body — no hypothesis,
      so this score has no claim to be wrong about,L1:keyword=lane); F3=0 (basis:
      task body — no hypothesis, so this score has no claim to be wrong about,L0:
      no signal); F1=2 (basis: task body — no hypothesis, so this score has no claim
      to be wrong about,L2:keyword=export)'
    rubric_sha: e4a00f38e801
---

# T-1102: Duplicate node ids within one lane: start events inside (event) subprocesses rank separately and reuse <lane>_<rank>_<slug> ids of top-level nodes (kitchen-sink: lan_3_event x2, lan_5_event x2, lan_6_event x2, lan_8_event = startEvent + subProcess)

## Context

Two distinct nodes can get the same display id, and the display id IS the saved element id, so the export is invalid
BPMN (an id must be unique in a document). Seen on kitchen-sink (filed 2026-10-08; again 2026-10-28 as T-1332:
`lan_end_event` x2, `lan_start_event`, `lan_start_event_2` x2), events inside subprocesses.

## Acceptance Criteria

### Agent
- [ ] The cause is shown in `computeDisplayId` / `refreshDisplayIds` (why two nodes get one id), not assumed.
- [ ] Every display id in a map is unique: every corpus map and every third-party fixture saves with no repeated
      `id` value; designer-written maps whose ids are already unique keep exactly the ids they had (byte-identical).
- [ ] A browser harness proves it on kitchen-sink and on a minimal case, red on the pre-T-1102 source; the
      third-party goldens that change are re-recorded deliberately, each changed line checked.
- [ ] Core tier green.

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
         1. Run `bin/fw reviewer T-1102`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1102 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->
- [ ] **Shown as a person sees it:** on kitchen-sink at 1024, 1440 and 1920, the node labels under the events read as
  distinct ids — the events inside the event-subprocess (in no lane) now read `la3_start_event…`, the events in lane
  `Lane_1cofr07` (abbreviation `lan`) keep `lan_start_event…`, and lane "Lane" (`Lane_1vakzes`) keeps `la2_…` — and
  nothing else on screen changed (toolbar, notice, panels as before).
  Screenshots in `docs/reports/T-1102-evidence/` (full pages, and `kitchen-sink-1920-ids-crop.png` enlarged 3x so the
  labels are legible), read in `## Visual Verification`.
  For the independent reviewer: `fw reviewer judge T-1102 --criterion 1` (render-surface, no operator carve-out).

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
grep -q 'leg browser "_t1102-unique-display-ids-cdp" _leg_213' tests/run-bridge-tests.sh
PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH" node tools/_t1102-unique-display-ids-cdp.mjs > /tmp/.t1102 2>&1 && [ "$(sed -n 2p /tmp/.t1102)" = '  "ok": true,' ]
test -s docs/reports/T-1102-evidence/kitchen-sink-1920-ids-crop.png
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

Shots by `tools/_t1327-notice-shots.mjs` into `docs/reports/T-1102-evidence/` (its own measures 9/9 ok: notice in the
viewport, text unclipped, no node under it, header buttons on screen, no notice on a designer map), plus an enlarged
crop of the kitchen-sink 1920 canvas (`kitchen-sink-1920-ids-crop.png`, region x290-620 y520-820, 3x) because node
labels are ~7 px at fit zoom. Read by the agent, 2026-10-29:

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| kitchen-sink | event labels under the nodes | ok | ok | ok | crop: lane `Lane_1cofr07` (abbr `lan`) events `lan_start_event`, `_2`, `_3`; event-subprocess events `la3_start_event`, `_2` … `_12`; no two alike. (First written as lane "Lane": wrong, judge round 1 — lane "Lane" is `Lane_1vakzes`, abbr `la2`, reads `la2_…`.) |
| kitchen-sink | header, toolbar, notice, side panels | ok | ok | ok | unchanged from T-1264's shots |
| plain designer map | labels | ok | ok | ok | unchanged (designer maps keep every id: harness leg 3) |

Gate: the first run exited 1 on the sweep harness's Name-field leg (at 1440 a name cut in error-escalation-ladder; at
1920 typed text stored wrong, focus lost). Run alone it passed twice on this source and once on the old one, so a
timing flake under load (the half-hourly cron audit falls in that window), not this change; the gate re-run exited 0
(label-clearance, name-fit, sweep, note-box, toolbar-reach 21/21, project-browser all PASS).

**Advisory sweep** (codex `t1102-sweep-49129db68b25`, 2026-10-29, no verdict asked), in substance: no two readable
labels alike in the crop (`la3_…` and `lan_…` distinguishable, numbered variants too); no clipping, overlap or hidden
control attributable to the new prefix; the crowded central cluster and the small 1024 canvas are visible problems but
the diff changes id assignment, not positions; nested-lanes and the plain map show nothing concerning (it had no
"before" images: harness leg 3 is that check). One comprehension point: nothing on screen says why `la3_` differs from
`lan_`. **Disposition:** not acted on here. Before, the lane-less events read `lan_`, which was equally unexplained and
worse, since it read as a member of the real lane abbreviated `lan`; an explanation of id prefixes is a separate UI
question.

**Judge round 1: AMBER** (judge-t-1102-r1-250ff33144c9, claude-code seat). Met: the ids are distinct; a pixel diff
against T-1264's shots changes only event labels (1024: 0 cells; 1440 and 1920: label positions only). Owed: "The
criterion says the lan_ events are in the lane named 'Lane'. They are in lane Lane_1cofr07 (abbr lan). Lane 'Lane'
(Lane_1vakzes) has abbr la2 and reads la2_*. Correct the AC text and the Visual Verification row (the commit message
has the same mislabel), then re-judge." **Done:** criterion, table row, RCA corrected; the source comment and harness
header corrected in the next commit (62d8cff9b's message keeps the mislabel; this note is its correction).

Not this change: in the crop, the label `la3_start_event` runs under the "Event-Subprocess" box, and several events sit
close together — kitchen-sink's own geometry (T-1264's sweep noted the same cluster).

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

**Symptom:** kitchen-sink saved two `bpmn:endEvent id="lan_end_event"` (and three start-event ids twice): invalid BPMN,
and a second save differed because the duplicates collapsed on re-import.
**Root cause:** `computeDisplayId` numbers events within the nodes sharing `node.lane`, but takes the prefix from the
lane's abbreviation with a fallback `lan` for a node whose lane is missing. A real lane can also derive `lan`: in
kitchen-sink it is `Lane_1cofr07` (no name in the source, abbreviation derived from its id). (Not the lane named
"Lane", as first written — that one is `Lane_1vakzes`, abbreviation `la2`; corrected after judge round 1.)
The lane-less events (inside an event subprocess) and that lane's events were two groups with one prefix, each starting
its count at 1. `uniqueAbbrAmong` kept lane abbreviations unique among lanes (T-1088) but not against the fallback.
**Why structurally allowed:** every id check ran on designer-written maps, where every node is in a lane; the
third-party goldens recorded the duplicate ids as correct.
**Prevention:** `_t1102-unique-display-ids-cdp.mjs` (browser leg `_leg_213`): no repeated BPMN id in any fixture or
corpus map, a minimal two-group case, designer maps keep their ids, second saves stable; red on the old source.

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
     fw inception decide T-1102 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-08T09:14:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1102-duplicate-node-ids-within-one-lane-start.md
- **Context:** Initial task creation

### 2026-10-28 — still live under today's display ids (found again as T-1332, now marked its duplicate)
- T-1264's id-uniqueness check over the third-party goldens (bleeding-edge, 2026-10-28): kitchen-sink's export has two
  `bpmn:endEvent id="lan_end_event"`, and `lan_start_event`, `lan_start_event_2` likewise twice (before T-1264 they also
  showed as duplicate `BPMNShape_` ids). Same class as this task, under the current `<lane>_<slug>` id shape. Check:
  parse `tests/goldens/third-party/kitchen-sink.bpmn.golden` and count repeated `id` values.

### 2026-10-29T00:26:22Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
