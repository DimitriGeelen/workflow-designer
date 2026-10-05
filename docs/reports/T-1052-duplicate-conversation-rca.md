# T-1052 — Two live Claude processes ran the same 832 conversation (2026-10-05)

## Outcome first

- **No work was lost.** The second copy did step 3 of the 1.8.2 upgrade (re-apply our local
  fixes) and committed all of it: `444d090b` (re-apply, 43 files, `_t517` clean), `d698db49`
  (project files the upgrade rewrote), `142c4183` (runme.sh for the one new cron job), `318d515c`
  (bridge run 238/1, follow-up T-1051). Re-checked from the surviving copy: `_t517` reports "every
  diverged path is declared, and every declared path still diverges".
- **No collision.** The surviving copy only read files and wrote to its scratch directory while
  the other was working. No duplicate tasks (T-1050 from one copy, T-1051 from the other); the six
  sidecar messages sent today are all distinct.
- **Stopped.** `claude -c` (pid 2677347) and its wrappers are gone; a second `claude-fw -c
  --termlink` wrapper (pid 1437602, suspended since ~14:23) was resumed so its pending SIGTERM
  ended it. One process now runs conversation `500d44d9` (fleet-launched).

## Timeline (local time, from process start times, the transcript and runme.events)

| time | event |
|---|---|
| 13:38:36 | host reboot |
| ~14:17 | fleet cockpit (tmux `fleet-*`) starts `claude-fw --resume 500d44d9… --termlink` — the copy the operator talks to |
| ~14:23 | a terminal shell (bash 1410765) runs `claude-fw -c --termlink`; later suspended (state T) |
| ~15:00 | `claude-fw -c` (pid 2677155, parent 2656345) starts `claude -c` (2677347). `-c` = "continue the most recent conversation in this directory" = **500d44d9, already open in the fleet** |
| 15:05–15:43 | operator runs the 1.8.2 upgrade runme.sh; both copies receive the events |
| 15:43:59 | runme `done` — **both copies start protocol step 3 at the same time** |
| 15:44:47–15:45:12 | the other copy re-applies 41 patches + resolves 3 conflicts in the working tree; the operator's copy, unaware, investigates "an unknown writer" |
| 16:17–17:10 | the other copy commits the four commits above |
| ~17:18 | all 8 fleet sessions are relaunched within ~2 minutes, 055's own first. The operator's copy is cut off mid-tool-call. **Cause not known here** — see questions for 055 |
| after | surviving copy confirms no loss, stops the leftover `-c` wrapper |

## Root cause

`claude -c` resolves "the most recent conversation for this directory" without knowing whether
that conversation is **already live in another process**. The fleet had resumed 500d44d9 by id;
a manual `claude-fw -c` in a terminal picked the same conversation. Claude Code permits two live
processes on one conversation id: both append to the same transcript and both receive the same
background-task notifications, so both acted on the runme `done` event.

## Why it was allowed (structurally)

1. **No single-owner lock per conversation.** Neither `claude-fw` nor the fleet launcher checks
   for a live process on the conversation (or the project) before starting one.
2. **Two launchers, no shared registry.** The fleet starts sessions by id at boot; a human or a
   script starts `claude-fw -c` by directory. Neither sees the other. `-c` is ambiguous by design.
3. **Event wake-ups fan out to every copy.** A runme `done` is a work trigger; with two copies it
   is two workers on one job. Nothing in the protocol (T-1000 step 3) claims the job.
4. **Nothing flagged it.** The duplicate ran ~2h45 before the operator's copy saw evidence
   (files changing under it), and even then the first hypothesis was a tool, not a second self.

## Prevention (proposed)

- **055 / fleet:** before launching a session for a project, refuse (or attach) if a live
  `claude` already runs with that project as cwd or that conversation id; after a reboot, launch
  each project exactly once.
- **claude-fw:** on `-c`, resolve the conversation id first and refuse when a live process holds
  it (`pgrep -f "--resume <id>"` plus any `claude -c` with the same cwd), naming the holder.
- **832 (T-1050 scope widened):** session start reports any other live `claude` process with this
  project as cwd, by pid and launcher, in the session-start check.
- **Protocol:** step 3 of the re-vendor protocol takes a claim (a lock file under
  `.context/working/`) before writing, so a second worker stops with a named holder.

## Questions for 055 (only the fleet can answer)

1. What started `claude-fw -c` at ~14:23 (bash 1410765) and ~15:00 (parent 2656345)? Is any
   fleet path (restart, re-attach, a fallback when no session id is known) using `-c`?
2. What relaunched all 8 fleet sessions at ~17:18, 055 first?
3. Does the fleet keep a registry of which conversation each project's session runs, and can it
   refuse a second launcher for the same project?
