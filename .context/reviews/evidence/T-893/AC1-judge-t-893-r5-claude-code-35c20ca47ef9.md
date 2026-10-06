# T-893 AC1 — reviewer judge-t-893-r5-claude-code-35c20ca47ef9 (rung-5-panel:claude-code)

Revision reviewed: 9670520cb385081f5d76f3385a43d6d9643d45cc

## What I did
- Ran `tools/_t893-authority-marker-shots.mjs` via a temp copy whose only change was `OUT` -> a /tmp dir
  (so I did not overwrite the tracked PNGs). Output: `L1 PASS` (per size: differs 1, missing 3, nodes 15),
  `L2 PASS` (buildBpmnXml unchanged, 23321 bytes), 9 screenshots, rc=0.
- `cmp` of my differs-m / missing-m / none-m against the committed `docs/reports/t893-shots/` copies: byte-identical.
- Viewed all three -m shots at 1x and 4x (nearest-neighbour), plus missing-s / missing-l, and a crop of the missing marker.
- Read the render code: `src/aef-workflow-designer.html:638-639` (classes) and `:3786-3790` (both markers at
  `x: n.x + 2, y: n.y - 3`, 8px mono; missing is `--orange`, weight 600, text "⚠ no authority").

## Findings
1. **Common case silent — met.** `AC1-judge-t-893-r5-claude-code-35c20ca47ef9-none-m.png`: frw_3_start shows only its type icon, the "1-8" id badge and
   the "frw_3_start" caption. No marker.
2. **Differs reads as an annotation — met.** `AC1-judge-t-893-r5-claude-code-35c20ca47ef9-differs-m.png`: faint grey mono "◆ ini" above the top-left
   corner of frw_4_enter, same visual weight as the id caption. It does not read as an alarm.
3. **Missing reads as a defect — met, a different KIND from differs.** `AC1-judge-t-893-r5-claude-code-35c20ca47ef9-missing-m.png`: orange, bold mono
   "⚠ no authority". Hue, weight and wording all set it apart from the faint ◆ badge. The subtle/loud contrast is pitched
   correctly. Minor points: at 8px the ⚠ glyph renders as a small smudge, so the word carries the signal. Orange is also
   the stroke colour of the framework-lane nodes (see none-m / differs-m borders), so a "missing" marker on an
   orange-bordered node would be weaker than it is here on the blue agent-lane node.
4. **Position COLLIDES — not met as reported.** The task's Visual Verification says the incoming edge label is "close
   but not overlapping". That is true of the *label* ("resume after healing…"). It is not true of the *edge itself*:
   the incoming sequence flow drops vertically onto the node's top-centre, and its line and arrowhead pass through the
   marker text, covering the "r" of "authority". See `AC1-judge-t-893-r5-claude-code-35c20ca47ef9-missing-m-marker-zoom.png`, and the same overlap in
   `AC1-judge-t-893-r5-claude-code-35c20ca47ef9-missing-s.png` and `AC1-judge-t-893-r5-claude-code-35c20ca47ef9-missing-l.png` (marker is 8px at every size, so all three sizes collide).
   The cause is structural, not specific to this fixture: "⚠ no authority" is about 14 mono chars × ~4.8px ≈ 67px,
   starting at n.x+2. It therefore spans the top-centre of a standard task, which is where top-entering flows land.
   The lane separator also runs just above the marker. The short differs badge ("◆ ini", ~25px) stays clear of
   top-centre here, but a long un-abbreviated authority value would hit the same collision.

## Verdict: amber
The pitch (the taste judgment the AC asks for) is right: two different kinds of thing, and the common case is silent.
The marker's position, though, collides with incoming top-centre edges on the loud marker at all three sizes, and the
task's own reading under-reported it.
