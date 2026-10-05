# Upgrade report — 832-Workflow-designer, AEF 1.8.2 -> 1.8.3 (2026-10-05)

Sent to AEF (sidecar, conversation `aef-release-v1.8.3`) under T-1058.

**Result:** success. Framework 1.8.3, every local fix carried over, doctor clean, own suite 241/0.

| | |
|---|---|
| Path | 1.8.2 (ddf86720) -> 1.8.3 (542623a3), tag pinned by commit |
| Environment | Linux Mint 22.3 (Ubuntu 24.04 base), kernel 6.8.0-146, x86_64, 24 cores, 62 GB, 377 GB free |
| Harness | Claude Code 2.1.289 (Opus 5.5); TermLink 0.12.220; bash 5.2.21, git 2.43.0, Python 3.12.3, Node 22.22.1 |
| Consumer shape | vendored `.agentic-framework/`; 50 local-only files (`.fwvendor-preserve.yaml`); 36 locally edited framework files, declared in a divergence register |
| Method | full clone of the tag; `<clone>/bin/fw upgrade <project> --allow-delete-locals` with FRAMEWORK_ROOT=clone; run by the operator through 832's launcher (rehearsed by the agent, never run by it); pristine commit, baseline advance, then re-apply |
| Time | operator run 15 min (21:18-21:33Z); re-apply + checks ~10 min |

**Per step:** 1 CLAUDE.md unchanged · 2 templates OK · 3 seeds: 2 SKIP (project items), no new cron
· 4 git hooks reinstalled (drops our own pre-commit line; we re-add it) · 4b vendor: 50 PRESERVE, 36
locally edited overwritten by design (backup kept) · 5 hooks: the 3 missing ones added, both project
hooks KEPT — but reported PARTIAL · 6-8 OK · 9 version + trail · 10 baseline WARN (already drifted; the
operator refreshed it after review).

**Carry-over:** 36/36 local fixes re-applied cleanly from the pre-upgrade diff (0 conflicts, 0 adopted upstream).

**Failed / surprised:**
1. Step 5 "PARTIAL … missing 0 hook(s)" -> run ends "1 step(s) failed" although nothing is missing (false alarm).
2. The dry-run does not say the real run will REFUSE (exit 3) on locally edited files; found by reading the vendor code.
3. Git-hook reinstall removes consumer lines from pre-commit (no extension point; 832 T-1000 U1).
4. Manual after-steps: Watchtower restart (T-3877 should cover it next time), hook-baseline refresh.

## Proposal: make this report the last step of every consumer upgrade

End the upgrade protocol with "send AEF a post-upgrade report" (this is one). One screen, optional,
on the release conversation. Fields, and why each helps AEF:
1. **Path**: from -> to version + commit. Which upgrade edge breaks.
2. **Environment**: OS/kernel/arch, harness + version + model, TermLink, bash/git/python/node.
   Correlates failures with platform (today's env -i and socket-stdin bugs were platform-shaped).
3. **Consumer shape**: vendored or not; counts of local-only and locally edited files; register or
   not. Shows which consumers stress preserve and the vendor stamp.
4. **Method**: how invoked, flags (--allow-delete-locals, --strict), who ran it. Reproducible.
5. **Per-step outcome**: the 10 steps as OK/UPDATED/SKIP/PARTIAL/FAIL, one line per non-OK.
   Fleet-wide reliability per step.
6. **Post-upgrade**: doctor, own test suite, and every MANUAL after-step. Each manual step is an
   upgrade gap.
7. **Surprises**: one line each, with a task id. Bug intake.
8. **Time**: wall clock and what dominated. Where it hurts.

Mostly automatable: `fw upgrade` already logs `.context/audits/upgrades.yaml`; a `fw upgrade report`
could pre-fill 1-5 and 8 from that trail plus the environment, leaving 6-7 to the agent.
