# T-1504 Human AC#1 — independent image review

Revision reviewed: 51f261e85e3d2a7e9760dd495821a92ee991ecae (HEAD matched at review time).
Images: the 12 files in docs/reports/T-1504-shots/, copied to this directory with the reviewer suffix.
Method: opened and inspected every image. No harness or app run (per brief).

## What I checked, per width (1024 / 1440 / 1920)

1. **palette** — Phases section sits under LANES with two items: "Add phase row — one phase across the map" and "Add phase — click where it starts". A footer explains click-then-click-canvas. Names and hints are readable at all three widths. Clear.
2. **row-added** — One bracket labelled "Phases" runs across the top of the pool. The right panel shows `phase` / Name "Phase 1" / Row "Phases". The status bar reads "phase selected". The new phase is visibly selected. Clear.
3. **split-preview** — The "Add phase" palette item is highlighted and the status bar reads "Mode: add phase: click where it starts · phase selected" at all three widths. **However, no dashed split line is visible in any of the three shots.** The pool is cut off on the right, and the pointer position over a step gap is not visible either. The brief says the line may be off-screen and the harness asserts it is drawn, but I cannot see it on the evidence supplied, so I cannot confirm that a person "sees where the split will land before clicking" from these images.
4. **five-phases** — At 1440 and 1920 the labels "Phase 4" and "Phase 5" are visible, Phase 5 is green-bracketed and selected, and dashed dividers sit at the step gaps (the one at x≈925 in 1440, x≈990 in 1920 falls between nodes). Panel shows "Phase 5". At 1024 only "ase 4" is visible at the left edge (viewport scrolled), with the selected bracket at the right. No overlap or clipping of the controls. Dividers are visible.

## Clipping / overlap
- No overlap between palette, status bar, notification stack and pool at any width.
- The pool extends past the viewport in several shots (scrolled canvas). This is the normal scrolled view, not a defect of the feature.
- The notification banners sit over the top of the canvas in every shot; they do not hide the Phases bracket.

## Gap
The split-preview evidence does not show the dashed landing line. That is the one element the criterion explicitly names ("sees where the split will land before clicking"). The other expected elements are present.

## Verdict
amber. The palette, the row, the selection, and the five-phase result are all clear and match the Expected clause. The split-preview shots show the mode and palette highlight but not the dashed landing line in any visible pixel. Needed: a re-captured split-preview at each width with the pointer over a visible step gap, so the landing line is in frame.
