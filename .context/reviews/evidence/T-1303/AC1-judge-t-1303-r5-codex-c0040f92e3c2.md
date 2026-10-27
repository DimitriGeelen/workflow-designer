# Reviewer evidence — T-1303 AC#1

- dispatch: `judge-t-1303-r5-codex-c0040f92e3c2`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `a1d493cbcd050ca2d150c75a665487d640f78fee`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `86706105348d3211a611b4263ca31e1b78062777bb895ce866c4c397683c5ee2`
- result.md sha256: `8d04178b9644e0550a128e1dacc781071b83ab62ae5ac4471d5da0b547def523`

## The worker's verdict block

```
1. [AC] Check findings belong to their io without crowding its rows
VERDICT: green
WHY: Visually inspected the full-viewport and panel screenshots for findings-lint, findings-v11 and findings-lint-edit at 1024/1440/1920 in docs/reports/T-1303-evidence/, plus their panel-end captures. The contact ERROR and account WARN sit directly beneath their respective output rows; both prefix ERRORs sit beneath the opp input. Severity, explanatory text and rule IDs are readable and wrap without overlap. Clean io rows have no findings. Names, types, req checkboxes and × controls remain readable. Compared v11-step-1440-panel.png with findings-v11-1440-panel.png: row alignment is preserved, the remaining summary is legible below the findings, and editable attributes are readable in the expanded editor. The shorter viewports use vertical scrolling; panel-end captures show the lower rows without crowding.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Check findings belong to their io without crowding its rows
VERDICT: green
WHY: Visually inspected the full-viewport and panel screenshots for findings-lint, findings-v11 and findings-lint-edit at 1024/1440/1920 in docs/reports/T-1303-evidence/, plus their panel-end captures. The contact ERROR and account WARN sit directly beneath their respective output rows; both prefix ERRORs sit beneath the opp input. Severity, explanatory text and rule IDs are readable and wrap without overlap. Clean io rows have no findings. Names, types, req checkboxes and × controls remain readable. Compared v11-step-1440-panel.png with findings-v11-1440-panel.png: row alignment is preserved, the remaining summary is legible below the findings, and editable attributes are readable in the expanded editor. The shorter viewports use vertical scrolling; panel-end captures show the lower rows without crowding.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
