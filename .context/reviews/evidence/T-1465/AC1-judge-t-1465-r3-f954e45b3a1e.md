# T-1465 Human AC#1 — independent review (reviewer judge-t-1465-r3)

Revision: 764656bd3ba8c7d77b5b285b93be24dd274fc112. Judged the supplied images in docs/reports/T-1465-shots/; did not re-run the capture (cannot reproduce, not needed). Crops cited below are copies made from those images.

## task-lifecycle (wide before/after)
- Before: 'gate failed — rework' (frw_gw_all -> agt_2_perform) ran below the pool across the "+ Add another lane" strip; its label sat on the strip over the "+ Add another lane" text, which hid that text.
- After: the route leaves All gates pass?, runs up and along the top of lane Framework (just under the Human/Framework divider), comes down at the left and enters Perform the work from the right. The label "gate failed — rework" sits above the line, on the lane divider, and is readable. Source and target can be followed. The 'resume after healing' label moved to the right of its segment and stays readable.
- Cost: the new descent adds one crossing (the Perform the work -> Outcome? loop) and runs close beside the resume-after-healing vertical. These are minor. Overall it reads better than before. **Pair met.**

## task-gate (wide before/after)
- Before: 're-issue' (agt_2_write -> agt_start_agent) and 'agent remediates' (frw_end_block -> agt_1_create) both ran along the strip, with both labels on the strip. (Flow ids come from .editor-versions/task-gate/v4.bpmn.)
- After: nothing is on the strip. ✓
- 'agent remediates': comes down from Block, runs left just under the Framework/Agent divider (label above it, readable), and joins the Started-work -> Create task arrow at its arrowhead on top of Create task. That is acceptable: the shared target port is clear.
- **'re-issue' reads worse.** It leaves Write real acceptance criteria, goes up into the busy Framework band (between the started-work + real ACs lines, just over the top of the Started-work gateway), runs left to x≈375 (original pixels) and then turns DOWN onto the same vertical as the Agent attempts -> PreToolUse flow. For about 110 px it lies exactly on top of that flow, and it ends with a down-arrowhead drawn inside the start-event circle (see task-gate-after-reissue-overlap-*.png). The two flows on that segment cannot be told apart, so a reader cannot follow re-issue into its target. Before, re-issue clearly entered the start event from below. The 're-issue' label also now sits in the busiest band of the map, between the started-work + real ACs lines, and is harder to place on its own line than before.

## Verdict: red
Nothing sits on the strip, and task-lifecycle passes. In task-gate, 're-issue' does not read at least as well as before: its final segment lies on another flow (start -> PreToolUse) and runs into the start event against that flow's direction.
