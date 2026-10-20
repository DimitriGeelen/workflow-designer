# Reviewer evidence — T-209 AC#1

- dispatch: `judge-t-209-r5-antigravity-71dca0f41ebf`
- worker kind: `antigravity` (vendor `google`, model `worker default`)
- seat: `antigravity`
- reviewed revision: `55f49763751618f860202f3a963a4cb8ea156ae7`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.md sha256: `d7e5252e65db05c828d00e0cf48a32fa694304416a21aadb009ea6286da9a4c7`

## The worker's verdict block

```
1. [AC] Judge whether 832 already satisfies the compile->promote->create producer contract that AEF proposed at rail offset 78, from the tests and evidence cited in the Recommendation
VERDICT: green
WHY: Both python3 tests/test_promote_contract.py (sha bbfbc5ec4835) and python3 tests/test_two_lane_joint_contract.py (sha 2ba55eedbd90) executed and passed (exit 0) with teeth verified. Inspecting the test code and fixtures against all 9 rows of AEF's offset-78 proposal confirms that all 4 producer-input rows ({name, owner, workflow_type} manifest tuple, lane-derived human + agent owners with IW-9 enforcement, aef:uid totality + pinned source_bpmn_sha reconcile keys, and workflow_type: "inception" in sovereignty lane with O-3 validator teeth) are directly asserted, the remaining 5 rows (promote CLI output, aef_provenance block, status: captured forcing, reconcile states, and AEF gate refusal) are AEF outputs that 832 must not assert under T-559 (and 0 occurrences of <aef:(provenance)|status="captured" exist in src/aef-workflow-designer.html), and nothing is missing.
GUIDANCE: None — the evidence supports Recommendation A (producer-input contract is already satisfied by T-206 and T-208, and typed-event fixtures are separately pinned by T-212).

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
### Evidence Report — T-209 (Criterion 1)

1. **Read AEF's offset-78 proposal rows and Recommendation** in [`.tasks/active/T-209-832-side-compile-promote-create-producer.md`](file:///tmp/tl-dispatch/judge-t-209-r5-antigravity-71dca0f41ebf/tree/.tasks/active/T-209-832-side-compile-promote-create-producer.md#L110-L374), along with [`tests/test_promote_contract.py`](file:///tmp/tl-dispatch/judge-t-209-r5-antigravity-71dca0f41ebf/tree/tests/test_promote_contract.py#L1-L294) and [`tests/test_two_lane_joint_contract.py`](file:///tmp/tl-dispatch/judge-t-209-r5-antigravity-71dca0f41ebf/tree/tests/test_two_lane_joint_contract.py#L1-L180).
2. **Executed the contract test suites** (`python3 -B`):
   - `python3 -B tests/test_promote_contract.py` → exit 0:
     `OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)`
     `manifest owner-bearing uids: n_inception {owner:human←sovereignty, workflow_type:inception}; uid totality + byte-determinism + teeth verified`
   - `python3 -B tests/test_two_lane_joint_contract.py` → exit 0:
     `OK: two-lane joint promote contract — two-lane-joint.bpmn (sha 2ba55eedbd90)`
     `owner-bearing uids: n_inception {owner:human←sovereignty, wf:inception}; n_plan {owner:agent←initiative, wf:build}; uid totality + byte-determinism + teeth verified`
   - `python3 -B tests/test_typed_event_fixture_contract.py` → exit 0 (`typed-events.bpmn` sha `5467071b3a39`, `boundary-events.bpmn` sha `37eec1b0f10a`).
3. **Row-by-row classification of AEF's offset-78 proposal:**
   - **Row 1 — `manifest shape {name, owner, workflow_type}`:** **Asserted by tests.** [`extract_manifest`](file:///tmp/tl-dispatch/judge-t-209-r5-antigravity-71dca0f41ebf/tree/tests/test_promote_contract.py#L137-L170) and check `(3)` in both suites pin the exact `{name, owner, workflow_type}` dict per owner-bearing `aef:uid`.
   - **Row 2 — `owner agent + human (lane-derived)`:** **Asserted by tests.** `test_promote_contract.py` asserts `sovereignty → human` on `n_inception`, checks no node-level `owner` override exists (IW-9), and guards `AUTHORITY_OWNER` against drift from [`tools/validate-workflow.py`](file:///tmp/tl-dispatch/judge-t-209-r5-antigravity-71dca0f41ebf/tree/tools/validate-workflow.py); `test_two_lane_joint_contract.py` asserts both `n_inception → human` and `n_plan → agent` (`initiative` lane `serviceTask`), explicitly checks `owners == {"human", "agent"}` (lines 112–117), and verifies teeth `(5b)` by mutating `authority="initiative"` to `"none"` and confirming `extract_manifest` raises `AssertionError`.
   - **Row 3 — `uid totality / source_bpmn_sha (reconcile KEYS)`:** **Asserted by tests.** Check `(2)` (`uid_missing`) asserts every flow node and sequenceFlow edge carries a non-empty `aef:uid` (with teeth `(5b)`/`(5c)` stripping `n_inception` and `n_plan` UIDs); check `(4)` pins exact SHA-256 byte-determinism (`bbfbc5ec48356c3a643efa21e37912994a3fff56532b7e0ef4815f91fbed00ab` and `2ba55eedbd90ae7805fa9ad3c8a7037913b4788dfc8c7db2ae9f3953d6d7bf7f`).
   - **Row 4 — `inception-node → DEFER-materialization input`:** **Asserted by tests.** Check `(3)` pins `"workflow_type": "inception"` on `n_inception`, and check `(1)` + teeth `(5a)` run `vw.run_xml` to verify that moving `n_inception` out of the `sovereignty` lane is rejected by the canonical O-3 validator rule.
   - **Row 5 — `promote CLI output`:** **AEF output 832 must not assert (T-559).** Produced by AEF's `fw bpmn promote` CLI and tested in AEF's `tests/unit/bpmn_promote_e2e.bats`.
   - **Row 6 — `aef_provenance block`:** **AEF output 832 must not assert (T-559).** Stamped by AEF during task creation; verified 0 matches for `<aef:(provenance)|status="captured"` in [`src/aef-workflow-designer.html`](file:///tmp/tl-dispatch/judge-t-209-r5-antigravity-71dca0f41ebf/tree/src/aef-workflow-designer.html) (positive control in `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/02-workflow-to-program.md` matches 1).
   - **Row 7 — `captured forcing (status: captured)`:** **AEF output 832 must not assert (T-559).** Task lifecycle status assigned by AEF on task creation; not emitted by 832's BPMN exporter (0 matches in `src/aef-workflow-designer.html`).
   - **Row 8 — `reconcile STATES`:** **AEF output 832 must not assert (T-559).** 832 emits only the reconcile keys (`aef:uid` and `source_bpmn_sha`, covered in Row 3); state transitions belong to AEF's reconciler.
   - **Row 9 — `gate refusal`:** **AEF output 832 must not assert (T-559).** AEF's promotion gate refusal lives on AEF's side of the seam (while 832's producer-side O-3 validator refusal is asserted by teeth `(5a)`).
   - **Missing rows:** **None.** Every producer-input row is asserted with working teeth, and the remaining rows are AEF outputs across the T-559 boundary.

1. [AC] Judge whether 832 already satisfies the compile->promote->create producer contract that AEF proposed at rail offset 78, from the tests and evidence cited in the Recommendation
VERDICT: green
WHY: Both `python3 tests/test_promote_contract.py` (sha `bbfbc5ec4835`) and `python3 tests/test_two_lane_joint_contract.py` (sha `2ba55eedbd90`) executed and passed (exit 0) with teeth verified. Inspecting the test code and fixtures against all 9 rows of AEF's offset-78 proposal confirms that all 4 producer-input rows (`{name, owner, workflow_type}` manifest tuple, lane-derived `human` + `agent` owners with IW-9 enforcement, `aef:uid` totality + pinned `source_bpmn_sha` reconcile keys, and `workflow_type: "inception"` in sovereignty lane with O-3 validator teeth) are directly asserted, the remaining 5 rows (`promote` CLI output, `aef_provenance` block, `status: captured` forcing, reconcile states, and AEF gate refusal) are AEF outputs that 832 must not assert under T-559 (and 0 occurrences of `<aef:(provenance)|status="captured"` exist in `src/aef-workflow-designer.html`), and nothing is missing.
GUIDANCE: None — the evidence supports Recommendation A (producer-input contract is already satisfied by T-206 and T-208, and typed-event fixtures are separately pinned by T-212).

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
