# T-1241 Human AC#1 — independent screenshot review (rung-5-panel:claude-code)

Revision under review: b19e977b0fafdad062fa85774a35c6d3c6583edc. All 34 PNGs under
docs/reports/T-1241-evidence/ were taken from `git show b19e977b:<path>` (not the working tree) and read
as images: all 24 lens shots (business/logical/technical/all x 1024/1440/1920 x panel/details) and the
toolbar-fit shots (1024/1440/1920 lens all/business, n-a 1024/1440/1894/1920).

## What holds
- Business lens (panel + details, all three widths): Name, Lane, Note, Owner only; no Slug/Display ID/UID,
  no id caption under the type name, no AEF: tag, no I/O, no Other extensions. Canvas: no id captions under
  nodes, pool label "AEF task lifecycle" without the workflow: id. Details sheet two-column, Close reachable.
- Logical adds Authority/Horizon/Workflow type/Determinism + I/O contract, no ids. Technical/All show ids,
  AEF: tags, Other extensions, id captions on canvas.
- Toolbar: every control present and unclipped at 1024/1440/1920 in all lens shots; toolbar-fit shots
  (current lens icon + name select) show one row at 1894/1920 and two clean rows at 1024/1440.
- Details sheets: no clipping at any width (technical 1440 scrolls inside the sheet, as expected).

## What does not hold
1. **Overlap on the canvas, technical and all lenses** (t1241-technical-1920-panel, t1241-all-1920-panel,
   also 1440): with id captions on, the gateway labels move beside the diamonds and collide —
   "issues encountered?" is crossed by its incoming flow and touches the diamond; "unchecked Human ACs?" runs
   into the "pass" flow label and over the flow line; the arrow into "completion gates…" runs through its id
   caption "agt_6_completion". Zoomed crop: crop-tech1920-judge-t-1241-r5-claude-code-30e9c090f642.png. The criterion says nothing overlapping
   in each lens. (The All lens is stated to be identical to the pre-lens designer, so this may be
   pre-existing, but it is visible in these shots.)
2. **Business lens, minor**: "unchecked Human ACs?" label is crossed by the vertical flow to the human lane
   (crop-bus1920-judge-t-1241-r5-claude-code-30e9c090f642.png). Panel and details header still print the BPMN type name "serviceTask" (camelCase
   technical token); the details subtitle still says "all fields, filled or empty", which is untrue in the
   business lens. The Lane select shows the lane id "agent" (author already noted, left for slice 1).
3. **Shots are stale against the reviewed revision**: the 24 lens shots were committed in 64fbcdba; after
   that cba1f565 (T-1241) changed the toolbar (no "Lens: " prefix, icon + name, "instances: n/a") and
   a3a62820 (T-1249) changed the side panel/details. The listed lens screenshots still show "Lens: Business"
   and "instances: unavailable" with Save to project/Save wrapping at 1920, i.e. not the UI at b19e977b.
   The toolbar-fit shots cover the new toolbar only, on audit-process, not the lenses on aef-task-lifecycle.
4. Observation: at 1024 the map at fit zoom is too small to read in every lens (author noted it).

Verdict: amber — the business lens does read as a business view and nothing in the controls is clipped,
but there are canvas overlaps in technical/all and the shots predate the reviewed revision.
