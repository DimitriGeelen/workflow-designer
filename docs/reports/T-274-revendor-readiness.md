# T-274: Re-vendor Readiness — the Four-Concern Closure Path

**Status:** READY FOR OPERATOR — coordinates received (rail 264/265, T-275); every command below is
copy-pasteable as-is.
**Date:** 2026-07-28 (coordinates same day)
**Owner of the re-vendor action:** operator (rewrites the vendored tree — sovereignty-gated).

## Pinned coordinates (AEF, rail 264/265)

- **upstream_repo:** `https://github.com/DimitriGeelen/agentic-engineering-framework.git`
  (public GitHub mirror; auth-free; auto-mirrored from AEF's token-authed OneDev origin on every
  push — PushRepository + 15-min auto-recover cron, their T-1594; verified in sync at answer time.
  The .201:6611 LAN git hosts only the designer origin — the framework is NOT there.)
- **Pull point:** annotated tag **`v1.6.763`** = commit `28c7a1bd3f070bb090f6890fb0a20081afe4c3e8`
  (verified present on the mirror by AEF).
- **Tag contents:** the full T-270 fix set (T-2645/T-2646/T-2647) + T-2637 sim + T-2640/41/42
  reviewer fixes + v1.4 catalogues + **T-2648** (OBS-097 Python grep-lint + 4 more FRAMEWORK_ROOT
  fixes found by its calibration — designer pin/draft-new fw path, approvals batch-complete fw path,
  cron FW_BIN; without these our `/cron` generate and approvals batch-complete would invoke
  `PROJECT_ROOT/bin/fw`, which doesn't exist here) + **T-2649** (shell half: fw policy emit/status
  interpreter, fw mcp check/wire-fragment reads, fw designer status pin read, liveness/notify lib
  sourcing). Fallbacks if ever needed: `v1.6.762` (pre-T-2649), `v1.6.761` (pre-T-2648 minimal set) —
  `.763` is AEF's recommendation and ours.

## Why this matters

Four open concerns now close on one action — re-vendoring `.agentic-framework/` from AEF's
current upstream. AEF confirmed all upstream fixes shipped (rail 258/259, their
T-2645/T-2646/T-2647; earlier T-2637/T-2640/T-2641):

| Concern | What the re-vendor delivers | Post-vendor local action |
|---------|----------------------------|--------------------------|
| G-004 | review.py FRAMEWORK_ROOT fix (their T-2645) + the two sibling fixes (approvals.py:23, orchestrator.py:434) | delete `lib/dispatch_pause.py` shim, operator flips watching→resolved |
| G-008 | Canonical anchored disposition-gate regex (their T-2218 RC5) + bats regression tests | none (our local fix is superseded by canonical), flip |
| G-001 | secret-scan.sh in payload (vintage since 2026-05-15) + loud-fail pre-commit v1.2 + mcp-baseline exit-3/INFO first-run handling (their T-2647) | verify secret scan runs on next commit, flip |
| G-011 | policy/ reviewer catalogues vendored with code (their T-2637), v1.4 header + T-2640/T-2641 reviewer-code fixes | delete local `policy/` shadows (escalation-patterns.yaml, anti-patterns.yaml), flip |

## Original blocker (resolved by the coordinates above)

`fw update` (the vendored-tree re-vendor command) requires `upstream_repo:` in `.framework.yaml`.
That key was never configured: the original vendoring (T-001, 2026-06-04) recorded no provenance,
and `.agentic-framework/VERSION` reads literally `dev`. Verified 2026-07-28:

```
$ .agentic-framework/bin/fw update --check
ERROR: No upstream_repo in .framework.yaml
```

RESOLVED (rail 264/265): coordinates pinned above. Direction confirmed pull-our-side, operator-gated
(matches AEF's standing no-cross-repo-writes boundary — they don't push into /opt/832).

## Operator procedure (copy-pasteable as-is)

```bash
# 0. Optional pre-verify — the ^{} line must show 28c7a1bd3f070bb090f6890fb0a20081afe4c3e8:
cd /opt/832-Workflow-designer && git ls-remote https://github.com/DimitriGeelen/agentic-engineering-framework.git 'refs/tags/v1.6.763*'

# 1. Pin the upstream (one-time):
cd /opt/832-Workflow-designer && echo "upstream_repo: https://github.com/DimitriGeelen/agentic-engineering-framework.git" >> .framework.yaml

# 2. Preview (no changes applied):
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw update --check --branch v1.6.763

# 3. Re-vendor at the tag (saves a rollback backup automatically):
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw update --branch v1.6.763

# 4. Rollback if anything breaks:
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw update --rollback
```

(`fw update --branch` feeds `git clone --depth 1 --branch`, which accepts annotated tags —
verified in `.agentic-framework/lib/update.sh:123`.)

## Post-vendor checklist (agent-assisted, operator-approved)

1. `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw doctor` — health check clean.
2. Delete `lib/dispatch_pause.py` (G-004 shim; its header documents this removal condition).
   Verify `/review/T-XXX` pages still load (the fix is now upstream-side).
3. Delete local `policy/` shadows once the vendored tree ships catalogues (G-011):
   check `ls .agentic-framework/policy/` first; only delete the project-local copies after
   confirming the vendored versions exist and `fw reviewer` still passes a smoke run.
4. Confirm the disposition gate still passes on T-190 (the G-008 regression case):
   canonical grammar rejects `* IW-N` / `# IW-N` forms — T-273 swept the tree: zero such markers.
   RESOLVED (rail 263): canonical regex carries `\*?\*?` — the dash+bold `- **IW-N:` template
   shape is CONFIRMED matching (AEF verified empirically against the live regex: bold, plain,
   `###`, and indented forms all MATCH; `* IW-N` and prose mentions correctly no-match).
   Zero task edits needed; our 17-task/60-question population migrates as-is.
5. Make one commit and verify the secret scan RUNS (G-001 F4): expect scan output, not
   "scanner not found (skipping)".
6. Run `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw audit` — expect the
   orchestrator-mcp baseline to survive (it is per-install state under .context/, untouched by vendor).
7. Operator flips G-001, G-004, G-008, G-011 watching→resolved in `.context/project/concerns.yaml`
   (closure evidence already recorded per concern).

## Risks / notes

- `fw update` overwrites `.agentic-framework/` entirely. Our local in-tree fixes (G-008 anchored
  regex, T-014-era edits) are superseded by canonical equivalents — nothing local needs preserving.
  The rollback backup covers surprises.
- Project-local artifacts (lib/ shim, policy/ shadows, .context/ state) are NOT touched by the
  vendor — their cleanup is the manual checklist above.
- The re-vendor rewrites the vendored governance tree the running session depends on; do it at a
  session boundary, not mid-task.
