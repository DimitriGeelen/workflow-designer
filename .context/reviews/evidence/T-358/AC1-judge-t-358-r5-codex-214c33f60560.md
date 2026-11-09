# Reviewer evidence — T-358 AC#1

- dispatch: `judge-t-358-r5-codex-214c33f60560`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `91dcac38f14a7f98aa51e62bcd1495d3db18a245`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `8ba0f57a90802933a099e29f642919ea09b38caace3f93f0e60f5ba435e45868`
- result.md sha256: `095ba95c12fa5707c0faa89ff29c91a7267f7be99cc9797b6f8da3d9e11818e9`

## The worker's verdict block

```
1. [AC] Maps without declared lanes retain correct vertical pool bounds
VERDICT: green
WHY: Visually inspected all 21 screenshots in docs/reports/T-358-evidence/ covering seven maps at 1024/1440/1920, plus boundary-events-1024-bottom.png. The visible tasks, events and subprocesses remain within the pools’ vertical bounds; no invented lane bands or lane headers appear. The add-lane strip sits below each main pool. Advisory dismiss, expansion and Clean layout controls are unobscured. The boundary-events scrolled view confirms the bottom border below the lowest event. All three collaboration screenshots show the read-only pool below the main pool without overlap. Narrow views horizontally clip diagram content and the add-lane label; this judgement follows the stated vertical scope. The nested-subprocesses left-border crossing is excluded as specified under T-1386.
GUIDANCE: None required for the scoped criterion.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Maps without declared lanes retain correct vertical pool bounds
VERDICT: green
WHY: Visually inspected all 21 screenshots in `docs/reports/T-358-evidence/` covering seven maps at 1024/1440/1920, plus `boundary-events-1024-bottom.png`. The visible tasks, events and subprocesses remain within the pools’ vertical bounds; no invented lane bands or lane headers appear. The add-lane strip sits below each main pool. Advisory dismiss, expansion and Clean layout controls are unobscured. The boundary-events scrolled view confirms the bottom border below the lowest event. All three collaboration screenshots show the read-only pool below the main pool without overlap. Narrow views horizontally clip diagram content and the add-lane label; this judgement follows the stated vertical scope. The nested-subprocesses left-border crossing is excluded as specified under T-1386.
GUIDANCE: None required for the scoped criterion.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
