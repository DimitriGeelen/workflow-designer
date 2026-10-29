# T-1266: can a save write a subprocess's contents back inside it?

**Status:** framed, research not started (2026-10-28). Inception per the operator's ruling on
`docs/reports/T-1329-open-job-c-findings-brief.md` (job C F8).

## The question (IW-1)

Today a save moves a subprocess's contents up into the process: import collects nodes from the process and from every
subProcess inside it (`foreignContainers`), and export writes them all as direct children of `<process>`. The saved
process then has two start events and an empty subprocess, which an engine runs differently. The import notice names it
(T-1327). Can the designer write the contents back inside the subprocess on save, while still drawing them flat,
without breaking lanes, flows that cross the subprocess boundary, display ids, or validation?

## Options to weigh

- **(a)** remember each node's parent subprocess at import and nest it on export, drawn flat (no canvas change);
- **(b)** a real nested subprocess model, drawn nested;
- **(c)** keep the notice only.

## What the research must establish first

- Which subprocess shapes the fixtures carry (5 of 11 third-party files have one): plain, event, transaction,
  ad-hoc; nesting depth; whether any flow crosses the subprocess boundary.
- How lanes relate: a lane's flowNodeRef may name a node inside a subprocess.
- What happens to a nested node the person moves or deletes, and to a flow drawn into or out of the subprocess.
- What AEF's importer does with nested contents (their maps carry none today).
- The duplicate display ids of events inside subprocesses (T-1102) touch the same code path.

## Dialogue Log

- 2026-10-28, operator, on the T-1329 brief: "Proceed as you should fit and suggest" — F8 becomes an inception.

## Findings (research, 2026-10-29)

Measured = read from the files or the source with a command (script: an ElementTree walk of each fixture's
`<process>`, descending only into subProcess / transaction / adHocSubProcess). Inferred = reasoned from the code, not run.
Line numbers are `src/aef-workflow-designer.html` (15 777 lines) unless another file is named.

### F1. Which fixtures carry subprocesses with contents

Measured. 5 of 11 files in `tests/fixtures/third-party/` have a subprocess-kind element; **4 have one with contents**.

| File | Container (kind) | Parent, depth | Nodes inside | Flows inside |
|---|---|---|---|---|
| `simple.bpmn` | SubProcess_1 (subProcess) | process, 1 | 2 (startEvent, task) | 1 |
| `boundary-events.bpmn` | SubProcess_1 (subProcess, isExpanded) | process, 1 | 2 (startEvent, task) | 1 |
| `nested-subprocesses.bpmn` | SubProcess_1 (subProcess) | process, 1 | 3 (subProcess, startEvent, exclusiveGateway) | 2 |
| | SubProcess_2 (subProcess) | SubProcess_1, **2** | 3 (startEvent, userTask, endEvent) | 2 |
| `kitchen-sink.bpmn` | Activity_088fmm5 (subProcess, `triggeredByEvent="true"`) | process, 1 | 12 (all startEvent) | 0 |
| | Activity_0djfr8f (**transaction**) | process, 1 | 1 (endEvent) | 0 |
| | 6 more: 2 subProcess, 2 adHocSubProcess, 1 transaction, 1 event subprocess (Activity_1fi82ot) | process, 1 | 0 | 0 |
| `aef-draft-inception-readiness-v2.bpmn` | agt_4_explore (subProcess) | process, 1 | 0 | 0 |

- Totals: 23 nested nodes, 6 nested flows, in 6 containers; deepest nesting 2 (one file).
- No adHocSubProcess has contents. One transaction has contents (one endEvent). One event subprocess has contents (12 start
  events, no flows: a catalogue of start-event kinds, not a runnable body).
- Start events, top level vs anywhere: simple 1/2, boundary-events **0**/1, nested-subprocesses 1/3, kitchen-sink 4/16.
  So after today's hoist boundary-events gains its only start event, and kitchen-sink goes from 4 to 16 top-level starts.
- `kitchen-sink.bpmn` has 4 extra `BPMNPlane`s (collapsed-subprocess drill-down planes for Activity_0g37k20, _0r6ceyw,
  _137lgd1, _1fi82ot); all 4 are self-closing (empty). Export writes one BPMNDiagram (`:14087`), so they are dropped
  today; nothing is drawn in them.
- AEF's own dialect (`aef-draft-inception-readiness-v2`) is the childless subProcess; `tools/_t523-nesting.pin.json`
  (`_finding_collapsed`) records that 100% of AEF's real subProcess usage is childless.

### F2. Flows across a subprocess boundary

Measured: **0 of 30** sequenceFlows across the 5 files cross a boundary; every flow's sourceRef and targetRef are
children of the container the flow is declared in (simple 0/3, boundary-events 0/1, nested-subprocesses 0/5,
kitchen-sink 0/3, aef-draft 0/18). Connections from outside to a subprocess go to the subprocess itself, or through a
boundaryEvent attached to it (boundary-events: BoundaryEvent_1, _3 on SubProcess_1; kitchen-sink: 5 boundary events on
Activity_0pzvbay / Activity_0djfr8f). No boundary event in the fixtures is attached to a NESTED node.

Measured, ordering: in `boundary-events.bpmn` the inner sequenceFlow is declared between the startEvent and the task
(lines 7-8), i.e. other tools interleave flows and nodes inside a subprocess.

### F3. Lanes

- Measured: only 2 of the 4 files with contents have lanes (kitchen-sink; aef-draft has lanes but an empty subprocess).
  In kitchen-sink **no lane flowNodeRef names a nested node**; all 13 nested nodes (12 event-subprocess starts + the
  transaction's endEvent) are in no lane (refs: Lane_1cofr07 51, Lane_1vakzes 14, none nested). So the tool that wrote it
  (Camunda Modeler) leaves subprocess contents out of the process's lanes.
- Measured, code: `parseBpmnXml` sets `laneId = null` and takes the first `bpmn:lane` whose `flowNodeRef`s contain the
  node's id (`:15084-15088`); there is no inheritance from the enclosing subprocess. So hoisted nodes get `lane: null`
  whenever the file does not list them (the T-891 rule, comment `:15066-15083`).
- Measured, code: export writes a lane's `flowNodeRef`s from `s.nodes.filter(x => x.lane === lane.id)` (`:13886-13889`),
  so a `lane: null` node gets no flowNodeRef. Display ids put all lane-null nodes in one "unlaned" group, prefix `lan`
  or the next free variant (`computeDisplayId`, `:2351-2373`, T-1102).
- Measured, validator: `tools/validate-workflow.py:1365-1373` raises E-XML-NODE-UNASSIGNED for a flow node in no lane.
  Inferred: a saved kitchen-sink therefore carries 13 such errors today, caused by the hoist (nested, they would be
  inside the subprocess — whether the rule should then apply to them is a rule question, see F5).
- `childLaneSet` (nested lanes) is a different notice line (`nestedLanes`, `:15458`); no fixture puts a `laneSet` inside
  a subprocess, and `laneSet` is in `ELEMENT_READ_CHILDREN` (`:14232-14234`), so one would not be kept.

### F4. Where the source hoists, keeps, and writes

Import (`parseBpmnXml`):
- `nodeTags` (`:14936-14939`) includes `subProcess` but not `transaction` / `adHocSubProcess`; those two arrive through
  the foreign branch with `foreignTag` (`:15017-15025`) and are re-emitted under their own tag.
- Allowlisted nodes are collected with `byBpmn(proc, tag)`, a DESCENDANT query (`:15009`; `byBpmn` `:14694`), so they
  are found at any depth. Non-allowlisted children (`bpmn:task`) are found by walking `foreignContainers =
  [proc, ...byBpmn(proc, 'subProcess')]` (`:15017`). **Measured gap:** a `transaction` or `adHocSubProcess` is not in
  `foreignContainers`, so a `bpmn:task` inside one is never collected (the T-1131 dangling-ref class). No fixture has that
  case today (kitchen-sink's transaction holds an allowlisted endEvent).
- `nodeWork` is sorted into document order (`:15030`, T-1271), so a subprocess always precedes its contents in
  `state.nodes`, and nested-subprocess contents follow their own subprocess.
- Sequence flows: `byBpmn(proc, 'sequenceFlow')` (`:15353`), a descendant query; flows inside subprocesses are read
  with the rest and carry no container.
- The subprocess's kept children: `elementKept(el, NODE_READ_ATTRS, c => nodeWorkEls.has(c))` (`:15033`, `:15281`).
  Its own nodes are skipped through `nodeWorkEls`; its sequenceFlows, laneSet, data objects and artifacts are skipped
  because they are in `ELEMENT_READ_CHILDREN` (`:14232-14234`). Kept: attributes such as `triggeredByEvent` (measured on
  Activity_088fmm5, Activity_1fi82ot), loop characteristics, other tools' extensions.
- The notice: `hoisted = nodeWork.filter(w => SUBPROC_TAGS.has(w[1].parentNode.localName))` (`:15451-15457`) counts only
  the IMMEDIATE parent, so `hoistingSubs` counts SubProcess_2 in nested-subprocesses as its own container (correct), and
  the notice text is at `:10712-10714`.

Export (`buildBpmnXml`):
- Lanes first (`:13879-13892`), then every node in `s.nodes` order as a direct child of `<bpmn:process>`, each element
  opened and CLOSED in the same iteration (`:13895-13965`: `</bpmn:${tag}>`), then every edge (`:13968` ff.). So nesting
  needs the node loop to stop closing a container until its contents are written, and edges to be written inside the
  container that owns both ends.
- DI: one plane; each node a BPMNShape, kept geometry while unmoved (`keptShapeXml`, `:14101`, `:14332-14341`), else
  `NODE_DEFAULTS` size (subProcess 120x64, `:2439`). Kept shape attrs (e.g. `isExpanded="true"`) survive only while
  unmoved.
- `deleteNode` (`:11534-11542`) removes the node and its incident edges only.

Validation (`tools/validate-workflow.py`): collects flow nodes from `list(process)`, **direct children only**
(`:1144`, also `:1688`, `:2111`), and its vocabulary comment says child nesting is "phase 2 (own inception) — nothing here
permits children yet" (`:57-58`). Inferred: under (a) a saved file's nested nodes become invisible to it, and every flow
naming them (now declared inside the subprocess, also invisible) — the validator would need a walk or would report the
subprocess as a node with no visible body. Existing pins that encode today's hoist: `tools/_t523-nesting.pin.json`
(`child_a/child_b: survived-flattened`) and its teeth `tools/_t523-nesting-teeth.py`; both move under (a).

State option (a) needs (inferred, from the above):
1. `n.parent` = the uid of the enclosing subprocess / transaction / adHocSubProcess (null at top level), set from
   `el.parentNode` at import; serialised in the project JSON and, for a designer-written file, implied by nesting.
2. Edges: no stored field needed if the container of an edge is derived from its ends (both ends share a parent, per F2).
3. Export order: emit a container's contents (nodes and flows) between its open tag and its close, recursively;
   `incoming`/`outgoing` stay per node. The kept order (interleaved flows, `boundary-events.bpmn:7-8`) is not
   reproduced today either; document order of nodes is kept by T-1271.
4. Display ids: unchanged in principle (they are per lane), but the T-1102 unlaned group then mixes top-level and nested
   lane-null nodes; ids must stay unique across the whole file because BPMN ids are document-global.
5. Lanes: decide whether nested nodes get flowNodeRefs in the process's laneSet (kitchen-sink's writer gives none).
6. DI: nested shapes stay in the same plane; once the person moves a nested node the designer writes its flat position,
   which can fall outside the subprocess's bounds (inferred; other tools would draw it outside its container).
7. The notice line (`:10712-10714`) changes from "NOT kept" to a statement that nesting is kept but drawn flat.
8. `foreignContainers` (`:15017`) should include transaction and adHocSubProcess regardless of the option (F4 gap).

### F5. Cases that need a rule under option (a)

1. **Nested node moved to another lane** — the lane is display; does it change containment? (proposal space: no; lane
   and parent are independent). And does a nested node get a flowNodeRef at all (F3)?
2. **Nested node dragged visually outside the subprocess** — drawn flat, there is no visible boundary; containment
   cannot follow the drag unless the canvas shows the box.
3. **Subprocess deleted** — `deleteNode` leaves its contents in `state.nodes` with a `parent` naming nothing: hoist them
   (contents to the parent's parent), delete them with it, or refuse. A nested subprocess (depth 2) chains this.
4. **Subprocess retyped** (to a task) — a task cannot contain nodes; the same three choices. Kept children are already
   dropped on retype (`:13921` comment).
5. **Flow drawn between a nested node and an outside node** — BPMN forbids it; no fixture has one (F2). Refuse at draw
   time, warn in validation, or re-parent one end.
6. **Flow drawn between nodes of two different subprocesses**, or between a subprocess and its own content — same rule.
7. **New node added** — top level by default; nested only by an explicit action (no gesture exists flat).
8. **Copy/paste or duplicate of a nested node / of a subprocess** — copy the parent link, and the contents?
9. **Boundary event attached to a nested node** — must sit in the same container as its host (none in fixtures).
10. **Event subprocess** (`triggeredByEvent`): its start events have no incoming flow and are not process starts; the
    validator's reachability (W-UNREACHABLE seeds from every startEvent, `validate-workflow.py:797`) and any
    "one start event" reading must skip them.
11. **Undo/redo** — `parent` must ride history snapshots like `lane` does.
12. **Project JSON and AEF's map** — AEF's importer reads nested contents not at all today (their maps carry none,
    framing); a nested save is new input for them (release note, per the AEF rule in CLAUDE.md).

## Options compared

| | (a) remember parent, nest on save, draw flat | (b) real nested model, drawn nested | (c) notice only (today) |
|---|---|---|---|
| Fixes | Saved XML keeps containment for all 23 nested nodes in 4 fixtures; engines run the file as written; start events stay in their scopes | Same as (a), plus the person sees and edits containment | Nothing in the file; the person is told (T-1327) |
| Costs | Import: one field from `parentNode`. Export: recursive node/flow emission instead of the flat loop (`:13895-14030`). Rules for F5 cases 3-6 and 9 at least. Validator walk (`validate-workflow.py:1144` and two more loops). Re-pin T-523. Notice text. | All of (a) plus canvas: container shapes with bounds, hit-testing for drop-into/out-of, auto-resize, nested routing, lane interaction; every person-sees-gate harness | None |
| Risks | Containment invisible on canvas, so moves/deletes change it silently or not at all; flat positions written into DI can lie outside the container's bounds; a flow the person draws across the boundary has no visible reason to be refused | Large UI change on a 16k-line single file; the toolbar/layout regressions class (T-1172); AEF's whole corpus has no contents to benefit (T-528 pin) | Engines run a different process after open→save (boundary-events gains its only start at top level; kitchen-sink 4→16 top-level starts); E-XML-NODE-UNASSIGNED on hoisted nodes |
| Who it serves | Files from other tools (4 of 11 fixtures) | Same, plus authoring nested processes | — |

## Recommendation (orchestrator, 2026-10-29)

Checked against the source before writing: `foreignContainers` lists only `subProcess` (`:15017`) and the validator walks
only `list(process)` (`validate-workflow.py:1144`, `:1688`), both as the research says.

**GO on (a), in two slices, scoped to preserving what arrived, not to authoring nesting.**

- **Why not (c):** today a save changes what an engine runs: boundary-events gains its only start event at the top
  level, kitchen-sink goes from 4 to 16 top-level starts. That is the one remaining case where an unedited open→save
  changes a third-party process's meaning, after T-1325..T-1264 closed the rest; the notice names it but cannot undo it.
- **Why not (b):** it is a canvas redesign for a case AEF's corpus never has (T-523 pin: every AEF subProcess is
  childless). Its cost lands on the riskiest surface (layout, the T-1172 class) for no AEF benefit.
- **Why (a) is affordable:** no flow crosses a boundary in any fixture (F2), so a flow's container follows from its two
  ends and needs no state; the import already reads nested nodes in document order with the subprocess first (F4).
  The new state is one field per nested node.

**Slice 1 — round-trip (the open, look, save case):** record each nested node's parent subprocess at import; export
writes nodes and flows inside their container (recursive emission instead of the flat loop); the validator walks
containers; nested nodes outside lanes are not E-XML-NODE-UNASSIGNED (Camunda leaves them out of lanes, F3); the import
notice drops the "nesting NOT kept" line for files whose nesting is now kept; re-pin T-523. Done when the 4 fixtures
save with containment, a second save is byte-identical, and designer-written maps are unchanged.

**Slice 2 — edits (each a rule, from F5):** a nested node keeps its parent through moves and lane changes (the canvas
shows no container, so nothing implies it left); a flow drawn between a nested and an outside node is refused with a
message (BPMN forbids it); deleting a subprocess moves its contents to the top level and the notice says so (no silent
loss); new nodes are never nested. Each rule with a harness leg.

**Separately, now:** T-1337, a plain `bpmn:task` inside a `transaction` or `adHocSubProcess` is dropped on import — a
data-loss bug independent of this decision.

**If NO-GO:** keep (c), and file T-1337 anyway.
