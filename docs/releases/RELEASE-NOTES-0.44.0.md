# Workflow Designer 0.44.0 — release notes

**Since:** `designer-v0.43.0`. Import and export get a named home in the toolbar, and new formats: pictures (SVG, PNG)
and PDF out, Mermaid and CSV in both directions (T-1439, T-1440, T-1441; the first three steps of the import/export
plan the operator approved in T-1093). The instance overlay draws AEF's recorded route (T-1428) and stops promising a
refusal marker it cannot draw (T-1427). The validator's header text is corrected (T-1424).

## Changes

- **Import ▾ and Export ▾ in the toolbar (T-1439).** The unlabelled "Load…" is gone. Import and Export each open a
  short menu that names its formats, starting with **BPMN 2.0 / Camunda**. Import does exactly what "Load…" did;
  Export → BPMN downloads exactly the bytes Save downloads. Keyboard: arrows, Enter, Escape. The menus are built from
  one list, so each later format adds one entry. Guard: browser leg `test_t1439_io_menus`.
- **Export → SVG, PNG 1x/2x/4x and PDF (T-1440).** A **paper version** of the map: white background, dark text, light
  boxes (the operator's choice, 2026-11-19); the screen stays dark. The SVG is self-contained: no remote reference, no
  editor controls. The PNGs are drawn from that SVG at exact sizes. PDF goes through the browser's own print ("Save as
  PDF"): one A4 landscape page with the map's title and the map alone. Guard: browser leg `test_t1440_picture_export`
  (it also checks that the PDF's arrowheads resolve, a defect the reviewer caught). Known limit: a very wide map
  prints small on one A4 page (T-1446, planned).
- **Mermaid and CSV, both ways (T-1441).** Export → Mermaid writes a `flowchart LR`, one subgraph per lane, BPMN shapes
  mapped (event `(( ))`, task `[ ]`, gateway `{ }`), every flow with its label. Export → CSV writes one row per step:
  `id, name, type, lane, next, next_labels, lane_code, lane_authority, uid`. Import reads either, builds BPMN without
  a layout, lays it out with Clean, and **says in the import notice what the format did not carry**: positions (so
  the step numbers in the visible ids follow the new layout), the conditions on flows out of a gateway, each step's
  details (inputs, outputs, roles), and for CSV lanes that hold no step. A round trip keeps the map id, the lanes,
  every step's permanent identity (`aef:uid`), name, type and lane, and every flow. Guard: browser leg
  `test_t1441_text_bridges`.
- **The instance overlay draws the recorded route (T-1428).** When `/api/instances` gives `traversed` (AEF projection
  v2, T-5193), the overlay marks exactly those edges, "×N" on an edge taken more than once, ✓ on their ends; the
  picker says "✓ recorded path" and counts `unmapped` hops. Without `traversed` it is "✓ derived path" as before.
- **The instance picker no longer promises a refusal marker it cannot draw (T-1427).** Refusal rows are kept only
  when they name a `node` and a `rule` or `reason_code`; the ⛔ explanation shows only then.
- **Validator header (T-1424).** `validate-workflow.py` no longer calls its YAML input "AEF-canonical": it is an
  authoring form converted to BPMN. Text only; no rule changes.

## What changes in stored maps

- **Nothing.** Saving writes the same bytes as 0.43.0 (byte-identity goldens, browser tier). The new formats are
  extra exports and imports; BPMN stays the format maps are stored in.

## Not kept yet

Unchanged from 0.43.0, plus what the new bridges state on import:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- escalation and compensate events draw as plain events;
- imported text annotations are kept and saved back but not drawn (T-1447, planned: Greenfield's workshop maps);
- Mermaid and CSV import: positions, gateway conditions and step details (named in the import notice).

## For AEF

**What changes in what you store:** nothing. Maps save byte-identically to 0.43.0.

**What changes in Check (`POST /api/validate`):** nothing in the rules. The validator's header text changed (T-1424).

**What you get without any change on your side:** the Import and Export menus with BPMN, SVG, PNG, PDF, Mermaid and CSV.
Mermaid is the format you asked for docs and task-file Markdown; CSV is Greenfield's and Sprind's flat step list. The
instance overlay reads your projection v2 `traversed` and `unmapped` (your T-5193), and your new
`aef-inception-lifecycle` map (be.60) works with it unchanged: the overlay keys on `aef:uid`.

The endpoints as you confirmed them (msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.43.0`.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | yes |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | yes |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

Row 1 moved because the page changed (new exports); the procedure export itself is byte-identical. Row 3 moved for the
header text only (T-1424). Rows 4 and 5: the page changed; the overlay change is T-1428, save/export is unchanged.
