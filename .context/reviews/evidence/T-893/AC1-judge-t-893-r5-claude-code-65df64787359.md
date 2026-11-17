# T-893 Human AC#1 — evidence, seat claude-code (judge-t-893-r5-claude-code-65df64787359)

Revision reviewed: 365dc64d16f1c151528fe6708abb2d53dde5a81b (HEAD at the time; `src/aef-workflow-designer.html`,
the fixture base and `tools/_t893-authority-marker-shots.mjs` are clean in the working tree).

## What I ran

I am read-only outside this directory, and step 1 overwrites nine tracked PNGs in `docs/reports/t893-shots/`.
So I ran a byte-for-byte copy of `tools/_t893-authority-marker-shots.mjs` from /tmp with only two changes:
the three relative imports made absolute, and `OUT` pointed at a temp directory. Same Chromium, same
`--window-size=1400,900`, same fixture, same clips.

Result: exit 0, `L1 PASS` (differs=1, missing=3, nodes=15 at s/m/l), `L2 PASS` (buildBpmnXml 22736 bytes,
identical before and after), 9 PNGs written.

## What the step's own shots show (step 2, read by eye)

| shot | file here | what it shows |
|---|---|---|
| none-m | `asrun-none-m-judge-t-893-r5-claude-code-65df64787359.png` | "Start work" node, I/O badge 1→0, id badge frw_1_start. No marker. MET. |
| missing-m | `asrun-missing-m-judge-t-893-r5-claude-code-65df64787359.png` | orange bold mono "⚠ no auth" above the top-left corner of "Perform the work"; ends left of the arrowhead entering at top-centre, no overlap. Reads as a defect. MET. |
| differs-m | `asrun-differs-m-judge-t-893-r5-claude-code-65df64787359.png` | **NOT the node.** The clip shows the right-hand properties panel ("task-lifecycle", "human-readable name shown", "Workflow version · bump manually"). No "◆ ini" is visible. NOT MET as written. |

Cause, measured in a diagnostic copy of the script: the differs node (`frw_2_enter`) sits at viewport
x=1140..1250, y=209..284 in the 1400px window, and `document.elementFromPoint` at its centre returns
`INPUT.field-input` (the properties panel), not the node. `asrun-fullpage-1400-judge-t-893-r5-claude-code-65df64787359.png` is the full page at
the script's window size: the panel covers everything right of about x=1080. All three differs shots
(s/m/l) come out as the same 14675-byte picture of the panel. The script does not check that the node is
the top element at the clip, so it exits 0 and L1/L2 pass.

The committed `docs/reports/t893-shots/differs-m.png` (commit 57c78a35b, 2026-10-10) does show "◆ ini",
but it is from a designer 139 commits older than this revision, and step 1 replaces it with the panel shot.

## The taste judgement, on a shot that does show the node

Same script, one more change: `--window-size=2700,900` so the panel no longer covers the node
(elementFromPoint then returns `rect.node-shape` for all three). `wide-side-by-side-m-x2-judge-t-893-r5-claude-code-65df64787359.png` is
none-m | differs-m | missing-m from that run, enlarged 2x.

- none: no marker.
- differs: "◆ ini" in faint grey mono above the top-left corner. Computed style: fill rgb(90,97,115)
  (--text-faint), 8px JetBrains Mono, weight 400. Same weight as the id badge; reads as an annotation.
- missing: "⚠ no auth" in orange. Computed style: fill rgb(245,168,71) (--orange), 8px, weight 600.
  Reads as a defect. `<title>` carries the full text ("no authority — this element has none and its lane
  offers no default").

My reading: the two are different kinds of thing (colour, weight and glyph all differ; one is the
background-grey of metadata, the other the app's warning colour), neither is mis-pitched, and the common
case is silent. Position: on task-lifecycle "⚠ no auth" stops a few pixels left of the top-centre
arrowhead on both `agt_1_write` and `agt_2_perform`, and the nearest edge labels ("placeholder ACs",
"resume after healing…") sit above it without touching. The lane separator runs just above the marker,
as the task already notes.

## Verdict: amber

The design the criterion asks about is right, on evidence I produced with a wider window. But the criterion
as written is not met at this revision: its step 1 writes a `differs-m.png` that shows the properties panel,
so step 2 cannot show "◆ ini", and running the step destroys the one committed shot that does.

Needed: fix `tools/_t893-authority-marker-shots.mjs` so the differs node is in clear view when clipped
(close/collapse the right panel, pan to the node, or widen the window), add a leg that fails when
`elementFromPoint` at each clipped node is not inside that node, re-take the nine shots and commit them.
Minor: `## Visual Verification` names the differs node `frw_4_enter`; the script uses `frw_2_enter`.
