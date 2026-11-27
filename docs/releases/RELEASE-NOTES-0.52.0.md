# Workflow Designer 0.52.0 — release notes

**Since:** `designer-v0.51.0`. Two changes. A map can now say whose it is (`scope`, agreed with AEF), and the designer
keeps that mark when it saves. A deep link to one version of a map opens that version, whether or not the `load` value
is encoded.

## Changes

- **A map says whose it is: `aef:workflowMeta/@scope` (T-1528; decided in T-1519, agreed with AEF).**
  - `framework`: the process belongs to the framework and ships to every project that vendors it.
  - `project`: the process belongs to the project whose repository holds it, and does not ship.
  - **Absent is read as `project`**, so an unmarked map does not ship.
  - **Designer:** reads and writes `scope` (right after `kind`, only when set). The workflow panel (nothing selected)
    has a **Scope** select under Kind. Its options say what each does ("framework — ships to every project",
    "project — this project only", unset). A change is one undo step. A value outside the two is kept as is and
    shown.
  - **Before:** the designer did not read the attribute, so **0.51.0 and every earlier designer drop `scope` when they
    save a map.**
  - **Validator:** a value other than `framework` or `project` is a **warning**: `W-XML-WORKFLOW-SCOPE` on BPMN,
    `W-WORKFLOW-SCOPE` on the YAML form. Absent and both legal values give no finding. The YAML bridge carries `scope`.
  - **Authoring kit:** AUTHORING 6 says how to mark a map's scope. The rule summary lists the values.
  - **Guards:**
    - Browser leg `test_t1528_workflow_scope` (S1-S4: an unmarked map saves byte-identically to 0.51.0; both values
      survive open and save; the select sets, undoes and clears; a bad value is kept and warned on). 0.51.0 fails
      S2-S4.
    - Warning fixtures for both forms.
- **A deep link opens the version it names, encoded or not (T-1521).** `?load=/api/version?id=M&v=1` written without
  encoding the `load` value opened the latest version, with no error, because the page read only `load`.
  - Now a page `v` is carried into an `/api/version` load that has no `v` of its own. A `load` that has its own `v`
    keeps it.
  - The same source is used for the fetch and the autosave identity.
  - Encoding still works and is still recommended.
  - Guard: browser leg `test_t1521_deeplink_version` (V1-V5). 0.51.0 fails V1 and V5.

## What changes in stored maps

- **A map someone marks with Scope:** its `aef:workflowMeta` gains `scope="framework"` or `scope="project"`.
- **A map that already carries `scope`** (written by a script or by hand): it now keeps it on save. Before, the
  designer removed it.

Nothing else changes. A map without `scope` saves byte-identically to 0.51.0 (S1), and the byte-identity goldens are
unchanged.

## For AEF

**What changes in what you store:** only what you mark. You plan to mark your framework maps `scope="framework"` once
you serve 0.52.0, and to ship your vendor filter and its test with this pickup (msg 56a0436f, your T-5415). Mark only
in 0.52.0 or later, or with a script: an older designer drops the mark on save.

**What changes in Check (`POST /api/validate`):** one new warning, `W-XML-WORKFLOW-SCOPE`, on a `scope` value other
than `framework` or `project`. Nothing else in the validator changed. The validator-refusal mapping (your T-5189
artifact, pinned by 832 under T-1425) gains the two scope codes, `prevents: []`, `design_only: true`. Its pin moves
from 713cb005 to edc34c1d. Nothing else in it changed.

**What you get without any change on your side:** deep links with an unencoded `&v=` open the version they name. Your
0.51.0 pickup (T-5419) can take 0.52.0 directly.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.51.0`.
"Moved" means the 832 artifact changed, not that the contract did. In this release, all three changed:
- the designer page (scope read, write and select; the deep-link version);
- the authoring kit (AUTHORING 6);
- the validator (the scope warning).

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | yes |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | yes |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1514: phase boundaries do not yet follow steps that move (Clean layout, dragging a step).
- T-1517: an exported picture's file name can carry another version's number (AEF).
- T-1518: in Focus mode, Fit whole diagram cannot be clicked normally (AEF).
- T-1522: `Screen:` and `Master:` documentation lines are shown under Notes, not as their own blocks.
- T-1495: an io field shows its raw reference where the field catalog has a readable name (Greenfield).
- T-1507: a lane's other-tool attributes and extensions are dropped on save.
