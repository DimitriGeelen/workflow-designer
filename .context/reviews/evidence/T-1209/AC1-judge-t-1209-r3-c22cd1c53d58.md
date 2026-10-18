# T-1209 Human AC#1 — independent screenshot review

Reviewer dispatch: judge-t-1209-r3-c22cd1c53d58 · revision 1f75e60aca80cc11a586a7a44c279ab372232b92

## Provenance
All six screenshots have identical git blob hashes in the working tree and at revision 1f75e60a
(1024 after 911c9e56, 1440 after 23610dbe, 1920 after 1bc32272; before f30d19c6 / ae118a74 / 084351af).
I copied them here as before-*.png / after-*.png.

## BEFORE (docs/reports/T-1127-evidence/2026-10-19/)
At 1024, 1440 and 1920 the modal body opens scrolled down: the first row shown is Display ID / UID,
and the element header (serviceTask · age_1_call) plus the BPMN Name/Slug row are above the fold. This confirms the defect.

## AFTER (docs/reports/T-1209-evidence/), checked one control at a time
| control | 1024 | 1440 | 1920 |
|---|---|---|---|
| Element header (icon, "serviceTask", "age_1_call") at top of body | ok | ok | ok |
| BPMN Name ("Call the service") / Slug ("call") row | ok | ok | ok |
| Close button (top-right of modal header) whole, unclipped | ok | ok | ok |
| Extensions in two columns, no overlap/clipping (Authority/Horizon, Workflow type/Tier, Determinism/Agent type, Endpoint/Context reads, Artifacts writes/Side effect, ...) | ok (the rows below the fold are cut by the scroll viewport only, as expected) | ok | ok |
| Tier buttons T0 T1 T2 T3 whole, T2 selected | ok | ok | ok |
| Horizon shows the orange note "hidden in the side panel by this project" | ok | ok | ok |

The scrollbar thumb sits at the top in every AFTER shot, so the body scrollTop is 0.

## Regressions
None seen. The layout, column widths, Tier group and Horizon note match the BEFORE shots, which are just
offset by the scroll. One difference: Side effect now reads "writes the ledger twice" instead of "writes the ledger".
That is fixture data from an edit (the side panel shows the same value), not a rendering change. It is
consistent with the commit note "edits still keep the place".

## Limits
I reviewed the screenshots only and did not drive the app myself. The criterion is defined over these screenshots.
