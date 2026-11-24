# Workflow Designer 0.48.0 — release notes

**Since:** `designer-v0.47.0`. One fix to what a save writes (a data loss), and two things a person sees, all from
Greenfield's maps. Maps whose lanes carry documentation now keep it; nothing else a save writes changes.

## Changes

- **A lane's documentation is kept on save (T-1500, data loss).** The designer never read a lane's
  `<bpmn:documentation>`, so every save in every earlier version dropped it, without a notice. Greenfield keeps a
  lane's owner role there. It is now read as a step's is (text, `id`, `textFormat`) and written back first in the
  lane, in file order. A lane without documentation is written exactly as before. Guard: browser leg
  `test_t1500_lane_docs_kept`.
- **A step's documentation is shown in the panel (T-1492, Greenfield).** Selecting a task, gateway, event or lane
  shows its `bpmn:documentation` in a Documentation section, read-only: one block per line prefix in Greenfield's
  order (Instruction, Rule, Keys, Mapping, Open, Detail, Decision), another short label (a lane's "Owner:") as its own
  block, any other line under Notes; an indented or bulleted line continues the item above it. It is shown under every
  lens. Nothing is written: the documentation is saved back exactly as read. Guard: browser leg
  `test_t1492_documentation_panel`.
- **Phase rows are named (T-1498, Greenfield).** Each phase row shows its category's name at its left ("Fase",
  "Fase in Salesforce"), in a quieter style than the phase names, so a reader can tell the rows apart. Drawing only.
  Guard: leg P7 of `test_t1473_phases`.

## What changes in stored maps

A map whose lanes carry `<bpmn:documentation>` keeps it on save (before, it was dropped). Nothing else a save writes
changes: byte-identity goldens unchanged; the documentation display and the row labels are view only.

## For AEF

**What changes in what you store:** lane documentation, if any of your maps has it, is now kept on save instead of
dropped (asked on our 0.47.0 thread whether any of your 49 maps carries it).

**What changes in Check (`POST /api/validate`):** nothing.

**What you get without any change on your side:** a selected step's documentation readable in the panel; phase rows
named.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.47.0`.
"Moved" means the 832 artifact changed, not that the contract did: the designer page changed (lane documentation kept
on export; documentation and row labels drawn); the authoring kit and the validator did not change.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1499: notes above the pool and the phase rows claim the same band (Greenfield, on 0.47.0).
- T-1495: an io field shows its raw reference where the field catalog has a readable name (Greenfield).
- T-1496: when the canvas is scrolled right, the pinned lane header covers the steps that scroll under it.
- T-1491: editing phases (inception; making phases waits for AEF T-5381).
