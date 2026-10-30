# Workflow Designer 0.33.0 — release notes

**Since:** `designer-v0.32.0`. A file made in another tool keeps its subprocess structure: opened and saved, every node
and flow stays inside the subprocess, transaction or adHocSubProcess it was in. Until now a save moved them all up into
the process, so an engine would run a different process (boundary-events.bpmn gained its only start event at the top
level; kitchen-sink.bpmn went from 4 to 16 top-level start events). The canvas still draws nested contents flat; the
saved file keeps them nested. Designer-written maps (every AEF map) save byte-for-byte as in 0.32.0.

## Changes

- **Subprocess nesting is kept on save (T-1339, T-1266 GO slice 1).** Each nested node remembers its innermost
  container at import, and the save writes it inside, with the flows whose two ends share that container. Measured on
  the 4 third-party test files that nest: 23 nested nodes and 6 nested flows, all in the file's container after a save,
  and a second save byte-identical to the first. The validator (`tools/validate-workflow.py`) now walks into
  containers; a nested node in no lane is not reported as unassigned (Camunda Modeler lists none in the lanes).
- **Edits keep the file valid (T-1345, slice 2).** A sequence flow that would cross a subprocess boundary is refused,
  by the connect gesture and by dragging a flow's end, with a message naming both nodes and their containers.
  Deleting a subprocess keeps its contents: they move to the subprocess's own container, a message says how many and
  where, and undo restores them. Dragging a nested node, or moving it to another lane, leaves it in its subprocess; a
  node added from the palette is never nested. Deleting several selected nodes at once can now be undone (it recorded
  no undo step before).
- **A task inside a transaction or adHocSubProcess is no longer dropped (T-1337).** Only `subProcess` contents were
  read; a plain `bpmn:task` (or sendTask …) inside the other two kinds was lost on import while its flows were kept.
- **Boundary events stay put across a reopen (T-1342).** An attached boundary event is placed on its host when the file
  is read, as every render already did; a reopened file no longer moved it or renumbered the boundary events' ids, and
  the import notice no longer counted it as "moved back into place".
- **The import notice** now says nested contents are "drawn at the top level of the canvas — on save they stay inside
  their subprocess" (it said the nesting was NOT kept).
- **Guards:** browser legs `_t1339` (round-trip of the 4 nesting files, second save identical), `_t1345` (the edit rules,
  real mouse events), `_t1131` (a task in a transaction and in an adHocSubProcess); core legs `_t1327 --phrases` (notice
  wording), `test_t1339_validator_nesting`. T-523's nesting pin re-measured (`nesting-round-trips-intact`). The
  third-party byte goldens re-recorded deliberately (the 4 nesting files: nesting; kitchen-sink and boundary-events:
  boundary events on their hosts).

## What changes in stored maps

- **Designer-written maps (all of AEF's): nothing.** Same bytes as 0.32.0 (24 of 24 corpus maps identical).
- **A file another tool wrote, saved by the designer:** nodes and flows inside a subprocess, transaction or
  adHocSubProcess are now written inside it, not at the process level. A boundary event's position is its host's edge.

## Not kept yet

Nested lanes (T-1267, deferred), another tool's pool and lane outlines, and another tool's placement of boundary
events on their host (T-1344: they are placed by the designer, and several on one host can overlap). The import notice
names the first two when a file has them.

## For AEF

0.33.0 uses no new endpoint. **New for your importer:** a third-party file saved by the designer can now carry flow
nodes and sequence flows inside a `bpmn:subProcess`, `bpmn:transaction` or `bpmn:adHocSubProcess`. Your maps never do
(your subProcess is the childless collapsed form, T-523's pin), so nothing you store changes; a file someone opens in
the designer from another tool and hands to you would. As of AEF v1.8.15 the designer endpoints stand as follows:

| Endpoint | Feature (task) | In AEF v1.8.15 |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker over the field catalog** (T-1312) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
Design of the nesting change: `docs/reports/T-1266-subprocess-nesting.md`.
