# T-1384 evidence: the advisory dock as one card

Fixture: `tests/fixtures/t1381/data-stores.bpmn`, opened the real way (`adoptImportedXml(xml,{userImport:true}); openingZoom()`),
both side panels open. Produced by `node tools/_t1384-advisory-dock-cdp.mjs --shots docs/reports/T-1384-evidence`.

| File | Width | State |
|---|---|---|
| live-1024.png | 1024×768 | opening state: canvas under 700px, so multi-part notices show their first part and "▸ N more" |
| live-1024-open.png | 1024×768 | both "▸ N more" controls clicked: every part shown, controls read "▾ less" |
| live-1440.png | 1440×900 | opening state: canvas wide, every part shown, no control |
| live-1920.png | 1920×1080 | opening state: canvas wide, every part shown, no control |

Dock top padding (canvas height taken by the advisories), before → after:

| Width | Before | After |
|---|---|---|
| 1024 | 270px of 685 (39%) | 135px (20%) |
| 1440 | 200px | 176px |
| 1920 | 182px | 158px |

The design (operator's option 1): the three advisories (import notice, Clean-layout nudge, authority summary) form one card of
one width, rows joined, each row's controls at its right edge. Below a 700px canvas a notice with more than one part shows
its first part and "▸ N more"; one click shows the rest. No warning text was removed or reworded.
