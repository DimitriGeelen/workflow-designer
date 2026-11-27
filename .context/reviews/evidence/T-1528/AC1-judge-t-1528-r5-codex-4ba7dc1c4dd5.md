# Reviewer evidence — T-1528 AC#1

- dispatch: `judge-t-1528-r5-codex-4ba7dc1c4dd5`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `e1e7edddf7f15523c34f8f2edf838a338e94e298`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `d50e0a59135c1cfe123f3e63f7db290dc37bea5480bcbb89183275cc90c5305d`
- result.md sha256: `56b754754278459b26aaf217493bbbdfe87624ea9d1a9f4d9ec61c23a3cd78ca`

## The worker's verdict block

```
1. [AC] Scope field reads well at every specified width
VERDICT: green
WHY: Visually inspected all six supplied images in docs/reports/T-1528-shots/: workflow-panel-unset-{1024,1440,1920}.png and workflow-panel-framework-{1024,1440,1920}.png. In each, the Scope label, hint, and select are visible, unclipped, and non-overlapping. Alignment, styling, and select dimensions are consistent with Kind above. Each selected value is fully readable: “unset — this project only” or “framework — ships to every project.” The hint “which projects get this map,” together with these explicit options, explains distribution without requiring knowledge of T-1519.
GUIDANCE: None needed.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Scope field reads well at every specified width
VERDICT: green
WHY: Visually inspected all six supplied images in docs/reports/T-1528-shots/: workflow-panel-unset-{1024,1440,1920}.png and workflow-panel-framework-{1024,1440,1920}.png. In each, the Scope label, hint, and select are visible, unclipped, and non-overlapping. Alignment, styling, and select dimensions are consistent with Kind above. Each selected value is fully readable: “unset — this project only” or “framework — ships to every project.” The hint “which projects get this map,” together with these explicit options, explains distribution without requiring knowledge of T-1519.
GUIDANCE: None needed.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
