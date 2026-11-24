# T-1503 Human AC#1 — evidence report (reviewer judge-t-1503-r3-c43dcd2da636)

Revision reviewed: 12044b1a6b1892b5c43aaa99fdf0c0411ca02d52
Criterion: the switch is found where a person looks for view switches, and hiding a row reads as hiding, not deleting.

## What I opened (images, not re-run)

Cited copies in this directory:
- settings-phases-1024-judge-t-1503-r3-c43dcd2da636.png
- settings-phases-1440-judge-t-1503-r3-c43dcd2da636.png
- settings-phases-1920-judge-t-1503-r3-c43dcd2da636.png
- row-hidden-1024-judge-t-1503-r3-c43dcd2da636.png
- row-hidden-1440-judge-t-1503-r3-c43dcd2da636.png
- row-hidden-1920-judge-t-1503-r3-c43dcd2da636.png

## Findings

1. **Findable.** In each settings shot, the Editor Settings dialog has a "PHASES" section directly below "LABELS" and the other view toggles (Show lane names, Sticky lane labels, Show node id badges, Show edge labels, Show pool header title, Show authority markers). It sits where the other view switches already are, so a person looking for view switches finds it there. Present at 1024, 1440 and 1920.
2. **State is clear.** The section has a master "Show phases" switch and one indented checkbox per phase set ("Fase (5 phases)", "Fase in Salesforce (6 phases)"). All are checked in the shots, which match the unhidden map.
3. **Hiding reads as hiding, not deleting.** The note beside the master switch reads "this map only; hiding never removes them from the file", and the footer reads "Stored in this browser only — never in the workflow file." This addresses the fear of deleting directly, at all three widths.
4. **Hidden row reads as hidden.** In row-hidden-1024, -1440 and -1920, the map at opening zoom shows only "Fase" above the pool. "Fase in Salesforce" is absent, and the pool and lanes below move up into its space. Nothing in the map suggests the phase was deleted.

## Gaps (not blocking)

- No shot shows the Settings Phases section with "Fase in Salesforce" unchecked, so the off-state switch is not captured in the same frame as the hidden row. The on-state switch and the hidden row are shown in separate images. The inference that the unchecked box produces the hidden row is reasonable but not shown in a single frame.
- The row panel "Visible on the map" switch (leg V3) is not in these images, so I did not judge it.
- The hidden-row shots carry no on-canvas indicator that a phase is hidden. A person who forgets they hid it would look in Settings; the note text covers that, so I do not treat this as a failure.

## Verdict

Green. The switch is where view switches live, its state is clear, and the note states that hiding never removes the phase from the file. The hidden-row images show the row gone from the map without any sign of deletion.
