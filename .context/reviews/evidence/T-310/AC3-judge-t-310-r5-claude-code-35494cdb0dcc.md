# T-310 Human AC#3: stacked Clean nudge overlaps top-lane content

Reviewer: reviewer-judge-t-310-r5-claude-code-35494cdb0dcc:claude-code (rung-5-panel:claude-code)
Revision: 2ecd350d8fc1a36691b3216c138a3c98d8b20c03

## What I checked
1. Screenshot `docs/screenshots/t310-both-after.png` (copy: `AC3-judge-t-310-r5-claude-code-35494cdb0dcc-both-after.png`).
   - The lane-fix notice ("2 nodes were drawn outside their declared lane — moved back into place") is in the top slot.
   - The stacked Clean nudge sits below it and covers the body of `agt_2_agent` in the AGENT · INITIATIVE lane.
     Only the node's left edge, part of its id label and the incoming arrowhead remain visible. This matches the AC's disclosure.
2. Source `src/aef-workflow-designer.html` at this revision:
   - L512-528: `.clean-nudge` is absolutely positioned, top:12px, z-index 5. The single nudge already overlays the canvas.
   - L533: `.clean-nudge.stacked { top: 52px; }`. L8453 sets `stacked` only when the lane-fix notice shows.
   - L9331: ✕ dismisses the nudge. L9333-9335: dismissing the lane-fix notice also removes `stacked`, so the nudge returns to the top slot.
   - L10705: both are cleared on reload.
   - The overlap therefore needs both advisories, i.e. a malformed map, and one click clears it.
3. Follow-up tracking: the earlier claude-code seat's amber (19d512f8792a, rev 330535c0) asked for a tracked follow-up.
   That now exists: `.tasks/active/T-1078-advisory-banners-overlay-the-canvas-with.md`, status started-work.
   Its Agent ACs are measurable (no advisory rect intersects any node or label bbox on the T-310 fixture, checked at 1280 and 1720 px),
   and a poison-arm leg is to be wired into the bridge suite.

## Judgement
- This is cosmetic. Under the operator's risk ruling it is not a human call: nothing here is irreversible, Tier 0 or direction-setting.
- It is acceptable for T-310. The overlap is disclosed, limited to malformed maps, dismissible, and the same class as the existing
  single-nudge overlay.
- The real defect (the banner hides the node the notice points at) is now owned by T-1078, which has verifiable ACs.
  The amber condition from the prior round is resolved.

## Verdict: green
