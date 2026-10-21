# T-962 Human AC#1 — does the finding marker duplicate "⚠ no authority", and should it?

Reviewer: reviewer-judge-t-962-r3-74bac7cd8b45 (rung-3-termlink-single-reviewer), revision 5ac9f04504fa052ad6972f659e5a15432326fac4.
Not a risk call (no Tier 0, nothing irreversible, no sovereignty/direction question): a marker-placement
policy inside one UI, so it is decided here per the operator ruling.

## What I checked
1. Code, src/aef-workflow-designer.html:
   - Authority marker (T-893/T-1092) ~L4250-4270: drawn top-left when `authorityMarkerState(own, effectiveLaneDefault(lane))`
     is 'missing'; only if `labelPrefs.showAuthority`; folded into one summary instead when `!mapDeclaresAuthority()`.
     Live, derived from the model, needs no Check.
   - Finding marker (T-962) ~L4298-4320: drawn bottom-right from `findingsView.byNode`, only after **✓ Check**, severity-coloured.
   - Lane-anchored rules (W-XML-LANE-CAPACITY/GEOMETRY, T-1164) mark the LANE header, not a node.
2. Validator tools/validate-workflow.py L1338-1346: the only node-anchored "no lane" rule is E-XML-NODE-UNASSIGNED; its
   comment records 0 unassigned nodes across the authored corpus (24 maps, 306 flow nodes).
3. Ran `python3 tests/test_t962_findings_on_map.py`: 11 passed, 0 failed. Includes the leg "a node dragged clear of the
   lanes keeps its lane (the designer refuses to orphan it)".
4. Headless probe (AC1-judge-t-962-r3-74bac7cd8b45-probe.py, Playwright on the working-copy designer served by tools/gallery-serve.py):
   - **A. The AC's own steps** (drag a step below every lane band, then Check): on the node, finding markers = [],
     authority markers = []; lane headers marked = 1; dock rows = [W-XML-LANE-GEOMETRY, W-XML-LANE-CAPACITY].
     Screenshot AC1-judge-t-962-r3-74bac7cd8b45-dragged.png.
   - **B. A dangling lane ref** (node.lane points to a lane that doesn't exist, no own authority; map declares authority):
     finding = [E-XML-NODE-UNASSIGNED] (red ✖ bottom-right) AND authority = [missing ⚠] (top-left), both on the same node.
     Screenshot AC1-judge-t-962-r3-74bac7cd8b45-unassigned.png. The two marks are in opposite corners and don't overlap.

## Findings
- **The AC's premise is wrong for the path it describes.** Dragging a step below the lanes produces NEITHER mark on the
  step. The designer keeps its last lane, so the lane default still applies and there is no ⚠. The resulting findings
  are lane-anchored and mark the lane header, not the node. The two marks only co-occur when a node's lane reference is
  invalid (imported/hand-edited file, lane removed underneath). That case is E-XML-NODE-UNASSIGNED, the map must declare
  authority somewhere, Settings must show authority markers, and the node must have no own authority. The authored corpus
  has zero such nodes.
- **Decision: leave both. Don't suppress or merge.**
  1. They're not the same condition. ✖ appears without ⚠ whenever the node has its own authority. ⚠ appears without ✖
     for any in-lane node whose lane has no default. They overlap only in the subset above.
  2. They have different sources and lifetimes. ⚠ is live and depends on display settings (showAuthority; T-1092 folds
     it into one summary on undeclared maps). ✖ is the validator's verdict from the last Check. Hiding ✖ "when ⚠ is
     showing" would make whether a validator ERROR is visible depend on a display preference and on T-1092's per-map
     rule. That is the silent-drop failure the T-964 comment on FINDING_MARKER_EXCLUDED rejects ("exclusion is not
     suppression", loud is better than silent). It would also make the dock's "N on the map" count wrong.
  3. Merging would tie a model-derived marker to a validator snapshot for a case that doesn't occur on authored maps.
     That's engineering for a case the AC itself says to drop.
  4. ✖ carries severity (ERROR, and it blocks compile). ⚠ is an authoring hint. Both carry information.

## Verdict
green: the judgement is made (leave both), with evidence that the duplication is rare (only via an invalid lane ref) and
harmless (opposite corners, no overlap). Follow-up for the task author: fix Step 2/3 of this AC. Dragging below the lanes
doesn't produce the co-occurrence; a node whose lane ref is invalid does.
