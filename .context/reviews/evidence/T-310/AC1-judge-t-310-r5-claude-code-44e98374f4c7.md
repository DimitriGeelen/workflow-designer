# T-310 Human AC#1 — reviewer judge-t-310-r5-claude-code-44e98374f4c7 (rung-5-panel:claude-code)

Revision reviewed: e43e0f7028eb4c5cf2fd57d68f7bf6064e8b77e4 (`git diff e43e0f70 -- src` is empty;
the designer was extracted with `git show e43e0f70:src/aef-workflow-designer.html`).

## Method
I wrote my own driver (/tmp/rv310/shot.mjs, not the producer's harness). It serves the designer through
`tools/gallery-serve.py` and opens it in headless Chromium at 1200x820. It then loads
`tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` through the REAL user path: a trusted mouse click on
the toolbar "Load…" button (`#btn-load`), the file chooser intercepted by CDP, and
`DOM.setFileInputFiles`. Then it reads live `state` and the DOM and takes a full-page screenshot.
I ran the same driver against the pre-fix build (df5f5b6) as a control.

## Result — fixed build (e43e0f7)
Lane bands: agent (Agent · Initiative) 62..222, framework (Framework · Authority) 222..382.

| node | declared lane | y | centre-y | drawn in |
|---|---|---|---|---|
| request arrives | agent | 110 (unchanged) | 128 | agent |
| framework validates the request | framework | 100 → 270 | 302 | **framework** |
| agent carries out the work | agent | 300 → 110 | 142 | **agent** |
| recorded | framework | 310 (unchanged) | 328 | framework |

x is preserved for the moved nodes (300, 470). The notice `#lane-fix-notice` is visible at the top of the
canvas and reads: "⚠ 2 nodes were drawn outside their declared lane — moved back into place" (dismissible ✕).
The count (2) matches the two nodes that moved. The two nodes that already agreed did not move.
Screenshot: AC1-judge-t-310-r5-claude-code-44e98374f4c7-after.png. I read it visually: "framework validates the request" (orange
script task) is inside the FRAMEWORK · AUTHORITY band, and "agent carries out the work" (blue service task) is
inside the AGENT · INITIATIVE band.

## Control — pre-fix build (df5f5b6)
"framework validates the request" was drawn in agent (y=100). "agent carries out the work" was drawn in
framework (y=300). There was no notice. This matches docs/screenshots/t310-both-before.png, which I also
viewed. Screenshot: AC1-judge-t-310-r5-claude-code-44e98374f4c7-before-df5f5b6.png.

## Does it read as a repair?
Yes. The wording names the cause ("drawn outside their declared lane") and calls the move a correction
("moved back into place"). It gives an exact count, and only the conflicting nodes moved. The resulting
picture is coherent: each node sits in the lane its label and colour belong to.
Minor observations (do not block this AC):
- The connectors now zig-zag up and down between lanes, which is the honest consequence of the flow alternating lanes.
- In my run the Clean-layout nudge was not shown, so I did not see the stacked-banner overlap from Human AC#3 in this state.

## Verdict: green
