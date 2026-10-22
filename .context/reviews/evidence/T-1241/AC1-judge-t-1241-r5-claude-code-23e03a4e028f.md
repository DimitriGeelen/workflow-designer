# T-1241 Human AC#1 — independent screenshot review (seat claude-code, revision 1fdffed4)

Source: docs/reports/T-1241-evidence/t1241-<lens>-<width>-<panel|details>[-bottom].png (last re-shot in d268b263,
2026-10-22, on designer v0.25.0; cc3b8b53 lens alignment states lifecycle shots unchanged).

## Shots opened
- business: 1920 panel, 1920 details, 1440 panel, 1024 panel, 1024 details
- logical: 1440 panel
- technical: 1920 panel, 1440 details, 1024 panel-bottom
- all: 1024 panel
- 2x crop of the business 1920 canvas (crop-business1920-canvas-judge-t-1241-r5-claude-code-23e03a4e028f.png)

## Findings
- Toolbar: 1920 one row through Save (Save fully inside the edge); 1440 and 1024 two rows; lens icon + select
  ("Business"/"Logical"/"Technical"/"All") legible; no control clipped or overlapping at any width.
- Business lens, canvas (1920 crop): no id captions under nodes/gateways/events, pool label "AEF task lifecycle"
  without workflow id, no I/O or authority markers; node names, gateway questions and flow labels legible; no
  label overlap that hides text. Compare technical 1920: id captions (agt_1_create …) and "· workflow:aef-task-lifecycle"
  are present there, so the lens removes them.
- Business panel: plain "Service task" header with no id, × delete, All details, Name, Lane, Note, Owner only — no
  Slug/Display ID/UID, no AEF: tag, no I/O, no Other extensions. Reads as a business view.
- Business details (1920, 1024): subtitle "business fields · edits apply to the element", two-column sheet,
  Close reachable, nothing clipped.
- Logical 1440 panel: Name/Lane/Note/Owner, "+4 empty fields", I/O contract; no ids. Technical: ids, Slug, Display ID,
  UID, AEF: tags, Other extensions, I/O; details sheet scrolls inside, Close reachable. All 1024: "serviceTask"
  header + every field, as before.

## Observations (not blocking)
- At 1024/1440 the canvas is at 70% and its right part sits under the open side panel; it is pannable and the panel
  collapsible (◂/▸ toggles visible), so no control is unreachable. The VV note "at 1024 the map fits small (fit zoom)"
  no longer matches the shots (zoom shows 70%) — a doc nit.
- Two node names end in an ellipsis on the canvas ("Verification comman…", "…tick, compl…") in every lens; this is
  deliberate node-label truncation, full name in the panel; not lens-related.
- Lane select shows lane id "agent" in business — recorded as deliberate for slice 1.

Verdict: green.
