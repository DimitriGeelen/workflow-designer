# T-1300: the designer's four data APIs that AEF does not serve (for AEF inception T-4737)

AEF asked (2026-10-24, msg 1e63c585) for each endpoint's request and response shape, and what the designer does when the call
fails or the endpoint is absent. The source of truth is 832's reference server `tools/gallery-serve.py` (server) and
`src/aef-workflow-designer.html` (client), as of designer 0.26.0. Line numbers are at commit time of this file.

## Common rules

- **Same origin, JSON.** The designer calls relative paths (`/api/...`) from the page it is served from. Request bodies are
  `Content-Type: application/json`. Every JSON answer carries `ok: true|false`. A refusal carries `error: "<text>"`; the
  designer shows that text to the person where it has a place for it.
- **The gate for all four is `/api/health`** (`detectSaveApi`, html:11323). Only when `GET /api/health` answers
  `{ok:true}` does the designer believe a project server exists and try the endpoints below. AEF answers health, so the
  designer DOES try all four inside AEF today.
- **"Absent" vs "broken".** The designer tells apart an endpoint that does not exist (404/403/405 with a non-JSON body:
  a server that simply lacks the route) from one that answers wrongly (5xx, a JSON body of the wrong shape, a non-JSON 200).
  Absent = the feature is quietly off. Broken = the feature is off AND a fault is recorded (`aefRecordFault`, visible in the
  designer's fault log). **For AEF: an endpoint you do not serve should answer 404 with your normal (non-JSON) page, or a JSON
  404 without the fields listed below; never 200 with a different shape.**
- **Identifiers.** A map id matches `^[a-z0-9][a-z0-9_-]*$` (server answers 400 `invalid id` otherwise). A field key or
  element type matches `^[A-Za-z][A-Za-z0-9_-]*$`.

## 1. `POST /api/validate` (the Check button, T-955/T-962)

**Request:** `{"bpmn": "<the map as BPMN 2.0 XML, as the designer exports it>"}`

**Response 200:**
```json
{"ok": true,
 "findings": [{"severity": "ERROR|WARN|INFO", "rule": "E-XML-...", "location": "<element id or path>", "message": "<text>"}],
 "errors": 0, "warnings": 2}
```
`errors`/`warnings` are counts of `severity == "ERROR"` / `"WARN"`; the designer derives them if they are missing.

**Refusals:** 400 `{ok:false, error:"missing/empty bpmn"}`; 503 `{ok:false, error:"validator unavailable: ..."}` when the
validator cannot be loaded (deliberately NOT an empty findings list); 500 `{ok:false, error:"validate failed: ..."}`.

**The rules are not in the route.** The route loads 832's `tools/validate-workflow.py` and calls its `run_xml(bpmn)`; the
findings are its `Finding.as_dict()`. The same validator runs in 832's suite, CLI and save path (`POST /api/save` returns it as
`validation`, T-973). Serving this endpoint means running THAT file, not re-implementing rules: a second implementation
would drift from the one the suite pins. It is plain Python 3 (stdlib only); 832 can ship it with each release, versioned with
the designer, if AEF wants it vendored.

**When it fails or is absent** (html:11380-11430): the Check drawer shows the state "could not check — `<error or HTTP
status>`", never "no findings" (an unreachable validator must not read as a clean map). No markers are drawn. Unlike the
other three, this path does NOT tell "absent" from "broken": every failure, a plain 404 included, is shown and recorded as a
fault, because the person pressed Check and must see why nothing came back. In AEF today the Check button shows (health
answers) and every check ends in "could not check — HTTP 403": AEF's CSRF guard refuses the POST before any route
(AEF probe, msg 478af8d4). **If AEF builds this endpoint, the designer's POST must pass that guard the same way its
`POST /api/save` does**: the designer sends no token, only `Content-Type: application/json`, same origin.

## 2. `GET /api/instances?template=<map id>` (the instance overlay, T-884)

**Response 200** (the output of `tools/instance-node.py snapshot <id>`):
```json
{"template": "<map id>", "generated": "<UTC ISO>", "state": "INSTANCES|NO-INSTANCES", "examined": 42,
 "instances": [{"task": "T-123", "state": "NODE|STALE|NO-POSITION", "node": "<BPMN element id>",
                "status": "<task status>", "owner": "<task owner>"}],
 "refusals": [{"ts": "...", "task": "T-123", "case": "...", "rule": "...", "kind": "REFUSED-BY-GATE",
               "node": "...", "target": "...", "template": "...", "detail": "...", "actor": "..."}]}
```
- An instance is a live task whose `workflow_type` is bound to this map in `examples/aef-processes/template-binding.yaml`.
  `node` is the task's recorded `current_node:` frontmatter. `NODE` = it is a node of this map, `STALE` = it names a node the map
  no longer has, `NO-POSITION` = no `current_node` recorded.
- `refusals` are the audit-log lines (`.context/audits/instance-refusals.jsonl`) for those tasks: a gate refused a transition.
- **In AEF the data is AEF's own:** your tasks, your binding of workflow types to maps, your gate refusals. The shape is what the
  designer needs; where it comes from is yours.

**Refusals:** 400 `invalid template`; 404 `{ok:false, error:"unknown template"}` (no such map); 500 on a tool failure.

**When it fails or is absent** (html:11251-11280): the picker reads "instances: n/a" and nothing is drawn. A 404 or no
server is a state, not a fault; a 5xx, a non-JSON body, or a JSON body without an `instances` array is recorded as a fault.
The overlay is view state only: nothing in it is saved or exported.

## 3. `GET` and `PUT /api/field-profile[?id=<map id>]` (which fields the properties panel shows, T-1125/T-1128/T-1134)

Without `id`: the project's profile. With `id`: that map's own profile (overrides the project's for that map).

**Profile shape** (refused whole if anything is off, never half-applied):
```json
{"version": 1,
 "types":  {"<elementType>": {"show": ["<fieldKey>"], "hide": ["<fieldKey>"]}},
 "fields": {"<fieldKey>": {"label": "1-60 chars", "hint": "<=200 chars", "types": ["<elementType>"],
                           "approved_by": "<who>", "approved_at": "<when>"}}}
```
`types` is required; `fields` (operator-approved extra fields, see 4) is optional; no other top-level key. A key both shown
and hidden is refused.

**GET 200:** `{ok:true, profile:{...}, scope:"project|map", base:"<sha256 of the stored bytes>"}`
**GET 404 (no profile yet):** `{ok:false, error:"no field profile", scope, base:"none"}`. **The `base` string is what tells
the designer the endpoint exists:** a JSON 404 WITH `base` means "offered, nothing stored"; any other 404 means "not offered".
**GET 422:** `{ok:false, error:"field profile refused: <why>", scope}` (a stored file that is malformed).

**PUT request:** `{profile:{...}, base:"<the base from the last GET>", note:"<optional>"}`
**PUT 200:** `{ok:true, profile, scope, base:"<new>"}`. **422** malformed. **409** `{ok:false, error:"the <scope> profile
changed since it was read", base:"<current>", current:{...}}`: optimistic concurrency, never a silent overwrite. The reference
server writes atomically and appends one line per write to `field-profile.history.jsonl` (ts, scope, id, previous, new, note).

**When it fails or is absent** (html:7197-7260, 7458, 7487): the designer's built-in default fields are shown, and the field
settings panel is read-only with the line "This project server does not offer field settings — shown read-only (designer
default in use)." It never offers an edit it cannot save. A non-JSON answer that is not
a plain 404/403/405 is recorded as a fault.

## 4. `GET` and `POST /api/field-suggestions` ("Suggest as a field", T-1126)

When a map carries an `aef:` key the designer has no field for, the person can ask the operator to make it a field. The
suggestion is a RECORD on the server, never a field: only the operator approves it (in 832 with `tools/field-suggestion.py`,
which then adds it to the profile's `fields`, see 3).

**GET 200:** `{ok:true, version:1, suggestions:[{type, key, status:"pending|approved|rejected", count, total, examples[],
maps[], first_seen, last_seen, decided_by?, decided_at?, reason?}]}`. No file yet = an empty list, still 200.

**POST request:** `{type:"<elementType>", key:"<fieldKey>", count:<int>, total:<int>, examples:["<=120 chars", ...max 3],
map:"<map id or empty>"}` with `0 < count <= total <= 100000`. One entry per (type, key): a repeat merges the evidence and
never changes the status. **POST 200:** `{ok:true, suggestion:{...}}`. **400** on any field out of range, with the reason.

**When it fails or is absent** (html:7286-7370): the button "Suggest as a field" is shown disabled, titled "This project
server does not offer field suggestions". Only an answer that is 200 with `ok` and a `suggestions` array counts as offered.
A failed POST leaves the button's title "Not recorded — <error or HTTP status>" and records a fault.

## What turning each on costs AEF, as 832 sees it

| Endpoint | Data it needs on AEF's side | Writes? |
|---|---|---|
| `/api/validate` | none; runs 832's `validate-workflow.py` | no |
| `/api/instances` | AEF tasks' `workflow_type` + `current_node`, a type→map binding, gate refusals | no |
| `/api/field-profile` | a project profile and per-map profiles (two JSON files per scope) | yes (PUT) |
| `/api/field-suggestions` | one JSON list, plus an operator approval path | yes (POST) |

The choice is AEF's operator's (T-4737). 832 will answer questions on any of them.

## Reference tests (acceptance material for whichever AEF builds)

Server side (HTTP against the reference server):

| Endpoint | Server-side tests |
|---|---|
| `/api/validate` | `tests/test_t955_validate_endpoint.py`; `tests/test_t973_save_findings.py` (the same verdict on save) |
| `/api/instances` | `tests/test_gallery_instances_api.py` |
| `/api/field-profile` | `tools/_t1128-field-profile-server.py` |

Designer side (headless Chromium against a server, checking what the person sees):

| Endpoint | Designer-side tests |
|---|---|
| `/api/validate` | `tests/test_t961_designer_validate_reach.py` |
| `/api/instances` | `tools/_t884-instance-overlay-cdp.mjs`, `tools/_t884-live-proof-cdp.mjs` |
| `/api/field-profile` | `tools/_t1125-field-profile-cdp.mjs` |
| `/api/field-suggestions` | `tools/_t1126-field-suggestions-cdp.mjs` |

Absence behaviour of all four on a portal that lacks them: `tools/_t1134-portal-without-endpoints-cdp.mjs`.

Pointing the designer-side tests at AEF's server instead of `gallery-serve.py` is the acceptance run.
