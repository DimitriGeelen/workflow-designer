# T-310 AC1 — stacked Clean nudge overlaps top-lane content

Reviewer: reviewer-judge-t-310-r5-claude-code-387c42141a26:claude-code (rung-5-panel:claude-code)
Revision reviewed: 9f7d2662626b2a4325f4d96c3bf03c7e434aa146

## What I checked
1. `docs/screenshots/t310-both-after.png` at 9f7d2662 (byte-identical to the working tree copy; extracted with
   `git show`), cited as `AC1-judge-t-310-r5-claude-code-387c42141a26-both-after.png`. Also the matching before shot, cited as `AC1-judge-t-310-r5-claude-code-387c42141a26-both-before.png`.
2. CSS/JS in `.agentic-framework/vendor/designer/aef-workflow-designer-0.14.0.html` at 9f7d2662:
   - L512-533: `.clean-nudge` is `position:absolute; top:12px; z-index:5`; `.clean-nudge.stacked { top: 52px; }`.
   - L8259: the nudge gets `stacked` while the lane-fix notice is visible.
   - L9140-9141: dismissing the lane-fix notice hides it **and removes `stacked`**, so the nudge moves back up to 12px.
   - L10256-10257: both are cleared when a new document loads.

## Findings
- The overlap is real and as disclosed: in the after shot the stacked nudge (about y=105-188 in the image) covers
  the whole `agt_2_agent` node ("agent carries out the work"). Only its left edge and part of its id label are visible.
- **The disclosure understates it in two ways:**
  1. The hidden node is one of the "2 nodes … moved back into place" that the notice above it reports. So the
     user is told a correction happened, but the second banner hides one of the corrected nodes. The advisory
     hides the result it is reporting.
  2. "The single nudge already overlapped canvas content at 12px": in the before shot the single nudge covers only
     the lane-header/title strip and no node. Stacked, it reaches into the lane body, where nodes sit.
- Mitigations confirmed in code: both banners are dismissible. Dismissing the lane-fix notice re-docks the nudge at
  12px (L9141), so one click uncovers the node. Nothing is lost or changed in the document; this is presentation only.
- Risk class: cosmetic/UX. Not Tier 0, not irreversible, not a direction call, so no human escalation is needed.

## Verdict: amber
This is acceptable for this task: it is cosmetic, can be undone with one click, and leaves the document unchanged.
But it is not "fine as is", because the overlap hides the node the notice is about. The brief's own
"If not" path (canvas top padding while advisories show, or docking advisories outside the canvas) should be
registered as a follow-up task before this AC is closed.
