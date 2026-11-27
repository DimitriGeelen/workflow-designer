# Workflow Designer 0.53.0 — release notes

**Since:** `designer-v0.52.0`. One change: phase boundaries follow the steps when steps move. This lifts the known limit
listed in the 0.51.0 and 0.52.0 notes (T-1514).

## Changes

- **Phase boundaries follow moved steps (T-1514; T-1491 design, IW-2).** A phase is a range of steps. An edit that moves
  steps recomputes each phase row's boundaries from the steps each phase held before the edit, in the edit's own undo
  step. Both edits are covered: dragging one step or a group of steps, and Clean layout.
  - **Dragging inside its phase:** the shared edge next to the step moves with it. The edge keeps its place in the gap
    between the two phases' steps, so an authored, off-centre boundary keeps its proportion. Edges whose neighbouring
    steps did not move stay where they were.
  - **Dropping a step in the neighbour phase:** the step joins that phase, and the boundary moves to the new gap.
  - **An edge that two phases do not share** (as in Greenfield's 'Fase in Salesforce' row, 6 px apart) keeps its
    distance to the phase's nearest step. An edge at the pool's edge stays there.
  - **Nothing is guessed:**
    - a row whose steps end up out of phase order is left as it was;
    - so is a phase with no steps, and the edge it shares;
    - so is a result that would overlap or leave a phase under 20 px.
  - **Only the group shapes' `dc:Bounds` `x`/`width` change.** A map nobody edits saves exactly as before.
  - **Guard:** browser leg `test_t1514_phases_follow_steps` (F1-F5 on Greenfield's sample):
    - a drag inside a phase, and a drop in the neighbour phase;
    - Clean layout;
    - no edit changes nothing, and saves read back the same by 0.52.0;
    - out-of-order rows and empty phases are left alone.

    0.52.0 fails F1 and F2.

## What changes in stored maps

- **Maps with phases where someone drags a step or runs Clean layout:** the drawn phases' group `dc:Bounds` `x`/`width`
  follow the steps as described above.

Nothing else changes. The byte-identity goldens are unchanged, and a map nobody edits saves exactly as before (F4).

## For AEF

**What changes in what you store:** nothing. You confirmed on 2026-11-25 (T-5408) that none of your stored maps carries
a group or a category. Your scope markings (T-5415) are untouched.

**What changes in Check (`POST /api/validate`):** nothing; the validator is unchanged since 0.52.0.

**What you get without any change on your side:** phases that stay with their steps, once you author phases.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.52.0`.
"Moved" means the 832 artifact changed, not that the contract did. Here only the designer page changed (the phase
bounds follow steps); the authoring kit and the validator did not.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1517: an exported picture's file name can carry another version's number (AEF).
- T-1518: in Focus mode, Fit whole diagram cannot be clicked normally (AEF).
- T-1522: `Screen:` and `Master:` documentation lines are shown under Notes, not as their own blocks.
- T-1495: an io field shows its raw reference where the field catalog has a readable name (Greenfield).
- T-1507: a lane's other-tool attributes and extensions are dropped on save.
- T-1530: 832's pinned copy of the refusal mapping moves to AEF's file (2307d836) when their be.72 lands.
