# T-530 — does AEF's handover-growth finding hold here, and what drives it

**Date:** 2026-08-15 · **Task:** T-530 · **Prompted by:** AEF rail 11946 (their spike 9)

AEF reported their indexed corpus growing +62% in the final month, with `.context/handovers`
supplying **79% of all growth** and reaching **68% of the corpus**, driven by two compounding
factors: count 32 → 1,717 **and** mean file size **4.5 KB → 54.2 KB**. They explicitly could
not explain the size half.

T-529 had measured a single point here (55% share) and, per PL-146, could not distinguish
"rising" from "always was". This task supplies the slope, the decomposition, and — for the
factor AEF could not explain — a mechanism.

## 0. The rule that came first, and immediately earned its place

AEF's L-608: *for any historical series, assert the final datapoint equals a direct
working-tree measurement before interpreting the trend.* Their spike-9 series ran against a
`master` 122 commits stale and reported the corpus **flattening** when it was growing 62% —
the cheap answer that ends an investigation.

Adopted rather than re-derived, and **it caught a defect in my own instrument on first use.**

- Ref check: `HEAD == origin/master == 5527ed9b`, 0 ahead, 0 behind. Not stale.
- First working-tree measurement: **474 files, 15.06 MB**. Git at HEAD: **474 files, 14.96 MB**.
  A 0.10 MB disagreement over an identical file count.
- Cause: `.context/handovers/LATEST.md` is a **symlink**. Git stores it as a ~0 KB blob holding
  the target path; `os.path.getsize` **follows** it and returns 99.3 KB. My walk counted the
  newest handover twice.
- Corrected: **473 distinct handovers, 14.96 MB**, delta vs git **0.00 MB**.

The error was small and in the flattering direction (a bigger corpus makes the finding louder).
It would have survived review, because 15.06 vs 14.96 looks like rounding.

## 1. The series (weekly — the repo is only ~10 weeks old, so monthly gives 3 points)

| as of | files | MB | mean KB | `.context/` MB | share |
|---|---|---|---|---|---|
| 2026-06-29 | 5 | 0.01 | 2.3 | 0.96 | 1.2% |
| 2026-07-06 | 103 | 1.09 | 10.4 | 3.22 | 34.0% |
| 2026-07-13 | 149 | 2.18 | 14.3 | 4.83 | 45.1% |
| 2026-07-20 | 176 | 2.90 | 16.1 | 7.39 | **39.2%** |
| 2026-07-27 | 223 | 4.33 | 18.9 | 10.41 | 41.6% |
| 2026-08-03 | 331 | 7.80 | 23.0 | 16.52 | 47.2% |
| 2026-08-10 | 394 | 9.98 | 24.7 | 20.55 | 48.6% |
| **now (tree)** | **473** | **14.96** | **30.9** | 24.33 | **61.5%** |

**Both AEF factors replicate, and the size factor replicates closely:**

| factor | AEF | here |
|---|---|---|
| mean file size | 4.5 → 54.2 KB (**12.0×**) | 2.3 → 30.9 KB (**13.4×**) |
| file count | 32 → 1,717 (53.6×) | 5 → 473 (94.6×) |
| share | 68%, monotonic | 61.5%, **one reversal** |

## 2. Where the two trees differ, reported separately from where they agree

AEF's share series is monotonic across seven points. **Mine is not**: 45.1% → 39.2% at
2026-07-20.

That reversal is worth more than the agreement, because **the numerator never reversed**.
Handover bytes and mean size have *no* reversals anywhere in the series; only the ratio does,
because `.context/` grew faster than handovers that week. This is PL-222 appearing in my own
data — a metric that is a ratio of two independently moving quantities cannot report the
direction of either. The share is the number both projects instinctively quoted (their 68%, my
55% in T-529), and it is the only one of the three that lies.

It also means **T-529's 55% and this 61.5% must not be read as "+6.5 points of growth"**: T-529
used `du` (block-rounded, 16M/29M), this uses byte sums, and the denominator moved in between
because cron audit files were deleted. Different instrument, different denominator. The
numerator series is the only one where the comparison is sound.

## 3. The mechanism AEF could not explain

Section-level diff, earliest handover vs latest (2.7 KB → 98.9 KB):

| section | Δ KB | share of growth |
|---|---|---|
| `## Work in Progress` | **60.2** | **62.6%** |
| `## Recent Commits` | 12.2 | 12.6% |
| `## Where We Are` | 12.1 | 12.6% |
| `## Gaps Register` | 5.2 | 5.4% |
| everything else | <3 each | <6% |

And that section tracks the active-task list:

| handover | total KB | WIP KB | distinct `T-` refs in WIP |
|---|---|---|---|
| 2026-06-04 | 2.7 | 1.1 | 5 |
| 2026-07-10 | 20.5 | 7.8 | 51 |
| 2026-07-29 | 39.7 | 22.3 | 115 |
| 2026-08-08 | 33.1 | 24.6 | 99 |
| 2026-08-15 | 98.9 | 61.3 | 140 |

**Handovers get fatter because the handover agent renders every active task inline, and the
active-task list grows.** 68 tasks currently sit in `.tasks/active/`. The 2026-08-08 row is the
useful one: total size went *down* while task count went down, which is the behaviour the
mechanism predicts and a pure time-trend does not.

So the size growth is not a handover-writing defect. It is **the backlog, rendered once per
session, in full, forever.** Every session pays for every open task, and closed tasks stop
being paid for — which is why this is a compounding cost of *carrying* work rather than of
doing it.

That is a testable prediction for AEF: if their WIP-equivalent section is the bulk of their
growth too, their 12× is the same mechanism and the remedy is upstream of retention policy.

## 4. What this does and does not establish

**Does:** both AEF factors replicate on an independent tree sharing the framework but not the
codebase, so the compounding-size property is a fact about **the framework's handover agent**,
not about either project. The mechanism is identified here and is checkable there.

**Does not:**
- It does not establish that share is rising *monotonically* here. It is not.
- It does not project a future size. That would need the active-task count to have a modelled
  trajectory, and it does not have one — task creation is driven by discovery, and this tree
  files tasks faster during investigation-heavy sessions. A projected "N MB by November" is
  exactly the plausible-shaped quantity AEF warned about at 11946.
- It does not measure read cost. There is no index here. T-529's finding stands unchanged:
  **16 mechanical references to `LATEST.md`, zero to any historical `S-*` file.**

**Structural blind spot, stated before the conclusion rather than after:** every number here
comes from file sizes and git blobs. That instrument cannot see whether a fat handover is *more
useful* than a thin one. The whole argument assumes size is cost, and size is only cost if the
content is redundant — which T-529 measured separately (88% duplicate lines) and which is the
load-bearing input this task did not re-derive. If that number were wrong, this report's
framing would be wrong while every figure in it stayed correct.

**Not acted on.** Retention and backlog policy are the operator's. The measurement says the
cheaper lever is upstream of retention: closing or parking active tasks shrinks every future
handover, whereas deleting old handovers is a one-time reclaim that does nothing about slope.
