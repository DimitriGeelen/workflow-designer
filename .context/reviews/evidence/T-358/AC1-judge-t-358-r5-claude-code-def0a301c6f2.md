# T-358 AC1: independent review (seat claude-code, dispatch judge-t-358-r5-claude-code-def0a301c6f2)

Revision: 91dcac38f14a7f98aa51e62bcd1495d3db18a245. The evidence dir is clean against it: the last commit touching it is 91dcac38f, with no working-tree changes.

## What I looked at
I opened all 22 PNGs myself: 7 maps × 1024/1440/1920 plus boundary-events-1024-bottom.png. I did not rely on the earlier runs' reports in this directory.

## Per map (vertical extent, which is the scope narrowed on 2026-11-08)
| map | 1024 | 1440 | 1920 |
|---|---|---|---|
| simple | ok: all 5 elements between header (y≈236) and bottom (y≈507) | ok | ok |
| boundary-events | top ok; the bottom is off-frame in the opening frame. The -bottom shot shows joker (y≈642–685) inside the bottom border (y≈710) | ok: Task_2 "(task)" tag y≈297 is below the header, joker above the bottom border y≈795 | ok |
| collaboration-message-flows | ok; the read-only pool (y≈495–595) is below ours (bottom y≈455) with the add-lane band between them, no overlap | ok (ours ends y≈437, read-only starts y≈478) | ok (ours ends y≈392, read-only starts y≈433) |
| i18n-documentation | ok | ok | ok |
| multiple-diagrams | ok | ok | ok |
| nested-subprocesses | ok vertically (header y≈272 … bottom y≈643) | ok (end event label y≈637 < border y≈663) | ok (ExclusiveGateway is inside too) |
| zeebe-service-task | ok | ok | ok |

In all 22 frames:
- **No lane band or lane header** is drawn: one pool header ("<Process> · workflow:<id>") and no "FRAMEWORK · AUTHORITY"-style lane labels. Compare v0.40.0-nested-subprocesses-1440.png, which has them.
- **"+ Add a lane"** is a dashed band directly below the pool. The label reads "Add a lane", not "Add another lane".
- **Advisory card** controls (× dismiss, "▸ 1 more", "Clean layout") are visible and unobstructed at every width.

## Observations (non-blocking, outside this criterion's narrowed scope)
1. At 1024 the "+ Add a lane" label is centred in a band that runs under the inspector panel, so the text itself is hidden. Only the empty band shows to the left of the panel. The control is still there, but you have to scroll or collapse the panel to read it.
2. In collaboration-message-flows (1440/1920) the message-flow lines cross the add-lane band and its label. One arrowhead lands on the "Pool · read-only" label. These are edges crossing the gap between pools, not the pools overlapping each other.
3. nested-subprocesses: the left-edge start event across the pool border is out of scope and filed as T-1386.

## Verdict
green. Every map draws one pool whose top and bottom enclose the whole diagram, with no invented lanes, at all three widths.
