# T-1302 Human AC#1 — independent review (judge-t-1302-r3-2ecb2d9bd7cd)
Revision: 1045742fe8f47d4667699bf8fb0d634028d768b5. Sources: docs/reports/T-1302-evidence/ (87 shots), docs/reports/T-1305-evidence/.

## Field rows (fields-edit, field-add, fields-when; panel and panel-end; 1024/1440/1920)
- Each field is two rows. Row 1: kind select (path/fieldRef) and the address input. Row 2: role select, cardinality select ("cardinality —" shown whole), req checkbox, ×. Every control is visible, aligned to the editor's two-column grid, and nothing is clipped. I checked a 3x zoom of fields-edit-1024 (fields-edit-1024-zoom-judge-t-1302-r3-2ecb2d9bd7cd.png).
- A dotted separator sits between field blocks, and the "fields" heading has a dotted rule above it.
- The "+ add field" dashed button is full width inside the editor and present in every edit state, including empty "fields" lists (field-add-1440-panel-end: an output editor with no fields).
- A new empty field shows the "path…" placeholder, "role —", "cardinality —", req and ×.
- fields-when: "req  when ×1  ×" fits on the second row at 1920 (also checked at 1024/1440).
- Belonging: the fields list sits inside the io editor's yellow left rule, under the attribute grid and above the next io. It is visually part of its io.
- Long fieldRefs (tacton:Opportunity.crmOppExtId, .accountId) wrap mid-segment inside the input at 1024. The value is shown whole. This is the same accepted pattern as T-1305 (mid-segment wrap noted, not changed).
- The faint "req" label and "×" predate this task (filed as T-1310; the T-1305 shots show the same). Not counted against this AC.

## Closed states versus T-1305 (pixel comparison with PIL, RGB)
- 29 same-name shots are pixel-identical: empty-step, stylea-step, v1-step, v11-step and workflow at all widths, except the three below.
- stylea-step-1920, v11-step-1920 and workflow-1920 differ by 35 px in a 288x2 strip at y=9-11 (toolbar). A 3x crop shows no visible change (anti-aliasing).
- hint-edit, v1-edit, stylea-edit and longname differ. These are open-editor states that now include the new "fields" section, as expected. Side by side, longname-1440 differs only by the added fields block and scroll offset.
- Minor: the task's Visual Verification says "32 same-name shots pixel-identical". I count 29 identical plus 3 with sub-visible differences. This does not change the outcome: the closed states are unchanged.

Verdict: green.
