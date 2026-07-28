# T-274: Re-vendor Readiness — the Four-Concern Closure Path

**Status:** WAITING ON AEF (upstream coordinates requested on the rail at offset 262, thread T-274).
**Date:** 2026-07-28
**Owner of the re-vendor action:** operator (rewrites the vendored tree — sovereignty-gated).

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

## Current blocker

`fw update` (the vendored-tree re-vendor command) requires `upstream_repo:` in `.framework.yaml`.
That key was never configured: the original vendoring (T-001, 2026-06-04) recorded no provenance,
and `.agentic-framework/VERSION` reads literally `dev`. Verified 2026-07-28:

```
$ .agentic-framework/bin/fw update --check
ERROR: No upstream_repo in .framework.yaml
```

The upstream coordinates must come from AEF (asked at rail offset 262):
1. What `upstream_repo` consumers should pin (LAN git server repo name, or URL).
2. Whether a tagged/branch pull point carries the fix set (pull-at-tag preferred — sha-verifiable).
3. Or whether AEF prefers the push direction (`fw upgrade <consumer-path>` from their side).

## Operator procedure (fill in coordinates when AEF answers)

```bash
# 1. Pin the upstream (one-time). Replace <UPSTREAM> with AEF's answer:
cd /opt/832-Workflow-designer && echo "upstream_repo: <UPSTREAM>" >> .framework.yaml

# 2. Preview (no changes applied):
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw update --check

# 3. Re-vendor (saves a rollback backup automatically; add --branch <NAME> if AEF names a release branch/tag):
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw update

# 4. Rollback if anything breaks:
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw update --rollback
```

## Post-vendor checklist (agent-assisted, operator-approved)

1. `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw doctor` — health check clean.
2. Delete `lib/dispatch_pause.py` (G-004 shim; its header documents this removal condition).
   Verify `/review/T-XXX` pages still load (the fix is now upstream-side).
3. Delete local `policy/` shadows once the vendored tree ships catalogues (G-011):
   check `ls .agentic-framework/policy/` first; only delete the project-local copies after
   confirming the vendored versions exist and `fw reviewer` still passes a smoke run.
4. Confirm the disposition gate still passes on T-190 (the G-008 regression case):
   canonical grammar rejects `* IW-N` / `# IW-N` forms — T-273 swept the tree: zero such markers.
   OPEN ITEM: AEF to confirm canonical tolerates the dash+bold `- **IW-N:` template shape
   (asked rail 260); if NOT tolerated, reformat T-155's 3 markers + the inception template first.
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
