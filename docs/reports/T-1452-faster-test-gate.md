# T-1452 — Faster test gate: measured before adopted

Operator, 2026-11-19: chose both levers ("1 + 2") after the T-1447 session showed ~2 h for one visual task, and then:
"we need to test and evaluate the results … we don't know until we do it … and measure it, as we have the eight step
protocol". The protocol is 1409's **"Der Kreis"** (1409-sprind CLAUDE.md, their T-6317; sent to us in msg 49026d6b):
0 expect, 1 be able to test, 2 telemetry on every run, 3 evaluate against the expectation at a fixed time by a named
owner, 4 recognise the improvement with a named cause, 5 implement (each change with its own expectation, scope of
observation and way back), 6 evaluate the improvement in operation (confirmed / reverted / undecided), 7 again.
Five questions before any start, four safeguards; 1409's lessons (i)-(v) below are taken as rules.

## Step 0 — expectations (committed BEFORE any measurement)

### Baseline (from our own logs, 2026-11-13 .. 2026-11-19, completed gate runs)

| Gate | designer/high-risk: pool AND here | normal: pool alone |
|---|---|---|
| browser tier (`build/tiergate/tier-browser.runs.log`) | median **25.0 min** (n=14, 22.0–34.9) | median **23.5 min** (n=2) |
| core tier (`.context/working/prepush-core.runs.log`) | median **18.8 min** (n=21, 13.8–30.8) | median **13.2 min** (n=8) |

Disagreements between pool and here: 0 real ones in the runs logs. Known pool-side failures that were not product reds
(`build/tiergate/rerun-notes.log`): Chrome not starting on pool-w2 ("no devtools port"), 2026-11-17 and 2026-11-19.

What this already says: the long part is the pool run itself (~22 min browser). Dropping the local run (lever A) can
only remove the wait for the slower local run and the host contention it causes.

### Lever A — designer changes (`src/aef-workflow-designer.html`) on the pool alone

- **Expect:** browser gate median 25.0 → **≤ 24 min**; core gate median 18.8 → **≤ 14 min**. Correctness: in shadow
  mode, the local run (still executed, NOT gating) agrees with the pool on **every leg** for **10 of 10** designer runs.
- **Measured by:** gate wall time from the runs logs (start line → verdict line), per run; per-leg agreement from the
  two tier logs.
- **If missed:** browser saving < 1 min and core saving < 3 min → not worth losing the second machine: revert (keep
  both). Any real disagreement (a red one machine shows and the other does not, not an infrastructure failure) →
  stop, keep both machines, and the disagreement becomes its own task.
- **Scope:** only `src/aef-workflow-designer.html` leaves `tools/pool/high-risk.re`. The validator, the test runner,
  the gate and pool tooling and the vendored framework stay two-machine (a change to the machinery that judges must
  not be judged by that machinery alone).

### Lever B — the browser tier split over k pool workers

- **Expect:** pool browser run 22 min → **≤ 13 min with k=2**, **≤ 9 min with k=3**, measured end to end (submit →
  verdict), not compute only. Correctness (safeguard a, never traded against speed): the split run gives **the same
  result for every leg** as an unsplit run of the same commit, **10 of 10** paired runs.
- **Measured by:** sections of each job (1409 lesson iv): staging and upload, queue wait, start, compute, return —
  ring20's `node_times` in every result plus our own timestamps; per-leg results compared by name.
- **If missed:** end-to-end saving < 5 min at k=2 → find the section that eats it (1409 found 2 min compute inside
  10 min of waiting, mostly on the submitting machine) before adding workers; any leg differing → shadow continues,
  nothing gates on split runs.
- **Rule from 1409 (ii):** shadow first — split runs only compared, never counted for a push, until 10/10 agree.
- **Rule from 1409 (v):** a refused or failed pool job is read at once and named; no silent waiting.

## The five questions (an empty answer means: do not start)

1. **Can we see what happened, also when something expected does not come?** Each gate run writes a start and a
   verdict line; a start without a verdict within 60 min is itself reported (to be added: today an aborted run leaves
   only a start line).
2. **Do we measure it, and what value do we expect?** Wall time per run, per section for pool jobs; values above.
3. **Does the measure carry — the goal, not only the quantity?** Speed AND per-leg agreement; agreement is its own
   guard and is never netted against speed.
4. **How does it come back to us, when, and who sees it?** A small report (`tools/_t1452-gate-times.py`, to build)
   over the runs logs and pool results, run at every session start; evaluated by the agent after 10 designer runs
   per lever, and reviewed by the independent reviewer (safeguard d: the builder does not judge alone), then shown
   to the operator.
5. **What happens then?** Expectation met → standard (CLAUDE.md rule updated); missed → revert as written above;
   undecided → 10 more runs. Each outcome is checked by the next 10 runs keeping the measured value.

## Measurements (raw; evaluated only at 10 runs per lever, step 3)

| # | When (UTC) | Commit | Gate | Pool (node, compute) | Here (compute) | End to end | Note |
|---|---|---|---|---|---|---|---|
| 0 | 2026-11-19 20:47 | 558214e5f | core, push (pool AND here) | pool-w2, 744 s | 899 s | 985 s (16.4 min) | first run with the bundle chain (T-1453); before T-1452 changes anything |
| 0b | 2026-11-19 21:18 | 558214e5f | browser, pool alone (submit.sh) | pool-w1, 1197 s | — | 1222 s (20.4 min) | only ~25 s outside compute: the older chain links were reused, not re-staged (1409 lesson iv) |

### Lever B shadow trials (browser tier, 2 shards on pool-w1 + pool-w2, then the whole tier)

| Trial | Commit | Shard 1 | Shard 2 | Whole tier | Slowest shard / whole | C1-C3 (same legs, none twice, same outcome) | Note |
|---|---|---|---|---|---|---|---|
| 1 | d4dbbb17 / 47bfe503 | 793 s, STOPPED after 55 legs | 396 s, 71 legs | 1328 s, 142 legs | — | shard 2: 71/71 same | shard 1 hit a leg that uses another leg's output (`$T423_ADD_EXP`): fixed (3e70420f); shards from two commits (I committed mid-trial): not comparable |
| 2 | 3e70420f (whole: 01e72ba4, docs/tasks only) | 891 s, 72 legs, 879 leg-s | 409 s, 71 legs, 395 leg-s | 1336 s, 143 legs | **67%** (expected ≤ 13 min = 58%): missed | **pass** 143/143 | cause named: legs split by COUNT, so shard 1 got the slow ones (879 vs 395 leg-s); step 4: balance by measured leg time |

| 3 | 9ea72270 (all four jobs) | 671 s, 71 legs, 659 leg-s | 589 s, 72 legs, 578 leg-s | 1330 s compute / 1343 s end to end | **50%**; shards end to end **706 s (11.8 min)** vs 1343 s (22.4 min): **met** (≤ 13 min) | **pass** 143/143, C4 pass | first trial on the time-balanced plan (`tests/shard-plan-browser-2.tsv`); counts as balanced run 1 of 10 |

Rule learned (1409 iii, like with like): during a trial, commit nothing; `submit.sh` stages HEAD at submit time.

Lever A data point (core gate on a designer push, 2026-11-19 23:13Z, 01e72ba4): pool-w1 615 s, here 1673 s (host busy),
push 1849 s end to end: the gate waited 21 min for the local run that the pool had already answered.

Before this, the pool had been giving no result since ~18:40Z (T-1453: one-file limit, then unstaged chain links): runs
in that window are excluded from the baseline as not comparable (1409 rule iii).

## Dialogue Log

- 2026-11-19 operator: "Why the review rounds taking so incredibly long …" → explanation: ~1 h of discarded test
  runs and 5 review rounds (2 of them from the agent's own misses), plus the 22–35 min gate per attempt.
- Operator: "1 + 2 yeah it sounds like a really good idea … we could even use multiple pool workers".
- Operator: "but we need to test and evaluate the results … we have the eight step protocol, ask 1409" → asked 1409
  (msg 7252b782); answer 49026d6b (Der Kreis, five questions, four safeguards, lessons i–v).
- Measurement of the baseline (above) shows lever A saves little on the browser tier; lever B carries most of the gain.
