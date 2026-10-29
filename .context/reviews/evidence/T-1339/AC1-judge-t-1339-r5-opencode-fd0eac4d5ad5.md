# Reviewer evidence — T-1339 AC#1

- dispatch: `judge-t-1339-r5-opencode-fd0eac4d5ad5`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `42283c1d68fee383a8ba86146bcc2344d10792fe`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `0272a5486f4536811b23ef01333834cc3c4c38c0423165685018004be1b517b0`
- result.md sha256: `4505220439e9b5062d795bc38196740ce68bc0aba304b4b8aa9b22a5d004a589`

## The worker's verdict block

```
1. [AC] Import notice subprocess line truthful, readable at 1024/1440/1920; toolbar uncovered; plain map clean
VERDICT: green
WHY: Note: this seat's model cannot view images directly, so I verified the screenshots programmatically (tesseract OCR + PIL pixel/geometry analysis), which succeeded on every sub-check. (1) Truth: fixture tests/fixtures/third-party/kitchen-sink.bpmn holds exactly 13 flow elements inside 2 subprocesses — 12 start events inside event-subProcess Activity_088fmm5 and end event Event_1cutsq6 inside transaction Activity_0djfr8f — matching "13 elements inside 2 subprocesses"; the golden tests/goldens/third-party/kitchen-sink.bpmn.golden (what a save writes) keeps the 12 start events nested in lan_3_event and the end event nested in lan_9_transaction, so "on save they stay inside their subprocess" is true. The line (src/aef-workflow-designer.html:10713-10715) states the canvas/file contrast explicitly: drawn flat at the top level of the canvas, nested on save. (2) Readability/fit: measures.json text for kitchen-sink at 1024/1440/1920 contains the line verbatim as the fifth part; each -notice.png crop pixel-matches the exact rect region of its full-window screenshot and every rect lies fully inside its viewport ([232,87,460,238]⊂1024×768; [232,87,876,151] at 1440; [402,60,1016,133]⊂1920×1080) — not clipped. OCR extracted every clause at all three widths, and 6× magnification OCR of the fifth line reads "• 13 elements inside…". (3) Close button: the ✕ dismiss button (lane-fix-dismiss, src/aef-workflow-designer.html:1788) renders in the notice's top-right at all three widths (identical 77-pixel glyph signature) and is inside the viewport, hence reachable. (4) Toolbar uncovered: the strips above the notice (0–87px at 1024/1440, 0–60px at 1920) OCR the full toolbar (Open project…, Pending refs…, instances, fit, Add Lane, Reset, Clean layout, View XML, Settings, Load…, Check, Versions, Save) and are pixel-near-identical (mean |diff| ≤ 0.73/255, only the boundary row differs) to the same strips in the no-notice plain-map shots. (5) Plain map: measures.json records shown: false with empty text for plain-designer-map at all three widths, and OCR of plain-designer-map-1440.png shows only toolbar/palette — no notice.
GUIDANCE: none needed; the criterion is met. (For the record: visual confirmation was by OCR/pixel analysis because this seat's model lacks image input; all sub-checks were executable and passed.)

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
All evidence files exist. Let me view the notice screenshots at the three widths.
Image reading is not supported by this model. Let me try to verify what I can programmatically — OCR on the PNGs, the HTML wording, the golden file, and measures.json.
measures.json gives the notice text and rects; crops match rect sizes exactly. Now let me OCR the screenshots to verify what actually rendered, and check the fixture/golden for truthfulness.
OCR confirms the notice renders fully at all three widths, and the plain map's OCR shows no notice. Now verifying truthfulness against the fixture and golden.
The 12 start events nested in the golden's `lan_3_event` subProcess confirm "stay inside their subprocess". Now checking the transaction (2nd subprocess) and the end event claim.
Truthfulness verified: fixture has 13 elements in 2 subprocesses (12 start events in `Activity_088fmm5`, end event in transaction `Activity_0djfr8f`); golden writes them nested (`lan_3_event`, `lan_9_transaction`). Now checking geometry in the full-window shots: toolbar uncovered, notice inside viewport, close button present.
Notice rects are inside viewports and pixel-match the full shots; toolbar strip above OCRs fully at both widths. Now: close button presence/reachability, and toolbar-region diff vs the no-notice plain map to prove nothing is covered.
The notice has a dismiss button (`✕`, `lane-fix-dismiss`, src/aef-workflow-designer.html:1788). Let me confirm the glyph actually renders in each screenshot's notice corner via pixel analysis.
One last check: OCR mangled the leading "13" digit — let me magnify the fifth line specifically to confirm it renders correctly.
All checks complete. The 6× magnification OCR reads `"* 13 elements insid..."` — the "13" renders legibly; earlier misreads were OCR noise. Here is my verdict:

1. [AC] Import notice subprocess line truthful, readable at 1024/1440/1920; toolbar uncovered; plain map clean
VERDICT: green
WHY: Note: this seat's model cannot view images directly, so I verified the screenshots programmatically (tesseract OCR + PIL pixel/geometry analysis), which succeeded on every sub-check. (1) Truth: fixture `tests/fixtures/third-party/kitchen-sink.bpmn` holds exactly 13 flow elements inside 2 subprocesses — 12 start events inside event-subProcess `Activity_088fmm5` and end event `Event_1cutsq6` inside transaction `Activity_0djfr8f` — matching "13 elements inside 2 subprocesses"; the golden `tests/goldens/third-party/kitchen-sink.bpmn.golden` (what a save writes) keeps the 12 start events nested in `lan_3_event` and the end event nested in `lan_9_transaction`, so "on save they stay inside their subprocess" is true. The line (src/aef-workflow-designer.html:10713-10715) states the canvas/file contrast explicitly: drawn flat at the top level of the canvas, nested on save. (2) Readability/fit: measures.json text for kitchen-sink at 1024/1440/1920 contains the line verbatim as the fifth part; each `-notice.png` crop pixel-matches the exact rect region of its full-window screenshot and every rect lies fully inside its viewport ([232,87,460,238]⊂1024×768; [232,87,876,151] at 1440; [402,60,1016,133]⊂1920×1080) — not clipped. OCR extracted every clause at all three widths, and 6× magnification OCR of the fifth line reads "• 13 elements inside…". (3) Close button: the ✕ dismiss button (`lane-fix-dismiss`, src/aef-workflow-designer.html:1788) renders in the notice's top-right at all three widths (identical 77-pixel glyph signature) and is inside the viewport, hence reachable. (4) Toolbar uncovered: the strips above the notice (0–87px at 1024/1440, 0–60px at 1920) OCR the full toolbar (Open project…, Pending refs…, instances, fit, Add Lane, Reset, Clean layout, View XML, Settings, Load…, Check, Versions, Save) and are pixel-near-identical (mean |diff| ≤ 0.73/255, only the boundary row differs) to the same strips in the no-notice plain-map shots. (5) Plain map: measures.json records `shown: false` with empty text for plain-designer-map at all three widths, and OCR of plain-designer-map-1440.png shows only toolbar/palette — no notice.
GUIDANCE: none needed; the criterion is met. (For the record: visual confirmation was by OCR/pixel analysis because this seat's model lacks image input; all sub-checks were executable and passed.)

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
