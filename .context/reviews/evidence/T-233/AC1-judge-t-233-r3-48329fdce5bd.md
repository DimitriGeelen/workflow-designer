# T-233 AC1 — ghost entry reads as "not a map yet" at a glance

Reviewer: reviewer-judge-t-233-r3-48329fdce5bd (rung-3-termlink-single-reviewer), revision cd0048a7e0f9fad4522fe8fdc004d093ed6e6b9f (src/ and tools/ clean in the working tree).

## What I did
1. Ran the AC's step 1 exactly: `python3 tools/gallery-serve.py 3099 --docroot src --repo .`. Afterwards I stopped it by PID and confirmed the port was free.
2. `/api/list` returned 33 maps and 1 ghost: uuid 4300eae7-f2b4-4a1f-abcf-a2812a882a5e, name "future-map", referenced_by=[claim-smoke-legacy / frw_2_handoff-2].
3. Opened http://localhost:3099/aef-workflow-designer.html in headless Chromium (Python Playwright, 1400x900) and did a real click on the toolbar button "📂 Open project…".
4. Took screenshots of the grid as first shown, the grid scrolled to the ghost, a greyscale version, and a zoom. I compared them visually before reading any text.
5. Did a real click on the ghost card, then read the toast and the editor state.

## Findings
- **The ghost is distinct before reading** (AC1-judge-t-233-r3-48329fdce5bd-open-grid-ghost-visible.png, AC1-judge-t-233-r3-48329fdce5bd-ghost-vs-neighbours-zoom.png):
  - **Border:** 1px dashed amber (#d0a227). Every map card has a 1px solid grey border (computed: `1px dashed rgb(208,162,39)` vs `1px solid rgb(42,49,66)`). Of all the buttons in the dialog, only the ghost card has a dashed border.
  - **Tile:** empty dark tile with a dashed divider and a small amber ◌. No 🗑 delete button, which every map card has.
  - **Colour:** the amber accent repeats on the border, the divider, the glyph and the "◌ pending ref" text.
- **Greyscale** (AC1-judge-t-233-r3-48329fdce5bd-open-grid-ghost-visible-greyscale.png): the dashed outline and the missing 🗑 still set it apart. The signal does not depend on colour.
- **Click:** the toast reads exactly "🔗 New map adopts pending ref 4300eae7… — Save to project to claim it." (AC1-judge-t-233-r3-48329fdce5bd-after-click.png). Editor state afterwards: activeKey=future-map, workflowMeta.uuid=4300eae7-f2b4-4a1f-abcf-a2812a882a5e, which is the ghost's uuid. The canvas is a new empty map. I did not save, so nothing was claimed and nothing was written.

## Weak signals (advisory, not blocking)
- **Position:** the ghost comes after all 33 maps. It is below the fold when the dialog opens (AC1-judge-t-233-r3-48329fdce5bd-open-grid.png) and you only see it by scrolling to the end. That is by design ("what exists, then what is promised"), but position does nothing for discovery, only for grouping.
- **Tile glyph:** the ◌ is small and thin. On its own it looks a lot like the T-149 ▦ fallback tiles (dark empty tile, small centred glyph). The dashed border carries the distinction. The glyph adds little.

## Verdict: green
The criterion is that the ghost is visibly a different kind of thing before reading any text. That holds in colour and in greyscale, and the click behaviour matches the Expected text exactly. This is a visual-weight taste call, not a Tier-0, irreversible or direction call, so under the operator's ruling it does not need a human. In my judgement it is loud enough. Optional polish: a larger ◌ glyph, a pinned or "N pending" header for ghosts, or a 2px border.
