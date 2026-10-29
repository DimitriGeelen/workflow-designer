# T-1339 Human AC#1 — independent review (rung-5-panel:claude-code, dispatch judge-t-1339-r5-claude-code-66a506082770)

Revision reviewed: 7586da326eb217fd13cab0e458dbd7e95d93d061 (HEAD at review time; screenshots and wording both come from this commit).

## 1. Notice shots (kitchen-sink-{1024,1440,1920}-notice-judge-t-1339-r5-claude-code-66a506082770.png)
I viewed all three. Each shows the same 6 lines, all readable and not truncated: 1024 wraps lines to two rows, and 1440/1920 show one row per line.
The 5th line reads: "13 elements inside 2 subprocesses drawn at the top level of the canvas — on save they stay inside their subprocess".
measures.json for these shots records shown=true, problems=[] and the same text.

## 2. Truth of the 5th line against fixture and golden
- Fixture tests/fixtures/third-party/kitchen-sink.bpmn: Activity_088fmm5 (Event-Subprocess, triggeredByEvent) contains 12 startEvents
  (Event_1l5ozbh … Event_09uyr4s). Transaction Activity_0djfr8f contains 1 endEvent (Event_1cutsq6). Event_0m5cdgr and Event_1vk962b come
  after </bpmn:subProcess>, so they are top-level. The other subprocesses (Activity_0pzvbay, Activity_08egzqv, Activity_0g37k20, Activity_0r6ceyw, Activity_137lgd1,
  Activity_1fi82ot) have no flow-node children. 12 + 1 = 13 elements in 2 subprocesses, which matches the line.
- Golden tests/goldens/third-party/kitchen-sink.bpmn.golden: lan_3_event (origin Activity_088fmm5, lines 161–291) holds the 12 startEvents
  (la3_start_event*, same event-definition ids). lan_9_transaction (origin Activity_0djfr8f, lines 495–512) holds la3_end_event
  (origin Event_1cutsq6, cancelEventDefinition). So a save keeps them inside their subprocess, as the line says.
- The canvas is flat. kitchen-sink-1920-judge-t-1339-r5-claude-code-66a506082770.png shows the Event-Subprocess box with the start events drawn as top-level nodes around it, and the
  Transaction with its end event at the top level. "drawn at the top level of the canvas" is accurate.
- Readability: the line contrasts the canvas (flat) with the file (nested on save) in one sentence, and a reader can follow it.
  Small point: "they stay inside their subprocess" mixes plural and singular. It is still clear, so I don't count it as a defect.
- Source: src/aef-workflow-designer.html:10714-10715 produces exactly this string from nk.hoistedNodes / nk.hoistingSubs.

## 3. Full-window fit (kitchen-sink-1024-judge-t-1339-r5-claude-code-66a506082770.png, kitchen-sink-1920-judge-t-1339-r5-claude-code-66a506082770.png)
- 1024: the notice spans x 232–692 and y 87–325. It sits in the canvas column between the left palette and the right inspector, below the
  two-row toolbar (which ends at about y 70). All toolbar controls are uncovered, the × close button at about (674,205) is visible, and no line is clipped.
- 1920: the notice sits at the top of the canvas below the one-row toolbar. Nothing is covered, × at about (1400,126), every line is whole.

## 4. Plain designer map (plain-designer-map-1440-judge-t-1339-r5-claude-code-66a506082770.png)
arc-lifecycle loaded with no import notice and no other banner, and the toolbar is uncovered.

## Verdict: green
