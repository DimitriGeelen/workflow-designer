# Workflow Designer 0.28.0 — release notes

**Since:** `designer-v0.27.0`. The attributes of an input or output can now be edited in the properties panel (arc-006,
slice 2 of T-1242). A save writes exactly the edit.

## Changes

- **The io attributes are editable (T-1301).** Under each input/output row, an "▸ edit attributes" toggle opens an editor.
  It is closed by default, so the read-only summary stays exactly as in 0.27.0 until someone edits.
  - **Controls:** ref, fieldRef, typeRef, schemaRef, conceptRef (wrapping text fields that grow with the value, so a long
    IRI is shown whole); role (read | write | create | match | delete); operation (read | create | update | upsert |
    delete); cardinality (one | optional | many); sourceSystem on inputs, targetSystem on outputs; and dataType (text,
    informational). A producer's own value in a dropdown is kept as an extra option, never rewritten.
  - **Editing:** a change replaces the value in place, a new attribute is appended after the existing ones, and an
    emptied control removes the attribute. Editing never adds `mappingVersion` or `aef:prefixes`.
  - **Help:** "use a ref from this map" offers the refs already used in the map. A fieldRef, typeRef or conceptRef whose
    CURIE prefix the map does not declare shows a hint (the full v1.1 lint is slice 4, T-1303).
  - **Guard:** `tools/_t1301-io-edit-cdp.mjs` (legs a-h; browser tier). It sets and clears each attribute through its own
    control and checks the saved item changed in exactly that attribute.
- **Fix: an attribute added to an io in "raw layout" was dropped on save (T-1301).** An io whose attribute order differs
  from the designer's own (aef-greenfield-test writes `type` before `name`, each io block on one line) is written back in
  its own order. An attribute added to such an item was not in that order list, so the save silently left it out. It
  is now appended.

## What changes in stored maps

Nothing, unless you edit. A map opened and saved without an edit keeps its `aef:io` bytes. An edited step's `aef:io`
block is written in the designer's layout (one item per line). The edited item keeps its attribute order and gains or
loses exactly the attribute you changed. Other steps keep their bytes.

## For AEF

0.28.0 needs no new endpoint; the edits save through `/api/save`, which AEF serves. The designer endpoints AEF's server
does not answer are unchanged, so these features stay off in AEF:

| Endpoint | Feature (task) | In AEF today |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962) | "could not check: HTTP 403" (AEF's CSRF guard) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | picker "instances: n/a" |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | button disabled |

Request and response shapes: 832 `docs/reports/T-1300-designer-data-api-contract.md` (AEF inception T-4737).
