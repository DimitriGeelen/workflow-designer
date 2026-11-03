# Workflow Designer 0.39.0 — release notes

**Since:** `designer-v0.38.0`. Data stores are drawn (T-1381), and the authoring kit says plainly which exit code a
project gate refuses on (T-1379).

## Changes

- **Data stores are drawn (T-1381).** A `bpmn:dataStoreReference` and its data associations have been kept on save
  since T-1096 but were not drawn; the 0.38.0 import notice said so (`1 data store (CRM) … not drawn`). Now:
  - **The shape.** Each store is drawn as BPMN draws it: a cylinder with its name, and `[state]` when it has one.
  - **Placement.** It is placed by the rule documents follow since 0.37.0 (T-1369): under the task that writes it (its
    first output association), else the first task that reads it, side by side with that task's documents, in that
    task's lane. The lane grows to hold it.
  - **Links.** Dotted lines with open arrowheads link it to the tasks that write and read it.
  - **Unlinked stores.** A store no task links to is not drawn. The import notice names it:
    `1 data store no task links to (Archive) … in the file and saved back unchanged, but not drawn`.
  - **The import notice** counts drawn documents and data stores together:
    `1 document and 2 data stores drawn under the tasks that make or use them, with 4 links to those tasks`.

  Two layout fixes come with it, for documents too:
  - **Label room.** Shapes under one task now get a slot as wide as their widest label line, so neighbouring labels no
    longer overlap. Before, "Order confirmation" beside "Order book" collided.
  - **Visible arrowheads.** A link to a shape that stands under its own task meets the task's bottom edge beside the
    task's id badge, not in it. Before, the arrowhead of an upward link was hidden in the badge text.

  Guard: leg 225, `tools/_t1381-data-stores-cdp.mjs`.
- **The kit says which exit refuses (T-1379).** AUTHORING.md section 1 and SKILL.md step 8 now state:
  - a project gate refuses on exit 2 (errors), never on any non-zero exit;
  - `--strict` raises only the general map rules (section 4b) and `W-XML-GW-AMBIGUOUS`, so a declared open key
    (`W-XML-IO-MATCH-UNRESOLVED`) stays an honest warning that must not block a publish.

  Section 5's honest end state lists the open key. This came from greenfield's first `--strict` run on 0.38.0, which
  read exit 1 as a refusal.

## What changes in stored maps

- **A map with a data store linked to a task saves with taller lanes, once.** On the first open in 0.39.0 the lane of
  the store's anchor task grows to hold it, and the lanes below move down with their nodes, as for documents in
  0.37.0.
  - The save writes those lane heights and node positions.
  - No id, content, data element or association changes.
  - A reopened save is identical, so nothing grows twice.
  - Where the lane already has room (kitchen-sink), the save is byte-identical to 0.38.0.
- **A map without linked data stores saves exactly as in 0.38.0.**
- The validator is unchanged since 0.38.0. The kit changes only in AUTHORING.md and SKILL.md.

## Not kept yet

Unchanged from 0.38.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- escalation and compensate events draw as plain events;
- the `Mapping:` lines are not checked by the validator, which waits for AEF's mapping vocabulary (T-4991).

Known, not changed here: the opening view fits the whole pool width, so on a pool much wider than its content the names
are small at 1024 and 1440. It is filed for its own task.

## For AEF

**What changes in what you store:** for maps with a linked data store, lane heights and the positions of nodes below a
grown lane, once, on the first save by 0.39.0. Node ids do not change.

**The kit changed** (AUTHORING.md, SKILL.md), so the kit's `SHA256SUMS` moves. `validate-workflow.py` is byte-identical
to 0.38.0's (sha256 88d6a649…, 137965 bytes). The new anchors come with this release's message.

The endpoints as stated at 0.38.0 (your T-5015 check of the table is still open). Please correct anything that has
changed:

| Endpoint | Feature (task) | In AEF (as of 0.38.0) |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
