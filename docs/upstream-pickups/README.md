# Upstream pickups for AEF (832 T-1009)

These are `git format-patch` series, each verified on 2026-10-04 to `git am` cleanly onto AEF `bleeding-edge` **914326e0**, with its own probe green on the applied tree. Each directory has a `MANIFEST.md` covering what the bundle fixes, the files, its probes, what was left out and why, and where things should live. The bundles are independent, so any one can be applied without the others. **Stacking them (checked 2026-10-04, `git am -3` in order A, B, C, D, E on 914326e0):** one conflict, between A and B. Both add a new rail function at the same spot in `agents/audit/audit.sh` (A: `check_stale_ownership`; B 0002: the stray-capture rail). Resolve by keeping both blocks (delete the three conflict-marker lines), `bash -n agents/audit/audit.sh`, `git add`, `git am --continue`. C, D and E then apply cleanly, giving 18 commits, and bundle E's 12 probes pass on the stacked tree.

| Bundle | AEF task | Commits | Probe on the applied tree |
|---|---|---|---|
| [A: stale task ownership](A-t931-stale-ownership/MANIFEST.md) | T-3568 | 3 | delegate test 4/4 (2/4 unpatched); teeth 16/16; audit rail finds 56 of 391 |
| [B: screen-capture leaks and secret history](B-t936-captures-and-secret-history/MANIFEST.md) | T-3572 | 3 | gate 17/17; capture teeth 12/12; secret teeth 14/14; both rails PASS on your tree |
| [C: re-vendor protocol tooling](C-t1000-revendor-protocol/MANIFEST.md) | T-3737 | 1 | gate test 12/12 (reference input under `contrib/`) |
| [D: allowlisted reads that write (security)](D-t3746-allowlisted-writes/MANIFEST.md) | T-3746 | 1 | write/read matrix 21/21 (10/21 unpatched); your 8 safe-commands bats suites unchanged |
| [E: fixes lost or re-applied across the 1.7.740 re-vendor](E-t1021-revendor-restores/MANIFEST.md) (832 T-1021, delivered 2026-10-04) | T-3817 (with A-D) | 10 (0010 is a proposal) | 12 probes green on the am-applied tree; your suites unchanged for 0001-0009; 0010 breaks 17 of your tests by design |

| [F: null-focus aliases and a block that says why](F-t3814-null-focus-aliases/MANIFEST.md) (832 T-1037/T-1038, delivered 2026-10-04, built on **v1.8.0**) | T-3814 | 2 (apply after D) | alias 16/16 with D (15/16 without); null-focus 9/9; your gate suites unchanged |
| [G: runme job queue — several pending jobs, one command, a numbered choice](G-t1111-runme-job-queue/MANIFEST.md) (832 T-1111, sent 2026-10-10; builds on c24521a0) | — | proposal, no patch | real use: jobs 005-009, 2026-10-08/09; two gaps it exposed |

**Apply one bundle:** `git am <dir>/*.patch` from your repository root.

**Defects in 832's own code found while building these** (all fixed here and in the bundles):
- T-931's delegate fix had been lost silently by the 1.7.740 re-vendor.
- The bare-import gate had stopped doing what its header promised.
- The secret-name heuristic flagged six of your files that are *about* a key.
- Two tests ran against the stale self-vendored `.agentic-framework/` instead of the repo's own code.
