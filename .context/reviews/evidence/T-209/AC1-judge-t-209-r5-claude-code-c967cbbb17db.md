# T-209 AC1 — independent review (rung-5-panel:claude-code)

Revision: 3f5450c7d4c07210449957dd72dc5d66cc5d15c0 · Date: 2026-10-20

## What I checked
1. Read the T-209 task: the offset-78 proposal rows (task `description:` + Context table), and `## Recommendation`.
   The rail message itself is not quoted word for word in the repo, so I cross-checked the row list against AEF's own
   description of `tests/unit/bpmn_promote_e2e.bats` in `.agentic-framework/agents/bpmn/AGENT.md:87-108`
   (T-2545/T-2548/T-2549). That file names the same set: owner:human+captured, aef_provenance, G2 owner forcing,
   audit line, refusal of `create --owner agent`, stale `source_bpmn_sha` → propose-not-clobber, inception → DEFER injection.
2. Ran both suites:
   - `python3 tests/test_promote_contract.py` → rc 0, `inception-gonogo.bpmn (sha bbfbc5ec4835)`, n_inception {owner:human←sovereignty, workflow_type:inception}
   - `python3 tests/test_two_lane_joint_contract.py` → rc 0, `two-lane-joint.bpmn (sha 2ba55eedbd90)`, n_inception human/inception + n_plan agent/build
3. Read both test sources in full to see what they actually assert, not just what they print.
4. Ran my own in-memory mutation checks (scratch script in /tmp, fixtures not touched). Every one was caught:
   inception→build workflowType (pc: (3)+(4)), n_plan build→test (jt: (3)), n_plan rename (jt: (3)), and an
   initiative→authority lane swap that leaves the owner unchanged (jt: (4) sha pin + (5b)). Both baselines unmutated: no failures.
5. Exporter seam: `grep -cE '<aef:(provenance)|status="captured"' src/aef-workflow-designer.html` → 0; `aef_provenance` → 0.

## Row-by-row
| Proposal row | Classification | Evidence |
|---|---|---|
| manifest shape {name, owner, workflow_type} | ASSERTED | `extract_manifest` + exact dict equality, check (3) in both suites |
| owner human (sovereignty-derived) | ASSERTED | both (3); teeth (5a) |
| owner agent (initiative-derived) | ASSERTED | joint (3) incl. owner set == {human, agent}; teeth (5b) |
| reconcile KEYS: uid totality | ASSERTED | check (2) both; teeth pc(5b), jt(5c) |
| reconcile KEYS: source_bpmn_sha | ASSERTED | check (4) pinned sha256 both (re-pinned under T-314; old efb53839 in AEF's AGENT.md is the pre-re-pin value, documented and cleared on the rail) |
| inception-node DEFER leg: 832 input (workflow_type inception) | ASSERTED | both (3) |
| inception DEFER injection / `## Recommendation: DEFER` | AEF OUTPUT | AGENT.md:101-108: `create_via_gate` injects it, AEF-side |
| promote CLI output | AEF OUTPUT | T-559; not emitted by 832 |
| aef_provenance block | AEF OUTPUT | 0 occurrences in exporter |
| captured forcing / G2 owner→human forcing | AEF OUTPUT | 0 `status="captured"` in exporter; AGENT.md:90-91 |
| reconcile STATES (propose-not-clobber) | AEF OUTPUT | AGENT.md:85-86, 92 |
| gate refusal (`create --owner agent`) | AEF OUTPUT | AGENT.md:91 |
| audit-line append | AEF OUTPUT | AGENT.md:84, 91 (not in the task's table, but on AEF's side all the same) |

Missing rows: none.

## Notes (not blocking)
- Both suites assert committed shared-fixture bytes under a pinned sha, not live exporter output. That is the agreed
  seam shape (shared fixture + byte-exact sha). Per the task text, a check that the exporter reproduces these bytes was never part of offset 78.
- `horizon` is deliberately not a producer assertion (AEF defaults it). The test header documents this, and the offset-78 manifest tuple does not include it.
- AEF-side greenness against these shas cannot be observed from 832 and is not claimed.

Verdict: GREEN. Every producer-input row is asserted, with working teeth. Every other row is an AEF output. Nothing is missing.
