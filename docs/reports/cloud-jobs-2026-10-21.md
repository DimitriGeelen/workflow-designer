# Cloud jobs for 832, 2026-10-21 (run by ring20 on the operator's cloud-session credits)

Rules (ring20 / operator): each job clones the PUBLIC repo, checks out the LATEST `bleeding-edge` tip, prints the
commit sha it ran against first, does its work, and reports in the session only: no push, no PR, no issues, no
comments. Nothing from the estate is in the briefs. Results come back to 832, which reviews and lands them under
the named task with its own tests and full suite.

---

## Job A — T-358: the importer invents lanes and pools the input never had

```
You are working on an open-source BPMN workflow designer: a single-file web app.
Setup:
  git clone https://github.com/DimitriGeelen/workflow-designer.git && cd workflow-designer
  git checkout bleeding-edge && git log -1 --format='RUNNING AGAINST %H'   (print this first)
  npm i -D playwright@1.47.2 && npx playwright install chromium   (for the browser harnesses)
The app: src/aef-workflow-designer.html (parse: parseBpmnXml, build/export: buildBpmnXml).
Defect: opening a third-party BPMN file that has NO lanes and NO pools, then saving it, adds lanes and a pool
(the importer falls back to defaultLanes() and a participant). The five third-party fixtures in
tests/fixtures/third-party/ show it: lanes 0->3, participants 0->1 on open->save. tools/_t356-third-party-fidelity-cdp.mjs
measures it; tests/goldens/third-party/*.golden pin today's (wrong) output.
Goal: a document with no laneSet and no participant round-trips (open -> save) with none added, while maps that
DO carry lanes/pools (tests/fixtures/aef-bpmn/, the AEF dialect) are unchanged.
Do: 1) find where the fabrication happens and why (cite lines); 2) write the smallest patch to src/ that stops it;
3) run node tools/_t356-third-party-fidelity-cdp.mjs before and after and show both tables; 4) run
node tools/_t358-byteid-thirdparty.mjs and list which goldens drift and why each drift is the fix, not a regression;
5) say what the canvas shows for a lane-less map after the patch (is anything left unplaced or unrendered?).
Report in this session: the RUNNING AGAINST sha, root cause, the patch as a unified diff, the before/after tables,
the golden drifts, risks. Do not push, open PRs, or create issues.
```

## Job B — T-347: content inside accepted elements is dropped on import

```
You are working on an open-source BPMN workflow designer: a single-file web app.
Setup:
  git clone https://github.com/DimitriGeelen/workflow-designer.git && cd workflow-designer
  git checkout bleeding-edge && git log -1 --format='RUNNING AGAINST %H'   (print this first)
  npm i -D playwright@1.47.2 && npx playwright install chromium
The app: src/aef-workflow-designer.html (parseBpmnXml / buildBpmnXml).
Defect: inside a BPMN element the designer accepts (a task, event, gateway, flow), some standard or foreign
content is lost on open -> save: bpmn:documentation, foreign extensionElements content (other vendors'
namespaces, e.g. camunda:, zeebe:), multi-instance markers and similar. Known: unknown aef: ATTRIBUTES on aef:io
are already preserved (search IO_NAMED_ATTRS / ioExtraAttrs); several other cases are not.
Do: 1) build a small fixture BPMN (save it under tests/fixtures/) that puts each of these inside accepted elements:
bpmn:documentation (with text and with textFormat), a foreign extensionElements block (zeebe:taskDefinition,
camunda:inputOutput), bpmn:multiInstanceLoopCharacteristics, bpmn:standardLoopCharacteristics, an unknown child
element inside aef:input; 2) write a node/playwright harness that opens it in the app and exports, and list
exactly which of these survive byte-for-byte, which are changed, which are dropped; 3) for the dropped ones, write
the smallest patch to src/ that keeps them verbatim (preserve, do not interpret); 4) re-run and show before/after.
Report in this session: the RUNNING AGAINST sha, the per-construct table before/after, the patch as a unified diff,
the fixture and harness source, risks. Do not push, open PRs, or create issues.
```

## Job C — independent bug hunt: silent data loss on open -> save

```
You are an independent reviewer of an open-source BPMN workflow designer: a single-file web app.
Setup:
  git clone https://github.com/DimitriGeelen/workflow-designer.git && cd workflow-designer
  git checkout bleeding-edge && git log -1 --format='RUNNING AGAINST %H'   (print this first)
Read src/aef-workflow-designer.html, focusing on import (parseBpmnXml and what it calls) and export
(buildBpmnXml and what it calls). The product promise is: opening a BPMN file and saving it without edits keeps
everything the author wrote (attributes, child elements, text, ids, order where it carries meaning), or the app
says clearly what it could not keep. Hunt for places where that promise breaks SILENTLY: data read but not written
back, written back changed, ids regenerated, order lost, namespaces dropped, characters escaped wrongly.
For each finding: the line(s), a minimal BPMN snippet that triggers it, what goes in vs what comes out, and how
sure you are (verified by running it, or by reading only). Optional: verify findings with
npm i -D playwright@1.47.2 && npx playwright install chromium and a tiny harness that opens the snippet and exports.
Rank findings by how likely real users hit them. Report in this session only; do not push, open PRs, or create issues.
```
