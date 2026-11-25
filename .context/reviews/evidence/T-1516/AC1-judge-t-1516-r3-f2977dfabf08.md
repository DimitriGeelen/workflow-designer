# T-1516 AC#1 — independent review, dispatch judge-t-1516-r3-f2977dfabf08

Criterion: the skill helps an agent new to the designer produce a good map with fewer rounds, and says nothing wrong
about the designer. Reviewed revision 6d661940578426d4070bab35287f6c254c928d4e.

Verdict: **amber**. One instruction states a wrong fact about the designer (rule 5, the version-by-URL form). Fix is
one line. Everything else spot-checked is correct.

## What I read

- `skills/workflow-designer/SKILL.md` (19 rules, 4 "Never" bullets).
- `docs/reports/T-1516-designer-skill.md` (sources, decisions, external-review table).
- `dist/aef-authoring-kit-0.49.0/SKILL.md` (steps 1–13, "Update a map"). The skill's cross-references to kit step
  numbers, kit step 10 (round trip), step 11 (screenshot), step 13 (publish), and AUTHORING sections 3, 4, 4b, 5 all
  resolve to real sections.
- `src/aef-workflow-designer.html`, the designer source for each control and behaviour claim (line numbers below).

## Spot-checks: correct

| Skill claim | Source | Result |
|---|---|---|
| Import formats: BPMN, Mermaid, CSV, Excel | `IO_FORMATS.import` l.14794 | correct |
| Export: SVG, PNG 1x/2x/4x, PDF one page (A4/A3), PDF readable pages, BPMN, Mermaid, CSV, Excel | `IO_FORMATS.export` l.14794–14806 | correct |
| Step-list columns; only `id` required; `type` defaults to `task`; `next`/`next_labels` `;`-aligned; `lane_code`/`lane_authority` read | `CSV_HEAD` l.14541, `stepRowsToModel` l.14574–14590 (throws unless `id` is a column; skips rows without id) | correct |
| Step-list import lays out the map itself | `importBridgeModel` l.14645 calls `cleanLayoutAll()` | correct |
| `_deepLinkSettled` values `'none'`/`'adopted'`/`'suppressed'`/`'failed'`; `_appReady` fires before the fetch | l.14879–14920 | correct (rule 17 is right) |
| `btn-zoom-fit` = "Fit whole diagram" | l.1627 | correct |
| `btn-save` downloads the BPMN and keeps a library copy | l.12744–12747 (`saveActiveToLibrary()` + `downloadBpmnFile()`) | correct |
| `btn-save-project` shown only when the server answers `/api/health` | l.12926–12935 | correct |
| Check shown only when a server answers; needs a server to validate | `btn-check` shown on health ok, l.12935; `validateCurrentWorkflow` returns "unavailable" when `_apiAvailable` is false, l.12974 | correct |
| Check runs a validator with `run_xml` | designer_api pinned validator; kit `validate-workflow.py` defines `run_xml` at l.2646 | consistent; the designer runs the pinned copy, not the kit file by name (not checked byte-for-byte) |
| Phases: "Add phase row" then "Add phase" click splits; add lanes first | `palette-add-phase-row`/`palette-add-phase`, l.12656–12672 | correct |
| Phase = `bpmn:group` spanning full pool height; other groups stay undrawn | `phasesParse`, l.16815–16840 (F3 comment) | correct |
| Banners: "N nodes were drawn outside their declared lane — moved back…", "This map declares no authority", "This map could use Clean layout" | l.11584, l.2301, l.1956 | correct |
| `aef:workflowMeta` identity used by the designer | l.3508, l.13711 | correct in substance |
| "Look at it" / screenshot in kit step 11 | kit SKILL.md step 11 | correct |
| MCP `validate_workflow` documented in `docs/mcp-designer-server.md` | file exists; the r3 judgement also confirmed l.52 | correct |

## Defect: rule 5 gives a wrong URL for a specific version

Rule 5 says: open a specific version with
`…/designer/app?load=/api/version?id=<map-id>&v=<n>`.

The `&v=<n>` is not inside `load`. It is a second query parameter of the designer page. I ran the query through a
standard parser:

    parse_qs('/designer/app?load=/api/version?id=ABC&v=3')
    -> {'load': ['/api/version?id=ABC'], 'v': ['3']}

The designer reads only `load` (l.14896) and never reads `v` from the page URL (the only `v=` uses are in
`fetch(...)` calls for the Versions modal, l.13436–13700). So the page fetches `/api/version?id=ABC` with no `v`, which
returns the latest version, not version *n*. A reader following rule 5 gets the wrong version and no error.

This is the kind of error the criterion forbids ("no factual error about the designer"). It also plausibly connects to
the report's "T-1517" bug (AEF saw `…v1@2x.png` while v3 was loaded). I have not verified that link.

Needed fix (rule 5): percent-encode the nested query so `v` stays inside `load`, e.g.

    …/designer/app?load=%2Fapi%2Fversion%3Fid%3D<map-id>%26v%3D<n>

and say it that way, or write `load=` followed by `encodeURIComponent('/api/version?id=<map-id>&v=<n>')`. Verify with a
parser that `load` decodes to `/api/version?id=<map-id>&v=<n>`.

The earlier r3 judgements (`AC1-judge-t-1516-r3-52a0e3866f81.md` l.33, `…9e11c84867b6.md` l.30) confirmed "`?load=`
handled" but did not follow the nested `&v=` through the parser. Their "matches rule 5" does not hold for `v`.

## Gaps not counted as errors

- **Peer must-nots:** only AEF's list is applied. Greenfield (aef-greenfield-test) and 055 have not answered. The
  criterion requires the skill to be free of "anything the peers said the skill must not encourage"; I can judge only
  against AEF's list. The report states this itself (external-review table, row "reviewer, second judgement, finding 3").
- **Rule 1 scope:** the skill correctly says to write scope in the description until T-1519 is agreed. Not an error.
- **Rule 15 vs kit step 11:** not in conflict. Rule 15 says do not use a screenshot as the picture of the map; rule 13
  says how to read the kit's step-11 screenshot. Consistent.

## Images

No screenshot is cited by criterion 1 or by the skill. Nothing was rendered. The designer source was read, not run.
The kit's `dist/…/SKILL.md` and the skill were read as text.

## Environment note

The brief's `bin/fw` does not exist in this checkout; `.agentic-framework/bin/fw` does. I used that path for the
digest and record commands.
