# T-1241 Human AC#1 — independent screenshot review

Reviewer dispatch: judge-t-1241-r1-7b132af02e9c · revision 206862129afe6e11e7bd66be47a24771eccf8de9 · rung-1-same-vendor-independent

## Provenance note
The 24 screenshots named under `## Visual Verification` (`docs/reports/T-1241-evidence/t1241-<lens>-<width>-<state>.png`)
exist in the working tree but are **untracked**: `git ls-tree 20686212 docs/reports/T-1241-evidence/` is empty.
I read the working-tree files (mtime 2026-10-21 09:24-09:25). They are not part of the reviewed revision.

## What I read (11 of 24 files, every lens and width covered)
business 1024/1440/1920 panel; business 1024/1440/1920 details; logical 1440 panel; logical 1920 details;
technical 1920 panel; technical 1024 + 1440 details; all 1024 panel.

## Met
- Toolbar: the lens select ("Lens: Business/Logical/Technical/All") is visible and unclipped at every width.
  At 1024 it is the first control of row 2, and at 1440/1920 it sits in row 1. Check / Versions / Save to project / Save are all
  reachable (at 1920 Save to project and Save wrap to row 2, as the author noted). Nothing in the toolbar overlaps.
- Business panel (all widths): only Name, Lane, Note and Owner show. There is no Slug, Display ID or UID, no id under the type name,
  no `AEF:` tag, no I/O and no Other extensions. Compare technical-1920-panel and all-1024-panel, which show all of these.
- Business canvas (1440/1920): no id captions under nodes, and the pool label is "AEF task lifecycle" without
  "workflow:aef-task-lifecycle". Technical shows both, as expected.
- Business details (1024/1440/1920): a two-column sheet with BPMN (Name, Lane) and Extensions (Note, Owner). Close is reachable.
- Logical: adds Authority, Horizon, Workflow type, Determinism and I/O contract, with no ids.
- Technical/all details: the modal scrolls, and the lower fields are cut off by the scroll edge, not by the layout. Acceptable.

## Not met / needs work
1. **The business lens still shows a technical type token.** The panel header and the details header read `serviceTask`
   (the camelCase BPMN element type) in the business lens at every width (business-1920-panel.png top right;
   business-1440-details.png). A business reader would expect "Service task" / "Agent step" or nothing.
2. **The details subtitle contradicts the lens.** In the business (and logical) lens the details sheet still says
   "all fields, filled or empty · edits apply to the element", but it shows a filtered subset (business-1440-details.png).
3. **Canvas overlaps, in every lens, worst in technical:** edges run through gateway labels
   ("ready to st|art now?", "issues en|countered?", "unchecked Human ACs?" at business-1920-panel.png).
   In technical-1920-panel.png the id captions and gateway labels collide with edge labels ("pass" / "unchecked Human ACs?";
   "issues encountered?" / agt_gw_issues). The designer's own toast says "This map could use Clean layout".
   This is pre-existing map layout, not caused by the lens, but the criterion says "nothing clipped or overlapping" for each lens.
4. **1024 is not legible.** At fit zoom the whole map is about 470x130 px (business-1024-panel.png), and no node or edge
   label can be read. The author acknowledges this in the notes. The criterion asks that each lens be legible at 1024.
5. Lane select still shows the lane id `agent` (author-noted, deliberately out of scope for slice 1). Minor.

## Verdict: amber
The lens mechanics are visibly right: the business lens hides ids, slugs, UIDs, `AEF:` tags, I/O and id captions, and every
toolbar control is reachable and unclipped. Before green, the following are needed: (a) hide or humanise `serviceTask` in the business lens; (b) make the
details subtitle match the lens; (c) re-shoot after Clean layout (or with label collisions resolved), and at 1024
include a zoomed shot or accept the fit-zoom legibility limit explicitly; (d) commit the screenshots.
