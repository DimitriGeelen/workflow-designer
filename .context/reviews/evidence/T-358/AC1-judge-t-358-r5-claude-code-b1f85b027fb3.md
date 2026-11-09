# T-358 AC1: independent review (rung-5-panel seat claude-code)

Revision reviewed: 76ee72d11c5e84ce48a4851337623364eda03695
Criterion: [REVIEW] A map that declares no lanes reads correctly without the lanes the importer used to invent.
Scope as narrowed 2026-11-08: the vertical extent. The left edge of nested-subprocesses is out of scope (T-1386).

## What I opened
I opened all 21 screenshots in docs/reports/T-358-evidence/ (7 maps x 1024/1440/1920) and boundary-events-1024-bottom.png.
I viewed each one myself. I did not use any other reviewer's report.

## Checks per map (all three widths)
| Map | Pool encloses all shapes top to bottom | Lane band or header | "+ Add a lane" below the pool | Advisory controls |
|---|---|---|---|---|
| boundary-events | yes. SubProcess_1 and its boundary events are near the top, joker is near the bottom; the pool's bottom edge (about y=795 at 1440, 751 at 1920, 706 in the 1024 bottom scroll) is below joker's label | none | yes (at 1024 the strip shows in the bottom scroll, partly under the Mode chip, which is a canvas overlay) | ×, "1 more" and Clean layout are visible |
| collaboration-message-flows | yes. Task_1, Task_2 and the end event are inside; the end label is above the bottom edge | none | yes, between the two pools | × visible |
| (step 3) second pool | "Pool · read-only" is drawn below ours with the add-lane strip between them; no overlap. Message flows cross the gap as dashed lines, which is expected | | | |
| i18n-documentation | yes. The "(task)" tag sits just under the header, inside the body | none | yes | ×, Clean layout visible |
| multiple-diagrams | yes, the single task A | none | yes | ×, "1 more" visible |
| nested-subprocesses | yes vertically. The subprocesses are near the top and the end event and its label (lan_end_endevent) are above the bottom edge at 1440 and 1920 | none | yes | ×, Clean layout visible |
| simple | yes. Sub Process 1 is near the top and Task/End Event are above the bottom | none | yes | × visible |
| zeebe-service-task | yes | none | yes | ×, Clean layout visible |

At 1024 the inspector panel crops shapes on the right (Activity_08bosyf, Task_2, the third start event). That cut is horizontal and comes from the viewport, not the pool, so it is outside this criterion's scope.
The advisory text itself says "the file's original pool and lane outlines are NOT kept", which matches the change.

## Out of scope, noted
nested-subprocesses: the first start event at x~293 sits on or near the pool's left border at 1440 and 1920. The scope narrowing excludes this; it is filed as T-1386.

## Verdict
green. Every map draws one pool whose top and bottom enclose the whole diagram, with no invented lane band or header, at all three widths. The read-only second pool sits below ours without overlapping it.

Cited copies: boundary-events-1024-bottom-judge-t-358-r5-claude-code-b1f85b027fb3.png, collaboration-message-flows-1440-judge-t-358-r5-claude-code-b1f85b027fb3.png, nested-subprocesses-1920-judge-t-358-r5-claude-code-b1f85b027fb3.png
