# T-1035: 832's hook fixes whose teeth fail on 1.7.740 — adopted, lost, or obsolete?

**Status:** inception, exploration in progress (2026-10-04).
**Trigger:** T-1013 wired the unwired standing guards. 13 teeth for 832 framework-hook fixes (T-628..T-662) fail (9) or cannot build their pre-fix mutant (4) on the 1.7.740 vendor. T-1020's census, which looked for exactly this class, did not flag them.
**Why now:** the v1.8.0 upgrade is next. Anything lost and undeclared will be lost again.

## Method

- **Spike A (mechanical):** per tool, the fix commit(s) under `.agentic-framework/`, the share of added lines surviving in HEAD, the T-1020 census row, and the register status. Answers IW-2.
- **Spike B (behavioural):** per tool, the behaviour it protects, tested directly on today's tree. Verdict ADOPTED / LOST / OBSOLETE with the check that decided it. Answers IW-1 and IW-3.

## The 13

| Tool | Today (T-1013) |
|---|---|
| `_t628-g020-remedy-reachable.sh` | 5/11 |
| `_t629-g067-remedy-reachable.sh` | 7/10 |
| `_t631-tier0-approval-reachable.sh` | 4/6 |
| `_t632-read-only-misclassification.sh` | cannot measure |
| `_t633-shared-tmp-sinks.sh` | 6/8 |
| `_t634-guard-verdict-reaches-caller.sh` | 4/7 |
| `_t636-prose-verbs-vetoed-by-their-own-text.sh` | 13/15 |
| `_t637-inception-coverage.sh` | 7/8 |
| `_t638-commit-exemption-is-clause-scoped.sh` | cannot measure |
| `_t639-drift-gate-reads-fixtures.sh` | cannot measure |
| `_t650-an-alias-is-the-command-it-aliases.sh` | 10/16 |
| `_t654-watchdog-detections-must-be-surfaced.sh` | cannot measure |
| `_t662-null-focus-commit-path-must-be-discoverable.sh` | 4/9 |

## Findings

### Spike A

(in progress)

### Spike B

(pending)

## Dialogue Log

- 2026-10-04: the operator approved the plan (T-1013 report → "yes" to: wire, restore hooks, then this census before the v1.8.0 upgrade).
