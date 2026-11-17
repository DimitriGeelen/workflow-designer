# T-893 Human AC#1 — evidence report (judge-t-893-r5-claude-code-ba1535a7d22a, seat claude-code, rung-5-panel)

Revision reviewed: 7c61a110a657ceb8e5d109ca30e85d86be26348b

## What I ran

The criterion's step 1 writes into `docs/reports/t893-shots/`, which I may not touch. I therefore exported
the reviewed revision (`git archive 7c61a110a tools src examples/aef-processes/rendered/task-lifecycle.bpmn`)
into a temp directory and ran `node tools/_t893-authority-marker-shots.mjs` there (same script, same
source, isolated headless Chromium). Result: exit 0.

- L1 PASS marker counts per size s/m/l: differs=1, missing=3, nodes=15 (3 agent-lane nodes MISSING, frw_2_enter DIFFERS)
- L2 PASS buildBpmnXml before == after rendering markers (22736 bytes)
- L3 PASS 9/9 shots show their node
- L4 PASS control: the guard refuses the node under the properties panel
- 9 PNGs written. My fresh `none-m`, `differs-m`, `missing-m` are byte-identical (sha256) to the
  committed ones in `docs/reports/t893-shots/` (c2a23a18…, bf99de4f…, da609fb3… for differs/missing/none).

## What I saw (I opened the PNGs myself, at 1x and at 3x)

Cited copies: `none-m-judge-t-893-r5-claude-code-ba1535a7d22a.png`, `differs-m-judge-t-893-r5-claude-code-ba1535a7d22a.png`, `missing-m-judge-t-893-r5-claude-code-ba1535a7d22a.png`,
`side-m-x3-judge-t-893-r5-claude-code-ba1535a7d22a.png` (the three side by side, 3x), `sizes-s-l-x2-judge-t-893-r5-claude-code-ba1535a7d22a.png` (differs/missing at S and L, 2x).

- **none-m**: "Start work" node, no marker of any kind above it. The common case is silent. Met.
- **differs-m**: a small mono "◆ ini" above the node's top-left corner in a dim grey-blue, markedly dimmer
  than the node's own id label and far dimmer than its orange border and white title. It reads as a
  footnote-style annotation; nothing about it suggests an error. Met.
- **missing-m**: "⚠ no auth" in orange (sampled text pixel 245,168,61), semibold mono, above the top-left corner.
  It is the brightest non-title text in the crop and carries a warning glyph; it reads as a defect. Met.
  This is the middle form the criterion names (T-1069).
- **Kind, not just degree**: the two differ in three channels at once: glyph (◆ vs ⚠), colour (dim grey vs
  saturated orange) and weight (regular vs 600). At S and L label sizes the markers are unchanged
  (fixed 8px), so the contrast holds at all three sizes.
- **Hover**: source at the reviewed revision (src/aef-workflow-designer.html ~4581-4590) appends an SVG
  `<title>` with the full text ("no authority — this element has none and its lane offers no default";
  "authority: <v> (differs from the lane default)") and the fit ladder
  `['⚠ no authority', '⚠ no auth', '⚠']`. Confirmed in code; hover itself is not visible in a still shot.
- **Collision** (the criterion's "If not" probe): in missing-m the marker text ends at x≈137 and the
  incoming top-centre edge/arrowhead starts at x≈147, so about 10px of clear space; no edge label sits on
  or above the marker in this shot. No collision on task-lifecycle.

## Judgment

The subtle/loud pitch is right: the annotation is quiet enough not to compete with node titles, the
defect is loud enough to be found in a scan without being red-alarm (it is a hole in the map, not a
runtime failure, so orange rather than red is apt).

Two observations that do not change the verdict:
1. The missing marker's orange is the same hue as the framework-lane node border. On a framework-lane
   node with a missing authority the marker would share the border colour; the ⚠ glyph and the weight
   still set it apart. The fixture only shows missing on a blue (agent-lane) node, so this pairing is
   not in the nine shots.
2. The ⚠ glyph itself renders thin/dim at 1x beside the bold "no auth" text; the word carries the signal.

Limit of this review: the "your maps" part of the collision question was checked on the script's
task-lifecycle fixture only.

Verdict: green.
