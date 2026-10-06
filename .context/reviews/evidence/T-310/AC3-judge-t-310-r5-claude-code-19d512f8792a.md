# T-310 Human AC#3 — stacked Clean nudge overlaps top-lane content

Reviewer: reviewer-judge-t-310-r5-claude-code-19d512f8792a:claude-code (rung-5-panel:claude-code)
Revision: 330535c0d2e6a2e7a9def834ab7fac2b32a6a9fd

## What I checked
1. Screenshot `docs/screenshots/t310-both-after.png` (copy: `AC3-judge-t-310-r5-claude-code-19d512f8792a-both-after.png`).
   - The lane-fix notice ("2 nodes were drawn outside their declared lane — moved back into place") sits in the top slot.
   - The stacked Clean nudge sits directly below it and **fully covers the `agt_2_agent` node body**;
     only the left edge of the node, the tail of its id label ("agt_…gent") and the incoming arrowhead stay visible.
   - The overlap is exactly as the AC describes. Nothing is hidden from the reviewer.
2. Source `src/aef-workflow-designer.html`:
   - L533 `.clean-nudge.stacked { top: 52px; }`. The base `.clean-nudge` is absolutely positioned in the canvas wrap at z-index 5, so it overlays the content.
   - L1573-1580: both banners have a ✕ dismiss button. L9331 dismisses the nudge; L9333-9335 dismisses the lane-fix
     notice and removes `.stacked`, which returns the nudge to the top slot. L10705-10706 clears both on document reload.
   - L8453 sets `stacked` only when the lane-fix notice is shown. The overlap needs both advisories, which means a malformed map.
3. Follow-up: I searched `.tasks/` for clean-nudge/advisory tasks. No open task tracks advisory-vs-canvas overlap
   (T-100 is completed and covered the original nudge; T-101 and T-102 are unrelated).

## Judgement
- It is cosmetic, and the operator's risk ruling puts it with the reviewer, not the human. Nothing here is irreversible or about direction.
- It is acceptable for closing T-310. It only happens on malformed maps when both advisories fire. It takes one click to clear, and it is
  not a new class of defect: the single nudge at 12px already overlays canvas content.
- It is still not fully satisfactory. The hidden node is in the lane-fixed top lane, right where the notice above points the user, so
  the banner partly hides what the notice is telling the user to look at. The AC names the fix but no follow-up task exists yet.

## Verdict: amber
Accept the overlap for T-310. Register a follow-up task (canvas top-padding while advisories are visible, or dock the
advisories outside the canvas) so the known defect is tracked and not just noted in prose.
