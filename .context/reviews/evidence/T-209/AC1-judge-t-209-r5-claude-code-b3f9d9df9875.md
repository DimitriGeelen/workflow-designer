# T-209 Human AC#1 — independent review (rung-5-panel:claude-code)

Revision reviewed: 14a6ca61aaea1475a309103cf818cda66fae7434 (HEAD at review time; the two test files,
the fixtures in tests/fixtures/aef-bpmn/, tools/validate-workflow.py and src/aef-workflow-designer.html
are all unmodified relative to HEAD, per `git diff --stat HEAD`, which returned empty).
I did not read the earlier reviewers' evidence files in this directory; this judgment is my own.

## Source of the proposal rows
The original AEF rail message (offset 78) is not stored locally: grep found only handover mentions of
the task title. Following step 1, I judged against the rows quoted under `## Context` in the task. Those
rows match the item list in the task's `description:` frontmatter (manifest shape, promote CLI output,
owner agent+human + captured forcing, aef_provenance block, reconcile states, gate refusal,
inception-node DEFER-materialization leg). Every item is mapped to a row.

## Step 2: suites run
    $ python3 tests/test_promote_contract.py        -> rc=0
    OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)
      manifest owner-bearing uids: n_inception {owner:human←sovereignty, workflow_type:inception}; uid totality + byte-determinism + teeth verified
    $ python3 tests/test_two_lane_joint_contract.py -> rc=0
    OK: two-lane joint promote contract — two-lane-joint.bpmn (sha 2ba55eedbd90)
      owner-bearing uids: n_inception {owner:human←sovereignty, wf:inception}; n_plan {owner:agent←initiative, wf:build}; uid totality + byte-determinism + teeth verified
Fixture sha256 values computed independently with sha256sum match both PINNED_SHA constants exactly.

## Step 3: classification of each row (read from the test source, not from the printed output)
| Row | Classification | Where asserted |
|---|---|---|
| manifest shape {name, owner, workflow_type} | ASSERTED | `extract_manifest` builds the exact tuple; check (3) requires `manifest == expected` (dict equality) in both suites |
| owner human (sovereignty lane) | ASSERTED | AUTHORITY_OWNER mapping + check (3) in both; check (0) guards the mirror against validate-workflow.py; node-level owner override raises (IW-9) |
| owner agent (initiative lane) | ASSERTED | joint check (3): EXPECTED_MANIFEST n_plan owner agent, and the owners set must equal {human, agent}; teeth (5b) |
| uid totality (reconcile key 1) | ASSERTED | `uid_missing` check (2) in both; teeth (5b) promote and (5c) joint |
| source_bpmn_sha (reconcile key 2) | ASSERTED | check (4) pinned sha256 + recompute-stable, in both |
| inception node -> DEFER-materialization input | ASSERTED (input half) | workflow_type "inception" pinned in check (3); teeth (5a): moving the inception out of the sovereignty lane must make the validator fail |
| promote CLI output | AEF OUTPUT | not emitted by 832; belongs in AEF's bats (T-559) |
| aef_provenance block | AEF OUTPUT | `grep -c aef_provenance src/aef-workflow-designer.html` = 0; exporter aef:* element set has no provenance |
| captured forcing (status: captured) | AEF OUTPUT | `grep -cE '<aef:(provenance)|status="captured"' src/aef-workflow-designer.html` = 0; neither fixture has `status=` |
| reconcile STATES | AEF OUTPUT | 832 supplies only the keys (uid + sha), which are asserted above |
| gate refusal | AEF OUTPUT | AEF's gate; 832 asserts only its own validator's teeth (5a) |

Missing rows: none.

## Mutation spot checks (my own, in memory; no files changed)
- Changed the n_inception `<aef:meta workflowType>` from inception to build: extract_manifest returns
  workflow_type 'build', so check (3)'s dict equality would fail. The workflow_type assertion has real teeth.
  (My first attempt only rewrote the copy in an XML comment and was rightly ignored by the parser.)
- In the joint fixture, changed authority initiative to sovereignty: n_plan derives owner 'human', so the
  owners set is no longer {human, agent} and check (3) would fail.

## Notes (do not change the verdict)
- The suites assert pinned, 832-authored shared fixtures, not a live export from the designer. This is the
  stated design (byte-exact shared fixture + sha, T-559) and is how the producer contract is defined at this
  seam. It is not a missing proposal row.
- The task's re-measurement says the exporter emits "23 distinct aef:* markers". Today I count 28
  (it has grown, e.g. eventDef and boundaryPos). None of them is an AEF-OUTPUT field, so the side-split
  still holds. The number in the task is just stale.
- Whether AEF's side is green against these shas cannot be observed from here, and this criterion does not ask.

## Verdict: green
Every producer-input row is asserted by the two green suites, and the assertions have working teeth. The
remaining rows are AEF outputs that 832 does not emit and must not assert. Nothing is missing.
Replying to AEF stays with the operator (the second Human AC).
