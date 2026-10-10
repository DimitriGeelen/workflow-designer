# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-opencode-46a01a20336c`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.2`)
- seat: `opencode`
- reviewed revision: `57c78a35b8375733c80c760295a36c5c340be47a`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `f76130ad70567ae7d2de6beae9f19dbb56580db073a99c510acc0179d31296f8`
- result.md sha256: `2e22873f786e8555827e1bd0b9a8eb448d13f8e3caa8a7c8f8d9e31c58c92c76`

## The worker's verdict block

```
1. [AC] The two markers read as different KINDS of thing, and the common case is silent
VERDICT: not-evaluated
WHY: This seat cannot view images — the Read tool returned "this model does not support image input" on all three PNGs, and the criterion's core is explicitly a taste judgment of rendered output ("whether the subtle/loud contrast is RIGHT, which is taste, not geometry"), which pixel statistics cannot substitute. What I could verify without sight, and pass to the sighted reviewer: (a) all 9 PNGs exist committed at the reviewed revision; (b) none-{s,m,l} contain zero marker ink above the node — the common case is pixel-silent; (c) differs-{s,m,l} show a faint gray-blue marker above the node (exact --text-faint #5a6173 pixels; ink ≈22 local px ≈ the full "◆ ini" form at zoom 42/110); (d) missing-{s,m,l} show an orange marker (exact --orange #f5a847 family, font-weight 600 vs badge's 400; ~65 core ink px vs ~14 for differs — objectively louder); (e) no marker/edge overlap at any size (marker ink ends x≤84, top-entering arrowhead at x≥86); (f) the lane separator runs just above both markers, as the task discloses. One discrepancy a sighted reviewer must resolve: at THIS revision the fit math (MARKER_CH=4.9 × 10 chars = 49 > avail = 110/2−9 = 46 on 110px task nodes, src/aef-workflow-designer.html:3876-3878) should draw bare "⚠", yet the committed missing-shots' measured ink (~44.5 local px) matches "⚠ no auth" — the committed PNGs may predate a change to the fit constants, so step 1 (regenerate) is essential, not optional.
GUIDANCE: Re-run node tools/_t893-authority-marker-shots.mjs (do not judge the committed PNGs alone), view differs-m / missing-m / none-m with working image input, and judge the annotation-vs-alarm contrast. Specifically confirm which form missing-m now renders: if the current code produces bare "⚠", decide whether a lone orange triangle still reads as a defect with the full text on hover, and whether the AC's Expected text ("⚠ no auth") or the MARKER_CH/avail constants need amending.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```

## The worker's full output (result.md)

```
The 9 PNGs already exist in the export. Let me read the shot script and the task's Visual Verification section to understand what I'm judging.
The 9 shots are committed in the revision. Now let me view the three key screenshots and corroborate with the marker code and the task's Visual Verification section.
Image input is unsupported in this seat — a critical constraint I must weigh honestly. Let me gather every non-visual corroboration I can (code, task notes, pixel statistics) before deciding the verdict.
The task file and code corroborate the described implementation. Since this seat cannot view images, let me extract what objective evidence the PNG bytes themselves can give (read-only pixel statistics) and read the marker styling code.
The naive classifier caught node fills too. Let me target the marker strip above the node top and use the actual token colors from the CSS.
Anti-aliasing is diluting token colors at 8px. Let me classify by hue and dump an ASCII rendering of the strip above the node top so the glyph pattern is inspectable as text.
none-m is silent above the node — good. But differs-m shows no glyph and missing-m's orange glyph isn't where I expect. Let me dump raw pixel values in the marker regions.
The `<g>` bbox includes the marker itself, so my node-top estimate was off. Let me histogram where the orange and faint glyph pixels actually sit in each shot.
Both markers exist at rows ~55-62. Now the critical question: WHAT text is actually drawn (the T-1069 "longest form that fits" logic) — let me measure glyph x-extents precisely.
The measured widths don't yet match any expected form ('◆' alone? '⚠ no auth'?). Let me ASCII-dump the marker bands at fine resolution to read the actual glyphs.
The glyphs are barely legible at 8px. Rather than guess, let me determine ground truth: which form does the fit-logic actually draw for these two nodes? First the node geometry (def.w) and fixture node kinds.
Node defaults are 110px wide, but the shots' bounding boxes are only 42px — the fixture DI must set custom sizes. Let me check the fixture's DI bounds and how `def` resolves node width.
The pixel widths match the FULL forms ('◆ ini' ≈ 24.5px, '⚠ no auth' ≈ 49px at zoom 42/110) — but the current code's fit math (avail = 110/2−9 = 46 < 49) should pick bare '⚠'. Let me check what `def` renderNodes actually uses, and whether node sizes get overridden.
The current code would draw bare `⚠` (49 > avail 46), but the committed shot's ink measures ~44.5px ≈ `⚠ no auth`. Let me check git history — were MARKER_CH/avail changed after the 2026-10-07 re-shot?
No git metadata in the export. Last forensic check: do the marker and the incoming edge/arrow overlap in the s and l shots (the AC's collision question)?
All evidence gathered. The forensics corroborate the design claims, but the AC's core is an explicitly taste-based judgment on rendered output, and this seat's image-viewing capability failed — I cannot honestly judge what I could not see.

---

1. [AC] The two markers read as different KINDS of thing, and the common case is silent
VERDICT: not-evaluated
WHY: This seat cannot view images — the Read tool returned "this model does not support image input" on all three PNGs, and the criterion's core is explicitly a taste judgment of rendered output ("whether the subtle/loud contrast is RIGHT, which is taste, not geometry"), which pixel statistics cannot substitute. What I could verify without sight, and pass to the sighted reviewer: (a) all 9 PNGs exist committed at the reviewed revision; (b) none-{s,m,l} contain zero marker ink above the node — the common case is pixel-silent; (c) differs-{s,m,l} show a faint gray-blue marker above the node (exact `--text-faint` #5a6173 pixels; ink ≈22 local px ≈ the full "◆ ini" form at zoom 42/110); (d) missing-{s,m,l} show an orange marker (exact `--orange` #f5a847 family, font-weight 600 vs badge's 400; ~65 core ink px vs ~14 for differs — objectively louder); (e) no marker/edge overlap at any size (marker ink ends x≤84, top-entering arrowhead at x≥86); (f) the lane separator runs just above both markers, as the task discloses. One discrepancy a sighted reviewer must resolve: at THIS revision the fit math (`MARKER_CH`=4.9 × 10 chars = 49 > avail = 110/2−9 = 46 on 110px task nodes, src/aef-workflow-designer.html:3876-3878) should draw bare "⚠", yet the committed missing-shots' measured ink (~44.5 local px) matches "⚠ no auth" — the committed PNGs may predate a change to the fit constants, so step 1 (regenerate) is essential, not optional.
GUIDANCE: Re-run `node tools/_t893-authority-marker-shots.mjs` (do not judge the committed PNGs alone), view differs-m / missing-m / none-m with working image input, and judge the annotation-vs-alarm contrast. Specifically confirm which form missing-m now renders: if the current code produces bare "⚠", decide whether a lone orange triangle still reads as a defect with the full text on hover, and whether the AC's Expected text ("⚠ no auth") or the MARKER_CH/avail constants need amending.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```
