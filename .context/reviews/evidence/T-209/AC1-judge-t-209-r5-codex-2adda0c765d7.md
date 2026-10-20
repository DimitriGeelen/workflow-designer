# Reviewer evidence — T-209 AC#1

- dispatch: `judge-t-209-r5-codex-2adda0c765d7`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `55f49763751618f860202f3a963a4cb8ea156ae7`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `849e0f59a07db87c30fea51e814c9fa82d10c72c5a15937bd6a6e25ef0c51ec3`
- result.md sha256: `b3cdb78368faacc5b583847e2604c4c30b18508110e87d985309ab29137ce1dd`

## The worker's verdict block

```
1. [AC] Offset-78 producer-contract coverage
VERDICT: green
WHY: Read T-209’s Context proposal table and Recommendation, inspected both test implementations, and ran both specified scripts independently with bytecode writes disabled. Both exited 0: promote fixture SHA prefix bbfbc5ec4835; joint fixture 2ba55eedbd90.

Proposal-row assessment:

- Manifest {name, owner, workflow_type}: asserted by exact expected-manifest comparisons in both suites.
- Lane-derived agent and human owners: asserted by the joint suite, including the exact owner set and invalid-authority mutation.
- UID totality / source_bpmn_sha inputs: asserted through UID checks, missing-UID mutations, and pinned fixture-byte SHA comparisons.
- Inception → DEFER-materialization input: workflow_type: inception asserted; moving inception outside sovereignty is rejected. DEFER materialization itself belongs to AEF.
- Promote CLI output: AEF output.
- aef_provenance block: AEF output.
- status: captured forcing: AEF output.
- Reconcile states: AEF output.
- Gate refusal: AEF output; local validator rejection does not establish AEF gate behavior.

No producer-input row in the supplied proposal table is missing. This verifies the fixture-based producer contract, not live compile→promote→create execution or AEF-side cross-validation. The prose’s “four” output rows is a counting error: the table lists five, all accounted for above.
GUIDANCE: No additional producer-contract test is required by these rows. Replying to AEF and deciding the proposal’s disposition remain with the operator.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Offset-78 producer-contract coverage
VERDICT: green
WHY: Read T-209’s Context proposal table and Recommendation, inspected both test implementations, and ran both specified scripts independently with bytecode writes disabled. Both exited 0: promote fixture SHA prefix `bbfbc5ec4835`; joint fixture `2ba55eedbd90`.

Proposal-row assessment:

- Manifest `{name, owner, workflow_type}`: asserted by exact expected-manifest comparisons in both suites.
- Lane-derived `agent` and `human` owners: asserted by the joint suite, including the exact owner set and invalid-authority mutation.
- UID totality / `source_bpmn_sha` inputs: asserted through UID checks, missing-UID mutations, and pinned fixture-byte SHA comparisons.
- Inception → DEFER-materialization input: `workflow_type: inception` asserted; moving inception outside sovereignty is rejected. DEFER materialization itself belongs to AEF.
- Promote CLI output: AEF output.
- `aef_provenance` block: AEF output.
- `status: captured` forcing: AEF output.
- Reconcile states: AEF output.
- Gate refusal: AEF output; local validator rejection does not establish AEF gate behavior.

No producer-input row in the supplied proposal table is missing. This verifies the fixture-based producer contract, not live compile→promote→create execution or AEF-side cross-validation. The prose’s “four” output rows is a counting error: the table lists five, all accounted for above.
GUIDANCE: No additional producer-contract test is required by these rows. Replying to AEF and deciding the proposal’s disposition remain with the operator.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
