# T-676 Human AC#1 — evidence report (reviewer judge-t-676-r1-fd4a151d052e)

Revision reviewed: 854ea6889ea166a5038afcc473d0e659ba32ca88
Verdict: **escalate**

## The criterion
"[REVIEW] Should P-002 exempt read-only Bash when focus is absent, captured, or completed?"
Expected: "a recorded ruling. Nothing edits `check-active-task.sh` before it."

## What I checked

1. **Is a ruling recorded?** No.
   - Task file `.tasks/active/T-676-…md`: `## Decisions` and `## Decision` hold only the template
     comment. `## Recommendation` is the agent's own (GO, Variant B) and says of itself
     "What this recommendation is not: a ruling."
   - `.context/reviews/verdicts.jsonl`, `human-ac-ticks.jsonl`, `recorded.jsonl`: no T-676 row.
   - `.context/approvals`: no file mentions T-676.
2. **"Nothing edits check-active-task.sh before it" — under T-676: holds.**
   - `git log --grep=T-676 854ea6889 -- .agentic-framework/agents/context/check-active-task.sh` → 0 commits.
   - `git diff 854ea6889 -- <hook>` → 0 lines (no uncommitted edit).
3. **But the hook the question is about no longer exists in the form the task describes.**
   The hook has been replaced by vendor upgrades (latest: c156f1ed7 / 3c0ab7403, 2026-11-16,
   AEF v1.8.16-be.54, T-1426), none of them T-676 commits. At the reviewed revision it already has
   a read-only Bash fast path that runs BEFORE any focus check:
   - `check-active-task.sh:231` "Bash tool: safe-command fast path (T-650)"
   - `check-active-task.sh:350-372`: write patterns first; else `is_bash_safe_command` → `exit 0`
     when the command names no task (when it names one, it goes on to the drift gate, T-2880).
   - allowlist lives in `agents/context/lib/safe-commands.sh` (154 KB, chain-aware, not the
     budget-gate regex the task first leaned on).
   I sourced that library (PROJECT_ROOT and _FW_PAYLOAD_CWD = repo root) and ran the register's
   refused commands through it:

   | command (register instance) | is_bash_safe_command | has_bash_write_pattern |
   |---|---|---|
   | `git status --short` (1, 6) | SAFE | no |
   | `git log --oneline -5` (1) | SAFE | no |
   | `git diff` | SAFE | no |
   | `fw arc list` (4) | SAFE | no |
   | `checkpoint.sh status` (5, 8) | SAFE | no |
   | `cat .context/working/.gate-bypass-log.yaml` (8) | SAFE | no |
   | `git push` (7) | SAFE | no |
   | `git diff --output=/tmp/x` (the proposal's own named risk) | not safe | no |
   | `git commit -m x` (9) | not safe | no |

   Instance 9 (commit of a task's own completion) has its own upstream arms: T-2054 (null focus,
   hook line ~968) and T-3179 (work-completed focus, line ~1357).
   This was a function-level test, not a full hook run under each focus state; live focus is
   T-1063, and I did not alter focus.yaml.

## Out-of-date literals in the criterion
- "eight occurrences": the register now has nine rows (instance 9 added 2026-09-09).
- The premise "the gate refuses read-only Bash" is no longer true of the vendored hook.

## Why escalate, not green/amber/red
The criterion asks for the operator's GO / NO-GO / DEFER on loosening a Tier-1 enforcement hook.
The task itself says "Loosening an enforcement gate is not an agent decision". That is a
sovereignty / project-direction call; a reviewer cannot supply it, and none is recorded.
The evidence above changes what the operator is deciding: the exemption is already in the
vendored hook, so the live choice is to close T-676 as overtaken by upstream, or to keep it open
for something upstream does not cover.

## One thing the operator may want to look at when ruling
`git push` is classed SAFE by the upstream allowlist with no write pattern. That is wider than
the "git status / log / diff / checkpoint.sh status, nothing that writes" set the T-676 proposal
asked for. It is upstream's choice, not a T-676 change.
