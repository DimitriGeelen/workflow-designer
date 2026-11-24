# Workflow Designer 0.49.0 — release notes

**Since:** `designer-v0.48.1`. Phases can be edited in the designer (Greenfield's request; the operator's T-1491 GO,
slices A and D): select a phase or a phase row, rename it, write its documentation, delete it; show or hide phases.
Making new phases and moving their boundaries come later (slices B and C, after AEF's tooling carries phases).

## Changes

- **Select and edit a phase (T-1502, slice A).** Click a phase's bracket or name to select it: the panel ("phase")
  shows its Name, its Row and its Documentation, with delete. Click a row's label ("Fase", "Fase in Salesforce") to
  select the row: rename it, see its phases, delete it. Renaming changes the phase's `categoryValue` value (a row: its
  `category` name); documentation is the group's `<bpmn:documentation>`, shown in the panel as blocks (as a step's,
  0.48.0) and edited as text; deleting a phase removes its group, its shape and its value (the row too when it was the
  last), and deleting a row removes its category and all its groups. Each edit rewrites only the element it concerns;
  undo and redo cover it; the Delete key works on a selected phase or row. Phases are not reordered: a phase is a range
  of steps and follows them (T-1461 F4). Deleting a phase leaves its stretch without a phase; widening a neighbour comes
  with moving boundaries (slice C). Guard: browser leg `test_t1502_phase_edit` (A1-A6: real clicks, panel typing,
  undo/redo, the save carries exactly the edits, read back here and by 0.48.1).
- **Show or hide phases (T-1503, slice D).** Settings has a Phases section for the open map: "Show phases" and one
  switch per row; the row panel has "Visible on the map". A hidden row takes no space (the rows above it move down).
  The choice is kept for that map in this browser and never written to the file. Guard: browser leg
  `test_t1503_phase_view` (V1-V5).

## What changes in stored maps

Only maps whose phases someone edits: the edited `bpmn:categoryValue`/`bpmn:category` names, a group's
`bpmn:documentation`, and the groups, shapes and values someone deletes. Nothing else a save writes changes (byte-
identity goldens unchanged; a map whose phases nobody edits saves as before). Showing or hiding phases writes nothing.

## For AEF

**What changes in what you store:** nothing today: none of your 49 maps carries phases, and this release makes no new
phases (that is slice B, after your T-5381 be-tag).

**What changes in Check (`POST /api/validate`):** nothing.

**What you get without any change on your side:** nothing visible until a map carries phases.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.48.1`.
"Moved" means the 832 artifact changed, not that the contract did: the designer page changed (phase editing and view);
the authoring kit and the validator did not change.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1504, T-1505 (phases slices B and C: add phases from the left panel, drag boundaries): after AEF's be-tag for T-5381.
- T-1499: notes above the pool and the phase rows claim the same band (Greenfield).
- T-1495: an io field shows its raw reference where the field catalog has a readable name (Greenfield).
- T-1507: a lane's other-tool attributes and extensions are dropped on save (census T-1506).
