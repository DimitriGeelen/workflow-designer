# Workflow Designer 0.18.0 — release notes

**Since:** `designer-v0.17.0` (2026-10-11) · **Show what is filled; see everything on request.** The properties panel
used to draw every extension field an element offers, filled or not — a service task showed 13, of which a typical
one fills 2. 0.18.0 shows what the element carries, folds the rest behind one row, lets each project (and each map)
choose which fields show by default, and opens a details view with every field when you double-click an element.
This is a minor release because the panel looks different by default. Nothing changes in what is saved.

## The panel shows what is filled (T-1124)

- **Empty fields fold away.** In the Extensions section an empty field is not drawn; one row, "+ N empty fields",
  stands in for them. Click it to show them in place, in their usual order. Measured on the 42 service tasks in the
  examples: from 14 rows to a median of 4.
- **A field with a value is always shown** — whatever any setting says.
- **A handoff's target picker ("Choose from project…") is always shown**, empty or not: it is what makes the
  element a handoff.
- **Settings → "Show all fields"** brings back the old panel (off by default; Reset turns it off).

## Which fields show by default — per project, per map (T-1125, T-1128)

- **Settings → "Fields shown by default":** pick an element type, then for each field choose *Default*, *Always
  show* or *Hide*; choose the scope *This project* or *This map*. The right-hand column says what is in effect and
  where it comes from (designer default / project / map). Save writes it; Cancel discards.
- **The map's setting wins** for the fields it mentions; every other field falls through to the project's.
- **Stored on the project server:** the project's in `field-profile.json` at the root of its map repository, a map's
  beside that map's saved versions. Nothing is written into the map file.
- **Safe to share:** a setting changed by someone else after you opened Settings is not overwritten — Save says so
  and reloads. Every save is logged (`field-profile.history.jsonl`). A malformed file is refused whole.
- A field hidden by a setting but carrying a value is still shown, marked "hidden in this project/map · shown: it
  has a value". A map saved under a new id starts with no settings of its own.
- Without a project server (the designer opened as a local file) the designer default applies and the section is
  read-only, saying why.
- **For a portal of your own:** the settings travel through two endpoints that 832's gallery server
  (`tools/gallery-serve.py`) provides — `GET /api/field-profile[?id=<map>]` → `{ok, profile, base}` (404 = none) and
  `PUT /api/field-profile[?id=<map>]` with `{profile, base}` (409 when changed since read, 422 when malformed).
  Profile shape: `{"version": 1, "types": {"serviceTask": {"show": [...], "hide": [...]}}}`. A portal without them
  gets everything else in 0.18.0; the designer simply uses its default fields.

## Element details (T-1127)

- **Double-click an element** — or use "⤢ All details" at the top of its panel — to open a large view with **all**
  its fields, filled or empty, including ones the project hides (marked as such), "Other extensions", Constituents
  and the I/O contract. Edits there change the element exactly like the side panel.
- A handoff keeps its double-click jump to the target workflow; its details open from the button.
- Esc, Close or a click outside closes it.

## Fixes

- **Agent type and Decision owner showed a value that was not set (T-1129).** These two dropdowns had no empty
  choice, so an unset field displayed — and wrote on any change — its first option ("primary", "agent"). They now
  show unset as unset, like every other optional field.

## Authoring kit

Content unchanged from 0.17.0. Re-issued as 0.18.0 beside the artifact (the version is stamped into it) with its own
calibration record of these exact bytes (`docs/authoring-kit/calibration-records/0.18.0.yaml`, ledger L16).

## Re-test (Greenfield)

1. Open a map with a service task that has a few fields filled: the panel shows those, plus "+ N empty fields";
   click it — the rest appear.
2. Double-click the task: the details view shows every field; change one, close — the panel shows the change.
3. Settings → "Fields shown by default": on your portal (without the two endpoints) it says it needs the project
   server and is read-only — expected. If you add the endpoints (or try it on 832's gallery server): *This project* →
   set one field to *Hide* and one to *Always show* → Save; reopen the map: the hidden one is gone from the panel
   (unless filled), the other shows empty. Then *This map*: set the hidden one to *Always show* → it shows for this
   map only.
4. An element with no Agent type: the dropdown is empty, not "primary".
