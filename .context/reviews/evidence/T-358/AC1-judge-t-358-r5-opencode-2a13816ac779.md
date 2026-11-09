# Reviewer evidence — T-358 AC#1

- dispatch: `judge-t-358-r5-opencode-2a13816ac779`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `76ee72d11c5e84ce48a4851337623364eda03695`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `3f08d146ac788ba4dbfeed21573dd616b408b2ca6b26d7fe792cdff2bdcbd3a9`
- result.md sha256: `3bcbf4d52a248a3838300a5708b04adf2ef6d92bfad5ead68be786b021e2de2c`

## The worker's verdict block

```
1. [AC] A map that declares no lanes reads correctly without the lanes the importer used to invent
VERDICT: amber
WHY: Verified at 1440 and 1920 for all 7 maps (14 of 21 shots) by pixel analysis validated against the v0.40.0 control: each map draws one pool (top border + ~30px #1d2230 header band + bottom border, e.g. simple-1440 L249 R1118 top224 btm528; nested-1440 top260 btm664) with zero internal lane-divider lines (control shows two: y391, y521) and no lane-header strip (solid-fill in the 60px left strip 0.004–0.009 vs 0.869 in v0.40.0); a surface strip with centered text sits 8–9px below the pool bottom in every map (e.g. nested-1440 rows 673–696), matching the source's + Add a lane strip (src/aef-workflow-designer.html:4130 renders '+ Add a lane' when lanesArr is empty, and poolHeight() at :2947 sizes the pool bottom to the lowest node + 50px); no element pixels above the pool top or below that strip (only the canvas zoom cluster/scrollbar chrome at the canvas edges); the accent-bordered advisory dock card sits fully inside the canvas above the pool (e.g. 232,155–1107,221 within canvas 220–1119) so its controls are reachable; collaboration-message-flows at 1440/1920 shows the second pool below ours without overlap (pool1 btm 438/393 < pool2 top-border content 477/432). The T-1386 left-edge issue was excluded per the narrowed scope (vertical extent only). NOT verified: the 7 shots at 1024 plus boundary-events-1024-bottom.png — my analysis script's y-range crashed on the 768px-tall images and the run's time limit expired before the fix could be re-run; also the strip's literal text could not be OCR'd at any width (too small/dim) — the strip is confirmed by geometry and source only.
GUIDANCE: One more pass at 1024 only: run the same pixel checks on the seven *-1024.png shots (and the scrolled-bottom capture) — pool top/bottom encloses all element rows, no internal long line between header band and bottom, no solid #161922 left strip, add-strip below pool bottom, card inside canvas, second pool below without overlap for collaboration-message-flows-1024. If they match the 1440/1920 behaviour (expected, since 1440/1920 differ only by scale here), this is green.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
All 22 evidence images are present (7 maps × 3 widths, plus the scrolled-bottom capture and the v0.40.0 comparison). Now I'll view them, batching reads.
My model seat cannot view images directly (the tool rejects image input for this model). Before declaring not-evaluated, I'll try programmatic pixel analysis in scratch space — the checks are geometric (pool enclosure, lane bands, header strips), which can be verified from pixels, and the v0.40.0 comparison shot gives me a positive control for what an invented lane looks like.
Python with PIL, numpy and tesseract OCR are all available. Let me recon the source (to know what UI strings like "+ Add a lane" and the advisory card are) and calibrate pixel analysis on the v0.40.0 shot with the known lane label.
The app is a single-file SVG renderer. Let me read the pool/lane rendering code to know exactly what geometry to verify.
The source gives exact geometry: pool border #3a4257 (1.5px), pool header #1d2230 (32px), lane header strips #161922 (60px wide) with uppercase #80869a labels, lane dividers #2a3142 spanning the pool, "+ Add a lane" dashed strip 24px tall starting 8px below the pool bottom, accent #c4ee54 advisory card border. Now I'll write a pixel+OCR analysis script in scratch space and validate it against the v0.40.0 shot (positive lane control).
Write tool is blocked (plan-mode read-only outside my scratch). The review brief explicitly sanctions `$TMPDIR` scratch, so I'll run the analysis inline via bash heredoc, writing temp files only under `$TMPDIR` and leaving the export untouched.
Only two long lines found — the pool border may be anti-aliased at subpixel scale or cropped. Let me probe actual pixel structure directly.
v0.40.0 calibration: pool top ≈ y229 with a #1d2230 pool-header band y231–262 (scale ≈1.0), possible lane divider ≈ y391, pool bottom candidate ≈ y521 — and its pool border uses plain --border (older CSS). Now probing the new render the same way.
v0.40.0 shows a mid-pool divider row (y≈391) between pool top (229) and bottom (521) — exactly the invented-lane signature. The new renders (nested-subprocesses, simple) show **no** internal line between top and bottom. Now the full verification script over all 22 images, with the v0.40.0 shot as the must-fail control.
Pool-top/bottom line pairing bug (each long line became its own "pool"). Fixing: a line with a #1d2230 header band beneath it is a pool top; otherwise a bottom.
Pool geometry logic needs hardening (line extents from longest run, header-band-anchored pools, card detection). Probing two problem regions first: rows above pool-top and rows below the strip in nested-1440.
Layout decoded at 1440: palette < x211, scrollbar 211–219, canvas ≈ x221–1130, right panel x≥1137; advisory dock card y155–221 (accent-bordered rows) sits above pool top 259 — pool spans x279–1120. Now the critical probe: with the correct x-range, is there any diagram content between pool bottom (664) and the canvas floor?
Control validated: v0.40.0 has a lane divider at y391 (visible x677–1120, hidden under the subprocess box) plus vertical lane-label glyphs at x~253–288 in a 56px left strip, and content hanging below its pool bottom (521) — while the new nested render has no internal line, a "+ Add a lane" strip at 673–696 with centered text, and only the zoom cluster below. Now the full sweep over all 22 images:
Mostly clean: no internal lane lines in any new render, strips below pools, cards in-canvas, nothing above pools; the `below` hits are the canvas scrollbar/zoom UI at the edges (x>cr−20) — and v0.40.0 control correctly shows divider lines + 2643 lane-strip glyphs. Two gaps: 1024 shots crash (H=768 vs my y-range) and collaboration finds no pool. Fixing both plus a solid-fill lane-strip test and an OCR retry on the strip text:
Decisive discriminator: lane-strip solid fill = **0.869 (v0.40.0) vs 0.004–0.009 (all new renders)**. Remaining: 1024 crash (a leftover `min(880,…)` bound) and collaboration's pool bottoms. Fixing and running the last sweep:
Time is nearly exhausted — printing the verdict with what was verified and what was not.

**Verification summary (method disclosure):** my model seat cannot view images (the read tool rejects image input), so I verified via programmatic pixel-geometry analysis + OCR in scratch space, calibrated against the shipped v0.40.0 control shot (`v0.40.0-nested-subprocesses-1440.png`), which my detector correctly reads as having invented lanes: an internal lane-divider line at y391 (x677–1120, hidden under the subprocess box on the left), vertical lane-label glyphs in a solid #161922 left strip (solid-fill 0.869), and diagram content hanging below its pool bottom. Every new render behaves oppositely.

1. [AC] A map that declares no lanes reads correctly without the lanes the importer used to invent
VERDICT: amber
WHY: Verified at 1440 and 1920 for all 7 maps (14 of 21 shots) by pixel analysis validated against the v0.40.0 control: each map draws one pool (top border + ~30px #1d2230 header band + bottom border, e.g. simple-1440 L249 R1118 top224 btm528; nested-1440 top260 btm664) with **zero** internal lane-divider lines (control shows two: y391, y521) and **no lane-header strip** (solid-fill in the 60px left strip 0.004–0.009 vs 0.869 in v0.40.0); a surface strip with centered text sits 8–9px below the pool bottom in every map (e.g. nested-1440 rows 673–696), matching the source's `+ Add a lane` strip (src/aef-workflow-designer.html:4130 renders '+ Add a lane' when `lanesArr` is empty, and poolHeight() at :2947 sizes the pool bottom to the lowest node + 50px); no element pixels above the pool top or below that strip (only the canvas zoom cluster/scrollbar chrome at the canvas edges); the accent-bordered advisory dock card sits fully inside the canvas above the pool (e.g. 232,155–1107,221 within canvas 220–1119) so its controls are reachable; collaboration-message-flows at 1440/1920 shows the second pool below ours without overlap (pool1 btm 438/393 < pool2 top-border content 477/432). The T-1386 left-edge issue was excluded per the narrowed scope (vertical extent only). NOT verified: the 7 shots at 1024 plus `boundary-events-1024-bottom.png` — my analysis script's y-range crashed on the 768px-tall images and the run's time limit expired before the fix could be re-run; also the strip's literal text could not be OCR'd at any width (too small/dim) — the strip is confirmed by geometry and source only.
GUIDANCE: One more pass at 1024 only: run the same pixel checks on the seven *-1024.png shots (and the scrolled-bottom capture) — pool top/bottom encloses all element rows, no internal long line between header band and bottom, no solid #161922 left strip, add-strip below pool bottom, card inside canvas, second pool below without overlap for collaboration-message-flows-1024. If they match the 1440/1920 behaviour (expected, since 1440/1920 differ only by scale here), this is green.

Summary: 0 green, 1 amber, 0 red, 0 escalate, 0 not-evaluated
```
