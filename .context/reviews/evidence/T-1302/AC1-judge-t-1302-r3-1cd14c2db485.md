# T-1302 Human AC#1: independent review (judge-t-1302-r3-1cd14c2db485)

Revision reviewed: 213c7ff92892bf1dd4d504e63d760d52616d432f
Source: docs/reports/T-1302-evidence/ (87 shots), compared with docs/reports/T-1305-evidence/ (58 shots).
Harness states: tools/_t1249-v11-io-shots.mjs lines 98-110.

## Field rows (fields-edit, field-add, fields-when at 1024/1440/1920)
Viewed: fields-edit-{1024,1440,1920}-panel-end, field-add-{1024,1920}-panel-end, fields-when-{1024,1440,1920}-panel
and fields-when-{1024,1920}-panel-end. I enlarged the 1024 field blocks 3x (fields-edit-1024-zoom, fields-when-1024-zoom).
- Line 1: the kind select (fieldRef/path) and the address input are visible. Long fieldRefs (tacton:Opportunity.crmOppExtId,
  .accountId) wrap onto a second line and show the full value. Nothing is truncated (the break falls mid-identifier, which is cosmetic).
- Line 2: role select (match/write/create/"role —"), "cardinality —" / "many" select, req checkbox + label and ×.
  All are present, aligned on one baseline and unclipped at every width. The panel is 320 px wide at all three widths, so the layout is the same at each.
- Fields are separated by dotted rules. The "fields" heading sits below a dotted divider inside the io editor's yellow
  left rail, and "+ add field" is the last item inside that rail. The rows clearly belong to their io and sit above the next io row.
- field-add: the new empty row shows "path" + "path…" placeholder, "role —", "cardinality —", req and ×, followed by "+ add field".
- fields-when: "req when ×1 ×" fits on line 2 without wrapping or clipping.
- The "req" label and the × are faint (low contrast). The task attributes this to T-1310, which predates this work, and it
  applies equally to the io rows. Both remain visible in the shots, so I don't count it as a failure of this AC.

## Closed states vs T-1305 (pixel comparison, PIL ImageChops on same-name files)
- 29 identical; 3 (stylea-step-1920, v11-step-1920, workflow-1920) differ on 35 px with max channel delta 1
  (invisible). This matches the task's table.
- 26 other files differ heavily: hint-edit, stylea-edit, v1-edit (all open the io editor, which now
  contains the fields section) and longname. In longname the editor stays open from the earlier states in the same width run
  (the harness comment says so). Side-by-side longname-1440 (T-1305 left, T-1302 right): the only change is the
  "fields / + add field" block inside the open editor and the scroll offset that follows from it. The closed rows (team / list,
  assignment / ref, + add input / output) are unchanged.

Verdict: green. Every field control is visible, aligned and unclipped, the rows sit visibly inside their io, and the closed states are unchanged.
