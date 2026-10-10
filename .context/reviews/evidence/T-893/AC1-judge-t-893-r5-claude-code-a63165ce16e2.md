# T-893 Human AC#1 — independent review (rung-5-panel:claude-code)

Revision: 57c78a35b8375733c80c760295a36c5c340be47a. I did not read other reviewers' evidence files.

## What I ran
- `node tools/_t893-authority-marker-shots.mjs`, which output:
  - L1 PASS: per size s/m/l there are 15 nodes, 1 `differs` and 3 `missing`
  - L2 PASS: `buildBpmnXml` gives the same output before and after the markers are drawn (22668 bytes)
  - It wrote 9 PNGs. `git status` shows they are byte-identical to the committed shots.
- I put none/differs/missing (m) side by side at 4x, and missing/differs across s/m/l at 3x:
  - `AC1-judge-t-893-r5-claude-code-a63165ce16e2-side-by-side-m-x4.png`
  - `AC1-judge-t-893-r5-claude-code-a63165ce16e2-sizes-x3.png`
- I read the render code at `src/aef-workflow-designer.html:3861-3891` and the CSS at `:640-648`.

## Findings
- **none-m:** no marker above "Start work". The common case is silent. ✔
- **differs-m:** "◆ ini" above the top-left of the node, in `--text-faint` 8px mono, same weight as the id labels (`frw_4_enter`). It reads as metadata, not an alarm. ✔
- **missing-m:** "⚠ no auth" in `--orange` 8px mono, weight 600. On the blue agent-lane node it is the only warm, bold text in the area and reads as a defect flag. ✔
- **The two read as different kinds.** They differ in colour (faint grey vs orange), weight (400 vs 600), glyph (◆ vs ⚠) and wording (a value vs a statement of absence). ✔
- **Same across sizes:** s/m/l all keep the same form ("no auth"; "ini"). Nothing is clipped.
- **Hover text:** each marker gets a `<title>` with the full text, e.g. "no authority — this element has none and its lane offers no default". The CSS leaves the marker hit-testable (`cursor: help`, no `pointer-events:none`). I checked the code but did not hover in a browser.
- **Collision check (the "If not" clause):**
  - On task-lifecycle the edge label "(issues → started-work)" is about 25px above the marker, in the lane above, with a lane border between them. They do not overlap.
  - The incoming top-centre arrow ends a few px to the right of "auth". Close, but not crossing, which is what T-1069 required.
  - On differs-m the bottom edge label "blocked / failing" is below the node, nowhere near the marker.

## Pitch judgement
The subtle/loud contrast is pitched right: annotation vs defect, and silent by default. Neither marker is too loud or too quiet.

## Notes (do not block)
1. At 8px the ⚠ glyph is barely recognisable; it renders as a small "⊥". The defect cue comes from the orange colour plus the words "no auth". It would be stronger if the glyph were slightly larger than the text.
2. `--orange` (#f5a847) is the same hue as the border of framework-lane nodes. In this fixture every `missing` node is in the agent lane (blue border), so the warning stands out. On an orange-bordered node it would contrast less.
3. The gap to the top-centre arrowhead is tight, a few px at m. It is acceptable.
