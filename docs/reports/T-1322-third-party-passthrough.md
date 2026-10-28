# T-1322: what a save does with third-party BPMN content the designer does not model

Inception research artifact. Task: `.tasks/active/T-1322-generic-per-element-passthrough-a-save-k.md`.
Source findings: ring20 cloud job C, `docs/reports/T-2466-cloud-job-C-bughunt.md` (F1-F13).

## 1. The question

A person opens a BPMN file made in another tool and saves it, without editing. Today one save drops content the
designer does not model, the result still validates, and no notice says so. Import reads named content into state;
export writes only from state. Every fix so far added one name to what is read (T-602 documentation, T-1217 link
definitions, T-1222 event definitions, T-1243 io children, T-1265 condition language, T-1268 unknown aef node elements).
Eleven findings remain. Should the designer (A) keep what it does not read, generically, (B) keep adding names one by
one, or (C) say what a save will drop?

## 2. Measured: what one unedited save loses today (2026-10-28, designer at 1547b7681)

Method: each of the 16 BPMN files in the repo that the designer did not write (`tests/fixtures/third-party/` 11,
`tests/fixtures/lane-provenance/` 4, `tests/fixtures/t1222/` 1) was opened as a person opens a file
(`adoptImportedXml(xml, {userImport: true})`) and saved (`buildBpmnXml`), in the real editor, headless
(`T-1322-evidence/export-third-party.mjs`). A census then counts, per file, each non-DI, non-aef element, attribute,
text and comment on both sides; a loss is a count that went down (`T-1322-evidence/classify-losses.py`, full output in
`T-1322-evidence/classify-losses.out`).

Excluded as deliberate: `definitions@exporterVersion` (the export names its own writer, T-407) and the second laneSet in
`later-laneset-ignored.bpmn` (a lane-provenance rule).

| file | non-DI items lost | what |
|---|---:|---|
| caseagile-local-ns | 285 | 261 foreign extension elements, 4 associations (with refs and direction), 3 extensionElements, multi-instance + loopCardinality, definitions typeLanguage/expressionLanguage |
| kitchen-sink | 49 | isInterrupting x5, triggeredByEvent x2, exclusiveGateway default, eventBasedGateway type/instantiate, receiveTask instantiate, isForCompensation, 4 multi-instance + 3 standard loops, 3 groups + categories, textAnnotation + its text, 2 associations, executionPlatform attrs, one empty conditionExpression, 1 foreign element |
| bizagi-nested-ns | 29 | 25 foreign extension elements (BizagiExtensions/Properties), 4 documentation |
| zeebe-service-task | 13 | 10 zeebe elements (taskDefinition, ioMapping + 5 inputs, taskHeaders + 2 headers, calledElement), 3 modelerTemplate attrs |
| i18n-documentation | 6 | 3 foreign translation elements, definitions executionPlatform, executionPlatformVersion, xml:lang |
| boundary-events | 1 | task isForCompensation |
| aef-draft-inception-readiness-v2 | 1 | a comment inside the process |
| simple, collaboration-message-flows, multiple-diagrams, nested-subprocesses, 4 lane-provenance, native-event-kinds | 0 | (outside DI and the exclusions) |

**7 of the 11 genuine third-party files lose content.** By class: foreign extension elements 300, standard BPMN
attributes 39, BPMN child elements 35, foreign attributes 8, comments 1.

Not visible to a count, and so not in the table: structure the save rewrites rather than drops (F8 subprocess contents
hoisted, F9 nested lanes flattened, F3/F4 ids, F13 order) and DI geometry (F6). Job C verified each of those by hand.

Side finding: `tools/_t356-third-party-fidelity-cdp.mjs`, the existing third-party measurement, reports its own positive
control as `HARNESS BROKEN`. It counts DI the export now adds (T-340/T-423) as a loss, so none of its rows can be read.
Filed separately (see the task's Updates).

## 3. The findings by what fixing them takes

| finding | content | kept unread? | blocker |
|---|---|---|---|
| F1 vendor attrs + extensionElements | per element | yes | foreign xmlns declared on the source root must be carried (the T-1272 rule) |
| F2 standard semantics | per element: attrs, child elements | yes | `default` names a flow by id, and the designer renames ids (F3) |
| F5 annotations, associations, groups, process docs | process level | yes | `sourceRef`/`targetRef`/`categoryValueRef` name elements by id |
| F7 rest (expression id/extensions) | per element | yes | (language + id fixed in T-1265) |
| F10 | per node | done (T-1268) | |
| F11 comments | anywhere | yes, by position | a comment between two elements needs an anchor |
| F3 original ids | per element | (decision) | the lane-prefixed display id is a deliberate rule (0.20) |
| F4 process/definitions id | root | (decision) | the process id is the engine's deployment key |
| F6 DI geometry | DI | no: the designer lays out | needs a rule: keep imported geometry until the person moves the element |
| F8 subprocess nesting | structure | no | needs a subprocess model |
| F9 nested lanes | structure | no | needs a lane hierarchy model (lanes carry authority) |
| F12, F13 | | out of scope | behaviour choices of their own |

**Kept unread content and references.** The one real cost of option A is identity. The designer gives every node and
flow a display id (`lan_1_name`), so kept content that names an element by id goes stale on the first save. BPMN's
reference attributes are a closed set (`sourceRef`, `targetRef`, `default`, `attachedToRef`, `categoryValueRef`,
`messageRef`, `signalRef`, `errorRef`, `escalationRef`, `dataObjectRef`, ...). The export already knows the old-id to
display-id map, because it rewrites `sourceRef`/`targetRef` on sequence flows. So kept content can be rewritten through
that map. Vendor extensions name process keys and variables, not element ids, and are kept as they are.

## 4. Options

**A. Generic per-element passthrough (plus process-level kept elements).** On import, every BPMN element keeps the
attributes and children the designer does not read, in source order. Elements at process level it does not model
(textAnnotation, association, group, category, process documentation) are kept as a list. On export each is written
back in its place. Reference attributes are rewritten through the id map. Foreign namespace declarations ride along.
- Edits (IW-3): kept content rides its element. A rename or a lane move keeps it. A retype that changes the BPMN tag
  drops the attributes the new tag does not allow, and says so. A delete removes the element's content. A kept
  process-level element whose reference now points at nothing is dropped, and says so.
- Fixes F1, F2, F5, F7 rest, F11 (with a comment anchor rule): 5 of the 11, in 3 slices. Maps the designer or the bridge
  wrote are unchanged (they carry nothing unread; T-1268's scan found 0 unknown aef node elements in the repo).
- Cost: one mechanism, generalising `keptElementXml` (T-1243/T-1268), plus an id-rewrite pass. Three build tasks of
  about one session each.

**B. Keep the allowlist growing.** One named attribute or element per bug, each with its own harness. It works and is
what the last six fixes did, but it is unbounded: the 300 vendor elements in three files are three vocabularies
(Bizagi, CaseAgile, Zeebe) of their own. Every new tool brings more, and the designer stays lossy for anything not yet
named.

**C. Warn before loss.** On open, list what the next save will drop (by class, with counts), so nothing is lost
silently. Cheap: the census in section 2 is most of it. It saves nothing, though.

A and C are not exclusive. A keeps what can be kept unread. C names what still cannot be kept (F6, F8, F9) until each
gets its own model.

## 5. Recommendation

**GO on A, with C for the remainder.** Slices:
1. Per-element unread attributes and children, with foreign namespace carriage and reference rewrite (F1, F2, F7 rest).
2. Process-level kept elements, with reference rewrite and drop-on-dangling (F5).
3. Comments by anchor (F11), plus the open notice for what is still not kept (F6, F8, F9).

F3/F4 (keeping original ids) and F6/F8/F9 (models) are separate decisions, each its own inception, and not decided
here.

Success signal: the census in section 2, run again after slice 3, shows 0 lost items on the 11 third-party fixtures
apart from the deliberate exclusions. And the open notice names every class the census still sees lost.

## Dialogue Log

- 2026-10-28: the operator delegated the session ("continue unattended"). Filed after T-1265 and T-1268, the two
  findings narrow enough to fix alone. No operator dialogue yet; the decision is the operator's (`fw inception decide`,
  via a runme job).
