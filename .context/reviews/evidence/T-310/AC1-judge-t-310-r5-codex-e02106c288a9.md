# Reviewer evidence — T-310 AC#1

- dispatch: `judge-t-310-r5-codex-e02106c288a9`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `c7b6414b1cefb407b1e112f9dd229caaa25f4593`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `35d38c6c806533afb3d2be1dd787d651a9d8895e984f4e2455548a6e146ce1d1`
- result.md sha256: `e3b908c88a7b4f2160f54cc554636af2bb3d03c32d414d8e6a62d839f074daa8`

## The worker's verdict block

```
1. [AC] Reconciliation reads as a repair
VERDICT: amber
WHY: Compared the committed before/after screenshots and inspected the fixture and implementation. The before image shows the two tasks in each other’s lanes. The after image shows framework validation in Framework · Authority and the notice “2 nodes were drawn outside their declared lane — moved back into place.” However, the Clean layout advisory obscures the agent task’s label. Source reconciliation preserves declared membership and counts corrected positions, but I could not independently verify the current revision through a live import: the browser harness creates temporary files, contrary to this review’s read-only restriction.
GUIDANCE: Run the fixture import in a browser-enabled review environment and verify both task labels in their expected lanes with the two-node repair notice visible. Dismiss the Clean layout advisory to inspect the obscured agent task.
Summary: 0 green, 1 amber, 0 red, 0 escalate
```

## The worker's full output (result.md)

```
1. [AC] Reconciliation reads as a repair
VERDICT: amber
WHY: Compared the committed before/after screenshots and inspected the fixture and implementation. The before image shows the two tasks in each other’s lanes. The after image shows framework validation in Framework · Authority and the notice “2 nodes were drawn outside their declared lane — moved back into place.” However, the Clean layout advisory obscures the agent task’s label. Source reconciliation preserves declared membership and counts corrected positions, but I could not independently verify the current revision through a live import: the browser harness creates temporary files, contrary to this review’s read-only restriction.
GUIDANCE: Run the fixture import in a browser-enabled review environment and verify both task labels in their expected lanes with the two-node repair notice visible. Dismiss the Clean layout advisory to inspect the obscured agent task.
Summary: 0 green, 1 amber, 0 red, 0 escalate
```
