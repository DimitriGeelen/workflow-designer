# Workflow Designer 0.29.0 — release notes

**Since:** `designer-v0.28.0`. The fields of an input or output are editable, and an io's name is shown whole (arc-006,
slice 3 of T-1242).

## Changes

- **The fields of an io are editable (T-1302).** In an io's editor ("▸ edit attributes"), below the attributes, a
  "fields" list shows each `aef:field` child as an editable block:
  - line 1: path or fieldRef (a dropdown) and the address, which wraps so a long fieldRef is shown whole;
  - line 2: role (read | write | create | match | delete), cardinality (one | optional | many), required, a "when ×N"
    marker when the field has conditions (`aef:when`), and a remove ×;
  - "+ add field" appends a field; an empty one prompts "path…".
  - **Writing:** only the edited child is written anew. Its attributes are set in place, a new one is appended, and its
    `aef:when` conditions are kept. Untouched children, `aef:expect`, `aef:example` and unknown children keep their bytes.
    While the editor is open, the read-only summary stops listing the fields (they are the rows below).
  - Expectations and examples stay read-only (832 T-1309).
  - **Guard:** `tools/_t1301-io-edit-cdp.mjs` legs j1-j7: edit, a field with `aef:when`, add, remove, other steps
    byte-exact, and every field control inside its editor and clickable at 1024 and 1440.
- **An io's name is shown whole (T-1305).** A producer's io name is its field path (`sfdc:Opportunity.OwnerId`), and the
  one-line box cut it at every window width. The name now wraps. A name longer than the name column takes the row's full
  width, with type, req and × on a second line, so a path sits on one line unless it is longer than the panel. Short
  names keep the one-line row. Guard: `_t1301` leg i.

## What changes in stored maps

Nothing, unless you edit. A map opened and saved without an edit keeps its `aef:io` bytes. An edited step's `aef:io` block
is written in the designer's layout. Within it, only the edited item or child changes, by exactly the edit.

## For AEF

0.29.0 needs no new endpoint; the edits save through `/api/save`, which AEF serves. The designer endpoints AEF's server
does not answer are unchanged, so these features stay off in AEF:

| Endpoint | Feature (task) | In AEF today |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962) | "could not check: HTTP 403" (AEF's CSRF guard) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | picker "instances: n/a" |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | the designer's default fields, read-only settings |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | button disabled |

Request and response shapes: 832 `docs/reports/T-1300-designer-data-api-contract.md` (AEF inception T-4737).
