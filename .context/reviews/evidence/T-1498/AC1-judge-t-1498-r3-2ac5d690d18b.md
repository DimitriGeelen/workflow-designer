# T-1498 AC1 (Human AC#1) evidence - reviewer judge-t-1498-r3-2ac5d690d18b

Revision reviewed: 8dae62889d4da2abfaa244a1daa9def6142c8d26

Criterion: two phase rows told apart by labels; labels read as row names, not phases; nothing clipped or overlapping.

## What I checked
Opened all six screenshots (copies in this directory) and cropped the label region of each at full resolution.

- phases-1024 / phases-1440 / phases-1920 (opening zoom): both labels sit at the left of their rows. "Fase in Salesforce" (italic, muted) sits on the baseline of the upper bracket row "1 Qualification"; "Fase" (italic, muted) sits on the baseline of the lower bracket row "Opportunity". Phase names are bold and bright; category labels are quieter and italic, so they read as the row names, not as phases. No clipping or overlap in the label zone at any of the three widths. The cut-off text "2 Needs Analysis (bl..." and "Configu..." at the right edge of the 1024 and 1440 shots is viewport panning, not label clipping.
- phases-fit-1920: label strip enlarged 2x; both labels legible, left-aligned, no overlap.
- phases-fit-1024 / phases-fit-1440: both labels are present at the left of the rows and are not clipped or overlapping, but at captured resolution they are very small (about 6-7 px); they are only readable when zoomed. Commit 5d409618c states the readable floor is the opening zoom, so this is consistent with design, but it is worth noting.

## Verdict
Green: the labels meet the Expected clause (both rows named at the left at all three widths; nothing clipped or overlapping) on the opening shots, and the Fit shots show the same placement without clipping. Caveat: Fit at 1024 and 1440 is legible only on zoom.
