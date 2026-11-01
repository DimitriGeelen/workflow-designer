# T-1350 Human AC#1 — independent review (reviewer judge-t-1350-r3-e55f84e7d09e)

Revision: 70035d48482c40aff8c2b0799d74d51d7de24a87 (HEAD at review time). The evidence PNGs were committed in 74cbede38.

## What I looked at
- `docs/reports/T-1350-evidence/kitchen-sink-1920-host-zoom-before.png` and `kitchen-sink-1920-host-zoom.png` (the 3x host zooms)
- `kitchen-sink-{1024,1440,1920}.png` (the whole canvas)
- `docs/reports/T-1344-evidence/kitchen-sink-1920.png` (the T-1344 whole canvas, as the "as before" baseline)
- My own 3x LANCZOS crop of the host region of kitchen-sink-1920.png (x 480-900, y 495-870): host-region-1920-x3-<id>.png
- Copies of everything I cite are in this directory with the -<id> suffix.

## Findings
**Before (T-1344, host 120x64):** the 12 boundary events pile up on the host's left and right ends. The circles stack on each other and the labels overprint (Event_13xoo98, Event_1ks4j21, Event_1coa1sl, Event_O1qjlyl and others cannot be read). This confirms the defect.

**After (T-1350, host 150x600):**
- All 12 boundary circles sit on the host's vertical edges, each apart from the others:
  - left edge (7): Event_1ks0id1, Event_Okqsyo, Event_13xoo98, Event_1ks4j21, Event_O1qjlyl (error), Event_1coa1sl, Event_O16dsxc
  - right edge (5): Event_Oj9Owfw, Event_1x9von4, Event_1pdjezb, Event_Oncmtxn, Event_1o9cjfb
- Each event has a two-line label (name plus lan_* id), placed outside the host on its own side. No label sits on another label or on a circle.
- Free-standing events beside the host are not covered:
  - left column: Event_1vk9d2b, Event_Ord4z0d, Event_O1o5kun, Event_Oa3nmhs, Event_Ocvqzwg
  - right column: Event_1qjhrf7, Event_Onn7qi2, Event_Od3edlz, Event_1fol0Oq, Event_1bjbr5h
  - The host's outline stays between those two columns. Some free-standing labels were moved: Event_Ord4z0d and Event_O1o5kun are now labelled to the left of their circles. They remain readable.
  - One tight spot: Event_Ord4z0d's label is stacked directly above the label la3_start_event_8. The lines are distinct and do not overlap, so this is not a collision.
- The host stays inside its lane at all three widths:
  - At 1920 the host runs y≈510–815 and the lane divider is at y≈860.
  - The Transaction activity below it, with its "(transaction)" type label, is still apart from the host's bottom edge.
  - At 1440 and 1024 (the canvas fitted into a smaller area) the host is still well inside the upper lane.
- The rest of the canvas, the notices and the toolbar are unchanged. The T-1350 1920 shot matches the T-1344 1920 shot in the toolbar, the three notices (same text) and every other node. The only differences are the host and the label positions of the free-standing events near it. measures.json reports the same notice text at every width, with problems: [].

## Limits
- I judged the committed screenshots, as the criterion's steps direct. I did not re-render the app myself.
- At 1024 the fitted canvas is too small to read individual labels at any revision. Readability is judged on the 1920 shots, which the criterion's own zoom uses.

## Verdict: green
