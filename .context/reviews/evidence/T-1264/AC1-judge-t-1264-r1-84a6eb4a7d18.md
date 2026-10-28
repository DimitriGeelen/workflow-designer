# T-1264 Human AC#1 — judge judge-t-1264-r1-84a6eb4a7d18 (revision c7529d93c)

Verdict: green

## Screens read (copies in this directory, suffix -judge-t-1264-r1-84a6eb4a7d18)
- kitchen-sink 1024/1440/1920 (+ 1024 notice crop): the notice ends with the exact line "on save, shapes that neither you nor this
  import moved keep this file's sizes and labels, and lines between them keep their bends; the file's original pool and lane
  outlines are NOT kept". Readable, wraps under its bullet inside the notice border (3 lines at 1024, 2 at 1440, 1 at 1920),
  dismiss × on the right. The pool is drawn below the stacked advisories; no node is under the notice. Header and toolbar
  (Open project … Save) visible at every width (2 rows at 1024/1440, 1 row at 1920).
- nested-lanes 1024/1440/1920: same last line, full, wrapping in the notice; diagram below the advisories; toolbar visible.
- plain-designer-map (arc-lifecycle) 1024/1440/1920: no import notice.
- measures.json: all 9 states problems: [], shown true/false as expected; notice text matches the AC wording.

## Is the sentence true to what a save does?
- HEAD diff (captureImportedDi): kept geometry is anchored to the FILE's Bounds x/y (fileAt), not to the post-import position.
  keptShapeXml/keptEdgeXml return null (redraw) when the node is not at k.at, so a node the import moved back into its lane is
  redrawn, and so are flows touching it.
- Ran tools/_t1264-imported-geometry-cdp.mjs on HEAD: ok true, errs [] (corpus 24).
- Ran it with T1264_SRC = HEAD~1 source: ok false — "a node the import moved kept its imported geometry (X_di)" and "the flow
  into a node the import moved kept its imported route". So the harness catches the round-1 finding, and HEAD fixes it.
- Shots were taken at 1f5b7f301. HEAD changes only the save-path capture code and not the notice text or layout, so the shots
  still show what HEAD renders.

## Notes (not blocking)
- At 1024 the stacked advisories take about half the canvas height. That is the existing T-1327 layout; this task adds no line.
