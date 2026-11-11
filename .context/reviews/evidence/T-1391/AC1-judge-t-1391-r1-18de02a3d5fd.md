# T-1391 AC1 — independent review (rung-1-same-vendor-independent)

Revision reviewed: c8148b3ac8761723026b1a3ea8f47da07a291d8b (HEAD at review time matched).
Sources: docs/reports/T-1391-evidence/{settings,properties}-{1024,1440,1920}.png (copies in this directory, suffixed with the dispatch id).

## Settings (settings-1024/1440/1920)
- The whole Editor Settings dialog is in view at all three widths: sections ROUTING, SNAPPING (WHILE DRAGGING), VIEW, LABELS, then the footer ("Stored in this browser only..." + "Reset to defaults").
- There is no "Project field profile" row and no "Fields shown by default" section anywhere.
- In VIEW, "Clean layout when opening a file" is followed by "Show all fields in the properties panel" (with its hint text). Next comes the LABELS section heading, which is a real section heading and not a leftover, then "Fit lane names...". The vertical rhythm between these rows matches the rest of the dialog: there is no extra gap and no stray or empty heading.
- At 1024 the dialog sits over the properties panel and fits inside the viewport. Nothing is clipped.

## Properties (properties-1024/1440/1920)
- OTHER EXTENSIONS · 1 shows the explanation "Carried by this node in the source document. Shown read-only — these keys are either derived from the diagram or not authored here. They are not lost." It ends at "They are not lost." and there is no sentence about suggesting.
- Below the explanation come the key "costCentre", a read-only field "CC-1" and the evidence line "costCentre · on 1 of 1 serviceTask element".
- There is no "Suggest as a field" button. The section ends cleanly and I/O CONTRACT follows with normal spacing.
- The same holds at all three widths. Text wraps cleanly in the narrower panel at 1024.

## Limits
These are screenshots only. That the portal serves neither endpoint is the producer's stated setup (_t1134 --shots); I did not re-run the harness. The criterion is a render-surface judgement, and that judgement is fully supported by the images.

Verdict: green.
