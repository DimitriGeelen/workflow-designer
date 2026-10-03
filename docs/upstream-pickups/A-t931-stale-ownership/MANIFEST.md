# Bundle A: stale task ownership (832 T-931 → AEF T-3568)

**Verified against:** AEF `bleeding-edge` 914326e0 (2026-10-03, via the GitHub mirror), on 2026-10-04.
**Apply:** `git am docs/upstream-pickups/A-t931-stale-ownership/*.patch` (3 commits, applies cleanly).
**Probes on the applied tree:**
- `python3 tests/unit/test_t931_delegate_owner_follows_criteria.py` → 4/4. On the unfixed `lib/delegation_cli.py` it gives 2/4: both bug cases fail and the control passes.
- `bash tools/_t931-ownership-teeth.sh` → 16/16.
- `bin/fw audit --sections structure` → `[WARN] Stale task ownership: 56 of 391 human-owned task(s) have no open Human criterion` (AEF's own corpus).

## What it fixes

The ruling behind it (832 operator, 2026-09-29): `owner: human` is a sovereignty claim only while a Human criterion is open.

| # | Commit | Files | Fixes |
|---|---|---|---|
| 1 | `fw task delegate`: owner follows the open Human criteria | `lib/delegation_cli.py`, `tests/unit/test_t931_delegate_owner_follows_criteria.py` | The owner flipped only `if converted and remaining_human == 0`. A task with *no* open Human criterion therefore kept `owner: human` forever (832: 45 of 112). Your tree still has the old condition. |
| 2 | Predicate, attended corrector, teeth | `tools/_t931-ownership.py`, `tools/_t931-ownership-sweep.sh`, `tools/_t931-ownership-teeth.sh` | Classifies each task as OWNER-JUSTIFIED, OWNER-STALE or NOT-HUMAN-OWNED. The corrector is a dry run unless given `--apply`, writes only through `fw task update --owner`, and must never run on cron. |
| 3 | Audit rail | `agents/audit/audit.sh` (`check_stale_ownership`, after `check_delegation_surface`) | Reports the stale count as a WARN, taking its facts line from the tool. It stays silent where the tool is absent. |

The teeth turn your three T-3568 requirements into legs:
- the corrector never runs on cron;
- fail-safe means DO NOT FLIP;
- an audit check takes a facts line from a tool and never inlines Python inside a command substitution.

## Deliberately left out

- **The `update-task.sh` revert gate arm (832 e8ad5040).** Your `update-task.sh` already routes ownership reverts through R-033. Our probe passes on your pristine tree, so it is superseded.
- **`lib/task-ownership.sh`.** Its only caller was that gate arm, so it has no caller left.
- **The 45-task cleanup commits.** They are 832's own data.

## Placement is yours

The tools are under `tools/` with 832's `_tNNN` names. If the predicate should reach consumers, it belongs in `lib/`: `tools/` is not vendored, which is why the audit rail stays silent in consumer projects. The parser is already yours (`lib.delegation`). When 832's own `_t770` parser is absent, the predicate falls back to it, and on 832's corpus both parsers give identical facts (213 / 70 / 0 / 0).

## Found while building this bundle

1. **832 had lost commit 1 silently.** The 1.7.740 re-vendor overwrote it, it was never declared in `.vendor-divergence.yaml`, and no test held it. That is why it now comes with a test. 832 opened T-1020 to census any other silent losses.
2. **A trap in your tree that the test hit first.** Your repo carries a self-vendored `.agentic-framework/` holding a *stale* `lib/`. A test that looks for `.agentic-framework/lib` first tests the old copy and fails against a correct fix. The test therefore prefers the repo's own `lib/` when `FRAMEWORK.md` is at the root. Other dual-layout tests may share the trap.
