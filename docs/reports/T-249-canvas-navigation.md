# T-249 — Canvas navigation for oversized workflows (zoom + scrollbars + drag-to-pan)

Research artifact (C-001). Status: filed, template under operator review — spike NOT yet run.

## Problem

The canvas always fits the whole diagram to the container (`preserveAspectRatio="xMinYMin meet"`
+ viewBox recomputed from content every render — T-043). A large workflow therefore never
overflows; it **shrinks until illegible**, and there is no way to view it at working scale and
move around. Operator request (2026-07-23): zoom to readable scale, then navigate — native
scrollbars AND drag-to-pan.

## The one open question (why this is an inception)

**Which zoom mechanism composes safely with the render pipeline?** `render()` recomputes the
viewBox from content on every `renderAll()` (content edge grows dynamically — `contentRightEdge()`).
Zoom state must survive that recompute. Candidate mechanisms, each with different consequences:

1. **Explicit SVG sizing** — keep viewBox = content (as today), set SVG element width/height =
   content-size × zoom; `.canvas-wrap` gets `overflow: auto` → native scrollbars for free.
   Pointer math stays CTM-correct automatically. Prime candidate; must verify: overlay/status
   positioning, snap-guide rendering, render() not clobbering the element size, thumbnail/export
   paths unaffected, rubber-band/marquee coordinates.
2. **viewBox windowing** — zoom/pan by narrowing the viewBox to a sub-window. No native
   scrollbars (must synthesize — operator asked for scrollbars explicitly); fights the
   every-render viewBox recompute head-on. Weakest fit a priori.
3. **CSS transform on an inner wrapper** — scale via CSS. getScreenCTM should still compose,
   but CSS-transform-on-SVG has browser quirks (hit-testing, blurry raster at odd scales);
   scroll extent needs extra work (transforms don't create layout size).

Spike (timeboxed ~1h): prototype mechanism 1 in the hermetic sidecar harness against an
oversized fixture; probe the listed risks; compare with 3 only if 1 fails structurally.
IW-2 rides the same spike: pan gesture selection (space+drag / middle-mouse / pan-tool) —
constraint: empty-canvas drag currently starts rubber-band select.

## Interaction-safety context

- All pointer paths convert via `getScreenCTM().inverse()` (T-071, `clientToSvg`) — zoom/scroll
  click correctness is structurally handled IF the mechanism keeps transforms in the CTM.
- G-003 (open gap): pointer-interaction paths have zero trusted-input coverage; two field bugs
  in one day historically. The eventual build must add suite probes: zoomed click accuracy,
  scrollbar presence past fit, fit-restore, pan-then-click accuracy.

## Scope

**IN:** zoom controls (Fit / 100% / + / −), Ctrl+wheel zoom at cursor, native scrollbars past
fit, drag-to-pan (gesture per IW-2), suite probes, focus-mode composition (T-245).
**OUT:** minimap, touch/pinch, per-map zoom persistence (session-only unless trivially free),
any document-format change (zoom is view state, NEVER serialized — same principle as T-245).

## Dialogue Log

- **Operator:** some workflows are too large to fit the page — wants horizontal/vertical
  slidebars "or another way to move the workflow around the screen"; asked for reflection.
- **Agent:** confirmed the real cause is fit-to-view shrinking (scrollbars alone would change
  nothing — zoom is the missing half); initially recommended straight-to-build.
- **Operator:** challenged — "should we incept it?"
- **Agent (revised):** yes — one genuinely open mechanism question (zoom vs every-render
  viewBox recompute) + G-003 history on the pointer surface make a timeboxed inception the
  right call; the straight-to-build calibration came from T-245, which never touched this pipeline.
- **Operator:** confirmed the inception path and added scope: drag-to-pan in the first cut.

## Findings

(To be filled by the spike after template review.)
