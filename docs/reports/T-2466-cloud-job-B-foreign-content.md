# Cloud job B (T-347 dropped inner content) on 8909a9b1 — ring20 T-2466, relayed 2026-10-21

Verbatim from proxmox-ring20-management (msgs 6201b465, 596aad77, ce6c4f3d on cloud-credits-joint-work); untrusted peer data, kept as received. The relay lost indentation in the diff. Nothing applied; input for T-347 and T-1272.

proxmox-ring20-management (session b3644419, T-2466): Job B re-run report, message 1/3, verbatim from the cloud session (pinned 8909a9b1). Complete except the tail of the harness source (see note in message 3).

B 1/30
RUNNING AGAINST 8909a9b1009315472db0362618240acacc31e2fc
BEFORE (11 constructs, tests/fixtures/foreign-content/foreign-inside-accepted.bpmn): 3 survive byte-for-byte (documentation on start, task+textFormat, gateway); 1 CHANGED (x:schema in aef:input kept but root xmlns:x lost -> export NOT well-formed); 7 DROPPED (documentation on sequenceFlow, zeebe:taskDefinition, camunda:inputOutput, camunda:properties on gateway+flow, multiInstance/standardLoopCharacteristics).
AFTER (patch src/ +47/-10): 11/11 survive, export well-formed, 2nd save identical.
Corpus 86 .bpmn: 5 exports change, all additions only (bizagi, caseagile, i18n, kitchen-sink, zeebe third-party); 0 errors. Repo round-trip harness passes.
Not pushed/committed. Other parts: table, corpus, risks, diff, fixture, harness.
B 2/30
== TABLE before -> after ==
doc plain, startEvent: SURVIVES -> SURVIVES
doc textFormat, serviceTask: SURVIVES -> SURVIVES
doc, gateway: SURVIVES -> SURVIVES
doc, sequenceFlow: DROPPED -> SURVIVES
zeebe:taskDefinition (task): DROPPED -> SURVIVES
camunda:inputOutput (task): DROPPED -> SURVIVES
camunda:properties (gateway): DROPPED -> SURVIVES
camunda:properties (flow): DROPPED -> SURVIVES
multiInstanceLoopCharacteristics: DROPPED -> SURVIVES
standardLoopCharacteristics: DROPPED -> SURVIVES
x:schema in aef:input: CHANGED (bytes kept, xmlns:x lost, export not well-formed) -> SURVIVES
SURVIVES = exact source snippet inside the host's exported text (host found by aef:uid; export renames ids) with every prefix declared.
== CORPUS: 86 .bpmn (tests/fixtures, examples) ==
B 3/30
Before vs after: 80 identical; changed = new fixture + 5, additions only; 0 errors; all exports well-formed (xmllint).
third-party/bizagi-nested-ns +32: 5 bizagi:BizagiExtensions (self-declared xmlns)
caseagile-local-ns +281: 23 caseagile:model, unprefixed MI marker; root +xmlns:caseagile, +default xmlns
i18n-documentation +4: 3 i18n:translation; root +xmlns:i18n
kitchen-sink +9: 4 MI, 3 standardLoop, zeebe:calledElement; +xmlns:zeebe
zeebe-service-task +13: taskDefinition, ioMapping, taskHeaders; +xmlns:zeebe
2nd save identical for all but kitchen-sink (pre-existing id churn, same unpatched).
tools/_roundtrip-serialization-cdp.mjs: pass. tests/test_*.py: 56 pass, 4 fail same before/after (no python-playwright).
== RISKS ==
B 4/30
1. Kept content is not interpreted: edits can leave foreign config (zeebe ioMapping) stale; deleting a node/flow drops it.
2. aef:multiInstance and a kept bpmn MI marker are both emitted, unreconciled.
3. Root xmlns re-declared only if kept text uses the prefix (regex); a false positive adds an unused declaration.
4. Unprefixed kept content (caseagile) puts default xmlns=BPMN on the export root: same meaning, new root bytes.
5. A source root binding bpmn/bpmndi/dc/di/aef to another URI is not carried -> unbound prefix (as in the existing io path).
6. Still not kept (untested): foreign ATTRIBUTES on bpmn elements (camunda:asyncBefore), bpmn:script, resourceRole, auditing, lane documentation.
7. Verbatim is per element: XMLSerializer normalizes ("/>", &#10;); indentation is ours.
8. Project JSON gains foreignExt/loopXml/rootNs/edge.documentation; older builds drop them.
9. No AEF task used (CLAUDE.md); nothing committed; npm left package*.json, node_modules untracked.


proxmox-ring20-management (session b3644419, T-2466): Job B re-run report, message 2/3, verbatim from the cloud session (pinned 8909a9b1). Complete except the tail of the harness source (see note in message 3).

B 5/30 .. B 16/30
== PATCH (git diff -U3 src, complete) ==
(relay note: the cloud log collapses runs of whitespace, so INDENTATION IS LOST below; every token and line is as written, re-indent when applying)
diff --git a/src/aef-workflow-designer.html b/src/aef-workflow-designer.html
index 85572592..7882e45e 100644
--- a/src/aef-workflow-designer.html
+++ b/src/aef-workflow-designer.html
@@ -12104,10 +12104,11 @@ function ioExtraAttrXml(extra) {
// kept, verbatim, in order. XMLSerializer re-declares a namespace on a subtree serialised alone; a declaration the
// document root already makes with the same URI is redundant there and is dropped, so a save adds no xmlns noise and a
// second save is byte-identical to the first.
-function ioChildXml(el) {
+// `keep` (optional) narrows which children are kept; the foreign-content capture below reuses this with one.
+function ioChildXml(el, keep) {
const doc = el.ownerDocument, root = doc && doc.documentElement, ser = new XMLSerializer(), parts = [];
for (const c of Array.from(el.childNodes)) {
- if (c.nodeType !== 1) continue;
+ if (c.nodeType !== 1 || (keep && !keep(c))) continue;
let x = ser.serializeToString(c);
x = x.replace(/^(<[^\s>\/]+)((?:\s+[^\s=>]+="[^"]*")*)/, (m, tag, attrs) => tag + attrs.replace(/\s+xmlns(?::([A-Za-z_][\w.-]*))?="([^"]*)"/g,
(d, pfx, uri) => (root && root.getAttribute(pfx ? 'xmlns:' + pfx : 'xmlns') === uri) ? '' : d));
@@ -12364,6 +12365,8 @@ function aefExtensionXml(node) {
}
}

+ // foreign (non-aef) extension children, verbatim, after ours
+ for (const x of node.foreignExt || []) out += ` ${x}\n`;
out += ' </bpmn:extensionElements>\n';
return out;
}
@@ -12582,6 +12585,14 @@ function buildBpmnXml(s) {
lines.push(` xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"`);
lines.push(` xmlns:di="http://www.omg.org/spec/DD/20100524/DI"`);
lines.push(` xmlns:aef="http://anchorpoint.framework/aef/extensions"`);
+ // A namespace only the source root declared, re-declared when kept verbatim content (foreign extensions, loop
+ // markers, io children) uses it: ioChildXml drops a declaration the source root makes. Unused ones stay out.
+ const keptXml = [...s.nodes.flatMap(n => [...(n.foreignExt || []), ...(n.loopXml || []),
+ ...[...((n.io || {}).inputs || []), ...((n.io || {}).outputs || [])].flatMap(i => i.children || [])]),
+ ...s.edges.flatMap(e => e.foreignExt || [])].join('\n');
+ for (const [k, v] of s.rootNs || []) {
+ if (new RegExp(k === 'xmlns' ? '<[A-Za-z_][\\w.-]*[\\s/>]' : `[<\\s]${k.slice(6)}:`).test(keptXml)) lines.push(` ${k}="${escAttr(v)}"`);
+ }
lines.push(` id="Definitions_${escAttr(s.workflowMeta.id)}"`);
// T-399: producer identity. BPMN 2.0 defines `exporter` on <definitions> for
// exactly this question, so we answer it with the standard's own carrier rather
@@ -12721,6 +12732,8 @@ function buildBpmnXml(s) {
// T-1096: the task's kept data content, after incoming/outgoing in tActivity's order
const kd = s.dataKept && s.dataKept.perNode && s.dataKept.perNode[n.uid];
if (kd) for (const t of DATA_TASK_TAGS) for (const x of kd[t] || []) lines.push(` ${x}`);
+ // kept loop markers, verbatim: loopCharacteristics is the last child in tActivity's order
+ for (const x of n.loopXml || []) lines.push(` ${x}`);
lines.push(` </bpmn:${tag}>`);
}

@@ -12735,6 +12748,10 @@ function buildBpmnXml(s) {
const srcRef = srcNode ? displayIdOf(srcNode) : e.source;
const tgtRef = tgtNode ? displayIdOf(tgtNode) : e.target;
lines.push(` <bpmn:sequenceFlow id="${escAttr(edgeDisplayId)}"${nameAttr} sourceRef="${escAttr(srcRef)}" targetRef="${escAttr(tgtRef)}">`);
+ for (const d of (e.documentation || [])) { // T-602's node shape; documentation precedes extensionElements
+ const attrs = (d.id ? ` id="${escAttr(d.id)}"` : '') + (d.textFormat ? ` textFormat="${escAttr(d.textFormat)}"` : '');
+ lines.push(` <bpmn:documentation${attrs}>${escText(d.text)}</bpmn:documentation>`);
+ }
// T-690: extensionElements MUST precede conditionExpression. BPMN's tBaseElement declares
// extensionElements as the first element of the sequence, and tSequenceFlow extends it, so
// conditionExpression can only follow. This emitted them the other way round for the life of
@@ -12773,6 +12790,7 @@ function buildBpmnXml(s) {
}
lines.push(` </aef:routing>`);
}
+ for (const x of e.foreignExt || []) lines.push(` ${x}`);
lines.push(` </bpmn:extensionElements>`);
// T-690: emitted here, AFTER extensionElements, per tBaseElement's element order.
if (e.condition) {
@@ -13185,6 +13203,18 @@ function parseBpmnXml(text) {
const AEF_NS = 'http://anchorpoint.framework/aef/extensions';
const byBpmn = (parent, local) => Array.from(parent.getElementsByTagNameNS(BPMN_NS, local));
const byAef = (parent, local) => Array.from(parent.getElementsByTagNameNS(AEF_NS, local));
+ const readDocumentation = el => byBpmn(el, 'documentation')
+ .filter(d => d.parentNode === el) // direct children only — never a nested element's
+ .map(d => {
+ const entry = { text: d.textContent || '' };
+ if (d.hasAttribute('id')) entry.id = d.getAttribute('id');
+ if (d.hasAttribute('textFormat')) entry.textFormat = d.getAttribute('textFormat');
+ return entry;
+ });
+ const foreignExtXml = el => {
+ const ext = Array.from(el.children).find(c => c.namespaceURI === BPMN_NS && c.localName === 'extensionElements');
+ return ext ? ioChildXml(ext, c => c.namespaceURI !== AEF_NS) : null;
+ };

// ---- BPMN DI intake (T-340, operator ruling 2026-08-14, candidate (b)) ----
//
@@ -13737,14 +13767,11 @@ function parseBpmnXml(text) {
// so a child not on that list cannot survive. This adds documentation to the list.
// Order matters on the way out: the BPMN XSD puts documentation BEFORE
// extensionElements on tBaseElement, so the emitter writes it above the aef block.
- const documentation = byBpmn(el, 'documentation')
- .filter(d => d.parentNode === el) // direct children only — never a nested element's
- .map(d => {
- const entry = { text: d.textContent || '' };
- if (d.hasAttribute('id')) entry.id = d.getAttribute('id');
- if (d.hasAttribute('textFormat')) entry.textFormat = d.getAttribute('textFormat');
- return entry;
- });
+ const documentation = readDocumentation(el);
+ // Foreign content kept verbatim, not interpreted: other vendors' extensionElements children
+ // (zeebe:, camunda:, ...) and the standard loop markers (multiInstance/standardLoopCharacteristics).
+ const foreignExt = foreignExtXml(el);
+ const loopXml = ioChildXml(el, c => c.namespaceURI === BPMN_NS && /LoopCharacteristics$/.test(c.localName));

// Derive slug from name if not encoded (T-1218: an unnamed start/end event reads its carried slug, else its id)
const slug = unnamedEvent ? (aef.slug || deriveSlug(displayId)) : deriveSlug(name);
@@ -13766,6 +13793,8 @@ function parseBpmnXml(text) {
x, y,
aef, io,
...(documentation.length ? { documentation } : {}),
+ ...(foreignExt ? { foreignExt } : {}),
+ ...(loopXml ? { loopXml } : {}),
...(foreignTag ? { foreignTag } : {}),
...(linkDef ? { linkDef } : {}),
...(nativeEventDefs.length ? { nativeEventDefs } : {}),
@@ -13824,6 +13853,10 @@ function parseBpmnXml(text) {
const edge = { uid, id: uid, source, target };
const name = el.getAttribute('name');
if (name) edge.name = name;
+ const documentation = readDocumentation(el);
+ if (documentation.length) edge.documentation = documentation;
+ const foreignExt = foreignExtXml(el);
+ if (foreignExt) edge.foreignExt = foreignExt;
const condEl = byBpmn(el, 'conditionExpression')[0];
if (condEl) edge.condition = (condEl.textContent || '').trim();
const anchorsEl = byAef(el, 'anchors')[0];
@@ -13866,6 +13899,8 @@ function parseBpmnXml(text) {
const collab = captureCollaboration(doc, proc, partEl, displayIdToUid); // T-1119
const dataKept = captureProcessData(doc, proc, displayIdToUid); // T-1096
const eventRoots = captureEventRoots(doc, nodes, collab); // T-1222
+ const rootNs = Array.from(doc.documentElement.attributes).map(a => [a.name, a.value])
+ .filter(([k]) => k === 'xmlns' || (k.startsWith('xmlns:') && !['bpmn', 'bpmndi', 'dc', 'di', 'aef'].includes(k.slice(6))));

// Snap y-coords to lane centers for nodes that lacked explicit positions
const result = {
@@ -13898,6 +13933,8 @@ function parseBpmnXml(text) {
...(dataKept ? { dataKept } : {}),
// T-1222: root-level message/signal/error/escalation elements a kept native event definition names, verbatim.
...(eventRoots.length ? { eventRoots } : {}),
+ // the source root's own namespace declarations (not the five the export always writes), for kept content
+ ...(rootNs.length ? { rootNs } : {}),
};
// Use a temporary state so laneCenterY() resolves correctly during patching
const prev = state;


proxmox-ring20-management (session b3644419, T-2466): Job B re-run report, message 3/3, verbatim from the cloud session (pinned 8909a9b1). Complete except the tail of the harness source (see note in message 3).

B 17/30 .. B 21/30
== FIXTURE tests/fixtures/foreign-content/foreign-inside-accepted.bpmn ==
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
xmlns:aef="http://anchorpoint.framework/aef/extensions"
xmlns:zeebe="http://camunda.org/schema/zeebe/1.0"
xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
xmlns:x="urn:example:unknown"
id="Definitions_foreign_inside"
targetNamespace="https://aef.anchorpoint.dev/workflows">
<bpmn:process id="Process_foreign_inside" isExecutable="false">
<bpmn:laneSet id="LaneSet_1">
<bpmn:lane id="lane_a" name="A">
<bpmn:flowNodeRef>s1</bpmn:flowNodeRef>
<bpmn:flowNodeRef>t1</bpmn:flowNodeRef>
<bpmn:flowNodeRef>t2</bpmn:flowNodeRef>
<bpmn:flowNodeRef>g1</bpmn:flowNodeRef>
<bpmn:flowNodeRef>e1</bpmn:flowNodeRef>
</bpmn:lane>
</bpmn:laneSet>
<bpmn:startEvent id="s1" name="Start"><bpmn:documentation>Plain doc on start</bpmn:documentation><bpmn:extensionElements><aef:uid value="n_s1"/></bpmn:extensionElements></bpmn:startEvent>
<bpmn:serviceTask id="t1" name="Call API"><bpmn:documentation textFormat="text/markdown">**Formatted** doc on task</bpmn:documentation><bpmn:extensionElements><aef:uid value="n_t1"/><aef:io><aef:input name="order" type="string" required="true"><x:schema ref="order.json"/></aef:input></aef:io><zeebe:taskDefinition type="payment-service" retries="3"/><camunda:inputOutput><camunda:inputParameter name="amount">${total}</camunda:inputParameter></camunda:inputOutput></bpmn:extensionElements><bpmn:multiInstanceLoopCharacteristics isSequential="true"><bpmn:loopCardinality>3</bpmn:loopCardinality></bpmn:multiInstanceLoopCharacteristics></bpmn:serviceTask>
<bpmn:userTask id="t2" name="Review"><bpmn:extensionElements><aef:uid value="n_t2"/></bpmn:extensionElements><bpmn:standardLoopCharacteristics testBefore="true" loopMaximum="5"/></bpmn:userTask>
<bpmn:exclusiveGateway id="g1" name="OK?"><bpmn:documentation>Gateway doc</bpmn:documentation><bpmn:extensionElements><aef:uid value="n_g1"/><camunda:properties><camunda:property name="k" value="v"/></camunda:properties></bpmn:extensionElements></bpmn:exclusiveGateway>
<bpmn:endEvent id="e1" name="End"><bpmn:extensionElements><aef:uid value="n_e1"/></bpmn:extensionElements></bpmn:endEvent>
<bpmn:sequenceFlow id="f1" sourceRef="s1" targetRef="t1"><bpmn:documentation>Flow doc</bpmn:documentation><bpmn:extensionElements><aef:uid value="f_1"/><camunda:properties><camunda:property name="fk" value="fv"/></camunda:properties></bpmn:extensionElements></bpmn:sequenceFlow>
<bpmn:sequenceFlow id="f2" sourceRef="t1" targetRef="t2"><bpmn:extensionElements><aef:uid value="f_2"/></bpmn:extensionElements></bpmn:sequenceFlow>
<bpmn:sequenceFlow id="f3" sourceRef="t2" targetRef="g1"><bpmn:extensionElements><aef:uid value="f_3"/></bpmn:extensionElements></bpmn:sequenceFlow>
<bpmn:sequenceFlow id="f4" sourceRef="g1" targetRef="e1"><bpmn:extensionElements><aef:uid value="f_4"/></bpmn:extensionElements></bpmn:sequenceFlow>
</bpmn:process>
</bpmn:definitions>
B 21/30 .. B 24/30 (rest NOT relayed, see note)
== HARNESS tests/foreign-content/roundtrip-foreign.mjs ==
run: node tests/foreign-content/roundtrip-foreign.mjs probe tests/fixtures/foreign-content/foreign-inside-accepted.bpmn ; corpus: ... export <outdir> <files>
// Open -> save probe for foreign/standard content inside accepted BPMN elements.
// usage: node roundtrip-foreign.mjs probe <fixture.bpmn>
// node roundtrip-foreign.mjs export <out-dir> <file.bpmn>... (writes <out-dir>/<n>.bpmn per input)
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const APP = pathToFileURL(path.join(ROOT, 'src', 'aef-workflow-designer.html')).href;
const exe = process.env.CHROME || (() => {
const d = fs.readdirSync('/opt/pw-browsers').find(n => n.startsWith('chromium_headless_shell-'));
return d ? `/opt/pw-browsers/${d}/chrome-linux/headless_shell` : undefined;
})();

// [label, aef:uid of the element that must carry it (export renames ids), verbatim snippet from the fixture]
const CONSTRUCTS = [
['documentation (plain) on startEvent', 'n_s1', '<bpmn:documentation>Plain doc on start</bpmn:documentation>'],
['documentation textFormat on serviceTask', 'n_t1', '<bpmn:documentation textFormat="text/markdown">**Formatted** doc on task</bpmn:documentation>'],
['documentation on gateway', 'n_g1', '<bpmn:documentation>Gateway doc</bpmn:documentation>'],
['documentation on sequenceFlow', 'f_1', '<bpmn:documentation>Flow doc</bpmn:documentation>'],
['zeebe:taskDefinition (task ext)', 'n_t1', '<zeebe:taskDefinition type="payment-service" retries="3"/>'],
['camunda:inputOutput (task ext)', 'n_t1', '<camunda:inputOutput><camunda:inputParameter name="amount">${total}</camunda:inputParameter></camunda:inputOutput>'],
['camunda:properties (gateway ext)', 'n_g1', '<camunda:properties><camunda:property name="k" value="v"/></camunda:properties>'],
['camunda:properties (flow ext)', 'f_1', '<camunda:properties><camunda:property name="fk" value="fv"/></camunda:properties>'],
['multiInstanceLoopCharacteristics', 'n_t1', '<bpmn:multiInstanceLoopCharacteristics isSequential="true"><bpmn:loopCardinality>3</bpmn:loopCardinality></bpmn:multiInstanceLoopCharacteristics>'],
['standardLoopCharacteristics', 'n_t2', '<bpmn:standardLoopCharacteristics testBefore="true" loopMaximum="5"/>'],
['unknown child in aef:input', 'n_t1', '<x:schema ref="order.json"/>'],
];

async function with...
[RELAY NOTE: the harness source stops here. The rest of the harness (the browser driver and the per-construct
check: host text = from the last '\n <bpmn:' before its <aef:uid value="UID"/> to the next '\n </bpmn:' after it;
SURVIVES when the snippet is inside and every prefix it uses is declared; the export mode) was not relayed: the
cloud model's safety system stopped the relay turn at line 70 of 82, and ring20 did not retry that pattern.]

