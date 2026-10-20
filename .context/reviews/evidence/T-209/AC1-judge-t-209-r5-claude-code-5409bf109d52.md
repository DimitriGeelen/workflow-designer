# T-209 Human AC#1 — independent review (rung-5-panel:claude-code)

Revision reviewed: 3f5450c7d4c07210449957dd72dc5d66cc5d15c0 (HEAD at review time). Date: 2026-10-20.

## What I ran
- `python3 tests/test_promote_contract.py` → rc 0
  `OK: designer→AEF promote contract — inception-gonogo.bpmn (sha bbfbc5ec4835)`
  `manifest owner-bearing uids: n_inception {owner:human←sovereignty, workflow_type:inception}; uid totality + byte-determinism + teeth verified`
- `python3 tests/test_two_lane_joint_contract.py` → rc 0
  `OK: two-lane joint promote contract — two-lane-joint.bpmn (sha 2ba55eedbd90)`
  `owner-bearing uids: n_inception {owner:human←sovereignty, wf:inception}; n_plan {owner:agent←initiative, wf:build}; ...`
- `sha256sum tests/fixtures/aef-bpmn/{inception-gonogo,two-lane-joint}.bpmn` → bbfbc5ec4835…, 2ba55eedbd90…; both match PINNED_SHA in their suites.
- My own mutation (in-memory): `workflowType="inception"` → `"build"` in inception-gonogo. `extract_manifest` then returns workflow_type `build`, which differs from `expected` in check (3), so the suite would fail. The inception row has teeth beyond (5a).
- `grep -c aef_provenance src/aef-workflow-designer.html` → 0; `grep -cE '<aef:(provenance)|status="captured"' …` → 0.

## Source of the proposal rows
The task's Context table paraphrases the offset-78 proposal. The proposal itself is quoted in T-208's Evolution section: "your compile→promote→create integration test from the 832 side" against the contract in AEF `tests/unit/bpmn_promote_e2e.bats`. I read that bats file read-only (`/opt/agentic-engineering-framework/tests/unit/bpmn_promote_e2e.bats`, last change cf05c2074 T-2549) to check that the table lists every row. Its assertions are: owner:human + status:captured + aef_provenance + source_bpmn_sha on created tasks; G2 forcing agent→human; audit jsonl line; gate refusal of `create --owner agent`; stale sha → PROPOSE-not-clobber; joint-fixture manifest owner human/agent per lane; workflow_type build/inception; inception DEFER recommendation injected. Every bats assertion maps to one of the table rows below. I found no bats assertion the table omits. The audit-jsonl line is not named in the table, but it is plainly an AEF output (the promote audit log) and sits with "promote CLI output".

## Per-row decision
| Row | Decision | Evidence |
|---|---|---|
| manifest tuple {name, owner, workflow_type} | ASSERTED | `extract_manifest` + check (3) compares exact dict, both suites |
| owner human ← sovereignty | ASSERTED | both suites (3); (5a) teeth via validator O-3 |
| owner agent ← initiative | ASSERTED | joint (3) incl. owner set == {human, agent}; (5b) teeth |
| uid totality (reconcile key) | ASSERTED | check (2); teeth promote (5b), joint (5c) |
| source_bpmn_sha (reconcile key) | ASSERTED | check (4) pinned sha + recompute stability |
| inception node → DEFER-materialization input (workflow_type inception, sovereignty lane) | ASSERTED | check (3) pins `workflow_type: inception`; (5a); my workflowType mutation trips (3) |
| promote CLI output / audit line | AEF OUTPUT | produced by `fw bpmn promote`; T-559 |
| aef_provenance block | AEF OUTPUT | stamped at materialization; 832 exporter emits 0 occurrences |
| status: captured forcing | AEF OUTPUT | task-file field set by AEF gate; not a .bpmn field |
| G2 owner forcing to human | AEF OUTPUT | gate behaviour (bats l.75-79, 179-183) |
| reconcile states (PROPOSE-not-clobber) | AEF OUTPUT | 832 owns only the keys (uid + sha), which are asserted |
| gate refusal | AEF OUTPUT | AEF `fw task create` gate |
| DEFER recommendation injection | AEF OUTPUT | injected by AEF at create (T-2549); 832 supplies only the inception type |

Missing rows: none.

## Observations (not counted against the criterion)
- `horizon` is deliberately not asserted. The promote suite's docstring says AEF defaults it manifest-side and the bats does not assert it, so this is not a gap.
- AEF master's copy of two-lane-joint.bpmn hashes efb53839… and its bats comment still names that sha. AEF bleeding-edge's copy hashes 2ba55eedbd90…, which matches 832's T-314 re-pin. This is AEF-side fixture sync (on AEF's side of T-559), not a missing 832 producer row. It may be worth mentioning in the operator's rail reply.
- I did not judge whether to reply to or decline AEF. That is the operator's separate AC.

## Verdict: green
Every producer-input row is asserted by the two suites, which both pass and both have working teeth. Every other row is an AEF output that 832 must not assert under T-559. Nothing is missing.
