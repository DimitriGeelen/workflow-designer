# T-358 AC1: independent review (claude-code panel seat, dispatch judge-t-358-r5-claude-code-227e95f9cd33)

Revision reviewed: 9f07871f147fcbd65ea0450f3cdc8b49a14bb885

## What I did
I opened and looked at every one of the 22 screenshots in docs/reports/T-358-evidence/ myself: 7 maps x 1024/1440/1920, plus
boundary-events-1024-bottom.png. I also read measurements.txt (105 legs PASS, poison arms A/B/C each caught) as a
cross-check only, not as the basis for this verdict.

Freshness: the PNGs were last changed in 724bfe0db. Between 724bfe0db and 9f07871f1 the only non-evidence changes are
tests/goldens/third-party/*.golden (save output: collaboration/participant removed, poolProvenance added) and the task
file. No render code changed, so the screenshots show the code under review.

## Per map (vertical extent, lanes, "+ Add a lane", advisory card)
- simple (1024/1440/1920): one pool "Process_1"; Sub Process 1 (top) to Start/End/Task labels (bottom) all inside top and bottom borders. No lane band or header. "+ Add a lane" row directly below the pool. Advisory x buttons and "1 more" visible.
- boundary-events (1024/1440/1920 + 1024-bottom): SubProcess_1 with batman/wonder woman boundary events near the top, joker link event lowest (about y=728 at 1440). All inside the pool. In the 1024 opening frame the pool's bottom falls below the fold. 1024-bottom shows it scrolled: joker and its label sit above the bottom border (about y=708), with the "+ Add a lane" row below it. At 1440/1920, Task_2/superman and CompensationTask are inside. No lanes. Card shows Clean layout button, x buttons and "1 more".
- collaboration-message-flows (1024/1440/1920): our pool "Pool · workflow:process_1" holds Task_1, Task_2 and the end event. The "+ Add a lane" row sits under it, and the second pool "Pool · read-only" sits below that. The two pools do not overlap; only the message-flow dashed lines cross the gap, which is expected. No lane bands.
- i18n-documentation (1024/1440/1920): one pool; "(task)" caption, Activity, start, Ended and their labels all inside. "+ Add a lane" row below. No lanes.
- multiple-diagrams (1024/1440/1920): one pool with task A inside; "+ Add a lane" row below. No lanes. Card names the second process (kept, not shown).
- nested-subprocesses (1024/1440/1920): SubProcess_1/2, UserTask_1, ExclusiveGateway_1 (1920), three start events, end event and lan_end_endevent label all inside top and bottom (pool bottom about y=663 at 1440, label at about 637). "+ Add a lane" row below. No lanes. The first start event crosses the LEFT border, but that is out of scope per the narrowed criterion (T-1386).
- zeebe-service-task (1024/1440/1920): one pool; the two activities, start, end and labels inside. "+ Add a lane" row below. No lanes.

At 1024 the right-hand part of wide diagrams is under the properties panel and is reached by horizontal scroll. That is
not a vertical-extent defect, and the "+ Add a lane" row is still present below the pool, with its text off to the right.

## Result
Every map draws one pool whose top and bottom enclose the whole diagram, with no invented lane, at all three widths.
The collaboration's read-only pool sits below ours without overlap. Advisory card controls are visible.
Screenshots cited (copies): boundary-events-1024-bottom-judge-t-358-r5-claude-code-227e95f9cd33.png, collaboration-message-flows-1440-judge-t-358-r5-claude-code-227e95f9cd33.png, nested-subprocesses-1440-judge-t-358-r5-claude-code-227e95f9cd33.png
