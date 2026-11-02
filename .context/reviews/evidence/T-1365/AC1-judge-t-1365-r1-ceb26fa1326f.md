# T-1365 AC1 — independent review (judge-t-1365-r1-ceb26fa1326f), revision feb8b50e02281f6e5c31616aa4eae3cc8b49ddd4

Evidence: docs/reports/T-1365-evidence/*.png, last changed in feb8b50e0 (the reviewed revision), no working-tree changes. I viewed all 9 PNGs.

## Folded (panel-{1024,1440,1920}.png)
- Step "Register the order" selected; output "Order" editor open; fields list visible.
- ex:attr-order-id summary: "▶ crm:Order.Id · string · max 18 · pattern · e.g. ORD000000000000AAA". It matches the expected "crm:Order.Id · string · max 18 · pattern · e.g. ORD…". The example wraps onto a second line and is not truncated.
- ex:attr-order-status summary: "▶ crm:Order.Status · string · one of 3" ✓
- ex:attr-order-unknown: "not in the project's field catalog: no value rule" (italic) ✓
- path Order.note: no rule line ✓
- Exactly one summary line under each catalogued field ✓

## Opened (panel-*-open.png, fields-*-open.png at 2x)
- Order.Id: meaning "Id (CRM Order)", format "CRM record id, 18 characters, starts with ORD", type "string, max length 18", pattern "^ORD[A-Z0-9]{15}$", example "ORD000000000000AAA (made up, shape only)", comes from "set by the CRM on create", system "CRM", rule "ex:shape-attr-order-id" ✓ (all items the criterion lists)
- Order.Status: allowed "Open | Complete | Cancelled", derived "follows the order state in the quoting tool" (what the status follows), plus meaning, format, type, system and rule ✓
- Unknown and Order.note are unchanged ✓

## Readability and layout
- The rule text has no input boxes, uses a smaller dim label column with a value column, and sits under a ▶/▼ disclosure. It is visually distinct from the bordered editable inputs and selects above it and cannot be confused with an editable field.
- Readable at 2x and legible at 1x (11px). I found no overlap or clipping in any of the six panel shots or the three fields shots. Long values wrap inside the panel.
- Toolbar: 1024 has 2 rows with every control present (Open project … Save); 1440 has 2 rows with everything present; 1920 has 1 row with everything present. Nothing is clipped.
- Side panels: the left palette and the right inspector are fully visible horizontally at every width. The vertical extent continues by scrolling, which is normal panel scrolling and not clipping.

## Note
fields-1440-open.png and fields-1920-open.png have identical byte sizes and look identical. That is expected: the panel has a fixed width at those viewports. This does not affect the verdict.

Verdict: green.
