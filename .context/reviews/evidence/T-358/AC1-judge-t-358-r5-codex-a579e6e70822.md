# Reviewer evidence — T-358 AC#1

- dispatch: `judge-t-358-r5-codex-a579e6e70822`
- worker kind: `codex` (vendor `openai`, model `gpt-6-astra`)
- seat: `codex`
- reviewed revision: `9f07871f147fcbd65ea0450f3cdc8b49a14bb885`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `42b53afa75a3af2cc61cbe4461e42b8d6c665917eeda9500f6e27750b17ac7c2`
- result.md sha256: `05fd5d6f111cab8b87b5983b736e94c5725c63fd79418514891a66c4dcf05fcb`

## The worker's verdict block

```
1. [AC] Maps without declared lanes render correctly
VERDICT: green
WHY: Inspected all 21 screenshots in docs/reports/T-358-evidence/, plus boundary-events-1024-bottom.png. Across all seven maps and three widths, the pool vertically encloses the diagram without invented lane bands or lane headers. The add-lane strip sits below the pool; advisory controls remain visible and unobstructed. The extra boundary-events screenshot confirms its lower boundary encloses the lowest event. All three collaboration-message-flows screenshots show the read-only pool below ours without overlap. measurements.txt corroborates vertical containment and zero drawn lanes across all 21 combinations. The nested-subprocesses left-border crossing is outside this criterion’s explicitly narrowed scope.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] Maps without declared lanes render correctly
VERDICT: green
WHY: Inspected all 21 screenshots in `docs/reports/T-358-evidence/`, plus `boundary-events-1024-bottom.png`. Across all seven maps and three widths, the pool vertically encloses the diagram without invented lane bands or lane headers. The add-lane strip sits below the pool; advisory controls remain visible and unobstructed. The extra boundary-events screenshot confirms its lower boundary encloses the lowest event. All three collaboration-message-flows screenshots show the read-only pool below ours without overlap. `measurements.txt` corroborates vertical containment and zero drawn lanes across all 21 combinations. The nested-subprocesses left-border crossing is outside this criterion’s explicitly narrowed scope.
GUIDANCE: None.

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
