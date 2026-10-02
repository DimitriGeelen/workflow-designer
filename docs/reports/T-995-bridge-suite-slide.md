# T-995 — Why did the bridge suite slide from 7 to 38 failures in 10 days without being stopped?

**Type:** inception (one question, one go/no-go) · **Opened:** 2026-10-02 · **Asked by:** operator
("Do three, make the separate inception … very important. Probably there are structural
learnings for the framework to be taken out of it.")

## The question

`tests/run-bridge-tests.sh` (~166 checks: validator and bridge, the designer in a browser,
Watchtower, guards on the vendored framework) went from **7 failures on 2026-09-22** to **38 on
2026-10-01**. A ratchet (T-952) was added on 09-30, but it recorded 32 as the floor, which accepted
the slide instead of stopping it. The question is not which tests fail. It is **what let a regression
suite lose a third of its green in ten days, while every session kept working, committing and
closing tasks.** The answer is wanted as structural learnings for the framework, not as 38
individual fixes.

## Evidence so far (from `tests/.run-history.tsv`, no investigation yet)

| when (UTC) | passed | failed | rc | commit | note |
|---|---|---|---|---|---|
| 09-22 13:42 | 131 | 7 | 1 | 7fe65e0b | baseline |
| 09-22 15:12 | 133 | 10 | 1 | bcc780bc | |
| 09-24 22:51 | 142 | 9 | 1 | 2a841f3f | |
| 09-25 15:21 | 120 | 21 | 143 | b4c722f9 | killed (timeout): partial |
| 09-27 12:16 | 71 | 9 | **0** | 5583a51f | **rc 0 with 9 failures, 71 checks** |
| 09-27 12:19 | 71 | 9 | **0** | d43b09a0 | same |
| 09-27 12:22 | 121 | 30 | 1 | d43b09a0 | **same commit, 3 min later: 9 -> 30** |
| 09-27 12:31 | 122 | 29 | 1 | d43b09a0 | |
| 09-27 13:59 | 120 | 31 | 1 | a906f337 | |
| 09-27 14:45 | 119 | 32 | 1 | f0c84765 | |
| 09-29 07:54 | 116 | 35 | 1 | 1aec93b0 | |
| 09-30 18:50 | 125 | 32 | 1 | cf4e503b | ratchet floor recorded here |
| 10-01 17:37 | 122 | 40 | 1 | 665b52d8 | |
| 10-01 17:55 | 124 | 38 | 1 | 665b52d8 | |
| 10-02 14:08 | 128 | 38 | 1 | 4db14034 | after T-993 (net 0) |

Three leads:

- **L-a. Same commit, different result.** 9 -> 30 at d43b09a0 within three minutes. The committed
  code did not change, so the cause was outside it: a service (Watchtower, browser), the
  uncommitted working tree, the vendored framework copy, or the runner itself.
- **L-b. A suite that said success while failing.** Two runs exited 0 having recorded 9 failures over
  71 checks (about 40% of the suite). Either rc was wrong, or the run stopped early and reported
  clean. Either way, for those runs a green exit code was a lie.
- **L-c. The ratchet accepted the slide.** It was built to stop decay, and it set its floor at the
  decayed value (32) instead of at the last known-good one (7). Nothing in its design asks when
  the decay began.

## Hypotheses (= the task's open questions IW-1..IW-4)

- **H1 / IW-1 (environment):** most of the jump is environment-dependent checks (browser/CDP
  harness, Watchtower, the hub) that fail when a service is down or another version is running.
  The suite does not tell "the product is broken" apart from "the environment is missing".
- **H2 / IW-2 (vendored framework drift):** a large share is guards that test the vendored
  `.agentic-framework/`. Upgrades (including the uncommitted T-988) change what the guards
  measure, and nobody re-baselined or fixed them.
- **H3 / IW-3 (no consumer):** nothing in the normal work cycle reads the suite's result. Task
  completion, commits, handovers and releases all proceeded at 32-38 failures. A red suite had
  no consequence until 09-30, and then only a ratchet that measures change, not state.
- **H4 / IW-4 (exit-code integrity):** the rc 0 runs (L-b) come from a runner path that can exit 0
  on partial or failed sweeps, so "green" was not trustworthy even when seen.

## Spikes (proposed; none run yet)

1. **Attribute the 31 new failures.** For each check failing now but green on 09-22, find the
   first run where it failed and the commit/state then. Group by cause class: environment,
   vendored drift, real product regression, test defect (like T-994). Output: a table, one row
   per check. Time-box: 2h.
2. **Reproduce L-a.** Rerun at d43b09a0 in a clean worktree, once with Watchtower and the browser
   available and once without. Does the count move with the environment alone? Time-box: 1h.
3. **Explain L-b.** Read the runner's exit trap and the history writer. Under what path does a
   sweep record failures and still exit 0? Write a failing test for it. Time-box: 1h.
4. **Trace the consumers (H3).** Which framework gates read the suite's result today: task
   completion, handover, audit, release (runme.sh), pre-push? Where does the signal go to die?
   Compare with what AEF's framework does upstream. Time-box: 1h.

## Findings

### Spike 3 — IW-4: how a sweep exited 0 while failing (ANSWERED, confidence 2)

**Mechanism, reproduced.** The runner records its history from an EXIT trap with `"$?"` and
traps INT and TERM, but not **PIPE**. When its output is piped into a reader that closes early
(`… | head`, `… | grep … | head -20`), the next write kills the runner with SIGPIPE. The EXIT
trap still fires, `$?` is the status of the last completed command (0), and a **partial sweep is
recorded as rc 0**. A minimal runner with the identical trap logic, piped to `head -5`, recorded
`pass=6 fail=0 rc=0` for a 200-leg sweep; unpiped, it recorded `rc=1`. (The real runner could
not be reproduced in isolation: outside the project it stops at its preflight, and a git
worktree was not permitted. Hence confidence 2, not 3.)

**Who pipes it.** The session transcripts show agents, including this session's, running the
suite as `bash tests/run-bridge-tests.sh 2>&1 | grep … FAIL | head -20` and `| head -12/-20`.
The 09-27 rows fit: about 200 s against 800-1400 s for a full sweep, and an identical 71/9 at two
commits (the same early cut-off point).

**Why it matters beyond two rows.** `tools/_t952-bridge-suite-ratchet.py` treats rc 0 and 1 as
"completed sweep" (`COMPLETED_RCS = (0, 1)`) and never checks that rc 0 means zero failures. So a
pipe-killed sweep can read as a big improvement: "failures fell to 9, floor can be lowered". That
is precisely the false improvement its docstring says it was built to refuse for SIGTERM'd runs.
The SIGPIPE path was never considered.

**Structural learnings (candidates for the decision):**
- **F1. An impossible state was never asserted.** "rc 0 with fail > 0" cannot happen in a
  completed sweep. Neither the recorder nor the ratchet checks it. One line in each would have
  flagged the two rows on the day they were written.
- **F2. A trap that records `$?` records a lie on untrapped signals.** The recorder should write
  `rc` from its own completion flag (set on the final line), not from `$?`, and mark every other
  exit `partial`. This is a general pattern for any framework script that writes history from an
  EXIT trap.
- **F3. The habit of piping a long suite into `head` destroys its result.** It is an agent-usage
  pattern, not a one-off. Remedy in the tool, not in discipline: the runner writes its full log
  to a file and prints only a summary, so there is nothing to pipe; or it refuses to run with a
  pipe on stdout (`[ -p /dev/stdout ]`) unless told to.

## What the decision will be about

GO / NO-GO on a set of **framework-level changes**, each traceable to a spike finding. Candidate
shapes, to be confirmed or discarded by the evidence:

- the suite separates `ENV-MISSING` from `FAIL` (environment absence is reported, not counted as
  a product failure, and not silently passed either);
- an exit-code integrity rule: a partial sweep can never exit 0;
- a ratchet floor anchored to the last known-good run, with the gap shown;
- at least one real consumer: e.g. a release (runme.sh) or task completion refuses on a rise.

Every candidate that survives becomes its own build task, and framework-wide ones become a
proposal to AEF upstream (as T-980 did for the sidecar).

## Dialogue Log

- 2026-10-02, operator: on the bridge-floor options, chose option 3 (investigate the full slide
  from 7 to 32 as well) and asked for a separate inception: "very important. Probably there are
  structural learnings for the framework to be taken out of it."
- The T-988 decision (commit or roll back the vendored upgrade) is still open. Spike 1 must record
  which failures depend on it.
