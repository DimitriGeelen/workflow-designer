# T-1093: import and export formats (inception research artifact)

This is an inception. Nothing here is a build decision. The inception answers one question: which import and export
formats should the designer offer, in what order, and at what fidelity?

**Asked for:**
- Greenfield T-172 #4, export: PDF, SVG, PNG at 1x/2x/4x, Camunda-compatible BPMN 2.0 with DI, optionally JPEG and
  GIF, and steps-per-lane as CSV or Markdown.
- The operator (2026-11-15), export: BPMN, Camunda, PDF, Word, Visio, Mermaid, Excel, CSV.
- The operator (2026-11-15), import: Visio, BPMN, Camunda, Excel, CSV.

## Step 1: inventory of what exists today (IW-1)

Measured on `src/aef-workflow-designer.html` at HEAD (designer 0.42.0, 1,351,062 bytes) and on `tools/`, 2026-11-15.

### In the designer (browser, one HTML file)

| Direction | What | Where | Notes |
|---|---|---|---|
| Export | **BPMN 2.0 XML file** (`<id>.v<version>.bpmn`) | `btn-save` handler, `src/…html:12069`; writer `buildBpmnXml`, `:14172` | The designer's own serialiser, not bpmn-js. Emits standard `bpmndi`/`dc`/`di` (BPMNShape/BPMNEdge) alongside the `aef:` extension namespace, and names itself in `exporter=` (T-399). Output is byte-deterministic (T-358 goldens). |
| Export | **BPMN XML to the clipboard** | `btn-copy-xml`, `:12063`; viewer `btn-xml` | The same writer, shown in the XML panel. |
| Export | **Save to project** (BPMN plus a version in the project store) | `/api/save`, `:12687` | Served by `tools/gallery-serve.py` and by AEF. |
| Export | **PNG thumbnail**, 320 px max | `captureThumbnail`, around `:12530-12560` (SVG clone to canvas to `toDataURL('image/png')`) | For project-browser tiles only. No user-facing image export. The method is the starting point for PNG 1x/2x/4x. |
| Import | **BPMN 2.0 XML** (`.bpmn`/`.xml` file picker) | `btn-load`, `:13503`; `adoptImportedXml`, `:13421`; parser `parseBpmnXml`, `:15294` | Reads foreign DI (T-340, T-1264) and keeps other tools' extensions it does not understand (camunda, zeebe, Bizagi: T-1325, `:13957`, `:14664`). |
| Import | **Open from project** (library or `?load=` deep link) | `btn-open-project`; `?load=` handler after `:13522` | Same parser. |
| — | Drag and drop | `:9678` | Palette node types only; files cannot be dropped. |

**No browser code** exists for PDF, SVG download, PNG download, JPEG, GIF, Word, Visio, Mermaid, Excel or CSV. A
string search finds no `window.print`, `text/csv`, `mermaid`, `vsdx`, `xlsx` or `docx`; the only `pdf` hits are
inside embedded fonts.

### Outside the designer (tools, server side)

| What | Where | Notes |
|---|---|---|
| Canonical YAML to BPMN | `tools/yaml-to-bpmn.py` | Emits no DI; positions come from `aef:position`. The corpus must not be regenerated with it (G-012). |
| Corpus thumbnails (PNG) | `tools/gen-rendered-thumbs.mjs` | Headless; uses the editor's own `captureThumbnail`. |
| AEF procedure form (O-6) | not in this repo | O-6's round trip (BPMN to AEF procedure and back) is measured against AEF's side. There is no exporter for it here. |

### Proof that BPMN import from other tools already works

`tests/fixtures/third-party/` holds 12 maps from real emitters, documented in `PROVENANCE.md`: Camunda Modeler
(including 2.6.0 with the `bpmn2:` prefix), bpmn.io/bpmn-js, Zeebe, Bizagi and caseagile. They cover DI, boundary
events, multiple diagrams, two pools with message flows, and nesting. Byte-identity goldens live in
`tests/goldens/third-party/`. Known losses recorded there: deep subprocess nesting is flattened on import, and
PROVENANCE records a two-pool collaboration as having opened as one pool (T-348). The fidelity table (step 3) will
re-measure both rather than trust that record.

### The requests, set against today

| Format | Export | Import | Starting point |
|---|---|---|---|
| BPMN 2.0 | **exists** | **exists** | — |
| Camunda (BPMN with DI and `camunda:`/`zeebe:` extensions) | **mostly exists**: standard DI is written; Camunda-specific attributes we never author are not added | **exists** (extensions kept) | Step 3 must open our output in Camunda Modeler to prove the export claim; it is not yet measured. |
| SVG | missing | n/a | The canvas is SVG; the thumbnail path already clones and inlines styles. Smallest step. |
| PNG 1x/2x/4x | missing | n/a | `captureThumbnail` with a scale factor instead of the 320 px cap. |
| JPEG / GIF | missing | n/a | The same canvas, another MIME type (GIF is not native to canvas; a cost to check). |
| PDF | missing | n/a | The browser's print dialog on a print-only page, or a vector PDF writer (size cost). Spike decides. |
| Mermaid | missing | not asked | Text, small; lossy (no lanes' geometry, no DI). |
| CSV / Markdown (steps per lane) | missing | CSV asked | Export is a table walk. Import needs an auto-layout (IW-5). |
| Excel (.xlsx) | missing | asked | `.xlsx` is a zip of XML files; it needs a zip writer/reader in the file (size cost). The CSV columns are the same. |
| Word (.docx) | missing | not asked | Also zip plus XML; a "process document" (steps, inputs/outputs, pseudocode), not a picture. |
| Visio (.vsdx) | missing | asked | Zip plus XML with its own shape model; the hardest both ways. Import has the IW-5 problem (no BPMN semantics). |

**What this tells the inception:**
1. Two of the ten requests already exist (BPMN, and Camunda on import). One more (Camunda export) needs only a
   measurement.
2. The image family (SVG, PNG, JPEG) sits on code that already runs. It is the cheapest, and it is what Greenfield
   asked for first.
3. Every zip-based format (Excel, Word, Visio) shares one cost, a zip writer/reader inside the one HTML file. One spike
   measures it for all three.
4. Every non-BPMN import (CSV, Excel, Visio) shares one problem: turning rows or shapes without BPMN semantics or
   layout into a valid map (IW-5). The T-976 "files with no positions laid out along their flows" work in 0.42.0 is
   the starting point for layout.

## Next steps

2. Feasibility spikes (IW-2, IW-5), one per family (image, print/PDF, zip, text), each measured in bytes added to the
   HTML.
3. Fidelity table (IW-3) on 3 corpus maps, including opening our BPMN in Camunda Modeler.
4. Ask Greenfield and AEF which they need first (IW-4), then propose an order to the operator.

## Step 2: feasibility spike, the ZIP family and text (IW-2), 2026-11-18

`docs/reports/T-1093-spikes/office-spike.mjs` (Node 22, no dependencies; 151 lines, 15 KB unminified) takes one real
corpus map (`arc-lifecycle.bpmn`: 14 steps, 13 flows, 3 lanes) and writes Excel, Word, Visio, Mermaid and CSV, then
reads the Excel file back with its own reader. Every file was then opened by an **independent** program:

| Format | Written by the spike | Independent check | Result |
|---|---|---|---|
| Excel `.xlsx` (2.4 KB) | sheet "Steps": id, name, type, lane, next | `openpyxl` 3.1.5 | **opens; 15 rows, names and lanes correct**; our own reader re-reads it byte-for-row identical |
| Word `.docx` (1.7 KB) | title, counts, steps table | `python-docx`, LibreOffice → PDF | **opens in both** after one fix: the schema requires `w:tblGrid` (python-docx refused without it, LibreOffice was lenient: test with the strict reader) |
| Visio `.vsdx` (3.3 KB) | one box per step, one connector per flow | LibreOffice → PDF and PNG | **opens; every box drawn with its text.** Connectors render as loose lines, not attached: they need real begin/end geometry, and the boxes must take the map's own positions, not the spike's grid |
| Mermaid | `flowchart LR`, shapes by type, labelled edges | self (14 nodes, 13 edges) | text; renderer check left for the build |
| CSV | same columns as Excel | self | text |

**What this settles:**
- All three Office formats are ZIP packages of XML. A ZIP writer and reader is ~60 lines on top of what every
  current browser already has (`CompressionStream`/`DecompressionStream('deflate-raw')`), so **no library** and an
  estimated 3-5 KB added to the single HTML file for the shared core. The designer has none of it today (0 hits).
- Excel both ways and Word out are low-risk. Visio out is feasible but the most work (connector geometry). Visio
  **in** is not yet tested: it needs a real Visio file from the operator's world, because shapes drawn with Visio's
  BPMN stencils, plain flowchart shapes and free drawings each map differently.
- Import of anything without layout (Excel, CSV, Mermaid) lands as steps with no positions: the existing ✨ Clean
  layout has to place them (IW-5), then the validator runs.
- PDF needs no file writer at all: a print stylesheet and the browser's own "Save as PDF" (not spiked yet).

### Pictures and print, and imports without positions (2026-11-19)

`picture-spike.mjs` runs the real designer headless on `arc-lifecycle`:
- **SVG:** serialising `#canvas` as is gives solid black shapes, because the designer colours shapes through its
  stylesheet. Inlining each element's computed paint (fill, stroke, widths, opacity, font) fixes it: lanes, colours,
  arrows and boxes come through; **0 remote references** (Sprind's requirement), 82 KB. Still to style in the build:
  flow-label boxes render as black bars, event names too faint on white. Editor chrome ("+ Add another lane") must be
  left out.
- **PNG** from that SVG through a canvas: 1x 2100x534 (114 KB), 2x (304 KB), 4x 8400x2136 (823 KB). No library.
- **PDF** through the browser's print path (Chrome's "Save as PDF"): works, but prints the **whole editor** (toolbar,
  palette, properties) with the map cut off: the designer has no `@media print`. A print stylesheet is the build.

`nolayout-spike.mjs` answers IW-5: `arc-lifecycle` with its `<bpmndi:BPMNDiagram>` and every `aef:position` removed
loads in the real designer as 14 steps, 13 flows, 3 lanes, 0 stacked; Clean tidies 11; the re-exported map is
**VALID, no findings**; the screenshot is readable. So Excel, CSV and Mermaid imports become BPMN without the diagram
part and reuse what exists. Visio import is the one that also needs a shape-to-element table.

## Step 5: proposed order (agent's proposal, 2026-11-18)

1. **Make what exists visible:** one Import and one Export entry in the toolbar, BPMN/Camunda listed by name
   (today hidden as "Load…" and "Save").
2. **Pictures and print:** SVG, PNG (1x/2x/4x) and PDF out. All three consumer projects asked for SVG; no file format
   code beyond SVG serialisation and a print stylesheet.
3. **Text formats:** Mermaid and CSV out (small), then in (needs Clean to lay out).
4. **Excel** out and in (the ZIP core arrives here and is reused below).
5. **Word** out (diagram picture plus the steps table).
6. **Visio** out (connector geometry), then **Visio in**, tested on a real Visio file from the operator.

## Step 4: what the users said (IW-4)

Asked 2026-11-15 on conversation `832-t1093-formats` (AEF msg b9f57d56, Sprind msg d27ad97e). Greenfield cannot be
reached until the hub on its host is up (runme job 140); its original T-172 #4 list stands for it until then.

| Project | Ranked answer | Why, in their words (abridged) | Not needed |
|---|---|---|---|
| 1409-sprind (msg b7b1e37a, its agent's view, not its operator's ruling) | **SVG, PDF, Mermaid, CSV**; then PNG. Import: BPMN is enough. | SVG to embed inline in evidence pages that run with no external service and no script: it must be self-contained, with **no webfont or remote reference** inside. PDF for submission and evidence documents. Mermaid for Markdown reports kept in git, diffable. CSV as a flat list of steps and gateways with ids, to check a diagram against their step classes mechanically. PNG only where SVG is not accepted. | Visio, Word, Excel, Camunda export |
| Greenfield (T-172 #4, earlier) | PDF, SVG, PNG 1x/2x/4x, Camunda BPMN with DI; optionally JPEG/GIF; steps-per-lane CSV/Markdown | — | — |
| AEF (msg 9eb66d6e) | **BPMN** (as today, their corpus format), **SVG, Mermaid, PNG**; nothing else for now. | Mermaid for docs and the Markdown in task files. | Visio, Word, Excel, CSV, Camunda-specific import/export; PDF only if it comes free with SVG |

**All three projects want SVG.** Greenfield and Sprind also put PDF first and want CSV. Sprind and AEF want Mermaid,
and all three want PNG at least as a fallback. **Nobody has asked for Visio, Word or Excel.** Those came from the
operator alone, so they need the operator's own reason before they are ranked. Sprind adds a requirement the
spike must test: an SVG with no webfont or remote reference (the designer embeds its fonts as base64 woff2 today, so
the export either inlines them or falls back to system fonts).

## Dialogue log

- 2026-11-15, operator: "can we add export formats like bpmn camunda pdf word visio mermaid … and then also we want to
  be able to import stuff like visio bpmn camunda". Then: "Maybe also Excel, good import and export format." A further
  short reply was read as CSV (spoken input). T-1093 was widened from Greenfield's export menu to import and export.
- 2026-11-18, the agent asked what Visio, Word and Excel are for (show / bring in / round trip), first in abstract
  terms the operator did not follow, then plainly ("save out to give someone" vs "load in old files"). Operator:
  "it's indeed import and export … with Excel, with Visio, with BPMN, with Camunda, XML, what formats we can think
  are relevant, they want to be able to import and export. And with Word and PDF … it's nice to export a file to give
  a PDF or Word." Then: "Another export and import format is Mermaid for instance … might be good."
- 2026-11-18, operator: "If it already works I don't see it, there is no interface for it." Checked in
  `src/aef-workflow-designer.html`: BPMN import IS the toolbar's **Load…** (file picker, `.bpmn/.xml`, line ~13641) and
  BPMN export IS **Save** (downloads `<id>.v<n>.bpmn`, line ~12179). Neither is labelled import, export or BPMN, so the
  capability exists and is invisible. **Finding:** the menu this task builds must be a clearly named Import / Export
  entry listing every format, BPMN included; renaming Load/Save is part of it, not an afterthought.

**Operator's direction (2026-11-18), the IW-4 answer for this project:**

| Format | Import | Export | Source |
|---|---|---|---|
| BPMN 2.0 / Camunda (XML) | yes (exists, as "Load…") | yes (exists, as "Save") | operator |
| Excel (.xlsx) | yes | yes | operator |
| Visio (.vsdx) | yes | yes | operator |
| Mermaid | yes | yes | operator ("might be good") |
| Word (.docx) | no | yes, a document to hand someone | operator |
| PDF | no | yes, a document to hand someone | operator |
| CSV | yes | yes | agent's addition (Excel's plain-text form; Greenfield and Sprind asked for it) |
| SVG / PNG | no | yes | agent's addition (all three consumer projects asked for SVG) |

The operator's set and the consumer projects' set are complementary: the projects asked for SVG/PDF/Mermaid/CSV
(their ranking above); the operator adds Visio and Excel both ways, and Word out. Ordering within the set is the next
proposal (step 5).
