# T-1164 Human AC#1 — independent review (judge-t-1164-r3-9efd288b23e1)

Revision under review: dea5776732649773eaf6858120c7fd19e8346023 (HEAD at review time).

## What I looked at
The six screenshots named by the task's `## Visual Verification`: `.playwright-mcp/t1164-{1024,1440,1920}-{marked,sticky}.png`
(mtime 20:26–20:27 on 2026-10-17, i.e. produced with the last commit dea57767 at 20:27:05; untracked in git).
I copied them unchanged into this directory as `judge-t-1164-r3-9efd288b23e1-t1164-*.png` and cite those copies. I also made a 6× crop of the
1024 fit-view lane header (`judge-t-1164-r3-9efd288b23e1-crop-1024-marked-header.png`), because at fit the mark is tiny.

## Per screenshot (step 2 checks)
| shot | orange edge on FRAMEWORK · AUTHORITY header | ⚠ pill at top | name readable below the pill | dock header | lane rows "not on the map"? | covered/clipped |
|---|---|---|---|---|---|---|
| 1024-marked | yes; tiny at fit, clear in the 6× crop (orange box only on the middle band) | yes, small orange glyph at top of the band (crop) | the label is pixel-small at fit, same as every other label on the map; it sits below the pill | "2 findings · 0 errors, 2 warnings · 1 on the map" | no | no |
| 1024-sticky | yes | yes, ⚠ in a rounded pill | "FRAMEWORK · AUTHORITY" in full, above the dock (no "RAMEWORK" from the earlier review) | same | no | no |
| 1440-marked | yes (small at fit) | yes | below the pill | same | no | no |
| 1440-sticky | yes | yes | in full, below the pill, inside the visible lane | same | no | no |
| 1920-marked | yes | yes | below the pill | same | no | no |
| 1920-sticky | yes | yes | in full, below the pill | same | no | no |

The mark is on the right lane in all six: the orange edge is on the middle band (FRAMEWORK · AUTHORITY) only. HUMAN SOVEREIGNTY
and AGENT INITIATIVE are unmarked. In the fit views the dragged-out task "Start work" hangs below the pool, as described.

## Covered / clipped
- Toolbar: all buttons are whole at all three widths. At 1024 and 1440 it wraps to two rows; Save is visible.
- Side panels, collapse handles (◂ ▸) and the dock close (×) are visible and not overlapped.
- No autosave toast in any shot, so it covers no dock row (the earlier finding is gone).
- Dock: both WARN rows are readable. At 1024 the second row's last line sits at the viewport's bottom edge. The dock is a
  scrolling list with its header and both rows visible, so this is not a clipped control.
- In the sticky shots the canvas nodes are cut off by the dock and the panels. That is ordinary canvas content scrolled under
  fixed chrome, not a covered control. The pinned lane strip itself ends above the dock.

## Verdict
green: step 2 holds in all six screenshots. At 1024 fit the mark is small but present, as the AC expects.
