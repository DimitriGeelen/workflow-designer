# T-1049 — AEF 1.7.740 → 1.8.2, under the re-vendor protocol (T-1000)

Second real use of the protocol. AEF released 1.8.2 on 2026-10-05 (inbox @624). It is the
release we were waiting for: crontab-path fix (1.8.1), reindex disk guard T-3860, and the
receipt/nudge inbox fix T-3792/T-3840.

## Before the run (agent)

- **1.8.x refuses to delete consumer-local files** (AEF T-3850). The 1.8.2 dry-run listed 50 files
  under `.agentic-framework/` that are ours and would have been deleted. Six are real code
  (`lib/instance-position.sh`, `lib/external_consult.py`, `lib/task-ownership.sh`,
  `lib/verification-absence.sh`, `agents/context/check-bare-import.sh`, `web/test_safe_commands.py`);
  44 are their generated component docs. All 50 went into a new `.fwvendor-preserve.yaml`
  (3656cd53). Re-run: 50 PRESERVE, 0 DELETED.
- **A shallow clone of the tag is refused** by 1.8.2's foreign-source guard: our recorded
  `version_sha` is not in `--depth 1` history. The runme clones full history and checks the
  sha is present before upgrading.
- `runme.sh` (5c2d8962): upgrade from the v1.8.2 tag pinned by commit (`ddf86720`), re-install the
  re-vendor gate (the upgrade's hook reinstall removes it), pristine commit, baseline advance,
  crontab check. Dry-run passed and wrote nothing; the baseline rewrite was tested on a copy of
  the register.

## The operator's run (2026-10-05 15:05–15:44, rc=0)

| step | result |
|---|---|
| 1. fw upgrade | 1.8.2 in the tree; 50 local files kept; one step PARTIAL (hooks, below) |
| 2. pristine commit | **b37861b5**, 218 vendored paths (the post-commit hook took ~8 min, T-1004) |
| 3. baseline advance | **b34fca85** |
| 4. crontab | already pointed at the vendored framework (6 job lines); nothing to rewrite |

## Re-apply (protocol step 3)

`_t517` against the new baseline: 44 STALE. Two classes:

- **38 real**: declared files the upgrade overwrote. `_t1000-revendor-worklist.py` produced a patch
  for every one from its own local commits. 35 applied cleanly; 3 needed a three-way merge:
  - `lib/ask.py` (T-644) — **superseded**: upstream fixed the same defect (their T-3783). Upstream's
    version kept, register entry removed.
  - `docs/reports/T-375-agent-3-key-storage.md` (T-939/T-1024) — **superseded**: upstream redacted
    the machine-id themselves (T-3788). Upstream's version kept, register entry removed.
  - `policy/designer-pin.yaml` (T-1007, local-config) — ours: restored to the pre-upgrade pin
    (designer 0.15.3; the build is at the project root `vendor/designer/`, which is where
    `designer.py` resolves `vendored_path`).
- **6 false**: exactly the six preserved local files. A pristine commit snapshots the whole tree,
  so a file the vendor KEPT is inside the baseline and diffs as nothing. **Fixed in the
  instrument**, not the register: `_t517` now reads the vendor stamp (`.fw-vendor-stamp.json`,
  new in 1.8.x) from the baseline; a declared `added` path that exists and is not in the stamp is
  local by the vendor's own record. Teeth legs 10 (preserved file → green) and 11 (control: same
  tree, stamp lists the file → STALE) — `_t517-vendor-divergence-teeth.py` 11/11.

After both: `_t517` **OK — every diverged path is declared, and every declared path still diverges.**
All 36 re-patched files pass a syntax check (bash -n / py_compile / node --check / yaml).

## Suite results on 1.8.2

- First bridge run: 234 passed, 5 failed. Four were instruments still aimed at 1.7.740 code:
  `_t1047` (pre-fix library now taken from the pristine baseline), `_t644` (anchor on upstream's
  preamble), `_t654` (1.8.2 has three horizon-null sites, AEF T-3744; the mutant reverts all three,
  7/7), `_t1048` leg 6 (Watchtower still served pre-upgrade code; green after a restart, 6 cards /
  6 tiles).
- Final bridge run: **238 passed, 1 failed** (1478 s). The one failure is the `_t509` sweep's
  coverage leg: `_t549-fabric-coverage-mutation-teeth.py` exceeded the 90 s cap. Run alone it is
  5/5 green in 129 s — it did not finish within the cap, nothing regressed. It was inside the cap on
  1.7.740 (sweep 100/100). Not "fixed" by raising the cap (the sweep's own rule: measure the cost
  first); tracked as its own task.

## Outside .agentic-framework/

- `.claude/settings.json`: our three project hooks (`check-bare-import`, `_t420` rail-attribution
  gate, `warn-uncontrolled-absence`) are **kept** this time (1.8.1's T-3833); the sidecar hooks
  (autostart, receiver adapter/ready) and the Write-side human-AC tick guard were added.
  **PARTIAL:** three framework hooks the upgrade's own gap detector expects are not written by its
  settings generator (`check-paid-backend`, `check-worktree-governance-write`, `stop-driver.sh`):
  regeneration ran and the gap remained. Upstream's T-2710 class (template lags the detector);
  reported to AEF, not patched here.
- `CLAUDE.md`: the framework tail gained AEF T-3675 ("operator commands ship as `fw runme new`").
  It contradicts this project's standing operator rule (2026-10-02, `runme.sh` at the project root
  with `tools/runme-signal.sh`). The project section, which upgrades preserve, now says that rule
  wins. A blank line the rewrite dropped is restored.
- `.framework.yaml`: version 1.8.2, `version_sha`, `project_id: pid-6da630d5b53b170f` (minted once).
- The upgrade's doctor flagged exec-bit drift on `agents/audit/orchestrator-mcp-scan.sh`. Not a
  defect: upstream ships it 100644, the pristine commit recorded 100644, and `audit.sh` runs it via
  `bash`. The warning came from the 1.7.740 index, before the pristine commit.
