# T-1457 Human AC#1 — evidence report (judge-t-1457-r1-50b3da97acb2)

Revision reviewed: ad0495c1b2df87be7296934656fcf66b5f3b61e9. Rung: rung-1-same-vendor-independent.

Criterion: at Productieorder the incoming and outgoing lines read as two distinct flows; after, a reader
tells the two flows apart without zooming in.

## What I did
Opened all six supplied images (docs/reports/T-1457-shots/productieorder-{1024,1440,1920}-{before,after}.png,
each 410x440, captured at 100% zoom, device scale 1 per shots.mjs) and judged them as given. Cannot reproduce:
I did not re-run the capture. I also measured the bright line pixels on a few rows (PIL) to check the
numbers the criterion states. Copies cited: productieorder-<W>-<before|after>-judge-t-1457-r1-50b3da97acb2.png in this directory.

## What the images show
The three widths are pixel-identical in the region of interest (same measurements at 1024, 1440, 1920).

Before: the incoming line comes straight down at x=143-144 and ends in an arrowhead on the top edge of
Productieorder; the outgoing line leaves the top edge at x=151-152 (centres 8 px apart). On the arrowhead's
widest row (y=356) the head spans x=139-148 and the outgoing line is at 151-152: 2 dark pixels between them,
which at 100% reads as the arrowhead touching the outgoing line. The pair reads as one bundle with a
head on it; which line carries the arrowhead is not obvious.

After: incoming at x=147-148, outgoing at x=159-160 (centres 12 px apart). Arrowhead spans x=143-152 at its
widest; 6 dark pixels separate it from the outgoing line on every row. The arrowhead is visibly a separate
shape sitting on the left line only; the right line is seen leaving the box, rising about 25 px and turning
right to its own vertical run at x=229-230, 82 px from the incoming line. The incoming line is at
x=147-148 on every sampled row (y=300..360): still straight, no jog.

## Judgement
At 100% zoom, in the after images, the two lines at the top of Productieorder are seen as two separate
lines with a clear dark gap, one ending in an arrowhead (in) and one without (out). A reader tells them
apart without zooming in. The criterion's stated numbers (8 px before, 12 px after, incoming still straight)
match my measurements.

Observation, not a defect against this criterion: both flows still attach to the same (top) side of the
node, about 25 px of parallel run. The criterion's own "If not" names the fuller answer (outgoing end on the
right side) as a separate task; the criterion as written does not require it.

Verdict: green.
