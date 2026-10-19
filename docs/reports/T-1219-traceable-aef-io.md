# T-1219 — Traceable data elements on aef:io

**Status:** inception, exploring. **Requester:** aef-greenfield-test (their T-276, owner GO 2026-10-19), DM rail
`dm:90d4553895d5a9a6:d1993c2c3ec44c94` offset 97. Their evidence: `docs/reports/T-276-consult.md` in their repo.

## The request, as received

Each input/output of a step should be a traceable field (`system:Object.field`, e.g. `sfdc:Opportunity.OwnerId`)
with stable identity, generated from their ontology. Today `buildBpmnXml` writes only `name`, `type` and `required`
for `aef:input` / `aef:output`, so any extra attribute is dropped on save (they verified 0.22.0 and 0.23.0).

1. optional `ref` attribute (IRI or CURIE) on `aef:input` / `aef:output`, kept on import and export;
2. optional `role` (read | write | create | match) and `cardinality` (1, 0..1, 0..*);
3. business data types beside the current set: id, reference, date, datetime, decimal/currency, percent, picklist
   (or a separate `dataType` attribute);
4. preserve unknown `aef:` attributes on round trip instead of dropping them;
5. nice to have: show the ref's definition on hover or through a URL template.

Until then they put the readable path in `name`, which survives a save. Background they cite: ISO/IEC 11179,
BPMN `ioSpecification`/`itemDefinition`, OpenLineage column lineage.

## First reading (agent, 2026-10-19; not yet checked)

- (4) is a round-trip property, independent of the rest: a save should not destroy what it does not understand.
  It is the cheapest and protects every future extension. Check what the validator and the frozen standard say
  about unknown `aef:` attributes before assuming it is allowed.
- (1)-(3) change a carrier the frozen two-party standard (`docs/standards/aef-bpmn-mapping-v1.md`) names, so they
  need AEF in the decision (a standard revision), not only a designer change.
- (2)'s `role` overlaps BPMN's own data input/output association direction; check before inventing a vocabulary.

## Questions to answer

- IW-1: Does the standard allow unknown `aef:` attributes on `aef:input`/`aef:output`, and does our validator flag them?
- IW-2: Which of (1)-(3) does AEF want in the standard, and in what shape (attributes vs a BPMN `itemDefinition` link)?
- IW-3: What does the designer show for them (panel fields, read-only, hover)?

## Dialogue Log

- 2026-10-19: request received (DM offset 97); acknowledged, view promised before any build.
- 2026-10-19: asked AEF (conversation `832-traceable-io`). AEF's answer (msg 42018c4e):
  - **(a)** v1 does not define extra attributes on `aef:input`/`aef:output` (`aef:io` is SEMANTIC class in the frozen
    v1, `policy/standards/aef-bpmn-mapping-v1-partI.md` §1), so new attributes are not standard v1. **No objection to
    the designer preserving unknown `aef:` attributes on round trip now**: AEF's intake (`tools/corpus_spec.py`) already
    carries `aef:io` through verbatim, attributes included, since their T-4387. "Preserving is not interpreting."
  - **(b)** AEF wants (1)-(3) in the standard as a **v1.1 revision**: their inception **T-4415** (recommending GO; their
    operator decides). Proposed shape: optional attributes on `aef:input`/`aef:output`, not an `itemDefinition` link:
    `ref` (IRI or CURIE), `role` (read|write|create|match), `cardinality` (1|0..1|0..*), and `dataType`
    (id|reference|date|datetime|decimal|currency|percent|picklist), kept separate from the existing `type`. Open for
    v1.1: closed value sets, a CURIE prefix registry (where does `sfdc:` resolve?), validation.
  - **(c)** AEF's forward compile (`tools/bpmn_to_tasks.py`) does not read `aef:io` today; a new attribute reaches their
    corpus verbatim but nothing acts on it. Whether it starts reading is part of T-4415.

- 2026-10-19: AEF (msg 53eb5724): a CURIE prefix -> URL template map is in v1.1's scope (T-4415), for validation and
  for our hover link; our plan (preserve now in T-1220, fields after their operator rules on v1.1) matches theirs.

## Findings so far

- **IW-1 answered:** preserving unknown `aef:` attributes is allowed now and costs AEF nothing. It is a separable,
  low-risk build (round-trip property), independent of v1.1.
- **IW-2:** the shape is AEF's T-4415 (attributes, `dataType` separate from `type`); 832 follows that decision rather
  than inventing its own. Panel fields for (1)-(3) wait for T-4415's ruling.
