# Workflow Designer 0.32.0 — release notes

**Since:** `designer-v0.31.0`. Opening a file made in another tool (Camunda, bpmn-js, Bizagi, Zeebe …) and saving it no
longer strips or rewrites what the designer does not model. Measured on one unedited save of the 11 third-party test
files: 394 items lost before (T-1322's census), 11 after (deliberate exclusions, and one empty `conditionExpression`;
`docs/reports/T-1322-evidence/classify-losses.py`). Designer-written maps (every AEF
map) save byte-for-byte as in 0.31.0.

## Changes

- **What the designer does not read is kept and written back in place (T-1325, T-1326, T-1268, T-1265).** Per element:
  unknown attributes (standard and other tools'), unknown child elements, other tools' extensions and unknown `aef:*`
  children; a gateway's `default` flow follows the flow's current id. Per process, collaboration and file: their own
  attributes, documentation and extensions, categories, and the text annotations, groups and associations with their
  diagram shapes. A flow keeps its `conditionExpression` `language` and `id`.
- **XML comments are kept (T-1327),** each before the element that followed it.
- **The file's own identity is kept (T-1262, T-1270).** Definitions id, `targetNamespace`, collaboration id, process id
  and `isExecutable` (absent stays absent) are written as the file had them; a Camunda process keeps its deployment key.
  Opening a second file with the same process id no longer gives it `_v2` ids in the saved file (the designer's own map
  id still takes `_v2`, so "Save to project" cannot overwrite the first). A file with no participant gets a pool id of
  its own (`Pool_<id>`) instead of reusing the process id.
- **Original ids are recorded (T-1261).** An element that arrives without `aef:uid` keeps the designer's display id and
  records its original id as `<x832:origin originalId="…"/>` in its `extensionElements`, namespace
  `urn:832-workflow-designer:origin:1` (fixed; match it by URI). Written once, never replaced. Chosen with AEF.
- **Another tool's diagram geometry is kept until a shape moves (T-1264).** Shape sizes, labels, `isMarkerVisible`,
  diagram ids and edge waypoints are written as the file had them for every shape neither the person nor the import
  moved, and for lines between such shapes. A moved shape and its lines are redrawn as before.
- **Node order as the file declares it (T-1271),** in the process and in each lane.
- **Unique ids (T-1102).** Nodes in no lane (events inside a subprocess) no longer take a lane's prefix: kitchen-sink
  saved two end events with one id. Their prefix is now made unique against the lanes'.
- **The import notice says what a save still does not keep (T-1327, T-1264):** subprocess nesting (contents are saved at
  the top level), nested lanes (saved as top-level lanes), and another tool's pool and lane outlines; it also lists
  what is kept but not drawn (annotations, groups, data objects). It shows only for a file another tool wrote.
- **Guards:** browser legs `_t1265`, `_t1268`, `_t1325`, `_t1326`, `_t1327`, `_t1271`, `_t1262`, `_t1261`, `_t1264`,
  `_t1102`; the third-party byte goldens (`tests/goldens/third-party`) re-recorded deliberately at each step, every
  changed line checked.

## What changes in stored maps

- **Designer-written maps (all of AEF's): nothing.** Same bytes as 0.31.0.
- **A file another tool wrote, on its first save:** it keeps far more of itself than before (above); its elements gain
  `aef:uid`, as before, and now also `x832:origin` with the original id.

## Not kept yet

Subprocess nesting (T-1266, an open inception), nested lanes (T-1267, deferred), another tool's pool and lane
outlines. The import notice names each when a file has it.

## For AEF

0.32.0 uses no new endpoint. As of AEF v1.8.15 the designer endpoints stand as follows:

| Endpoint | Feature (task) | In AEF v1.8.15 |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker over the field catalog** (T-1312) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
