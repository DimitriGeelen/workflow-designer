# T-1157: full `fw verify-queue` sweep of the operator review queue (2026-10-14)

OBS-407 (2026-09-27) sampled 5 of 72 queued tasks and found 3 red (T-308, T-310, T-325). The queue has never been
swept whole. It now holds **16** tasks; T-308, T-310 and T-325 have left it since.

## Result

`fw verify-queue --all --json`, one pass: **16 checked, 8 red** (7 fail, 1 timeout), 8 green.

| Task | First sweep | Cause | Class | Carrier | After |
|---|---|---|---|---|---|
| T-189, T-608, T-586, T-423, T-735, T-740, T-696 | green | | | | green |
| T-410 | 1/6 fail | the pin `TEETH PASS — 13/13`; the teeth script has printed 14/14 since T-1009 (bundle B) added a leg | stale verification line | fixed here: pin 14/14 | 6/6 |
| T-593 | 3/9 fail | the legs assert H2 is *unresolved*; the operator answered H2 later (T-595, quoted verbatim in `decision_record`) | stale verification line (the truth moved) | fixed here: a resolution must carry the operator's quoted words. Mutation: with `decision_record` removed, all 3 legs go red again | 9/9 |
| T-597 | 1/7 fail | `_t596-arc0-exit-gate.sh --self-test`: the poison flipped H1 to resolved, but the operator ruled H1 (T-732), so the flip changed nothing and the gate *looked* blind | stale test fixture | fixed here: the poison flips the first question that is still open, and reports SKIP (never a pass) when none is left. 13/13 | 7/7 |
| T-540 | 1/4 fail | "zero `bvp_scores:` in .tasks/"; 33 tasks were scored through `fw bvp confirm` under the operator's T-856 auto-confirm ruling | stale verification line (policy moved) | fixed here: no `bvp_scores:` without the `confirmed_by` stamp the verb writes (0 found) | 4/4 |
| T-703 | 2/4 fail | (a) the dismiss-verb probe expected to CONFIRM the defect; the vendored verb now records the reason and dismissed_by/at (fixed upstream, arrived with T-1167); (b) "census rows == residue now"; T-1149 drained the residue to 0 | stale probe and line (the goal was met) | fixed here: probe reports FIXED; the count check is "residue has not grown past the census" | 4/4 |
| T-884 | 2/22 fail | (a) `_t884-instance-overlay-cdp.mjs` L2: my own T-1168 rename left the expected done-list unsorted (`frw_1_start` now sorts first); the overlay itself was right; (b) `out=$(… snapshot no-such-template)` aborts under the gate's `set -e` because the verb exits 3 by design | (a) test bug (introduced by T-1168); (b) verification line incompatible with the gate | fixed here: expected list sorted; `|| true` inside the substitution | 22/22 |
| T-866 | 2/8 fail | `.tasks/templates/inception.md` has no `## Hypothesis` / success-clause line: the 1.8.2 upgrade (T-1049) replaced the project's template, and T-1053 committed it as leftover state (e8e7e488). T-865's no-default score block went with it. The gate code that expects them survived | **real regression** | **T-1178** | red until T-1178 |
| T-392 | 2/2 fail | `_t392` (13/13 matrix legs) and `_t607` (14/14) pass on behaviour; their poison arms SKIP because the code they mutate is no longer in check-active-task.sh after the T-1167 upgrade | test harness drift after upgrade (behaviour intact, mutation proof lost) | **T-1179** | red until T-1179 |
| T-340 | timeout | its Verification runs the whole bridge suite (`tests/run-bridge-tests.sh`), longer than verify-queue's per-command limit (FW_VERIFY_QUEUE_TIMEOUT, 180s) | environment (timeout), not a failure | suite run separately, below | see below |

## T-340: the bridge suite run on its own

`bash tests/run-bridge-tests.sh`, one run, 2469 s (41 min): **278 passed, 4 failed.** The run overlapped other test
runs and the job-029 Watchtower restart. Each failure re-run on its own:

| Leg | In the suite | Alone | Class |
|---|---|---|---|
| instrument sweep coverage (`_t509`) | a probe killed by its 90 s cap | not re-run alone; the probe it names is `_t525` | load: `_t525` already uses 86 of its 90 s on a quiet machine (T-543) |
| fabric coverage teeth (`_t525`) | 7/8, leg 6a | 8/8 | load-sensitive, the T-1166 class |
| session cookie port (`_t544`) | red | all legs green | load/timing (it starts its own Watchtower instance) |
| divergence drain ratchet (`_t688`) | 42 > baseline 41 | 42 > 41 | **real**: the T-1172/T-1175 page `designer_open.html` was declared `upstream: fix` and never sent to AEF. Fixed by **T-1180** (reported to AEF, b9ede25a), now 41/41 |

So T-340's check (the whole suite) was red for one real reason, now fixed, plus three load failures. Its other
leg, `_t338-input-fidelity-cdp.mjs`, passes. T-340 needs a whole-suite run on a quiet machine to show green. That
takes about 41 minutes, longer than verify-queue's 180 s per command, so T-340 will always show as a timeout in a
sweep.

## Follow-up tasks

- T-1178 (inception template): fixed and closed; T-866 re-verified 8/8.
- T-1179 (poison arms): fixed and closed; T-392 re-verified 2/2.
- T-1180 (upstream report, from the T-340 suite run): fixed and closed.

## What the sweep says about the queue

- None of the 8 reds was a broken deliverable that a reviewer would have approved by mistake. Six were checks that
  went stale when the truth moved (an operator ruling, a later leg, a drained residue, an upstream fix). One was a
  test bug of mine (T-884, from T-1168). One is a real regression the sweep surfaced (T-866's template, T-1178).
- The class is "verification written as a snapshot of the state at close". It goes red when later work changes that
  state, even when the change is the operator's own decision. A pinned count (13/13) or an equality with a census
  is the sharpest form.
- OBS-407's T-308, T-310 and T-325 are no longer in the queue, so they were not re-measured here.
