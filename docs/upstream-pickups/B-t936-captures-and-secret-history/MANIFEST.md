# Bundle B: screen-capture leaks and secrets in history (832 T-936, T-410/T-938/T-939 → AEF T-3572)

**Verified against:** AEF `bleeding-edge` 914326e0 (2026-10-03, via the GitHub mirror), on 2026-10-04.
**Apply:** `git am docs/upstream-pickups/B-t936-captures-and-secret-history/*.patch` (3 commits, applies cleanly, independent of bundle A).
**Probes on the applied tree:**
- `bash tests/unit/test_t936_bare_import_gate.sh` → 17/17 (8 catches, 9 controls).
- `bash tools/_t936-capture-scan-teeth.sh` → 12/12.
- `bash tools/_t410-secret-artifact-teeth.sh` → 14/14.
- `bin/fw audit --sections structure` → both new rails PASS on your tree.

## What it fixes

| # | Commit | Files | Fixes |
|---|---|---|---|
| 1 | Bare-`import` gate | `agents/context/check-bare-import.sh`, `tests/unit/test_t936_bare_import_gate.sh` | Refuses a Bash command whose clause starts with `import` (ImageMagick's screen grab). It reads only shell text: heredoc bodies and quoted text are removed before it looks. **Not enabled by default.** To enable: `bin/fw hook-enable --event PreToolUse --matcher Bash --name check-bare-import`. |
| 2 | Stray-capture detector and rail | `tools/_t936-stray-capture-scan.py`, `tools/_t936-capture-scan-teeth.sh`, `agents/audit/audit.sh` (`check_stray_captures`) | Finds `import(1)` output by its PostScript header, not by filename, and WARNs with the paths. It covers what the gate cannot: a leak inside a shell that is already running. |
| 3 | Tracked-secret scan (index and history) and rail | `tools/tracked-secret-artifacts.py`, `tools/_t410-secret-artifact-teeth.sh`, `agents/audit/audit.sh` (`check_secret_paths_visible_to_git`) | Name-based detection of key material git is publishing. `--history` covers every path in reachable history. Index hits FAIL; history-only hits WARN, because the remedy is rotation first, and a rewrite is Tier 0. |

## Two defects found in our own code while building this

1. **The gate's code had stopped doing what its header promised.** An early version blocked the legitimate `python3 - <<'PY'` idiom, so the code was narrowed to "line 1, first word". The header still promised catches after `&&`, `;`, `|` and newlines; with the narrowing, `cd x && import re` got through. The new version removes heredoc bodies and quotes before splitting, so the catches come back without the false positive. The test holds both directions: 6 catches were red before the fix.
2. **The name heuristic flagged six of your files.** These were four task notes (`T-1302/1306/1352/2896 … secretkey …md`) and two tests (`test_secret_key.py`, `secret_key_gitignore.bats`). All are *about* the Watchtower secret key; none holds one. Unchanged, rail 3 would have FAILed your audit. Prose and source extensions are now exempt from the two name-only rules (`.txt`, `.json`, `.yaml` and extensionless names stay flagged), and a new teeth leg holds both directions.

## Limits, stated

- **History scan depth.** The history result on your tree comes from a 50-commit shallow clone. Run `python3 tools/tracked-secret-artifacts.py --history` on your full repository.
- **Content.** The scan judges names, never content. A key pasted into a `.py` file is your pre-commit content scanner's job.
- **The gate's coverage.** Over 832's four real incidents the gate catches **none**: every leak happened inside an already-running shell. That is why the detector exists. The only complete prevention is taking `import(1)` off PATH, which is an operator decision.

## Placement is yours

These are 832's `_tNNN` names under `tools/`. As with bundle A, consumers only get the rails if the tools reach `lib/` or another vendored path.
