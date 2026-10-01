# Workflow Designer 0.15.0 — release notes

**Since:** `designer-v0.14.0` (2026-09-30) · **Theme:** a vendor's agent can now produce, check
and improve governed maps without being told how by us.

The release ships two artefacts: the designer (`aef-workflow-designer-0.15.0.html`, one file, as
before) and, for the first time, the **authoring kit** beside it (`aef-authoring-kit-0.15.0/`).

## Why this release

A vendor project deployed 0.13.0, generated 26 maps from an ontology with a script, and saved
them 130 times. Not one map carried governance (no map identity, no lane authority), and nothing
told them. Their maps were also our test: 94 of the 110 findings on them were OUR defect.

## The authoring kit (new)

`aef-authoring-kit-0.15.0/`, immutable like the designer, checksummed in `SHA256SUMS`, recorded
in `MANIFEST.yaml` (`kit`, `kit_sha256`):

- `validate-workflow.py`: the validator, standard library only.
- `AUTHORING.md`: the guide for a generating agent. What a lane is (performer -> authority
  table); derive, never invent; the honest end state (which warnings an honest map KEEPS); source
  citations on every element; what the validator does NOT check. Rewritten from two external
  agent trials and a fresh re-run (T-975).
- `CONFORMANCE.md`: every rule, its severity and its class, GENERATED from the validator.
- `exemplar.bpmn`: a complete governed map.
- **The review loop** (T-982, T-983): `GENERATE.md`, `REVIEW.md`, `CORRECT.md`, `RUBRIC.md` and
  `loop.sh`. An agent generates with source citations, the validator is the floor, a second agent
  (ideally another vendor) reviews against the SOURCE, the generator corrects or contests, and
  every correction names its lesson. Provider-agnostic: the two agents are configuration.
- **Calibration** (`calibration/`, `loop.sh --calibrate`): proves a reviewer still catches three
  planted defects and raises nothing on a clean map. Measured with GLM-5.2: 3/3, 0 false.

## Designer

- **Findings on the map** (T-961, T-962, T-964): the designer reaches the validator, marks each
  node a finding names, and docks a findings drawer. "Could not check" is shown distinctly from
  "found nothing".

## Validator

- **Plain BPMN `<task>` is accepted** (T-970). It was refused as unknown: 86% of all findings on
  the first corpus we did not author were this defect of ours. It now takes part in ownership
  checks (T-972) and lane capacity (T-975).
- **Two completeness rules** (T-972): `W-XML-NO-WORKFLOWMETA` (a map with no identity or kind;
  house convention, labelled DIALECT-RELATIVE) and `W-XML-LANE-NO-AUTHORITY` (a lane with no
  stated authority is no longer quieter than one declaring `none`).
- **`W-XML-DISCONNECTED`** (T-967): one pool drawn as several separate flows.
- **A converging exclusive gateway (the BPMN merge) is no longer an error** (T-977), both forms.
- **Messages state the fact and both readings** (T-978): no more "independent processes",
  "control never terminates" or "a compiler must invent one" on an honestly partial map.

## Save API (reference server)

- **`/api/save` returns the validator's verdict** under `validation` (T-973): advisory, never
  blocking; an unloadable validator says so and never reads as a clean map. Existing fields are
  unchanged. AEF's own blueprint does not have this yet (proposal:
  `docs/reports/T-973-aef-save-findings-pickup.md`).

## Known gaps, stated

- The designer lays out an unpositioned map in DOCUMENT order, not flow order (T-976).
- `kind` is a declaration nothing acts on yet; overview maps are still judged as processes.
- Human edits are not yet turned into learnings (T-985); the learning ledger is T-984.
- The peer-consult sidecar does not work in vendored installs (T-980; the fix is upstream).
