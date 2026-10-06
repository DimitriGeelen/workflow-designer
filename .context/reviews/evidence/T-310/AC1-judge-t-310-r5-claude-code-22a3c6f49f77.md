# T-310 AC1 — reconciliation reads as a repair (reviewer judge-t-310-r5-claude-code-22a3c6f49f77, seat claude-code)

Revision reviewed: c78f56ad4614d7a0477ae7b032ca62e708cb12d7 (src/aef-workflow-designer.html, v0.15.3)

## What I checked
1. Read fixture `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn`: agent lane declared first (band 62..222),
   framework second (222..382). The two conflicting nodes are frw_1_check (framework, y=100) and agt_2_act (agent, y=300).
   The two agreeing nodes are agt_0_start and frw_3_done.
2. Ran the producer's harness against the current src myself: `node tools/_t310-lane-position-conflict-cdp.mjs`.
   Result was exit 0, ok=true, reconciled=2, reimportReconciled=0 (idempotent), laneAtVoid=null.
   Notice text: "⚠ 2 nodes were drawn outside their declared lane — moved back into place".
   Node results: n_check moved to framework (y 100→270, centre in framework); n_act moved to agent (y 300→110, centre in agent);
   n_start stays at y=110 and n_done stays at y=310 (both unmoved). Every node keeps its x.
3. Loaded the fixture in a real headless Chromium through the user-import path (`adoptImportedXml(xml,{userImport:true})`,
   the same path Open project/drag-drop uses). I took my own screenshots at 1720x1000 and 1280x800:
   - AC1-judge-t-310-r5-claude-code-22a3c6f49f77-after-1720.png
   - AC1-judge-t-310-r5-claude-code-22a3c6f49f77-after-1280.png
4. Compared these against docs/screenshots/t310-both-before.png (old build). Before the fix, "framework validates the request"
   sat in the AGENT · INITIATIVE band and "agent carries out the work" sat in FRAMEWORK · AUTHORITY.

## Findings
- "framework validates the request" now sits in **Framework · Authority**. ✔
- "agent carries out the work" now sits in **Agent · Initiative**. ✔
- The notice at the top of the canvas says **2 nodes** were moved back. This matches the 2 conflicts in the fixture. ✔
- It reads as a repair, not as the editor rearranging the work:
  - The notice states a past-tense fix: "drawn outside their declared lane — moved back into place".
  - It can be dismissed.
  - Only the conflicting nodes move, and only vertically. Horizontal order and the agreeing nodes are untouched.
  - The export round-trip is idempotent.
- The producer disclosed that the stacked Clean-layout nudge could cover a top-lane node (visible in docs/screenshots/t310-both-after.png).
  This does NOT reproduce on the current build for this fixture. The clean-nudge computed display is 'none'
  (mapMessiness is below CLEAN_NUDGE_MIN=3), so the lane-fix notice is the only overlay and covers no node at either viewport size.
- Minor cosmetic issue, not part of this criterion: the incoming edge arrowhead to "agent carries out the work" lands on its small
  display-id caption (agt_2_agent). This is a routing nicety and does not affect lane placement or the repair reading.

## Verdict
green. The expected result is met on the reviewed revision. Placement and notice count were verified in the live editor
and in screenshots. Under PD-355 this small visual check is within reviewer judgement.
