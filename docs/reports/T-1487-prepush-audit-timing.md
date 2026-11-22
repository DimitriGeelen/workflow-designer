# T-1487 — where the pre-push audit's time goes

Measured 2026-11-22 on this host (framework 1.8.15+1953.g695627584), `audit.sh --section structure`, the subset the
framework's pre-push hook runs after 832's core gate.

## Whole section

131 s wall. The timing ledger's last full run had structure at 102 s. After T-1481 the core gate itself takes ~4.5-5 min,
so the audit is now 30-45 % of a push; a push with the gate already cached-green took 98 s, nearly all audit.

## Per check (time between consecutive output lines; checks that print nothing fold into the next line)

| s | check |
|---|---|
| 92.8 | Reviewer-verdict ledger (waits for six prefetched Python audits started in parallel) |
| 4.1 | Issue-ledger lag |
| 3.2 | Project YAML parse |
| 1.6 | Fabric registered cards |
| <= 1.3 each | every other check (~60) |

## The six prefetched audits, run alone

| s | command |
|---|---|
| **84.9** | `lib/verdict_ledger.py audit` |
| 15.1 | `lib/human_ac_ticks.py audit` |
| 0.4 | `lib/accepted_miss.py audit` |
| 0.4 | `lib/watchtower_decision_revert.py` |
| 0.1 | `lib/outside_commits.py audit` |
| 0.1 | `lib/index_reconcile.py` |

## verdict_ledger.py audit, profiled (cProfile, 113.7 s under the profiler)

- `audit` → `_row_fault` × 285 rows (112.1 s) → `_completion_fault` (99.2 s) → `history_fault` × 286 (91.8 s).
- `_git_out` 56,151 calls (74.7 s), `_catfile_show` 43,578 calls (63.8 s): every row re-reads its task's committed
  history through `git cat-file`, on every run.
- The only cache is in-process (`_HISTORY_FM`, keyed by root, task, HEAD); nothing survives between runs, so every
  push and every 30-minute cron audit pays the full walk again.

## Lock contention adds to it

The same audit runs from cron at :00 and :30 (structure), :15 and :45 (oe-fast), :30 (hourly). The pre-push hook waits
for the audit lock (1.25 × the last structure time, clamped 90-600 s). A push that lands while a cron audit runs waits for
it, then runs its own 131 s. Our first timing attempt today met "Another audit is already running".

## Proposal (to AEF; their code, vendored here)

1. **A persistent per-row cache for `history_fault`**: a row's verdict depends on the row and on the committed history of
   its task file. Key the result by (row hash, the last commit touching that task's file); a new push changes the key only
   for rows whose task moved. Expected: ~85 s → a few seconds on a push that touches a handful of tasks.
2. **Or, at pre-push only, skip the ledger walk when the pushed range touches neither the verdict ledger nor any
   `.tasks/` file**, and leave the full walk to the cron audit (every 30 min). Weaker: a push that does touch tasks still
   pays the full 85 s.
3. Either way, `human_ac_ticks.py audit` (15 s) is the next one; the same treatment applies.

Nothing changed locally: the hook and `lib/` are vendored, and an upgrade would overwrite a patch.
