# T-1339 Human AC#1 — independent review (seat claude-code, dispatch judge-t-1339-r5-claude-code-c114243ea574)

Revision reviewed: 42283c1d68fee383a8ba86146bcc2344d10792fe

## 1. Notice screenshots (1024 / 1440 / 1920)
Viewed kitchen-sink-{1024,1440,1920}-notice-judge-t-1339-r5-claude-code-c114243ea574.png. All six notice lines are fully readable at every width;
at 1024 the lines wrap cleanly inside the box (box rect 460x238 per measures.json), at 1440/1920 each line is a single row.
Fifth line reads exactly: "13 elements inside 2 subprocesses drawn at the top level of the canvas — on save they stay inside their subprocess".
measures.json reports problems: [] for every kitchen-sink width.

## 2. Truth of the fifth line vs the golden
Parsed tests/goldens/third-party/kitchen-sink.bpmn.golden (XML, flow-node children per container):
- subProcess lan_3_event ("Event-Subprocess", = fixture Activity_088fmm5, triggeredByEvent) contains 12 startEvents (la3_start_event … la3_start_event_12).
- transaction lan_9_transaction ("Transaction", = fixture Activity_0djfr8f) contains 1 endEvent (la3_end_event).
- All other subProcess/transaction/adHocSubProcess containers have 0 flow-node children.
Total 12 + 1 = 13 elements in 2 subprocesses — matches the count and claim. The fixture has the same distribution
(Activity_088fmm5: 12, Activity_0djfr8f: 1), so a save keeps them nested.
On the canvas (kitchen-sink-1920-judge-t-1339-r5-claude-code-c114243ea574.png) the start events are drawn as free top-level nodes in the lane next to a collapsed
"Event-Subprocess" box, and the end event sits under the "Transaction" box — i.e. flat on the canvas, as the line says.
Reading: "drawn at the top level of the canvas" + "on save they stay inside their subprocess" clearly conveys flat-on-canvas,
nested-in-file. Source wording at src/aef-workflow-designer.html:10715 matches the screenshot text.

## 3. Full-window layout
kitchen-sink-1024-judge-t-1339-r5-claude-code-c114243ea574.png: notice at x 232–692, y 87–325, inside the canvas column between left palette and right inspector;
close (×) visible at right edge of the box; both toolbar rows (ending at ~y 70) uncovered.
kitchen-sink-1920-judge-t-1339-r5-claude-code-c114243ea574.png: notice centred above the canvas, y 60–193, close × visible; single-row toolbar (y ~0–45) uncovered.
No clipping at either width.

## 4. Plain designer map
plain-designer-map-1440-judge-t-1339-r5-claude-code-c114243ea574.png: arc-lifecycle map, no import notice at all (measures.json shown: false at all widths).

## Verdict: green
