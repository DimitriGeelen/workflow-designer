# T-1164 Human AC#1 — independent review (rung-3, revision 710e56900cbd)

Reviewer dispatch: judge-t-1164-r3-4571fa4aa0d8. **Verdict: amber**

## What I looked at
The six screenshots named in `## Visual Verification`, `.playwright-mcp/t1164-{1024,1440,1920}-{marked,sticky}.png`
(copies are in this directory; sha256 prefixes 1024-marked d24dc608, 1024-sticky aaa31676, 1440-marked 2e150361,
1440-sticky 9023f7ff, 1920-marked de24f56f, 1920-sticky 4dd0e9d2). I opened every one at full size and zoomed into the
lane-header area with PIL (crop-1920-marked-header.png, crop-1024-sticky-label.png).
Note: these PNGs are untracked in git (not in the tree at 710e5690, and not ignored), so the copies here are the record.

## Findings per step-2 clause
| clause | 1024 marked | 1024 sticky | 1440 marked | 1440 sticky | 1920 marked | 1920 sticky |
|---|---|---|---|---|---|---|
| orange edge on FRAMEWORK · AUTHORITY header (and on no other lane) | yes (small, at fit) | yes | yes | yes | yes | yes |
| ⚠ pill at the top of the header | yes (tiny, at fit) | yes | yes | yes | yes | yes |
| name readable below the pill | too small to read at fit (whole map is small, as the AC allows) | **"RAMEWORK · AUTHORITY": the "F" sits under the validator dock** | yes | yes | yes | yes |
| dock header "1 on the map" | yes | yes | yes | yes | yes | yes |
| lane rows not marked "not on the map" | yes | yes | yes | yes | yes | yes |
| nothing covered or clipped | ok | label clipped by the dock (see above) | **toast covers dock row 2** | **toast covers dock row 2** | **toast covers dock row 2** | **toast covers dock row 2** |

Details:
1. **The toast covers dock text (1440 and 1920, both states).** The "↩ Restored your unsaved work … / Start fresh" toast sits
   over the middle of the second WARN row (W-XML-LANE-CAPACITY) and hides part of its text, e.g. "member exten[…]4, occupies 64".
   The author's table says so too ("the autosave toast overlaps the dock's second row … as before this change"). It
   was there before this change and the toast is transient, but the AC says plainly that nothing in the dock is covered.
   At 1024 the toast does not appear in the shots.
2. **1024 sticky: the lane label is cut off by the dock.** The pinned framework header runs down under the validator
   dock, so its first letter is hidden and the label reads "RAMEWORK · AUTHORITY". The mark (edge + pill) is fully visible.
3. Minor, not counted against the AC: the left-panel collapse tab (◂) sits over the left edge of the sticky header strip
   at 1024/1440. It was there before this change and covers no text.

The core of the change is met: in every shot the right lane carries the edge and the ⚠ pill, the pill never sits on the
label, and the dock agrees ("1 on the map"; no row says "not on the map").

## What is needed for green
- Re-take the 1440/1920 shots after dismissing (or waiting out) the "Restored your unsaved work" toast, or start fresh
  so it never appears. Then confirm the dock rows are uncovered.
- For 1024 sticky, either scroll or zoom so the whole pinned label sits above the dock, or have the operator accept
  explicitly that the dock overlays the canvas bottom by design (so a tall lane label partly behind it is expected).
