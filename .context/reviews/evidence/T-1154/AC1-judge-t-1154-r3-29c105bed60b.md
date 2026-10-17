# T-1154 Human AC#1: review evidence (judge-t-1154-r3-29c105bed60b)

Revision reviewed: 2c5a627ee8e612c759d37665ce9e3f86893fff33
Source screenshots: .playwright-mcp/t1154-{1024,1440,1920}-{fit,zoomed}.png (mtime 2026-10-17 18:46, just before the
18:48 commit 2c5a627e; the canvas toast shows "6:46 PM"). I copied them here with the suffix -judge-t-1154-r3-29c105bed60b.png.

## Method
- I looked at all six screenshots at full size.
- The fit shots are too small to judge by eye, so I cropped and enlarged their right edges (crop-{w}-fit-right-edge-judge-t-1154-r3-29c105bed60b.png).
- I measured pixels with PIL: the right-most bright text pixel of the label "Resolved, recorded and promoted to a durable
  project learning" against the pool's right-border column.

## Measurements (label end → pool right border, screen px)
| shot | label end x | border x | gap |
|------|-------------|----------|-----|
| 1024-fit | 696 | 704 | 7 px |
| 1440-fit | 1105 | 1111 | 5 px |
| 1920-fit | 1578 | 1586 | 7 px |
| 1024-zoomed | 640 | 663 | ~22 px |
| 1440-zoomed | 1058 | 1079 | ~21 px |
| 1920-zoomed | 1538 | 1559 | ~21 px |

The id badge "frw_end_resolved" is shorter than the label and ends well inside the border in all six shots.

## Bands and lanes
In all six shots the pool header band and the HUMAN/SOVEREIGNTY, FRAMEWORK/AUTHORITY and AGENT/INITIATIVE lane
backgrounds and dividers run to the same right border. None of them is short. The widened pool reads as intentional.
The fit shots leave a few px of empty lane after the label, which matches the other lanes.

## Clipping and overlap
- The toolbar, side panels and fold tabs are intact at every width. At 1024 and 1440 the toolbar wraps onto two rows,
  which is the existing layout.
- The "Mode: select" pill and the "Restored your unsaved work" toast float over the canvas. These are existing chrome
  overlays, not part of this change, and they do not touch the label or the border.
- In 1024-zoomed the end-event circle sits partly under the sticky lane-name strip, because the view is scrolled right.
  This is the T-1091 sticky-lane behaviour, documented in the task. The label and badge themselves are fully visible.
- In 1920-zoomed the bottom badge agt_4_apply (y≈781) ends above the bottom border (y≈798).

## Verdict
green. Step 2 holds in all six screenshots. The fit gaps are small (5–7 px), but there is a clear dark gap between the
text and the border, and at 160% it is about 21 px.
