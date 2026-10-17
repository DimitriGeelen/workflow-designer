# T-1164 Human AC#1 — independent review (rung-3, revision 6d9662c03d68)

Reviewer dispatch: judge-t-1164-r3-2def7c2f72ca. **Verdict: amber**

## What I looked at
The six screenshots named in `## Visual Verification`, the current `.playwright-mcp/t1164-{1024,1440,1920}-{marked,sticky}.png`
(written 2026-10-17 20:19:56–20:20:00, i.e. regenerated for the fix commit 6d9662c0 at 20:20:22). They differ from the
older un-prefixed copies in this directory, which belong to the first review of 710e5690. My copies are prefixed
`judge-t-1164-r3-2def7c2f72ca-t1164-*.png` (sha256 prefixes 1024-marked e0c0d595, 1024-sticky 9388f754, 1440-marked ed3445ed,
1440-sticky 0b801d05, 1920-marked 5fa0c725, 1920-sticky 2daf306c). I opened each one at full size and enlarged the
lane-header areas with PIL (`judge-t-1164-r3-2def7c2f72ca-crop-{1024,1440,1920}-marked-header.png`, `judge-t-1164-r3-2def7c2f72ca-crop-1440-sticky-toast.png`).

## Findings per step-2 clause
| clause | 1024 marked | 1024 sticky | 1440 marked | 1440 sticky | 1920 marked | 1920 sticky |
|---|---|---|---|---|---|---|
| orange edge on FRAMEWORK · AUTHORITY header only | yes (small, at fit) | yes | yes | yes | yes | yes |
| ⚠ pill at the top of the header | yes (tiny, at fit) | yes | yes | yes | yes | yes |
| name readable below the pill | at fit too small to read (the whole map is small, which the AC allows); the pill is above the label | yes, full "FRAMEWORK · AUTHORITY" above the dock | yes (small) | yes | yes | yes |
| dock header "1 on the map" | yes | yes | yes | yes | yes | yes |
| no lane row marked "not on the map" | yes | yes | yes | yes | yes | yes |
| nothing covered or clipped | ok (no toast) | ok | ok (toast in empty canvas, dock clear) | **toast covers canvas content** | ok (toast in empty canvas, dock clear) | **toast covers canvas content** |

## The fixes from the first review
- Toast over dock row 2: fixed. In all four 1440/1920 shots the "Restored your unsaved work … / Start fresh" toast now
  sits above the dock, and both dock WARN rows can be read in full.
- 1024 sticky "RAMEWORK": fixed. The pinned label now reads "FRAMEWORK · AUTHORITY" in full, centred in the visible part
  of the lane and wholly above the dock.

## What remains
Moving the toast up put it over the canvas. In both sticky shots (zoom 160%) it now covers diagram content:
- **1440 sticky**: it cuts the gateway label "Outcome?" to "Outcom", hides the id under it ("frw_gw_…") and covers
  the edge that runs into "Run completion gate battery" (see `judge-t-1164-r3-2def7c2f72ca-crop-1440-sticky-toast.png`).
- **1920 sticky**: it covers the id under "Outcome?" ("frw_gw_…") and the edge into "Run completion gate battery".
In the fit shots it falls on empty canvas and covers nothing.

The toast is a transient, pre-existing autosave notice, not part of the lane mark. Every part of the change itself holds
in all six shots: the right lane is marked, the pill never sits on the label, and the dock agrees. But the AC says
"nothing in the canvas or dock is covered", and in two of the six shots something in the canvas is.

Minor, not counted: the left-panel collapse tab (◂) overlaps the left edge of the sticky header strip at 1024 and 1440.
It covers no text and was there before this change.

## What is needed for green
Either:
- re-take the two sticky shots with the toast gone ("Start fresh", wait it out, or clear the autosave before the run),
  then confirm no canvas content is covered; or
- have the operator rule that a transient toast over the canvas is out of scope for this AC.
