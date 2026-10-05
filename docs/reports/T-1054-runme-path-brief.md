# T-1054 — Should 832 adopt the framework's `fw runme` for operator commands?

Brief for an external consult (`fw external scan`). Asked for: the strongest objection to the
recommendation below, what would have to be true for it to be wrong, and what the author has
probably not considered.

## Setting

832 is a software project run by an AI coding agent under a governance framework (AEF). Some
commands only the human operator may run (releases, upgrades, approvals). The agent prepares them;
the operator runs them; the agent must learn the outcome without the operator pasting output back.

## The two mechanisms

**A. 832's own (in use since 2026-10-02).** One file, `/opt/832-Workflow-designer/runme.sh`, rewritten
per job. The operator always types the same line: `bash /opt/832-Workflow-designer/runme.sh`.
The script, hand-written per job by the agent:
- states what it will do; checks preconditions before writing anything; `--dry-run` writes nothing
  (the agent runs only the dry run, never the real one);
- asks y/N before each state-changing step (typeahead discarded first);
- logs to a timestamped file and emits `started / step / done / STOPPED` events (EXIT/INT/TERM/HUP
  traps) to a project events file and a message topic;
- the agent arms a background watcher that wakes it on the next event. Since today (T-1050) the
  watcher records which agent session armed it, and the session-start check reports WATCH LOST if
  that session is gone (the incident: the watcher died with its session after a reboot and the
  operator's run started with nothing listening).
Operator rule, verbatim: "put it in runme.sh always !!!".

**B. The framework's (AEF 1.8.2, T-3675 / T-3878).** `fw runme new <name> -- '<cmd>' ...` generates
`.context/runme/<name>/runme.sh`; the agent hands over `bash /abs/path/.context/runme/<name>/runme.sh`.
The script runs `set -euo pipefail`, echoes each command, tees timestamped output to `run.log`,
brackets it with `RUNME START` / `RUNME EXIT <code>`. `fw runme watch <name>` follows it;
`fw runme pending` (new) reports WATCH LOST / RUN IN FLIGHT / RUN ENDED WITHOUT RECORD, built on
832's design. No per-step confirmation, no preflight/dry-run convention, a different path per job.
Maintained by the framework team; other projects use it.

## Recommendation under review

**Do not adopt B. Keep A**, and ask AEF (who offered) to make `fw runme pending` also read 832's
events file, so 832 can retire its local watcher check (T-1050) while keeping its script shape.

Reasons: A gives the operator one constant command and a confirmation at every state-changing step,
which the operator explicitly asked for after a bad experience; a dry run the agent can rehearse is
how 832 caught two real defects in today's upgrade script before the operator ran it (a shallow
clone the framework refuses; files the upgrade would have deleted). B is simpler and shared, but
its generated scripts are fail-fast command lists with no confirmation and no rehearsal path.

## Questions for the panel

1. What is the strongest argument FOR switching to B (or a hybrid) that this recommendation
   underweights?
2. What failure mode does keeping a single mutable, hand-written `runme.sh` carry that B avoids
   (e.g. a script edited while running, an old job re-run, no history of past jobs)?
3. Is asking the framework to read a project-specific events file a reasonable request, or does it
   create a maintenance burden / divergence that will bite later?
4. What would have to be true for "keep A" to be the wrong call?

## Findings — external consult `t1054-runme-path` (2026-10-05, 5/5 answered: gpt-4o, gemini-2.5-pro, grok-4.7, deepseek-chat, qwen-2.5-72b)

**Unanimous: "keep A as it is" is the wrong call.** None argued for dropping the operator's
properties (one command, y/N per step, dry-run, preflight); all argued they sit in the wrong place.

| # | Objection (who) | Holds? | Evidence from 832 |
|---|---|---|---|
| 1 | **Wrong job, right muscle memory**: the operator's command never names the job, so whatever is on disk runs; confirmations only confirm that (grok, gemini) | **Yes — happened today** | During the T-1052 duplicate, the second agent copy rewrote `runme.sh` (cron install, 142c4183) while the first copy had told the operator a different script was waiting |
| 2 | **No immutable record of what ran**: the next rewrite destroys the script; events say `done`, not which bytes (grok, gemini, deepseek) | Partly | every runme.sh is committed before hand-over, so git holds the bytes, but no log records which commit/hash actually ran |
| 3 | **Dry-run not bound to the live script**: an edit after the rehearsal is not caught; no hash ties them (grok) | **Yes** | nothing checks it; today's dry-runs were by whichever copy last wrote the file |
| 4 | **Edit-while-running** splices jobs (all) | Rule only | CLAUDE.md forbids it; nothing enforces it |
| 5 | **Safety logic re-implemented by the agent every job**, on the highest-privilege path (grok, gemini, gpt-4o) | **Yes** | each runme.sh hand-writes preflight, prompts, traps; a forgotten prompt is a silent hole |
| 6 | **Asking AEF to read 832's events file is reverse coupling / debt** (deepseek, grok, qwen; gpt-4o similar) | **Yes** | 3-4 of 5; it also leaves the wrapper problem untouched |

**What the panel points to (a hybrid):** keep the operator requirements, move them into ONE reviewed
wrapper, and make each job an immutable, named artifact:
- each job a data file/dir (`.context/runme/<name>/`), never rewritten after hand-over;
- the wrapper (not each job) does preflight, `--dry-run`, y/N per step, logging, events, and records
  the job name + sha256 at start; the real run refuses a job whose hash differs from its dry-run;
- the operator still types one constant line, and the wrapper names the job and hash before asking.
Better still upstream: propose confirm/dry-run/preflight to AEF's `fw runme` so the shared runner has
them, instead of asking AEF to read our events.

## Disposition
- IW-1: answered — yes; A carries wrong-job (#1, observed today), unbound dry-run (#3) and per-job
  safety re-implementation (#5). Strong enough to change the recommendation.
- IW-2: answered — no; reverse coupling (#6). Withdraw the request; propose the features upstream.

**Recommendation changed: from NO-GO (keep A) to GO on a hybrid** — one reviewed wrapper with the
operator's safeguards, immutable named jobs, hash-bound dry-run; offer the safeguards to AEF's
`fw runme` so 832 can converge on it. The operator decides.

## Options scored (agent's judgment, 0-5; written for the operator, 2026-10-05)

Criteria: the four directives in priority order (D1 antifragility, D2 reliability, D3 usability,
D4 portability) and the value drivers this decision touches: F-AUTONOMY (replace human gates with
at-least-as-safe mechanical ones), F-RECALL (durable, retrievable record), F1 (context fabric /
cross-session memory). F2/F3 are not touched. Effort and fit with the operator rule shown apart.

| | D1 | D2 | D3 | D4 | F-AUT | F-REC | F1 | **sum** | effort (5=none) | operator rule |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 Keep A as is | 2 | 2 | 4 | 2 | 2 | 2 | 2 | **16** | 5 | 5 |
| 2 Adopt AEF `fw runme` as is | 3 | 3 | 2 | 5 | 2 | 4 | 4 | **23** | 4 | 1 |
| 3 Hybrid, built locally, offered upstream | 5 | 5 | 4 | 3 | 4 | 5 | 4 | **30** | 2 | 5 |
| 4 Upstream first; A + quick mitigations meanwhile | 3 | 3 | 4 | 5 | 3 | 3 | 3 | **24** | 4 | 4 |

Recommendation: 3, shaped like `fw runme` (`.context/runme/<name>/`) so it can fold into AEF's runner.
