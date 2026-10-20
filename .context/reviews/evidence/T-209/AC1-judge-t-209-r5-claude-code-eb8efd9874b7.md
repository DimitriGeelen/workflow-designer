# T-209 AC1 — independent review (rung-5-panel:claude-code)

Revision reviewed: 55f49763751618f860202f3a963a4cb8ea156ae7. Read-only, except for this report.

## Source of the proposal rows
AEF's raw offset-78 message is not stored in this repo; I searched .context/inbox, bus, episodic and arcs. As the
criterion allows, I used the proposal rows quoted in the task's description and under Context: manifest shape,
promote CLI output, owner agent|human + captured forcing, aef_provenance block, reconcile states, gate refusal,
inception-node DEFER-materialization leg. The Context table covers all seven. It splits the compound items
(owner + captured, inception + DEFER) into an input half and an output half.

## Runs (executed here, at this revision)
- `python3 tests/test_promote_contract.py`: rc 0. `OK: ... inception-gonogo.bpmn (sha bbfbc5ec4835)`, n_inception {owner:human←sovereignty, workflow_type:inception}
- `python3 tests/test_two_lane_joint_contract.py`: rc 0. `OK: ... two-lane-joint.bpmn (sha 2ba55eedbd90)`, n_inception human/inception; n_plan {owner:agent←initiative, wf:build}

## Code read (both test files in full)
- Manifest tuple: `extract_manifest` builds {name, owner, workflow_type} for each owner-bearing uid. Check (3) compares
  it to an exact expected dict in both suites. The joint suite also asserts the owner set == {human, agent}.
- Owner: derived from lane `laneMeta authority` through AUTHORITY_OWNER. A node-level owner override raises an error
  (IW-9). Check (0) guards the mapping mirror against drift from tools/validate-workflow.py.
- Reconcile keys: check (2) requires an aef:uid on every flow node and edge. Check (4) pins sha256 against
  PINNED_SHA and confirms a recompute gives the same value.
- Inception input: workflow_type "inception" is pinned in check (3). Teeth (5a) shows the canonical validator
  rejects the fixture when the sovereignty lane is mutated.
- Teeth: (5a)/(5b) in the promote suite; (5a)/(5b)/(5c) in the joint suite (initiative authority → none breaks agent
  derivation; a stripped n_plan uid is detected).
- My own extra check (mutating in-memory copies only, no file changed): workflowType inception→build trips check (3)
  directly, not only the sha pin. Changing sovereignty to authority trips (1) E-INCEP… and (3). So check (3)
  really does pin the tuple.

## Row-by-row ruling
| Proposal row | Ruling |
|---|---|
| manifest shape {name, owner, workflow_type} | ASSERTED: check (3), both suites, exact dict |
| owner agent / human (lane-derived) | ASSERTED: human in both suites; agent in the joint suite (+ owner-set check, teeth 5b) |
| captured forcing (status: captured) | AEF OUTPUT. Not a 832 producer field; `grep -cE '<aef:(provenance)|status="captured"' src/aef-workflow-designer.html` = 0 (control doc = 1, so the regex works) |
| aef_provenance block | AEF OUTPUT. `grep -c aef_provenance src/aef-workflow-designer.html` = 0 |
| promote CLI output | AEF OUTPUT. 832 cannot run AEF's promote (T-559) |
| reconcile states | AEF OUTPUT. 832 supplies only the keys (uid totality + pinned source sha), and both are ASSERTED |
| gate refusal | AEF OUTPUT. AEF's gate. 832's own validator-teeth (5a) covers the input side |
| inception-node DEFER-materialization leg | input half ASSERTED (workflow_type inception, sovereignty lane, teeth 5a); the DEFER materialization itself is an AEF OUTPUT |

Nothing is missing. Every producer-input row is asserted, and the remaining rows are AEF outputs that 832 must not
assert.

## Caveats (they do not change the verdict)
- I could not read AEF's original message verbatim. The verdict assumes the rows quoted in the task are faithful.
  They match the description written when the task was filed (2026-07-19), and the test headers name the same
  AEF reference (tests/unit/bpmn_promote_e2e.bats, T-2545).
- `horizon` is deliberately not asserted (documented in the test_promote_contract header: AEF defaults it). It is
  not one of the offset-78 rows.
- Whether AEF's side is green against these shas cannot be observed from 832, and this verdict does not claim it.
