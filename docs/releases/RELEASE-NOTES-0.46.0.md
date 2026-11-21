# Workflow Designer 0.46.0 — release notes

**Since:** `designer-v0.45.0`. Four fixes to what a person sees, two of them reported by AEF after it took 0.45.0
(T-1471, T-1472) and two from Greenfield's maps (T-1465, T-1470). Nothing a save writes changes.

## Changes

- **The toolbar fits AEF's frame again (T-1471, AEF).** Inside AEF at a 1920 px window the designer's frame is 1894 px
  wide, and 0.45.0's Import and Export menus left Save alone on a second toolbar row. The header buttons are 2 px
  narrower on each side (same text size): one row down to about 1855 px. Guard: `_t1176` (person-sees gate) now
  measures 1894 and requires one row there.
- **The starter map opens readable (T-1472, AEF).** `/designer/app` with no map opened the built-in starter map
  ("investigate") at fit: at 1024 px its text was 2.7 px. It now opens like every loaded map (T-1256):
  at fit unless that draws the smallest map text under 9 px, then larger, from the top-left corner; Fit is one click.
  A map imported into the designer afterwards starts at fit as before. Guard: browser leg `test_t1472_opening_zoom_default`.
- **No flow or flow label on the "+ Add another lane" strip (T-1465).** A loop the router runs under the last lane
  (task-lifecycle "gate failed — rework", task-gate "re-issue" and "agent remediates") was drawn below the pool's edge,
  over the strip, its label on the strip's text. The drawn pool now encloses such a flow and its label (drawn only, like
  the label room added in T-1154); routes are unchanged. Guard: browser leg `test_t1465_label_strip`.
- **Associations between aligned steps stay straight (T-1470, Greenfield).** A dotted association between two steps
  above each other (Greenfield's "Opportunity / Solution – Product" -> "Product", "Open Order" -> "Sales Order") was
  drawn diagonally: moving its arrowhead off the target's id caption (0.45.0, T-1447) moved that end only. The line now
  moves as a whole and stays straight. Guard: browser leg `test_t1470_assoc_straight`.

- **Authoring kit: the calibration maps follow the kit's own rule (T-1477).** The two maps the kit calibrates its
  reviewers on wrote their source quotes with the source's own line breaks, so each raised 5 `W-XML-DOC-PREFIX`
  warnings that AUTHORING.md section 5 does not allow; GLM-5.3 rightly flagged it during this release's calibration.
  Each quote is now one line, its words unchanged; no other finding moved. The kit's guidance is unchanged.

## What changes in stored maps

Nothing. All four changes are drawing or view only: no element, id, name, attribute or waypoint a save writes changes
(byte-identity goldens unchanged).

## For AEF

**What changes in what you store:** nothing.

**What changes in Check (`POST /api/validate`):** nothing.

**What you get without any change on your side:** your two notes on 0.45.0 fixed — Save on the first toolbar row in
your 1894 px frame (T-1471), and `/designer/app` opening its starter map readable at 1024 (T-1472).

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.45.0`.
"Moved" means the 832 artifact changed, not that the contract did: the designer page changed for drawing and view only.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1474: one label pass still follows the zoom at render time (two flow labels on review-emission come within 14 px
  when the map is laid out at 100% instead of fit).
- T-1475: steps at the same x in one lane are numbered in a per-load order (their tie is broken by a random uid), so
  the starter map's stacked "search" steps can show different id captions after a reload.
- T-1469: on a four-line step name the io badge can cover the end of the first line (Greenfield).
