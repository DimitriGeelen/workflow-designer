# T-1505 Human AC#1 — independent image review (run judge-t-1505-r3-b15d8845befb)

Revision reviewed: 2532ba56665f988207f56ef9cd62b933cfe57d4b
Images: docs/reports/T-1505-shots/ (judged as given; harness not re-run). Copies cited here are suffixed `-judge-t-1505-r3-b15d8845befb.png`.

## What I looked at

| Frame | Width | Shows | Judgement |
|---|---|---|---|
| handle-idle-closeup | 1440, 1024 | Edge Configuratie | Baseline: plain grey boundary tick, no affordance. Clear. |
| handle-hover-closeup | 1440, 1024 | Pointer on edge | Green accent bar on the edge: the drag affordance is visible on hover. Clear. |
| handle-hover | 1024 | Full view, hover | Green bar on the boundary in the phase strip, same as close-up. |
| dragging | 1440 (copy cited) | Mid-drag | Dashed yellow landing line sits in the gap between "Send Proposal" and the next Opportunity node. Clear. |
| dragging | 1024 (copy cited) | Mid-drag | Landing line in the gap between "Send Proposal" and "Opportunity". Clear. |
| dragging | 1920 (copy cited) | Mid-drag | Landing line in the gap between "Send Proposal" and "Opportunity". Clear. |
| moved | 1440 (copy cited) | After release, centred | Boundary now at the landing gap; dashed divider runs through the lanes; "Configuratie" and "Offerte & onderhandeling" both in view. Clear. |
| moved | 1024 (copy cited) | After release, 51% zoom | Both phase names legible; boundary and divider visible at the gap. Small text but readable. |
| moved | 1920 (copy cited) | After release | NOT CONFIRMED. See below. |

## Checks against the criterion

- Discoverable on hover: yes, at all three widths the close-ups show the accent bar against the idle baseline.
- Landing place clear before release: yes, the dashed landing line sits in a step gap at 1024, 1440 and 1920.
- Result reads: yes at 1440 and 1024. The moved frames show the boundary at the landed gap, the divider through the lanes, and both neighbouring phase names.
- Clipping/overlap: viewport-edge clipping of unrelated nodes ("Redesign?", "Opportunity Closed") at the right edge of the 1440 frame; not part of the edge-drag result. No overlap on the handle or divider.

## Not confirmed

1. **moved-1920.** My reading of this frame is uncertain. The frame is not centred on the new boundary the way the 1440 and 1024 moved frames are, and I could not reliably tell whether the divider sits at the landed gap (about x=1096 in the dragging frame) or at the original boundary (about x=948). The 1440 and 1024 moved frames are consistent with a correct move. I am not voting green on a frame I could not read with confidence.
2. **Cursor.** The criterion asks that the handle reads as draggable on hover. The `col-resize` cursor is not visible in any screenshot (as the criterion itself says). It is asserted by harness C1, which I was told not to re-run. I did not verify it.

## Criterion literal

The criterion's Steps refer to `docs/reports/T-1505-shots/` and the 1024/1440/1920 widths; the files exist and match. No literal is out of date that I could see, so no restatement is proposed.

## Verdict

AMBER. 1024 and 1440 satisfy the criterion. 1920 moved frame needs a re-read or a clearer capture showing the boundary at the landed gap, with the divider and both phase names visible. The cursor assertion stays with harness C1.
