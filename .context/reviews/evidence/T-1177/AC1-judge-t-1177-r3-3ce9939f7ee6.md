# T-1177 Human AC#1 — independent visual review (reviewer judge-t-1177-r3-3ce9939f7ee6)

Revision: ca5b79643eeb32a1871ce153014e524a61b2f295 (screenshots committed in that commit; `git status` clean for them).
Source: the 12 screenshots named in the task's `## Visual Verification` (copied here: t1177-{1024,1440,1920}-{open,palette-folded,props-folded,resized}.png). I opened and read each one.

## Per state
- **open (1024/1440/1920):** palette (~220px) and properties (~320px) both shown; the palette fold tab (◂) sits on the palette's inner edge at mid-height, and the properties tab (▸) sits on the properties panel's inner edge. Both are whole and clear of panel controls. At 1440 the tabs just touch the diagram frame edge without covering nodes. Toolbar: two rows at 1024/1440, one row at 1920; nothing is clipped and both fold toggles ◧/◨ are present.
- **palette-folded:** the palette is gone and a ~16px strip at the left window edge holds the ▸ notch (about 72px high, mid-height), visible and recognisable. The canvas starts right of the strip and the diagram refits visibly larger (clearest at 1920: the frame now runs from x≈42 to x≈1573). ◧ is shown pressed (lit) in the toolbar.
- **props-folded:** the same on the right: the ◂ notch is at the right window edge, ◨ is pressed, the canvas widens to about x≈1875 at 1920, and the palette and its tab are unchanged.
- **resized:** the palette is ~330px and properties ~460px (at 1024 properties stops so the canvas keeps ~320px). Both tabs follow the new edges, and the properties fields reflow wider (labels go onto one line). The drag edge shows as a ~7px tinted strip (pixel sample at 1440 x=977-983 and 1920 x=1457-1463 = rgb(35,42,26)/(43,50,39) against the 1px border rgb(42,49,66) in the open state). This is the hover/drag affordance, which shows the edge can be found.

## Observations (not defects of T-1177)
- Every shot has the "Restored your unsaved work" toast at the bottom centre (caused by the test's reloads, pre-existing feature). It covers the "Mode: select" pill at 1024 (open/props-folded/resized) and part of the Tips text at 1024. It covers none of the T-1177 controls (notches, tabs, ◧/◨, drag edges) and does not affect whether the canvas fills the space.
- When not hovered, the drag edges are only the 1px panel border plus a col-resize cursor. This is the usual splitter convention (e.g. VS Code), and the resized shots show the tint. Optional polish: a faint grip.

## Verdict
green. Every T-1177 control is visible and recognisable, folding gives the space to the canvas, and nothing T-1177 introduced is clipped or overlaps.
