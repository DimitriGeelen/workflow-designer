# Designer contract inventory — what our frozen surface actually says

**Task:** T-590 · **Written:** 2026-08-26 · **Role:** workflow-designer-agent
**Initiative:** `ewcr-v1` · **Correlation:** `ewcr-v1-designer-fixture`
**AEF references (by reference only):** draft `arc-019` / `ewcr-arc0-contract-evidence`, anchor `T-3147`
**Contract under inventory:** `docs/standards/aef-bpmn-mapping-v1.md` **v1.1 (2026-07-12)**, Part I frozen
**Status:** research artifact. Nothing here ratifies, decides, or moves a boundary.

---

## 0. What this document is for, and what it is not

Roadmap Arc 1's joint gate asks the Designer to *"render the canonical fixture without
inventing semantics"*. `questions-and-dispositions.md` **IW-7** established that this gate
is currently **unpassable** — not because our surface is weak, but because our forward
mapping **infers**, **defaults** and **derives**, and neither side has written those rules
down. A renderer that supplies a default is inventing semantics unless the runtime contract
declares the same default normatively.

This inventory discharges that. It states, for every governance-bearing datum our surface
carries: the value, the closed set, the absent-value behaviour, the citation, and — where the
rule is unratified or self-contradictory — the **named request** that must come back from AEF.

It is **read-only with respect to every existing contract**. It moves no Part I boundary,
adds no node kind, changes no compiler behaviour, and cannot ratify anything. Where it
records a defect, the defect already exists and already carries its own task; naming it here
does not schedule it.

**Ownership frame** (dossier §5.1): the Workflow Designer owns authoring, visualisation,
import/export and lossless round trips. AEF owns governance, validation, authority,
ratification, execution, secrets and evidence. Everything in this document is on our side of
that line. Nothing in it asks the Designer to be an authority, and nothing in it should be
read as the Designer supplying runtime semantics.

---

## 1. The frozen Part I surface

Part I of `aef-bpmn-mapping-v1.md` is **ratified and stable; changes require a version bump**
plus a conformance-test update (§Versioning). It is machine-fenced by
`tests/test_mapping_standard_conformance.py`. Part II (`tier` default, AC-seeding) is
**provisional and MUST NOT be relied on as settled** — open on termlink thread T-175 since
**2026-07-11**.

| § | What it fixes | One-line contract |
|---|---|---|
| §1 | Two attribute classes | Every `aef:` datum is exactly one of **semantic** (governance-bearing) or **presentational** (cosmetic). The forward compile MUST read only the semantic class |
| §2 | Governance meta-keys | Exactly four frozen scalar keys, carried as attributes of a single `aef:meta` element |
| §3 | Forward mapping | Diagram → **proposed** governed work. Never authored silently; approval is a separate sovereignty gate |
| §4 | Reverse mapping | AEF's own structured record → rendered process map. Arbitrary source parsing is out of scope for v1 |
| §5 | Identity | `aef:uid` on **every** node and edge, stable, **externally assignable** |
| §6 | Conformance | Four numbered requirements; an implementation is v1-conformant iff all four hold |
| §7 | Inception marker | Collapsed `subProcess` + `workflowType="inception"` + sovereignty lane, go/no-go implied at the boundary |

**The compatibility statement both sides already agree on.** Dossier §0.1 and §6.1 say the
runtime "does not alter the Mapping Standard's frozen Part I; a runtime contract is a
separately versioned extension", and that "frozen mapping v1.1 continues to compile a diagram
only into *proposed* governed work". Our §3 says the same thing from the other side. There is
**no boundary conflict at the level of stated intent** (IW-1, confidence 3). This inventory
therefore describes a surface AEF must design *around*, not *into*.

---

## 2. The §1 semantic / presentational partition (normative)

This partition is what bounds a diagram edit. It is the single most important thing for a
runtime designer to know, because it determines which bytes in a document can change meaning.

**Semantic (governance-bearing)** — compiles into / out of task-YAML. The forward compile
MUST read **only** this class:

- structured elements: `aef:artifactsWrites`, `aef:contextReads`,
  `aef:decisionInput` / `aef:decisionOutputs`, `aef:io` / `aef:input` / `aef:output`,
  `aef:constituents`, `aef:link`
- the identity key `aef:uid` (§5)
- the scalar **governance meta-keys** carried as attributes of `aef:meta` (§2, §3 below)

**Presentational (diagram cosmetics)** — the reverse compile MAY write these (layout) but MUST
treat them as **derived, never authoritative**:

`aef:position`, `aef:anchors`, `aef:endpoint`, `aef:waypoint`, `aef:routing`,
`aef:routingHint`, `aef:forceStraight`, `aef:loopDetour`, and the `aef:extensionElements`
wrapper.

> **The invariant AEF can rely on:** *a change to a presentational attribute alone MUST be a
> no-op for the task graph* (§1, last sentence). This is the reason a geometry migration can
> be in flight (IW-5: T-357 → T-423 → T-424, plus T-340) without moving Part I's semantic
> contract. `aef:position` is presentational, so retiring it in favour of BPMN DI is not a
> semantic change — but any Arc 0 "version matrix" agreed **before T-424 lands** would pin
> AEF to a geometry form we intend to retire. Pin the semantic classes, not the geometry.

---

## 3. Governance meta-keys — values, defaults, inference, derivation

This is §2 of the standard plus the §3 `owner` ruling, restated as a decision table with the
absent-value behaviour made explicit. **This section is the resolvable form of IW-7 and is
what request R3 asks AEF to accept or override, rule by rule.**

The frozen key list is machine-fenced in the standard itself as a literal block
(` ```conformance-governance-meta-keys `) containing exactly, and in this order:

```
horizon
workflowType
tier
agentType
```

A conformant editor **MUST** emit each on task-like nodes, and the bridge **MUST** round-trip
each. Parity is enforced two ways: standard ↔ implementation by
`tests/test_mapping_standard_conformance.py`, and editor ↔ bridge (`metaKeys` ⊆ `META_KEYS`)
by `tests/test_editor_bridge_meta_parity.py` (T-060).

| Key | Task-YAML field | Closed value set | **Absent-value behaviour** | Kind of rule | Ratification state |
|---|---|---|---|---|---|
| `horizon` | `horizon` | `now` \| `next` \| `later` | **`now`** | **DEFAULT** — a fixed constant | Part I frozen |
| `workflowType` | `workflow_type` | `build` \| `test` \| `refactor` \| `decommission` \| `specification` \| `design` \| `inception` | **inferred from the BPMN type**: service/script → `build`; user → `human-facing` | **INFERENCE** — derived from document shape | Part I frozen, **but internally inconsistent — see D-1** |
| `owner` | `owner` | `human` \| `agent` | **derived from the node's lane authority; no node-level override exists in v1.1** | **DERIVATION** — from a different element | Part I frozen (IW-9, T-189) |
| `tier` | enforcement tier | `0`..`3` | **"project default"** — the canonical default is **unratified** | DEFAULT, undefined | **Part II provisional, open since 2026-07-11** |
| `agentType` | agent assignment | `primary` \| `termlink-worker` \| `human` | **`primary`** | DEFAULT — a fixed constant | Part I frozen |

**The `owner` derivation in full (§3, IW-9 v1.1).** A node's `owner` **MUST** be its lane.
There is **no** node-level `owner` override. The lane's `aef:laneMeta authority` is the sole
authority-of-record for who-performs, compiled through the collapse map:

| Lane authority | Compiles to |
|---|---|
| `sovereignty` | `owner: human` |
| `initiative` | `owner: agent` |
| `authority` | `owner: agent` |
| `external` | **no task** |

Guard test: `tests/test_designer_owner_derived.py` (T-197) — the node-level override is
retired from the authoring surface in `src/aef-workflow-designer.html` and shown read-only.
`tests/test_validate_iw9.py` fences the validator side. The bridge/export side is fenced by
`tests/test_designer_export_contract.py` (T-202), which refuses to hand AEF's
`fw bpmn promote` an owner-bearing node it cannot **identify** (no `aef:uid`) or **lane** (no
defined lane authority) — either would make owner-derivation or provenance stamping
impossible downstream.

**O-1 — task-type vs lane mismatch.** Task-type (`userTask` vs `service`/`scriptTask`)
**SHOULD** agree with the lane and is **presentational where it does not**. The
forward-compiler emits a validation **WARNING** and does **not** refuse the diagram. *Lane
wins, warn-not-refuse.* A runtime that refuses on this mismatch would diverge from us.

**O-3 — inception go/no-go must be human-laned.** A conformant inception's go/no-go boundary
**MUST** sit in a sovereignty lane, machine-checked at **compile time** (§7, v1.1). This is
the one place our surface has a compile-time MUST about authority rather than a warning.

### Defect D-1 — the frozen `workflowType` inference yields a value outside its own closed set

`workflowType`'s allowed-values column is the closed set
`build|test|refactor|decommission|specification|design|inception`. The **same row's**
absent-value column says the value is "inferred from BPMN type (service/script→build;
**user→human-facing**)".

`human-facing` **is not a member of that set.**

Consequence: a `userTask` carrying no explicit `workflowType` has **no conformant compiled
value**. Either the inference produces a non-member (non-conformant), or an implementation
silently substitutes a member (invention). This is not a hypothetical — a "human gate" is
exactly the node the dossier §2.5 pilot is built around, and it is a `userTask`.

- **How the T-590 fixture handles it:** it emits `horizon`, `tier` and `agentType` explicitly
  on all three task-like nodes, emits `workflowType="test"` explicitly on the `scriptTask`,
  and leaves `workflowType` **deliberately absent** on the two `userTask` gates, with the
  reason carried in each node's own `aef:meta note`. Absence is the only truthful encoding.
- **Why it is not fixed here:** changing Part I requires a version bump plus a
  conformance-test update (§Versioning). That is out of scope for a read-only research slice.
- **Routed as:** request **R3a** in `handoff-ewcr-v1-designer-fixture.yaml`. AEF decides
  whether the runtime contract adds a set member for a human decision gate, changes the
  inference, or declares the pair legal.

### Why every key is stated explicitly in the fixture

A fixture that leaned on `horizon → now` or on the `workflowType` inference would be
**supplying semantics the runtime contract has not agreed to** — precisely what IW-7 says the
Arc 1 gate must not require of us. So the fixture states every applicable frozen key outright
and relies on **no** default. The defaults are documented here so AEF can adopt or override
them knowingly; they are not smuggled into the exhibit.

---

## 4. Identity — the `aef:uid` model and its **measured** defects

### 4.1 What the standard promises (§5)

- Every node and edge **MUST** carry a stable `aef:uid`. It is the round-trip hinge: identity
  survives forward edits and reverse re-renders.
- **Reverse:** each rendered element **MUST** set `aef:uid = <task-id>` (or a deterministic
  hash for edges), so re-rendering the same record is byte-stable.
- **Forward:** a node whose `aef:uid` resolves to an existing task is a **modify** proposal;
  a node with **no** `aef:uid` is a **create** proposal.
- `aef:uid` is **externally assignable** — the reference editor's import path honours
  arbitrary values, so a reverse renderer needs no editor change for identity.

External assignability is the feature AEF needs *and* the collision surface. §5 constrains
**nothing about the value**.

### 4.2 The defects, as measured — not as folklore

Roadmap §2.1 Arc 0 asks the Designer to supply "stable IDs… and round-trip constraints" as if
settled. They are not (IW-4). But the honest statement is **stronger and more useful** than
the open-task list T-587 carried, because three of those tasks have since **closed by
measuring** the behaviour rather than by removing it. A closed measurement task leaves a
standing **contract fact**; that is what a runtime has to design around.

> **Correction to `reflection-designer.md` §3 and `questions-and-dispositions.md` IW-4.** Both
> list **T-501, T-518, T-520, T-523, T-564** as open identity defects. Verified against the
> filesystem on 2026-08-26: **T-518, T-520 and T-523 are `work-completed`**; only **T-501**
> and **T-564** remain in `.tasks/active/`. A second correction applies to T-520 — see M2.

| # | Contract fact (measured) | Instrument | Task state | What a runtime must do about it |
|---|---|---|---|---|
| **M1** | **There is no uid uniqueness requirement and none is enforced.** Two *authored* uids carrying the same value **both survive** a round-trip, on nodes **and** on edges. A derived uid colliding with an authored one *is* guarded; two authored duplicates are not | `tools/_t518-uid-collision.mjs` | T-518 `work-completed` | A record-keyed consumer that assumes uniqueness will **silently collapse two nodes into one, with no error anywhere**. Either the runtime enforces uniqueness on admission, or the interchange contract states that uid is not a key |
| **M2** | **Whitespace in a uid was a writer defect and is now fixed.** `&`, `<`, `>`, `"` and non-ASCII UTF-8 survive byte-identical. A raw newline or tab used to be emitted **raw** into the attribute, where XML attribute-value normalisation turns it into a space for any conforming parser — so AEF would read a different uid than we wrote, silently. The value **is** representable (`&#10;`); the writer simply did not write it that way | `tools/_t520-uid-xml-safety.mjs`, pinned `newline: identical, tab: identical`; verdicts come from expat via `tools/_t520-xml-read.py`, never from the producer's own DOMParser | T-520 `work-completed` (measurement); **remedy shipped in T-521** `work-completed` — `escAttr` at `src/aef-workflow-designer.html:9511` now emits `&#10;` / `&#13;` / `&#9;`, per the AEF ruling on rail 11909 | Nothing further on our side. **The residual constraint is genuinely the assigner's:** most C0 control characters are **illegal in XML 1.0 anywhere, escaped or not** — `not-representable-in-xml`. A uid assigner must not mint them |
| **M3** | **A uid survives containment; the containment does not.** A node authored inside `<bpmn:subProcess>` comes back with its uid **byte-identical**, and so does the `sequenceFlow` joining two such nodes — but the node is **HOISTED to `<bpmn:process>` level and the subProcess returns EMPTY**. Nothing is lost and the scope silently stops existing | `tools/_t523-subprocess-nesting.mjs`, pinned in `tools/_t523-nesting.pin.json` (`attribution: uid-survives-containment-does-not`) | T-523 `work-completed` | The record survives and **silently changes parent** — worse than losing it, because a loss is at least countable, which is why no count-based instrument here ever went red on it. A runtime that reads scope from containment will read the wrong scope |
| **M3a** | **The favourable arm, pinned deliberately.** A **childless** collapsed `subProcess` carrying only `extensionElements` comes back as a `subProcess` — **not** retyped to a task — and **no placeholder child is injected** (`children_after: 0`). AEF measured that `subProcess` appears in three published maps and three drafts and **every one is childless**, so this arm covers 100% of their real usage | same pin, `collapsed` block; added at AEF's request, rails 11926 / 11930; T-528 | T-523 / T-528 | Their collapsed-subProcess dialect (AEF commit `226fe8680`) is **safe across this seam today**. It is pinned because a future "cleanup" that retypes an empty scope element — or that injects a placeholder child — would break three published maps, and is a change someone could defensibly make without ever learning that |
| **M4** | **The one remaining uncovered gap is not ours: the AEF-side reverse renderer.** We can state exactly what is *in* a document and have **no way to know what AEF should produce from it** — "correct" there means the records they would have produced from a natively-authored workflow, which is a fact about **their** data model, not about the document | `tools/_t515-external-uid-conformance.mjs` `does_not_cover` names it as the sole remainder | **open by agreement, not by neglect** — proposed as a fixture-pair contract at rail 11911; their operator decides | This is request **R5b**: a fixture-pair contract, or an explicit statement that the reverse renderer is out of joint scope |

**Still open on our side** (both in `.tasks/active/`, neither blocking this slice):
**T-501** (map ID round-trip defect triage) and **T-564** (load-time ID normalisation).
A runtime contract should not assume load-time ID behaviour is settled until T-564 closes.

**Why measurement discipline matters here.** All three closed probes were written as
*characterisation, not verdict* — nobody has ratified what *should* happen, so each pins the
observed behaviour and goes **red on a change** rather than legislating a co-designed standard
from a test file. Two of them corrected a claim that had been sitting in the source unchecked:
`parseBpmnXml`'s T-337 comment asserted "the whole interior of an accepted element is dropped
today", which M3 falsifies for flow nodes. AEF should treat the pins, not the prose, as the
statement of behaviour.

---

## 5. Round-trip, import and export guarantees, with their guard tests named

What "lossless round trip" actually means here, and what fences it. The Designer owns this
column outright (dossier §5.1: "own editing UX, layout, lanes, visual notation, import/export,
and lossless round trips").

| Guarantee | Scope | Guard test |
|---|---|---|
| The `aef:` serialization seam is a **semantic fixed point** across every corpus fixture — `parseBpmnXml → buildBpmnXml` in the real editor runtime, headless chromium | every `tests/fixtures/aef-bpmn/*.bpmn` | `tests/test_roundtrip_serialization.py` → `tools/_roundtrip-serialization-cdp.mjs` (G-002, T-187). Toolchain absence is a **loud environment skip**, never a silent green |
| Standard ↔ implementation parity on the frozen governance meta-key list | §2's fenced block vs the editor and the bridge | `tests/test_mapping_standard_conformance.py` |
| Editor ↔ bridge meta parity — `metaKeys` ⊆ `META_KEYS` | scalar `aef:meta` channel | `tests/test_editor_bridge_meta_parity.py` (T-060) |
| Structured-element and field-coverage parity | `aef:` structured children | `tests/test_editor_bridge_structured_parity.py`, `tests/test_editor_bridge_field_coverage.py` |
| Export carries the write-out content contract AEF's `fw bpmn promote` consumes — no owner-bearing node without a `aef:uid` or a defined lane authority | export seam (manifest-as-seam, T-201 §3a) | `tests/test_designer_export_contract.py` (T-202) |
| `owner` node-level override is retired and read-only | authoring surface (`src/`) | `tests/test_designer_owner_derived.py` (T-197); validator side `tests/test_validate_iw9.py` |
| The delivered corpus diagrams are **byte-pinned** — AEF cross-validates them byte-exact behind its own sha-guard | `session-handover.bpmn` (T-214), `dispatch-loop.bpmn` (T-215) and the rest of the pinned set | `tests/test_corpus_fixture_pins.py` (T-216); `tools/_t365-normative-fixture-guard.py` |
| Typed-event definitions survive a layout-only open→save | `aef:eventDef` carriers | `tests/test_t259_eventdef_preservation.py`, `tests/test_typed_event_fixture_contract.py` (T-212) |
| Namespace and extension-element shape stay consistent | `aef:` document shape | `tests/test_editor_namespace_consistency.py`, `tests/test_editor_extension_shape_consistency.py` |
| Released bytes are immutable | `dist/` | `tests/test_release_immutability.py` |

**The consequence for Arc 0 that AEF should read carefully.** Round-trip identity is
**DELIVERED at fixture level** (V3, G-002, T-187/T-188) and **not** delivered at the
externally-assigned-value level a runtime needs — that is the whole content of §4.2 above. The
two claims are not in tension; they are measurements of different things, and Arc 0's "stable
IDs" line conflates them.

**One process note, stated because it is a joint hazard:** `tests/fixtures/aef-bpmn/` is a
**jointly-pinned normative corpus**. Adding a file there changes shared state as a side effect.
The T-590 fixture therefore lives in `docs/research/executable-workflow/fixtures/` instead,
and the corpus is untouched by this slice.

---

## 6. What this inventory does **not** contain (deliberate absences)

Listed so nobody reads an absence as an oversight:

1. **No guard or outcome expression language.** Dossier §6.1 requires it to be "constrained,
   typed, deterministic, and auditable"; §5.1 prohibits the Designer from validating itself as
   authoritative. Authoring one here would breach the boundary.
2. **No action catalogue, execution profile, capability profile, or secret binding.** All
   AEF-owned (§6.2.1, §6.4, §6.5). We reference opaque profiles at most.
3. **No ratification state.** §5.1 ratification contract: *a Designer save/export never
   ratifies or executes.*
4. **No runtime-contract proposal.** Whether the extension is a BPMN extension or a companion
   manifest is explicitly open (§6.1, §14.1) and is request **R1**.
5. **No blast-radius claim from the Component Fabric.** This project has 67 component cards —
   not the 0/0 the roadmap assumes — but the instrumentation carries six open defects
   (T-342, T-343, T-344, T-345, T-524, T-525). The correct statement is **"measured but not
   yet trustworthy"**, which dossier §7.5 / §8.2 says must route to policy, never be read as
   low impact.
6. **No disposition reversal.** T-279 / T-280 / T-281 / T-282 stand as DEFER, and AEF's
   T-2669 NO-GO stands. Whether the roadmap's Arcs 4–6 supersede them is human decision
   **H1** and is not answered here.

---

## 7. Open requests this inventory generates

These are the Designer-side asks. Each is carried in
`handoff-ewcr-v1-designer-fixture.yaml` with the same identifier. None is a decision.

| # | Request | Why it is AEF's to answer |
|---|---|---|
| R1 | Runtime-contract extension **form** — BPMN extension vs companion manifest, with a version identifier | §6.1 leaves it open pending T-027 discovery; it determines our export target |
| R2 | **Ratify Part II** — `tier`'s absent-value default and AC-seeding, open since 2026-07-11 on thread T-175 | It is a governance default; §3 above cannot state a value until they do |
| R3 | **Adopt or override our defaults/inference/derivation, rule by rule** — the §3 table | Resolves IW-7. Without it Arc 1's "render without inventing semantics" gate is unpassable |
| R3a | **Defect D-1** — `workflowType`'s `userTask` inference yields `human-facing`, outside its own closed set. Add a member, change the inference, or declare the pair legal | Changing Part I needs a version bump + conformance-test update; the semantics are theirs |
| R4 | **Diagnostic schema** — stable codes, affected element IDs, failed predicate, severity, lawful remediation | §5.1 shared contract 3. It is what makes T-309 buildable |
| R5 | **Read back the pilot fixture** — sha256 `b6a9afd7eb03abeaba43513f45176dd439838887b588901f5a2aa2a83da1685b` — and return accept / refuse / needs-decision on correlation `ewcr-v1-designer-fixture` | Arc 1's joint gate. Delivery is not acceptance (§5.1, dossier §5.1 sequence) |
| R5b | **Fixture-pair contract for the reverse renderer** (M4), or an explicit statement that it is out of joint scope | Only AEF can say what records a document *should* produce |
| R6 | Disposition of the **DeepSeek and Mistral** findings (IW-10) — the pinned dossier carries tables for Claude (§17) and Z.ai (§18) only | Arc 0's exit gate ("every blocker finding has a contract disposition") is not satisfiable from the packet alone |
| R7 | **Reconciliation with ratified SD-1** (AEF T-2663, IW-11) | Escalate rather than average — the AEF agent owns it |

---

## 8. Provenance

| Input | sha256 | Stored |
|---|---|---|
| Architecture dossier | `c9070637b09493a24abc99982ae966a3b3ae8cd4a358a44fdceb59bdceb6ac2d` | `architecture-c9070637.md` |
| Delivery roadmap | `5be23719b976e37a6461b4b1f6f309985b5ba033ef0b801769edd2627fbae5b8` | `roadmap-5be23719.md` |

Re-verify with `sha256sum -c docs/research/executable-workflow/source-manifest.sha256`, which
also pins this file, the fixture, `cannot-represent-yet.md` and the envelope (manifest
revision 1). If a source hash stops matching: **stop** — `VERSION MISMATCH`, require a new
manifest, do not route around it (`reflection-designer.md` §8 stop condition 1).

**Companion artifacts:** `cannot-represent-yet.md` (the gap list),
`fixtures/ewcr-pilot-human-gate-script-human-gate.bpmn` (the worked exhibit),
`handoff-ewcr-v1-designer-fixture.yaml` (the prepared envelope).
