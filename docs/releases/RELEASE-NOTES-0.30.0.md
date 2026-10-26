# Workflow Designer 0.30.0 — release notes

**Since:** `designer-v0.29.0`. The `ref` of an input or output can be picked from the project's field catalog, and a new
field lands with the other fields (arc-006, T-1242).

## Changes

- **Pick a ref from the project's field catalog (T-1312).** In an io's editor ("▸ edit attributes"), under the `ref` field,
  a search field ("search catalog…") searches the project's catalog of attributes (`GET /api/field-catalog`; for
  aef-greenfield-test its `docs/views/nid-attributes.json`, format v1).
  - Every typed word must occur in a row's notation, label or ref; at most 8 hits are listed, each with its notation
    (`sfdc:Opportunity.OwnerId`) and below it the label and dataType. More matches say "N more: type more words to narrow".
  - **Picking a hit writes `ref`, and writes `dataType` from the row only when the io has none.** A producer's own
    `dataType` is never overwritten. Nothing else in the map changes.
  - **No catalog, no picker:** when the server answers 404 (or anything but a well-formed catalog) the editor is exactly
    as in 0.29.0: the free-text `ref` field and the "use a ref from this map…" picker.
  - The search survives a re-render of the panel; it is cleared once a hit is picked.
  - **Guard:** `tools/_t1312-catalog-picker-cdp.mjs` (browser leg), against the real reference server.
- **A new field lands with the fields (T-1314).** "+ add field" put the new `aef:field` at the end of the io's children,
  after `aef:example` (found by aef-greenfield-test on 0.29.0). It now goes after the last existing field, or first when
  the io has none, before `aef:expect` and `aef:example`. Guard: `_t1301` legs j3 and j8.
- **Reference server:** `GET /api/field-catalog` (T-1312): the catalog file is the server's setting
  (`--field-catalog PATH`, default `<repo>/field-catalog.json`), never derived from the request; 404 when there is none,
  422 when malformed (refused whole).

## What changes in stored maps

Nothing, unless you edit. A picked ref is an ordinary edit of `ref` (and `dataType` when the io had none); the edited
step's `aef:io` block is written in the designer's layout, changed by exactly the edit.

## For AEF

0.30.0 can use one more endpoint, `GET /api/field-catalog` (read-only, no input). Without it the picker is not shown and
the editor is as in 0.29.0, so nothing changes for AEF until it chooses to serve one. The designer endpoints AEF's server
does not answer:

| Endpoint | Feature (task) | In AEF today |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962) | "could not check: HTTP 403" (AEF's CSRF guard) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | picker "instances: n/a" |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | button disabled |
| `GET /api/field-catalog` | **Ref picker over the field catalog** (T-1312) | no picker; free-text ref, as in 0.29.0 |

Request and response shapes: 832 `docs/reports/T-1300-designer-data-api-contract.md` (the first four) and
`docs/reports/T-1312-field-catalog-contract.md` (the catalog); AEF inception T-4737.
