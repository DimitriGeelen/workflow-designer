# T-526 — Bridge suite determinism, measured

**Date:** 2026-08-15 · **Subject:** `tests/run-bridge-tests.sh` (94 legs) · **N = 5 consecutive runs**

## Why this was run

OBS-256 records three compounding properties of the bridge suite: no scheduled caller, not
deterministic under repetition, and growing in cost. Installing a caller is operator territory
(it means `/etc/cron.d`, outside the T-559 project boundary). Determinism is not — and it is the
prerequisite, because scheduling a suite whose reds cannot be trusted automates the production
of noise that gets dismissed.

## Correction to the record, made first because it changes the task

OBS-256 (19:00Z) claims the differing leg "was never identified by name". That was true of
OBS-250 (08:59Z). It stopped being true at 11:51Z, when **OBS-255 localised the flake** to
`tools/_t358-teeth.py` case 5. OBS-256 was filed seven hours after OBS-255 and asserted the
question was still open; the same false claim went to AEF at rail 11924, and was corrected to them at rail 11929.

The cause is structural rather than careless: the inbox holds 30 pending observations with **no
cross-referencing**. Nothing links entries on the same subject and nothing flags a new entry
that reopens a resolved one. Both entries read as `pending`, so the contradiction is invisible;
OBS-250 and OBS-255 sit four entries apart in the same file. This gets likelier as the inbox
grows, which is the direction it is going. Registered separately — the remedy is a design
question (does the inbox gain linking, or does triage become mandatory?) and not an agent's call.

## Method

`N=5` consecutive runs, each captured to its own file, wall-clock recorded per run, `git status
--porcelain` captured before the first and after the last. The harness lived in the scratchpad
and was **not committed**: adding an uncalled diagnostic to `tools/` in order to diagnose an
uncalled suite would be the same defect one level in (PL-182), and would move the T-451 census
ratchet off 67 for a script that runs once.

## Result — the matrix

| Run | Wall | Tally | Verdict | Failing leg |
|-----|------|-------|---------|-------------|
| 1 | 315s | 94 / 0 | GREEN | — |
| 2 | 312s | 94 / 0 | GREEN | — |
| 3 | 306s | 93 / 1 | **RED** | `aef:uid collision behaviour` (T-518, `_t518-uid-collision.mjs`) |
| 4 | 305s | 93 / 1 | **RED** | `instrument sweep` (T-509, `_t509-instrument-sweep.sh`) |
| 5 | 306s | 94 / 0 | GREEN | — |

**2 of 5 runs red. Two DIFFERENT legs. Neither reproduced.** No leg failed twice; no run failed
for the same reason as another. This is materially worse than "a flake" in the singular — the
suite's red rate is 40% and its per-leg reproducibility is zero.

Neither failing leg is `_t358-teeth.py` case 5 *by name*. Run 4's failure is the T-509 instrument
sweep, which executes all 24 teeth scripts **including `_t358-teeth.py`** — so it may well be
OBS-255's flake reported one level up. **This is not determinable from the record**, for the
reason given below, and that is the finding rather than a caveat.

## The enabling defect: 62 of 66 legs discard their evidence

- `report FAIL` calls: **66**
- `show_output` calls: **4**

T-326 diagnosed exactly this and wrote the reason into the source: *"fatal for an intermittent
one: the run that failed leaves no evidence of its own cause, so the flake is reproducible-only
and never diagnosable."* It then wired the remedy into **4 legs**.

Both failures in this measurement are uninvestigable from their own output. The T-518 leg runs
`> /dev/null 2>&1`. The T-509 sweep leg printed its `[FAIL]` line and nothing else, though its own
message advertises that the sweep "names the script and its rc" — true only if a human re-runs it
by hand, which requires the flake to still be there.

**Of the 10 CDP/browser-driven legs, 6 discard output entirely** — `_t511`, `_t513`, `_t515`,
`_t518`, `_t520`, `_t523`. Those six are precisely the **AEF-seam conformance probes** (rails
11833, 11882, standard §6.3, rail 11891, gap 2, subProcess nesting). The legs carrying our
promises to AEF are the ones that leave nothing behind when they fail, and one of them flaked here.

Each was written by copying the previous probe's invocation line, `>/dev/null 2>&1` included, so
T-326's remedy never propagated past the leg that prompted it. Same shape as T-508 and T-509: a
fix applied to the instance that raised it while the population grew around it.

This is why OBS-250 could not name the differing leg and why OBS-255 called past occurrences
uninvestigable. It is not a record-keeping accident — 94% of legs throw the evidence away by
construction.

## Hypothesis refuted: cron contention

`git status` was **not** identical before and after: `.context/audits/cron/2026-08-15-2130.yaml`
and `-2145.yaml` appeared. The tree cannot be held still while the suite runs, because a
15-minute cron writes into the repository — and a 310s run overlaps one write about a third of
the time. That makes scheduled-audit contention the obvious suspect for CDP browser-launch death.

**The timing refutes it, and in fact anti-correlates:**

| Cron write | Falls inside | That run was |
|---|---|---|
| 21:30:02 | run 2 (21:28:35–21:33:47) | GREEN |
| 21:45:04 | run 5 (21:43:58–21:49:04) | GREEN |

Both red runs (3 and 4, 21:33:47–21:43:58) contained **no** cron write. At N=5 the most
available explanation is disconfirmed rather than merely unsupported. The cause remains open.

## Cost: the recorded figure is stale by ~2×

OBS-256 cites 168s, from T-509. Measured here: **305–315s, mean 309s**. Cost has roughly doubled
since that figure was recorded, consistent with the browser-per-CDP-probe shape identified at rail
11924 — a constant fault whose consequence scales (PL-222), not decay.

## Limitations, stated rather than assumed

- **The tree was not held still.** Beyond cron, T-526's own task file was edited mid-measurement.
  The runs remain comparable and the reason is evidenced, not asserted: the file is untracked, so
  `git status --porcelain` renders it identically regardless of content, and the one real risk —
  a new `## Verification` line tripping the G-015 hygiene leg — did not materialise, as that leg
  is green in all five runs.
- **N=5 is small** for a 40% event. It is enough to establish that failures occur and that they do
  not repeat; it is not enough to rank causes.
- **The harness's own per-run tally line is wrong** and was not used. It counts `[PASS]` lines
  (132) rather than legs (94); the authoritative figure is the suite's closing `bridge round-trip:`
  line. Recorded because a count that looks like coverage and is not is the defect this project
  keeps finding, and the harness reproduced it.

## What this does not do

It does not fix anything. What the right fix is depends on whether the non-determinism is
instrument-side or subject-side, and **that question cannot currently be answered**, because the
evidence needed to answer it is discarded by the legs in question. Restoring the evidence is
therefore the prerequisite, and is filed separately.
