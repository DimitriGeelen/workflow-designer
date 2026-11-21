# T-1472 Human AC#1 — starter map opening view (reviewer judge-t-1472-r3-d670f01ec4fb)

Revision: d5f3f119d63abafc2c6cf5dab3e52fa322a6ac62. Judged the six supplied images in
docs/reports/T-1472-shots/ (copied here with the dispatch suffix). Did not re-run the capture.

## Before (fit)
- 1024: whole map squeezed into ~470x190 px at top of canvas; node text ("Load context bundle",
  "Decompose problem", lane names) is unreadable; most of the canvas is empty.
- 1440: map ~870 px wide; node labels tiny (~6-7 px), ids under nodes illegible.
- 1920: map ~1330 px wide; node labels small but marginally legible; ids hard to read.

## After (100%, top-left)
- 1024: lane titles (HUMAN SOVEREIGNTY / FRAMEWORK AUTHORITY / AGENT INITIATIVE), start event
  "Investigation requested", "Load context bundle" (2-1) and "Decompose problem" (1-1) with their
  ids all crisp and readable. Start event and the first two steps are in sight; the flow
  edge leads off right, horizontal scrollbar signals more. Zoom control reads 100%.
- 1440: start, Load context, Decompose, Fan out, the three Search tasks, Join and the left edge
  of Synthesize in sight; all text readable.
- 1920: nearly the whole flow in sight: start through Synthesize findings, Sufficient? gateway,
  Write report, Human review & route; all readable. Only the two end events (Ready, Abandoned)
  sit right of the canvas under the inspector panel — off-screen by design of a 100% opening,
  reachable by scroll.

## Reads worse?
Nothing renders worse: no overlaps, clipping of labels or toolbar regressions introduced (header
toolbars identical between before/after apart from the zoom readout fit -> 100%). The only loss
is overview — the whole map is no longer visible at once (at 1920 the end events), which is the
intended trade of the criterion's "100% from the top-left corner". Minor pre-existing spacing
(id labels under the stacked Search tasks nearly touching the next node) appears identically
in before shots, so not a regression.

## Verdict: green
