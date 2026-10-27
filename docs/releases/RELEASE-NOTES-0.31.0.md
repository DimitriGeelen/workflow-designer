# Workflow Designer 0.31.0 — release notes

**Since:** `designer-v0.30.0`. Check now reads mapping v1.1's io rules and shows a finding under the io it is about, and
the io rows' req and × are legible and easy to hit (arc-006, T-1242).

## Changes

- **Mapping v1.1 io lint, shown on the io (T-1303).** The validator gains three rules from AEF's mapping v1.1 spec (the
  ones decidable from the map alone):
  - `E-XML-IO-MATCH-MISSING` (ERROR): an io with `operation` update, upsert or delete and no `aef:field role="match"`
    reads as "update / delete every instance".
  - `E-XML-IO-PREFIX-UNDECLARED` (ERROR): a prefix in `fieldRef`, `typeRef` or `conceptRef` (on the io or an `aef:field`)
    that the process-level `aef:prefixes` does not declare. `http`, `https` and `urn` are not prefixes; `ref` is not read.
  - `W-XML-IO-MATCH-UNRESOLVED` (WARN): a match field with neither `fieldRef` nor `path`.
  - Each finding is located on the io: `node '<id>' output[i] "<name>"`. After **Check**, the properties panel shows it
    directly under that io's row (severity, message, rule id), besides the drawer and the canvas marker as before. An io
    removed, moved or renamed since the Check shows nothing. A step without such a finding looks exactly as in 0.30.0.
  - A map that uses none of these attributes (every map saved before mapping v1.1) draws none of them. Saving is never
    refused on a finding.
  - **Guards:** `tests/test_t1303_io_lint.py` (core), validator fixtures, `tools/_t1303-io-findings-cdp.mjs` (browser leg).
- **req and × are legible and easy to hit (T-1310).** On io rows and field rows, `req` and `×` were 2.84:1 against the
  panel and 14 px tall; they are now the panel's label grey (5.58:1) with a 24×24 px hit area. Nothing moved.
- **Authoring kit:** the rule table (`CONFORMANCE.md`) lists the three new rules; the kit is recalibrated on its new bytes.
- **Reference server:** `tools/gallery-serve.py` no longer writes Python bytecode into the tree it serves.

## What changes in stored maps

Nothing. The new rules only report; the designer writes nothing new.

## For AEF

0.31.0 uses no new endpoint. The three new findings appear only where **Check** works, i.e. where `POST /api/validate`
is served; in AEF today Check still says "could not check". The designer endpoints AEF's server does not answer:

| Endpoint | Feature (task) | In AEF today |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), now also under the io (T-1303) | "could not check: HTTP 403" (AEF's CSRF guard) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | picker "instances: n/a" |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | button disabled |
| `GET /api/field-catalog` | **Ref picker over the field catalog** (T-1312) | no picker; free-text ref |

Request and response shapes: 832 `docs/reports/T-1300-designer-data-api-contract.md` (the first four) and
`docs/reports/T-1312-field-catalog-contract.md` (the catalog); AEF inception T-4737. An AEF that serves
`/api/validate` from its own copy of the validator needs the three rules (`tools/validate-workflow.py`,
`XmlValidator._check_io_v11`) for the io findings to appear.
