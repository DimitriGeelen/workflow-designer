# T-893 Human AC#1 — evidence report (panel seat claude-code, dispatch judge-t-893-r5-claude-code-d76f8e843ecd)

Revision reviewed: c7822ac5108b9b55e2bf47bf562e959f2f9f34f0 (HEAD at review time; src/, tools/ and the fixture clean in the working tree).
Criterion digest: b2dc7cc4f233

## What I ran

Step 1 as written, with one deviation: I am read-only outside this directory, and the driver overwrites the
tracked PNGs in docs/reports/t893-shots/. So I ran the unmodified driver from a scratch copy
(/tmp/t893-rev-7zsdVV: tools/*.mjs copied, src/ and examples/ symlinked to the repo), which makes it write
its 9 PNGs there instead.

    L1 PASS  marker counts per size: s/m/l each differs=1, missing=3, nodes=15; agent-lane nodes=3
    L2 PASS  buildBpmnXml before == after rendering markers (22736 bytes)
    L3 PASS  every shot shows its node (elementFromPoint at the clip centre is inside it; T-1429): 9/9
    screenshots: 9      exit code 0

All 9 PNGs I produced are byte-identical (sha256) to the 9 committed in docs/reports/t893-shots/ at this
revision, so the committed shots are what the code renders. (differs-m and differs-l share one hash; the
grid shows the node text does grow from s to l, m and l simply wrap the same on this node.)

## What I saw (step 2: none-m, differs-m, missing-m side by side, all three opened and read)

- none-m (.context/reviews/evidence/T-893/none-m-judge-t-893-r5-claude-code-d76f8e843ecd.png): "Start work" node, I/O badge 1→0 and id badge only. No marker. Silent.
- differs-m (.context/reviews/evidence/T-893/differs-m-judge-t-893-r5-claude-code-d76f8e843ecd.png): small grey mono "◆ ini" above the top-left corner, on the dark canvas,
  clearly dimmer than the node label and dimmer than the id badge. Nothing about it signals a problem.
  6x zoom: .context/reviews/evidence/T-893/differs-m-marker-6x-judge-t-893-r5-claude-code-d76f8e843ecd.png.
- missing-m (.context/reviews/evidence/T-893/missing-m-judge-t-893-r5-claude-code-d76f8e843ecd.png): orange, bold mono "⚠ no auth" in the same position. It is the only
  saturated text near the node and reads as a warning at a glance.
  6x zoom: .context/reviews/evidence/T-893/missing-m-marker-6x-judge-t-893-r5-claude-code-d76f8e843ecd.png.
- s and l (.context/reviews/evidence/T-893/s-l-grid-judge-t-893-r5-claude-code-d76f8e843ecd.png, all six read): same result at both sizes; none silent, "◆ ini" faint,
  "⚠ no auth" orange.

## The judgment asked for: is the subtle/loud contrast right?

Yes.
- Different KINDS, not two volumes of one thing: the two differ in glyph (◆ vs ⚠), colour (neutral
  --text-faint #5a6173 vs --orange #f5a847), weight (normal vs 600) and wording (a value "ini" vs a
  statement "no auth"). A reader who has never seen the legend would still take the first as a tag and the
  second as a fault.
- Neither is mis-pitched. "◆ ini" is quiet but legible at the capture scale; "⚠ no auth" is loud without
  being a red error (orange, 8px, no box or halo), which fits a modelling gap rather than a runtime failure.
- Hover: each marker carries a <title> with the full text (src/aef-workflow-designer.html:4561, :4566-4569),
  so the short form loses nothing.

## Position / collisions (the "If not" clause)

- Measured on missing-m and missing-s pixels: the orange text ends at x=136, the incoming flow's line and
  arrowhead start at x=145 (image px at 2x), so there is a clear gap; nothing crosses the marker (6x zoom).
- No edge label sits above the marker in missing-m at this revision. The clause's remark that
  "missing-m.png shows an edge label sitting just above it" described an older render; it is a note in the
  fallback clause, not part of the Expected, so I did not treat it as an out-of-date literal to restate.
- The lane separator line runs about 8 image px above the marker. Visible, not touching.

## Observations that do not change the verdict

1. Legibility floor. The driver's shots are 2x device scale on a fit-zoomed canvas. At true 1x on the same
   fit zoom (.context/reviews/evidence/T-893/fit-zoom-1x-m-judge-t-893-r5-claude-code-d76f8e843ecd.png, my own extra capture, same driver with scale 1) "◆ ini" is barely
   readable while "⚠ no auth" still is. Everything on the node is small at that zoom, and the hover title
   covers it, so this is the right order of failure (the annotation fades first, the defect last).
   --text-faint is about 3:1 on the canvas background; if the operator ever finds the differs marker too
   quiet, --text-dim is the one-token fix.
2. Not shown by this fixture: the framework lane's node outline is the same orange family as the missing
   marker. All three "missing" nodes here are blue agent-lane nodes, where orange stands out. A missing
   marker on an orange-outlined node would have less colour separation (the ⚠ glyph and bold weight would
   still carry it). Worth a look if a framework-like lane ever loses its default.
3. The ⚠ glyph itself renders dimmer than the "no auth" text beside it (thin outlined triangle at 8px).
4. The task's Visual Verification prose names frw_4_enter as the differs node; the driver uses frw_2_enter.
   Prose drift in the task, outside this criterion.

## Verdict

green — every part of the Expected clause is met on shots I regenerated and read myself, and the
subtle/loud contrast is right.
