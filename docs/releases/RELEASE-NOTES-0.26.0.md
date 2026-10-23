# Workflow Designer 0.26.0 — release notes

**Since:** `designer-v0.25.0`. Readability fixes from the T-1241 business-lens review rounds, and a URL entry that
opens the project browser. No change to what the designer stores.

## Changes

- **`?browse=1` opens the project browser on load (T-1282, AEF T-4716).** `/designer/app?browse=1` (or
  `aef-workflow-designer.html?browse=1`) opens the Open-project card browser, with hover-zoom, as soon as
  `/api/health` confirms the project API; picking a card opens that map exactly as Open project does. `?load=` wins
  (the named document opens and the browser stays closed); with no project API it does nothing. Lets AEF route
  Watchtower `/designer` straight to the designer's own browser. Guard: `tools/_t1282-browse-entry-cdp.mjs`.
- **Flow labels keep clear of gateway names; the Note box grows to its text (T-1274).** A flow label no longer runs
  into a gateway name on the other side of its flow, and the side-panel Note box shows every line up to its cap, then
  scrolls. Guard: `tools/_t1274-note-box-cdp.mjs`.
- **No corpus task name is cut short (T-1276).** A long task name wraps at a third, smaller fit step (9 px) inside its
  box instead of ending in an ellipsis; flow labels were measured at 6.1:1 (AA), unchanged. Guard:
  `tools/_t1276-name-fit-cdp.mjs`.
- **Id captions are no longer crossed by arrowheads (T-1277).** The label-clearance pass treats a drawn arrowhead as an
  obstacle like a flow segment (it treated a flow as a zero-width line). Guard: `tools/_t1256-label-clearance-cdp.mjs`.
- **The codex sweep items (T-1278).** Text at the opening zoom is at least 9 px in every class, the Name field shows
  its whole value and keeps typed input, the business lens's palette uses plain words, helper text meets 4.5:1, and
  the canvas and palette scroll to every control. Guard: `tools/_t1278-sweep-cdp.mjs`.

## Validator and authoring kit (T-1284)

- **W-XML-GW-AMBIGUOUS now reads the gateway's default.** It fires on the same condition as before (more than one
  outgoing flow without a `conditionExpression`), but the message now says whether a default flow is declared, and
  names it and the flows that lack a condition. It used to print "at most one may be the default" for every case, so
  a gateway with a correct default read like one with none. During this release's calibration, that wording led a
  reviewer (GLM-5.3) to report a default problem that did not exist; it withdrew the finding on re-check, and codex
  confirmed independently.
- **New W-XML-GW-DEFAULT-NOT-OWN (warning):** an exclusive gateway's `default` must be one of its own outgoing
  flows. Classified CONVENTIONAL (no MUST in mapping-v1 backs it); no corpus map trips it.
- The kit ships this validator, so the kit's bytes changed. The first 0.26.0 calibration (codex PASS, GLM-5.3 FAIL
  on that false finding) is kept in the record as voided runs, and both reviewers calibrated the corrected kit.

## What changes in stored maps

Nothing: every change above is display only, and the guards check saved bytes are unchanged. No node id, field or
finding id changes.

## For AEF (host)

- **`/designer` → `/designer/app?browse=1`** (AEF T-4716): with this release pinned, the route lands in the
  designer's own project browser. No new endpoint is needed: the browser uses `/api/health`, `/api/list` and
  `/api/thumb`, which AEF already serves.
- **Endpoints the designer uses that AEF's server does not answer**, checked against AEF's own Watchtower code at
  v1.8.15-be.8 (`web/blueprints/designer_api.py`, `designer.py`). The designer degrades quietly when they are absent,
  so these features are off inside AEF:

  | Endpoint | Feature (task) | In AEF today |
  |---|---|---|
  | `POST /api/validate` | **Check**: validator findings drawn on the map (T-962) | the Check button shows; checking fails |
  | `GET /api/instances?template=<id>` | **Instance overlay**: where each live task sits on the map (T-884) | picker stays "instances: n/a" |
  | `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | always the designer's default fields |
  | `GET/POST /api/field-suggestions` | **"Suggest as a field"** for an unknown `aef:` key (T-1126) | the suggestion is not recorded |

  The request/response contract of each is in the header of `tools/gallery-serve.py`, 832's reference server.
  Served by AEF already: `/api/health`, `/api/list`, `/api/version`, `/api/versions`, `/api/save`, `/api/delete`,
  `/api/thumb`, `/api/lens-definition`, `/api/overlay`.

## Re-test

1. Open `/designer/app?browse=1`: the Open-project browser is open on load; pick a card and that map opens. Open
   `/designer/app?browse=1&load=<a map URL>`: the map opens and the browser stays closed.
2. Open `aef-task-lifecycle` at 1920: it opens at 100% with every name, flow label and caption at least 9 px; no
   caption sits on a flow or an arrowhead; no task name ends in "…".
3. Select a task with a long name: the side-panel Name field shows it whole; type into it: every character is kept.
4. Switch the lens to **Business**: the palette reads in plain words ("where the work begins", …).
