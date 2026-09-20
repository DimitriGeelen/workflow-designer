# 05 — The BPMN subset and its fidelity (GATHERER evidence)

**Leg:** three-way diff between (a) what the EDITOR can author, (b) what the FROZEN
STANDARD declares, (c) what the 24 rendered corpus maps contain. Plus `docs/designer/schema.md`.
**Role:** evidence only. No classification, no recommendation.
**Repo state:** `HEAD = 12ad8f9f`, `VERSION = 0.12.0`, working tree dirty in `.context/` only
(see session `git status`); no source file was modified by this leg.

## Provenance of every measurement below

| Probe | Command (all read-only) | Writes to |
|---|---|---|
| P1 corpus construct census | `grep -ho '<bpmn:[a-zA-Z]*' examples/aef-processes/rendered/*.bpmn \| sort \| uniq -c` (and `aef:` variant) | nothing |
| P2 editor round-trip over the 24 corpus maps | `ROUNDTRIP_FIXTURES_DIR=examples/aef-processes/rendered node tools/_roundtrip-serialization-cdp.mjs` | `/tmp/rt-*` temp dirs only (`tools/_roundtrip-serialization-cdp.mjs:543-552` — `mkdtempSync`) |
| P3 fresh bridge render of all 24 canonical YAMLs | `python3 tools/yaml-to-bpmn.py examples/aef-processes/<n>.workflow.yaml --out /tmp/vr05/<n>.bpmn` | `/tmp/vr05/` only |
| P4 conformance + parity tests | `python3 tests/test_mapping_standard_conformance.py`; `python3 tests/test_editor_bridge_meta_parity.py` | nothing |
| P5 XML structural parse of the corpus | inline `xml.etree` script over `examples/aef-processes/rendered/*.bpmn` | nothing |

`examples/aef-processes/rendered/` was **not** regenerated. `build/gallery/`, `dist/`, `VERSION`,
`dist/MANIFEST.yaml` and `docs/standards/aef-bpmn-mapping-v1.md` were not touched. P3 renders a
byte-parallel copy into `/tmp/vr05/` precisely so the committed corpus stays untouched while the
bridge's own output is still measurable.

---

## Population sizes (the three columns of the diff)

| Population | Size | Citation |
|---|---|---|
| (a) Editor authorable node types | 12 palette entries | `src/aef-workflow-designer.html:1199-1336` (`data-create=` × 12) |
| (a) Editor `aef:meta` scalar whitelist | 20 keys | `src/aef-workflow-designer.html:9819-9824` |
| (a) Editor per-type field offer (`AEF_FIELDS`) | 13 node types, 26 distinct field names | `src/aef-workflow-designer.html:1861-1904` |
| (a) Editor serialization key spec (harness denominator) | 36 keys | P2 `selftest.denominator.specSize = 36` |
| (b) Standard frozen governance meta-keys | 4 (`horizon`, `workflowType`, `tier`, `agentType`) | `docs/standards/aef-bpmn-mapping-v1.md:57-62` |
| (b) Standard forward-mapping BPMN rows | 13 | `docs/standards/aef-bpmn-mapping-v1.md:81-95` |
| (c) Corpus | 24 maps / 306 nodes / 319 edges / 67 lanes | P2 sum over `fixtures[]`; `aef:position` count 306 confirms node total |
| Bridge `META_KEYS` | 29 keys | `tools/yaml-to-bpmn.py:56-79`; P4 prints "20 ⊆ 29" |
| `docs/designer/schema.md` declared node types | "a ten-element BPMN subset" | `docs/designer/schema.md:170-172` |

---

## MAIN EVIDENCE TABLE

Kind legend: `structure` / `usage` / `cost` / `friction` / `value`.
Window: `HEAD@12ad8f9f` unless a commit range is named.

| Item | Source | Status of source | Data point (with citation) | Window | Kind |
|---|---|---|---|---|---|
| **A. Editor-authorable, ZERO corpus use** | | | | | |
| A1 `horizon` meta-key | editor `metaKeys` + `AEF_FIELDS` on 4 task-like types | EXISTS | Editor offers it (`src/aef-workflow-designer.html:1888-1890,1903`, `:2015`) and emits it (`:9824`). Corpus: **0 occurrences in 0 of 24 maps** (P1: `grep -o ' horizon=' rendered/*.bpmn` → 0). Also 0 in a *fresh* bridge render of the canonical YAMLs (P3) ⇒ absent at the SOURCE, not lost in rendering. | HEAD | usage |
| A2 `workflowType` meta-key | same | EXISTS | Offered (`:1888-1890,1903`, `:2016`, 7-value closed set), emitted (`:9824`). Corpus **0 / 0 of 24** (P1). Fresh bridge render also 0 (P3). | HEAD | usage |
| A3 `owner` meta-key | editor writer only (panel read-only since IW-9) | EXISTS (writer) / DESIGNED-ONLY (as authorable field) | Retained in `metaKeys` (`:9824`) but explicitly **not** offered in the panel — `AEF_FIELDS` comment `:1880-1883`, `FIELD_META.owner special:'derived'` `:2021`. Corpus **0 / 0 of 24** (P1, precise ` owner=` match). Fresh render 0 (P3). Standard removed the node-level carrier in v1.1 (`docs/standards/aef-bpmn-mapping-v1.md:68`). | HEAD | structure |
| A4 `scopeOf` (FC-15 boundary marker) | editor `metaKeys` + `subProcess` field | EXISTS | Offered `:1903`, `:2010`; emitted `:9822`. Corpus **0 / 0 of 24** (P1) and **0 in fresh render** (P3). Both corpus `subProcess` nodes carry `constituents` but no `scopeOf` (`rendered/resume-status.bpmn` `n_intel`; `rendered/session-capture.bpmn` `n_capture`). | HEAD | usage |
| A5 Typed-event bindings `errorStatus` / `timerSpec` / `busTopic` | editor `AEF_FIELDS` + `EVENT_BINDING_FIELD` | EXISTS | `src/…:1900-1902`, `:2000-2002`, `:9798`. P2 classifies all three **NEVER-PRESENT** across the 24 maps. Corpus has **0 `<bpmn:intermediateCatchEvent>`** and **0 `<aef:eventDef>`** (P1). | HEAD | usage |
| A6 Typed-event node types `eventError` / `eventTimer` / `eventMessage` | editor palette | EXISTS | Palette entries `src/…:1311`, `:1323`, `:1336`. Zero instances in corpus (P1: `intermediateCatchEvent` = 0 files). | HEAD | usage |
| A7 Off-page connector fields `workflowRef` / `name` / `targetWorkflow` / `linkId` | editor `AEF_FIELDS.linkEventThrow/Catch` | EXISTS | `src/…:1893-1894`, `:1994-1997`; emitter `:9886-9900`. P2: all four **NEVER-PRESENT**. Corpus has **0 `<aef:link>`**, 0 `intermediateThrowEvent`, 0 `intermediateCatchEvent` (P1). | HEAD | usage |
| A8 Node types `linkEventThrow` / `linkEventCatch` | editor palette | EXISTS | `src/…:1283`, `:1295`. Zero corpus instances (P1). | HEAD | usage |
| A9 Boundary-event attachment `hostRef` / `boundaryPos` / `interrupting` | editor `AEF_FIELDS` (T-204 Slice 2) | EXISTS | `src/…:1900-1902`, `:2006-2008`, `:9922-9924`. P2: `hostRef` (attachedref), `interrupting` (cancelact) **NEVER-PRESENT**. Corpus has **0 `<bpmn:boundaryEvent>`** (P1). | HEAD | usage |
| A10 `eventDefKind` / `eventDefBinding` passthrough | editor import/export | EXISTS | `src/…:9860`, `:9905-9909`. P2 **NEVER-PRESENT**; 0 `<aef:eventDef>` in corpus (P1). | HEAD | usage |
| A11 `determinism` field (T-618) | editor panel select, corpus-derived vocabulary | EXISTS | Offered on 7 node types `src/…:1878-1903`, `:1978`. Corpus **.bpmn: 0 occurrences**; canonical **.workflow.yaml: 199 occurrences** (`determinism: deterministic` 156, `stochastic` 36, `human` 7 — P3 census over `examples/aef-processes/*.yaml`). Fresh bridge render emits **199 across 23 of 24 maps**; committed `rendered/` has **0** (P3 diff). | HEAD | structure |
| A12 `sideEffect` field (T-618) | editor panel textarea | EXISTS | `src/…:1888,1890,1903`, `:1985`. Fresh render **38 occurrences / 14 maps**; committed `rendered/` **0** (P3 diff). | HEAD | structure |
| A13 `fabricRef` / `links` (T-589) | editor panel, 4 task-like types | EXISTS | `src/…:1888-1890,1903`, `:2027-2028`. Corpus **0 / 0 of 24** (P3 census). Not in the harness's 36-key spec (they ride T-570 carriage). | HEAD | usage |
| A14 `io` types `number` / `ref` / `arc_id` / `object` | editor `IO_TYPES` | EXISTS | `src/…:2055` (9 types). Corpus uses only `string` 26, `task_id` 6, `enum` 4, `path` 3, `list` 2, `boolean` 1, `computed-set` 1 (P5). Four editor types appear in **zero** corpus documents. | HEAD | usage |
| **B. Standard declares, editor cannot author** | | | | | |
| B1 `aef:arc` on the process | `docs/standards/aef-bpmn-mapping-v1.md:83` ("`aef:arc` on the process when the flow is a program") | DESIGNED-ONLY | `grep -rn 'aef:arc'` over the repo returns **only prose**: the standard `:83`, `docs/standards/aef-bpmn-forward-compile-v1.md:55`, `docs/reports/T-175-mapping-strawman.md:50`, and two AEF-side reports. **0 hits in `src/aef-workflow-designer.html`, 0 in `tools/yaml-to-bpmn.py`, 0 in the 24 corpus maps.** | HEAD | structure |
| B2 node documentation / annotation → AC seed | `docs/standards/aef-bpmn-mapping-v1.md:95` (row) + Part II `:153-155` ("AC-seeding … the exact seed field/format is unratified") | PARTIAL | Editor **preserves** `<bpmn:documentation>` on round-trip (import `src/…:10879-10913`, export `:10251-10257`, T-602) but there is **no panel field** for it — `documentation` appears in no `AEF_FIELDS`/`FIELD_META` entry (`src/…:1861-2029` contains no `documentation` key). Corpus: **0 `<bpmn:documentation>` elements** in the 24 maps (P1). | HEAD | friction |
| B3 `owner` as a BPMN-carried datum | `docs/standards/aef-bpmn-mapping-v1.md:68` — "`owner` remains in task-YAML output but **has no node-level BPMN carrier in v1.1**" | EXISTS (as deliberate removal) | Editor matches the standard: panel read-only, derived via `ownerFromAuthority` (`src/…:1946-1956`). Recorded here because it is the one case where "editor cannot author" is the standard's *instruction*, not a gap. | v1.1 (2026-07-12) | structure |
| B4 `tier` default value | `docs/standards/aef-bpmn-mapping-v1.md:151-152` (Part II, provisional: "the canonical default is unratified") | DESIGNED-ONLY | Corpus supplies a per-workflow default instead: `<aef:workflowMeta … tier_default="2"/>` present on all 24 processes (`rendered/task-gate.bpmn:17`; `aef:workflowMeta` in 24/24 files, P1). Standard's Part II item still unratified at HEAD (last touched `4a1a30e1` T-204). | Part II open since 2026-07-11 (`:156`) | structure |
| B5 Lane authority value `none` | standard §3 collapse map lists only `sovereignty`/`initiative`/`authority`/`external` (`:97`) | conflict | Editor `AUTHORITIES = ['sovereignty','authority','initiative','external','none']` (`src/…:1623`); `OWNER_FROM_AUTHORITY` has no `none` entry so it derives `''` (`:1950-1952`). Corpus **uses `authority="none"` 3×**, all in `rendered/context-memory.bpmn:21,29,40`. The string `none` appears **0 times** in the frozen standard (`grep -c none docs/standards/aef-bpmn-mapping-v1.md` → 0). Corpus lane authority census: `authority` 23, `initiative` 23, `sovereignty` 15, `external` 3, `none` 3. | HEAD | structure |
| **C. Corpus constructs the editor would lose or cannot reach** | | | | | |
| C1 **Nothing is lost on round-trip.** | P2 harness over all 24 corpus maps | EXISTS | `pass: true`. Every one of 24 maps: `ok=True`, `deterministic=True`, `projEqual=True`, `byteIdempotent=True`, `drift=""`, node/edge/lane counts preserved. `selftest.unperturbable = []`. Summary string: `"36 keys / 21 LIVE / 0 BLIND / 0 DRIFT-ELSEWHERE / 0 NOT-EXERCISABLE / 15 NEVER-PRESENT over 24 fixtures"`. | HEAD | value |
| C2 `decisionOutputs` on `exclusiveGateway` — carried but **unreachable in the panel** | corpus + `AEF_FIELDS` | EXISTS / PARTIAL | P5: corpus hosts `<aef:decisionOutputs>` on **`exclusiveGateway` 17× and `userTask` 6×**. Editor offers the field on `userTask` only (`src/…:1889`); `exclusiveGateway`'s field list is `['determinism','decisionInput','decisionOwner','note']` (`:1891`). The exporter is type-agnostic (`:9881` `if (aef.decisionOutputs)`) so the value survives — but 17 of 23 corpus values can be neither seen nor edited. | HEAD | friction |
| C3 `<aef:emits>` structured vs scalar `emits` — two shapes for one name | corpus + editor | conflict | Corpus carries the **structured** form (`rendered/audit-process.bpmn`: `<aef:emits><aef:emit value="pass"/>…`, 5 wrappers). Editor's panel offers `emits` as a **scalar** text field on `endEvent` (`src/…:1879`, `:1966`). The structured exporter fires only on `Array.isArray(aef.emits)` (`:9946`); a scalar falls through to `<aef:meta emits="…">` carriage — stated verbatim at `:9836-9841`. Both survive; they are different serializations of the same key. | HEAD | structure |
| C4 `aef:multiInstance`, `aef:aggregation`, `aef:compensates`, `aef:timer` — carried, no UI | corpus + editor | EXISTS (round-trip) / ABSENT (authoring) | Corpus: `multiInstance` 3 (`fabric-blast-radius`, `revisit-due-scan`, `session-capture`), `aggregation` 2 (`audit-process`, `fabric-blast-radius`), `compensates` 1 wrapper / 2 `<aef:compensate>` (`upgrade-process`), `timer` 1 (`revisit-due-scan`). Editor reads them (`src/…:10854-10865`) and re-emits them (`:9943-9959`) — P2 confirms byte-idempotence — but **none appears in `AEF_FIELDS` or `FIELD_META`** (`:1861-2029`), so none is authorable or visible. | HEAD | friction |
| C5 `io` types `enum` and `computed-set` not in the editor picker | corpus + editor | conflict | Corpus `type=` vocabulary (P5): `enum` 4, `computed-set` 1. `IO_TYPES` (`src/…:2055`) offers neither. Round-trip preserves them (P2 byte-idempotent) but the picker cannot re-select them after an edit. | HEAD | friction |
| C6 Corpus `rendered/` has LOST 250 bridge-emitted values | P3 fresh-render diff | EXISTS (loss is committed) | Per-key `occurrences (files)` — fresh bridge render vs committed `rendered/`: `determinism` **199 (23) → 0 (0)**; `sideEffect` **38 (14) → 0 (0)**; `advisory` **9 (6) → 0 (0)**; `autoTriggerKind` **5 (4) → 0 (0)**; `compensatedBy` **2 (1) → 0 (0)**; `restoresFrom` **1 (1) → 0 (0)**; `compensationSnapshot` **1 (1) → 0 (0)**; node-level `authority=` **7 (7) → 0 (0)**. Total 262 → 0. Unchanged: `tier` 74, `agentType` 17, `decisionOwner` 54, `aef:position` 306, `aef:io` 28, `constituents` 6, `emits` 5, `multiInstance` 3, `aggregation` 2, `compensates` 1, `timer` 1, `subProcess` 2. | HEAD | cost |
| C7 The 8 lost keys are **bridge-only** vocabulary | `tools/yaml-to-bpmn.py:56-59` vs `src/…:9819-9824` | EXISTS | Bridge `META_KEYS` (29) ⊋ editor `metaKeys` (20). The 9 bridge-only keys are exactly `determinism`, `authority`, `endpoint`, `sideEffect`, `autoTriggerKind`, `restoresFrom`, `compensationSnapshot`, `compensatedBy`, `advisory`. Eight of those nine are the keys C6 shows missing from `rendered/`; the ninth (`endpoint`) survives because the editor has its own element emitter for it (`:9877`) — the mechanism is stated verbatim at `src/…:9829-9832`. | HEAD | structure |
| C8 The loss is **committed history**, not a live regression | `git log` | EXISTS | `rendered/` was re-baked from **editor-saved** bytes, not from the bridge: `bdcfbc86` ("T-300: … write buildBpmnXml byte-verbatim from the Clean session, YAML patch removed … regen forbidden") and `2d33b2b0` ("T-145: Adopt 11 editor-saved layouts as canonical corpus"). Four maps were then **hand-edited in editor dialect** (`4dc64858` T-288, `30aeff5e` T-298 "rendered twin hand-edited in-dialect"). T-570's carriage fix (`src/…:9826-9853`) post-dates the bake, so it cannot retroactively restore them. | `2d33b2b0` → `bdcfbc86` | cost |
| C9 Drift now runs **both** ways | P3 diff | EXISTS | Committed `rendered/` carries `note=` values the canonical YAML does not: `error-escalation-ladder` fresh 0 / committed 2; `healing-loop` 2 / 3; `tier0-escalation` 1 / 2. So the "generated, not hand-authored / canonical source is always the `.workflow.yaml`" claim in `examples/aef-processes/rendered/README.md:1-3,20-21` is contradicted by the tree at HEAD. | HEAD | friction |
| C10 Editor and bridge emit **different dialects** for the same datum | P3 + corpus | conflict | `endpoint`: bridge emits the attribute `endpoint="…"` inside `<aef:meta>` (`tools/yaml-to-bpmn.py:56`, verified in `/tmp/vr05/healing-loop.bpmn`); editor emits the element `<aef:endpoint>…</aef:endpoint>` (`src/…:9877`). Committed corpus carries **108 `<aef:endpoint>` elements, 0 `endpoint=` attributes**; a fresh bridge render carries **0 elements**. Same for presentational layout: fresh render has 0 `<aef:anchors>`, 0 `<aef:routing>`, 0 `<aef:routingHint>`, 0 `<aef:loopDetour>`; committed corpus has 55 / 9 / 9 / 3. | HEAD | structure |
| **D. Standard-vs-corpus conformance** | | | | | |
| D1 The corpus emits **none** of the frozen governance meta-keys that the standard marks MUST | standard §2 vs corpus | conflict | `docs/standards/aef-bpmn-mapping-v1.md:55` — "A conformant editor MUST emit each on task-like nodes, and the bridge MUST round-trip each." Corpus totals (P1, independent grep): `tier` 74 occ / 14 files ✓, `agentType` 17 / 7 ✓, `horizon` **0 / 0** ✗, `workflowType` **0 / 0** ✗. So 2 of the 4 frozen keys appear on **zero** of 306 corpus nodes. | HEAD | usage |
| D2 The conformance test cannot see D1 | `tests/test_mapping_standard_conformance.py` | EXISTS, PASSES | P4 output: `"OK: all 4 frozen governance meta-keys [horizon, workflowType, tier, agentType] present in both editor metaKeys and bridge META_KEYS"`, exit 0. It compares **key lists**, not emitted documents. `tests/test_editor_bridge_meta_parity.py` likewise: `"OK: all 20 editor metaKeys … present in bridge META_KEYS (29 keys)"`. Neither test opens a corpus map. | HEAD | structure |
| D3 Zero standard-conformant inceptions exist in the corpus | standard §7 vs corpus | conflict | §7 (`:134-142`): an inception is a **collapsed `subProcess` carrying `aef:meta workflowType="inception"`, sovereignty-laned**, go/no-go implied at the boundary. Corpus has exactly **2 `<bpmn:subProcess>`** — `rendered/resume-status.bpmn` (`n_intel`, meta `tier="1" note="FC-11 composite…"`) and `rendered/session-capture.bpmn` (`n_capture`, meta `tier="1" note="FC-11 composite…"`). **Neither carries `workflowType`**, so by the standard's own detection rule ("`subProcess` **with** `workflowType="inception"` ⇒ inception; **without** ⇒ ordinary composite", `:140-142`) both are ordinary composites. Meanwhile `rendered/inception-lifecycle.bpmn` and `rendered/inception-review.bpmn` model inception *as a whole flow* with 0 subProcess nodes. The sole §7 example lives in a test fixture: `tests/fixtures/aef-bpmn/inception-gonogo.bpmn`. | v1.1 (2026-07-12) → HEAD | usage |
| D4 The corpus uses 8 of ~20 BPMN element kinds | corpus | EXISTS | Corpus element census (P1, occurrences): `sequenceFlow` 319, `scriptTask` 111, `lane` 67, `endEvent` 59, `exclusiveGateway` 52, `serviceTask` 40, `startEvent` 26, `userTask` 12, `parallelGateway` 4, `subProcess` 2. **Zero** occurrences in all 24 maps of: `intermediateCatchEvent`, `intermediateThrowEvent`, `boundaryEvent`, `inclusiveGateway`, `eventBasedGateway`, `complexGateway`, `textAnnotation`, `association`, `dataObject`, `dataObjectReference`, `dataStoreReference`, `callActivity`, `businessRuleTask`, `manualTask`, `receiveTask`, `sendTask`, `transaction`, `adHocSubProcess`, `messageFlow`, `group`. | HEAD | usage |
| D5 The corpus ships **no BPMN DI** | corpus | EXISTS | `bpmndi` appears exactly once per file and only as the namespace declaration on `<bpmn:definitions>` (`rendered/task-gate.bpmn:3`). **0 `<bpmndi:BPMNDiagram>` elements** in any of the 24 maps (P1). Layout is carried entirely by the `aef:` presentational class: `aef:position` 306, `aef:anchors` 55, `aef:routingHint` 9, `aef:routing` 9, `aef:loopDetour` 3. `aef:waypoint` and `aef:forceStraight` — both named in the standard's presentational list `:42-44` and `aef:waypoint` in `docs/designer/schema.md:586` — appear **0 times**. | HEAD | structure |
| **E. `docs/designer/schema.md` fidelity** | | | | | |
| E1 The `aef:endpoint` contradiction **still stands** | schema.md vs frozen standard | conflict | `docs/designer/schema.md:239` — "**`endpoint`** — what executes this step." `docs/standards/aef-bpmn-mapping-v1.md:42-45` lists `aef:endpoint` in the **Presentational (diagram cosmetics)** class, which the forward compile "MUST NOT" read and for which "A change to a presentational attribute alone MUST be a no-op for the task graph". Carried for context only per this leg's brief; **re-verified present at HEAD `12ad8f9f`, unchanged.** | HEAD | structure |
| E2 A second contradiction of the same shape: `aef:decisionOutputs` serialization | schema.md vs implementation + corpus | conflict | `docs/designer/schema.md:580` — "`aef:decisionOutputs` \| inside userTask extensionElements \| `values="…"` **attribute**". Actual editor emitter writes **element text** (`src/…:9881`), and the corpus agrees: `<aef:decisionOutputs>close, abandon</aef:decisionOutputs>` (`rendered/*.bpmn`, 46 `aef:decisionOutputs` tokens = 23 element pairs). Zero `values="` attributes on that element anywhere. schema.md also scopes it "userTask only"; 17 of 23 corpus instances are on `exclusiveGateway` (P5, cf. C2). | HEAD | structure |
| E3 schema.md is stale by ~9 shipped feature tasks | `git log` | EXISTS but stale | Last commit touching `docs/designer/schema.md` is `fd6f26a5` (T-081, subProcess phase 1). Shipped since, and **entirely absent** from schema.md (`grep -n` returns 0 hits for each): `eventError`, `eventTimer`, `eventMessage`, `eventDef`, `boundaryEvent`, `hostRef`, `fabricRef`, `determinism`, `sideEffect`, `horizon`, `workflowType`. (The only `grep -i horizon` hits at `:65,445,460-462` are the word "horizontal" in the routing section.) Corresponding tasks: T-177, T-204, T-225, T-570, T-589, T-602, T-618. | `fd6f26a5` → HEAD | cost |
| E4 schema.md's `aef:meta` description is 5 keys behind the writer | schema.md vs editor | conflict | `docs/designer/schema.md:575` — "`aef:meta` … Carries tier, agentType, decisionOwner, triggeredBy, emits as attributes" (5 keys, incl. `emits` which is now a structured element, cf. C3). Editor `metaKeys` is **20** (`src/…:9819-9824`); bridge `META_KEYS` is **29** (`tools/yaml-to-bpmn.py:56-79`). | HEAD | structure |
| E5 schema.md's `aef:link` row predates `workflowRef` | schema.md vs editor | conflict | `docs/designer/schema.md:588` lists only `targetWorkflow=`, `linkId=`. T-225 made `workflowRef` (uuid, rename-stable) authoritative with `targetWorkflow` a back-compat alias (`src/…:1990-1997`, `:9886-9900`). | HEAD | structure |
| E6 schema.md declares "ten-element BPMN subset"; the palette has 12 | schema.md vs editor | conflict | `docs/designer/schema.md:170-172` + table `:175-187` (11 rows, of which `sequenceFlow` is an edge ⇒ 10 node types). Palette: 12 `data-create=` entries (`src/…:1199-1336`) — the three typed events are the surplus. | HEAD | structure |

---

## THE THREE-WAY DIFF (condensed)

### (a) ∖ (c) — editor can author it, **zero** corpus documents contain it

Measured two independent ways and the two agree.

**Harness verdict (P2).** `"36 keys / 21 LIVE / 0 BLIND / 0 DRIFT-ELSEWHERE / 0 NOT-EXERCISABLE / 15 NEVER-PRESENT over 24 fixtures"`, `proven_fraction: "21/36"`.

The 15 NEVER-PRESENT keys, with the shape the editor would have serialized them into:

| Key | Shape | Key | Shape |
|---|---|---|---|
| `scopeOf` | metaattr | `targetWorkflow` | linkattr |
| `horizon` | metaattr | `linkId` | linkattr |
| `workflowType` | metaattr | `hostRef` | attachedref |
| `owner` | metaattr | `interrupting` | cancelact |
| `errorStatus` | eventbind | `eventDefKind` | eventkind |
| `timerSpec` | eventbind | `eventDefBinding` | eventbind |
| `busTopic` | eventbind | | |
| `workflowRef` | linkattr | `name` | linkattr |

The 21 LIVE keys (present somewhere in the corpus and proven to survive round-trip): `tier`,
`agentType`, `decisionOwner`, `triggeredBy`, `terminalKind`, `state`, `note`, `softFail`,
`section`, `guard`, `external`, `exitCode`, `autoTrigger`, `trigger`, `gatewayKind`, `gate`,
`endpoint`, `contextReads`, `artifactsWrites`, `decisionInput`, `decisionOutputs`.

**Independent grep (P1).** The 16 `<aef:meta>` attribute names actually used across all 24 maps:
`tier` 74, `decisionOwner` 54, `note` 26, `terminalKind` 19, `state` 19, `triggeredBy` 18,
`agentType` 17, `softFail` 8, `guard` 8, `exitCode` 6, `section` 5, `external` 4, `autoTrigger` 3,
`trigger` 2, `gatewayKind` 2, `gate` 2. The editor's `metaKeys` minus that set is exactly
`{scopeOf, horizon, workflowType, owner}` — the four metaattr rows above.

**Outside the harness's 36-key spec** but also zero-in-corpus: `fabricRef`, `links` (T-589),
`sideEffect` and `determinism` in the *rendered* corpus (both present in the canonical YAML —
see C6/C11 below for why the two disagree). And four `IO_TYPES` values: `number`, `ref`,
`arc_id`, `object`.

**Node types**: 5 of the editor's 12 palette types (`linkEventThrow`, `linkEventCatch`,
`eventError`, `eventTimer`, `eventMessage`) instantiate **zero** times across 306 corpus nodes.

### (b) ∖ (a) — standard declares it, editor cannot author it

| Standard construct | Cite | Editor status |
|---|---|---|
| `aef:arc` on the process | `:83` | **ABSENT** — 0 hits in `src/`, 0 in `tools/yaml-to-bpmn.py`, 0 in corpus. Exists only in prose. |
| node documentation/annotation as AC seed | `:95` + Part II `:153-155` | **PARTIAL** — preserved on round-trip (T-602), no authoring field; the seed format is unratified. |
| `tier` absent-value default | `:151-152` (Part II) | **DESIGNED-ONLY** — unratified; corpus works around it with `workflowMeta/@tier_default` (24/24). |
| node-level `owner` carrier | `:68` | **Deliberately removed** in v1.1; the editor matches. Not a gap. |
| `aef:waypoint`, `aef:forceStraight` (presentational) | `:42-44` | Editor emits both (`forceStraight` 13 hits in `src/`); corpus contains **0** of either. |
| `owner`/`workflowType` MUST-emit on task-like nodes | `:55` | Editor can; corpus does not (D1). The gate that should catch this checks lists, not documents (D2). |

Also in (b) but **not** in (a) as a *value*: lane authority `none`. The standard's collapse map has
four values (`:97`); the editor's `AUTHORITIES` has five (`src/…:1623`) and the corpus uses the
fifth 3×. `ownerFromAuthority('none')` returns `''` (`src/…:1950-1952`), i.e. "no task", the same
as `external`, but nothing in the standard says so.

### (c) ∖ (a) — corpus constructs the editor would lose on round-trip

**Nothing. Zero.** P2 over all 24 committed corpus maps: `pass: true`, every map
`ok / deterministic / projEqual / byteIdempotent = True`, `drift` empty, `unperturbable: []`.
The editor is a **semantic and byte-level fixed point** on the corpus as committed.

The finding directly adjacent to it, which is *not* a round-trip loss:

- **C2 / C4 / C5 — carried but unreachable.** 17 gateway-hosted `decisionOutputs`, 3
  `multiInstance`, 2 `aggregation`, 1 `compensates`, 1 `timer`, and the `enum`/`computed-set`
  io types all survive open→save byte-identically, but none is exposed in the properties panel.
  Preserved, not editable, not visible.
- **C6 / C11 — the loss already happened, upstream, and is committed.** A fresh bridge render of
  the same 24 canonical YAMLs carries **262 values** (8 distinct keys) that the committed
  `rendered/` maps do not. The largest is `determinism`: 199 authored values across 23 of 24
  maps, present in `*.workflow.yaml`, absent from every `*.bpmn`. Per `src/…:9826-9832`, the
  pre-T-570 editor "loaded those values, rendered them nowhere, and DESTROYED them on the next
  save"; per `bdcfbc86`/`2d33b2b0` the corpus was re-baked **from editor saves**. T-570 fixed the
  editor; it did not restore the corpus bytes.

**C11 (the reconciliation).** A11's two readings are recorded side by side and not averaged:
`determinism` is **199 occurrences / 23 files** in the canonical YAML corpus and **0 / 0** in the
rendered BPMN corpus. Both are true of the tree at HEAD. Which one is "the corpus" is a question
this leg does not answer.

---

## NON-USE DIAGNOSIS EVIDENCE (A–E), per zero-use editor capability

No classification is made. Each row records only what was found for each reading.
There is **no product usage telemetry in this repo**, so **every** row carries a D.

### 1. `horizon` + `workflowType` (A1, A2) — 0 of 306 corpus nodes

- **A BROKEN?** No evidence of breakage. P2 round-trips them in the `governance-key-coverage.bpmn`
  fixture; P4 conformance and parity tests both pass, exit 0. `tests/fixtures/aef-bpmn/governance-key-coverage.bpmn` exists and is exercised.
- **B NEVER WIRED?** Origin task **T-177** (`.tasks/completed/T-177-emit-aef-horizon-workflow-type-owner-as-.md`). Its Context says the goal was a *"Low-regret, standalone editor capability that de-risks the designer-authoring-surface arc's forward-bridge (child-2) **without pre-deciding the mapping contract**"*. All six Agent ACs are editor/bridge/round-trip assertions; **none** requires a corpus document, a forward-compile consumer, or an authoring workflow to use the field. The consumer named ("child-2 forward bridge") is `docs/standards/aef-bpmn-forward-compile-v1.md`; whether a runtime reads it is outside this leg.
- **C UNDISCOVERABLE?** Both are offered as panel selects on the 4 task-like types (`src/…:1888-1890,1903`) — so, discoverable *in the app*. But: **absent from `docs/designer/schema.md`** (0 hits, E3), `docs/designer/user-guide.md` has 0 hits for "Workflow type" (the 3 `horizon` hits there need separate inspection), and `README.md` has 0 hits for either.
- **D UNMEASURED?** Yes — unconditionally. No instrumentation on any editor path.
- **E NOT WANTED?** No positive recorded reason found. Searched `.context/gaps.yaml` / `.context/concerns.yaml` (neither file exists at HEAD; `ls .context/*.yaml` returns `bvp-weight-history`, `bypass-log`, `cron-registry`, `inbox`, `settings`). No decommission task, no NO-GO.
- **INTENT:** Named in the **frozen standard as a MUST** (`:55-62`, `:64-70`) — the strongest intent evidence in this leg. Origin task T-177 completed. `workflowType` appears in 19 task files, `horizon` in 744 (the latter is dominated by the AEF framework's own task frontmatter field, not the BPMN attribute — do not read 744 as designer demand).

### 2. `owner` as an emitted attribute (A3) — 0 of 306

- **E NOT WANTED — positive evidence exists, uniquely in this leg.** The standard removed it:
  *"the node-level `owner` override is **removed** (§2 table + conformance fence, §3), `owner` now derives from the lane authority (T-189)"* (`docs/standards/aef-bpmn-mapping-v1.md:8-10`), ratified by sovereign GO (`2aadc1e2`). The key is retained in `metaKeys` only "for O-2 reverse-render laning" (`src/…:1882`).
- **A/B/C:** not applicable in the same sense — the panel field was deliberately retired (`:1880-1883`, `:2017-2021`).
- **D UNMEASURED:** yes.

### 3. Typed events + their bindings (A5, A6, A10) — 0 of 306

- **A BROKEN?** No. Dedicated fixtures exist and are exercised: `tests/fixtures/aef-bpmn/typed-events.bpmn`, `tests/test_typed_events.py`, `tests/test_typed_event_fixture_contract.py`, `tests/test_t259_eventdef_preservation.py`, `tests/fixtures/aef-bpmn/t257-eventdef-roundtrip/`. Not run in this leg (read-only budget), but present.
- **B NEVER WIRED?** Origin **T-204** (`.tasks/completed/T-204-typed-bpmn-event-palette-errortimermessa.md`). The standard row it produced (`:93`) declares the semantics — error→`status:issues`, timer→cron/`horizon`, message→bus topic — and explicitly says the node is "a Trigger annotation on the flow (**no task itself**)". Whether any consumer acts on that binding is outside this leg; no corpus map exercises it.
- **C UNDISCOVERABLE?** In-app: three palette tiles, `src/…:1311,1323,1336` — discoverable. In docs: **`eventError`/`eventTimer`/`eventMessage`/`eventDef` = 0 hits in `docs/designer/schema.md` and 0 in `docs/designer/user-guide.md` and 0 in `README.md`.** schema.md still declares a "ten-element BPMN subset" (E6).
- **D UNMEASURED?** Yes.
- **E NOT WANTED?** No positive reason found.
- **INTENT:** Named in the **frozen standard §3 row `:93`** (added by `4a1a30e1`, T-204). Referenced by 5 task files ("typed event"), 3 for `eventTimer`.

### 4. Boundary-event attachment (A9) — 0 of 306

- **A BROKEN?** No. Fixture `tests/fixtures/aef-bpmn/boundary-events.bpmn` and `governance-key-coverage.bpmn` both carry `bpmn:boundaryEvent`.
- **B NEVER WIRED?** T-204 Slice 2 (`src/…:1897-1899`). No corpus adoption.
- **C UNDISCOVERABLE?** 0 hits for `hostRef`/`boundaryEvent` in schema.md; 1 case-insensitive hit for "boundary" in user-guide.md (needs separate read to know if it is this feature).
- **D UNMEASURED?** Yes. **E?** No positive reason found.
- **INTENT:** **Not named in the frozen standard at all** — the standard's §3 event row (`:93`) covers in-flow `intermediateCatchEvent` only; `boundaryEvent` appears 0 times in `docs/standards/aef-bpmn-mapping-v1.md`. Referenced by 6 task files.

### 5. Off-page connectors (A7, A8) — 0 of 306

- **A BROKEN?** No. Fixtures `offpage-seam.bpmn`, `s4-exemplar.bpmn`, `bare-catch-event.bpmn`; guards `tests/test_t308_bare_catch_render.py`, `tools/_offpage-seam-parity-verify.py`.
- **B NEVER WIRED?** Origin **T-225** (S2 workflowRef serialization). The feature is *cross-workflow*; the 24 corpus maps are each self-contained, so an unused cross-reference is what a single-file corpus with no declared inter-map edges would look like either way.
- **C UNDISCOVERABLE?** **Best-documented of the unused features** — `docs/designer/user-guide.md` has 18 hits for "off-page|Handoff". But schema.md's `aef:link` row (`:588`) is two contract revisions stale (E5).
- **D UNMEASURED?** Yes. **E?** No positive reason found.
- **INTENT:** Named in the **frozen standard §3** (`:92`, linkEventThrow/Catch → `related_tasks`). 28 task files mention off-page/offpage.

### 6. `fabricRef` / `links` (A13) — 0 of 306

- **A BROKEN?** No evidence either way in this leg. **B?** Origin **T-589**; ships as scalars riding T-570 carriage specifically so as *not* to be a contract change (`src/…:2022-2026`). **C?** 0 hits in schema.md, user-guide.md, README.md. **D?** Yes. **E?** No positive reason found.
- **INTENT:** **Not named in the frozen standard** (0 hits). Referenced by 5 task files. The T-589 commit subject is itself a usability claim: *"the panel could show these two values all along — it just could not click them or let anyone type them"* (`3b6e262f`).

### 7. `determinism` / `sideEffect` (A11, A12) — 0 in rendered BPMN, 199 / 38 in canonical YAML

- **A BROKEN? — positive evidence, recorded verbatim.** `src/…:9826-9832`: *"A key present in a source document and absent from `metaKeys` was therefore loaded, rendered nowhere, and DESTROYED on the next save — not invisible (that was T-566), destroyed. Measured by an actual round trip in the page … of the 4 keys the corpus carries outside `metaKeys`, `determinism` (16), `sideEffect` (2) and `emits` (1) do not survive parse→build→parse."* Fixed by T-570; the corpus bytes were baked before the fix (C8).
- **C UNDISCOVERABLE?** Was, by construction, until T-618 (`504e4bc9`: *"surface determinism + sideEffect — 215 authored values the panel could not show"*). Still 0 hits in schema.md / user-guide / README.
- **D UNMEASURED?** Yes. **E?** No positive reason found.
- **INTENT:** **Not in the frozen standard** (0 hits for either). But present in the **bridge's** `META_KEYS` since before T-060 (`tools/yaml-to-bpmn.py:56`, listed first), authored 199× in the canonical corpus, and referenced by 33 task files. `determinism` is the clearest case in this leg of a construct with heavy authored use and zero standing in the frozen contract.

### 8. `scopeOf` (A4) — 0 of 306, 0 in fresh render

- **A?** No breakage evidence; fixture `tests/fixtures/aef-bpmn/two-lane-joint.bpmn` and `inception-gonogo.bpmn` carry subProcesses. **B?** Origin T-081 (FC-15 marker), same task that shipped `constituents` — and `constituents` **is** used (6 corpus instances). So the sibling feature from the same task landed and this one did not. **C?** schema.md **does** document it (`:225-232`, §4.4) — the one unused field with live doc coverage. **D?** Yes. **E?** No positive reason found.
- **INTENT:** In the bridge `META_KEYS` (`tools/yaml-to-bpmn.py:73-76`, "validator checks it resolves"), in the editor panel, in schema.md §4.4. Not in the frozen standard (0 hits for `scopeOf`).

### 9. `aef:arc` (B1) — declared by the standard, built nowhere

- **A?** Cannot be exercised — no implementation exists. **B NEVER WIRED?** There is no wiring and no caller; `grep -rn 'aef:arc'` returns five prose hits and zero code hits. **C?** It *is* in the standard, so not undiscoverable to a reader of the contract. **D?** Yes. **E?** No positive reason found.
- **INTENT:** Declared in **Part I frozen** `:83` and in `docs/standards/aef-bpmn-forward-compile-v1.md:55`, traced back to `docs/reports/T-175-mapping-strawman.md:50`, and mirrored by AEF-side reports (`.agentic-framework/docs/reports/T-2522-…:33`, `T-2523-…:21`). The intent is documented on **both sides of the seam**; the implementation is on neither.

---

## Conflicting data points, recorded side by side (not reconciled)

1. **How many `determinism` values does the corpus have?** `199 / 23 files` (canonical
   `*.workflow.yaml`, P3) vs `0 / 0 files` (rendered `*.bpmn`, P1). Both measured at HEAD.
2. **What is the canonical form of `rendered/`?** `examples/aef-processes/rendered/README.md:1-3`:
   *"These files are generated, not hand-authored … produced from the canonical `../*.workflow.yaml`"*
   and `:20-21` *"Do not edit these `.bpmn` files by hand"*. Against: `bdcfbc86` (baked from editor
   saves, *"regen forbidden"*), `4dc64858` and `30aeff5e` (*"rendered twin hand-edited in-dialect"*),
   and the 3 maps where committed `note=` exceeds a fresh render (C9).
3. **Is `aef:endpoint` semantic or presentational?** `docs/designer/schema.md:239` (*"what executes
   this step"*) vs `docs/standards/aef-bpmn-mapping-v1.md:42-45` (Presentational; forward compile
   MUST NOT read it). Unchanged at HEAD (E1).
4. **Is the corpus v1-conformant on §2?** `tests/test_mapping_standard_conformance.py` exits 0
   (D2) vs 0/306 nodes carrying `horizon` or `workflowType` (D1). The test and the corpus measure
   different things and both are green/red on their own terms.
5. **How large is the editor's key surface?** 20 (`metaKeys`) vs 29 (bridge `META_KEYS`) vs 36
   (harness spec) vs 5 (schema.md's `aef:meta` row, `:575`). Four numbers for one surface.

---

## Sources expected and found ABSENT

| Expected | Result |
|---|---|
| `.context/gaps.yaml`, `.context/concerns.yaml` | **ABSENT at HEAD.** `ls .context/*.yaml` → `bvp-weight-history.yaml`, `bypass-log.yaml`, `cron-registry.yaml`, `inbox.yaml`, `settings.yaml` only. No gap/concern register was available to check for a recorded reason behind any zero-use feature (the E-reading is therefore under-evidenced across the board, not disproven). |
| Any `aef:arc` implementation | **ABSENT.** Standard-declared, zero code. |
| `<bpmndi:BPMNDiagram>` in the corpus | **ABSENT** (0/24). Portability-relevant: a stock BPMN tool opening these files gets no diagram interchange, only the `aef:` layout class. |
| `<bpmn:documentation>` in the corpus | **ABSENT** (0/24), despite the standard's §3 AC-seed row and the editor's T-602 preservation work. |
| A corpus-level conformance check (standard §2 MUST vs actual documents) | **ABSENT.** `tests/test_mapping_standard_conformance.py` checks list membership only; no test in `tests/` opens `examples/aef-processes/rendered/` to assert the frozen keys are emitted. |
| A standard-conformant §7 inception in the corpus | **ABSENT** (0/24). The only instance is the fixture `tests/fixtures/aef-bpmn/inception-gonogo.bpmn`. |
| `aef:waypoint` / `aef:forceStraight` in the corpus | **ABSENT** (0/24), though both are named in the standard's presentational list and `aef:waypoint` in schema.md `:586`. |
| Any product usage telemetry | **ABSENT** (operator-confirmed). Every usage row above is UNMEASURED as to real-world use; "0 corpus occurrences" is a statement about 24 files, not about users. |
