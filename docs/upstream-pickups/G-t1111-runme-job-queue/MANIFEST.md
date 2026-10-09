# G — runme job queue: several pending operator jobs, one command, a numbered choice (832 T-1111)

**Status:** proposal (no patch series). **Builds on** 832's earlier pickup `c24521a0` (conversation
`runme-launcher`, 2026-10-08, T-1085), which offered the launcher's *safeguards* (definitions-only jobs, a
dry-run sealed by sha256, per-step y/N, done-never-rerun, start/step/done/STOPPED signals). Not answered yet.
This note covers what that one did not: **the queue** — how the operator meets several jobs at once.
**Asked for by:** 832's operator, 2026-10-10: "you wrapped multiple scripts in the runme with a selection
option. That's something the framework doesn't have, but it's a really nice add-on."

## What AEF has today

`fw runme new <name> -- '<cmd>' …` writes one `.context/runme/<name>/runme.sh` per request, and the agent
hands the operator that job's own path. Two requests mean two paths in chat; the operator has to know
which ones are still open, which were run, and in what order.

## What 832's queue does (tools/runme-launcher.sh, test tests/test_t1055_runme_launcher.py)

The operator always runs ONE fixed command, whatever is pending:

    bash /opt/832-Workflow-designer/runme.sh

- **Jobs are numbered folders**, `.context/runme/<NNN>-<name>/job.sh` (`tools/runme-new.sh <name>` picks the
  next number), so the queue has a stable order and a job's name says what it is.
- **Pending = has `job.sh`, has no `done`** (`pending()`, launcher line ~104). Nothing else to maintain.
- **One pending job:** it is shown and run directly. **Several:** a numbered list, `Which job? [1-N]`;
  anything else stops with "no job chosen; nothing run" (lines ~170-181).
- **Each chosen job is re-verified on its own:** never rehearsed → refused; `job.sh` changed since its
  dry-run (sha differs) → refused; preflight re-run → refused if the world changed. A refusal is logged and
  signalled (STOPPED) like any other end, so the agent wakes even on a refused start.
- **A job that STOPPED stays pending**, so it can be run again after the cause is fixed; a job that ran all
  its steps gets `done` and is never offered again.
- `--list` prints the queue with each job's state (`ready` / `CHANGED since dry-run` / `NOT REHEARSED`).
- `--dry-run [name]` (the agent's only verb) rehearses one job or every pending one.

## Real use, 2026-10-08/09 (jobs 005-009)

| Job | What | Outcome |
|---|---|---|
| 005 | install a systemd receiver | done, 3/3 |
| 006 | upgrade AEF 1.8.6 -> 1.8.8 (re-targeted from 1.8.7 before it ran; folder renamed, re-rehearsed) | done, 4/4 |
| 007 | release designer 0.16.0 (cut, commit, tag, push) | done, 4/4 |
| 008 | install a partner's hub credential from a file the operator places | STOPPED at step 1, three times (no file yet); later retired |
| 009 | the same, fetched over ssh as a local account | STOPPED at step 1 (unknown host), then at step 2 (no access); paused |

At one point four jobs were pending at once (006, 007, 008, 009). The operator ran them in the order he
chose, from one command, with the agent woken on every start, step and end.

## Two gaps that real use exposed (worth fixing before AEF adopts it)

1. **The menu shows bare folder names.** The operator picked 008 three times while it was still waiting
   for a file he had not placed, and once picked 008 when he meant 006. Proposal: each line shows the job's
   `JOB_TITLE`, its state (`ready` / `CHANGED` / `NOT REHEARSED`) and its **last outcome**
   (`last run 20:48: STOPPED at step 1 — no /root/x.secret`), so a job that needs something first says so
   in the menu.
2. **No retired state.** A job superseded by another can only be hidden by writing `done`, which reads as
   "completed". 832 wrote a `done` whose text says "RETIRED, not completed: superseded by 009". Proposal: a
   `retired` marker (with reason) that hides the job and is reported as such by `--list`.

## What AEF would need

- A queue directory convention (`<NNN>-<name>/`) and a single entry point (`fw runme` with no argument =
  "run what is pending"), keeping `fw runme new` as the way jobs are created.
- The pending/done/retired rule and the numbered choice; refuse a non-number.
- Per-job re-verification at the moment it is chosen (already in c24521a0's safeguards).
- The menu line from gap 1 (title, state, last outcome).

832's files, free to take: `tools/runme-launcher.sh`, `tools/runme-new.sh`, `tools/runme-signal.sh`,
`tools/runme-watch.sh`, `runme.sh` (the fixed stub), `tests/test_t1055_runme_launcher.py`.
