# T-1241 Human AC#1: independent screenshot review (seat claude-code, revision 6d03c1b9)

Source: docs/reports/T-1241-evidence/t1241-<lens>-<width>-<panel|details>[-bottom].png, all 48 re-shot in 6d03c1b9
(2026-10-22 21:27-21:28, designer v0.25.0, map aef-task-lifecycle; every width now opens at 78%).

## Shots opened
- business: 1920 panel, 1920 details, 1440 panel, 1024 panel, 1024 details
- logical: 1440 panel-bottom
- technical: 1920 panel, 1024 details-bottom
- all: 1440 panel
- my 2x crops: crop-bus1920-left-<id>.png and crop-bus1920-right-<id>.png (business 1920 canvas, whole flow),
  crop-tech1920-right-<id>.png (technical 1920 canvas, right half with id captions)

## Findings
- Toolbar: one row at 1920 through Save; two rows at 1440 and 1024, every control present; lens icon + select
  ("Business"/"Logical"/"Technical"/"All") legible. Nothing clipped or overlapping.
- Prior amber (codex 094a2e6d, 89e5801f): the node names "Verification comman…" and "…tick, compl…" were truncated.
  Fixed: the 2x crops show "completion gates: Agent ACs (P-010) + ## Verification commands (P-011)" and
  "partial-complete: review Human ACs (Watchtower /review), tick, complete" in full. No node name ends in an ellipsis.
  The smallest name text (about 9 px at 78%) is legible in the 2x crop. The crowding of "issues encountered?" and
  "yes – status: issues" is gone: the gateway name sits above the diamond and the flow label sits below it.
- Business canvas: no id captions, no I/O or authority markers, and the pool label is "AEF task lifecycle" without
  the workflow id. The technical canvas has ids such as agt_1_create and "· workflow:aef-task-lifecycle", so the
  lens is what removes them. Gateway questions, flow labels and the end-to-end path (work identified -> task
  archived, including the human partial-complete lane) can be followed. Reads as a business view.
- Business panel: plain "Service task" header with no id, × delete, All details, Name, Lane, Note, Owner. No
  Slug/Display ID/UID, no AEF: tag, no I/O, no Other extensions.
- Business details (1920, 1024): subtitle "business fields · edits apply to the element", two-column layout,
  Close reachable, nothing clipped.
- Logical 1440: "+4 empty fields" and an I/O contract with add input/output reachable; no ids.
- Technical: ids, Slug, Display ID, UID, AEF: tags, Other extensions and I/O. At 1024 the details sheet scrolls
  inside itself, and Close plus add input/output stay reachable.
- All 1440: "serviceTask" header and every field, as before.

## Minor observations (not blocking)
- At 1024 and 1440 the right part of the map sits under the open side panel. The canvas can be panned and the panel
  collapsed (◂/▸), so no control is unreachable. At 1024 the ▸ toggle covers the "H" of "Handoff" in the label
  under the panel edge.
- Technical 1920: the caption "agt_6_completion" starts right next to the arrowhead entering the completion node.
  The two touch but no text is hidden.
- The note in the task's Visual Verification section, "at 1024 the map fits small (fit zoom)", is out of date: the
  shots show 78%. This is a documentation nit.
- The Lane select shows the lane id "agent" in the business lens. The task records this as deliberate for slice 1.

Verdict: green.
