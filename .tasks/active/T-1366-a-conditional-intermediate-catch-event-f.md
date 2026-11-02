---
id: T-1366
name: "A conditional intermediate catch event from another tool's file opens as a
  link catch event (wrong symbol, display id says link)"
description: >
  bpmn:intermediateCatchEvent with a bpmn:conditionalEventDefinition is typed linkEventCatch
  on import: drawn as a plain double circle without the condition marker, display
  id sal_link_lead, link-jump UI; the importer only types error/timer/message (EVENT_KIND_TYPE).
  Found reproducing T-1364 with greenfield's wt01-io-v11.

status: started-work
workflow_type: build
current_node: frw_1_start
owner: agent
horizon: now
tags: [bug]
components: []
related_tasks: [T-1364, T-1363, T-1222]
origin: {kind: "agent"}
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
#                                 # `fw work-on T-1366` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-11-02T07:25:42Z
last_update: '2026-11-02T07:56:56Z'
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
  - ts: '2026-11-02T07:56:56Z'
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
      F1: 2
    rationale: 'D1=1 (body:fix-without-learning); D2=0 (no-signal); D3=0 (no-signal);
      D4=0 (no-signal); F-RECALL=0 (no-signal); F2=0 (no-signal); F4=0 (basis: task
      body — no hypothesis, so this score has no claim to be wrong about,L0: no signal);
      F3=0 (basis: task body — no hypothesis, so this score has no claim to be wrong
      about,L0: no signal); F1=2 (basis: task body — no hypothesis, so this score
      has no claim to be wrong about,L2:keyword=import)'
    rubric_sha: e4a00f38e801
---

# T-1366: A conditional intermediate catch event from another tool's file opens as a link catch event (wrong symbol, display id says link)

## Context

<!-- All four parts are required before source edits (T-4907). Plain language; link design docs for substantial tasks. -->
**Background / trigger:** 832 found this while reproducing T-1364 on 0.35.0 with greenfield's wt01-io-v11 (2026-11-02;
the map is kept in ignored build/peer-data/greenfield/). Greenfield models a state change that starts a step ("Lead
status Qualified in Salesforce") as an intermediate catch event with a `bpmn:conditionalEventDefinition`. That is rule
E of the WT-01 mapping, and need 2 of T-1363 (state transitions as triggers). In the 1440 screenshot it is a plain
double circle with no condition marker, and its display id reads `sal_link_lead`.

**Problem / hypothesis:** The importer (`parseBpmnXml`, T-1222 block near "a third-party catch ... whose one native
definition is a kind the designer models") gives an intermediate catch event a typed node type only when its single
native definition is in `EVENT_KIND_TYPE` (error, timer, message). Everything else, conditional and signal included,
stays `linkEventCatch`, so it is drawn and named as a link catch. The definition itself is kept on save (T-1222), so
nothing is lost, but the canvas says the wrong thing: a person sees a link where the map means "waits for a
condition".

**Goal:** A conditional (and signal) intermediate catch event from another tool's file is recognisable on the canvas
as what it is. It is not drawn or named as a link event.

**Expected outcome:** The conditional catch event shows a condition marker (BPMN's lined-sheet symbol). Its display id
uses a non-link word. The link-jump UI does not appear on it. The save stays byte-identical to today's.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
<!-- Revised 2026-11-02 while building (see Decisions): the node type stays the plain event (T-1222), and the save
     changes only these events' id word. -->
- [x] On the synthetic fixture `tests/fixtures/t1366/plain-event-kinds.bpmn` (no client data; one intermediate event per
  native kind: conditional catch, signal catch, message catch, timer catch, a catch with no definition, signal throw),
  the conditional catch, signal catch and signal throw each draw BPMN's kind marker (`[data-kind-marker]`).
  Message and timer keep their typed rendering. The catch with no definition is unchanged.
- [x] Display ids of conditional and signal events name the kind (`_conditional_`, `_signal_`) and never `link`.
- [x] The side panel heads a conditional event `conditionalEvent`, says what it waits for, and shows the condition as
  written. It no longer says "carries no kind" and offers no "Make this a handoff".
- [x] Every native definition survives a save (`tools/_t1222-event-definitions-kept.py` green, 49 → 49), and a second
  save is byte-identical. The only saved difference from 0.35.0 is the id word of conditional and signal events
  (`…_link_…` → `…_conditional_…` / `…_signal_…`), named in the release notes for AEF.
- [x] `tools/_t1366-plain-event-kinds-cdp.mjs` asserts the above (leg 222, browser tier) and is red on the pre-T-1366
  source (the bite).
- [x] `bash tools/person-sees-gate.sh` exits 0, and screenshots at 1024/1440/1920 are read in `## Visual Verification`.

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
         1. Run `bin/fw reviewer T-1366`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1366 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->
- [x] [REVIEW] A conditional or signal event from another tool's file reads as what it is: on the canvas and in the panel
  **Steps:**
  1. Compare `docs/reports/T-1366-evidence/events-1920-zoom-before.png` (0.35.0) with `events-1920-zoom.png` (this
     change): the row Start, Status Qualified (conditional), Recall signal (signal catch), Order received (message),
     Two days (timer), Plain catch (no definition), Send recall (signal throw), Done.
  2. Look at `docs/reports/T-1366-evidence/events-{1024,1440,1920}.png`: the whole window at three widths.
  3. Look at `docs/reports/T-1366-evidence/panel-{1024,1440,1920}.png`: the conditional event selected.
  **Expected:** After the change, the conditional event shows a lined-sheet marker, the signal catch an outlined
  triangle and the signal throw a filled triangle. Their ids read `tea_conditional_status`, `tea_signal_recall` and
  `tea_signal_send`, where before they read `tea_link_…`. Message, timer and the plain catch look as before. Every name
  and id is readable and nothing overlaps. The panel says "conditionalEvent", explains that the flow waits until a
  condition holds, shows "status = Qualified", and offers no handoff. At all three widths the toolbar and both side
  panels are complete and unclipped.
  **If not:** name the screenshot and what is wrong (marker unreadable, label overlap, misleading panel text).
  For the independent reviewer: `fw reviewer judge T-1366 --criterion 1`

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
  **Reviewer verdict:** green V-20261102-7159f0fa — reviewer-judge-t-1366-r3-77909b6a8a49:reviewer (rung rung-3-termlink-single-reviewer), digest d344c9b81d69; dispatch judge-t-1366-r3-77909b6a8a49; evidence: .context/reviews/evidence/T-1366/AC1-judge-t-1366-r3-77909b6a8a49.md, .context/reviews/evidence/T-1366/events-1920-zoom-before-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/events-1920-zoom-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/events-1024-zoom-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/events-1440-zoom-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/events-1024-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/events-1440-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/events-1920-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/panel-1024-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/panel-1440-judge-t-1366-r3-77909b6a8a49.png, .context/reviews/evidence/T-1366/panel-1920-judge-t-1366-r3-77909b6a8a49.png; ledger .context/reviews/verdicts.jsonl

## Verification

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
#     bin/fw vendor self --check --task T-1366X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.
-->
grep -q "^function plainEventKind(n)" src/aef-workflow-designer.html
grep -q 'leg browser "_t1366-plain-event-kinds" _leg_222' tests/run-bridge-tests.sh
test -f tests/fixtures/t1366/plain-event-kinds.bpmn
export PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH"; node tools/_t1366-plain-event-kinds-cdp.mjs >/dev/null
export PATH="$HOME/.nvm/versions/node/v22.22.1/bin:$PATH"; python3 tools/_t1222-event-definitions-kept.py >/dev/null
test -f docs/reports/T-1366-evidence/events-1920-zoom.png && test -f docs/reports/T-1366-evidence/panel-1024.png

## Visual Verification

Screenshots by `node tools/_t1366-shots.mjs` (with `T1366_BEFORE` = the pre-T-1366 source) of
`tests/fixtures/t1366/plain-event-kinds.bpmn`, in `docs/reports/T-1366-evidence/`. Each one was read.

| state | control | 1024 | 1440 | 1920 | note |
|-------|---------|------|------|------|------|
| canvas, opening | conditional catch: lined-sheet marker, id `tea_conditional_status` | ok | ok | ok | events-{W}.png; 3x in events-{W}-zoom.png |
| canvas, opening | signal catch: outlined triangle, id `tea_signal_recall` | ok | ok | ok | |
| canvas, opening | signal throw: filled triangle, id `tea_signal_send` | ok | ok | ok | |
| canvas, opening | message, timer, plain catch: unchanged (envelope, clock, empty ring; `tea_link_plain` kept) | ok | ok | ok | compared with events-1920-zoom-before.png |
| canvas, opening | every name and id below its event, no overlap | ok | ok | ok | see note 1 |
| panel, conditional selected | header `conditionalEvent`, kind text, condition `status = Qualified`, no handoff button | ok | ok | ok | panel-{W}.png |
| window | toolbar (two rows at 1024 and 1440, one at 1920), both side panels | ok | ok | ok | nothing clipped or off-screen |

What was read, per screenshot:
- **events-1920-zoom-before.png (0.35.0):** conditional, signal catch and signal throw are empty double rings, and
  their ids read `tea_link_status`, `tea_link_recall` and `tea_link_send`.
- **events-1920-zoom.png:** the three markers are drawn and readable. The message envelope and the timer clock are
  unchanged, and the plain catch is still an empty ring (`tea_link_plain`, out of scope). All eight labels sit below
  their events at 150 px spacing.
- **events-{1024,1440,1920}.png:** a one-lane pool at the opening zoom, with every element inside it. The authority
  notice is unchanged, and the toolbar and panels are complete.
- **panel-{1024,1440,1920}.png:** the right panel shows the header, display id, the "Event kind" section with the
  condition in a quoted mono block, and the I/O contract below. Nothing is cut off at 1024.
- **Greenfield's real map** (wt01-io-v11, not committed: client data): at 1440 "Lead status Qualified in Salesforce"
  shows the marker, its id reads `sal_conditional_lead`, and its label stays below the event, unchanged.

**Advisory sweep** (codex, worker t1366-advisory-f53b96742ec8, 2026-11-02, before the official review). It found no
overlap, clipping or misleading meaning. Two points were acted on, then the screenshots were retaken and the gate re-run:
- Marker contrast was weak (grey on dark), most of all the filled triangle. Fixed: markers are drawn in `--text-dim`, a
  step brighter than the ring's `--text-faint`, on the canvas and in the panel badge.
- "the designer does not edit this kind yet" was ambiguous next to editable Name and Lane fields. It now reads "the
  designer cannot edit the condition yet" (and the signal equivalent).

Not acted on, because this change does not cause them:
- small text at the opening (fit) zoom;
- the 1024 panel scrolling to reach "add output";
- the version badge still reading v0.35.0 until the release.

Note 1: in a first version of the fixture the events stood 110 px apart. There, the longer id
(`tea_conditional_status`, 4 characters longer than `tea_link_status`) no longer fitted between its neighbours, and
the label placer put it above the event, on the pool's title band. That is the existing placement behaviour for any
long label in a cramped one-lane pool, not something this change introduces. Greenfield's real map and the fixture at
150 px do not show it. It is recorded here so it is not mistaken for an unseen regression.

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

**Symptom:** greenfield's state-change trigger ("Lead status Qualified in Salesforce", a `bpmn:conditionalEventDefinition`)
was drawn as an empty double ring with the id `sal_link_lead`. Its panel said it "carries no kind" and offered "Make
this a handoff".
**Root cause:** the importer types an intermediate catch event only when its definition is error, timer or message
(`EVENT_KIND_TYPE`). Every other kind stays `linkEventCatch`. T-1222 kept those definitions on save and T-308/T-1222
drew them as a plain event, but nothing read the kept definition for display. So the kind was in memory and in the
saved file, and never on screen. The id word came from `STEP_WORD[linkEventCatch] = 'link'`.
**Why structurally allowed:** T-1222's tests asked whether a definition survives a save (49 → 49), not whether a
person can see which kind it is. The kitchen-sink fixture has conditional and signal events, but no check looked at
their marker or id word.
**Prevention:** `tools/_t1366-plain-event-kinds-cdp.mjs` (leg 222) asserts the marker, the id word and the panel text
per kind, and is red on the old source. Kinds with no marker yet (escalation, compensate, ...) still draw as the plain
event. Adding one means one entry in `PLAIN_KIND_WORD` and one branch in `plainKindMarker`.

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

### 2026-11-02 — display the kind on the plain event, do not add node types
- **Chose:** keep conditional and signal events on T-1222's plain-event path (node type unchanged). Read their kind
  from the native definition kept on import. Draw BPMN's marker, use the kind as the id word, and head and explain them
  in the panel.
- **Why:** it is a display defect, and the data was already right. New node types would touch about 15 tables (palette,
  sizes, field plans, export tags, EVENT_KIND, the validator's vocabulary, the YAML bridge) and invite authoring
  conditional and signal events, whose editing T-1363 has not decided. The plain-event path also keeps the T-1222
  reviewer ruling that these are "never link semantics".
- **Rejected:** typed `eventConditional` / `eventSignal` node types (scope, an undecided authoring model). Shortening
  the id word to `cond` to keep labels narrow (it reads worse, and the label overlap appeared only in a cramped
  synthetic layout; see Visual Verification note 1).
- **Consequence:** the save renames these events' ids from `…_link_…` to `…_conditional_…` / `…_signal_…`. AEF
  stores node ids, so the release notes must name it.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1366 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-11-02T07:25:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1366-a-conditional-intermediate-catch-event-f.md
- **Context:** Initial task creation

### 2026-11-02T07:56:55Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
