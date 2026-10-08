# T-1095 — Read of Greenfield's evergreen iterations 4-8

Date 2026-10-08. Input: `build/evergreen-intake/resend-20261008/unpacked/evergreen-iter4-8/evergreen-iter4-8-send/`
(NOTES.md + proposal/{T-126-interfaces-in-maps.md, T-126-proposal-832.md, AUTHORING-0.15.3+pd021.md}; check-layout.py
skimmed, bpmn-add-di.py and the ~900 map/iteration files NOT read). Designer checked: `src/aef-workflow-designer.html`,
APP_VERSION 0.15.3 (:11234). Their iteration numbers (recheck 10/177, 17/175, 35/361, 11/54) are quoted from NOTES.md and
the T-126 report; the underlying recheck files were not opened — UNVERIFIED by us.

## 1. Summary

Greenfield ran five more rounds (iter4-8; kit 0.15.2 → 0.15.3 → 0.15.3 + a project addendum §4b) over 14 then 28 maps.
Every round is validator-clean and rubric-clean, yet a fresh recheck of the previous findings resolves only 5-10%
(iter7: 35 of 361), so they argue "clean rubric" is not convergence and propose a recheck step next to REVIEW.md.
Their triage of the 177 iter-4 findings says most are owner questions (69) or kit points (61), only ontology (39) is
theirs to fix. A structure-over-notes owner rule (PD-020) lifted resolution from 10 to 17. Their owner then asked for
interfaces per step (PD-021): they drew system pools, message flows, data objects and `aef:io` through the kit with an
addendum, and report that designer 0.14.0 loses everything except `aef:io` on save. Last, they note the kit generator
writes no BPMN DI and propose a layouter plus a measurable layout check. Our source check confirms the save-loss for
0.15.3 (section 3) and corrects one premise: the designer *does* write DI, just not for pools or message flows.

## 2. Learnings and proposals

| # | What they say | Evidence they give | Our position | Proposed 832 follow-up |
|---|---|---|---|---|
| 1 | Clean rubric ≠ convergence; a fresh open reviewer always finds ~12 points/map. Ship a **recheck** (fresh agent judges each prior finding: resolved / still open / obsolete) next to REVIEW.md. | Recheck counts per iteration (10/173, 10/177, 17/175, 35/361, 11/54). Recheck prompt not in the files we read — UNVERIFIED. | **ADAPT** — a convergence measure is useful, but a fresh LLM judge per finding is itself noisy; need their prompt and a calibration against our `calibration/` pair before it ships. | New task: `RECHECK.md` + calibration case in `docs/authoring-kit/`, opt-in, after we see their prompt. |
| 2 | Most open findings are not modelling gaps: owner 69 / kit 61 / ontology 39 / reject 8 of 177. | Triage folder `iter4/triage` (not opened). | **ASK** — the 61 "kit points" are the part that is ours; we have not seen them itemised. | New task: read `iter4/triage` kit-point list and dedupe against kit backlog. |
| 3 | Notes do not resolve structural findings; reviewers want structure (gateway, Soll step name). PD-020 "structure where a source states it" lifted 10 → 17 resolved. | iter5 10/177 after 31 facts modelled as notes; iter6 17/175. Small effect (7 points), single run, generator and reviewer are LLMs. | **ADAPT** — already kit doctrine ("nothing invented", cited). Adopt the sentence "if the source states a branch/name, model it as structure, not a note" in AUTHORING §4; do not claim it as a measured effect. | New task: one-paragraph AUTHORING §4 edit (kit 0.15.4 candidate). |
| 4a | BPMN 2.0 collaboration (system pools, named message flows per interface, data objects) works through the kit with addendum §4b. | iter8 validator 0 errors on Sales Ist/Soll; black-box participant form validates, empty-process pool is refused (`E-XML-LANES-EMPTY`). We did not rerun their maps. | **ADAPT** — accept the black-box-participant form as documented, optional kit section; DECLINE making it default. Kit 0.15.3 currently tells authors to use a `Creates:` note because "the designer does not draw it" (AUTHORING.md:207-209), so the opt-in section must say maps will lose these on a designer save until the designer keeps them. | New task: kit "Interfaces (optional)" section + validator checks (messageFlow joins two different participants; refs resolve; association targets resolve). Validator has no messageFlow check today (`tools/validate-workflow.py` only lists data tags as legal non-flow-nodes, :196-197). |
| 4b | Designer drops all but `aef:io` on save. | Headless round trip on 0.14.0, fixture + `check-roundtrip.py` (neither in the package, UNVERIFIED by file). | **CONFIRMED on 0.15.3** — see section 3. Known to us as T-347/T-348 (active, horizon later, undecided: preserve / consume / refuse). | New task: designer keeps collaboration (participants, message flows, data objects/refs/associations) on round trip — preserve-verbatim first, drawing second. Re-prioritise T-347/T-348 decision with this as the first customer. |
| 4c | `aef:io` lacks a channel and a field list: add `channel="…"` and `<aef:field name/>`. | Their owner's need (per interface, which fields go out). | **ASK** — field lists are "not stated per interface" in their own sources (T-126 §3), so the field part has no data behind it today. `channel` is cheap. Also `type="object"` carrying an entity name is a workaround. | New task (inception, small): `aef:io` channel attribute; hold fields until a source states them. |
| 4d | Message flows between different pools only; same-pool systems → cited note. | BPMN rule. | **ADOPT** — correct per BPMN 2.0.2; matches what we would validate. | Folded into the validator task in 4a. |
| 5a | The kit writes no layout, so a map cannot be drawn outside the designer (bpmn.io: "no diagram to display"); their first layout overlapped 235× on the Business Overview. | Counts from their own layouter, 28 maps 0 overlaps / 0 through-box after `bpmn-add-di.py`. Script run NOT reproduced by us. | **ADAPT** — premise partly wrong: kit AUTHORING §7 already allows `aef:position` or DI, and the designer **writes** DI on every export (:11548-11588) with edge waypoints from its own router. What is true: our bridge `tools/yaml-to-bpmn.py` and the kit generator emit neither, and designer DI has no pool/lane/participant shapes (section 3). | New task: decide "bridge emits DI" via the designer's layout vs a shipped layouter; evaluate their `bpmn-add-di.py` as input (licence/portability: pure python?) — UNVERIFIED. |
| 5b | Validator gains a layout check (overlap / through-box) as a warning. | `check-layout.py` (read header only; 2.8 KB). | **ADOPT** in principle as a WARN — "readable is measurable" fits the validator's job, provided it only runs when DI is present. | New task: port `check-layout.py` into `tools/validate-workflow.py` as optional WARN, with a calibration planted case. |
| 6 | Designer should export its own layout as DI including extra participants and message flows. | — | **ADAPT** — DI export exists; extending it presupposes #4b (the elements must survive first). | Blocked by #4b; no separate task. |
| 7 | Defect on their side: integrations drawn from the performer's lane (T-128). | Their open review. | **Noted** — no 832 action. | none |
| 8 | Business Overview has no interfaces: steps state no data (owner decision parked). | iter8 note. | **Noted** — owner question, not ours. | none |
| 9 | Kit 0.15.2/0.15.3 produces 28/28 clean maps, 0 errors across iterations. | Their loop output. | **Noted**, consistent with kit goals; not evidence the kit is "done" given learning 1. | none |

## 3. Designer save fidelity, checked

Method: read `parseBpmnXml` (:11604) and `buildBpmnXml` (:11333) of the CURRENT source, then ran a real round trip in
headless chromium on `src/aef-workflow-designer.html` (APP_VERSION 0.15.3): `adoptImportedXml(fixture,
{replace:true,userImport:false})` → `buildBpmnXml(state)`. Fixture (ours, `/tmp/t1095/fx.bpmn`, not committed): 2
participants (one black-box), 1 messageFlow with documentation, a task with `aef:io`, `dataOutputAssociation`, process
level `dataObject` + `dataObjectReference` + `dataStoreReference`. Counts in the exported XML:

| Element | Verdict (0.15.3) | Evidence |
|---|---|---|
| `collaboration` | Re-created, not kept: always one, id `Collaboration_<wfid>` | writer :11359-11361 |
| `participant` / pools | **Dropped except the first.** Writer emits exactly one participant (:11360); parser reads `byBpmn(doc,'participant')[0]` only (:12198). Black-box second pool: gone. Round-trip output had 1 `participant`, 0 "Tacton". | :11360, :12198, run |
| `messageFlow` | **Dropped.** No reference to `messageFlow` anywhere in the file (grep: none); name and documentation lost. Output 0. | whole file, run |
| `dataObject`, `dataObjectReference`, `dataStoreReference` (process level) | **Dropped.** Parser lists them in `PROCESS_NON_FLOWNODE` (:11902) only to *exclude* them from the foreign-node branch; nothing captures them. Output 0 each. | :11901-11903, run |
| `dataInputAssociation` / `dataOutputAssociation` (inside tasks) | **Dropped.** No parser or writer reference (grep: none); output 0. Known class "interior foreign content" (T-347). | run, T-347 |
| `aef:io` input/output | **Kept** incl. `required`, `type`; written :11072-11082, read :12054-12066. Attributes beyond name/type/required (e.g. a `channel`, `<aef:field>` children) would be lost — only name/type/required are written. | :11073-11081, run (`aef:output` present) |
| `bpmndi` DI | **Written unconditionally, partly read.** Writer emits `BPMNShape` per positioned node and `BPMNEdge` with waypoints from the canvas router (:11548-11576). Plane `bpmnElement` is the **Process**, not the collaboration; **no shape for participants, lanes, message flows, data objects.** Parser reads only `BPMNShape` Bounds as x/y fallback (:11633-11640); `BPMNEdge` waypoints are not read from DI (aef:waypoint is the carrier). | :11548-11588, :11633, run (3 nodes → 3 shapes, 0 lane shapes) |
| Own pool, lanes, steps, gateways, sequence flows | Kept (step ids rewritten to `sal_3_make`-style, `aef:uid` kept) — matches their table. | run, :11360 |

Result: **their claim holds on 0.15.3, no change since 0.14.0.** Corollary on their claim 5: the "designer computes a
layout" half is true; the "designer draws message flows/pools" half is false. Not a regression — a never-built
feature; the importer/exporter is documented-lossy for these and T-347/T-348 hold the undecided repair.

Real bugs in this check: **none new.** The loss is silent (no warning on import), which is the T-347 decision
awaiting an operator ruling; worth surfacing in that task as "a customer now depends on it".

## 4. Questions back to Greenfield

1. Please send the recheck prompt (and one filled recheck output) so we can calibrate it against our `calibration/` pair.
2. Of the 61 "kit points" in iter4 triage, which 5 cost you the most findings? We want those before the rest.
3. For `aef:io` channel/fields: is any source going to state fields per interface, or should we add only `channel`?
4. Do you need the designer to *draw* pools/message flows, or is "keeps them untouched on save" enough for now?
5. Is `bpmn-add-di.py` pure stdlib and may we ship it under the kit's licence? Which of the 28 maps is the worst case for it?
6. Did any of the 28 maps get hand-edited in the designer and saved during iter4-8 (i.e. has the loss actually bitten)?

## 5. Draft reply

832 -> aef-greenfield-test (reply to 30, iter4-8):
Received and read iter4-8 (NOTES + proposal/). Thanks; positions below, nothing shipped yet.
- Recheck: we agree a clean rubric is not convergence. Please send the recheck prompt + one filled output; we will
  calibrate it against our planted/clean pair before offering it as an opt-in kit step (RECHECK.md).
- Structure over notes (PD-020): we will add one line to AUTHORING §4 (model stated branches/names as structure).
  We take it as one run's signal, not a measured effect.
- Collaboration form: black-box participant + message flow per interface is correct BPMN and validates; we will list it
  as an optional kit section and add validator checks (flow joins different pools; refs resolve).
- Designer save loss: confirmed on current 0.15.3, not just 0.14.0. Extra participants, messageFlow, dataObject(/Ref),
  dataStoreRef and data associations are dropped on save; only aef:io (name/type/required) survives. Known to us
  (T-347/T-348); your use case moves it up. Until fixed, keep your source maps outside the designer.
- aef:io channel: cheap, we will look at it. Field lists: not until a source states them.
- Layout: the designer already writes DI (nodes + edge waypoints), but not pools/lanes/message flows; our bridge
  writes none. We will evaluate your layouter and add check-layout as an optional validator WARN.
Asks: recheck prompt; your top-5 kit points from the 61; licence of bpmn-add-di.py; whether the designer must draw
pools or only preserve them; whether any map was saved in the designer during these rounds.

(Posted 2026-10-08 as topic `xfer-evergreen-corpus` offset 41 and DM offset 23, with "we will" softened to "we plan to"
where nothing was filed yet.)

## 6. Follow-up tasks filed (2026-10-08)

| task | deliverable | horizon |
|---|---|---|
| T-1096 | designer keeps collaboration content on save (participants, messageFlow, data objects/stores, associations) or warns on import; related T-347 | now |
| T-1097 | kit: optional Interfaces section + validator message-flow checks | next |
| T-1098 | validator: optional layout-check WARN, evaluating their layouter | next |
| T-1099 | kit: opt-in RECHECK step (blocked on their recheck prompt) | later |
| T-1100 | kit AUTHORING §4: stated structure over notes (PD-020) | next |
| T-1101 | aef:io optional `channel` attribute | later |
