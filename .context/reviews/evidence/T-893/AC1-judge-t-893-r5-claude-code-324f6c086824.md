# T-893 Human AC#1 — independent review (rung-5-panel:claude-code, dispatch judge-t-893-r5-claude-code-324f6c086824)

Revision reviewed: 872816fcb9ccaef69a227ab9c76a752248063f56 (HEAD at review time).

## What I did
1. Ran `node tools/_t893-authority-marker-shots.mjs` — L1 PASS (s/m/l each: differs=1, missing=3 of 15 nodes), L2 PASS (buildBpmnXml identical before/after, 23321 bytes); 9 PNGs written.
2. Read none-m, differs-m, missing-m side by side, plus missing-s / missing-l / differs-l (upscaled 3x nearest-neighbour for legibility). Copies cited here:
   none-m-judge-t-893-r5-claude-code-324f6c086824.png, differs-m-judge-t-893-r5-claude-code-324f6c086824.png, missing-m-judge-t-893-r5-claude-code-324f6c086824.png, missing-s-judge-t-893-r5-claude-code-324f6c086824.png, missing-l-judge-t-893-r5-claude-code-324f6c086824.png
3. Read the render code (src/aef-workflow-designer.html ~3786-3812) and CSS (lines 643-644).

## Findings
- **Common case silent — met.** none-m: no marker; only the I/O badge (1→0) and id badge, as before.
- **Two different KINDS — met.** differs-m: "◆ ini" in --text-faint, 8px mono, regular weight — same visual register as the id badge; reads as an annotation. missing-m: "⚠ no auth" in --orange, weight 600 — clearly a warning. The contrast (neutral grey vs warm bold) is the right pitch; neither marker is mis-pitched. Unchanged across s/m/l (fixed 8px).
- **Position / edge labels — no collision.** At m (and s, l) the edge label "resume after healing (issues → started-work)" sits in the lane above, separated by the lane boundary; no overlap. Since T-1069 the marker stays left of top-centre: it ends ~4px before the incoming arrowhead — tight but clear.

## Discrepancies (why not green)
1. **The AC's Expected text and the task's ## Visual Verification record are stale.** Both say missing renders "⚠ no authority"; at this revision it renders "⚠ no auth" at every size (T-1069 fitMarker: ['⚠ no authority','⚠ no auth','⚠'], avail = def.w/2-9 rejects the 14-char form on a standard task). The record does not describe what is now rendered.
2. **The "full text on hover" promise does not hold.** The T-1069 comment says "the full text is always the <title>, so a short form loses nothing on hover", but both classes carry `pointer-events: none` (lines 643-644), so the <text> is never hit-tested and its <title> tooltip cannot show. Combined with the cryptic abbreviations ("ini", "aut", "sov", "ext" — AUTHORITY_ABBR line 1827), a reader has no in-place way to expand "◆ ini" or "⚠ no auth". This is a static finding from the CSS; I did not drive a hover.
3. Minor, taste: the --orange hue used for "missing" is also the stroke of some nodes (frw_4_enter in differs-m has an orange border), which slightly dilutes "orange = defect". Not blocking.

## Verdict: amber
The design judgment the AC asks for is met: the markers read as different kinds, the subtle/loud contrast is right, and the common case is silent. Before green: (a) update the AC Expected text and the ## Visual Verification table to "⚠ no auth" (and re-read the nine shots at the current revision); (b) either drop `pointer-events: none` from .node-authority-badge/.node-authority-missing (or put the <title> on a hit-testable element) so hover really shows the full text, or remove that claim from the code comment.
