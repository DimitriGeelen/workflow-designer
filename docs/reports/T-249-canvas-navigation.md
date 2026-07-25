# T-249 — Canvas navigation for oversized workflows (zoom + scrollbars + drag-to-pan)

Research artifact (C-001). Status: spike COMPLETE (12/12 probes green), Recommendation GO — awaiting operator decide.

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

Spike: `tools/_t249-spike-zoom-cdp.mjs` (throwaway prototype harness, same hermetic pattern
as the G-010 suite — temp docroot, sidecar server, isolated headless chromium, REAL trusted
input via CDP `Input.dispatchMouseEvent`). The entire mechanism candidate was injected at
runtime into the UNMODIFIED shipping editor — zero source edits, ~20 lines: a `syncCanvasSize`
wrapper that, when a zoom factor is set, sizes the SVG element to `viewBox × zoom` via inline
style and flips `.canvas-wrap` to `overflow:auto`. Fixture: arc-lifecycle spread to
viewBox width 5117 (≈8× the 660px wrap). **All 12 probes green** (`t249-spike-final.json`).

**IW-1 ANSWERED: explicit SVG element sizing wins — and the integration point is exactly one
function.** Key evidence:
- P1: zoom 1.5 → element 7675.8px == viewBox 5117.2 × 1.5 (±0.004px); native scrollbars appear
  (scrollW 7676 vs clientW 652); `getScreenCTM().a = 1.4999993` — the CTM carries the zoom.
- P3 (the core question): mutate a node + `renderAll()` mid-zoom → viewBox recomputed as today,
  wrapper reapplies size, zoom survives byte-exact. P4: content GROWS mid-zoom (node moved
  +1500) → element tracks new content × zoom. The every-render viewBox recompute is not an
  enemy but the natural hook: zoom re-applies wherever `syncCanvasSize()` already runs.
- P2 (G-003 class): real CDP click on a node at zoom 1.5 + scroll (600,120) → correct node
  selected. P6: real marquee drag at zoom+scroll → `multiSelect` exactly equals the
  centre-containment set precomputed via `clientToSvg` (expected==selected==[n_close_decide]).
  T-071's CTM-based pointer math needs ZERO changes.
- P5: fit restore = remove inline style + overflow → identical to today (svg 660px == wrap,
  no overflow). Fit stays the default; zoom is pure opt-in view state.

**IW-2 ANSWERED: capture-phase pan handler on `.canvas-wrap` preempts everything cleanly.**
- P7: with pan active, drag on empty background → scrollLeft 500→680, scrollTop 100→160
  (exact −Δmouse), rubberBand NEVER started, selection/multiSelect untouched. The svg-level
  mousedown (rubber-band) never fires because the wrap capture listener stops propagation —
  no existing handler was modified.
- P7b: middle-mouse drag pans with NO mode key at all (button!==1 guard only) — zero collision
  with left-button gestures. Gesture recommendation for build: **middle-mouse drag always ON +
  space+drag as the laptop-friendly alternative** (space sets the same flag the capture
  listener checks); both share one code path. Pan-tool button optional, not needed for v1.
- P6 doubles as the no-regression proof: with the pan prototype INSTALLED but inactive,
  left-drag marquee still selects exactly the expected set.

**IW-3 ANSWERED: secondary render consumers unaffected.**
- `/api/thumb` is server-side — untouched by construction (zoom lives only in live-DOM style).
- P9: `captureThumbnail()` renders non-null at zoom (its dimensions derive from `getBBox`,
  which is viewBox-space and zoom-blind). Build hardening (one line): clear `clone.style.width/
  height` in `captureThumbnail` since `cloneNode(true)` copies the inline zoom style — the
  spike shows output stays valid, but strip it for byte-stability of thumbnails across zoom.
- Suite renders (offscreen/headless) never set a zoom factor → fit path, unchanged (P5).

**IW-4 ANSWERED: composes with T-245 focus mode.** P8: focus mode ON (body.vc-focus) with
zoom 1.5 → zoom held, scrollbars still live, Esc exits focus with zoom intact.

**Two build-scope findings (not blockers):**
1. **Status overlay** (`.canvas-overlay`, absolute bottom-left in the wrap) scrolls out of
   view when panned (P10: overlay left −568 vs wrap left 220). Build: anchor it outside the
   scroll content or `position:sticky` — small, known fix.
2. **Zoom-at-cursor (Ctrl+wheel)** was NOT prototyped (pure arithmetic on scrollLeft/Top
   around the zoom change — no structural risk; the mechanism exposes exactly the right
   knobs). Standard formula, covered by build-time suite probes.

## Go/No-Go evaluation

- Mechanism proven against the real render pipeline with zero source modifications — the
  production diff is small and additive (one wrapper site + controls + gesture listeners).
- Pointer correctness (the G-003 risk that motivated inception) verified with REAL trusted
  input at zoom+scroll: click, marquee, pan — all CTM-exact.
- Reversible: fit remains default; zoom is transient view state, never serialized (P5 restores
  today's behavior exactly).
- Build ACs inherit the spike probes: the prototype IS the test harness seed (promote probes
  P1–P8 into the G-010 standing suite as the T-249 leg).
