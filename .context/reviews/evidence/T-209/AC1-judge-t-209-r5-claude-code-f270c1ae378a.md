# T-209 Human AC#1 — reviewer evidence (rung-5-panel:claude-code)

Revision reviewed: e72704c74bbed1fbca2cb0733c4ddbd67d19da78 (HEAD at review time).

## Question
Decline AEF's offset-78 producer-contract proposal as already satisfied? (Recommendation: A.)

## What I ran / checked (2026-10-19)
- `python3 tests/test_promote_contract.py` → rc 0, `OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)`; uid totality + byte-determinism + teeth.
- `python3 tests/test_two_lane_joint_contract.py` → rc 0, `OK: two-lane joint promote contract — two-lane-joint.bpmn (sha 2ba55eedbd90)`; human (sovereignty/inception) + agent (initiative/build) owners.
- `python3 tests/test_typed_event_fixture_contract.py` → rc 0, `typed-events.bpmn (sha 5467071b3a39), boundary-events.bpmn (sha 37eec1b0f10a)`.
- `tests/test_promote_contract.py` inspected: check (3) pins exact `{name, owner, workflow_type}` tuple (incl. `workflow_type: inception`), (4) pinned sha256 + recompute, (5a)/(5b) teeth (sovereignty-lane blanking, uid strip). This matches the Context table's producer-INPUT rows.
- `grep aef_provenance|captured src/aef-workflow-designer.html` → no `aef_provenance` and no `status: captured` emission (hits are unrelated code comments). Supports "exporter emits none of the AEF-OUTPUT fields".
- T-212 is in `.tasks/completed/`; commit `39f69bcb` (2026-07-19) adds the typed-event fixture sha pin. Wired in `tests/run-bridge-tests.sh` at **line 306** (brief says :203 — stale line ref, harmless).

## Finding
Substance of option A is verified: producer-input half of the offset-78 proposal is asserted by two green suites with teeth; the AEF-OUTPUT half (promote CLI output, aef_provenance, captured forcing, reconcile states, gate refusal) correctly belongs on AEF's side per T-559. Option C's extra action (file typed-event cross-validation) is already discharged by T-212. Declining is reversible (a test can be built later) and is a message to a cooperating peer, not a Tier-0/irreversible/sovereignty action — no human escalation required on risk grounds.

## Defect in the AC (why not green)
Step 3's prescribed command still records **"T-209 offset-78 proposal: C"** with rationale "... file typed-event byte-exact cross-validation as its own task", and "Expected" says the agent then files the typed-event task. That contradicts the AC's own recommendation (A) and, if executed literally, would have the agent file a duplicate of T-212. Not evaluated: AEF's side (whether their cross-validation is green) — not observable from here, and correctly not claimed.
