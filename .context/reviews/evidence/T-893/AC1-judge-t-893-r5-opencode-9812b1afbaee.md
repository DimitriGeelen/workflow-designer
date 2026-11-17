# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-opencode-9812b1afbaee`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `7c61a110a657ceb8e5d109ca30e85d86be26348b`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `c955f751d5f1d67cd7238242e1d5001d9201c98495ee38526462a3814b67d740`
- result.md sha256: `3c03a23c678be42450d908358deed4c9483bd641172e475c82cc5aa4a5b64411`

## The worker's verdict block

```
1. [AC] The two markers read as different kinds of thing, and the common case is silent
VERDICT: green
WHY: Verified on the committed docs/reports/t893-shots/{none,differs,missing}-m.png (316px-wide element crops of the task-lifecycle fixture) by pixel decode: none-m — above the node fill (rows 58-181) there is nothing but the node's own 3px border stroke; no marker of any color (common case silent). differs-m — a faint-gray (#5a6173) text cluster at rows 59-71, x 53-99 above the box's top-left, with the "◆" diamond and 3-4 mono glyphs readable in the pixel map ("◆ ini"; source line 4587 ['◆ ' + ab, '◆']); normal weight, measured contrast 3.10:1 on the background — the same faint/mono/8px class the app uses for id badges, i.e. it reads as an annotation, not an alarm. missing-m — an orange (#f5a847) bold (CSS :718 font-weight:600) text cluster at rows 61-71, x 73-136, glyphs legible as "⚠ no auth" (ladder ['⚠ no authority','⚠ no auth','⚠'], line 4590; "⚠ no authority" ≈67px would run past top-centre ≈x157 — marker ends at x136, exactly the longest-fitting form per T-1069); contrast 9.66:1 — 3× the differs marker, and #f5a847 is the theme's WARN/defect token (finding badges/pills :756-768, io-finding :1263, tone-warn :824), so it reads as a defect. Full text is the <title> (hover), per :4587/:4589. Position: ~6px clear above the node border; the incoming edge's label block (rows 30-39, x 148-312) sits above-right and disjoint — close but no collision in the -m shot, matching the task's own flag. The subtle/loud pitch is right: an unweighted near-whisper for a mere override vs the app's established alarm color at 3× contrast for a real hole. Side observations: differs-m.png and differs-l.png are byte-identical (md5 395195fb…) — legitimate under the label fit ladder ("Enter issues (auto → healing diagnose)" fits at the same step at m and l, while none-m/none-l differ in the label region), and it does not affect the -m judgment.
GUIDANCE: none
Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
The 9 PNGs already exist in the export. Let me read the shot script and find the agent's `## Visual Verification` notes.
The task file is `.tasks/active/T-893-render-authority-on-the-element-and-indi.md`. Let me read its Visual Verification section and view the three key screenshots.
My model cannot view images directly in this environment — I'll verify the shots by pixel-level analysis instead (read-only: decode the PNGs and print measurements, no files written). First, the marker CSS and color tokens.
PIL is available. Now pixel-level analysis of the three `-m` shots (read-only, prints only): locate orange (#f5a847) and faint-gray (#5a6173) text clusters above the node, and render 1:1 ASCII crops so I can "read" the markers.
`differs-m.png` and `differs-l.png` are byte-identical — noted. My color classifier was too loose (none-m can't have 1508 orange marker pixels). Let me census actual colors and map where they sit.
Orange dominates none-m/differs-m (framework-lane node stroke) — so I must locate the node box first, then examine the strip *above* it. Detailed analysis:
Too slow — switching to numpy with projections:
Now I can see the structure. Let me ASCII-render the actual marker glyphs to read their text, check the edge-label proximity on missing-m, and verify the s/m/l ladder:
I can now literally read both markers from the pixels. One last check: why differs-m == differs-l byte-identically (label fit ladder?) — check the fixture's frw_2_enter and where none-m vs none-l actually differ:
All evidence is in. The pixel forensics match the source exactly (src/aef-workflow-designer.html:4587-4590 ladder `['⚠ no authority','⚠ no auth','⚠']` and `['◆ '+ab,'◆']`; CSS :717-718 faint-normal vs orange-600). Printing my verdict.

**How I evaluated (method disclosure):** this model cannot view images in this environment and this run is read-only, so I did not re-run the Chromium driver (step 1 writes PNGs and spawns Chrome + an HTTP server). Instead I inspected the nine committed PNGs at `docs/reports/t893-shots/` in the fingerprinted export directly — the exact artifacts step 2 asks to open — by decoding them pixel-by-pixel (color-class maps, 1:1 ASCII glyph rendering, cluster bounding boxes, WCAG contrast), cross-checked against the marker source and CSS.

1. [AC] The two markers read as different kinds of thing, and the common case is silent
VERDICT: green
WHY: Verified on the committed `docs/reports/t893-shots/{none,differs,missing}-m.png` (316px-wide element crops of the task-lifecycle fixture) by pixel decode: **none-m** — above the node fill (rows 58-181) there is nothing but the node's own 3px border stroke; no marker of any color (common case silent). **differs-m** — a faint-gray (#5a6173) text cluster at rows 59-71, x 53-99 above the box's top-left, with the "◆" diamond and 3-4 mono glyphs readable in the pixel map ("◆ ini"; source line 4587 `['◆ ' + ab, '◆']`); normal weight, measured contrast 3.10:1 on the background — the same faint/mono/8px class the app uses for id badges, i.e. it reads as an annotation, not an alarm. **missing-m** — an orange (#f5a847) bold (CSS :718 `font-weight:600`) text cluster at rows 61-71, x 73-136, glyphs legible as "⚠ no auth" (ladder `['⚠ no authority','⚠ no auth','⚠']`, line 4590; "⚠ no authority" ≈67px would run past top-centre ≈x157 — marker ends at x136, exactly the longest-fitting form per T-1069); contrast 9.66:1 — 3× the differs marker, and #f5a847 is the theme's WARN/defect token (finding badges/pills :756-768, io-finding :1263, tone-warn :824), so it reads as a defect. Full text is the `<title>` (hover), per :4587/:4589. Position: ~6px clear above the node border; the incoming edge's label block (rows 30-39, x 148-312) sits above-right and disjoint — close but no collision in the -m shot, matching the task's own flag. The subtle/loud pitch is right: an unweighted near-whisper for a mere override vs the app's established alarm color at 3× contrast for a real hole. Side observations: `differs-m.png` and `differs-l.png` are byte-identical (md5 395195fb…) — legitimate under the label fit ladder ("Enter issues (auto → healing diagnose)" fits at the same step at m and l, while none-m/none-l differ in the label region), and it does not affect the -m judgment.
GUIDANCE: none
Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
