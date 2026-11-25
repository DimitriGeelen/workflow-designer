# Workflow Designer 0.51.0 — release notes

**Since:** `designer-v0.50.0`. Three fixes to phases and lanes. Lanes can now be added after phases: 0.50.0's first
known limit ("add lanes before phases") is gone. Adding, deleting and resizing a lane can each be undone. Deleting a
phase hands its range to its neighbour instead of leaving a gap.

## Changes

- **Phases follow the pool (T-1513).** When an edit makes the pool taller (a lane added below, a lane made taller),
  every drawn phase whose shape reached the old pool bottom is stretched to the new one (only its `dc:Bounds`
  `height`), as part of that edit's undo step.
  - Before: a step placed in a lane added below the phases put the saved file's step band below the groups. After a
    save and reopen, no phase was drawn.
  - The stretch never happens when a map is opened or re-rendered without an edit, so a map nobody edits is unchanged.
  - Guard: browser leg `test_t1513_phases_follow_pool` (P1-P4: lanes and steps added after phases on the starter map
    and on Greenfield's sample, read back here and by 0.50.0; a lane-resize drag and its undo; untouched maps
    byte-identical).
- **Lane changes are each one undo step (T-1525).** Adding a lane, deleting a lane and resizing a lane (one step per
  drag; a press without moving records none) can each be undone and redone.
  - Before: none of the three recorded an undo step. Ctrl+Z right after one also undid the action before it.
  - Guard: browser leg `test_t1525_lane_undo` (U1-U4).
- **A deleted phase's range goes to its neighbour (T-1515; T-1491 design step 7).** Deleting a phase (Delete key or
  the panel) widens the neighbour it shares an edge with over its range:
  - the left one;
  - or, for a row's first phase (or when the left one does not touch), the right one.

  Only that neighbour's `dc:Bounds` `x`/`width` change, in the same undo step. A phase that touches no neighbour (as
  in Greenfield's 'Fase in Salesforce' row) leaves its stretch empty, as before. Guard: browser leg
  `test_t1515_phase_delete_neighbour` (D1-D4).

## What changes in stored maps

- **Maps with phases where someone adds a lane or makes one taller:** the drawn phases' group `dc:Bounds` `height`
  grows to the new pool bottom.
- **Maps where someone deletes a phase:** besides what 0.49.0 already removed (its group, shape and value), the
  neighbour's `dc:Bounds` `x`/`width` widen.

Nothing else changes. The byte-identity goldens are unchanged, and a map nobody edits saves exactly as before (P4).

## For AEF

**What changes in what you store:** nothing. You confirmed on 2026-11-25 (T-5408) that none of your stored maps
carries a group or a category, and lane undo changes nothing that is saved.

**What changes in Check (`POST /api/validate`):** nothing; the validator is unchanged.

**What you get without any change on your side:** lane changes that can be undone. Your 0.50.0 pickup (T-5419) can
take 0.51.0 directly.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.50.0`.
"Moved" means the 832 artifact changed, not that the contract did: the designer page changed (phases following the
pool, lane undo, phase delete); the authoring kit and the validator did not change.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1514: phase boundaries do not yet follow steps that move (Clean layout, dragging a step).
- T-1517: an exported picture's file name can carry another version's number (AEF).
- T-1518: in Focus mode, Fit whole diagram cannot be clicked normally (AEF).
- T-1521: `?load=/api/version?id=X&v=N` written unencoded opens the latest version; encode the `load` value.
- T-1522: `Screen:` and `Master:` documentation lines are shown under Notes, not as their own blocks.
- T-1495: an io field shows its raw reference where the field catalog has a readable name (Greenfield).
- T-1507: a lane's other-tool attributes and extensions are dropped on save.
