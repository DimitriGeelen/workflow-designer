# Reviewer evidence — T-358 AC#1

- dispatch: `judge-t-358-r5-codex-6997805b39cc`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `76ee72d11c5e84ce48a4851337623364eda03695`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `bd10efb8df52681c8d69dc63aea33b106056349e0fe1b8d5d4f760047a0da036`
- result.md sha256: `6906878fd2fc319945a8d20797c0c519b74c080837b64545898e11f1c031bdb4`

## The worker's verdict block

```
1. [AC] Maps without declared lanes retain correct vertical pool extent
VERDICT: green
WHY: Opened all 21 screenshots in docs/reports/T-358-evidence/ covering simple, nested-subprocesses, collaboration-message-flows, boundary-events, i18n-documentation, multiple-diagrams, and zeebe-service-task at 1024/1440/1920, plus boundary-events-1024-bottom.png. The screenshots show no invented lane bands or lane headers, no diagram elements crossing the pool’s top or bottom, and the add-lane strip below each pool. Advisory controls remain visible and unobstructed. The additional boundary screenshot confirms the bottom border below the lowest event. Collaboration’s read-only pool sits below the main pool without overlap at every width. At 1024, horizontal clipping hides some diagram content and the add-lane label; the strip remains visible below the pool. The nested-subprocesses left-border crossing is excluded by the criterion’s explicit scope.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Maps without declared lanes retain correct vertical pool extent
VERDICT: green
WHY: Opened all 21 screenshots in `docs/reports/T-358-evidence/` covering simple, nested-subprocesses, collaboration-message-flows, boundary-events, i18n-documentation, multiple-diagrams, and zeebe-service-task at 1024/1440/1920, plus `boundary-events-1024-bottom.png`. The screenshots show no invented lane bands or lane headers, no diagram elements crossing the pool’s top or bottom, and the add-lane strip below each pool. Advisory controls remain visible and unobstructed. The additional boundary screenshot confirms the bottom border below the lowest event. Collaboration’s read-only pool sits below the main pool without overlap at every width. At 1024, horizontal clipping hides some diagram content and the add-lane label; the strip remains visible below the pool. The nested-subprocesses left-border crossing is excluded by the criterion’s explicit scope.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
