# Workflow Designer 0.27.0 — release notes

**Since:** `designer-v0.26.0`. The io panel now shows a producer's `ref` and `dataType`, and the authoring kit's review
findings carry map evidence that is checked mechanically. No change to what the designer stores.

## Changes

- **The io panel shows `ref` and `dataType`, read-only, like `role` (T-1304).** An `aef:input`/`aef:output` written in
  the v1 style that mapping v1.1 keeps (aef-greenfield-test's "style A", e.g. `ref="nid:attr-…" role="read"
  dataType="id"`) showed only name, type, required and role. `ref` and `dataType`, the producer's link to its ontology,
  were kept on save but never shown, not even under All details. Found by greenfield's own check of VZN-T1 on 0.25.0.
  - `ref` shows as `ref <value>`, hinted "v1 attribute". Under the mapping v1.1 read rule (AEF T-4415 §2.3: no
    `mappingVersion="1.1"`, no `fieldRef`/`typeRef`, prefix declared `kind="field"`) it shows once, as the derived
    `fieldRef … derived · from ref`.
  - `dataType` shows as `dataType <value>`, hinted "informational" (v1.1: informational only, kept verbatim).
  - Both are read-only. Editing io attributes comes with the next slice (832 T-1301).
  - Guard: `tools/_t1249-v11-io-cdp.mjs` legs f and g assert what is SHOWN for style A, with and without a field
    prefix. Leg c measured VZN-T1 by bytes only, which is why the gap passed 0.25.0.

## Authoring kit

- **Review findings carry map evidence, checked mechanically (T-1290).** REVIEW.md asks each finding for
  `map_evidence: {line, quote}` (or `null` for something absent from the map), and the new `kit/verify-findings.py`
  labels each finding verified / absence / unverified.
  - The production review loop sets unverified findings aside in `review.rN.unverified.json` before anyone acts on
    them.
  - Calibration prints each finding's label. Its PASS/FAIL is unchanged: an unverified finding on the clean map
    still fails it.
  - Origin: in 0.26.0's first calibration a reviewer cited a map line that did not contain what it claimed.

## What changes in stored maps

Nothing. No node id, field, attribute or finding id changes; a saved map's `aef:io` blocks are byte-identical to what
0.26.0 writes.

## For AEF

AEF serves 0.26.0. 0.27.0 needs no new endpoint. The four endpoints AEF does not serve are unchanged; see 832
`docs/reports/T-1300-designer-data-api-contract.md` (AEF inception T-4737).
