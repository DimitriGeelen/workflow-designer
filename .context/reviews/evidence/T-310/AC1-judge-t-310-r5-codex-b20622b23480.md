# Reviewer evidence — T-310 AC#1

- dispatch: `judge-t-310-r5-codex-b20622b23480`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `c78f56ad4614d7a0477ae7b032ca62e708cb12d7`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `cf39052e37e8c0582d6a5ad253ab35f527dfa368ff6d2744f00990addcfd1051`
- result.md sha256: `acfb627999d5f0963adfdb9c70e35a99d0bbf23d90ec253c4bb245f07d4aa774`

## The worker's verdict block

```
1. [AC] Reconciliation reads as a repair
VERDICT: amber
WHY: Inspected the fixture, designer source, and before/after screenshots. The after screenshot places “framework validates the request” in Framework · Authority and displays “2 nodes were drawn outside their declared lane — moved back into place,” clearly describing a repair. However, the Clean layout notice obscures the agent task. Source reconciliation preserves declared membership and counts moved nodes, but I could not independently verify the live import: the browser harness creates files, contrary to this review’s read-only constraint.
GUIDANCE: Run the fixture in a browser permitted to create temporary runtime files. Verify both named tasks’ lanes and the two-node notice; dismiss the overlapping Clean layout advisory to inspect the agent task.
Summary: 0 green, 1 amber, 0 red, 0 escalate
```

## The worker's full output (result.md)

```
1. [AC] Reconciliation reads as a repair
VERDICT: amber
WHY: Inspected the fixture, designer source, and before/after screenshots. The after screenshot places “framework validates the request” in Framework · Authority and displays “2 nodes were drawn outside their declared lane — moved back into place,” clearly describing a repair. However, the Clean layout notice obscures the agent task. Source reconciliation preserves declared membership and counts moved nodes, but I could not independently verify the live import: the browser harness creates files, contrary to this review’s read-only constraint.
GUIDANCE: Run the fixture in a browser permitted to create temporary runtime files. Verify both named tasks’ lanes and the two-node notice; dismiss the overlapping Clean layout advisory to inspect the agent task.
Summary: 0 green, 1 amber, 0 red, 0 escalate
```
