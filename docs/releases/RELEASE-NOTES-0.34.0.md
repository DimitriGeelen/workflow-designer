# Workflow Designer 0.34.0 — release notes

**Since:** `designer-v0.33.0`. Boundary events in a file made in another tool are drawn where that file drew them: on
the same edge of their host and in the same order along it. Until now they all landed on one point at the bottom of
the host, or in one row along its bottom edge. A host carrying more boundary events than its edges hold at the
designer's size is drawn at the size the file gives it, so its events sit apart. Designer-written maps (every AEF map)
save byte-for-byte as in 0.33.0.

## Changes

- **Boundary events keep the file's placement (T-1344).** At import, a boundary event that the file draws on its host
  keeps the edge nearest its centre and its position along that edge. The position is carried as the event's perimeter
  fraction on the host as the designer draws it, kept off the corners. Events the file does not draw keep the earlier
  fallback, spread along the bottom edge. Measured on kitchen-sink and boundary-events: every drawn event on the file's
  edge, in the file's order, no two on one point, and a second save byte-identical to the first.
- **A crowded host is drawn at the file's size (T-1350).** A task or subprocess drawn bigger in the file than its type,
  whose boundary events overflow an edge at the type's size (44 px per event), keeps the file's size, grown further
  if even that is too small. Kitchen-sink's subprocess with 12 boundary events now opens at 150x600 with its events apart
  down both sides; at 120x64 it had 23 overlapping pairs. Every other node keeps its type's size. The size is written to
  the saved diagram and comes back on reopen and on undo.
- **Guards:** browser legs `_t1344` (edge, order, no stacking, second save identical) and `_t1350` (the crowded host's
  size, no overlapping circles, a host that fits gets no size of its own, size kept through save and reparse). The
  third-party byte goldens of kitchen-sink and boundary-events re-recorded deliberately.

## What changes in stored maps

- **Designer-written maps (all of AEF's): nothing.** Same bytes as 0.33.0 (25 of 25 example maps identical).
- **A file another tool wrote, saved by the designer:** each boundary event is written at its file edge and order. A
  host crowded with boundary events is written at the size it is drawn, which is the file's size or larger.

## Not kept yet

Nested lanes (T-1267, deferred), another tool's pool and lane outlines, and drawing a subprocess's contents inside it
on the canvas: they are drawn flat, and the save keeps them nested (0.33.0). The import notice names these when a file
has them.

## For AEF

0.34.0 uses no new endpoint, and nothing you store changes: your maps carry the designer's own boundary positions,
which are left as they are. As of AEF v1.8.16-be.4 the designer endpoints stand as follows:

| Endpoint | Feature (task) | In AEF v1.8.16-be.4 |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker over the field catalog** (T-1312) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
