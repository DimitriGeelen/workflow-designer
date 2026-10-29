# Reviewer evidence — T-1339 AC#1

- dispatch: `judge-t-1339-r5-opencode-d0753962a6eb`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `7586da326eb217fd13cab0e458dbd7e95d93d061`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `6b350090f647b773b453a9a35ae2bf2e71fbaeb4d8a6d3edf81851a2b0a852c0`
- result.md sha256: `2fda29e99f1da590dc7f7acf87a431bf3cf438e2622b536f4e505de0bc662c00`

## The worker's verdict block

```
1. [AC] Import notice subprocess line truthful + fits at 1024/1440/1920
VERDICT: green
WHY: Truth: the fixture tests/fixtures/third-party/kitchen-sink.bpmn nests exactly 12 <bpmn:startEvent> inside subProcess Activity_088fmm5 and 1 endEvent inside transaction Activity_0djfr8f (13 elements, 2 subprocess parents; SUBPROC_TAGS = subProcess/transaction/adHocSubProcess at src/aef-workflow-designer.html:15051, hoist filter at :15504-15507 → hoistedNodes=13, hoistingSubs=2). The golden tests/goldens/third-party/kitchen-sink.bpmn.golden shows a save writes them nested: 12 startEvents inside lan_3_event (origin Activity_088fmm5, lines 161-291) and la3_end_event inside lan_9_transaction (lines 495-512). So "13 elements inside 2 subprocesses drawn at the top level of the canvas — on save they stay inside their subprocess" says exactly what a person sees (flat canvas, per the code comment "the canvas still draws the contents flat", :10713) and what a save does (nested in the file) — understandable as written, with the contrast doing the work. Fit: I could not view the PNGs (this model has no image input), so I re-ran the capture harness itself at this revision into scratch (node tools/_t1327-notice-shots.mjs $TMPDIR/t1339-ev): exit 0, 9/9 ok, and the regenerated measures.json is identical to docs/reports/T-1339-evidence/measures.json. It measures in a live page at 1024/1440/1920: notice rect inside the viewport at every width ([232,87,460,238] / [232,87,876,151] / [402,60,1016,133] — right edges 692/1108/1418 within 1024/1440/1920), no text clipping (scrollWidth/scrollHeight check), no drawn node under the notice, every header button on-screen. The notice is one part per line with the target line fifth in the DOM text at all three widths; the close button (lane-fix-dismiss) sits inside the notice element, whose full rect is in-viewport; the notice is absolutely positioned 12px inside .canvas-wrap, i.e. below the 48px+ header, so it covers no toolbar control; plain-designer-map-* shows shown:false at all three widths and the harness flags a notice-on-plain-map as a problem — none flagged.
GUIDANCE: none required. (For a future seat with image input, the six screenshots in docs/reports/T-1339-evidence remain the pixel-level record; my verification of them is via the in-page measures, reproduced identically at this revision.)

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
The image reads failed — this model cannot view images. Let me gather what non-visual evidence exists (measures.json, the HTML wording, the golden file) before deciding how much of the criterion I can evaluate.
measures.json gives DOM-extracted text and rects. Now verify the claim's truth against the golden file, and find the harness code that produced measures.json to know what `problems: []` actually checks.
The golden shows an event-subprocess with origin `Activity_088fmm5` and a transaction. Let me count the elements inside each, check the fixture's DI (drawn at top level), and find what generated measures.json.
Golden confirms the save behavior: 12 start events inside the `Activity_088fmm5`-origin subProcess, end event inside the transaction — 13 in 2 subprocesses. Now check the fixture's DI (drawn at top level), the notice code, and the shot harness.
The fixture does declare the subprocess shapes and the end-event shape at the plane level. Let me inspect the coordinates (are the 13 drawn outside the subprocess bounds?) and the designer code that computes the hoisting numbers.
The notice code is clear. Now verify the fixture's semantic nesting (13 elements inside the 2 subprocesses in the input file) and find how `hoistedNodes`/`hoistingSubs` are computed.
SUBPROC_TAGS includes transaction — 2 subprocesses, 13 nodes. Now find what wrote measures.json and what its `problems` field checks, plus the notice container CSS.
The harness measures the notice in a live page at each width (viewport containment, text clipping via scrollWidth, node overlap, header buttons, plain-map no-notice) and wrote both shots and measures.json. Strongest check: reproduce it myself into scratch. Let me see if node/chromium are available.
Node and chromium are present, and the harness writes only to its outdir plus mkdtemp scratch. Reproducing the evidence into my own scratch dir (tree untouched):
Reproduction is exact: 9/9 ok, and my regenerated measures.json is byte-equivalent to the committed evidence. One last geometry check — header height vs the notice's viewport top (toolbar uncovered):
All evidence is in. The line is true against the golden, and I independently reproduced the layout evidence at this revision (identical measures, 9/9 ok, tree untouched — the harness only read it and wrote to my scratch).

1. [AC] Import notice subprocess line truthful + fits at 1024/1440/1920
VERDICT: green
WHY: Truth: the fixture `tests/fixtures/third-party/kitchen-sink.bpmn` nests exactly 12 `<bpmn:startEvent>` inside subProcess `Activity_088fmm5` and 1 endEvent inside transaction `Activity_0djfr8f` (13 elements, 2 subprocess parents; `SUBPROC_TAGS` = subProcess/transaction/adHocSubProcess at src/aef-workflow-designer.html:15051, hoist filter at :15504-15507 → hoistedNodes=13, hoistingSubs=2). The golden `tests/goldens/third-party/kitchen-sink.bpmn.golden` shows a save writes them nested: 12 startEvents inside `lan_3_event` (origin `Activity_088fmm5`, lines 161-291) and `la3_end_event` inside `lan_9_transaction` (lines 495-512). So "13 elements inside 2 subprocesses drawn at the top level of the canvas — on save they stay inside their subprocess" says exactly what a person sees (flat canvas, per the code comment "the canvas still draws the contents flat", :10713) and what a save does (nested in the file) — understandable as written, with the contrast doing the work. Fit: I could not view the PNGs (this model has no image input), so I re-ran the capture harness itself at this revision into scratch (`node tools/_t1327-notice-shots.mjs $TMPDIR/t1339-ev`): exit 0, 9/9 ok, and the regenerated measures.json is identical to `docs/reports/T-1339-evidence/measures.json`. It measures in a live page at 1024/1440/1920: notice rect inside the viewport at every width ([232,87,460,238] / [232,87,876,151] / [402,60,1016,133] — right edges 692/1108/1418 within 1024/1440/1920), no text clipping (scrollWidth/scrollHeight check), no drawn node under the notice, every header button on-screen. The notice is one part per line with the target line fifth in the DOM text at all three widths; the close button (`lane-fix-dismiss`) sits inside the notice element, whose full rect is in-viewport; the notice is absolutely positioned 12px inside `.canvas-wrap`, i.e. below the 48px+ header, so it covers no toolbar control; `plain-designer-map-*` shows `shown:false` at all three widths and the harness flags a notice-on-plain-map as a problem — none flagged.
GUIDANCE: none required. (For a future seat with image input, the six screenshots in docs/reports/T-1339-evidence remain the pixel-level record; my verification of them is via the in-page measures, reproduced identically at this revision.)

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
