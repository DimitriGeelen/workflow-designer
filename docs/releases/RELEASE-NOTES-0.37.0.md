# Workflow Designer 0.37.0 — release notes

**Since:** `designer-v0.36.0`. The two builds of 832's T-1363 decision (GO, 2026-11-02), from greenfield's WT-01 sales
process across five systems:
- documents and their state are drawn on the canvas;
- the validator checks a map's io against the project's field catalog.

## Changes

- **Documents are drawn with their state (T-1369).** A `bpmn:dataObjectReference`, with its `bpmn:dataState`, and the
  data associations linking it to tasks were kept on save since T-1096 but never drawn. A reader could not see which
  document a step makes or needs, nor in which state. In WT-01 the signed order confirmation is the binding moment of
  the sale. Now:
  - each document is drawn as BPMN draws it: a page with a folded corner, its name, and `[state]`;
  - it stands centred under the task that produces it (else the first task that uses it), inside that task's lane.
    Several documents under one task stand side by side;
  - dotted lines with open arrowheads link it: from the producing task to the document, and from the document to each
    task that uses it;
  - the anchor task's **lane grows** to hold its documents and their labels (the operator's choice, option 1). The
    lanes below move down with their nodes, keeping their layout.

  The file's own DI position for a data object is not used: all five of WT-01's documents lay outside every lane in its
  DI. Data stores (`bpmn:dataStoreReference`) are not drawn yet. Guard: leg 224, `tools/_t1369-documents-cdp.mjs`.
- **The validator checks io against the field catalog (T-1370).** `tools/validate-workflow.py --field-catalog PATH`
  (catalog contract T-1312, format v1) adds four findings, located like the other io rules, so the designer shows them
  under the io row:

  | Rule | Severity | When |
  |---|---|---|
  | W-XML-IO-FIELD-UNKNOWN | WARN | an `aef:field fieldRef` the catalog has no row for |
  | W-XML-IO-FIELD-ENTITY | WARN | a field whose catalog `entity` is not the io's `typeRef` (an io typed as a message, no catalog entity, is exempt) |
  | E-XML-IO-EXPECT-CONTRADICTS | ERROR | an `aef:expect` const or `aef:value` outside the attribute's `in`, failing its `pattern`, or longer than its `maxLength` |
  | W-XML-IO-EXPECT-REDUNDANT | WARN | an `aef:expect` repeating the attribute's `pattern`, or listing exactly its `in` |

  Unknown and entity are warnings because a catalog can be partial; a contradiction is an error (AEF spec T-4415 C).
  Without `--field-catalog` nothing changes, and an unreadable catalog is a load failure (exit 2). Greenfield's own
  version of the entity check found 15 real modelling errors in WT-01. Guard: `tests/test_t1370_catalog_checks.py`
  (core).

## What changes in stored maps

- **A map with documents saves with taller lanes.** On the first open in 0.37.0, the lane of each task that produces
  (or first uses) a document grows to hold it, and the lanes below move down with their nodes. The save writes those
  lane heights and node positions. Unchanged: no id, no content, no data element or association. A reopened save is
  identical, so nothing grows twice. The DI of tasks that moved is rewritten as for any moved node (T-1264).
- **A map without documents saves exactly as in 0.36.0.**
- The validator change writes nothing. It adds findings only when a catalog is given.

## Not kept yet

Unchanged from 0.36.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested).

Data stores are kept, not drawn. Escalation and compensate events draw as plain events.

## For AEF

**What changes in what you store:** for maps with documents, lane heights and the positions of nodes below a grown lane,
once, on the first save by 0.37.0. Node ids do not change.

**The validator changed**, so the kit anchors move: the new `validate-workflow.py` sha256 and size come with this
release's message. `--field-catalog` is optional. For your Check (`POST /api/validate`) to report the four new
findings, its wrapper would pass the project's field catalog (the file behind `GET /api/field-catalog`). Until then,
the findings come from the CLI and the authoring kit.

The endpoints as stated at 0.36.0. Please correct anything that has changed:

| Endpoint | Feature (task) | In AEF (as of 0.36.0) |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`
(which now also describes the validator side).
