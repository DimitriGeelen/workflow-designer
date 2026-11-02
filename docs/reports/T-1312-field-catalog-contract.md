# T-1312: `GET /api/field-catalog`, the ref picker's catalog (for AEF inception T-4737, fifth candidate)

The fifth designer data API, in the same form as the four in `docs/reports/T-1300-designer-data-api-contract.md` (whose
"Common rules" apply here too: same origin, JSON, `ok: true|false`, gated by `/api/health`). Proposed by aef-greenfield-test,
which serves its own attribute catalog (`docs/views/nid-attributes.json`, format v1, 1294 rows). Source of truth: 832's
reference server `tools/gallery-serve.py` (`read_field_catalog`) and `src/aef-workflow-designer.html` (`loadFieldCatalog`,
`ioCatalogPicker`), designer 0.30.0 and later.

## What it is for

In the io editor ("▸ edit attributes" on an input or output), under the `ref` field, the designer shows a search over the
project's catalog. A person types words; every word must occur in a row's notation, label or ref; at most 8 hits are listed
(notation, label, dataType). Picking a hit writes `ref`, and writes `dataType` from the row **only when the io has none**
(a producer's own dataType is never overwritten). Nothing else in the map changes.

## Request

`GET /api/field-catalog` — no parameters. **The route takes no input:** which file is served is the server's own setting,
never derived from the request (a query string changes nothing; the reference test asserts it).

## Responses

**200:** `{"ok": true, "catalog": <the file, unchanged>}` where the file is
```json
{"version": 1,
 "attributes": [{"ref": "nid:attr-salesforce-opportunity-id", "notation": "sfdc:Opportunity.Id",
                 "label": "Id (Salesforce Opportunity)", "system": "nid:app-salesforce", "systemLabel": "Salesforce",
                 "entity": "nid:de-opportunity", "dataType": "id", "keyRole": "keyPrimary", "sources": 1}]}
```
Only `ref` (non-empty text) is required per row. `notation`, `label`, `system`, `systemLabel`, `entity`, `dataType`,
`keyRole`, when present, must be text (an empty string is fine). Other keys (`generatedBy`, `count`, `sources`, ...) are
carried through untouched. The designer reads `ref`, `notation`, `label` and `dataType`.

**Value rules (T-1365, designer 0.36.0).** Since 0.36.0 the designer also reads these optional keys and shows them,
read-only, under each io field whose `fieldRef` matches the row's `ref`. They say how a value of the attribute is
built. They are named after SHACL because the producer's rule lives in its ontology as a `sh:PropertyShape` (agreed
with greenfield and AEF, 832 T-1361 / T-1363):

| Key | Shown as | Type |
|---|---|---|
| `datatype` | type (`xsd:` dropped) | text |
| `maxLength` | max length | text or number |
| `pattern` | pattern (ECMA-262), shown as written | text |
| `in` | allowed values | array of text, or one `\|`-separated text |
| `description` | format (plain words) | text |
| `example` | example, marked "made up, shape only" | text |
| `valueSource` / `derivedFrom` | comes from / derived | text |
| `unit` | appended to the type | text |
| `shape` | the rule's id | text |

None is required. A key that is absent is not shown, and a row with none of them shows only the attribute's name.
They are not validated (a wrong type shows as text, or not at all), so the T-1312 refusal rule is unchanged.

**404:** `{"ok": false, "error": "no field catalog"}` — the project has none.

**422:** `{"ok": false, "error": "field catalog refused: <why>"}` — the file exists but is not JSON, has no `version: 1`,
has no `attributes` list, has a row without a text `ref`, or a listed key that is not text. **Refused whole, never
half-served:** a picker offering a wrong subset is worse than none.

## Where the file comes from (reference server)

`--field-catalog PATH` names it (greenfield: `docs/views/nid-attributes.json`, no copy); without the setting,
`<repo>/field-catalog.json`. In AEF the data is AEF's own: whichever catalog your projects keep, in this shape.

## When it fails or is absent

The picker is simply not shown: the `ref` field stays free text and the "use a ref from this map…" picker is unchanged.
Only a 200 with `ok` and an `attributes` array turns it on; a 404, 422, a non-JSON body or no answer leaves today's
behaviour (a network failure is recorded as a fault, `field-catalog:load`). Read-only: nothing is written to the server.

## Cost for AEF, as 832 sees it

| Data it needs | Writes? |
|---|---|
| one JSON file per project (or a generated view of the same rows) | no |

The lowest-risk of the five: read-only, no input, one file.

## Reference tests

| Side | Test |
|---|---|
| Server (HTTP against the reference server) | `tests/test_t1312_field_catalog.py`: 200, 404, each 422, `--field-catalog PATH`, a query string changes nothing |
| Designer (headless Chromium against a server) | `tools/_t1312-catalog-picker-cdp.mjs`: 404 = unchanged; search, 8-hit cap, ref + dataType only when absent, a producer's dataType kept, other steps byte-exact, geometry at 1024/1440 |

Pointing the designer-side test at AEF's server instead of `gallery-serve.py` is the acceptance run.
