# T-893 AC1 — reviewer judge-t-893-r5-claude-code-6002883f4d71 (rung-5-panel:claude-code)

Revision reviewed: e035d9c9e0496c65f4f76f0f270f41de28c64713

## What I did
- Ran `node tools/_t893-authority-marker-shots.mjs` exactly as the AC says. Output: L1 PASS (per size: 15 nodes, 1 differs, 3 missing), L2 PASS (buildBpmnXml is byte-identical before and after rendering, 23321 bytes), 9 PNGs.
- `git status docs/reports/t893-shots` afterwards was clean, so my regenerated shots are byte-identical to the committed ones.
- Opened differs-m, missing-m and none-m side by side, then made nearest-neighbour zooms (x4 and x6) to check the marker and edge geometry.
- I formed this verdict on my own. I did not use another reviewer's evidence file that was already in this directory.

## Findings
1. **The common case is silent: met.** `AC1-judge-t-893-r5-claude-code-6002883f4d71-none-m.png`: frw_3_start shows only its type icon, its "1-8" id badge and the lane-id caption. There is no authority marker.
2. **Differs reads as an annotation: met.** `AC1-judge-t-893-r5-claude-code-6002883f4d71-differs-m.png` / `-differs-m-zoom.png`: a small, low-contrast grey mono "◆ ini" sits above the top-left corner of frw_4_enter. It is quieter than the node title and the id caption. It reads as metadata, not a warning. Pitch is right.
3. **Missing reads as a defect, and as a different KIND: met.** `AC1-judge-t-893-r5-claude-code-6002883f4d71-missing-m.png`: an orange/amber "⚠ no authority" in the same slot. It differs from the differs marker in hue (warm vs neutral grey), glyph (⚠ vs ◆) and wording (a statement of absence vs a value). It is the only warm text near the node, so it catches the eye. It is not oversized and does not compete with the node title. Pitch is right: loud enough, not alarming beyond a lint-style defect.
4. **Position collision: NOT met.** `AC1-judge-t-893-r5-claude-code-6002883f4d71-missing-m-marker-zoom.png` (x6 crop): on task-lifecycle, the incoming edge to agt_2_perform comes down vertically into the top of the node. Its line and arrowhead pass straight through the marker text, over the "ori" of "authority". The edge *label* above ("resume after healing (issues → started-work)") is clear of the marker, about 30px above it, so the label is not the problem. The edge line and arrowhead are. The same overlap appears in `AC1-judge-t-893-r5-claude-code-6002883f4d71-missing-s.png` and `AC1-judge-t-893-r5-claude-code-6002883f4d71-missing-l.png`. The marker text does not scale with the size mode, so changing the size mode does not fix it.
   On this map the differs marker ("◆ ini") is short enough to finish before the incoming arrow at frw_4_enter, which enters from below. But any top-entering edge near the left third of a node would hit it as well.
5. Side note, not blocking: differs-m.png and differs-l.png are byte-identical. For that node the m/l size modes render the same, so the "nine distinct shots" are really eight distinct images.

## Verdict: amber
The subtle/loud contrast is pitched right. The position (top-left, above the shape) collides with incoming top-entering edges and arrowheads. The marker is the defect signal, and it is partly overwritten exactly where an edge lands.

## Needed
Keep the styling. Move the marker so top-entering edges cannot cross it. Any of these works:
- (a) inside the shape's top-left padding;
- (b) left-aligned below the shape, next to the id caption;
- (c) give the text a background knock-out (canvas-coloured rect) and draw it above edges, so the edge passes behind it.

Then re-shoot missing-{s,m,l} on task-lifecycle and confirm that no edge pixels cross the text.
