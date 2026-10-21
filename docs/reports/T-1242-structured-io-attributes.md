# T-1242 — Structured attributes on aef:io: the shape of each input and output

**Status:** inception, exploring. **Asked by:** the operator, 2026-10-20. **Decision owner:** the operator (GO/NO-GO);
the mapping standard itself is AEF's (their v1.1, AEF T-4415), so any GO here becomes a proposal to AEF.

## The question

Should a step's inputs and outputs (`aef:input` / `aef:output` in the designer's BPMN dialect) describe the SHAPE of
the data they carry (named attributes with their own types, nesting for objects and lists, allowed values) plus the
system the data comes from and the system it goes to; and if so, in what form?

## The request, as received (operator, 2026-10-20)

> "we see input and output and then we see types of a type, a string, a number, a boolean or an object ... maybe we
> should make it more specific, that the input has a name, it has a type, but it also has attributes. So we really
> also store the attributes ... it would be really nice if you can show the individual attributes for an object or for
> a string ... That ... also makes it easier to derive pseudocode from it but we can then also describe the source of
> the system where it comes from and the target system it goes to ... an object can have multiple values and multiple
> attributes." Then: "If you do that, then also get external advice on this."

## What exists today

- `aef:input` carries `name`, `type`, `required`; `aef:output` carries `name`, `type` (designer `IO_NAMED_ATTRS`).
- Types are flat words: `string`, `number`, `boolean`, `list`, `object`, `ref`, `task_id` ... A `list` or `object`
  says nothing about what is inside. Sample from the test corpus: `<aef:input name="deliverables" type="list"
  required="true"/>`, `<aef:output name="result_ref" type="ref"/>`.
- Designer 0.24.0 keeps any unknown `aef:` attribute on an `aef:io` element through a save (832 T-1220), so an author or
  producer can already add attributes without losing them; the designer just does not show or edit them.
- T-1219 (GO 2026-10-20), raised by aef-greenfield-test (their T-276): optional `ref` (IRI/CURIE), `role`,
  `cardinality`, and a business `dataType` separate from `type`. Those attributes wait on AEF's mapping v1.1 ruling
  (AEF T-4415); the designer fields for them are 832 T-1229. T-1219's open question IW-2 already named the fork:
  "attributes vs a BPMN `itemDefinition` link".
- The authoring kit and AEF's corpus intake (`corpus_spec`) read `aef:io` today; anything new must survive AEF's
  intake (no silent drop: AEF T-4502 now refuses rather than drops).

## Options

| | Shape | For | Against |
|---|---|---|---|
| A | **Nested `aef:attr` children** inside `aef:input`/`aef:output` (name, type, required, values, ref; recursive for object/list; `source`/`target` on the io) | readable in the XML; travels with the map; easy for the designer to show as a small tree; pseudocode can name fields | a private schema language inside BPMN; grows into reinventing JSON Schema; every reader (AEF intake, kit, designer) must learn it |
| B | **BPMN 2.0 native**: `bpmn:itemDefinition` with `structureRef` pointing at a schema (JSON Schema / XSD) kept beside the map; `aef:io` references the itemDefinition | standard BPMN, other tools understand it; the shape lives in a real schema language with validators | the schema is a second artifact to keep in sync; the designer needs a schema reader; BPMN `dataInput`/`ioSpecification` is heavyweight |
| C | **Inline JSON Schema** in an `aef:schema` child (CDATA) | one artifact, a real schema language | JSON in XML is awkward to diff and edit; still needs a schema reader |
| D | **Named types**: a project-level type catalogue (`aef:type name="Order"` with attributes, once), and `aef:io type="Order"` | no repetition across steps; a catalogue is reviewable on its own; maps stay small | one more file/section; needs a home (the map? the project?) and versioning |

Source/target system is a separate, smaller question: two attributes on the io (`source`, `target`), possibly a
reference into a system catalogue rather than free text.

## Questions (for the external advice and for AEF)

- **IW-1:** A, B, C or D (or a mix, e.g. D with B underneath)? Which is least likely to be regretted in two years?
- **IW-2:** How deep: attributes one level, or recursive? Allowed values (enums), formats, ranges: in or out of scope?
- **IW-3:** Source and target system: free text, or a reference into a catalogue? On the io, or on the step?
- **IW-4:** How does this relate to T-1219's `ref` / `dataType` (business types): is `ref` the bridge to an external
  schema, making B or D the natural home?
- **IW-5:** What must the designer show (a tree under each io? hover? read-only first?) and what must AEF's intake
  carry, so nothing is silently dropped on either side?
- **IW-6:** Pseudocode: what minimum shape lets a step's pseudocode name real fields?

## External advice

Brief: this document. Asked of the locally paid cross-vendor accounts, each isolated (an empty directory holding only
this brief; Codex read-only), 2026-10-20: **Codex** (`codex exec`, it also checked the OMG BPMN and JSON Schema
specs) and **Z.AI GLM-5.3** (`opencode run`). Antigravity was not asked yet (see Synthesis). Raw answers kept in the
session scratchpad; summaries below.

### Codex

- **IW-1:** D, a catalogue of versioned **JSON Schemas**; C as an alternative packaging of the same schemas; B only when
  a concrete BPMN integration needs it. **Reject A**: a private recursive schema language is lasting work for no
  benefit.
- **IW-2:** nested objects and arrays from the start, required properties, enums, ranges, string constraints; missing
  vs `null`. Preserve full schemas, edit a documented subset; decide whether `format` is enforced.
- **IW-3:** system-catalogue references on each io, optional step default; source = supplying system, target =
  consuming system, kept separate from endpoints and credentials.
- **IW-4:** keep business meaning (`dataType`) and representation (a new `schemaRef`) separate; do not repurpose
  T-1219's `ref` unless AEF defines it as a schema reference.
- **IW-5:** read-only expandable tree first (names, types, required, constraints, schema version, loud unresolved-ref
  errors); designer and intake preserve complete schemas, references and **extension children**, or refuse.
- **IW-6:** stable input names, nested property names, array item types, optional/null, so `order.lines[i].sku` is
  defensible; real transformations also need explicit input-to-output mappings.
- **Example:** `<aef:input name="order" type="object" required="true" schemaRef="schemas/order-v1.schema.json"
  source="sys:crm" target="sys:fulfilment"/>`. **Biggest risk:** schema-reference drift (a map validates differently
  later or breaks when moved); contain with immutable schema versions, a dependency manifest, offline resolution,
  export/import/validate package tests.
- **Brief overstates B:** `structureRef` is a QName, not a JSON Schema URL; a JSON Schema binding needs a convention.
  The four options mix four separate decisions (schema language, storage, reuse, BPMN linkage). Strings have
  constraints, not subfields. Source/target labels do not replace BPMN data associations.

### GLM-5.3

- **IW-1:** a mix: **A as the foundation**, D factored on top (`type="Order"` defined once in the same grammar), B as
  the door out (T-1219's `ref` to an external JSON Schema for heavy cases). Pure B is "the option everyone praises and
  no designer wants to edit".
- **IW-2:** recursive, small vocabulary; enums in, formats and ranges out (push them to `ref`); JSON-Schema primitive
  names so export stays mechanical.
- **IW-3:** a system-catalogue reference, on the io (inputs care about source, outputs about target), optional step
  default; free text "rots into forty spellings of Salesforce".
- **IW-4:** `ref` is the bridge outward; `dataType` becomes D's handle; `type` stays structural.
- **IW-5:** read-only collapsed tree first; extend T-1220's preservation from unknown attributes to unknown **child
  elements**; AEF's intake carries the tree verbatim, with a grammar version.
- **IW-6:** name, type, required, recursion, enum values: enough for `order.customer.email` and `status in {paid,
  shipped}`; source/target give the "from X / to Y" line.
- **Example:** nested `aef:attr` children under `<aef:input name="order" type="Order" ... source="sys:crm">`.
  **Biggest risk:** reinventing JSON Schema badly, and the designer shipping a private grammar ahead of AEF's v1.1.
  Contain: freeze the vocabulary at about six attributes (name, type, required, values, description, ref), version it,
  provide a mechanical attr-to-JSON-Schema export, propose to AEF T-4415 before any UI.
- **Brief misses:** B's interop is mostly theoretical (Camunda 8 replaced ioSpecification with flat zeebe:input/output;
  bpmn.io and Flowable largely ignore it); prior art OpenAPI `components/schemas` + `$ref` is D done well; versioning
  of named types; reuse T-1219's `cardinality` for lists; sample values/defaults help pseudocode and tests.

### aef-greenfield-test (the first producer, msg e6caaa76, 2026-10-20)

- **Today:** each `aef:input`/`aef:output` is ONE field, `name` = a system path (`sf:Opportunity.Id`,
  `tacton:Account.companyName`), `ref` = an ontology IRI, plus `role` and `dataType` (T-1219). The structure (type,
  mandatory, index, picklist values, owning object) already lives in their ontology (~1,300 `ntl:DataAttribute`s,
  real Salesforce and Tacton metadata), and `ntl:AttributeMapping` (with a transformation type) links source and
  target fields.
- **Shapes they need:** objects (Salesforce Opportunity/Account/Contact/Quote; Tacton Account/Opportunity/Solution);
  lists (Solution line items incl. TradeIn, QuoteLineItems, OpportunityContactRoles). Today flattened to field paths;
  a list-of-object io would help for line items.
- **Preference: REFERENCED, not inline.** The io points at a named type by IRI/QName (`schemaRef`-like); source/target
  as system references (they have system ids); ontology to JSON Schema export is easy for them. An inline frozen
  grammar is acceptable as a fallback for producers without a catalogue, but they would not author it.
- **Agrees** with agreed points 1-6; asks the designer to keep unknown CHILD elements of `aef:io` through a save (not
  only attributes). For v1.1: an optional `typeRef`/`schemaRef` + `sourceSystem`/`targetSystem`; flat `name`/`type`
  must stay valid (their maps VZN-T1 v26, WT-01).

### AEF, as the corpus_spec reader (msg b1d5beca, 2026-10-20)

Routed to AEF T-4415 (mapping v1.1 inception) as its IW-1; nothing decided until AEF's operator rules. AEF's view:
(a) the common case INLINE, in the small frozen grammar with named, versioned types and JSON Schema semantics (a map
stays self-contained and diffable); (b) `schemaRef` accepted for anything richer, carried verbatim as an opaque
reference; (c) readers preserve child elements or refuse naming them, never drop. Placement: v1.1 beside
ref/role/cardinality/dataType if additive (old maps valid, no field changes meaning), else v1.2. Takes the six
reviewer-agreed points as given.

**Tension settled (AEF msg 9fb1413f, T-4415 IW-1 addendum 752932d2a):** after greenfield's answer AEF no longer asks
for inline as primary: "the producer is the authority on what it will write", so **referenced named types lead and
inline is the fallback**. Both forms have equal standing in the standard (inline grammar with named types;
typeRef/schemaRef carried verbatim), and the designer leads on references. Which form the authoring kit leads with
goes to AEF's operator in T-4415. Child elements of `aef:io` in AEF's intake: AEF T-4518 (msg bc02bcbb) checked:
`corpus_spec` already kept unknown `aef:io` children verbatim, but silently dropped extension content in five other
places (children, text and repeats of structured aef elements; extra plain attributes; unknown elements at process and
lane level). Now fixed: unknown elements at node, flow, process and lane level round-trip verbatim at any depth, extra
attributes round-trip, and where verbatim is impossible `derive` refuses, naming the element and node. Lands with
AEF's next push.

### Synthesis (agent)

**Agreed by both:** source and target as **references into a system catalogue**, on each io with an optional step
default, never free text; **recursion** is needed from the start (a `list` must say "list of what"); a **read-only
tree first**, editing later; the designer and AEF's intake must preserve **child elements**, not only unknown
attributes (T-1220 covers attributes only), or refuse; **B's interoperability is overstated** (QName, not a URL;
mainstream engines ignore ioSpecification); business meaning (`dataType`) and structure stay separate; versioning of
named types matters; **propose to AEF (T-4415) before building any UI**.

**Disagreed:** the core form. Codex: real JSON Schema files referenced from the io (D over JSON Schema), no private
grammar. GLM: a small inline grammar (A, frozen at about six attributes) with named types (D) and a mechanical export
to JSON Schema, `ref` for anything richer. The common ground is **D (named, versioned types)** with JSON Schema as
the semantics; the open choice is whether the shape is authored INLINE in a small grammar that compiles to JSON
Schema, or authored AS JSON Schema in files beside the map.

**Leaning (agent, revised after greenfield's input):** **referenced named types** as the primary form: an optional
`typeRef`/`schemaRef` on the io pointing at a named, versioned type (a catalogue entry: greenfield's ontology IRI, or
a JSON Schema), plus `sourceSystem`/`targetSystem` as system references, with flat `name`/`type` still valid. This is
Codex's recommendation, and it is what the first real producer already has and wants. GLM's small inline grammar
stays only as an optional fallback for producers without a catalogue (greenfield would not author it), so it is not
needed for v1.1. Independent of the ruling, the designer must keep unknown `aef:io` CHILD elements through a save
(both reviewers and greenfield ask for it; filed as its own build task, the same "preserving is not interpreting"
reasoning AEF gave for T-1220).

*(First leaning, before greenfield answered: inline tiny grammar with JSON Schema export. Superseded above.)*

## Dialogue Log

- 2026-10-20, operator: the request above; "If you do that, then also get external advice on this."
- 2026-10-20, agent: proposed a nested `aef:attr` sketch (option A) as a discussion starter, not a choice; filed this
  inception with recommendation DEFER until the advice, AEF's view and greenfield's maps are in.
- 2026-10-20, external panel: Codex and GLM-5.3 answered (above); they agree on catalogue references for
  source/target, recursion, read-only tree first, child-element preservation, and proposing to AEF first; they
  split on inline grammar vs JSON Schema files.
- 2026-10-21, operator: prioritise; then chose to WAIT for AEF T-4415's ruling rather than build ahead (option 1).
- 2026-10-21, AEF: T-4415 draft 1 received over TermLink (sha256 7be4c44f…, verified); 832's designer-side check below.
- 2026-10-21, AEF: draft 2 (AEF a9f9d677b, sha256 f13ab1ff…, confirmed by AEF) takes in 832 points 1-8 and greenfield
  a-i; the v1 type vocabulary is adopted as the designer's nine values, open, int/bool as aliases, enum kept. `role`
  gains `delete` (needs a match key). 832 sent three small points (ref-as-field read rule needs a string-level test;
  present='false' vs the absent keyword; dataType id/reference mapping) and relayed AEF's write/delete question to
  greenfield. Open for AEF's ruling: ref as data-flow join key, typeRef version pinning, greenfield's full maps.

## Check of AEF T-4415 draft 1, designer side (2026-10-21)

Checked against the designer (`src/aef-workflow-designer.html`) and the maps tracked in this repo. greenfield's own
maps were requested (VZN-T1 v26, WT-01) for the producer-side check; not in yet.

1. **BLOCKING for additivity: section A's v1 `type` list is not v1.** Draft A lists `string | number | boolean | date |
   object | list` as "v1 flat type, unchanged". The designer offers `string, number, boolean, ref, path, task_id,
   arc_id, list, object` (`IO_TYPES`), and 54 tracked maps here use `ref`, `task_id` or `path` (io counts: string 167,
   task_id 97, ref 38, list 24, enum 16, path 7, boolean 5, number 2, int 2, bool 1). As written, v1.1 would make those
   maps non-conforming, so A is not additive (their review question 4). `date` is new (fine, additive) but not v1.
   Proposal: A keeps the v1 set as it is in the corpus, and states how `enum`/`int`/`bool` (seen, not in IO_TYPES) are
   read.
2. **Two ways to name a single field.** greenfield's T-1219 request puts the field in `ref`
   (`ref="sfdc:Opportunity.OwnerId"`); B puts it in `typeRef="sf:Opportunity"` + `<aef:field path="OwnerId"/>`. The
   standard should say which is canonical, or how a reader treats a `ref` that names a field.
3. **`ref` vs `type="ref"`.** A new attribute `ref` beside the existing type value `ref` will confuse authors and the
   designer UI. Worth a different name (e.g. `objectRef`), or a sentence that they are unrelated.
4. **`role` is circular.** "as T-1229 defines": 832 T-1229 is a captured follow-up that waits on this ruling, so it
   defines nothing. The values need to be in the standard (greenfield asked for `read | write | create | match`).
5. **`cardinality` vocabulary and overlap.** Draft: `one | optional | many`; greenfield asked `1 | 0..1 | 0..*`.
   Also `required="false"` and `cardinality="optional"` say the same thing: one of them should win, or the
   combination should be defined.
6. **`oneOf` values comma-separated** breaks on values containing a comma; repeated `<aef:value>` children (or a
   stated escape) avoid it.
7. **Underspecified in C:** the comparison for `range` (number, date, string?) follows from which type; the regex
   dialect for `pattern` (ECMAScript or XSD) is not named; how `path` steps through a `list` (`Lines.Amount` =
   every line?) is not defined, for B as well.
8. **Prefixes.** `sys:`, `sf:` and the other CURIE prefixes need the prefix map AEF put in v1.1 scope earlier
   (T-1219, AEF msg on 6a2b98dd); the draft text does not show where it lives.
9. **Producer check (greenfield's io fragments, VZN-T1 v27, msg f3760c56; full maps await their operator).** Two styles
   in use today:
   - **Style A, single field** (their target, 20 io on hand-over 2):
     `<aef:input name="sfdc:Opportunity.Id" type="object" ref="nid:attr-salesforce-opportunity-id" role="read" dataType="id"/>`.
   - **Style B, legacy object with a free-text field list:**
     `<aef:output name="Account [Name, Phone, …, OwnerId]" type="object"/>`.

   What it means for draft 2:
   - a. **greenfield's `ref` is a FIELD IRI.** Their `ref` (`nid:attr-…`) names the attribute itself, which is what
     the reviewers call `fieldRef`. Draft 2 must say how an existing `ref` holding a field IRI is read, or style A maps
     stop meaning what they mean.
   - b. **greenfield's `dataType` is a technical token, not a concept IRI.** It holds `id` and `reference`, not a
     business-concept IRI. Renaming to `conceptRef` (reviewers) is right, but `dataType="id"` in existing maps needs a
     stated reading. It sits closer to a value kind than to business meaning.
   - c. **`type="object"` on a single field is a forced placeholder.** greenfield would drop it. `type` must become
     optional when `fieldRef`/`typeRef` is present.
   - d. **`role` is confirmed: read | write | create | match.** `match` also appears on an output
     (`tacton:Opportunity.currency`), so its meaning (a lookup or join key) needs a definition.
   - e. **Systems come from the path prefix today** (`sfdc:`, `tacton:`). Draft 2 can let `sourceSystem`/`targetSystem`
     be derived from a declared prefix to system mapping in the prefix map, with the explicit attribute overriding.
     The prefixes must be declared either way (the draft's examples use `sf:`; greenfield writes `sfdc:`).
   - f. **Style B maps directly onto B** (`typeRef="sfdc:Account"` plus `<aef:field path="Name"/>` children). The
     legacy free-text form must stay valid v1.
   - g. **Lists are a must, not an edge case:** Solution line items including TradeIn lines, OpportunityContactRole,
     QuoteLineItem. Draft 2 needs a list-path syntax and a way to select one KIND of line (TradeIn lines are a subset).
   - h. **Their only expectations today are behavioural**, e.g. "one-to-one: update if exists else create"
     (H-039/H-042). That is upsert semantics, which `role` (match + create) or a `ruleRef` carries. The value checks
     in C do not cover it, and draft 2 should say where it goes.
   - i. **Field-to-field transformations stay out of the map**, in their ontology (AttributeMapping). That is
     consistent with the draft.
10. **Designer cost (for the ruling, not an objection):** A and the step default are fields in the existing io editor;
   B, C and D are child lists per io, which the designer now keeps verbatim (T-1243) and would show read-only first;
   E reuses the tree. Nothing in A-E conflicts with what the designer stores.
