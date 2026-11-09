# T-358 AC1 — independent review (rung-5-panel:claude-code)

Revision reviewed: 80b3bf5a83a4a90a1e73d25bc94c96adef6b7ed7 (HEAD at review time).

## What I checked
I opened all 22 PNGs in `docs/reports/T-358-evidence/`: 7 maps × 1024/1440/1920, plus `boundary-events-1024-bottom.png`.
The 1024/768, 1440/900 and 1920/1080 sizes are correct. In each I checked the vertical extent of the pool, whether any lane band or lane header was drawn, where "+ Add a lane" sits, and whether the advisory card's controls were reachable.

| Map | 1024 | 1440 | 1920 | Notes |
|---|---|---|---|---|
| boundary-events | ok (opening frame + `-bottom` frame) | ok | ok | Header top encloses SubProcess_1/Task_2 and the boundary events; the pool bottom encloses `joker` (link event). In the `-bottom` frame the pool's lower border is under joker and above the add-lane strip. |
| collaboration-message-flows | ok | ok | ok | Our pool is above, then the add-lane strip, then "Pool · read-only" with a gap and no overlap. Message flows cross the strip; at 1440/1920 one flow is drawn over the word "a" in "+ Add a lane" (cosmetic, outside this criterion). |
| i18n-documentation | ok | ok | ok | 3 elements, all inside the pool; the "(task)" label is just below the header. |
| multiple-diagrams | ok | ok | ok | 1 task inside the pool. |
| nested-subprocesses | ok (vertical) | ok (vertical) | ok (vertical) | Everything from SubProcess_1 at the top to the end event at the bottom is inside the pool. The first start event at x≈26 sits on/over the LEFT border, which is out of scope per the criterion's narrowing (T-1386). |
| simple | ok | ok | ok | All 5 elements are inside the pool. |
| zeebe-service-task | ok | ok | ok | All 4 elements are inside the pool. |

In all 21 frames plus the extra one:
- There is one pool header ("<Process> · workflow:judge-t-358-r5-claude-code-f92a8a3eff5e" or "Pool · workflow:…"). No lane band or vertical lane header ("HUMAN · SOVEREIGNTY", etc.) is drawn.
- "+ Add a lane" is the dashed strip directly below the pool's bottom border. At 1024 the label text is right-aligned beyond the visible canvas, but the strip itself is visible.
- The advisory card's "×" buttons, "▸ 1 more" and "Clean layout" are all visible and none is cut off.

So the visual part of the criterion (Expected: one pool whose top and bottom enclose the whole diagram, with no invented lanes, at all three widths) **is met**.

## What is not met as written
The criterion's scope note cites `docs/reports/T-358-evidence/v0.40.0-nested-subprocesses-1440.png` to show the left-edge overlap is pre-existing.
**That file does not exist at the reviewed revision.** It was deleted in commit 724bfe0db (shown in `git show --stat`: `v0.40.0-nested-subprocesses-1440.png | Bin 157459 -> 0 bytes`), apparently when the screenshot set was re-recorded. T-1386 cites the same path.
I recovered it from 58c641d64 (`v0.40.0-nested-subprocesses-1440-from-58c641d64-judge-t-358-r5-claude-code-f92a8a3eff5e.png`) and it supports the claim: in 0.40.0 the start event is drawn across the left border and over the "FRAMEWORK · AUTHORITY" lane label, with invented lanes HUMAN · SOVEREIGNTY / FRAMEWORK · AUTHORITY / AGENT · INITIATIVE.
The claim is true, but the path the criterion cites is out of date.

## Cited copies
- nested-subprocesses-1440-judge-t-358-r5-claude-code-f92a8a3eff5e.png
- collaboration-message-flows-1440-judge-t-358-r5-claude-code-f92a8a3eff5e.png
- boundary-events-1024-bottom-judge-t-358-r5-claude-code-f92a8a3eff5e.png
- v0.40.0-nested-subprocesses-1440-from-58c641d64-judge-t-358-r5-claude-code-f92a8a3eff5e.png
