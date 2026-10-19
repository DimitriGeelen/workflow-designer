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
