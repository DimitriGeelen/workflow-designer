# T-1241 AC1 — independent screenshot review (rung-5-panel:claude-code, judge-t-1241-r5-claude-code-3b1844bc2570)

Revision: dea6f124f83816f6e5aec0b4006b7030e459ef0b (HEAD at review; no diff in docs/reports/T-1241-evidence vs that rev).

## What I looked at (myself, image by image)
- business: 1024/1440/1920 × panel/details (all 6)
- logical 1920 panel; technical 1920 panel, 1024 details; all 1440 panel
- overlap-0.24.0-1920 vs overlap-now-1920, overlap-0.24.0-noids-1920 vs overlap-now-business-1920 (PIL diff of canvas region 240,130–1580,480)

## Findings
- Toolbar: 1920 one row (… Versions, Save to project, Save at right edge); 1440 and 1024 two rows; lens select ("Business"/"Logical"/"Technical"/"All") with ◑ icon is visible in every shot; no control clipped, overlapping or hidden. At 1024 the "Clean layout" toast wraps cleanly.
- Business panel (all widths): header "Service task", no id under it; × delete, All details, BPMN Name/Lane, Extensions Note/Owner. No Slug/Display ID/UID, no AEF: tag, no I/O contract, no Other extensions. Name input text runs past the field edge, which is normal input scrolling, not clipping of a control.
- Business details (all widths): title, subtitle "business fields · edits apply to the element", Close reachable, two-column sheet (Name, Lane | Note, Owner), nothing clipped.
- Business canvas: no id captions under nodes (technical 1920 shows agt_1_create etc.), pool label "AEF task lifecycle" without "· workflow:aef-task-lifecycle", no badges. Reads as a business flow view. Edge and node text such as "promoted — fw work-on T-XXX" is label text the map's author wrote, not a lens artifact.
- Logical/technical/all: the fields and I/O contract the task's table describes are present; the technical details sheet scrolls inside at 1024 with Close reachable; All shows "serviceTask" + id as before.
- Canvas overlaps (gateway labels "issues encountered?", "unchecked Human ACs?", "ready to start now?" crossed by flows) are visible in every lens. They are NOT from the lens: canvas diff 0.24.0 vs now (ids on) bbox=None (pixel-identical); 0.24.0 no-ids vs today's Business differs only at (90,13,213,22) of the crop, which is the pool label. Labels stay readable. Out of scope here; filed by the author as T-1256.

## Verdict: green
The criterion's Expected is met: every control is reachable and unclipped at 1024/1440/1920, and the business lens shows the flow without ids or technical badges. The canvas label overlaps were already in 0.24.0 (verified by pixel diff) and are tracked separately.
