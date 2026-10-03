# Upstream pickups for AEF (832 T-1009)

These are `git format-patch` series, each verified on 2026-10-04 to `git am` cleanly onto AEF `bleeding-edge` **914326e0**, with its own probe green on the applied tree. Each directory has a `MANIFEST.md` covering what the bundle fixes, the files, its probes, what was left out and why, and where things should live. The bundles are independent, so any one can be applied without the others.

| Bundle | AEF task | Commits | Probe on the applied tree |
|---|---|---|---|
| [A: stale task ownership](A-t931-stale-ownership/MANIFEST.md) | T-3568 | 3 | delegate test 4/4 (2/4 unpatched); teeth 16/16; audit rail finds 56 of 391 |
| [B: screen-capture leaks and secret history](B-t936-captures-and-secret-history/MANIFEST.md) | T-3572 | 3 | gate 17/17; capture teeth 12/12; secret teeth 14/14; both rails PASS on your tree |
| [C: re-vendor protocol tooling](C-t1000-revendor-protocol/MANIFEST.md) | T-3737 | 1 | gate test 12/12 (reference input under `contrib/`) |
| [D: allowlisted reads that write (security)](D-t3746-allowlisted-writes/MANIFEST.md) | T-3746 | 1 | write/read matrix 21/21 (10/21 unpatched); your 8 safe-commands bats suites unchanged |

**Apply one bundle:** `git am <dir>/*.patch` from your repository root.

**Defects in 832's own code found while building these** (all fixed here and in the bundles):
- T-931's delegate fix had been lost silently by the 1.7.740 re-vendor.
- The bare-import gate had stopped doing what its header promised.
- The secret-name heuristic flagged six of your files that are *about* a key.
- Two tests ran against the stale self-vendored `.agentic-framework/` instead of the repo's own code.
