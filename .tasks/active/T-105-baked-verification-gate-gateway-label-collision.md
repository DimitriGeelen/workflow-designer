---
id: T-105
name: "Baked corpus regression: aligned gateways collide their edge-labels (verification-gate)"
description: >
  Operator field report (2026-07-05, screenshot of verification-gate): after the T-101 Clean bake, the three framework-lane gateways (frw_6_every, frw_8_rca, join) sit on one aligned centre-line, so their long edge-labels ("every verify cmds exit 0", "all verify cmds exit 0", "RCA/evolution/inception gates pass?") overlap into an unreadable mess. Likely caused by align-rows (T-094) snapping the gateways to a common Y that previously staggered them enough to separate the labels. Investigate cause, then fix (edge-label collision avoidance and/or a bake that accounts for label footprint).
status: started-work
workflow_type: build
owner: human
horizon: now
tags: [ui, editor, bug, corpus]
components: []
related_tasks: [T-101, T-082, T-089, T-083]
created: 2026-07-05T17:30:00Z
last_update: 2026-07-05T21:38:34Z
date_finished: null
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
- [ ] Cause confirmed empirically (headless): compare verification-gate edge-label
      bounding boxes pre-bake (git HEAD~ of the .bpmn) vs post-bake; show whether
      align-rows co-linearity is what pushed the labels into overlap
- [ ] Decision recorded: fix in the editor's edge-label placement (collision-avoid /
      stagger / wrap — extend T-082/T-089), OR make Clean/align-rows label-aware, OR
      exempt this gateway cluster — with rationale
- [ ] Fix implemented so verification-gate (and any other affected baked map) opens
      with no overlapping edge-labels, WITHOUT regressing node-row tidiness
- [ ] If the corpus geometry changes: re-bake affected maps via
      `tools/bake-clean-layout.py`, keep `--check` at 24/24 fixpoints, suites green
      (bridge 31/31, validator 34/34, parity OK, geometry 24 clean), gallery synced
- [ ] Change synced byte-identical to `build/gallery/designer.html` if editor JS changed
- [ ] Before/after screenshots of verification-gate READ, confirming labels readable

### Human
- [ ] [REVIEW] verification-gate (and neighbours) open with readable, non-overlapping
      edge-labels and still-tidy rows
  **Steps:**
  1. Serve the gallery; open verification-gate, review-emission, and any other
     gateway-dense map
  2. Confirm no edge-label overlaps the gateway glyphs or other labels
  **Expected:** All branch labels legible; rows still tidy
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

## Decisions

## Updates

### 2026-07-05 — captured
- Filed at session budget ceiling (~300k) after operator screenshot; could not
  investigate/fix in-window (source edits gated). Next session: confirm the
  align-rows-vs-label hypothesis first, then choose fix locus (editor label
  placement vs label-aware Clean).
