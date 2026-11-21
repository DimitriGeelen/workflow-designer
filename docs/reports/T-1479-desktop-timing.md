# T-1479 — Where this machine's test time goes (T-1478 step 1 of 7)

Measured 2026-11-21, 22:15-23:00Z: both tiers here, one after the other, on bleeding-edge at the 0.46.0 release
(per-leg times via `T1288_LEGLOG`), against the pool's runs of the release tree 1fb5dc76a (same legs; the trees differ
in documentation and task files only). Raw data: `build/t1479/` (legs-browser.tsv, legs-core.tsv, load.tsv, host.txt).

## The answer

| tier | here, wall | here, sum of legs | pool, sum of legs | here ÷ pool per leg | pool, wall |
|---|---|---|---|---|---|
| browser | 1562 s (26 min) | 1562 s | 1456 s | **1.07** | ~438 s (4 shards in parallel) |
| core | 980 s (16 min) | 988 s | 794 s | **1.24** | 784 s (one job) |

**Leg for leg, this machine is about as fast as the pool** (browser 7 % slower, core 24 %). The difference in wall time
is that the pool runs the browser tier as four shards at once, while this machine runs every leg one after another —
on a host with **24 cores and 96 GB** (`nproc`, `free`), more than all four pool workers together. This is the option
both consultants pointed at ("shard and profile the desktop run itself", codex): splitting this machine's run the way
the pool's is split would take its browser tier from ~26 to ~7 min and core from ~16 to ~4-5 min, before any other step.

**The host is busy.** Load average 25.5 on 24 cores over the run (peak 65.5, 168 samples), from the other sessions on
this machine; at most 12 Chrome processes of ours at a time. Parallel shards here add to that load. This is the risk to
measure first: jobs 173 and 174 each lost one Chrome start to a busy host (infra class, logged), and more parallel
Chrome starts make that likelier.

## The largest gaps, here minus pool

Browser (positive gap 159 s; the top 15 explain 67 %):

| gap | here | pool | share | leg |
|---|---|---|---|---|
| +34 s | 46 | 12 | 21.4 % | `_t396-release-tag-state` |
| +18 s | 21 | 3 | 11.3 % | `_t1017-uid-count-teeth` |
| +11 s | 75 | 64 | 6.9 % | `_t1068-corpus-labels` |
| +7 s | 17 | 10 | 4.4 % | `_t570-meta-carriage-teeth` |
| +5 s | 7 | 2 | 3.1 % | `_t1249-v11-io-cdp` |
| 10 more | | | 19.9 % | +2 to +4 s each |

Core (positive gap 248 s; the top 15 explain 83 %):

| gap | here | pool | share | leg |
|---|---|---|---|---|
| +87 s | 121 | 34 | 35.1 % | `_t1221-guards` |
| +52 s | 89 | 37 | 21.0 % | `_t578-js-comment-edge-census` |
| +17 s | 80 | 63 | 6.9 % | `_t1039-hook-teeth` |
| +11 s | 19 | 8 | 4.4 % | `_t544-session-cookie-port-teeth` |
| +8 s | 10 | 2 | 3.2 % | `_t536-status-desync-teeth` |
| 10 more | | | 12.3 % | +2 to +6 s each |

## Causes of the top five (per tier)

- **Measured: not the 21 GB `build/` tree.** `_t578` walks the repository (`os.walk`, skipping only `.git`,
  `node_modules`, `.agentic-framework`, `.editor-versions`) and so also walks `build/`; but walking `build/` here takes
  0.0 s (6138 files, cached).
- **Not yet separated (two candidates), for `_t578`, `_t1221-guards`, `_t1039-hook-teeth`:** this checkout holds
  36,485 files against 16,911 tracked (the pool's is a clean clone), and the host ran at load 25.5. Which of the two
  explains the extra 52-87 s needs a run of those three legs alone, once on this checkout and once on a clean clone here
  (same CPU load), which the next step can do in minutes.
- **`_t396-release-tag-state` (+34 s) and `_t544`/`_t536` (+8-11 s):** not measured; `_t396` reads tag state, likely
  from origin over the network (the pool's clone is local to its relay); `_t544`/`_t536` start local servers (port and
  start-up time under load). Marked for the same leg-alone run.

## What this changes in the T-1478 plan

1. **New first lever, before T-1480-T-1485's pool work:** run this machine's tiers split too (k parallel shards here,
   with the same time-balanced plans), capped below what the host's load allows. Expected: browser ~26 → ~7 min, core
   ~16 → ~4-5 min, per designer round. Risk: Chrome starts failing on a loaded host; mitigation: start at k=3, measure
   infra-class failures over several runs, keep the infra retry, raise k only on zero failures.
2. **The tree-walking legs** (`_t578`, `_t1221-guards`): if the leg-alone run shows the untracked files are the cause,
   make them walk `git ls-files` (what the pool sees) instead of the disk, which is also the correct scope.
3. The pool steps (T-1480-T-1485) stay as filed; with this machine split, the round is decided by the slower of the two
   at ~7 min each, instead of this machine's ~42 min.
