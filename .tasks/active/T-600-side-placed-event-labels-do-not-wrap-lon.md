---
id: T-600
name: "Side-placed event labels do not wrap: long label text overruns the lane boundary"
description: >
  Operator screenshot 2026-08-26: the label 'run halted - operator kill switch' on event node hum_3_run renders as one unwrapped line to the right of the circle and overruns the lane divider. Node labels rendered INSIDE a shape already wrap (src/aef-workflow-designer.html:3206 iterates a 'lines' array), so wrapping logic exists; the side-placed label path for circular event nodes bypasses it. Add wrapping there, with a width budget that respects the lane boundary rather than the node box.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T17:23:44Z
last_update: 2026-08-26T19:20:38Z
date_finished: 2026-08-26T19:20:38Z
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
---

# T-600: Side-placed event labels do not wrap: long label text overruns the lane boundary

## Context

Gateway and event names render on a SINGLE line below the shape (src/aef-workflow-designer.html
~:3222). They are re-wrapped only by deCollideBelowLabels() (T-105), and only when the label's
box actually HITS another below-label's box. A long sentence with no neighbouring label therefore
never wraps: it stays one line, sprawls sideways across the diagram, and — as in the operator's
2026-08-26 screenshot of hum_3_run "run halted - operator kill switch" — runs past the geometry
it belongs to. Task rect labels already wrap (:3201 iterates a `lines` array), so the wrapping
primitive (wrapText) exists; the below-label path simply never reaches it uncontested.

Side placement (adjustLabelPlacements) does NOT re-wrap either: it re-stacks whatever text
elements already exist. So a single-line label moved beside a circle stays a single long line.
Wrapping the label BEFORE the de-collision and placement passes fixes both, because both passes
already handle multi-line blocks.

The cap is a MEASURED width (getComputedTextLength), not a character estimate — PL-008: estimated
char widths diverged enough from real metrics to move labels onto other edges.

## Acceptance Criteria

### Agent
- [x] A below-label whose MEASURED width exceeds the size-scaled cap is wrapped to fit, whether or not it collides with another label
- [x] Labels at or under the cap are left on one line — the T-105 contract that uncontested short labels stay single-line and tightly packed is preserved
- [x] The wrap pass runs BEFORE deCollideBelowLabels() and adjustLabelPlacements(), so side-placed labels inherit the wrapped lines instead of a single long one
- [x] The id badge below a wrapped name is pushed down by the added lines rather than overlapped
- [x] The behaviour is an operator preference (`labelPrefs.wrapNames`), exposed as a settings checkbox and persisted to localStorage like every other label pref
- [x] `node tools/_t600-label-wrap.mjs --self-test` passes, and its poison arms prove the wrap legs can fail

### Human
- [ ] [REVIEW] Long event/gateway sentences wrap instead of sprawling, and the map still reads well
  **Steps:**
  1. Open the designer, load the map that showed `hum_3_run`
  2. Look at the label "run halted - operator kill switch"
  3. Toggle Settings -> "Wrap long labels" off and on
  **Expected:** With the option on the sentence occupies two or three stacked lines under/beside the circle and no longer runs across the lane divider; with it off the old single-line behaviour returns
  **If not:** Screenshot the label with the option ON and note the label size pref in use

## Verification

# Shell commands that MUST pass before work-completed. One per line.
node tools/_t600-label-wrap.mjs
node tools/_t600-label-wrap.mjs --self-test

## Visual Verification

Element-level screenshots at scale 3, headless Chromium loading the real editor, with the
first label-below node renamed to a long sentence. Each was READ, not just captured.

- `.context/working/t600-wrap-off.png` — the defect reproduced. `wrapNames` off: one line,
  263px against a 165px cap, running left across the lane header and out of the pool.
- `.context/working/t600-wrap-on.png` — size M, wrapped onto two lines (156px / 105px),
  id badge `frw_1_investigation` below the name block, not above it.
- `.context/working/t600-wrap-s.png` — size S, two lines, no regression.
- `.context/working/t600-wrap-l.png` — size L, two lines, no regression.

Residual, NOT fixed here and captured separately: even wrapped, a label on a node at the
pool's left edge still extends past the lane header, because adjustLabelPlacements() scores
candidates against edges, node boxes and other labels — the pool and lane bands are not
obstacles to it. Wrapping narrows the overrun; it does not clamp the placement.

## Decisions

- **Cap by measured width, not character count.** PL-008: estimated char widths diverged
  from real metrics far enough to move labels onto other edges. The pass seeds a character
  budget from the measured overshoot, then tightens until every rendered line measures
  inside the cap, with a floor of 8 characters so one unbreakable token terminates.
- **Wrap unconditionally at the cap, rather than extending T-105's collision trigger.**
  T-105 deliberately leaves uncontested labels single-line so densely packed maps gain no
  new vertical collisions. A width cap preserves that exactly: short labels never reach it.
- **Insert wrapped lines BEFORE the id badge.** adjustLabelPlacements() stacks a node's
  label elements in DOCUMENT ORDER, so appending put the id above the name as soon as the
  block moved to the side of a shape. T-105's own rewrap had the same latent flaw and is
  fixed with it — same defect, same mechanism, one line each.
- **Exposed as `labelPrefs.wrapNames`, default on.** The operator asked for the option, and
  the pre-T-600 behaviour stays reachable from Settings.

## Recommendation

**Recommendation:** GO

**Rationale:** The mechanical half is settled — the wrap triggers on a MEASURED width
(`getComputedTextLength()`), not a guessed character count, so it fires exactly when the
text actually overruns and never on a label that already fits. The one remaining AC is a
taste call that only the operator can make: does a wrapped sentence read better on the map
than a long one. That is why it stays `[REVIEW]` and why this is a recommendation rather
than a completion.

Two honest limits the operator should weigh before ticking:

1. **Wrapping narrows, it does not clamp.** A wrapped label on a node at the pool's left
   edge still crosses the lane header, because `bboxScore()` scores against edges, node
   boxes and other labels — the pool and lane bands are not obstacles to it. Captured
   separately as T-601. If the review finds labels still landing on lane furniture, that
   is T-601, not a defect in this change.
2. **It is opt-out, defaulted ON.** `labelPrefs.wrapNames` is exposed in Settings and
   persisted like every other label pref, so a NO-GO on taste costs the operator one
   checkbox rather than a revert.

**Evidence:**
- `node tools/_t600-label-wrap.mjs --self-test` → PASS, 7 live legs, 4 proven failable
  across 2 poison arms. Arm A (wrap pass removed) fails L1/L2/L7; arm B
  (`insertBefore` → `appendChild`) fails L3. Arm B exists because arm A could not
  exercise L3 at all — with one line the id badge sits below trivially, so the leg
  passed without the fix and asserted nothing until a second arm was written.
- Screenshots taken at element level and READ, not merely captured, in four modes:
  `.context/working/t600-wrap-off.png`, `t600-wrap-on.png`, `t600-wrap-s.png`,
  `t600-wrap-l.png` (both size ends, and the pref both ways).
- A second, latent bug was found and fixed en route: `deCollideBelowLabels()`'s `rewrap`
  carried the identical `appendChild` ordering flaw, which renders the id badge ABOVE the
  name once the block moves to the side of the shape — `adjustLabelPlacements()` stacks a
  node's label elements in DOCUMENT ORDER.
- Cap is size-scaled (s/m/l → 150/165/180px) with an 8-character floor, so the pass
  terminates rather than shrinking indefinitely on a long unbroken token.

**What a NO-GO means:** uncheck nothing and say so — the pref defaults flip to `false` in
one line, and T-601 remains the open structural question either way.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d7a7180f
- **Timestamp:** 2026-08-26T19:20:42Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T19:20:38Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
