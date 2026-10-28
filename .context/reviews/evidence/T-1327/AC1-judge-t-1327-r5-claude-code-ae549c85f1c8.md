# T-1327 Human AC#1 — independent review (rung-5-panel:claude-code, dispatch judge-t-1327-r5-claude-code-ae549c85f1c8)

Revision reviewed: 5142be9be4bb60a2386ca261017454d81dffe4ff. HEAD == that revision. The commit after the shots (5142be9) only edits the task file. The shots were retaken in afec36920 after the last text fix ("... are NOT kept"), and they show that fixed text.

## What I did
I opened and read all of these with my own eyes: docs/reports/T-1327-evidence/{kitchen-sink,nested-lanes}-{1024,1440,1920}.png, kitchen-sink-1024-notice.png, plain-designer-map-1024.png and plain-designer-map-1440.png. I also read measures.json (9 entries, problems: [] for all) and the task's ## Visual Verification table.

## Findings, control by control
- **Kitchen-sink notice (1024/1440/1920):** the notice has 6 parts. Every new part is present and fully readable: "1 annotation, 3 groups, 2 associations kept unchanged and saved back, not shown yet", "13 elements inside 2 subprocesses ... the subprocess nesting is NOT kept", and "the layout is redrawn on save: positions are kept; this file's shape sizes and line bends are NOT kept". Each part is on its own bulleted line. At 1024 the text wraps inside the box (460 px wide) and wrapped lines hang under their bullet. The last word is not clipped. The dismiss ✕ is visible on the right edge.
- **No node covered (T-1078 dock):** at every width the pool/diagram starts below the last advisory (notice, then the Clean-layout nudge, then the no-authority summary). None of them overlap each other or the diagram. measures.json agrees: "no drawn node under it".
- **Toolbar reachable:** at 1024 and 1440 the header wraps to two rows, and at 1920 it is one row. Every button from "Open project…" to "Save" is on screen and unobscured at all three widths.
- **Nested-lanes notice (1024/1440/1920):** the notice has 4 parts, including "2 nested lanes shown and saved as top-level lanes — the lane nesting is NOT kept" and the layout line. It wraps at 1024 and is one line per part at 1440/1920. The diagram sits below it, and the four lanes (Sales, Inside sales, Field sales, Operations) are drawn top-level, as the notice says. The toolbar is intact.
- **Plain designer map (arc-lifecycle) at 1024/1440:** there is no notice, and the canvas starts at the top. measures.json shows shown:false at all 3 widths.

## Notes, not caused by this task
- The canvas text is small at fit zoom.
- Kitchen-sink's events overlap because of the file's own positions.
- At 1024 the three advisories take about half the canvas height. They are separately dismissable, and this task made the notice shorter.

None of these breaks the criterion.

## Verdict: green
