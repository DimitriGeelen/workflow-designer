# Reviewer evidence — T-1528 AC#1

- dispatch: `judge-t-1528-r5-antigravity-db4f98e78c6d`
- worker kind: `antigravity` (vendor `google`, model `worker default`)
- seat: `antigravity`
- reviewed revision: `e1e7edddf7f15523c34f8f2edf838a338e94e298`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.md sha256: `59ff686df9a5170ae6f77af5eb325bebd87bef0b1a12a91fa607f118cf0a0db5`

## The worker's verdict block

```
1. [AC] The workflow panel's new Scope field reads well at every width
VERDICT: green
WHY: Opened and visually inspected all six supplied screenshots in docs/reports/T-1528-shots/ (workflow-panel-unset-1024.png, workflow-panel-unset-1440.png, workflow-panel-unset-1920.png, workflow-panel-framework-1024.png, workflow-panel-framework-1440.png, and workflow-panel-framework-1920.png; verified 2x-DPI captures at 2048×1800, 2880×1800, and 3840×1800 corresponding to 1024, 1440, and 1920 widths). In all six images, the WORKFLOW right-hand panel renders the Scope label and its single-line muted hint · which projects get this map cleanly below Kind, with matching typography, alignment, spacing, and select-box styling. The select displays unset — this project only in all three unset shots and framework — ships to every project in all three framework shots; both strings fit comfortably with clear margin before the dropdown chevron, with no clipping, awkward wrapping, or overlap with Kind above or RECENTLY OPENED below. Together, the hint ("which projects get this map") and explicit option labels ("this project only" vs. "ships to every project") clearly explain to someone unfamiliar with T-1519 whether the map ships to other projects.
GUIDANCE: none

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] The workflow panel's new Scope field reads well at every width
VERDICT: green
WHY: Opened and visually inspected all six supplied screenshots in `docs/reports/T-1528-shots/` (`workflow-panel-unset-1024.png`, `workflow-panel-unset-1440.png`, `workflow-panel-unset-1920.png`, `workflow-panel-framework-1024.png`, `workflow-panel-framework-1440.png`, and `workflow-panel-framework-1920.png`; verified 2x-DPI captures at 2048×1800, 2880×1800, and 3840×1800 corresponding to 1024, 1440, and 1920 widths). In all six images, the `WORKFLOW` right-hand panel renders the `Scope` label and its single-line muted hint `· which projects get this map` cleanly below `Kind`, with matching typography, alignment, spacing, and select-box styling. The select displays `unset — this project only` in all three `unset` shots and `framework — ships to every project` in all three `framework` shots; both strings fit comfortably with clear margin before the dropdown chevron, with no clipping, awkward wrapping, or overlap with `Kind` above or `RECENTLY OPENED` below. Together, the hint ("which projects get this map") and explicit option labels ("this project only" vs. "ships to every project") clearly explain to someone unfamiliar with T-1519 whether the map ships to other projects.
GUIDANCE: none

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
