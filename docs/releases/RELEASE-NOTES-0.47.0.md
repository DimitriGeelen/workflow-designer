# Workflow Designer 0.47.0 — release notes

**Since:** `designer-v0.46.0`. Phases are drawn (Greenfield's request, T-1461 GO, slice 1), and five fixes to what a
person sees, three of them from Greenfield's maps. Nothing a save writes changes, except the uids of a starter map
saved fresh (T-1475, below).

## Changes

- **Phases drawn from the file (T-1473, Greenfield).** A map whose `bpmn:group`s point at the values of a
  `bpmn:category` and span the pool's full height now shows them as phases, read-only: the first category in the file
  is row 1, a named bracket per phase above the pool and a dashed divider through all lanes at each boundary; every
  further category is a row of brackets above it, with no dividers (Greenfield's 'Fase' and 'Fase in Salesforce').
  A name wider than its bracket is trimmed, the full name in a tooltip; phase names count toward the opening zoom's
  readable floor. Groups that do not span the pool (a box around a few elements, as bpmn.io draws them) are not
  phases and stay kept and undrawn, as before (T-1461 F3). The import notice no longer lists drawn phases as "not
  shown yet". Editing phases is a later slice (T-1491, an open question for the operator). Guard: browser leg
  `test_t1473_phases` (P1-P6), on Greenfield's sample `tests/fixtures/greenfield/ws-otb-fasen-voorbeeld.bpmn`.
- **The io badge no longer covers a step's name (T-1469, Greenfield).** On a four-line name ("Opportunity – Solution
  (doorgestreept) – onder water") the "1→1" badge sat on the end of the first line. When a name line meets it, the
  badge now moves up onto the step's top edge; otherwise it stays where it was. Guard: browser leg
  `test_t1469_io_badge_clear`.
- **Flow labels take the same places at every zoom (T-1474).** Node names, id captions and io badges are now measured
  unhinted, as flow labels already were, so the label placer sees the same boxes whatever the zoom at render time
  (16 corpus labels used to move between fit, 100% and 200%). One label moves for good: review-emission's "not found"
  now sits right of its drop, clear of the gateway's "Task file found?". Guard: browser leg
  `test_t1474_label_places_zoom_free`. **Open with the operator:** at 1024 px with the side panel open that label sits
  past the visible canvas edge (only "not" shows; 0.46.0 showed "not fou"); the reviewer met 1440 and 1920 and
  escalated the 1024 case as a direction question.
- **The starter map numbers the same on every load (T-1475).** Its steps' uids came from a random number, so steps at
  the same x in one lane could swap display ids between loads. They are now derived from the starter's own ids.
  Guard: browser leg `test_t1475_starter_ids_stable`.
- **A plain task is headed 'task' in the properties panel (T-1494, Greenfield).** A `bpmn:task` was headed
  'serviceTask', the designer's internal stand-in, while the canvas captioned it "(task)". The save was already right
  (it writes `bpmn:task` back). Guard: browser leg `test_t1494_plain_task_title`.
- **The Lane field shows lane names (T-1493, Greenfield).** It listed lane ids (Lane_Salesforce) where the canvas shows
  names (Salesforce); it now shows the names and still stores the id; two lanes sharing a name are told apart by id.
  Guard: browser leg `test_t1493_lane_names`.

## What changes in stored maps

Nothing a save writes for an existing map: every change is drawing, view or panel text only (byte-identity goldens
unchanged; the phases save byte-identical with the layer suppressed, leg P3). One difference for new maps: a map
started from the built-in starter and saved now carries uids derived from the starter's ids instead of random ones
(same form, `n_…`/`e_…`; T-1475). Maps already saved keep the uids they have.

## For AEF

**What changes in what you store:** nothing for existing maps; a fresh starter map's uids are deterministic (above).

**What changes in Check (`POST /api/validate`):** nothing.

**What you get without any change on your side:** phases drawn on maps that carry them; flow labels that no longer
shift with the zoom; the starter map's ids stable across reloads; the panel naming plain tasks and lanes as the file
does.

The endpoints, unchanged since 0.44.0 (as you confirmed them: msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884); recorded route from projection v2 (T-1428); counts per step (T-1438) | served (your T-4831, T-5193) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

## Shared contracts

`tools/_t1425-shared-contracts.py --check` (a core leg) holds the last column to what moved since `designer-v0.46.0`.
"Moved" means the 832 artifact changed, not that the contract did: the designer page changed for drawing, view and
panel text only; the authoring kit and the validator did not change.

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | yes |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | no |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | no |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | yes |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | yes |

## Known, filed

- T-1474 (above): the 1024 case of the moved "not found" label is with the operator.
- T-1496: when the canvas is scrolled right, the pinned lane header covers the steps that scroll under it (present
  in 0.46.0; found by the reviewer on T-1469).
- T-1492: a step's `bpmn:documentation` (Greenfield's Instruction/Rule/Keys/… lines) is kept and saved back, but not
  yet shown in the panel (Greenfield).
- T-1495: an io field shows its raw reference where the field catalog has a readable name (Greenfield).
