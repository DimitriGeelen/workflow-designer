# T-1470 Human AC#1 — independent review (revision 8ebda3a2)

Images judged as supplied (360x360 PNG crops at 1440); app not re-run.

## Pair 1 — Opportunity / Solution – Product -> Product (status: Needs Analysis)
- Before: dotted line runs diagonally from the Opportunity box's top (x~185) up-right to the Product box's bottom-right corner (x~222); arrowhead barely visible.
- After: dotted line is perfectly vertical at x~222, from the top edge of Opportunity / Solution – Product to the bottom edge of Product. An open chevron arrowhead sits at the Product box's bottom edge, to the right of the `sal_3_product` caption with a visible gap (zoom: pair1-arrow-zoom-*.png). Reads as attached to both steps.

## Pair 2 — Open Order -> Sales Order (status: Open Order)
- Before: same diagonal from Open Order's top to the Sales Order box's bottom-right corner.
- After: vertical at x~222 from Open Order to Sales Order; arrowhead at the target's bottom edge, right of `sal_7_sales` and clear of it (pair2-arrow-zoom-*.png).

## Nothing worse
- A pixel diff of before vs after shows the change is confined to bbox (184,123)-(227,230) in both pairs, which is only the region where the old diagonal ran and the new vertical line runs. No caption, label, task tag, trigger line or other connector outside that region changed.
- Inside that box: the `sal_3_product` / `sal_7_sales` captions, the `trigger` label and the `(task)` tag are unchanged and not crossed by the new line. The new line crosses the horizontal lane divider, as the old diagonal did.
- The unrelated diagonal association at the bottom left of pair 2 (from tac_5_open) is the same in both images.

## Minor observation (not blocking)
Both ends sit near the right-hand rounded corners of the boxes, and the open chevron is small and low-contrast at this zoom. It is still visible and clearly ends on the target box.

Verdict: green.
