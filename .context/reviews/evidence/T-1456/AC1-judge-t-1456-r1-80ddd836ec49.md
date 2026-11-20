# T-1456 Human AC#1 — independent review (rung 1), revision 3fdf7a2ba (round 2)

Verdict: **amber**. Judged on the supplied images only (`docs/reports/T-1456-shots/*.png`, identical to the reviewed
revision: `git status` clean for that directory). Cannot reproduce: the capture was not re-run (by the brief). All 10
images opened and viewed; positions measured per pixel (PIL, line-coloured pixels per row/column). Coordinates below
are screenshot pixels of each clip. Cited copies are in this directory with my dispatch id.

## Pair 1 — Greenfield 'wel' (1024 / 1440 / 1920): after reads BETTER. Met (steps 1 and 4).
- Before (all three widths): bar at y 210-211, below the lane line at y ~152 (through Novis); at Opportunity/Solution
  the loop's end is at y 147-148 and the outgoing flow at y 143-144: 4 px, the two arrowheads are one blob.
- After (all three widths): bar at y 74-75, above the steps, between the lane lines at ~22 and ~152 (inside Tacton);
  the loop's end at y 131-132, the outgoing flow at 143-144: 12 px, both arrowheads read separately.
  `zoom4x-greenfield-opp-before-left-after-right-judge-t-1456-r1-80ddd836ec49.png`.
- Round 2: the bar (y 74-75) is 13 px clear of the horizontal part of Send Proposal's outgoing flow (y 89-90, x 541-618);
  the earlier reviewer measured it at y 85-86, 4 px above. The double line is gone. The bar still crosses that flow's
  vertical at x 618 once (and at 1920 the vertical into the Redesign gateway): plain right-angle crossings, readable.

## Pair 2 — task-lifecycle 'gate failed — rework' (1440): NOT "the same as before". One new crossing. Not met.
- The bar is back under the last lane: y 271-272, x 71-718, in both images; the vertical at x 71-72 up to the step is
  the same. The round-1 fault (bar ON 'blocked / failing') is gone: the top-left of the clip shows no shared segment.
  The label on the "+ Add another lane" strip is the same in both (T-1465, not judged).
- BUT the flow's start at the 'All gates passed?' gateway changed. Before: the incoming flow from 'Run completion gate
  battery' arrives at y 107-108 and 'gate failed — rework' leaves the gateway at y 115-116, below it, turning down at
  x 717-718: the two never touch. After: the two ends are swapped. The incoming flow arrives at y 115-116 and
  'gate failed — rework' leaves at y 107-108, so its vertical at x 717-718 now CROSSES the incoming flow at y 115-116,
  about 12 px before that flow's arrowhead. Pixel rows 100-121, x 650-745, show the vertical stopping at the upper line
  before and running through the lower line after. `zoom7x-lifecycle-allgates-before-left-after-right-judge-t-1456-r1-80ddd836ec49.png`.
- The criterion expects "the same as before" for this pair. It is not: after has one crossing more, on the judged flow,
  next to an arrowhead. That reads slightly worse than before.
- Also changed, harmless: the vertical of the flow left of the 'Outcome?' gateway sits 4 px further right (x 95 -> 99).
  `zoom5x-lifecycle-outcome-before-left-after-right-judge-t-1456-r1-80ddd836ec49.png`.

## Pair 3 — task-gate block (1440): reads at least as well. Met, but the step's "unchanged" is not literally true.
- The images differ (bbox x 95-385, y 362-388). On 'Write real acceptance criteria' the two incoming ends were 8 px
  apart (y 367-368 and 375-376, the small arrowhead touching the large one) and are 12 px apart after (371-372 and
  383-384, clear of each other). The straight flow from 'Create task + set focus' is 4 px lower over its whole length,
  still straight. No route, crossing or label changed. Reads the same or slightly better.
  `zoom8x-gateblock-target-before-left-after-right-judge-t-1456-r1-80ddd836ec49.png`.

## What is needed
1. task-lifecycle pair: at 'All gates passed?' put the ends back in the order of before (incoming flow from 'Run
   completion gate battery' above, 'gate failed — rework' leaving below it), so the loop's vertical at x 717-718 does
   not cross the incoming flow; then re-take `task-lifecycle-rework-1440-after.png`.
2. Step 3 says the task-gate block pair is "unchanged on purpose". The ends on 'Write real acceptance criteria' moved
   from 8 px to 12 px apart. Either correct the step's text to say so, or explain why the pair differs.
