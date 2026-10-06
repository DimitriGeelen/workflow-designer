# T-310 AC1 (Human AC#3) — stacked Clean nudge overlaps top-lane content
Reviewer: reviewer-judge-t-310-r5-claude-code-7e00e3cc94fd:claude-code · rung-5-panel:claude-code · revision 43d2afa8

## What I checked
1. Screenshot `docs/screenshots/t310-both-after.png` (copy: `AC1-judge-t-310-r5-claude-code-7e00e3cc94fd-both-after.png`) and the
   before shot (copy: `AC1-judge-t-310-r5-claude-code-7e00e3cc94fd-both-before.png`).
2. Source `src/aef-workflow-designer.html`:
   - :512-533 `.clean-nudge` is absolute, top:12px, z-index 5; `.clean-nudge.stacked { top: 52px; }`.
   - :8320-8354 `maybeShowLaneFixNotice()` toggles `stacked` on the nudge whenever the lane-fix notice shows.
   - :9231-9236 both banners are dismissible; dismissing the lane-fix notice drops `stacked` (nudge returns to 12px).
   - :3010-3018 `syncOverlayPin()` pins both banners to the viewport, so scrolling/panning the canvas moves content out from under them.
   - :10605-10606 both are cleared on the next load.

## Findings
- The overlap is real and as disclosed: in the after shot the stacked nudge (y≈105-190px in the 2x shot)
  **completely hides the `agt_2_agent` task node**. Only its id label and an arrowhead are visible beneath it.
- That node is the one the lane-fix notice above says was "moved back into place". So the reader is told
  a node moved and cannot see where it went until they dismiss a banner or pan. The AC text calls this
  "the same behaviour one row down". That is accurate mechanically, but it understates the effect:
  the banner hides the content that the banner above it is reporting on.
- Mitigations confirmed in code: both banners can be dismissed with ✕, and dismissing the notice restores the single-slot position.
  The banners only appear after an import, they don't touch the document, and panning reveals the node. There is no data or
  correctness impact. It is purely presentational and reversible.
- The pre-existing single nudge (12px) already overlapped canvas content (before shot: it sits over the lane header strip).
- Side note, not part of this AC: `.clean-nudge-msg` is `white-space: nowrap`. The combined lane-fix message
  (move + grow + T-603 skip parts joined with "; ") can grow very wide, and the stacked layout does not handle that.

## Judgement
Not a risk, irreversibility or direction call, so this does not escalate. It is acceptable to ship T-310 because the overlap is
transient, dismissible and harmless to data. But it is not cleanly "acceptable as is": the hidden node is the subject
of the first banner. The disclosed follow-up (top padding on the canvas while advisories are visible, or docking
the advisories outside the canvas) should be filed as a real task, not left as a note.
