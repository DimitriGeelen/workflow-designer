# T-1381 AC1 — independent review (judge-t-1381-r1-17c89bd22e4b)
Revision: 01cb10fc3bbe16b77e7fe5f54be15055677bb399 (HEAD at review). Screenshots last changed in 01cb10fc3.

Viewed: stores-1920-zoom.png, stores-1440-zoom.png, stores-1024-zoom.png, stores-1024.png, stores-1440.png,
stores-1920.png, stores-1920-zoom-before.png (all in docs/reports/T-1381-evidence/). Cropped and upscaled with PIL
(1024-zoom is only 978x322 px, so I checked the arrowheads in 4-6x crops).

1. Cylinders. Order book and Stock both have a top ellipse, two rim lines, straight sides and a curved base. That is the
   BPMN data-store glyph, and it is plainly different from the folded-corner page of Order confirmation. Labels "Order book"
   and "Stock" sit centred under the shape, unclipped and readable at all three widths. The before-shot shows no
   stores, so this change adds them. PASS.
2. Order book vs Order confirmation (under Record the order): separate slots with a clear gap between the shapes and
   between the labels ("Order confirmation [draft]" ends well left of "Order book") at 1920, 1440 and 1024. PASS.
3. Direction of the four dotted links: Record->Order confirmation (arrowhead on the page top), Record->Order book
   (arrowhead on the cylinder top), Order book->Confirm the order (arrowhead at Confirm's bottom-left corner),
   Stock->Check stock (arrowhead at Check stock's bottom-right corner). All four arrowheads are visible at every width,
   1024 included (crop stock-arrow-1024-crop). Stock's arrowhead sits right of the "war_1_check" badge text with clear
   space, and the line does not cross the text (stock-arrow-1920-crop, 1440 crop alike). PASS.
4. Lanes: Stock and its label sit inside the Warehouse lane, above the pool's bottom border. Order book and Order
   confirmation (label included) sit inside Sales, above the Sales/Warehouse border. No shape or label sits on or across
   a lane border. The only line that crosses a lane border is the sequence flow Confirm the order -> Check stock.
   That is a normal cross-lane BPMN flow, it was there before this change (before-shot), and I do not count it against "nothing crosses a
   lane border" (read as shapes and labels, per the step's subject). PASS.
5. Full windows: the toolbar wraps to two rows at 1024 and 1440 with no control clipped. At 1024 "All" is the last control
   and is fully visible. Left palette and right properties panel are unclipped. The notice banner wraps cleanly at 1024. PASS.

Nit (no effect on the verdict): Expected says "all four hold", but the steps list five checks (2-5 plus step 1's
open/compare). All checks hold, so the count does not matter.
Verdict: green.
