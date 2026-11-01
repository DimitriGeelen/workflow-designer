# Reviewer evidence — T-1303 AC#1

- dispatch: `judge-t-1303-r5-codex-69433d7d7c40`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `290281a46f81cb609a6632a1a92250dfcbcfcea0`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `4e5d65e8069f5e9881e5fb23e3952121c76bf723d367c3f8801629d4f9e983d5`
- result.md sha256: `cba86daeca8f46f47314e54863494e21d54d82f923239c3c61e331bd1b01cc61`

## The worker's verdict block

```
1. [AC] Check findings belong to their io without crowding its rows
VERDICT: green
WHY: Inspected full-viewport and panel screenshots for findings-lint, findings-v11 and findings-lint-edit at 1024/1440/1920, plus available panel-end captures in docs/reports/T-1303-evidence/. The contact ERROR and account WARN sit directly beneath their respective output rows; both undeclared-prefix ERRORs sit beneath the opp input. Severity, explanatory messages and rule IDs remain legible without overlap. Clean ios have no findings. Names, types, req controls and × remain readable and aligned. Compared v11-step-1440-panel.png with findings-v11-1440-panel.png: the v1.1 expectations and example remain readable beneath the findings, with attributes visible in the expanded editor. Scroll-end captures confirm lower rows remain readable with editors open.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Check findings belong to their io without crowding its rows
VERDICT: green
WHY: Inspected full-viewport and panel screenshots for findings-lint, findings-v11 and findings-lint-edit at 1024/1440/1920, plus available panel-end captures in docs/reports/T-1303-evidence/. The contact ERROR and account WARN sit directly beneath their respective output rows; both undeclared-prefix ERRORs sit beneath the opp input. Severity, explanatory messages and rule IDs remain legible without overlap. Clean ios have no findings. Names, types, req controls and × remain readable and aligned. Compared v11-step-1440-panel.png with findings-v11-1440-panel.png: the v1.1 expectations and example remain readable beneath the findings, with attributes visible in the expanded editor. Scroll-end captures confirm lower rows remain readable with editors open.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
