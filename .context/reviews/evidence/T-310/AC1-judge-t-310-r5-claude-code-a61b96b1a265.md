# T-310 Human AC#1 — independent review (rung-5-panel:claude-code, dispatch judge-t-310-r5-claude-code-a61b96b1a265)

Revision reviewed: 830b2b93bff239a4724369b6d53c2c2d7be8d3ce. `git diff --quiet 830b2b93 -- src tests/fixtures docs/screenshots/t310-both-before.png` is clean, so the build I ran is the reviewed build.

## What I did
- I opened `src/aef-workflow-designer.html` in headless Chromium (Playwright, 1600x900) from file://.
- I loaded `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` through the toolbar **Load…** file picker (`#btn-load`, the same `adoptImportedXml(..., {userImport:true})` path a drag-in or Open project uses). The 📂 Open project… button is hidden without the gallery server.
- I read the notice text and the in-memory model (`state.nodes`, `state.lanes`, `_laneReconcileCount`), took a screenshot (AC1-judge-t-310-r5-claude-code-a61b96b1a265-after.png), and compared it with docs/screenshots/t310-both-before.png.

## Findings
Lane bands (per the fixture header and laneMeta height 160): agent is 62..222 (top), framework is 222..382 (bottom).

| node | declared lane | fixture y | after import (x,y) | band now | result |
|---|---|---|---|---|---|
| request arrives (n_start) | agent | 110 | 180,110 | agent | untouched (agreed) |
| framework validates the request (n_check) | framework | 100 | 300,**270** | Framework · Authority | moved back, x kept |
| agent carries out the work (n_act) | agent | 300 | 470,**110** | Agent · Initiative | moved back, x kept |
| recorded (n_done) | framework | 310 | 640,310 | framework | untouched (agreed) |

- Notice, visible at the top of the canvas: "⚠ 2 nodes were drawn outside their declared lane — moved back into place". `_laneReconcileCount` = 2.
- Old-build screenshot (t310-both-before.png): "framework validates the request" sits in the AGENT · INITIATIVE band and "agent carries out the work" sits in the FRAMEWORK · AUTHORITY band. That is the swap the criterion describes. The old build also showed only a generic "could use Clean layout" nudge.
- New build: each of the two nodes is in its own lane. Each keeps its x column. Only y changed, to the target lane's row. The two nodes that agreed did not move at all. The flow order still reads left to right.

## Does it read as a repair?
Yes. The notice states a fact in the past tense ("were drawn outside their declared lane — moved back into place"). It is not an offer. Only the two nodes that conflicted moved, and they moved only vertically into the lane they declare. Nothing else on the map changed. Nothing in the move looks like the editor rearranging the author's work.

Verdict: green.
