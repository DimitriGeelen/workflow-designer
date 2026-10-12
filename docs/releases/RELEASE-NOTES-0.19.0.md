# Workflow Designer 0.19.0 — release notes

**Since:** `designer-v0.18.0` (2026-10-11) · **Data is no longer lost; new fields by approval.** A map with data
objects and data stores used to lose all of them on the first save — without a word. 0.19.0 keeps them. It also lets
an author suggest that an unknown entry become a field, which becomes one only when the operator approves it, and
fixes a third-party import that wrote a flow pointing at nothing. Minor release: maps with data objects now save
differently (more is kept). Maps without data save exactly as before.

## Data objects and data stores are kept (T-1096)

- **Nothing is dropped any more.** Data objects, data object references, data store references, a task's data
  input/output associations (and the properties and input/output specifications they point at), and the diagram
  shapes and edges that draw them all come back unchanged on save. Before, every one of them was silently removed
  (measured on a test map: none of the data elements, associations or their shapes survived a save).
- **Nothing dangles.** Deleting a task takes its data associations and their edges with it. An association whose
  target is not in the file is left out and named in the import notice — a broken reference is never written.
- **Not drawn yet.** The import notice says how much data is kept and saved back; showing it on the canvas comes later.

## Suggest a field; the operator approves (T-1126)

- Under **"Other extensions"** — data on an element that the designer has no field for — each entry now shows how
  often it appears in the map ("approvalLimit · on 2 of 3 userTask elements") and a **"Suggest as a field"** button.
- A suggestion is **only a record** on the project server. Nothing becomes a field from the designer.
- The **operator** approves or rejects suggestions (`tools/field-suggestion.py`, run through a runme job). An approved
  field is a normal, editable field in that project, marked "approved field", subject to the field settings like any
  other. Values the diagram computes itself (owner, gateway kind) are never offered.
- For a portal of your own: suggestions travel through `GET/POST /api/field-suggestions`; approved fields live in
  the `fields` section of the project's `field-profile.json`. Without them, the button is disabled and says why.

## Fixes

- **A plain task inside a sub-process was dropped on import (T-1131)** while its flows were kept, so the save wrote a
  flow pointing at an element that no longer existed. Such tasks are now imported. A new check scans every
  third-party example's export for references to nothing.

## Authoring kit

Content unchanged from 0.18.0. Re-issued as 0.19.0 beside the artifact with its own calibration record of these exact
bytes (`docs/authoring-kit/calibration-records/0.19.0.yaml`, ledger L16).

## Re-test (Greenfield)

1. Open a map with a data object (e.g. a document passed between two tasks) and a data store; save; reopen the
   saved file in any BPMN tool: the data object, the store, the dotted associations and their positions are there.
   The import notice says "… kept unchanged and saved back, not shown yet".
2. Delete a task that writes to the data store; save: its association is gone, the store remains, nothing broken.
3. Open a map whose elements carry an entry the designer has no field for: under "Other extensions" it shows the
   count and "Suggest as a field" (disabled on your portal unless you add the endpoints — expected).
4. A BPMN file with a plain task inside a sub-process: the task appears after import, and its flows connect to it.
