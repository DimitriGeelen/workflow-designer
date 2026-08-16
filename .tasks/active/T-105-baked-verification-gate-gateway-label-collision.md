---
id: T-105
name: "Baked corpus regression: aligned gateways collide their edge-labels (verification-gate)"
description: >
  Operator field report (2026-07-05, screenshot of verification-gate): after the T-101
  Clean bake, the three framework-lane gateways (frw_6_every, frw_8_rca, join) sit
  on one aligned centre-line, so their long edge-labels ("every verify cmds exit 0",
  "all verify cmds exit 0", "RCA/evolution/inception gates pass?") overlap into an
  unreadable mess. Likely caused by align-rows (T-094) snapping the gateways to a
  common Y that previously staggered them enough to separate the labels. Investigate
  cause, then fix (edge-label collision avoidance and/or a bake that accounts for
  label footprint).
status: started-work
workflow_type: build
owner: human
horizon: now
tags: [ui, editor, bug, corpus]
components: []
related_tasks: [T-101, T-082, T-089, T-083]
created: 2026-07-05T17:30:00Z
last_update: '2026-08-16T12:33:25Z'
date_finished:
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:25Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=2 (body:concern-ref); D2=0 (no-signal); D3=0 (no-signal); D4=0
      (no-signal); F-RECALL=0 (no-signal); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-105: Baked corpus regression — aligned gateways collide their edge-labels (verification-gate)

## Context

Field report (2026-07-05): the shipped `verification-gate` map opens with colliding
gateway edge-labels in the FRAMEWORK lane. Three exclusiveGateways in a row
(`frw_6_every` "every verify cmds exit 0", `frw_8_rca` "RCA/evolution/inception
gates pass?", plus the adjacent decision) now share a single centre-Y after the
T-101 bake, so their long branch labels stack at the same height and overlap.

**Leading hypothesis (verify first):** T-101 baked `cleanLayout()` into the corpus.
`alignRowsLane()` (T-094) snaps non-stack row-mates to a shared median centre-Y.
Pre-bake, these gateways were at slightly different Ys, which vertically separated
their labels; post-bake they're co-linear and the labels collide. If confirmed, the
bake improved node-row tidiness at the cost of edge-label readability on
label-dense maps — a real regression T-101 missed (only task-lifecycle +
harvest-pipeline were screenshotted; verification-gate was not).

This is adjacent to the existing partial-complete label work: T-082 (edge-label
placement / measure-after-move), T-089 (edge-label wrap), T-083 (label halo). The
real fix may belong there rather than in the bake.

## Acceptance Criteria

### Agent
- [x] Cause confirmed empirically (headless): the align-rows/edge-label hypothesis was
      DISPROVEN (see "Investigation findings" — gateways were always co-linear). Real
      cause: two long gateway NAME labels ("every verify cmd exit 0?" 117px,
      "RCA / evolution / inception gates pass?" 189px) render single-line under 48px
      diamonds only ~100px apart → node-name ∩ node-name overlap (edge-label ∩
      edge-label was already 0)
- [x] Decision recorded: fix in the editor's node-label rendering via CONDITIONAL
      wrapping — wrap only below-labels (gateway/event names) that actually collide with
      a neighbouring below-label, progressively tighter until clear; uncontested labels
      stay single-line. Rejected unconditional wrapping (grew all labels taller → 4 new
      collisions in dense maps) and edge-label placement (edge labels weren't the cause).
      See ## Decisions.
- [x] Fix implemented — `deCollideBelowLabels()` post-pass. Corpus metric (headless,
      measure-after-render): gateway/event NAME ∩ NAME overlaps **2 → 0** (fixed
      verification-gate g_verify∩g_gates AND git-commit-flow n_done∩g_hooks). No node-row
      geometry changed (render-only, PD-044). Zero regressions: name∩node-box overlaps
      12 → 9 (improved — narrower wrapped names cleared 3), verified against a no-op
      baseline
- [x] Corpus geometry did NOT change (render-only fix — no re-bake needed); suites green
      anyway: node-cut 0/24, bridge 31/31, geometry 24 clean
- [x] Change synced byte-identical to `build/gallery/designer.html`
- [x] Before/after screenshots of verification-gate AND git-commit-flow READ, confirming
      each gateway/event name is legible in its own column with no overlap —
      `t105-verifgate-after.png`, `t105-gitcommit-after.png`

### Human
- [x] [REVIEW] verification-gate (and neighbours) open with readable, non-overlapping
      gateway/event NAME labels and still-tidy rows
  **Steps:**
  1. Serve the gallery (`tools/serve-gallery.sh`, :8834); open verification-gate and
     git-commit-flow (the two fixed maps), plus any other gateway-dense map
  2. Confirm each gateway/event name (below its diamond/circle) is legible in its own
     column and does not overlap the neighbouring node's name — e.g. verification-gate's
     "every verify cmd exit 0?" and "RCA / evolution / inception gates pass?" now wrap
     to their own columns
  **Expected:** All gateway/event names legible and separated; rows still tidy; no name
  runs into a neighbour
  **If not:** Note which map/label still collides

## Verification

diff -q src/aef-workflow-designer.html build/gallery/designer.html

## RCA

**Symptom:** Shipped verification-gate map opens with overlapping, unreadable
gateway edge-labels.

**Root cause:** (to confirm) T-101's Clean bake aligned the gateway row to a common
centre-Y via align-rows; their long labels, previously separated by staggered Ys,
now collide. mapMessiness/Clean optimise node-box geometry and are blind to
edge-label footprint.

**Why structurally allowed:** T-101 verified "no visual regression" from only two
sampled maps; label-dense maps (verification-gate, review-emission) were not
screenshotted, and no automated check asserts edge-labels don't overlap after Clean.

**Prevention:** (candidate) an edge-label overlap check in the corpus sweep, and/or
make align-rows label-aware; capture as part of the fix. Ties to the G-003 editor
test-coverage gap and the T-103 harness inception.

## Investigation findings (2026-07-06, T-115/T-116 session)

**Leading hypothesis DISPROVEN.** The task assumed align-rows snapped previously-
staggered gateways to a common Y, colliding their labels. Headless measurement
(tools/_label-overlap-probe.mjs) shows the framework gateways were ALREADY co-linear
pre-bake (all y=300) and post-bake (all y=338) — the bake only shifted the whole row
down 38px uniformly; their relative geometry is identical. Co-linearity is not the cause.

**Actual root cause:** horizontal overcrowding of gateway NAME labels. Measured on
verification-gate after render (adjustEdgeLabelPlacements runs):
- edge-label ∩ edge-label overlaps: **0** (the placement pass already separates them)
- the real defect is node-label ∩ node-label: the two gateway NAMES
  "every verify cmd exit 0?" (117px wide) and "RCA / evolution / inception gates
  pass?" (189px wide) overlap because the diamonds sit only ~100px apart. Centred
  under 48px diamonds, 117+189px names cannot fit a 100px pitch.

**What the T-115/T-116/T-117 changes do for this:**
- T-115 Horizontal spacing control spreads the gateway columns (100→147px at gap 150)
  — helps but does NOT fully separate 189px-wide names; and gap ≥220 made OTHER
  overlaps worse. So spacing alone is insufficient.
- T-116 align-columns / T-117 de-jog do not touch horizontally-adjacent gateway
  spacing, so they neither fix nor worsen this collision.

**Remaining fix options for T-105 (pick one):**
1. Node-label wrapping/collision-avoidance for gateway NAMES (they currently render
   full-width centred with no wrap — unlike edge labels which have a placement pass).
2. Shorten the gateway names in the source YAML (they partly duplicate the edge
   labels, e.g. name "every verify cmd exit 0?" + outgoing edge "all verify cmds
   exit 0").
3. Operator uses the new Horizontal spacing lever + accepts partial relief.

**Re-bake note:** re-baking (T-101) now bakes align-columns (straight drops) into all
maps; it leaves this gateway-NAME collision unchanged (does not worsen it). Do not
treat "re-bake" as fixing T-105.

## Recommendation

**Recommendation:** GO
**Rationale:** Root cause was empirically pinned (first hypothesis DISPROVEN and documented; real cause = two long gateway name-labels overlapping under 48px diamonds), and the chosen fix (conditional below-label wrapping, only where labels actually collide) is recorded with rejected alternatives. All 6 Agent ACs checked. The Human AC is pure visual legibility on the two fixed maps.
**Evidence:**
- Investigation findings + Decision recorded in this task (hypothesis-driven, not shotgun)
- Fixed maps live: http://192.168.10.107:8834/designer.html?load=rendered/verification-gate.bpmn and git-commit-flow
- Unconditional wrapping rejected after measurement (grew 4 new collisions in dense maps)

## Decisions

### 2026-07-06 — Fix locus: conditional node-label wrapping
- **Chose:** Wrap gateway/event NAME labels, but ONLY the ones that actually collide
  with a neighbouring below-label (`deCollideBelowLabels()` post-pass, measure → wrap
  colliders tighter → re-measure, bounded iterations).
- **Why:** The collision is node-name ∩ node-name (edge-labels were already 0, so the
  T-082/T-089 edge-label machinery was the wrong locus). Wrapping shrinks the horizontal
  footprint so adjacent names clear. Conditional (not global) wrapping is the key: it
  leaves every uncontested label single-line, so densely packed maps gain no new
  vertical collisions.
- **Rejected:** (a) Unconditional wrapping of all gateway/event names — measured to fix
  the 2 target overlaps but introduce 4 NEW collisions (taller blocks in tight maps,
  relocated into each other by adjustLabelPlacements). (b) Making Clean/align-rows
  label-aware — the geometry was never the cause. (c) Shortening names in the YAML —
  loses information; a rendering fix generalises to any long name.

### 2026-07-06 — Out of scope: name ∩ node-box overlaps
- **Observed:** 9 gateway/event names overlap a *nearby node's box* (not each other) —
  e.g. promotion n_ready_gate∩n_count, resume g_ho∩n_tasks. This is PRE-EXISTING (12 at
  baseline; this fix incidentally cleared 3) and a different problem class (below-label
  vs adjacent-node-box, not below-label vs below-label). Left for a separate task — the
  relocation lever (adjustLabelPlacements) already handles name-vs-edge/node but only
  fires when a clean side exists; extending it is its own slice.

## Updates

### 2026-07-06 — fix implemented (T-105, still owner:human — not closed)
- Implemented `deCollideBelowLabels()`; NAME∩NAME overlaps 2→0, zero regressions
  (name∩box 12→9), render-only (PD-044), suites green, 2 maps screenshotted + read.
- Agent ACs checked. Human [REVIEW] AC left for the operator to confirm on the served
  gallery. Task remains owner:human — agent does not self-close.

### 2026-07-05 — captured
- Filed at session budget ceiling (~300k) after operator screenshot; could not
  investigate/fix in-window (source edits gated). Next session: confirm the
  align-rows-vs-label hypothesis first, then choose fix locus (editor label
  placement vs label-aware Clean).

## Reviewer Verdict (v1.5)

- **Scan ID:** R-bcd43bfd
- **Timestamp:** 2026-07-29T13:13:35Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Human)** — [REVIEW] verification-gate (and neighbours) open with readable, non-overlapping
  - **human-ac-mechanical-signal** (partial, heuristic) — `matched='names l' in Expected: All gateway/event names legible and separated; rows still tidy; no name   runs into a neighbour`
