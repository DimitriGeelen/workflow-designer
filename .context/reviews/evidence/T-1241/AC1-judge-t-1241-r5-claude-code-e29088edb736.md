# T-1241 Human AC#1 — independent screenshot review (seat claude-code, revision fc2c7339)

Reviewer: judge-t-1241-r5-claude-code-e29088edb736. Read the PNGs directly (committed at 107545ef, unchanged at fc2c7339; worktree clean for these paths).

## Viewed
- t1241-business-{1024,1440,1920}-panel, business-{1024,1440}-details, logical-1440-panel-bottom,
  technical-1920-panel, technical-1024-details, technical-1440-details-bottom, all-1024-panel-bottom
- T-1278 reach-business-{1024,1920}-right, palette-end-business-1024, palette-2x-business-1920 vs palette-2x-logical-1920
- 2x crops (made in /tmp, not committed) of the gateway/label region 900-1600 x 180-470 at 1920 in Business and Technical.

## Findings
- Toolbar: 1920 one row ending with Save; 1440/1024 two rows; every control present, none clipped or overlapping.
- Business lens: panel header "Service task" with no id; fields Name, Lane, Note, Owner only (no Slug/Display ID/UID,
  no AEF: tag, no I/O, no Other extensions). Canvas has no id captions; pool label "AEF task lifecycle" without workflow id.
  Details sheet: subtitle "business fields · edits apply to the element", two columns, Close reachable.
  Palette subtitles are business wording ("where the work begins", "a step made of steps", "when something goes wrong")
  vs logical's startEvent / collapsed composite. Reads as a business view.
- Technical/All: id captions (agt_*) placed under/over nodes; at 2x none crosses a flow, arrowhead or name
  (issues encountered?/agt_gw_issues, gates pass?/agt_gw_gates, unchecked Human ACs?/agt_gw_unchecked all clear).
  Details sheet scrolls internally at 1024/1440 with Close in view; bottom shots show Other extensions and I/O contract intact.
- Logical: Name/Lane/Note/Owner, "+4 empty fields", I/O contract; no ids.
- Reachability: at 100% the map overflows to the right; reach-*-right shows the rest (human-lane task, archive, end event)
  fully drawn; palette-end shows the last palette control (Add Lane + help text).
- Text legible at 1x; smallest canvas labels readable.

## Minor, non-blocking
- When scrolled right, the sticky lane caption column covers the left edge of the human-lane task (reach-business-1024-right);
  the task is fully visible at other scroll positions. The panel-collapse handle sits over the canvas edge (by design).
- Words like T-1068, fw work-on T-XXX, P-010/P-011, G-020 appear inside AEF's own names/notes: map content, not lens ids.

Verdict: green.
