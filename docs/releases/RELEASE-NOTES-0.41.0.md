# Workflow Designer 0.41.0 — release notes

**Since:** `designer-v0.40.0`. A file that declares no lanes or no pool is no longer given ones it never had (T-358),
and an `<aef:eventDef>` keeps what the designer does not read (T-347).

## Changes

- **No invented lanes (T-358, operator ruling 2026-11-08).** Opening a BPMN file that declares no lanes used to add the
  designer's three lanes, "Human · Sovereignty", "Framework · Authority" and "Agent · Initiative", and put every node
  in the first. Saving then wrote `authority="sovereignty"` for every step of a file whose own tool never said so.
  Now:
  - **On opening.** The map has no lanes.
  - **On saving.** No `<bpmn:laneSet>` is written. While the map still has no lanes, `aef:workflowMeta` carries
    `laneProvenance` (`defaulted:no-laneset`, `defaulted:empty-laneset` or `defaulted:later-laneset-ignored`), which
    the next open reads back. Once a person adds a lane the map is authored and the marker goes.
  - **On the canvas.** A pool with no lanes encloses its whole diagram, and the strip below it reads "+ Add a lane".
  - **The authority summary** says such a map declares no authority, which is now true of what it shows.

  Guard: browser leg 227, `tools/_t358-laneless-render-cdp.mjs` (every lane-less third-party fixture at
  1024/1440/1920).
- **No invented pool (T-358, operator ruling 2026-11-09).** A file that declares no `<bpmn:participant>` used to save
  with a `<bpmn:collaboration>` and a participant the designer added. Now:
  - **The collaboration is not written,** unless the file's own content needs it (another process, a message flow, an
    artifact).
  - **The marker.** `aef:workflowMeta` carries `poolProvenance="defaulted:no-participant"`, read back on open. Where
    the collaboration must still be written (a file with two processes), the marker says the pool was the designer's.
  - **The canvas** still shows one pool frame. Only what is saved changes.
- **The validator (T-358).** A process with no `<bpmn:laneSet>` is no longer reported as `E-XML-LANES-EMPTY`: it declares
  no partition, which is a valid map. A `<bpmn:laneSet>` with no lane in it is still an error. Such a file can still be
  reported for its nodes (`E-XML-NODE-UNASSIGNED`: in no lane, so no authority-of-record). That rule is unchanged.
- **`<aef:eventDef>` keeps what it carries (T-347).** It was read for `kind` and `binding` and written back with only
  those two. Any other attribute (foreign namespaces included) or child was lost on one unedited save, on start events
  and on typed catches. Both are now kept and written back while the event keeps its kind; a retype to another kind
  writes kind and binding alone.

## What changes in stored maps

- **Maps this designer saved before keep their lanes and pool, byte for byte.** Every map in AEF's corpus declares its
  lanes and its participant; all 24 save byte-identically to 0.40.0.
- **A file that declares no lanes or no pool changes on its first save in 0.41.0.**
  - This covers a third-party file, and a map written by the YAML bridge (`tools/yaml-to-bpmn.py`), which writes no
    participant.
  - The save no longer contains the three invented lanes and their `flowNodeRef`s, nor the invented collaboration and
    participant, and the pool's diagram shape is as tall as its content.
  - It gains `laneProvenance` and/or `poolProvenance` on `aef:workflowMeta`.
  - No node id, flow or other element changes, and a second save is identical.
- **An `<aef:eventDef>` with extra content** keeps it. One without (every map the designer wrote) is unchanged.

## Not kept yet

Unchanged from 0.40.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- escalation and compensate events draw as plain events;
- the `Mapping:` lines are not checked by the validator, which waits for AEF's mapping vocabulary (T-4991).

Known, filed: a node a file places left of the pool's fixed left edge is drawn across the border, with or without lanes
(T-1386; the same in 0.40.0).

## For AEF

**What changes in what you store:** only for a map whose file declared no lanes or no participant, on its first save
by 0.41.0. The invented `Human · Sovereignty` / `Framework · Authority` / `Agent · Initiative` lanes and the invented
collaboration are no longer written, and `aef:workflowMeta` gains `laneProvenance` and/or `poolProvenance` (both
attributes of our own element, inside `bpmn:extensionElements`). Node ids do not change. Maps the designer saved
before, including your corpus, are byte-identical. If you store a lane-less map that a 0.40.0 save gave three lanes,
it keeps them until someone re-imports the original file.

**What changes in Check (`POST /api/validate`):** `validate-workflow.py` changed (sha256 1edc2d7f…, 138405 bytes). A
process with no `<bpmn:laneSet>` no longer raises `E-XML-LANES-EMPTY`; nothing else in the validator changed. The
kit's `SHA256SUMS` moves with it. The new anchors come with this release's message.

The endpoints as you confirmed them on 2026-11-08 (msg adadee0b):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
