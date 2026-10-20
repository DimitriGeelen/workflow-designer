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

**Leaning (agent, for the operator and AEF):** named types (D) with JSON Schema semantics, authored inline in a tiny
frozen `aef:attr` grammar for the common case (so the map stays one readable artifact, as the designer and greenfield
work today) with a guaranteed export to JSON Schema, and a `schemaRef` for anything the grammar cannot say. This takes
GLM's authoring model inside Codex's semantics and drift guards (versioned types, export/import/validate tests). A
third opinion (Antigravity) would settle the inline-vs-files split if the operator wants it.

## Dialogue Log

- 2026-10-20, operator: the request above; "If you do that, then also get external advice on this."
- 2026-10-20, agent: proposed a nested `aef:attr` sketch (option A) as a discussion starter, not a choice; filed this
  inception with recommendation DEFER until the advice, AEF's view and greenfield's maps are in.
- 2026-10-20, external panel: Codex and GLM-5.3 answered (above); they agree on catalogue references for
  source/target, recursion, read-only tree first, child-element preservation, and proposing to AEF first; they
  split on inline grammar vs JSON Schema files.
