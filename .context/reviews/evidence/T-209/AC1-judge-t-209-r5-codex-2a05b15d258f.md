# Reviewer evidence — T-209 AC#1

- dispatch: `judge-t-209-r5-codex-2a05b15d258f`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `3f5450c7d4c07210449957dd72dc5d66cc5d15c0`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `4f5e0fbfa630d9abe1e0d79c8ef6eefa4026f568656335f75024d34328cefa31`
- result.md sha256: `ac666d8415b640ba0cc15bd391f55d3c25020051e5dbe7d476199f0d9cefac87`

## The worker's verdict block

```
1. [AC] Offset-78 producer-contract coverage
VERDICT: green
WHY: Read T-209’s Context proposal table and Recommendation, inspected both test implementations, and ran both with PYTHONDONTWRITEBYTECODE=1 to preserve the export. Both exited 0: promote contract SHA prefix bbfbc5ec4835; joint contract SHA prefix 2ba55eedbd90.

Row-by-row findings:

| Proposal row | Classification and evidence |
|---|---|
| Manifest {name, owner, workflow_type} | Asserted: extract_manifest and check (3) compare exact expected tuples. |
| Lane-derived agent + human owners | Asserted: joint check (3) verifies both tuples and the exact owner set; initiative-authority mutation must break extraction. |
| UID totality / source_bpmn_sha keys | Asserted: check (2) verifies nonempty UIDs; check (4) verifies pinned fixture hashes and repeat-read equality; UID-removal mutations are detected. |
| Inception → DEFER-materialization input | Asserted: exact workflow_type: inception tuple; check (5a) rejects inception outside sovereignty. Actual DEFER materialization remains an AEF output. |
| Promote CLI output | AEF output; outside 832’s producer assertions under T-559. |
| aef_provenance block | AEF output; outside 832’s producer assertions. |
| status: captured forcing | AEF output; outside 832’s producer assertions. |
| Reconcile states | AEF output; producer keys are covered above. |
| Gate refusal | AEF output; local validator mutation checks do not claim AEF gate execution. |

No missing producer-input row found. Exporter inspection also found no aef_provenance, <aef:provenance, or status="captured" emission. This verifies the specified fixture-based producer contract, not AEF execution or cross-validation. The reply and disposition remain with the operator.
GUIDANCE: None required for this evidence criterion.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Offset-78 producer-contract coverage
VERDICT: green
WHY: Read T-209’s Context proposal table and Recommendation, inspected both test implementations, and ran both with `PYTHONDONTWRITEBYTECODE=1` to preserve the export. Both exited 0: promote contract SHA prefix `bbfbc5ec4835`; joint contract SHA prefix `2ba55eedbd90`.

Row-by-row findings:

| Proposal row | Classification and evidence |
|---|---|
| Manifest `{name, owner, workflow_type}` | Asserted: `extract_manifest` and check (3) compare exact expected tuples. |
| Lane-derived `agent` + `human` owners | Asserted: joint check (3) verifies both tuples and the exact owner set; initiative-authority mutation must break extraction. |
| UID totality / `source_bpmn_sha` keys | Asserted: check (2) verifies nonempty UIDs; check (4) verifies pinned fixture hashes and repeat-read equality; UID-removal mutations are detected. |
| Inception → DEFER-materialization input | Asserted: exact `workflow_type: inception` tuple; check (5a) rejects inception outside sovereignty. Actual DEFER materialization remains an AEF output. |
| Promote CLI output | AEF output; outside 832’s producer assertions under T-559. |
| `aef_provenance` block | AEF output; outside 832’s producer assertions. |
| `status: captured` forcing | AEF output; outside 832’s producer assertions. |
| Reconcile states | AEF output; producer keys are covered above. |
| Gate refusal | AEF output; local validator mutation checks do not claim AEF gate execution. |

No missing producer-input row found. Exporter inspection also found no `aef_provenance`, `<aef:provenance`, or `status="captured"` emission. This verifies the specified fixture-based producer contract, not AEF execution or cross-validation. The reply and disposition remain with the operator.
GUIDANCE: None required for this evidence criterion.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
