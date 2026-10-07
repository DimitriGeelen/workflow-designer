# T-893 Human AC#1 — independent review (rung-5-panel:claude-code)

Dispatch: judge-t-893-r5-claude-code-12b7bd803929 · revision reviewed: b0e8abe2782a4d5034ae40a2da6b25940b44f22b (HEAD at review time)

## What I did
1. Ran `node tools/_t893-authority-marker-shots.mjs` myself. Output: `L1 PASS` (per size: differs=1, missing=3, nodes=15 at s/m/l)
   and `L2 PASS` (buildBpmnXml 23321 bytes before == after rendering markers), 9 PNGs written.
2. Read none-m, differs-m, missing-m side by side, plus missing-l, differs-l, missing-s. Upscaled differs-m and missing-m 4x (nearest-neighbour) to check spacing.
3. Read the marker CSS, `src/aef-workflow-designer.html:647-648`, and the render call sites at :3800-3814:
   - `.node-authority-badge`: fill `--text-faint` (#5a6173), mono 8px, normal weight
   - `.node-authority-missing`: fill `--orange` (#f5a847), mono 8px, weight 600
   - full-text `<title>` on both, `cursor: help`
4. Checked where else `--orange` is used. It is the app's existing WARN colour: finding badge and pill WARN (:680/:682), finding-row WARN (:720), and `.aef-annotation.tone-warn` (:735-736). So the missing marker uses the same visual language as the rest of the app.

## Findings
- **Common case is silent:** none-m (`none-m-judge-t-893-r5-claude-code-12b7bd803929.png`) has no marker. The node shows only its label, the I/O badge "1→0" and the id badge.
- **Differs reads as an annotation:** "◆ ini" is low-contrast grey mono, the same visual weight as the id badge below the node (`differs-m-4x-…png`).
  It is easy to miss unless you look for it, which is right for "a deliberate choice that differs from the lane default".
- **Missing reads as a defect:** "⚠ no auth" is orange, bold and mono (`missing-m-4x-…png`). It is clearly louder than "◆ ini" and has the same hue as WARN findings.
  So the two markers read as different kinds of thing: one is metadata, the other is a warning.
- **Position and collisions:** the edge label "resume after healing (issues → started-work)" sits about 40 px (at 1x) above the marker, with the lane separator between them, so they do not collide.
  The text ends left of the top-centre arrowhead, so it no longer crosses the incoming flow (the earlier AMBER is resolved).
  The lane separator runs about 2-3 px above the marker text. It is tight but does not overlap.

## Minor notes (non-blocking; taste)
- At 8px the "⚠" glyph is barely recognisable as a warning triangle. The orange colour and the words "no auth" carry the signal. If the bare "⚠" fallback is the only form that fits, the signal rests on colour alone.
- `--orange` is also the stroke colour for scriptTask and gateway shapes (:3663, :3676). The marker is text, not a stroke, so I don't expect confusion. Worth noting if the palette is revisited.

## Verdict: green
The subtle/loud split is pitched right. Neither marker is mis-pitched, and I saw no collision with edge labels on the task-lifecycle fixture.
