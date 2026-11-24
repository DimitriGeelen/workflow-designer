# Workflow Designer 0.48.1 — release notes

**Since:** `designer-v0.48.0`. A patch with one fix: phases no longer disappear after a map is saved in the designer and
opened again. Nothing a save writes changes.

## Changes

- **Phases survive a save and reopen (T-1510).** In 0.47.0 and 0.48.0 a map with phases, saved in the designer and
  opened again, drew no phases (11 → 0 on Greenfield's sample); the groups and categories stayed in the file. A group
  counts as a phase when it spans the pool's full height (T-1461 F3); the designer's own save writes no pool or lane
  outline, so on reopen there was nothing to measure against. A file without a pool or lane outline is now judged
  against the band its steps occupy. Files with a pool outline are judged as before, so a box around a few steps
  (bpmn.io's groups) is still not a phase. Guard: legs P9 (save → reopen twice keeps the 11 phases at the same x
  ranges) and P10 of `test_t1473_phases`.

## What changes in stored maps

Nothing. The fix is in how a file is read; byte-identity goldens unchanged.

## For AEF

**What changes in what you store:** nothing.

**What changes in Check (`POST /api/validate`):** nothing.

**What you get without any change on your side:** none of your 49 maps carries phases, so nothing visible; maps that
carry phases keep them drawn after a save in the designer.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.48.0`.
"Moved" means the 832 artifact changed, not that the contract did: the designer page changed in how it reads phases
only; the authoring kit and the validator did not change.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1502, T-1503 (phase editing, slices A and D), in progress; slices B and C wait for AEF's be-tag carrying T-5381.
- T-1507: a lane's other-tool attributes and extensions are dropped on save (from the save census, T-1506).
- T-1499: notes above the pool and the phase rows claim the same band.
