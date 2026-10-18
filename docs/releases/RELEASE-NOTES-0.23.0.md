# Workflow Designer 0.23.0 — release notes

**Since:** `designer-v0.22.0` (2026-10-17) · **Minor: the authoring kit stops calling our house rules universal.**
Includes everything in 0.22.0. The designer itself is unchanged apart from its version number.

## Authoring kit

- **A fourth rule class, CONVENTIONAL (T-1200, from T-1165).** The kit's `CONFORMANCE.md` labels every validator
  rule. UNIVERSAL promises "any conformant document satisfies it". The standard (mapping-v1 §6) says nothing about
  graph shape, so rules about connectivity, start and end events, reachable steps, dead ends and parallel-gateway
  balance were promising something the standard does not. They are now CONVENTIONAL: *the standard is silent on this
  shape and our house style expects it. Restructure, or ignore it if the shape is deliberate.*
- **A basis column.** Every rule now says what its class rests on: the standard's own text (only MUST, SHALL or
  REQUIRED counts), a well-formedness ground (XML id and reference rules, the BPMN schema), the field the rule
  reads, or none.
- **The legend says what each class asks of you.** DIALECT-RELATIVE: an optional field the standard does not require
  is missing (add it, or ignore it as your dialect). CONVENTIONAL: as above.
- Calibrated on its own bytes with codex and GLM-5.3 (`docs/authoring-kit/calibration-records/0.23.0.yaml`).

### Class changes, UNIVERSAL → CONVENTIONAL

Severity and messages are unchanged; nothing stored in a map changes, so there is nothing to migrate.

- **BPMN form (listed in the kit):** `W-XML-DISCONNECTED`, `W-XML-NO-START-EVENT`, `W-XML-NO-END-EVENT`,
  `W-XML-UNREACHABLE`, `W-XML-DEADEND`, `W-XML-PGW-NOOP`, `W-XML-PGW-UNBALANCED`, `E-XML-GW-OUTGOING`.
- **YAML form:** `W-NO-START-EVENT`, `W-NO-END-EVENT`, `W-UNREACHABLE`, `W-DEADEND`, `W-PGW-NOOP`,
  `W-PGW-UNBALANCED`, `E-GW-OUTGOING`.
- **`E-XML-GW-OUTGOING` / `E-GW-OUTGOING` are ERRORs that rest on no basis:** an exclusive gateway with fewer than two
  outgoing flows (and not a merge) is refused, though neither BPMN nor mapping-v1 requires two. Their severity is
  unchanged in this release; whether they should stay errors is an open question. AEF's compiler does not require
  it either.

## Standard

- **mapping-v1 Part II gained a non-normative note:** the standard places no requirement on graph shape; a document
  with any of these shapes can be v1-conformant, and validators may report them as conventions of their own. AEF
  accepted the wording as written; it moves into Part I at the next frozen v1.x.

## Re-test

1. Open the kit's `CONFORMANCE.md`: the legend names CONVENTIONAL, the table has a `basis` column, and
   `W-XML-DISCONNECTED` reads `CONVENTIONAL | none: the standard is silent on this property (house convention)`.
2. `E-XML-ID-DUP` reads `UNIVERSAL | xml-id: …`; `W-XML-GW-AMBIGUOUS` reads `DIALECT-RELATIVE | carrier: …`.
3. Validate any map: the findings are the same as with 0.22.0.
