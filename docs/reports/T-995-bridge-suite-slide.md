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

### Spike 4 — IW-3: who consumes the suite's result (ANSWERED, confidence 3)

Every place that could act on a red suite, checked on 2026-10-02:

| consumer | acts on the suite? | evidence |
|---|---|---|
| task completion (P-011, update-task.sh) | no | no reference to the suite or its history |
| release (`runme.sh`, `release-designer.sh`) | no | 0 references; 0.15.0, 0.15.1 and 0.15.2 were all cut at 38-40 failures |
| pre-push hook | no | it runs the `structure` audit section only |
| cron `bridge-suite-age-daily` (T-917) | reports only | prints age / red duration; it chose deliberately NOT to run the suite (its description already records "twice exited 0 while reporting 9 failures (OBS-430)") |
| audit rail `check_bridge_suite_ratchet` (T-952) | WARN only, and **now gone** | present in HEAD's vendored `audit.sh` (4 refs), **0 in the working tree**: the uncommitted T-988 re-vendor overwrote it. The cron audit carried "Bridge suite: failures ROSE — 38 against a floor of 32" at 2026-10-01 23:00 and in none of the 70 cron audits since 01:00 on 10-02. T-952's own comment predicted exactly this ("likely after any re-vendor"). |
| observation inbox | captured, not acted on | **OBS-430** (urgent, 09-28) states the rc-0 anomaly; still `pending`, among 124 pending / 46 urgent observations |

So: the result was **seen four times** (the T-917 cron description, OBS-430, the T-952 ratchet
and its audit WARN) and **acted on zero times**. Every consumer is a reporter. The only one in
the audit was removed by a re-vendor, silently, in less than a day. The suite has a leg that
detects that removal, and it is one of the 38 failures, so the alarm about the missing alarm is
inside the thing nobody reads.

**Structural learnings (candidates for the decision):**
- **F4. A signal with no consumer that can say no is decoration.** Four layers each reported
  the redness; none could block anything. At least one gate that matters must refuse on a rise:
  the release (`runme.sh` preflight: no release while the suite is above its floor or STALE),
  which is cheap and outward-facing.
- **F5. A local rail in a vendored file is erased by the next re-vendor.** T-952 knew and wrote
  it down, and it happened within a day. A project-owned check must live in a project-owned file
  the vendor never overwrites (a project audit hook or plugin directory that `audit.sh` sources),
  or be upstreamed. For AEF upstream: give consuming projects an extension point for audit
  checks, so they never patch `audit.sh`.
- **F6. An urgent observation can sit for days.** OBS-430 named the exact defect on 09-28. The
  inbox's urgent flag has no deadline and no escalation. 46 urgent items means "urgent" carries
  no information. Candidate: urgent observations older than N days surface in the handover's
  first section and in `fw doctor` as a FAIL, not a count.

### Spike 1 — IW-1 and IW-2: attribution (IW-1 DISSOLVED, IW-2 ANSWERED, confidence 2)

**IW-1 dissolves.** Lead L-a ("9 -> 30 at the same commit in 3 minutes") compared a pipe-killed
partial sweep (71 checks, rc 0, Spike 3) with a full one. It was never an environment effect.
Spike 2 (rerun at d43b09a0 with and without services) is therefore not needed. Environment-
dependent legs do exist (a live Watchtower for T-568, a browser for the CDP probes), but they are
not what drove the slide.

**The real curve:** 7-10 failures (09-22 to 09-24) -> the T-840 re-vendor to AEF 1.7.68 on 09-25
(1407 vendored files changed, 545 of them carrying local commits; T-944) -> 29-32 from 09-27 ->
35-40 since. A second re-vendor (T-988, AEF 1.7.740, uncommitted in the working tree since
10-01) has started the same cycle: it already erased T-952's audit rail.

**IW-2: the 38 failing legs of 2026-10-02, grouped by what they test** (by each leg's message and
target; not re-verified leg by leg, hence confidence 2):

| class | count | legs (abridged) |
|---|---|---|
| vendored framework (`.agentic-framework/`: update-task.sh, audit.sh, observe.sh, web/, lib/) | **24** | P-011 gate, T-943 heading states, T-574, fw note, episodic pipefail and extractor, vendored-divergence (x2), T-949 triage, T-952 ratchet rail, fabric validate/coverage/_t525, T-568/T-569 card cache and markdown, 403 htmx, hx-prompt encoding, D2 review queue, audit trend, gaps closure gauge, BVP (x2), T-344, approvals queue |
| designer (ours: src/, bridge, tests) | **9** | round-trip fixed point (plain-task fixture), editor↔bridge (T-490), meta carriage (T-570), bridge vocabulary (T-572), swallowed-failure (x2), third-party byte identity, render check (artifact; passes since 0.15.2 was cut), release immutability (T-994, a test defect) |
| project tooling / task hygiene | **5** | unwired-guard backlog, G-015 carrier, T-509 instrument sweep, capture helper, absence census |

**About two thirds of the red is local fixes to the vendored framework that a re-vendor reverted.**
T-944 diagnosed exactly this on 09-30, including that the upgrade had removed the audit rail
that would have reported it (T-657). Two days later the next re-vendor removed the next rail
(T-952). **The pattern was diagnosed and then recurred, because the diagnosis produced fixes,
not a change in how re-vendoring works.**

## The answer to the question

The suite slid because **the project patches its vendored framework in place and then
re-vendors over the patches**. Each re-vendor silently reverted local fixes and removed the rails
that would have reported it. That is about 24 of the 38. Nothing stopped it, because:
- every consumer of the result only **reports** (F4);
- the one report in the audit lived **inside a vendored file** and was erased with the rest (F5);
- the observation that named the rc-0 defect **sat unrouted** (F6);
- **the record itself could lie**: a pipe-killed partial sweep recorded rc 0 (F1-F3), and the
  ratchet built to stop decay set its floor at the decayed value (L-c).

## Recommendation: GO, as these build tasks (each one deliverable)

| # | change | owner | from |
|---|---|---|---|
| B1 | **Runner record integrity.** rc from a completion flag, not `$?`; trap PIPE; every non-final exit recorded `partial`; full log to a file plus a summary on stdout (nothing worth piping); the ratchet rejects `rc 0 && fail > 0` as impossible | project | F1-F3 |
| B2 | **A consumer that can say no.** `runme.sh` preflight refuses a release while the ratchet reports RISE or STALE (override only with a logged reason) | project | F4 |
| B3 | **Project rails out of vendored files.** Restore the T-952 rail in a project-owned audit extension that `audit.sh` sources, not in `audit.sh`; same for T-657 | project | F5 |
| B4 | **Re-vendoring becomes a gated operation.** Before an upgrade is committed (T-988 now), `_t517` divergence runs and every STALE local fix is resolved: adopted upstream, re-applied, or upstreamed. The upgrade does not land with STALE entries | project + operator (T-988) | F5, T-944 |
| B5 | **Re-anchor the floor** after B1, B3 and B4, to a measured full run, with the known-good 7 (09-22) recorded beside it as the target | project | L-c |
| U1 | **Upstream to AEF:** (a) an audit extension point so projects never patch `audit.sh`; (b) the EXIT-trap `$?` pattern (F2) in any framework script that records history; (c) urgent observations that age past N days surface in the handover and as a `fw doctor` FAIL (F6); (d) re-vendor tooling that runs a divergence check and refuses on STALE local fixes | AEF | F2, F5, F6 |
| — | **Triage OBS-430 now:** answered by this inception | agent | F6 |

The designer-owned 9 are not part of this decision. Each gets its own bug task ("one bug = one
task"), starting with the round-trip fixed point and editor↔bridge, which guard the save path
Evergreen's maps go through.

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
