# T-358 AC1 — independent review (rung-5-panel:claude-code)

Revision reviewed: 3da0b4f6a0ede7741f9853879c561c5e9f5ca82f
Reviewer dispatch: judge-t-358-r5-claude-code-f905b0414c85
Criterion: [REVIEW] A map that declares no lanes reads correctly without the lanes the importer used to invent.

## What I did
Opened all 21 PNGs in docs/reports/T-358-evidence/ (boundary-events, collaboration-message-flows, i18n-documentation,
multiple-diagrams, nested-subprocesses, simple, zeebe-service-task × 1024/1440/1920). For each, checked: one pool outline,
no lane band/header, every task/event/subprocess inside the pool, "+ Add a lane" below the pool, advisory card controls
(× close, "▸ 1 more", "Clean layout") visible and unobstructed. Zoomed (PIL crop, NEAREST x4) where an edge was in doubt.

## Findings

### Met
- No lane band or lane header is drawn in any of the 21 screenshots. Each map has a single pool header "<Process> · workflow:<id>".
- "+ Add a lane" (singular wording) sits directly below the pool at 1440 and 1920 in every map.
- Advisory card: close (×), "▸ 1 more" and "Clean layout" controls are visible and not covered by canvas or panels at all three widths.
- collaboration-message-flows (1024/1440/1920): the read-only pool ("Pool · read-only") sits below ours with the
  "+ Add a lane" strip between; the two pool outlines do not overlap.
- boundary-events, i18n-documentation, multiple-diagrams, simple, zeebe-service-task at 1440/1920: all shapes are inside the pool outline.

### NOT met — an event lies across the pool outline
- **nested-subprocesses-1920.png / -1440.png / -1024.png**: the pool's left border is at x≈280 and the first start event
  ("lan_start_startevent", centre x≈293, radius ≈18) spans x≈275–311. The pool's left border line runs through the circle
  (see nested-subprocesses-1920-zoom-left-edge-judge-t-358-r5-claude-code-f905b0414c85.png). Its label also extends left out of the pool (x≈238).
  The pool therefore does not enclose every event, so "one pool around its whole diagram" fails for this map at all three widths.
  (Every other map gives about 25px+ clearance between the pool's left edge and its leftmost shape. In this map the pool's left
  edge seems to follow a coordinate that is about 14px inside the leftmost shape's bounds.)

### Not verifiable from the screenshot (secondary)
- **boundary-events-1024.png**: the pool's bottom edge and "+ Add a lane" are below the 768px viewport. The lowest node (joker, y≈705)
  is visible and the pool's left border reaches it, but the screenshot does not show that the outline closes below it.
- At 1024 the text of "+ Add a lane" is hidden behind the right properties panel in every map; only the dashed strip shows.
  The criterion asks that it "sits below the pool": the strip is in place, but the label cannot be read at that width.
- collaboration-message-flows-1440/1920: message-flow lines run through the "+ Add a lane" label ("Add a lane" is struck through at x≈1020).
  This is a nit and does not fail the criterion.

## Verdict
red: nested-subprocesses (all three widths) has a start event outside / straddling the pool outline.
