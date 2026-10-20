# T-209 Human AC#1 — independent review (seat claude-code, dispatch judge-t-209-r5-claude-code-d3eda8259ab5)

Revision reviewed: `e1e0958be32fb6e0793cc4782acb40f89e716b1f` (no diff vs working tree in the tests, fixtures or exporter).
Verdict: **green**

## What I did
1. Read the T-209 task (Context table, Re-Measurement, Recommendation).
2. Took AEF's offset-78 proposal items from the task description and the T-208 evolution log
   (`.tasks/completed/T-208-...md` ~l.250, "your compile→promote→create integration test from the 832 side",
   against AEF `tests/unit/bpmn_promote_e2e.bats`). I cross-checked what that bats file pins
   against AEF's own vendored doc `.agentic-framework/agents/bpmn/AGENT.md` l.87-97. That doc lists these pins:
   owner:human+captured with an `aef_provenance` block, owner forced human (G2), audit line per `--write`,
   promote-origin `--owner agent` REFUSED, stale `source_bpmn_sha` → propose-not-clobber, and the seam-slice
   owner derivation. It also says outright: "832's producer contract is `tests/test_promote_contract.py`
   (their side); this is the consumer half."
3. Ran both suites myself:
   - `python3 tests/test_promote_contract.py` → rc 0, `OK ... inception-gonogo.bpmn (sha bbfbc5ec4835) ... n_inception {owner:human←sovereignty, workflow_type:inception}; uid totality + byte-determinism + teeth verified`
   - `python3 tests/test_two_lane_joint_contract.py` → rc 0, `OK ... two-lane-joint.bpmn (sha 2ba55eedbd90) ... n_inception {owner:human←sovereignty, wf:inception}; n_plan {owner:agent←initiative, wf:build}; ... teeth verified`
4. Read both test sources in full and checked the assertions (not only the printed OK line).
5. Ran an independent in-memory mutation check (no repo files modified) against `test_promote_contract.failures()`:
   - `workflowType="inception"`→`build`: 1 failure (manifest tuple + sha)
   - node name changed: 2 failures
   - one trailing byte appended: 1 failure (sha pin)
   - clean fixture: 0 failures
6. Exporter: `grep -cE '<aef:(provenance)|status="captured"' src/aef-workflow-designer.html` → 0,
   `aef_provenance` → 0. The control regex on `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/02-workflow-to-program.md` → 1,
   so the regex is not vacuous.

## Row-by-row
| Proposal row | Classification | Evidence |
|---|---|---|
| manifest shape `{name, owner, workflow_type}` | asserted | `extract_manifest` + check (3): exact dict equality in both suites |
| owner `human` (lane-derived) | asserted | sovereignty→human, both suites; IW-9 node-override rejected in `extract_manifest` |
| owner `agent` (lane-derived) | asserted | joint check (3) owner set == {human, agent}; teeth (5b) |
| reconcile keys: uid totality + `source_bpmn_sha` | asserted | check (2) + teeth (5b/5c); check (4) pinned sha256, recompute-stable |
| inception-node DEFER-materialization **input** (`workflow_type: inception`) | asserted | check (3) pins `inception`; teeth (5a) rejects inception outside sovereignty (validator O-3) |
| promote CLI output | AEF output (T-559) | produced by AEF `fw bpmn promote`; 832 cannot run it |
| `aef_provenance` block | AEF output | stamped by AEF gate; 832 exporter emits 0 occurrences |
| `captured` forcing / G2 owner:human override | AEF output | gate-side (`create-task.sh`); not an 832 field; exporter 0 occurrences |
| reconcile STATES (propose-not-clobber etc.) | AEF output | computed by AEF from 832's keys, which are asserted |
| gate refusal (`--owner agent` refused) | AEF output | AEF `create-task.sh` behaviour |
| inception materialization itself (T-2549) | AEF output | AEF `create_via_gate` fix; the 832 input is the `workflow_type` (above) |
| audit line per `--write` (in bats, not in the task table) | AEF output | AEF writes `.bpmn-promote-audit.jsonl`; no 832 input. The table leaves it out, but this changes nothing |

Missing producer-input rows: **none**.

## Notes / limits
- I could not read the raw rail message at offset 78 (no rail log in the repo). I used the task's
  quotation, the T-208 record of the message and AEF's own AGENT.md description of the bats pins. These three sources agree.
- `horizon` is not asserted. The test header documents this as deliberate: AEF defaults it manifest-side and the
  fixture carries none. It is not a row in AEF's proposal.
- This verdict covers the evidence only. Whether to decline AEF's proposal and reply on the rail stays with the operator (Human AC#2).
