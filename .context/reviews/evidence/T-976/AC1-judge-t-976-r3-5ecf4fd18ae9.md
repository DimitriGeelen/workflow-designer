# T-976 AC1 — independent review (judge-t-976-r3-5ecf4fd18ae9), revision 91c16d75c

Screenshots read (copied here): flow-order-no-di-1024-judge-t-976-r3-5ecf4fd18ae9.png, flow-order-no-di-1440-judge-t-976-r3-5ecf4fd18ae9.png, flow-order-no-di-1920-judge-t-976-r3-5ecf4fd18ae9.png
Fixture read: tests/fixtures/t976/flow-order-no-di.bpmn (no DI, End listed first, lanes Sales/Warehouse, flows F1-F9 incl. F9 "recheck" Reject->Check).

## 1920 (inspected at 1x and 3x crops)
- Order: Order received (x~358) -> Check the order (~555) -> In stock? (~684) -> no: Reject and notify (~875, Sales) / yes: Pick the items (~875, Warehouse) -> Ship the order (~1035) -> Merge (~1164) -> Done (~1318). Every node is right of all its predecessors; Reject and Pick share a column as siblings of the gateway.
- Only back-running flow: "recheck" leaves Reject's left side, runs above the lane at y~168, re-enters Check's right side. All other flows run left->right (yes drops from gateway bottom then right; Ship->Merge rises from Ship's top then right).
- No node overlaps; no label collides with another label (In stock?/sal_gw_in clear of the yes line; "recheck" label boxed on its line at the pool-header edge; "no"/"yes" clear).
- Lanes: Sales = start, check, In stock?, reject, merge, done; Warehouse = pick, ship. Matches the fixture's flowNodeRefs.
## 1440
- Left part identical in layout (start..Ship, Reject's outgoing flow and Ship->Merge riser cut at canvas edge under the right panel). Horizontal scrollbar visible at the canvas bottom (thumb ~half the track), so the rest is reachable by scrolling.
## 1024
- Left part identical (start, Check, gateway partially; recheck loop start visible). Horizontal scrollbar visible (thumb ~30% of track). Commit 91c16d75c adds CDP leg F7 asserting the last node is reachable by scrolling and clickable at 1024 (not re-run by me; the screenshot shows the scrollbar).

## Non-blocking observation
At Check's right edge the recheck arrival arrowhead sits ~4 px above the departure of Check->In stock, so the two endpoints read as a small double arrowhead cluster. Still legible (the "recheck" label names the loop); not an overlap of nodes or labels, not a flow through a node. Optional polish: bring the loop-back into Check from its top.

Verdict: green.
