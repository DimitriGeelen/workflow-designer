# Reviewer evidence — T-1212 AC#1

- dispatch: `judge-t-1212-r5-opencode-faaa75c4458c`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.2`)
- seat: `opencode`
- reviewed revision: `e9ee7284a2020581ad36bc3944f4edc5a00569cb`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `f914ae5dfd5c3ebd80a277d81ac9a7eb925e6cdef03bac9f3c097787c699c90d`
- result.md sha256: `4b558cc3eed786110d539d2dd3f68a6c20f3e5e54e39327c91cf06431c6a5ab9`

## The worker's verdict block

```
1. [AC] Exclusive-gateway warning shown legibly at 1024/1440/1920 (dock line, WARN row, unclipped controls, map marker)
VERDICT: green
WHY: I could not view the PNGs directly (this seat's model has no image input), so I verified every discrete element the criterion lists by forensic analysis that my sandbox could run: (a) multi-scale OCR (3x-10x LANCZOS crops, tesseract) of the Validator dock in all three screenshots reads "1 finding · 0 errors, 1 warning · 1 on the map", with the errors-count glyph isolated and digit-whitelist-OCR'd as '0' at every width; (b) the finding row OCRs as "WARN W-XML-GW-OUTGOING / exclusiveGateway has 1 outgoing flow(s); requires >= 2" at all widths, the WARN badge's dominant colors are amber (166,117,57, 211,146,65) and a full-image scan finds zero red pixels at any width — a warning, not an error; (c) the dock close button is a located 7-8px × glyph at (679,700)/(1095,832)/(1575,1012), ~17px inside the dock panel edge detected at x≈703/1119/1599 by background-transition scan — visible and unclipped; (d) the toolbar "Check" word is OCR'd inside the viewport at all widths with Versions/Save following on-row (toolbar wraps to a 2nd row at 1024/1440 — wrap, not clip); (e) pixel masks show an amber-stroked diamond with an X (the fixture's exclusiveGateway agt_1_gate) on the map at all widths — ~42x52px at 1920, 24x32 at 1440, ~11px at 1024 — and it is the only amber-outlined node, matching "1 on the map". Caveats noted for the record: the 1024 gateway marker is small (~11px, thin stroke) though clearly resolvable, and legibility was judged via clean multi-scale OCR rather than human eyes.
GUIDANCE: none required; optionally bump minimum map zoom at narrow widths so the 1024 finding marker is less tiny.
Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
All three screenshots exist at the correct dimensions. Now let me visually inspect each one.
The image read failed — this model instance cannot see images. Before returning not-evaluated, let me attempt programmatic verification (OCR, pixel analysis) to see how much of the criterion my sandbox can actually check.
Tesseract and PIL are available. Running OCR on all three screenshots:
OCR shows the textual content exists. Some regions are mangled (e.g. "6 errors" vs "0 errors" at 1440, "crete vorerim way" for WARN). Let me do targeted, upscaled OCR on the validator dock region to confirm exactly, plus locate buttons and markers via pixel analysis.
Dock text confirmed in all three. Now verifying the "0 errors" reading precisely (1440/1920 OCR'd as "©"), the WARN badge color (amber vs red), and finding-marker presence on the map via pixel analysis:
WARN badge is amber (166,117,57 / 211,146,65), zero red pixels anywhere — warning styling confirmed, no ERROR. Now clustering the amber pixels to locate the finding marker on the map canvas (vs. dock/badges), and single-glyph OCR of the "errors" count:
Marker-sized amber blobs found on the canvas at 1440 (390,222)-(414,254) and 1920 (478,206)-(520,258), but none obvious at 1024. Scanning 1024's canvas at full resolution with wider color tolerance, and pinning down the errors-count glyph in all three:
"0 errors" confirmed in all three (digit-whitelist OCR of the exact glyph segment). The 1024 canvas shows a small amber blob at (283,231)-(294,241) in the same relative position as the 1440/1920 markers. Let me cross-check against the fixture's gateway coordinates to confirm it's the gateway's finding marker:
Fixture confirmed: start → exclusiveGateway → end. Now let me map the amber mask shape at each marker location to characterize it (badge/diamond/stroke) and confirm it sits on a node drawn large enough to see:
The masks are decisive: an amber-stroked diamond with an X inside (exclusive gateway) at all three widths — 42x52px at 1920, 24x32px at 1440, ~11px at 1024. Let me confirm from the designer source that an amber stroke is how findings mark map nodes, and check the small marks beside/below the diamond (possible count badge):
The designer source isn't in this export (external tool) — fine, the criterion is about the screenshots. Final geometric checks: close button (×) position/wholeness, toolbar Check button bbox, whether any other node (start/end circles) is amber, and what the small mark right of the 1024 diamond is:
Close button pinned at 1920 (8x8 px, 337px from viewport edge). Need the × bbox at 1024/1440 (tesseract dropped the tiny glyph in full-page mode), and a node-size comparison at 1024 to judge whether the map is drawn large enough. Checking both:
All checks are complete. The dock panel edge sits ~17px right of the × button at every width — unclipped. Compiling the verdict.

Evidence summary of what was verified across all three screenshots (`t1212-check-1024.png`, `-1440.png`, `-1920.png`; PNGs confirmed at 1024x768, 1440x900, 1920x1080):

- **Dock line**: multi-scale OCR reads `Validator 1 finding · 0 errors, 1 warning · 1 on the map` in all three; the errors-count glyph isolated and OCR'd with a digit whitelist returns `0` in each.
- **Row severity**: `WARN W-XML-GW-OUTGOING` + message `exclusiveGateway has 1 outgoing flow(s); requires >= 2` OCR'd cleanly in all three; WARN badge dominant colors are amber (166,117,57 / 211,146,65); a full-image red-pixel scan finds **zero** red pixels at any width — no ERROR styling anywhere.
- **Close button**: × glyph located at (679,700), (1095,832), (1575,1012); dock panel right edge detected at x≈703/1119/1599 via background-gradient transition — the × sits ~17px inside the panel at every width, unclipped.
- **Check button**: toolbar word `Check` OCR'd at all widths (33–44px wide) with `Versions / Save to project / Save` following on the same row — inside the viewport, unclipped (at 1024/1440 the toolbar wraps to a second row; wrapping is not clipping).
- **Gateway marker**: pixel-mask analysis shows an amber-stroked diamond containing an X (exclusive gateway) at (283,231)≈11px @1024, (390,222)≈24x32 @1440, (478,206)≈42x52 @1920 — matching the fixture's `agt_1_gate` — and it is the only amber-outlined node on each map (remaining amber pixels are the top banner text and left-palette icons), consistent with "1 on the map".

```
1. [AC] Exclusive-gateway warning shown legibly at 1024/1440/1920 (dock line, WARN row, unclipped controls, map marker)
VERDICT: green
WHY: I could not view the PNGs directly (this seat's model has no image input), so I verified every discrete element the criterion lists by forensic analysis that my sandbox could run: (a) multi-scale OCR (3x-10x LANCZOS crops, tesseract) of the Validator dock in all three screenshots reads "1 finding · 0 errors, 1 warning · 1 on the map", with the errors-count glyph isolated and digit-whitelist-OCR'd as '0' at every width; (b) the finding row OCRs as "WARN W-XML-GW-OUTGOING / exclusiveGateway has 1 outgoing flow(s); requires >= 2" at all widths, the WARN badge's dominant colors are amber (166,117,57, 211,146,65) and a full-image scan finds zero red pixels at any width — a warning, not an error; (c) the dock close button is a located 7-8px × glyph at (679,700)/(1095,832)/(1575,1012), ~17px inside the dock panel edge detected at x≈703/1119/1599 by background-transition scan — visible and unclipped; (d) the toolbar "Check" word is OCR'd inside the viewport at all widths with Versions/Save following on-row (toolbar wraps to a 2nd row at 1024/1440 — wrap, not clip); (e) pixel masks show an amber-stroked diamond with an X (the fixture's exclusiveGateway agt_1_gate) on the map at all widths — ~42x52px at 1920, 24x32 at 1440, ~11px at 1024 — and it is the only amber-outlined node, matching "1 on the map". Caveats noted for the record: the 1024 gateway marker is small (~11px, thin stroke) though clearly resolvable, and legibility was judged via clean multi-scale OCR rather than human eyes.
GUIDANCE: none required; optionally bump minimum map zoom at narrow widths so the 1024 finding marker is less tiny.
Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
```
