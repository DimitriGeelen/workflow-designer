# Reviewer evidence — T-310 AC#1

- dispatch: `judge-t-310-r5-codex-fe43a3440d6c`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `2c952a3e6d525bf14d41589069f1c3bb8be95d01`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `913313ff11c12805b27099f3b9cb05ed45d19cd468001dd62fd4082e4203f5f6`
- result.md sha256: `737b7fe590e0aa257428865b8341924c1f3a258d9b937eef0658d45a5eb015fb`

## The worker's verdict block

```
1. [AC] Reconciliation reads as a repair
VERDICT: not-evaluated
WHY: I inspected docs/screenshots/t310-both-before.png and confirmed the two nodes appear in each other’s lanes. However, running python3 -B tests/test_t310_lane_position_conflict.py failed before opening the designer: the sandbox rejected the harness’s localhost listener with listen EPERM: operation not permitted 127.0.0.1. I could not inspect the live repaired placement or notice count.
GUIDANCE: Reassign to a reviewer with browser access and permission to run the local designer. Load the fixture, verify both requested lane placements, and confirm the notice reports 2 nodes moved back.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Reconciliation reads as a repair
VERDICT: not-evaluated
WHY: I inspected `docs/screenshots/t310-both-before.png` and confirmed the two nodes appear in each other’s lanes. However, running `python3 -B tests/test_t310_lane_position_conflict.py` failed before opening the designer: the sandbox rejected the harness’s localhost listener with `listen EPERM: operation not permitted 127.0.0.1`. I could not inspect the live repaired placement or notice count.
GUIDANCE: Reassign to a reviewer with browser access and permission to run the local designer. Load the fixture, verify both requested lane placements, and confirm the notice reports 2 nodes moved back.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```
