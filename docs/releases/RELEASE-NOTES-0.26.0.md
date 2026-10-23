# Workflow Designer 0.26.0 — release notes (DRAFT)

**Status: DRAFT, not released.** `VERSION` and `APP_VERSION` stay 0.25.0 until the release task bumps them; the
number is the one this file is named for unless that task chooses otherwise.

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

## What changes in stored maps

Nothing: every change above is display only, and the guards check saved bytes are unchanged.
