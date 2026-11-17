# T-893 Human AC#1 — evidence report (panel seat claude-code, dispatch judge-t-893-r5-claude-code-0c43def05584)

Revision reviewed: eb0a943ff6de81c1b2b6bcd9a7efcdb9e2c3752c. Criterion digest: b2dc7cc4f233.

## Method
Judged the supplied images as given (docs/reports/t893-shots/, 9 PNGs present). Cannot reproduce:
the capture harness was not re-run, per the brief. Copies of what I read are in this directory:

- none-m-judge-t-893-r5-claude-code-0c43def05584.png, differs-m-judge-t-893-r5-claude-code-0c43def05584.png, missing-m-judge-t-893-r5-claude-code-0c43def05584.png (the three the criterion names)
- none-s / none-l / differs-s / differs-l / missing-s / missing-l -judge-t-893-r5-claude-code-0c43def05584.png (the other six, unmodified copies)
- differs-m-marker-6x-judge-t-893-r5-claude-code-0c43def05584.png, missing-m-marker-6x-judge-t-893-r5-claude-code-0c43def05584.png (6x crops of the marker area, made by me)
- grid-s-l-judge-t-893-r5-claude-code-0c43def05584.png (the six s and l shots side by side, made by me)

## What the images show
1. **none-m** — "Start work (captured -> started-work)": no marker above the node. Only the existing
   I/O badge (1→0), the type glyph and the id label. The common case is silent. Same at s and l (grid).
2. **differs-m** — "Enter issues": a grey monospace "◆ ini" above the top-left corner, in the same faint
   grey and weight as the id labels ("frw_…"). At 6x it is a small solid diamond plus three thin
   letters; nothing in it is coloured. It reads as an annotation of the node, not a warning.
3. **missing-m** — "Perform the work": an orange, bolder "⚠ no auth" above the top-left corner. It is
   the only orange text in the shot and sits on a blue-bordered node, so it stands out as a defect.
   At 6x the text ends about 9 px (real) left of the incoming flow line and arrowhead at top-centre:
   no overlap. Same form and clearance at s and l (grid).
4. **Kind, not degree** — the two markers differ in three ways at once: glyph (◆ vs ⚠), colour
   (faint grey vs orange) and weight (regular vs 600). They do not read as two levels of one scale.

## Not visible in an image, checked in source
"Full text on hover": src/aef-workflow-designer.html:4580-4590 appends a <title> to each marker
("no authority — this element has none and its lane offers no default"), and the forms list is
['⚠ no authority', '⚠ no auth', '⚠'] with the longest that fits chosen, as the criterion states.
I did not hover in a browser.

## Judgement on pitch
- "◆ ini" is not too quiet: legible at 1x at every size, and it has cursor: help plus a title.
- "⚠ no auth" is not too loud: 8 px text, no fill, no box, no animation; it does not compete with the
  node label. Minor: the ⚠ glyph itself is thin at 8 px and reads mostly through the orange word.
- Position: no collision with incoming flows in the supplied shots. A lane separator line runs about
  3 px above the missing marker; it does not touch it.

## Out-of-date remark in the criterion (does not change the verdict)
The "If not" clause says missing-m.png "shows an edge label sitting just above it on task-lifecycle".
The current missing-m.png shows no edge label above the marker, only the lane separator and the
incoming flow lines. The Expected clause is met exactly as written, so the verdict is green; the
remark could be dropped when the task is next edited.

## Verdict: green
