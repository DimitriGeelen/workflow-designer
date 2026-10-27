# Reviewer evidence — T-1303 AC#1

- dispatch: `judge-t-1303-r5-codex-fad3d6295d0c`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `f5fd98ac04ac2bd4fec73646e8401af3f2ee7673`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `bcb40412e0363fe08751553860fbdc4acf7f2654be3d20b45ca645e4a395ace7`
- result.md sha256: `a8efdc0a0210d2f1b537a41c330d9e562ac748177cb27bee950bbad60cc67567`

## The worker's verdict block

```
1. [AC] Check findings belong to their io without crowding its rows
VERDICT: green
WHY: Visually inspected all full-viewport and panel screenshots for findings-lint, findings-v11 and findings-lint-edit at 1024/1440/1920, plus their panel-end captures, in docs/reports/T-1303-evidence/. The contact ERROR and account WARN sit directly beneath their respective output rows; both prefix ERRORs sit beneath the opp input. Severity, explanatory messages and rule IDs are readable without overlap. Clean ios have no findings. Compared v11-step-1440-panel.png with findings-v11-1440-panel.png: name, type, req and × retain their row arrangement; expect/example summaries remain readable below the findings, with editable attributes visible in the opened editor. Smaller viewports use vertical scrolling; the end captures show the lower rows remain readable.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Check findings belong to their io without crowding its rows
VERDICT: green
WHY: Visually inspected all full-viewport and panel screenshots for findings-lint, findings-v11 and findings-lint-edit at 1024/1440/1920, plus their panel-end captures, in docs/reports/T-1303-evidence/. The contact ERROR and account WARN sit directly beneath their respective output rows; both prefix ERRORs sit beneath the opp input. Severity, explanatory messages and rule IDs are readable without overlap. Clean ios have no findings. Compared v11-step-1440-panel.png with findings-v11-1440-panel.png: name, type, req and × retain their row arrangement; expect/example summaries remain readable below the findings, with editable attributes visible in the opened editor. Smaller viewports use vertical scrolling; the end captures show the lower rows remain readable.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
