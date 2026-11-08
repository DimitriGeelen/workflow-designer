# T-1384 AC1 — independent review (judge-t-1384-r3-b3f291dd7e92), revision 9b112befc

Read docs/reports/T-1384-evidence/README.md, then opened all four screenshots (the 1024 dock regions also cropped and enlarged 2x).

## live-1024-judge-t-1384-r3-b3f291dd7e92.png (collapsed)
- One card (single yellow border), three rows of equal width joined by dividers: import notice, Clean-layout nudge, authority summary.
- Row 1: "▸ 2 more" and ✕ at the right edge. Row 2: "Clean layout" button and ✕ at the right edge. Row 3: "▸ 1 more" and ✕ at the right edge. All of them visible and unclipped.
- Card spans about y 88–202 of a canvas about 692px tall (y 76–768). The pool header starts at y≈240, so the card covers no pool, task, event, document (Order confirmation) or data store (Order book). The README gives 135px of 685 (20%) dock padding, which matches the pixels: about a fifth.
## live-1024-open-judge-t-1384-r3-b3f291dd7e92.png (opened)
- Controls read "▾ less", still at the right edge next to an unclipped ✕.
- The import notice shows its headline and both bullets (the on-save sizes/labels/bends and pool/lane outlines NOT kept bullet; the 1 document and 2 data stores bullet). The authority row shows the full sentence "...none of its 5 elements carries one and no lane offers a default (markers summarised here, not drawn per element)".
- The text matches word for word what 1440 and 1920 show unexpanded, so nothing is dropped.
- The diagram moved down (pool header at y≈370). The card still covers no element.
## live-1440-judge-t-1384-r3-b3f291dd7e92.png
- One card of equal-width rows, every part shown, no more/less control. ✕ and the Clean layout button sit at the right edge. Card ends at y≈242 and the pool starts at y≈282: no overlap.
## live-1920-judge-t-1384-r3-b3f291dd7e92.png
- Same as 1440. The card is centred, ends at y≈197, and the pool starts at y≈237: no overlap. All ✕ and the Clean layout button are at the right edge.

## Out-of-scope observation (not an advisory issue)
At 1024 the right side panel hides the right part of the pool ("Confirm order" is cut off), and at 1440/1920 the pool runs under the right panel. That comes from the side panel and canvas width, not from the dock. It does not bear on this criterion.

Verdict: green.
