# T-1241 Human AC#1 — independent screenshot review (judge-t-1241-r5-claude-code-523695e828b4, rung-5-panel:claude-code)

Revision reviewed: e3ad4b4eb92e6a1e2e5ec16fd218e2e1a2fa4914.

## Are the shots current?
The 48 lens shots in docs/reports/T-1241-evidence/ (t1241-<lens>-<width>-<panel|details>[-bottom].png) are dated
2026-10-22 00:19-00:21, taken at 1a4ec1c9 (00:29). `git diff 1a4ec1c9 e3ad4b4e -- src` changes only (a) openingZoom's
CTM catch, which now records a fault and still returns, and (b) ioChildXml's XML export. Neither changes what is drawn,
so the shots stand for the reviewed revision.

## What I read
- All four lenses at 1920 (panel), business 1920/1440/1024 panel, business 1920 and 1024 details, logical 1440 panel,
  logical 1920 details, technical 1920 and 1024 panel, technical 1024 details-bottom (scrolled), all 1440 panel-bottom.
- 2x crops of the 1920 canvas (left, middle and right) in business, technical, all and logical. 1:1 crops of the
  business 1440 and all 1024 canvases to check that text is legible at the opening zoom.

## Findings
- **Toolbar:** at 1920 there is one row ending with Save. At 1440 and 1024 there are two rows. Every control is
  present, and none is clipped or overlapping. The lens select shows the lens name next to the ◑ icon in every shot.
- **Business lens reads as a business view.** The canvas has no id captions, and the pool label "AEF task lifecycle"
  has no workflow id. The panel header says "Service task" with no id under it. Its fields are Name, Lane, Note and
  Owner, with no Slug/Display ID/UID, no AEF: tag, no I/O contract and no Other extensions. The details sheet says
  "business fields · edits apply to the element" and shows the same four fields in two columns, with Close reachable.
  The technical lens at the same width shows the id captions, workflow:aef-task-lifecycle, Slug/Display ID/UID, the
  AEF: tags, Other extensions and I/O, so the difference is real.
- **Canvas overlaps that earlier reviewers saw are gone in these shots.** "issues encountered?" now sits clear of its
  flows (crop-business1920-mid, crop-technical1920-mid). "unchecked Human ACs?" sits above or beside its gateway, and
  the "pass" label and the vertical flow to partial-complete are separate from it. The agt_6_completion caption is no
  longer crossed. "next/later — backlog" no longer overlaps the "shelved…" label. I found no label-on-label or
  flow-through-label overlap in any lens at 1920.
- **Legibility at 1024/1440:** the map opens at 70%. At 1:1 the node, gateway and edge labels are readable. Part of
  the map is under the side panel, so the user pans or presses Fit (reachable) to see it. This is canvas viewport,
  not a clipped control.
- **Details sheets:** the business, logical and technical sheets fit, with Close reachable at every width. The
  technical sheet scrolls inside the modal at 1024 (details-bottom shows Other extensions, Suggest as a field and the
  I/O contract, all unclipped).

## Minor, non-blocking observations
- Long task names end in an ellipsis on the node ("Verification comman…", "tick, compl…"). This is by design, and the
  full name is in the panel.
- The Lane select shows the lane id "agent" in the business lens. The author records this as deliberate for slice 1,
  since it is the lane's name on this map.
- The 1920 left palette runs past the bottom of the window ("LANES"). The palette scrolls, and this is not from the
  lens.

## Verdict: green
