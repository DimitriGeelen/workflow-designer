# Workflow Designer 0.35.0 — release notes

**Since:** `designer-v0.34.0`. A validator release: `validate-workflow.py` (shipped in the authoring kit, and behind the
designer's Check) accepts the plain BPMN 2.0 task subtypes `sendTask`, `receiveTask`, `manualTask` and
`businessRuleTask`, which the designer already imports and saves back unchanged. Until now Check refused them with
E-XML-NODE-TYPE (ERROR): greenfield's map tobe-sales-without-novis drew 7 on its sendTasks. The designer itself is
unchanged apart from its version number.

## Changes

- **The plain task subtypes validate like `<task>` (T-1358).** The reasoning that admitted plain `<task>` (T-970) applies
  to them unchanged: mapping-v1 §3 (O-1) makes the lane the sole authority-of-record for who performs a step, and the
  task type presentational. So each of the four is accepted on the XML side and checked like `<task>`: it counts toward
  its lane's ownership (a lane with no `aef:laneMeta` warns W-XML-LANE-NO-AUTHORITY for it) and toward lane capacity.
  No new rule, no rule removed; nothing changes for maps that never carried these elements.
- **Guards:** `tests/test_xml_node_type_vocab.py` now fails when an accepted task type is missing from either table the
  checks key on (performer or occupancy, the class T-972 and T-975 each repaired once), and validates a fixture with
  all four subtypes end to end (`tests/fixtures/t1358/task-subtypes.xml`: no E-XML-NODE-TYPE, the lane warning counting
  4 tasks).

## What changes in stored maps

- **Nothing.** The designer source is unchanged since 0.34.0 except `APP_VERSION`; every map saves byte-for-byte as in
  0.34.0. Only the validator's verdict on maps carrying the four subtypes changes (an ERROR per node becomes no finding,
  or the lane-ownership WARN where the lane declares no authority).

## Not kept yet

Unchanged from 0.34.0: nested lanes (T-1267, deferred), another tool's pool and lane outlines, and drawing a
subprocess's contents inside it on the canvas (they are drawn flat; the save keeps them nested).

## For AEF

0.35.0 uses no new endpoint and changes nothing you store. **The validator changed**, so the kit anchors move: the new
`validate-workflow.py` sha256 and size come with this release's message. Your `POST /api/validate` (T-4830) wraps it, so
greenfield's Check stops showing the sendTask errors once you serve 0.35.0. As of AEF v1.8.16-be.4 the designer
endpoints stand as follows:

| Endpoint | Feature (task) | In AEF v1.8.16-be.4 |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303) | served |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served |
| `GET /api/field-catalog` | **Ref picker over the field catalog** (T-1312) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served: the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served: button disabled |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.
