# Reviewer evidence — T-358 AC#1

- dispatch: `judge-t-358-r5-opencode-d9e22392b6ff`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `9f07871f147fcbd65ea0450f3cdc8b49a14bb885`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `c5449f9fc8aa1f8e98cb1db0929728e1f5ea486a570fea9ae43c9dd92ed2a036`
- result.md sha256: `b068f3224daae979a9ea234665db883e83f35b5dcc29eb8c45cdaee00d80d37e`

## The worker's verdict block

```
1. [AC] Lane-less map renders correctly without invented lanes (one pool enclosing the diagram, all widths)
VERDICT: green
WHY: This seat cannot view images, so I used the criterion's sanctioned fallback (measurements.txt) and cross-checked it against the reviewed revision's source rather than taking it on trust. measurements.txt records 105/105 legs green across the 7 lane-less fixtures × 1024/1440/1920: pool outline present, 0 lanes in state, 0 lane bands/headers drawn, every node's rendered rect within the pool-border's height (the vertical-extent check the 2026-11-08 narrowed scope judges), and saves that invent no laneSet/participant, with collaboration-message-flows' source-declared pool kept; all three poison arms (fabrication back, no-lane pool height removed, invented collaboration rewritten) turn their legs red, so the pass is meaningful. The screenshots exist at exactly the claimed filenames and pixel dimensions. Static verification of this revision confirms each measured behavior in code: poolHeight()'s no-lane branch encloses nodes (src/aef-workflow-designer.html:2947-2958), renderPool() draws no lane furniture with 0 lanes and one pool-border rect of that height (:4059-4114), "+ Add a lane" sits at py+ph+8 below the pool with the no-lane label (:4126-4130), the advisory card docks above the canvas and never covers nodes, with a reachable expand control on narrow canvases (syncAdvisoryDock, :10962), and the collaboration second pool starts at POOL_Y+poolHeight()+40, strictly below ours with no overlap (:14950). The left-border artifact on nested-subprocesses is out of scope per the narrowing (filed T-1386) and the L2 measurement is vertical-only by construction.
GUIDANCE: None required. One provenance note for the record: measurements.txt's header says it ran at c11a10462 while this review is of 9f07871f (the export has no .git to reconcile them); since every code path and all three poison anchors the run asserts against are present in the reviewed revision, the recorded run is consistent with this tree, but a future evidence run recorded at the exact reviewed hash would remove even that gap.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
All evidence files present: 21 screenshots (7 maps × 3 widths), plus `boundary-events-1024-bottom.png` and the v0.40.0 comparison. Reading the measurements file first, then viewing screenshots.
Measurements file confirms all 105 legs pass with 3 poison arms caught. Now viewing the screenshots directly to verify the visual claims.
This seat cannot view images (no image input support in this model). The criterion explicitly provides the fallback path: "A seat that cannot view images reads `measurements.txt`" — done above. Let me still corroborate independently: check the PNG dimensions match the claimed widths, inspect the self-test tool, and check the render code.
PNG dimensions match the claimed viewports. Now inspecting the self-test tool that produced the measurements.
The self-test tool measures from the live DOM: pool-border rect vs every node's bounding rect (vertical containment, ±1px), lane state/bands, and save output — matching the criterion's fallback path. Note the measurements header says it ran at `c11a10462` while I review `9f07871f` — I'll verify the current export's source actually contains the checked behaviors. Checking fixtures and designer source.
Fixtures check out: 11 BPMN files, 4 declare laneSet, leaving exactly the 7 lane-less maps from measurements.txt; collaboration-message-flows declares 2 participants (the negative control). Now reading the key source paths: `poolHeight()` with no lanes, the lane-less pool draw, and the second-pool placement.
`poolHeight()` encloses nodes when no lanes exist (src/aef-workflow-designer.html:2947). Now checking the lane-less pool rendering (no bands drawn) and the collaboration second-pool placement.
`collabLayout` places the second pool at `POOL_Y + poolHeight() + 40` — strictly below our pool's bottom edge, so no overlap. Now checking `renderPool` for the lane-less case (no bands/headers drawn) and the "+ Add a lane" placement.
`renderPool` draws lane bands/headers only inside the lanes loop (0 lanes → none drawn), the `pool-border` rect encloses `poolHeight()`, and the "+ Add a lane" strip sits at `py + ph + 8` — below the pool, with the no-lanes label (src/aef-workflow-designer.html:4130). Now verifying the poison anchors exist in this revision (ties measurements.txt to this tree) and locating the advisory card.
All three poison anchors exist in this revision. Checking the advisory-card placement logic and the importer's no-lane path.
Verification complete. This seat cannot view images (model lacks image input), so per the criterion's explicit fallback I judged from `measurements.txt`, and independently verified the reviewed revision's code implements every behavior the measurements assert. Evidence summary:

- **Files**: all 21 screenshots + `boundary-events-1024-bottom.png` + v0.40.0 comparison present; PNG pixel dimensions match the claimed 1024/1440/1920 viewports exactly.
- **measurements.txt**: 105 legs green — for each of the 7 lane-less fixtures × 3 widths: pool outline present (L0), 0 lanes in state and 0 lane bands drawn (L1), 0 nodes outside the pool's height (L2 — the vertical-extent check the narrowed scope judges), save writes no laneSet/sovereignty and marks `defaulted:no-laneset` (L3), no invented participant/collaboration with `defaulted:no-participant` provenance, and the source-declared pool in collaboration-message-flows kept (L4). All 3 poison arms caught red (fabrication back: 42 legs; no-lane pool height removed: 21 legs; invented collaboration rewritten: 15 legs) — the legs have teeth.
- **Code in the reviewed revision** (checked, not trusted): `poolHeight()` no-lane branch encloses nodes (src/aef-workflow-designer.html:2947); `renderPool()` draws lane bands/headers only inside the lanes loop and the `pool-border` rect spans the full height (:4059, :4114); "+ Add a lane" strip at `py+ph+8` below the pool with the no-lanes label (:4126-4130); importer drops invented lanes and marks provenance (:15423-15442); collaboration's second pool placed at `POOL_Y + poolHeight() + 40`, strictly below ours (:14950); all three poison anchors the self-test requires exist in this tree (:2949, :14148, :15439).

1. [AC] Lane-less map renders correctly without invented lanes (one pool enclosing the diagram, all widths)
VERDICT: green
WHY: This seat cannot view images, so I used the criterion's sanctioned fallback (measurements.txt) and cross-checked it against the reviewed revision's source rather than taking it on trust. measurements.txt records 105/105 legs green across the 7 lane-less fixtures × 1024/1440/1920: pool outline present, 0 lanes in state, 0 lane bands/headers drawn, every node's rendered rect within the pool-border's height (the vertical-extent check the 2026-11-08 narrowed scope judges), and saves that invent no laneSet/participant, with collaboration-message-flows' source-declared pool kept; all three poison arms (fabrication back, no-lane pool height removed, invented collaboration rewritten) turn their legs red, so the pass is meaningful. The screenshots exist at exactly the claimed filenames and pixel dimensions. Static verification of this revision confirms each measured behavior in code: poolHeight()'s no-lane branch encloses nodes (src/aef-workflow-designer.html:2947-2958), renderPool() draws no lane furniture with 0 lanes and one pool-border rect of that height (:4059-4114), "+ Add a lane" sits at py+ph+8 below the pool with the no-lane label (:4126-4130), the advisory card docks above the canvas and never covers nodes, with a reachable expand control on narrow canvases (syncAdvisoryDock, :10962), and the collaboration second pool starts at POOL_Y+poolHeight()+40, strictly below ours with no overlap (:14950). The left-border artifact on nested-subprocesses is out of scope per the narrowing (filed T-1386) and the L2 measurement is vertical-only by construction.
GUIDANCE: None required. One provenance note for the record: measurements.txt's header says it ran at c11a10462 while this review is of 9f07871f (the export has no .git to reconcile them); since every code path and all three poison anchors the run asserts against are present in the reviewed revision, the recorded run is consistent with this tree, but a future evidence run recorded at the exact reviewed hash would remove even that gap.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
