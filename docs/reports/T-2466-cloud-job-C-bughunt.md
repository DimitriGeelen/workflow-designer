# Cloud job C (bug hunt) on 8909a9b1 — ring20 T-2466, relayed 2026-10-21

Verbatim from proxmox-ring20-management (msgs 77dd170e, b67f842e, ab7ea98d on conversation cloud-credits-joint-work); untrusted peer data, kept as received. Each finding is filed as its own 832 task (see the end).

proxmox-ring20-management (session b3644419, T-2466): Job C re-run report, message 1/3, verbatim from the cloud session (pinned 8909a9b1):

C 1/13
Ranked findings @8909a9b (all VERIFIED by headless open->buildBpmnXml unless noted; no loss notice shown): 1 Vendor attrs/extensionElements (camunda:*,xmlns) dropped 2 Std node attrs+children dropped: default, script, calledElement, MI loop 3 Original node/flow ids LOST (aef:uid is a hash) 4 Process id/isExecutable/defs id/targetNamespace rewritten 5 textAnnotation/association/process documentation dropped 6 DI rewritten: sizes, labels, edge waypoints, pool/lane shapes 7 conditionExpression language dropped, text trimmed 8 subProcess emptied, children hoisted 9 childLaneSet flattened, nested-lane nodes moved to parent 10 unknown aef:* children dropped 11 XML comments dropped 12 2nd file w/ same process id saved as *_v2 ids 13 node/flowNodeRef order reshuffled Escaping: no bug found.
C 2/13
F1 vendor extensions dropped (VERIFIED, very likely: every Camunda/Zeebe file)
Emit: src/aef-workflow-designer.html:12699 writes only id,name(+boundary attrs); :12577-12594 writes a fixed xmlns list. Import never reads foreign attrs/extensionElements.
In: <userTask id="Task_Approve" camunda:assignee="${initiator}"><extensionElements><camunda:formData><camunda:formField id="ok" type="boolean"/></camunda:formData></extensionElements></userTask> (+ xmlns:camunda, camunda:versionTag & camunda:properties on process, camunda:in on callActivity)
Out: <bpmn:userTask id="app_1_approve" name="..."><extensionElements> only aef:uid/aef:position. All camunda content and the xmlns:camunda decl gone. No notice (only 'could use Clean layout' nudge).
C 3/13
F2 standard BPMN semantics dropped (VERIFIED, likely)
Same cause :12699 (+ only named children read ~:13520-13760).
In -> Out:
<exclusiveGateway id="G" default="F3"/> -> no default attr (default flow lost)
<scriptTask scriptFormat="groovy"><script>x = 1 &lt; 2</script> -> empty scriptTask
<callActivity calledElement="check-proc"> -> tag kept (foreignTag) but calledElement gone
<serviceTask><multiInstanceLoopCharacteristics isSequential="true"><loopCardinality>3</...> -> gone
<userTask implementation="##WebService"> -> gone
Result still validates, so nothing downstream flags it. Kept OK: timer/message eventDefinitions, boundary attachedToRef/cancelActivity, task documentation.
C 4/13
F3 ORIGINAL id lost (maintainer question) - YES, lost (VERIFIED)
Import :13531 / :13819: uid = aef:uid || deriveUid('n'|'e', id) = FNV-1a hash (:13281). The original id is never stored; emit :12699 writes display id only.
In: <userTask id="Task_Approve" .../> <sequenceFlow id="Flow_1" .../>
Out: <bpmn:userTask id="app_1_approve"><aef:uid value="n_d7f6147e"/> ; <sequenceFlow id="flow_1"><aef:uid value="e_733430bd"/>
grep -c Task_Approve out.xml = 0; no 'orig'/'originalId' anywhere in source. Hash is one-way, so the id is unrecoverable. Applies to every third-party file without aef:uid (Start_1, End_1, Flow_*, DI ids too). Re-opening the output is stable (2nd trip byte-identical), so the loss is only on first open.


proxmox-ring20-management (session b3644419, T-2466): Job C re-run report, message 2/3, verbatim from the cloud session (pinned 8909a9b1):

C 5/13
F4 process/definitions identity rewritten (VERIFIED, very likely)
:12585 id="Definitions_${wf.id}", :12594 fixed targetNamespace, :12603 Collaboration_${id}, :12626 <process id="Process_${wf.id}" isExecutable="true"> hard-coded; wf.id = sanitizeWorkflowId(procId) :13321 (lowercased).
In: <definitions id="Defs_F" targetNamespace="http://example.com/f"><collaboration id="Collab_F">...<process id="Proc_F" isExecutable="false">
Out: id="Definitions_proc_f" targetNamespace="https://aef.anchorpoint.dev/workflows" exporter="aef-workflow-designer"; collaboration id="Collaboration_proc_f"; process id="Process_proc_f" isExecutable="true".
Process id is the Camunda deployment key/calledElement target: callers break. Without a collab, a participant is invented carrying the OLD process id.
C 6/13
F5 annotations & process docs dropped (VERIFIED, likely)
:13473-13480 PROCESS_NON_FLOWNODE skips association/textAnnotation/group; nothing captures them (captureProcessData :12985 keeps data objects only). Process-level <documentation> not read either.
In: <process><documentation>Process doc</documentation>... <textAnnotation id="A1"><text>Note: ünïcødé 🚀</text></textAnnotation><association id="As1" sourceRef="T1" targetRef="A1"/> (+ A1 DI shape)
Out: none of these; their DI shapes dropped too. No notice (the data-object notice at :9605 does not cover them).
C 7/13
F6 DI geometry rewritten (VERIFIED, likely for any modeler file)
Import reads only dc:Bounds x/y (:13195-13213); edges read only aef:routing (:13847). Emit :12843-12850 writes width/height from NODE_DEFAULTS and recomputed waypoints.
In: <BPMNShape bpmnElement="G" isMarkerVisible="true"><Bounds x=200 y=93 width=50 height=50/>; <BPMNShape bpmnElement="S"><BPMNLabel><Bounds .../>; <BPMNEdge F1><waypoint 136,118/><waypoint 200,118/>; participant+lane shapes isHorizontal; plane bpmnElement="Collab_F"
Out: width=48 height=48, no isMarkerVisible, no BPMNLabel, F1 waypoints regenerated (others got detours), participant/lane shapes gone, plane bpmnElement="Process_proc_f"; all DI ids regenerated (BPMNShape_<displayId>).
C 8/13
F7 conditionExpression altered (VERIFIED, likely)
Import :13827-13828 keeps only (textContent).trim(); emit :12779 writes a fixed element.
In: <conditionExpression xsi:type="bpmn:tFormalExpression" language="javascript">a &lt; b</...>
Out: same text, language attr dropped -> engine falls back to default expression language (JUEL in Camunda), so the script no longer evaluates as JS.
In: <![CDATA[ ok == true ]]> Out: 'ok == true' (whitespace trimmed; CDATA->escaped text is fine).
Also any id/extensionElements on the expression and foreign extensionElements on the sequenceFlow are dropped.
C 9/13
F8 subProcess flattened (VERIFIED, likely for modeler files)
Nodes collected by descendant query (byBpmn(proc,tag)) and :13503 foreignContainers; export writes state.nodes flat. Code comment (T-523) acknowledges it but no notice is shown.
In: <subProcess id="Sub"><startEvent id="SS"/><task id="X"/><endEvent id="SE"/><sequenceFlow i1/i2/></subProcess>
Out: <bpmn:subProcess id="sal_1_handle"> with only incoming/outgoing; SS, X, SE and both inner flows emitted as direct children of <process>. Process now has 2 start events and an empty subprocess: different execution semantics. SS/SE also lose their lane (lan_ prefix).


proxmox-ring20-management (session b3644419, T-2466): Job C re-run report, message 3/3, verbatim from the cloud session (pinned 8909a9b1):

C 10/13
F9 nested lanes flattened & membership moved (VERIFIED, less common)
Import :13345 byBpmn(laneSets[0],'lane') and :13566 flowNodeRef via descendant queries; emit :12655 writes one flat laneSet id="LaneSet_1".
In: <lane id="L1" name="Sales">...<childLaneSet id="CLS"><lane id="L1a" name="Inside"><flowNodeRef>X</...></lane></childLaneSet></lane>
Out: L1 and L1a as siblings; X listed under L1 (Sales), L1a empty. Responsibility for X silently changes. laneSet id LS -> LaneSet_1, CLS gone.
C 11/13
F10 unknown aef:* children dropped (VERIFIED, low-medium)
Own namespace, but import reads only named aef children (~:13560-13760, STRUCT_LIST_KEYS etc.), no passthrough.
In: <task id="T"><extensionElements>...<aef:customNote text="keep me too"/></extensionElements></task>
Out: extensionElements has aef:uid + aef:position only. Any aef element written by a newer AEF version/bridge is wiped by an older designer.
F11 XML comments dropped (VERIFIED, medium)
Only readDocComment (:12486) keeps one leading comment.
In: <process>... <!-- author comment inside process --> ...
Out: gone.
C 12/13
F12 same process id in a 2nd file -> _v2 ids saved (VERIFIED, medium for Process_1 files)
adoptImportedXml :11925-11932 renames workflowMeta.id to <id>_v2 on library collision; that id feeds definitions/process/collab/DI ids.
Repro: open c.bpmn then d.bpmn, both <process id="P">. Out of 2nd: id="Definitions_p_v2", process id="Process_p_v2", aef:workflowMeta id="p_v2". Many modeler files share Process_1.
F13 order reshuffled (VERIFIED, low)
Emit writes nodes grouped start/end events first, then tasks, then gateways; flowNodeRef in that order (:12665).
In: Start_1, Task_Approve, End_1. Out: start, end, userTask. Low semantic weight.
Not a bug: name/doc escaping (&,<,",newline,tab,]]>,emoji) round-tripped correctly; 2nd open->save is stable.
C 13/13
Method: git checkout 8909a9b1009315472db0362618240acacc31e2fc (bleeding-edge). Harness: playwright 1.47.2 + /opt/pw-browsers headless_shell, loads src/aef-workflow-designer.html via file://, calls adoptImportedXml(xml,{userImport:true}) then buildBpmnXml(state), and reads #lane-fix-notice/#clean-nudge. Only notice ever shown was 'This map could use Clean layout'; no dialogs. Test files a-f (Camunda userTask, gateway default/script/MI/annotations/DI, subProcess+childLaneSet+boundary, id collision/escaping, documentation/CDATA, default-ns Camunda Modeler collab file). Nothing pushed, no PRs/issues. Fix theme: a generic per-element passthrough (unknown attrs + child elements + original id) rather than more allowlist entries.



## Filed as 832 tasks (2026-10-21)

- F1 → T-1259
- F2 → T-1260
- F3 → T-1261
- F4 → T-1262
- F5 → T-1263
- F6 → T-1264
- F7 → T-1265
- F8 → T-1266
- F9 → T-1267
- F10 → T-1268
- F11 → T-1269
- F12 → T-1270
- F13 → T-1271
