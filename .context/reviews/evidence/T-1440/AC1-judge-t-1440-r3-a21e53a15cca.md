# T-1440 Human AC#1 — reviewer evidence (judge-t-1440-r3-a21e53a15cca)

Revision reviewed: 10c4f11b8823b10f27d82358f971e59a4dd05390. Judged on the supplied images; the harness, app
and capture were not re-run (cannot reproduce: not attempted, per brief).

## Verdict: amber

One defect: **the PDF export has no arrowheads on any flow** (both maps). Everything else in the criterion is met.

## What I opened and what it shows

### PNG exports — met
- `arc-lifecycle@2x.png` (4200x1068, copy: arc-lifecycle-2x-judge-t-1440-r3-a21e53a15cca.png): white background (corner pixel 255,255,255);
  3 lanes with labels; 10 step boxes, 1 gateway, start + 2 end events; all 13 flows drawn with a filled arrowhead
  at the target; flow labels "close (demo evidence)" and "abandon" readable; step IDs readable. No editor
  controls, no selection, no grid. Cosmetic only: the "0→1" badge touches the last letter of "Create arc" and
  "Tag member"; "frw_1_abandon" sits on the lane border. Both stay readable.
- `audit-process@2x.png` (3492x1636, copy: audit-process-2x-judge-t-1440-r3-a21e53a15cca.png): white background; 3 lanes; 7 step boxes,
  3 gateways, start + 3 end events; all flows with arrowheads; labels "any FAIL", "any WARN (no FAIL)", "clean"
  readable. No editor controls. The step IDs frw_1_compliance, frw_5_traceability, frw_2_discovery,
  frw_3_enforcement under the middle column are half-covered by the box below — the criterion's note declares
  this the map's own spacing, so I do not count it against the export.

### PDF first pages — NOT met on arrowheads
- `arc-lifecycle-pdf-page-1.png` (copy: arc-lifecycle-pdf-page-1-judge-t-1440-r3-a21e53a15cca.png; 4x zoom of the bottom-left:
  arc-lifecycle-pdf-page-1-zoom-judge-t-1440-r3-a21e53a15cca.png): white A4 landscape page, title "arc-lifecycle · v1", the map alone, no
  editor controls; boxes, lanes, gateway, flow lines and flow labels present. **Every flow is a bare line: no
  arrowhead at any target** (e.g. start → Create arc → Start arc → Tag member → BVP rescore; gateway → Close arc;
  gateway → Abandon arc; Emit close → Close or abandon?).
- `audit-process-pdf-page-1.png` (copy: audit-process-pdf-page-1-judge-t-1440-r3-a21e53a15cca.png; zoom: audit-process-pdf-page-1-zoom-judge-t-1440-r3-a21e53a15cca.png):
  same: title "audit-process · v1", map alone, all elements present, **no arrowheads**; the lines into the join
  gateway and into each check box stop short of the shape where the arrowhead should be.
- Cross-check that this is the PDF and not the supplied raster: I rasterised the supplied
  `arc-lifecycle.pdf` / `audit-process.pdf` at 200 dpi with three independent renderers (poppler pdftoppm,
  Ghostscript, MuPDF). None draws an arrowhead. The PNG and SVG exports of the same maps do carry them
  (arc-lifecycle.svg: 13 x marker-end="url(#arrow)"), so the loss is in the PDF/print path only.
- Why it matters: on paper the direction of a flow can no longer be read. In arc-lifecycle the vertical runs
  between the Agent and Human lanes (BVP rescore ↔ Approve value drivers ↔ Work member tasks; Emit close ↔ Close or
  abandon?) are ambiguous without heads. The criterion's step 2 lists "arrowhead ... present" explicitly.
- Otherwise the PDF reads cleanly at 200 dpi: box text, IDs and flow labels are legible; arc-lifecycle uses the
  full page width (the map is wide and short, so the lower half of the page is empty — acceptable).

### Export menu — met
- `menu/1024-export-open.png`, `1440-export-open.png`, `1920-export-open.png` (copies: menu-<w>-export-open-judge-t-1440-r3-a21e53a15cca.png):
  six entries each — BPMN 2.0 / Camunda (.bpmn), PDF (print) (.pdf), SVG picture (.svg), PNG picture 1x / 2x / 4x —
  all readable, evenly spaced, none overlapping another; the menu sits on top of the canvas/side panel and wholly
  inside the window at each width (1024: under the Export button on the second toolbar row, right edge ~489px;
  1440 and 1920: right-aligned to the Export button, left of Save). `menu/measure.json` agrees
  (export-open: inWindow true, menuOnTop true at all three widths).

## Needed
Make the PDF/print sheet draw the flow arrowheads (the markers are lost in the print copy of the SVG — likely the
marker defs / url(#arrow) references or their resolved fill do not survive into the print sheet), re-export both
PDFs and re-shoot `{arc-lifecycle,audit-process}-pdf-page-1.png`. The browser leg should assert arrowheads in the
PDF path too, since it passed without them.
