# T-1327 Human AC#1 — independent review (rung-5-panel:claude-code)

Revision: 5142be9be4bb60a2386ca261017454d81dffe4ff. Dispatch: judge-t-1327-r5-claude-code-b97b1898ba3f.

## What I checked
- Shots in docs/reports/T-1327-evidence/ were last written in afec36920, the same commit as the last source change
  (src/aef-workflow-designer.html, line-bends string). HEAD 5142be9be only edits the task file, so the shots match the
  reviewed source. Source lines 10707-10710 carry the exact strings in the shots ("subprocess nesting is NOT kept",
  "lane nesting is NOT kept", "... line bends are NOT kept").
- I read 8 full-page shots myself: kitchen-sink 1024/1440/1920, nested-lanes 1024/1440/1920, plain map 1024/1920
  (copies cited below), plus kitchen-sink-1024-notice.png. I also read measures.json (9 entries, problems: [] in all).

## Findings
- kitchen-sink: 6 parts shown, one per bulleted line: lanes moved back, lanes grown, data objects kept, "1 annotation,
  3 groups, 2 associations kept unchanged and saved back, not shown yet", "13 elements inside 2 subprocesses ... subprocess
  nesting is NOT kept", "layout is redrawn on save ... NOT kept". The full text is readable at every width. At 1024 the
  text wraps inside the box (460 px wide) and wrapped lines hang under their bullet; ✕ is inside the box. The Clean layout
  nudge and the no-authority advisory are stacked below with no overlap. The pool starts below the last advisory (T-1078
  dock), so no node is covered.
- nested-lanes: 4 parts, including "2 nested lanes shown and saved as top-level lanes — the lane nesting is NOT kept".
  Readable and wrapped at 1024, one line per part at 1440 and 1920. The diagram starts below the advisories, and the four
  lanes are drawn top-level, as the notice says.
- Toolbar: two rows at 1024 and 1440, one row at 1920. Every button (Open project … Save) is fully on screen and not
  covered by the notice.
- Plain designer map (arc-lifecycle): no notice. The canvas starts at the top.

## Minor observations (not blocking)
- At 1024, kitchen-sink's three advisories take about 45% of the canvas height. Each one can be dismissed, and the
  operator already ruled on this in the advisory sweep.
- At 1024, the canvas side-collapse handles (◂ ▸) sit at the canvas edge next to the advisories' borders but do not
  cover any text.

Verdict: green.
