# Workflow Designer 0.45.0 — release notes

**Since:** `designer-v0.44.0`. Two more import/export steps: Excel both ways (T-1442) and PDF that stays readable for
wide maps, on A3 or across A4 pages (T-1446). Imported text annotations and their associations are now drawn (T-1447:
Greenfield's workshop notes). With instances loaded, each step shows how many sit on it (T-1438). Routing: two of
Greenfield's layout findings are fixed (T-1456: a loop through a foreign lane and two arrowheads on one point; T-1457:
an incoming and an outgoing line side by side on one side).

## Changes

- **Excel (.xlsx), both ways (T-1442).** Export → Excel writes a sheet "Steps" with the CSV columns (`id, name, type,
  lane, next, next_labels, lane_code, lane_authority, uid`), header bold and frozen. Import → Excel reads that sheet,
  or a workbook a person made or re-saved in Excel or LibreOffice: the sheet named "Steps", else the first sheet whose
  first filled row has an `id` column; shared strings, numbers and sparse cells are read. A file that is not a
  workbook (or an old `.xls`), or has no `id` column, is refused with the reason, and the open map is unchanged. The
  import route and its notice are CSV's. Built on a small zip reader/writer inside the page (no library). Guard:
  browser leg `test_t1442_excel` (an independent reader and openpyxl read the export; a LibreOffice-saved fixture).
- **PDF: one page A4, one page A3, or readable A4 pages (T-1446).** "PDF, one page" A4 is unchanged. "PDF, one page"
  A3 prints the same on A3. "PDF, readable pages" A4 cuts a wide map into parts so the smallest step name prints at
  8 pt or more (measured on all 24 corpus maps); parts end between steps, or overlap so a step cut by a page edge
  prints whole on the next page; each page says "page k of N (row, column)". Guard: browser leg
  `test_t1446_pdf_pages` (text size measured in the PDF itself).
- **Text annotations and associations are drawn (T-1447).** Read-only, under the flows and steps: an imported note's
  text and its dotted association line, the line's ends kept clear of captions and badges. They were already kept and
  saved back; now they are visible. Groups (`bpmn:group`) are still kept and saved back unchanged, not drawn.
- **Instance counts (T-1438).** With instances loaded and none selected, each step holding instances shows "● N"; the
  picker's tooltip says how many of them are on a step.
- **Routing (T-1456, T-1457; Greenfield findings 6 and 7).** A loop between steps of one lane stays in that lane when
  a route inside it cuts no step; a loop's bar does not run on, or right beside, another flow's line; where incoming
  and outgoing ends meet on one side of a step they keep at least an arrowhead's gap, and a flow that runs straight
  stays straight. On the corpus, a handful of drawn flows change (none that was straight bends); the saved ones are
  listed below.

## What changes in stored maps

- **The bends of re-routed flows, when a designer-drawn map is saved.** A map's stored bends equal the designer's own
  routing when the designer drew it, so saving it writes the new routing for the flows above. On the 24 corpus maps
  that is **14 edges on 5 maps**, waypoint coordinates only (no element, id, name or attribute changes):
  promotion-pipeline `flow_6`, `flow_7`; release-pipeline `flow_13`, `flow_14`, `flow_15`, `flow_17`; session-capture
  `flow_4`, `flow_6`; task-gate `flow_13`, `flow_14`; task-lifecycle `flow_6`, `flow_9`. Measured by saving every
  corpus map before and after; the byte-identity guards name exactly these and still compare every other byte.
- **Maps made in another tool** keep their own bends on save, as before.
- Everything else saves byte-identically to 0.44.0.

## Not kept yet

Unchanged from 0.44.0, minus annotations (now drawn):
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- escalation and compensate events draw as plain events;
- groups (`bpmn:group`): kept and saved back, not drawn (phases across a map: inception T-1461);
- Mermaid, CSV and Excel import: positions, gateway conditions and step details (named in the import notice).

## For AEF

**What changes in what you store:** when one of your designer-drawn maps is saved again, the bends of the re-routed
flows move (coordinates only); for the corpus maps, the 14 edges listed above. Nothing else.

**What changes in Check (`POST /api/validate`):** nothing.

**What you get without any change on your side:** Excel in and out, PDF on A3 or as readable A4 pages, drawn
annotations, instance counts per step with `/api/instances`, and the routing fixes.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.44.0`.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

Row 1 moved because the page changed (Excel and PDF exports; the procedure export's bends for re-routed flows, listed
above). Rows 2 and 3 did not move: the authoring kit and the validator are unchanged since 0.44.0. Row 4: the overlay
gains the instance counts (T-1438). Row 5: the page changed; save/export stays proposal-only.
