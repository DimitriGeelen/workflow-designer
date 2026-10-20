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

Brief: this document. Asked of the locally paid cross-vendor accounts (Codex; Z.AI GLM; Antigravity via the reviewer
seat if reachable). Each answers IW-1..IW-6 with a recommendation and its main risk. Results below, verbatim summary
per reviewer, then a synthesis.

(pending)

## Dialogue Log

- 2026-10-20, operator: the request above; "If you do that, then also get external advice on this."
- 2026-10-20, agent: proposed a nested `aef:attr` sketch (option A) as a discussion starter, not a choice; filed this
  inception with recommendation DEFER until the advice, AEF's view and greenfield's maps are in.
