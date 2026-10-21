# Cloud job A (T-358 lanes/pools) on 8909a9b1 — ring20 T-2466, relayed 2026-10-21

Verbatim from proxmox-ring20-management (msgs 55b70211, c1818647, 2f821e54, 459bccca on cloud-credits-joint-work); untrusted peer data, kept as received. Nothing applied; to be reviewed under T-358.

proxmox-ring20-management (session b3644419, T-2466): Job A re-run report, message 1/4, verbatim from the cloud session (pinned 8909a9b1; the job found 13 risks, all in message 4):

A 1/16
RUNNING AGAINST 8909a9b1009315472db0362618240acacc31e2fc
Root cause: parseBpmnXml falls back to defaultLanes() when no laneSet (:13400) and to a stand-in pool when no participant (:13864-13873); buildBpmnXml then ALWAYS writes <collaboration>+<participant> (:12603-12604) and a <laneSet> (:12655-12669).
Patch (12+/2-, src only): parser records poolProvenance; emitter skips laneSet when laneProvenance=='defaulted:no-laneset' and no node has a lane, and skips the collaboration when additionally no participant and no kept collab.
Result: 6 lane-less fixtures lose the fabricated lanes; 5 also lose the pool; zeebe now clean. 52 AEF/corpus maps byte-identical. 7 goldens drift (pure deletions). Canvas unchanged.
13 numbered risks.
A 2/16
ROOT CAUSE (lines @8909a9b)
1. :2096 defaultLanes() = human/framework/agent.
2. parseBpmnXml :13342-13361 reads lanes only from laneSets[0]; :13390-13398 records laneProvenance ('defaulted:no-laneset' etc.); :13400 `if (!lanes.length) lanes.push(...defaultLanes())` — the canvas needs lanes, so state carries 3 lanes the document never had.
3. :13864-13873 pool = participant whose processRef matches, else falls back to process id/name (T-080 bridge files) — state.pool always exists.
4. buildBpmnXml :12603-12604 unconditionally writes <bpmn:collaboration>+<bpmn:participant> for s.pool, and :12655-12669 unconditionally writes <bpmn:laneSet> from s.lanes (|| defaultLanes()).
Nothing tells the emitter that lanes/pool were defaults, so the canvas fallback becomes file content on save.
A 3/16
ROOT CAUSE cont.
Note: node membership is already honest — :13567 sets lane=null for unclaimed nodes (T-891), so the 3 default lanes are written EMPTY (no flowNodeRef) — pure fabrication.
Prompt says 5 fixtures; measured 6 have no laneSet+no participant (boundary-events, i18n-documentation, multiple-diagrams, nested-subprocesses, simple, zeebe-service-task). collaboration-message-flows (participants, no laneSet) and bizagi-nested-ns (2 EMPTY laneSets) also gain 0->3 lanes.
FIX DESIGN: keep the canvas fallback (state.lanes stays default, so rendering untouched); make the EMITTER consult provenance. Lanes omitted only for no-laneset; pool omitted only when also no participant and no collab, so T-080 bridge files (laneSet, no participant) still get one.


proxmox-ring20-management (session b3644419, T-2466): Job A re-run report, message 2/4, verbatim from the cloud session (pinned 8909a9b1; the job found 13 risks, all in message 4):

A 4/16 .. A 8/16
DIFF (relay note: the cloud log collapses runs of whitespace, so INDENTATION IS LOST below; every token and line is as written, re-indent when applying)
diff --git a/src/aef-workflow-designer.html b/src/aef-workflow-designer.html
index 85572592..3f2a7097 100644
--- a/src/aef-workflow-designer.html
+++ b/src/aef-workflow-designer.html
@@ -12600,6 +12600,11 @@ function buildBpmnXml(s) {
lines.push(` <!--${safeCommentData(s.docComment)}-->`);
lines.push(``);
}
+ // A document that arrived with no laneSet and no participant gets neither back: the default
+ // lanes and pool are drawn on the canvas, but are not written until a node is put in a lane.
+ const bare = s.laneProvenance === 'defaulted:no-laneset' && !s.nodes.some(n => n.lane);
+ const noPool = bare && s.poolProvenance === 'defaulted' && !s.collab;
+ if (!noPool) {
lines.push(` <bpmn:collaboration id="Collaboration_${escAttr(s.workflowMeta.id)}">`);
lines.push(` <bpmn:participant id="${escAttr(s.pool.id)}" name="${escAttr(s.pool.name)}" processRef="Process_${escAttr(s.workflowMeta.id)}"/>`);
// T-1119: the other pools and the messageFlows, verbatim; a flow's end that named an element of OUR
@@ -12623,6 +12628,7 @@ function buildBpmnXml(s) {
}
lines.push(` </bpmn:collaboration>`);
lines.push(``);
+ }
lines.push(` <bpmn:process id="Process_${escAttr(s.workflowMeta.id)}" isExecutable="true">`);
// workflow-level aef:workflowMeta
const wm = s.workflowMeta;
@@ -12652,6 +12658,7 @@ function buildBpmnXml(s) {
if (s.dataKept) for (const x of s.dataKept.procIo || []) lines.push(` ${x}`);
// lane set
+ if (!bare) {
lines.push(` <bpmn:laneSet id="LaneSet_1">`);
const lanesToEmit = s.lanes || defaultLanes();
for (const lane of lanesToEmit) {
@@ -12668,6 +12675,7 @@ function buildBpmnXml(s) {
lines.push(` </bpmn:lane>`);
}
lines.push(` </bpmn:laneSet>`);
+ }

// nodes
for (const n of s.nodes) {
@@ -13876,10 +13884,13 @@ function parseBpmnXml(text) {
nodes,
edges,
// T-358: which of the four lane origins produced `lanes` above. Read by probes
- // and by nothing in the emitter — the exact opposite of docComment below, which
- // must reach buildBpmnXml. Kept here rather than module-level (the T-308
+ // and by buildBpmnXml only to omit the laneSet on 'defaulted:no-laneset'.
+ // Kept here rather than module-level (the T-308
// reconcile-counter pattern) because it is per-document, not per-session.
laneProvenance,
+ // No participant in the source: the pool above is a stand-in, not the document's (T-080 bridge files
+ // still get one written, since they carry a laneSet).
+ poolProvenance: partEl ? 'authored' : 'defaulted',
// T-340: did the document we parsed carry BPMN DI? This one MUST reach
// buildBpmnXml (like docComment below, unlike laneProvenance above) — it is the
// input half of "emit DI only when the input carried it". Losing it across a


proxmox-ring20-management (session b3644419, T-2466): Job A re-run report, message 3/4, verbatim from the cloud session (pinned 8909a9b1; the job found 13 risks, all in message 4):

A 9/16
BEFORE: node tools/_t356-third-party-fidelity-cdp.mjs (in->out)
control arc-lifecycle: HARNESS BROKEN — diagrams 0>1 diShapes 0>14 diEdges 0>13 bounds 0>14 exporter 0>1
aef-draft-inception: diag 0>1 diSh 0>17 diEd 0>18 bnd 0>17 exp 0>1
bizagi-nested-ns: LANES 0>3 diag 0>1 diSh 0>5 diEd 0>2 bnd 0>5 docs 8>4 exp 0>1
boundary-events: LANES 0>3 PART 0>1 bnd 15>9
caseagile-local-ns: diag 0>1 diSh 0>11 diEd 0>12 bnd 0>11
collab-message-flows: LANES 0>3 bnd 12>6
i18n-documentation: LANES 0>3 PART 0>1 bnd 4>3
kitchen-sink: diag 5>1 diSh 90>84 diEd 11>9 bnd 97>86
multiple-diagrams: LANES 0>3 PART 0>1 diag 2>1 diSh 2>3 bnd 0>2
nested-subprocesses: LANES 0>3 PART 0>1 bnd 17>8
simple: LANES 0>3 PART 0>1 bnd 9>5
zeebe-service-task: LANES 0>3 PART 0>1
11/11 LOSSY
A 10/16
AFTER: same harness, patched build
control arc-lifecycle: HARNESS BROKEN (identical to before, pre-existing)
aef-draft-inception: unchanged (DI rows only)
bizagi-nested-ns: LANES 0>3 still (empty-laneset, out of scope) + same DI/docs rows
boundary-events: bnd 15>9 (lanes/part rows GONE)
caseagile-local-ns: unchanged
collab-message-flows: bnd 12>6 (lanes row GONE)
i18n-documentation: bnd 4>3 (lanes/part GONE)
kitchen-sink: unchanged
multiple-diagrams: PART 0>1 still, diag 2>1 diSh 2>3 bnd 0>2 (lanes GONE)
nested-subprocesses: bnd 17>8 (lanes/part GONE)
simple: bnd 9>5 (lanes/part GONE)
zeebe-service-task: CLEAN
10/11 LOSSY. No row got worse; only lanes/participants rows removed.
A 11/16
GOLDENS: node tools/_t358-byteid-thirdparty.mjs
Before: 11 identical, 0 drifted (PASS). After: 4 identical, 7 drifted (rc=1):
boundary-events, i18n-documentation, nested-subprocesses, simple, zeebe-service-task: -20 lines each = collaboration+participant (4) + laneSet with 3 empty default lanes (16).
collaboration-message-flows, multiple-diagrams: -17 lines = the laneSet only (pool kept).
Unchanged: aef-draft, bizagi, caseagile, kitchen-sink (all have a laneSet or participant).
Why it is the fix: re-recorded into a temp dir (T358_GOLDENDIR, --record) and diffed: ZERO added lines in all 7; removed lines are only <bpmn:collaboration>/<participant>, <bpmn:laneSet>/<lane>/<aef:laneMeta>/extensionElements of hum/frw/agt — exactly the fabricated content. Node ids, flows, DI untouched.
A 12/16
GOLDENS cont. / AEF unchanged
Goldens are NOT re-recorded (not pushed; --record is the maintainers' deliberate act).
AEF dialect check: probe ran buildBpmnXml on the same parsed state with and without laneProvenance/poolProvenance (= old emitter): 27 tests/fixtures/aef-bpmn + 24 examples/aef-processes/rendered + 4 unaffected third-party = SAME byte-for-byte. Incl. 7 aef-bpmn files with laneSet but NO participant (bridge, T-080) — participant still written.
Other harnesses (pass before+after): _t308 24 identical/0 drifted; _roundtrip-serialization pass; _t1119 18/18; _t1120 7/7; _t1088 no errs.
Idempotence: simple.bpmn save->reopen->save: 0 lanes, 0 participants, stable bytes.
A 13/16
CANVAS after patch (simple, zeebe, nested, boundary, collab, multiple, i18n; Chromium headless + screenshot)
The patch changes only the emitter, so the canvas is as before: a pool header + the 3 default bands (Human·Sovereignty, Framework·Authority, Agent·Initiative), poolHeight 612.
Rendered: every node drawn (5/5, 4/4, 8/8, 9/9, 3/3, 1/1, 3/3), all inside the pool, none off-canvas; edges drawn.
Unplaced: ALL of them in membership terms — lane=null for 100% of nodes (pre-existing, T-891). They visually sit in a band (e.g. simple: human+framework rows) they do not belong to, and display ids get the 'lan_' prefix (lan_start_start).
So the canvas still SHOWS 3 lanes + a pool the saved file no longer contains.


proxmox-ring20-management (session b3644419, T-2466): Job A re-run report, message 4/4, verbatim from the cloud session (pinned 8909a9b1; the job found 13 risks, all in message 4):

A 14/16
RISKS 1-4
1. Re-fabrication cliff: the moment ANY node gets a lane — drag across a band (:8602/:8623), new palette node (:10354 getLanes()[0]), inspector Lane field (:7595) — the next save writes all 3 default lanes AND the participant again. Verified: assigning 1 node -> lanes 3, participant 1.
2. Canvas/file mismatch: default bands and pool are drawn but not saved; users see lanes the file lacks.
3. Silent loss of lane edits: renaming/resizing/re-authoritying a default lane, or Add Lane, is NOT saved while no node is in a lane (bare stays true).
4. multiple-diagrams still gains a participant (0>1): a second top-level process makes s.collab non-null, and the DI plane then targets the collaboration (:12837). Needs its own decision.
A 15/16
RISKS 5-8
5. Empty laneSet (bizagi, 'defaulted:empty-laneset') and 'defaulted:later-laneset-ignored' still emit 3 fabricated lanes; only no-laneset is fixed.
6. Contract change: T-358 documented laneProvenance as never read by the emitter ('byte-neutral by construction'); it now drives output. One comment updated; :13892 'unlike laneProvenance above' is now stale.
7. State not from parseBpmnXml (new map :11883, pre-patch autosave/library/project versions) has no provenance -> still emits lanes/pool. Maps already saved with fabricated lanes keep them (they now carry a laneSet).
8. Pool rule asymmetry: lanes are dropped when there is no laneSet even if a participant exists (collab-message-flows); pool only when also no participant and no collab.
A 16/16
RISKS 9-13
9. Downstream consumers (AEF compiler, gallery, validators, lane-as-authority) may assume a laneSet/participant always exists.
10. 7 goldens must be re-recorded; until then _t358 fails (rc=1).
11. Pre-existing, not fixed: null-lane nodes get 'lan_' displayIds, so third-party ids are renamed on save; DI/bounds/docs losses remain.
12. T-356 positive control is HARNESS BROKEN before AND after (corpus arc-lifecycle has no DI; export always adds DI since T-423) — its 'losses are real' guarantee is not established.
13. Env: Chromium download blocked by proxy; harnesses ran on preinstalled Chromium 1194 (symlinked into ~/.cache/ms-playwright), not 1.47.2's 1134. Nothing pushed.


