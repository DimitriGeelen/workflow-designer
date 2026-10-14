# T-1175 Human AC#1 — independent review (revision 680d8de5)

Viewed (as images): `.playwright-mcp/t1175-inline-{1280,1440,1920}.png` (1280x860, 1440x860, 1920x1000),
copied here as `t1175-inline-<w>-<dispatch>.png`. Files dated 19:39-19:40, commit 680d8de5 at 19:42;
no CSS/HTML/JS change in the tree since the commit.

## Per screenshot

| Check | 1280 | 1440 | 1920 |
|---|---|---|---|
| Frame reaches near both edges | ~13px left / ~13px right | ~13px / ~13px | ~13px / ~13px |
| Watchtower nav (Work, Knowledge, Architecture, Govern, Docs, search, settings, theme) | all visible | all visible | all visible |
| Status line + breadcrumbs (Architecture › Designer › open) | visible | visible | visible |
| Bar: ← Maps, audit-process, v1, Open alone, ⛶ | all visible, ⛶ inside window | all visible | all visible |
| Designer toolbar | 2 rows | 2 rows | 1 row |

Toolbar controls read one by one in each screenshot: AEF·BPMN badge, Workflow Designer, v0.19.1, status dot,
Open project…, Pending refs…, +, instances: unavailable, −, fit, +, ⤢, ◧, ◨, ⛶, + Add Lane, Reset,
Clean layout, View XML, Settings, Load…, Check, Versions, Save to project, Save — all present and
unclipped at 1280, 1440 and 1920. Zoom group (− fit +) and view group (⤢ ◧ ◨ ⛶) stay together.
No overlap between controls; labels on one line ("Pending refs…" truncated with an ellipsis by design, as in
the label itself). Toolbar, tool palette, canvas and properties panel all sit within the frame.

Note (not a defect against this AC): the screenshots show bundle label v0.19.1 while the task says
the private Watchtower served the working designer; the toolbar layout shown is the T-1176 one (wrapping
groups), so the label is the version string, not evidence of the old bundle.

## Verdict: green
Full width used, nothing clipped, nothing overlapping in any of the three screenshots.
