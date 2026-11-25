# Workflow Designer 0.50.0 — release notes

**Since:** `designer-v0.49.0`. Phases can now be made and moved in the designer (the operator's T-1491 GO, slices B
and C): add a row of phases from the left panel, split it at the gaps between steps, and drag the edge two phases share.
With 0.49.0's editing (select, rename, document, delete, show or hide), a person can build a map's phases without
another tool. Notes above the pool no longer collide with the phase rows (Greenfield).

## Changes

- **Add phases from the left panel (T-1504, slice B).** A Phases section under Lanes:
  - **Add phase row** adds a row with one phase across the whole pool, selected, so its name is typed in the panel at
    once.
  - **Add phase**, then a click on the map, splits the phase under the click at the nearest gap between steps. A
    dashed line shows where while the pointer moves; Esc leaves the mode. The new phase is selected. With no phases yet,
    Add phase adds the first row.
  - Written as standard BPMN, Greenfield's encoding: a root `bpmn:category` per row, a `bpmn:categoryValue` per phase,
    a `bpmn:group` per phase naming its value, and the group's shape spanning the pool's full height. Nothing `aef:`.
  - Guard: browser leg `test_t1504_phase_add` (B1-B6: real clicks; the starter map and Greenfield's sample with its
    phases removed; read back here and by 0.49.0; a map nobody adds phases to saves as 0.49.0 saves it).
- **Drag a phase boundary (T-1505, slice C).** The edge two neighbouring phases share has a handle (accent bar on
  hover, a resize cursor), on the bracket and, in the first row, along the dashed divider through the lanes.
  - Dragged, the boundary snaps to the gap between steps nearest the pointer, never into a step and never past either
    phase's far end; a dashed line shows where it will land. Steps never move.
  - The save rewrites only the two groups' shape `x`/`width`. One undo step. A press and release without moving
    changes nothing.
  - Only edges two phases share are draggable. A row whose phases do not touch (Greenfield's 'Fase in Salesforce' row
    has 6 px between them) has no handles; a row's outer ends are not dragged in this release.
  - Guard: browser leg `test_t1505_phase_boundary` (C1-C6: real drags on Greenfield's sample and on a row made with
    slice B; read back here and by 0.49.0).
- **Notes clear of the phase rows (T-1499, Greenfield msg ee60b420).** A note placed just above the pool, where the
  phase rows are drawn, is drawn just above the rows, and its lines are routed from where it is shown. Phase names and
  row labels carry a halo in the canvas colour, so a line crossing them leaves them legible. With phases hidden, notes
  are where the file has them. View only: nothing a save writes changes. Guard: browser leg
  `test_t1499_notes_vs_phases` (N1-N5).

## What changes in stored maps

Only maps someone adds phases to or whose boundaries someone drags:

- **Adding phases** appends a root `bpmn:category` with `bpmn:categoryValue`s, `bpmn:group`s with `categoryValueRef`,
  and their `bpmndi:BPMNShape`s (bounds spanning the pool). Ids are new and unique (`Category_<n>`,
  `CategoryValue_<n>`, `Group_<n>`, `Group_<n>_di`).
- **Dragging a boundary** changes only the `x`/`width` of the two groups' `dc:Bounds`.

Nothing else a save writes changes: the byte-identity goldens are unchanged, and a map nobody adds phases to saves
exactly as 0.49.0 saves it (asserted on the starter map and on Greenfield's sample, B6).

## For AEF

**What changes in what you store:** nothing until someone adds phases to one of your maps. You confirmed on
2026-11-25 (T-5408) that none of your 52 stored maps carries a group or a category. A map someone adds phases to gains
the elements above, all standard BPMN, which your corpus support (T-5381, be.64) reads.

**What changes in Check (`POST /api/validate`):** nothing; the validator is unchanged.

**What you get without any change on your side:** the Phases section in the designer you serve.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.49.0`.
"Moved" means the 832 artifact changed, not that the contract did: the designer page changed (adding and moving
phases, notes placement); the authoring kit and the validator did not change.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1513: a lane added below after the phases makes the pool taller than them; after a save and reopen those phases
  are not drawn. Add lanes before phases until it is fixed.
- T-1514: boundaries do not yet follow steps that move (Clean layout, dragging a step).
- T-1515: deleting a phase leaves its stretch without a phase; its neighbour does not take it yet.
- T-1517: an exported picture's file name can carry another version's number (AEF).
- T-1518: in Focus mode, Fit whole diagram cannot be clicked normally (AEF).
- T-1521: `?load=/api/version?id=X&v=N` written unencoded opens the latest version; encode the `load` value.
- T-1522: `Screen:` and `Master:` documentation lines are shown under Notes, not as their own blocks.
- T-1495: an io field shows its raw reference where the field catalog has a readable name (Greenfield).
- T-1507: a lane's other-tool attributes and extensions are dropped on save.
