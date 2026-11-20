# T-1456 Human AC#1 — evidence report (judge-t-1456-r1-94d6a10b06de)

Revision reviewed: 44cdd96629fa429d1203a33b69be71349146bf44. Rung: rung-1-same-vendor-independent.
Method: opened all 10 supplied PNGs in docs/reports/T-1456-shots/, made nearest-neighbour zooms, a pixel
difference per pair (bounding box of changed pixels) and read line positions from the pixels.
Cannot reproduce: I did not re-run the capture (the brief says to judge the images as given).
Coordinates below are pixels in the clip, not map coordinates.

## Pair 1 + step 4: Greenfield 'wel' (1024, 1440, 1920)

- Before: the 'wel' bar runs BELOW the steps at y 210-211 and ends on the right side of
  'Opportunity / Solution - Product' about 4 px under that step's outgoing flow to 'Create Offer'
  (y 143-144). The two arrowheads overlap: it reads as one double-headed arrow between the two steps.
  (zoom5x-greenfield-opp-before-left-after-right-judge-t-1456-r1-94d6a10b06de.png, left half)
- After: the bar runs ABOVE the steps at y 74-75; its end comes down onto the same side at y ~132, the
  outgoing flow stays at y 143-144: about 12 px apart, two separate arrowheads, direction of each
  unambiguous. (same zoom, right half)
- Step 4: Send Proposal's outgoing flow has its horizontal run at y 89-90; the bar at y 74-75 leaves a
  13 px gap (15 px centre to centre). The label 'wel' sits on the bar, clear of both lines.
- Cost, stated plainly: the bar now crosses solid flows at right angles: Send Proposal's outgoing
  vertical (1440 and 1920), and at 1920 also the vertical that comes down into the Redesign gateway
  (zoom4x-greenfield-gateway-1920-before-left-after-right-judge-t-1456-r1-94d6a10b06de.png). Before it crossed no solid flow, only
  the dotted annotation connector under Send Proposal. Both new crossings are clean perpendicular
  crossings, away from any bend, end or label.
- At the gateway (1920) the two ends on its left side swap order (incoming now lower at y 146-147,
  'wel' leaves at y 138-139); same distance as before, no crossing between them.
- Not confirmable from the clips: the lane NAMES (Tacton / Novis); no lane header is in frame. What the
  images show is that the bar moved from under the steps to above them.
- Judgement: better. The overlapping double arrowhead was a real misreading risk; two clean
  right-angle crossings are a smaller cost.

## Pair 2: Task lifecycle 'gate failed - rework' (1440)

- Changed pixels are confined to x 20-100, y 57-157: the vertical of the healing flow left of
  'Outcome?' moved from x 94-95 to x 98-99. Nothing else differs.
- At 'All gates passed?' the pixels are identical before and after: incoming flow at y 107-108, rework
  leaving below it at y 115-116, no crossing. The rework route under the lanes is identical.
- The label on the '+ Add another lane' strip is the same in both (T-1465, excluded by the criterion).
- Judgement: reads the same as before (at least as well).

## Pair 3: Task gate block (1440)

- Changed pixels are confined to x 95-385, y 362-388. On 'Write real acceptance criteria' the two ends
  were at y 367-368 and 375-376 (8 px), now y 371-372 and 383-384 (12 px). The flow from
  'Create task + set focus' is at one y along its whole length (371-372 at x 200 and x 372): still straight.
- No route, crossing or label changed elsewhere.
- Judgement: at least as well; the two arrowheads are now separate
  (zoom5x-gateblock-target-before-left-after-right-judge-t-1456-r1-94d6a10b06de.png).

## Verdict: green

After reads at least as well as before in each pair, and better for 'wel'.
