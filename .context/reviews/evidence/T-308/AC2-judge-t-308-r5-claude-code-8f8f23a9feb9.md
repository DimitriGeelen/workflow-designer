# T-308 AC2 — placing a handoff from the palette still feels discoverable
Reviewer: reviewer-judge-t-308-r5-claude-code-8f8f23a9feb9 (rung-5-panel:claude-code) · revision 6e7bfdf5

## What I did (same live designer, isolated profile; probe `probe-judge-t-308-r5-claude-code-8f8f23a9feb9.mjs.txt`, log `probe-log-judge-t-308-r5-claude-code-8f8f23a9feb9.json`)
1. Fired real HTML5 `dragstart`/`dragover`/`drop` DragEvents from the palette item `[data-create=linkEventCatch]` ("← Handoff from another workflow") onto the canvas SVG. This goes through the production drop listener, which calls `createNodeAt`.
2. Left the node unbound and inspected its glyph and inspector.
3. Called `autosaveNow()`, which writes only to localStorage in this throwaway profile, then did a **real `Page.reload`**. The producer only simulated a reload with `sessionAuthoredLinks.clear()`. The designer's own `autoLoadStored` restored the document.
4. Inspected the same uid again, then clicked "← Make this a handoff".

## Findings
- **While placing** (`ac2-live-node-with-neighbours-judge-t-308-r5-claude-code-8f8f23a9feb9.png`, `ac2-live-panel-judge-t-308-r5-claude-code-8f8f23a9feb9.png`):
  - The new node `n_c8b58558` has type `linkEventCatch`, the name "← Handoff" and `isBareCatchEvent=false`.
  - Its glyph is the lime ring with a chevron (1 circle, 1 path).
  - The panel shows the full Extensions section: Workflow ref, Ref display name, Target workflow, "📂 Choose from project…", the type-an-id field, Open target workflow and Link ID.
  - The export still has exactly 2 `<aef:link>` elements, so the unbound node wrote no intent marker.
- **After the real reload** (`ac2-after-reload-node-with-neighbours-judge-t-308-r5-claude-code-8f8f23a9feb9.png`, `ac2-after-reload-panel-judge-t-308-r5-claude-code-8f8f23a9feb9.png`):
  - The node is restored with the same uid and the name "← Handoff". `sessionAuthoredLinks.size=0` and `isBareCatchEvent=true`.
  - The glyph is the neutral grey double ring (2 circles, 0 paths), labelled "← Handoff".
  - The panel badge reads `intermediateEvent`, followed by the EVENT KIND note and the "← Make this a handoff" button.
- **Escape hatch** (`ac2-after-affordance-panel-judge-t-308-r5-claude-code-8f8f23a9feb9.png`): one click brings back the full target fields and the chevron glyph (1 circle, 1 path) for the session.

## Judgement on the combination (neutral ring + "← Handoff" name)
- The combination reads as "meant to be a handoff, never bound", not as broken:
  - the name states the intent;
  - the glyph honestly says "no target";
  - nothing is red, dashed or flagged;
  - the inspector offers a one-click "Make this a handoff" right where the author looks.
- The live affordance is fully discoverable.
- Neutralising after the reload is correct and consistent with the bare-import case.
- Small rough edge, not blocking: the panel copy says "the source says only that something is awaited here", which is generic for a node the author named "← Handoff". A wording tweak such as "no handoff target set yet" would sit better with a palette-born node. This is optional polish, not a defect.
- Not attributable to T-308: after the reload my dropped node sat on a lane border, with its label nudged up and to the right. I had dropped it about 130px below the lane's original bottom edge, so this is lane geometry on restore, which T-308 did not touch.

Verdict: green.
