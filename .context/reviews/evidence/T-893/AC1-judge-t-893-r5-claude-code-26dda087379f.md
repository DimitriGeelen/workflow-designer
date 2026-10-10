# T-893 Human AC#1 — reviewer judge-t-893-r5-claude-code-26dda087379f (panel seat claude-code, rung-5-panel)

**Revision reviewed:** 281a7807ba173f63d1a872a460a451bb9871b293
**Panel status:** DEGRADED — single-vendor panel. This verdict is recorded and reported, but it cannot satisfy the multi-vendor requirement; the criterion stays open.

## What I did
1. Ran `node tools/_t893-authority-marker-shots.mjs` at 2026-10-10 02:35 CEST. Output: L1 PASS (per size: 1 differs, 3 missing, 15 nodes), L2 PASS (buildBpmnXml unchanged by rendering, 22668 bytes), 9 PNGs written. The regenerated PNGs are byte-identical to the committed ones (`git status` clean for docs/reports/t893-shots/).
2. Viewed none-m, differs-m, missing-m at 1x and upscaled 4x (nearest-neighbour); also checked missing-s/l and differs-s/l.
3. Read the marker CSS/render code in src/aef-workflow-designer.html (~L647-648, ~L3870-3892) to confirm the hover <title> and colour tokens.

Copies cited: AC1-judge-t-893-r5-claude-code-26dda087379f-none-m.png, AC1-judge-t-893-r5-claude-code-26dda087379f-differs-m.png, AC1-judge-t-893-r5-claude-code-26dda087379f-missing-m.png

## Findings
- **none-m:** "Start work" has no marker. The common case is silent. ✔
- **differs-m:** "◆ ini" in 8px mono, `--text-faint` (#5a6173), regular weight, above the top-left of the node. It has the same visual weight as the id badge ("frw_4_enter") below the node, so it reads as an annotation, not an alarm. ✔
- **missing-m:** "⚠ no auth" in 8px mono, `--orange` (#f5a847), weight 600, same position. It is clearly louder than the differs marker (warm saturated colour plus bold, against faint grey), so it reads as a defect or attention item. The short form follows T-1069 (the longest form that fits left of top-centre). The full text "no authority — this element has none and its lane offers no default" is a <title> on a hit-testable element (no pointer-events:none). ✔
- **Contrast between the two:** right. They share a position and a type size, so they read as the same family of thing, and they are told apart by colour and weight. The subtle/loud pitch matches "choice vs hole". Neither is mis-pitched.
- **Collision:** on task-lifecycle (missing-m) the edge label "(issues → started-work)" sits about 30px above the marker, in the lane above. It does not collide. The top-entering arrowhead lands about 4–5px to the right of the end of "no auth", so it is close but does not overlap; this is the T-1069 clearance working. On differs-m nothing is near the marker.

## Non-blocking observations (taste, for the operator if wanted)
- At 8px the ⚠ glyph renders about 3px tall and reads more like a small triangle than a warning sign. The word "no auth" in orange carries the meaning on its own.
- `--orange` is also the border colour of the framework-lane node (see the "Enter issues" frame in differs-m) and the external-authority label colour. So orange is not used only for alarms; weight and the ⚠ separate the marker from those uses. This is acceptable but worth knowing.

## Verdict
green: the subtle/loud contrast is right, the common case is silent, and the marker does not collide with edge labels in the shots.
