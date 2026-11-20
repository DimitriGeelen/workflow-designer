# T-1446 Human AC#1 — evidence report (judge-t-1446-r1-20c8ae1f9c8b)

Revision reviewed: ad0495c1b2df87be7296934656fcf66b5f3b61e9. Rung: rung-1-same-vendor-independent.
Method: opened every image the criterion names and judged it as given. Cannot reproduce: I did not re-run
the app, the harness or the capture (per the brief). I enlarged crops of four page images in a temp dir to
read small text; the crops are not evidence files. Copies of the images I cite are in this directory with
the suffix `-judge-t-1446-r1-20c8ae1f9c8b.png`.

## Step 1 — Export menu (1024-, 1440-, 1920-export-open)

- All three widths: the open menu lists 11 entries, counted on the image: BPMN 2.0 / Camunda (.bpmn);
  PDF, one page (A4); PDF, one page (A3); PDF, readable pages (A4); SVG picture (.svg); PNG picture 1x, 2x,
  4x; Mermaid (.mmd); CSV (step list) (.csv); Excel (step list) (.xlsx).
- The three PDF entries are readable and told apart: label on the left, size tag (A4 / A3 / A4) on the
  right of the same row; "one page" vs "readable pages" separates the two A4 entries.
- The menu is fully inside the window at each width (1024: under the second toolbar row, left; 1440 and
  1920: under Export at the right, right edge inside the window) and is drawn on top of the canvas and of
  the properties panel; no entry is clipped or covered.
- measure.json agrees (items 11, allInWindow true, allOnTop true at each width); I did not rely on it.

## Step 2 — PDF pages

- Step names larger on the readable pages: a task box is roughly 30 px wide (read off the image, not measured) on arc-lifecycle-a4-1 (585 px
  page) and roughly 70 px wide on pages-1..3 at the same page size, so the text is over twice as large; on
  the one A4 page the titles are not legible at this size, on the readable pages they read ("Create arc
  (status draft, immutable arc-NNN)", "Start arc (draft -> in-progress)", "BVP rescore (writes PROPOSED
  scores only)"). Same for cross-host-dispatch a4-1 vs pages-1/2.
- Heading names the part: "arc-lifecycle · v1 · page 1 of 3 (row 1, column 1)", "... page 2 of 3 (row 1,
  column 2)", "... page 3 of 3 (row 1, column 3)"; "cross-host-dispatch · v1 · page 1 of 2 (row 1, column
  1)", "... page 2 of 2 (row 1, column 2)".
- Cut step whole on the next page: arc-lifecycle parts end between steps (page 1 ends after "Start arc",
  page 2 starts at "Tag member tasks"; page 2 ends after "Close or abandon?", page 3 starts at the gateway);
  no step is cut. cross-host-dispatch page 1 cuts the end event "ERROR (exit 1)" label and the "reachable" /
  "unreachable" edge labels at the right edge; page 2 repeats the SSH gateway and shows "ERROR — cannot
  connect to host (exit 1) / fre_end_error_2" and both edge labels whole.
- Lane names on the first column of pages: arc-lifecycle-pages-1 shows Human Sovereignty, Framework ·
  Authority, Agent Initiative; cross-host-dispatch-pages-1 shows Agent Initiative, Framework · Authority,
  Remote host External. Later columns keep the lane bands and their dividing lines.
- Pages end shortly after the last step (arc page 3, cross-host page 2), no wide empty tail.

## Expected — could be handed to a person and followed

Yes. Reading left to right over the parts, every step name, gateway question, edge label and end state can
be read, and the flow lines leaving one part continue at the same height on the next.

## Blemishes seen (not blocking)

- cross-host-dispatch-pages-1: the task icon of "Build JSON envelope" touches the first letter of its title;
  the title still reads.
- arc-lifecycle-pages-1: the "0-1" badge sits tight against "Create arc"; both read.
- arc-lifecycle-pages-2: "Work member tasks (each = own task-lifecycle + Evolution log)" is the smallest box
  text on the page; it reads, but only just in this 585 px raster.
- Lane names and step ids are light grey; they read on screen, a weak printer may print them faint.

Verdict: green.
