# T-1310 Human AC#1 — independent review (judge-t-1310-r3-dc7a8cb02372)

Revision: dcaeb9b1bbde15658af031ebc0146c3fe01dd9c7. Verdict: **green**

## What I checked
1. **Pixel diff of all 121 shots**: each file in docs/reports/T-1310-evidence/ against the same file in T-1312-evidence/ (PIL ImageChops.difference bbox).
   - All sizes match.
   - Every `*-panel*` shot differs ONLY in x≈256–292, which is the req/× column.
     - fields-when-*-panel: x 210–292, i.e. the longer "req when ×1" label, which is part of the req control.
     - v1-step-1920-panel: x 264–300. This panel has no scrollbar, so the same column sits 8 px further right.
   - empty-step and workflow panels (no io rows): identical.
   - Full-page shots: the only other change is the version stamp (x256–270, y16–24).
   => Nothing else moved: name/type inputs, selects, row heights and "+ add field/input/output" are pixel-identical.
2. **Visual read of the side-by-side composites** (left T-1312, right T-1310):
   - Shots viewed: stylea-step-1440-panel (io rows closed), fields-edit-1024-panel-end (field rows + closed outputs), fields-when-1024-panel (io row open with editor), v1-step-1920-panel.
   - req and × are now clearly legible as controls. They are mid-grey, quieter than the bright name/type text and select boxes, so they don't compete with them.
   - Field rows stay two lines.
3. **Re-ran the CDP leg** `node tools/_t1310-req-x-cdp.mjs` (output in a temp dir; copy: cdp-rerun-judge-t-1310-r3-dc7a8cb02372.json): rc 0, "ok": true.
   - Contrast: 5.58:1 for io/field req and × at 1024 and 1440 (needs 4.5 / 3).
   - Hit area: the probe checks the four corners of a 24×24 square around each control, and all land on the control (miss: []).
   - The visible boxes are unchanged (37×14.5, 15.6×14), so the hit area comes from ::after without changing the layout.

## Limits
- The CDP leg measures at 1024 and 1440. At 1920 I checked by shot: the panel is the same 320 px wide, and the diffs are confined the same way.

Evidence: stylea-step-1440-panel-cmp-judge-t-1310-r3-dc7a8cb02372.png, fields-edit-1024-panel-end-cmp-judge-t-1310-r3-dc7a8cb02372.png, cdp-rerun-judge-t-1310-r3-dc7a8cb02372.json
