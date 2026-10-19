# T-209 Human AC#1 — reviewer evidence (rung-5-panel:claude-code)

Revision reviewed: f9e3daca8bae015b2f235dda0bcafe36da8e8ff1 (HEAD at review time, matches dispatch).

## Question
Decline AEF's offset-78 producer-contract proposal as already satisfied? (Recommendation: A.)

## What I ran / checked (2026-10-19)
- `python3 tests/test_promote_contract.py` → rc 0:
  `OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)`;
  `n_inception {owner:human←sovereignty, workflow_type:inception}; uid totality + byte-determinism + teeth verified`.
- `python3 tests/test_two_lane_joint_contract.py` → rc 0:
  `two-lane-joint.bpmn (sha 2ba55eedbd90)`; `n_inception {owner:human←sovereignty, wf:inception}; n_plan {owner:agent←initiative, wf:build}`.
- `python3 tests/test_typed_event_fixture_contract.py` → rc 0:
  `typed-events.bpmn (sha 5467071b3a39), boundary-events.bpmn (sha 37eec1b0f10a)`; aef:eventDef shape + teeth.
- Teeth present in `tests/test_promote_contract.py`: `failures()` at :189, (5a) sovereignty-lane blanking at :251, (5b) uid strip at :262.
- AEF-OUTPUT side-split: `grep -c aef_provenance src/aef-workflow-designer.html` → 0;
  `grep -c 'status="captured"'` → 0; remaining `provenance`/`captured` hits are code comments or unrelated (undo/drag). Exporter emits none of the AEF-OUTPUT fields.
- T-212: `.tasks/completed/T-212-...md` `status: work-completed`; commit `39f69bcb` (2026-07-19) adds the typed-event fixture sha pin; wired in `tests/run-bridge-tests.sh:306` (matches the AC's "line ~306").
- Prior panel amber (step 3 recorded "C" and asked to file a duplicate of T-212) is corrected at this revision: step 3 now records `"T-209 offset-78 proposal: A"` with rationale citing T-212; `grep "proposal: C"` on the task file → no hits. Expected section says no new task is filed.

## Finding
Option A is substantively correct and the AC is now internally consistent:
- every producer-INPUT row of the offset-78 proposal is asserted by two green suites with working teeth;
- the AEF-OUTPUT rows (promote CLI output, aef_provenance, captured forcing, reconcile states, gate refusal) correctly remain on AEF's side per T-559, and nothing has crossed the seam;
- option C's sole extra action is already discharged by T-212 (green today).
Option B would duplicate coverage and encode assumptions about AEF behaviour.

## Risk classification
Declining is a reply to a cooperating peer on the rail; reversible (a test can be built later if AEF pushes back), not Tier 0, not publishing/deploying/paying/credentials, and not a project-direction or sovereignty call. Under the operator's risk-only ruling, no human escalation required.

## Not claimed
Whether AEF's own cross-validation is green against the pinned shas is on their side of the seam and not observable from here; the AC correctly does not claim it.
