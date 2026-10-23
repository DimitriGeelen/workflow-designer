# T-1282 Human AC#1 — independent screenshot review (judge-t-1282-r1-90b5ddc9f4a2)

Revision reviewed: 2d0ae13b36bddae7ae2b894538451c1aa334488e (HEAD at review time; `git diff 2d0ae13b -- docs/reports/T-1282-evidence` empty, 10 files tracked).

## What I looked at (each image viewed)
- browse-1024/1440/1920: the modal is titled "Open project map" (Open-project mode, not the pick mode). The filter field and ✕ are fully visible at the top of the panel. 3-column grid. 8 saved cards, each with thumb, title, id, "saved · vN" and a 🗑 (8/8, so no pick callback). Two dashed pending-ref cards. At 1024/1440 the second pending card is under the grid's fold; at 1920 everything is visible.
- browse-end-1024/1440: the grid scrolled to its end. The last card "aef-task-lifecycle · 1f9b5f0c… · pending ref · referenced by 3" is whole, with the header (filter, ✕) still fixed. So every card can be reached by scrolling, and no control is clipped.
- browse-hover-1440: the preview is in the right gutter, x≈1094–1439. A pixel check shows its border at column 1439, the last column, so it sits inside the viewport. Shows the thumb, title and "aef-task-lifecycle · saved · v4".
- browse-hover-1920: the preview is whole in the right gutter and does not overlap the panel.
- browse-hover-1024: no preview. This matches pre-existing code: showProjectPreview (src/aef-workflow-designer.html ~L12054) computes W=min(360,gutter-14) and hides when W<200. The 1024 gutter is ~152px. The commit's src diff is only 5 lines in detectSaveApi, so this behaviour is unchanged.
- button-1440 compared with browse-1440: visually identical (only the clicked-button state differs).

## Same browser (code)
- ?browse=1 path: L11347 `if (qs.get('browse') === '1' && !qs.get('load')) openProjectModal();`
- Button: L12692 `$('btn-open-project').onclick = openProjectModal;`
Both call the same function with no pick callback, so it is the same browser.

## Notes (not defects)
- A long title ellipsizes, with the full id on the next line. This is the existing design and the same with the button.
- At 1024 the AC's "hover-zoom works" is met only in the sense that the existing no-overlap rule applies. The task discloses this, and the button-opened browser behaves identically.

Verdict: green.
