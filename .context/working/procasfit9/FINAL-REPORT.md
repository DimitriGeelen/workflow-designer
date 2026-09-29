# T-922 — procAsFit 9-round sequential run: final report

Two launches. The first is reported as what it was: one quota refusal counted eight times.
The second completed. **Failed rounds are named below, not averaged into a success count.**

## Launch 1 — 2026-09-28 22:47Z, stopped by a wall it could not see

| round | dispatched | secs | prompt B | handback B | verdict |
|---|---|---|---|---|---|
| 1 | yes | 3831 | 4,872 | 12,514 | **OK** |
| 2 | yes | 1571 | 17,436 | 0 | **FAILED-NO-HANDBACK** — 26 min of real work lost (closed T-882 `162afe3b`, opened T-923), then the session limit |
| 3 | yes | 4 | 17,642 | 0 | **FAILED — never ran.** Quota refusal |
| 4 | yes | 5 | 17,642 | 0 | **FAILED — never ran.** Quota refusal |
| 5 | yes | 5 | 17,642 | 0 | **FAILED — never ran.** Quota refusal |
| 6 | yes | 4 | 17,642 | 0 | **FAILED — never ran.** Quota refusal |
| 7 | yes | 4 | 17,642 | 0 | **FAILED — never ran.** Quota refusal |
| 8 | yes | 5 | 17,642 | 0 | **FAILED — never ran.** Quota refusal |
| 9 | yes | 5 | 17,642 | 0 | **FAILED — never ran.** Quota refusal |

All seven `.out` files for rounds 3-9 are byte-identical (`md5 e721d019e8ab07bdc3a3154a0ac85ecf`),
ending `You've hit your session limit · resets 3:10am`. Seven rounds consumed in 33 seconds
against a known wall. The mandate's own three-attempts clause was broken by the ORCHESTRATOR.
The verdict column said FAILED-NO-HANDBACK eight times: true, and useless, because it cannot
separate "tried and failed" (round 2) from "never ran" (rounds 3-9). **OBS-438, OBS-439.**

Rounds 3-9 were each fed `round1-handback.md` — the last REAL handback, per the AC. The
substitution is recorded here and in `orchestrator.log`.

## Launch 2 — 2026-09-29 07:39Z, nine rounds in order, all handed back

| round | fed | secs | prompt B | handback B | claimed |
|---|---|---|---|---|---|
| 1 | — | 3831 | 4,872 | 12,514 | 13 commits; closed T-880/881/890/892/902/905/906/907; T-866+T-893 partial; T-885 parked; OBS-432…436 |
| 2 | r1 | 2528 | 19,444 | 15,352 | closed T-923 (the inherited half-finished unit), T-883, T-884; filed T-924 |
| 3 | r2 | 3649 | 22,220 | 38,320 | closed T-573; parked T-785, T-826; filed T-925…T-929, OBS-440/441/445/446 |
| 4 | r3 | 243 | 45,286 | 12,564 | committed round 3's orphaned park (`a911daa0`). **Filed nothing. Closed nothing.** |
| 5 | r4 | 164 | 19,530 | 9,270 | committed the orphaned close content of T-891/906/908 (`6723041c`). **Closed nothing.** |
| 6 | r5 | 93 | 16,073 | 5,913 | **nothing.** Handback commit only |
| 7 | r6 | 74 | 12,716 | 5,833 | **nothing.** Handback commit only |
| 8 | r7 | 70 | 12,636 | 6,006 | **nothing.** Handback commit only |
| 9 | r8 | 54 | 12,809 | 5,498 | **nothing.** Handback commit only |

Every round fed the PREVIOUS handback only, never cumulative — the chain is in
`orchestrator-resume.log`. Largest prompt 45,286B (round 3's 38KB handback), within its
asserted arithmetic bound.

## The run's real finding: six rounds measured an identical board

Rounds 4-9 all re-measured the same board and found every above-median candidate
Sovereign-blocked. The WORKERS found this, not the orchestrator — round 6 F2 named it, and
rounds 7, 8 and 9 each repeated it, round 9 as a run-level finding:

> "rounds 4-9 (6 of 9 rounds) re-measured an identical board. Once a round's stop condition is
> 'a Sovereign question blocks every path' and the git log is empty, the next rounds add nothing."

**Four of nine rounds produced no work at all.** They are not failures — each ran, measured,
stopped correctly and handed back honestly. They are rounds with nothing to do, which is a
different and more interesting result: the mandate saturated the agent-executable board after
round 3, and everything left needs a Sovereign ruling. The orchestrator has no stop condition
for that, and a round costs a dispatch whether or not there is work. Proposed by round 9 F4,
NOT implemented (it is the human's call): skip round N when round N-1 stopped on
Sovereign-block AND `git log <prev>..HEAD` holds only T-922 handback commits.

## Worker findings worth the human's eye

- **r3 F1** `tools/_t820-rule-axes.sh` ignores its argument; the whole tree reads it as per-rule
- **r3 F3** T-826 AC 1 and AC 6 contradict each other
- **r4 F2** `fw git commit` bumps `last_update` AFTER the commit, so every close leaves a dirty tree
- **r5 F1** the close path commits the rename but not the close — hit three times
- **r5 F2 / r6 F1 / r7 F3 / r8 F3 / r9 F3** the orchestrator's dispatch census prints bare `T`s
  instead of task ids. Named in four consecutive rounds. **Mine to fix, not a worker's.**
- **r8 F2** `run-log.tsv`'s `dispatched_at` records when a round ENDED. The column name lies.
- **r7 F1 → r8 F1** a worker read `ls` local time as Z and reported the orchestrator building
  prompts out of order. Round 8 disproved it; round 9 confirmed the ordering by timestamp.
  A detector that over-fired, caught by the next round — the chain working as designed.

## Prompt integrity, re-run over the FINAL prompt set

`bash tools/_t922-prompt-integrity.sh` → **21 PASS / 0 FAIL**, denominator 9 prompt files
discovered on disk. Each prompt's bytes [0,4657) hash to the stored mandate, and the mandate
occurs exactly once. Three controls ran FIRST and all fired: a one-byte-changed mandate region
is rejected, a doubled mandate is rejected, one clean copy is accepted. Without the controls a
check that silently matched nothing would report all-clear — the same false green the run exists
to avoid. Rounds 3-9 rebuild their prompts at dispatch, so this is the final set, not the
pre-run set.

## Orchestrator conduct

The orchestrator executed no unit of the mandate. Its only commits are its own tooling
(`cea50a6d` `_t922-prompt-integrity.sh`) and this report. T-923's uncommitted implementation was
left untouched for a worker, and round 2 closed it.

## Found during closeout: the selftest's own control had rotted

Re-running `_procasfit-orchestrate.sh selftest` after the run went **5/5 PASS → 3/5 FAIL with the
detector code untouched**. Cause: the positive-control fixture was `$DIR/round3.out` — an artefact
OF THE LIVE RUN. Launch 2's round 3 succeeded and overwrote it, so the quota-refusal control had
silently become a second clean-output control.

It failed loudly this time only by luck. A successful round's output that happened to contain the
word "limit" would have flipped it the other way: a green light from a fixture nobody pinned. That
is the same defect class as everything else in this run — a check with nothing left to be wrong
about.

Fixed: both fixtures are now immutable copies under `tools/fixtures/`, the refusal one recovered
from commit `33666603` (md5 `e721d019e8ab07bdc3a3154a0ac85ecf`, byte-identical to the original)
and **asserted by hash inside the suite**, so fixture drift fails by name instead of by verdict
flip. Selftest is back to **6/6 PASS**, one leg more than before.

## Two worker-named orchestrator defects, fixed

- **r5 F2, repeated in r6/r7/r8/r9** — the dispatch census printed `T T T T …` instead of task ids:
  `basename` gives `T-923-framework-writer.md` and `sed 's/-.*//'` strips from the FIRST dash.
  Six rounds were handed a field carrying no information, and it never failed loudly — each worker
  fell back to git and grep. Now `sed -E 's/^(T-[0-9]+).*/\1/'`, verified against the live register:
  `T-102 T-101 T-041 T-105 …`
- **r8 F2** — `run-log.tsv`'s `dispatched_at` was stamped by `logrow` at WRITE time, i.e. when the
  round ENDED. Auditing timing against that column compared the wrong instant, which is what sent
  round 7 chasing a phantom out-of-order dispatch. The instant is now captured immediately before
  the model call and passed in.

Both were fixed only after the orchestrator stopped running — bash reads a script incrementally,
so editing a live one corrupts its execution.

## AC 1 is NOT met, and is not ticked

"Feasibility measured before dispatch, not assumed — `claude` present, hub up, and a print-mode
worker proven able to WRITE in this repo, recorded with its evidence." The orchestrator has no such
probe; `grep -n 'feasib|preflight|command -v'` over it returns nothing. Round 1 writing a handback
proves the capability AFTER the fact, which is not the claim the AC makes. Ticking it on that basis
would be the exact substitution this task exists to prevent. It stays open.
