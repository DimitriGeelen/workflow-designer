# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-codex-3e9e9473387b`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `57c78a35b8375733c80c760295a36c5c340be47a`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `18ee10e7ecd70042629cf8c33f1e6d88a9f2ba0513b4d8f17ce6c1411435621a`
- result.md sha256: `30e403e544c39b0d1a01e8fe03bcf7adf09d9f0951796b8701979b3d9d8d14ae`

## The worker's verdict block

```
1. [AC] Distinct marker kinds; common case silent
VERDICT: not-evaluated
WHY: Inspected the three revision-provided medium screenshots: “◆ ini” appears faint, “⚠ no auth” appears orange and stronger, and none-m has no authority marker. The incoming edge label appears separate from the missing marker. However, the required harness failed in scratch space with listen EPERM: operation not permitted 127.0.0.1, so I could not verify fresh renders or hover text. The brief excludes green from a failed run. The revision export was unchanged.
GUIDANCE: Rerun the harness in an environment permitting localhost listeners, inspect the generated screenshots, and verify the full missing-authority text on hover.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Distinct marker kinds; common case silent
VERDICT: not-evaluated
WHY: Inspected the three revision-provided medium screenshots: “◆ ini” appears faint, “⚠ no auth” appears orange and stronger, and none-m has no authority marker. The incoming edge label appears separate from the missing marker. However, the required harness failed in scratch space with `listen EPERM: operation not permitted 127.0.0.1`, so I could not verify fresh renders or hover text. The brief excludes green from a failed run. The revision export was unchanged.
GUIDANCE: Rerun the harness in an environment permitting localhost listeners, inspect the generated screenshots, and verify the full missing-authority text on hover.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```
