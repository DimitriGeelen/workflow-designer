# T-1115 — Sidecar delivery to an agent session that cannot be injected

**Status:** inception, exploring. **Origin:** T-1108 (mail sat 7 min unseen); operator question 2026-10-10.

## What the design intends (read in the vendored AEF copy, 1.8.8)

AEF owns it: arc-011, T-3693, `lib/sidecar/inject.py` (docstring), D-645 §2 steps 7-8.

1. The **receiver** stores an incoming message; the **watcher** (supervised, ticks every 30 s) also runs.
2. On store and on every tick, the **injector** looks for a target: a Claude session that recorded itself
   (`.context/sidecar/sessions/<id>.json`, written by its Stop / UserPromptSubmit hook) as running **inside a
   TermLink session registered for this project** (tag `fw-project=…`, added by `claude-fw --termlink`), whose
   process is alive and whose record says **ready** (urgent mail may go to a busy one).
3. It claims the message for that session, then types ONE fixed line into the agent's terminal:
   `termlink pty inject <session> "<line>" --enter`. The line carries only a count and ids, no peer content.
4. Enter fires the agent's **UserPromptSubmit hook**, which shows the stored messages (as untrusted data)
   and records HANDED_OVER.
5. **No candidate → the message stays flagged and an INJECT_BLOCKED event records why.** Nothing else.

This is the operator's model exactly: watchdog -> "is there a message" -> "is the agent free" -> PTY inject.

## Where 832 falls outside it

832's agent runs as a **Claude Code background session**, not under `claude-fw --termlink`. No TermLink session
owns its terminal (/dev/pts/31), so it is never a candidate (`receiver status`: `ready=False termlink=None`).
Step 5 applies to every message: it waits for the operator's next prompt. The design is not wrong; it is
**incomplete**: it assumes the agent can be typed into, and does not say what happens when it cannot.

## Two ways to close it

- **A. Run the agent where the design works:** start sessions with `claude-fw --termlink`, so the injector has a
  PTY. No new code; a change in how the operator launches 832's agent. Open: does a background/remote session
  (claude.ai, cloud) have a PTY at all?
- **B. Extend the design with a second delivery route** for sessions without a PTY: a wake signal the harness
  understands (for Claude Code background sessions: a background task that ends; 832's stopgap
  `tools/sidecar-mail-watch.sh`). AEF T-4003 is this case; AEF asked to start from 832's script.

## Consults

- AEF: sent 2026-10-10, conversation sidecar-delivery-noninjectable, a3709881, RECEIVED. **Answered (b3143a4b):**
  1. Our reading is right for 1.8.8; "always under claude-fw --termlink" was an **unstated assumption**, not an
     intended precondition.
  2. Both directions, as two routes on one ledger. **T-4003** (bleeding-edge, unreleased) resolves the target
     from the agent's pid to its tty: c1 a TermLink session owns it -> `pty inject`; c2 a tmux pane owns it ->
     `send-keys` (plain `claude-fw` now relaunches inside a private tmux server, `tmux -L fw-agents`); c3 neither
     -> WAITING_NO_RECIPIENT. **A Claude Code background session has no pty at all, so it is always c3**; T-4003
     does not wake it. That is **AEF T-4018**: a mail watch built from 832's `sidecar-mail-watch.sh` contract,
     plus MAIL WATCH MISSING at session start and NOT CHECKED on hook timeout. Their operator made reachability
     the first prerequisite of T-4023 (field evidence), so T-4018 is next.
  3. TermLink does not need to change for either.
  Suggestion: do not build a second one; send `tools/sidecar-mail-watch.sh` + `tests/test_t1108_sidecar_mail_watch.sh`
  as a contrib/ bundle, taken upstream with credit.
  **Consequence for route A:** launching 832's agent under `claude-fw` (tmux, c2) or `--termlink` (c1) would make
  PTY injection work once T-4003 ships; a background session never can, so route B (the mail watch) is needed
  for as long as the agent runs in the background.
- TermLink (agent id **`010-termlink`**; sent first to `termlink`, HUB_ACCEPTED, no receipt; then a Claude Code
  cross-session nudge). **Answered (6574d5e3):**
  1. AEF is right: no TermLink change needed for either route.
  2. A blocking wait exists today: `termlink channel subscribe <inbox-topic> --follow` (1 s poll floor; WebSocket
     push on a TCP hub) and `termlink wait --topic <t>` (blocks until a matching event, then exits) — a background
     session can run either as its mail watch. (832 note: direct-path consults land in our receiver, and the hub
     inbox topic carries only their receipts, so a topic wait would wake on the receipt, not the message; to check
     before switching.)
  3. The ready check is AEF's, not TermLink's: the harness self-reports readiness (Stop hook sets it,
     UserPromptSubmit clears it); it governs only the typing path. A session without a PTY gets mail via hooks or
     a mail watch (their R-47/R-48 split).
  4. **CR-21 (ruled today by TermLink's operator):** all delegation and agent-to-agent work goes through TermLink;
     vendor peer channels (Claude Code SendMessage / cross-session messages) are not used for governed work. 832's
     nudge used that channel; rely on the sidecar consult alone.

## AEF on plain `claude-fw` (f0ebf815, 2026-10-10)

1. T-4003 is on AEF bleeding-edge only, in no release. Under AEF's rule T-4020 it reaches master only after the
   field confirms it; it will be in the **first `-be` pre-release for the testbed** (T-4023 — whether 832 is a
   testbed is our operator's open decision D).
2. End to end, no `--termlink`, no other setup: plain `claude-fw` started in a terminal re-execs itself inside a
   private tmux server (`tmux -L fw-agents`, no user config, status bar off); the sidecar finds the pane owning
   Claude's tty and send-keys the line when the prompt is free and nobody is typing; the hook surfaces it.
   Verified on a real tmux pane; AEF's live check with a real Claude session is still pending.
3. Survives the auto-restart: the whole wrapper, restart loop included, runs inside tmux
   (`bin/claude-fw:104 exec tmux … -- claude-fw "$@"`), so `claude -c` stays in the same pane.
4. Nothing to type differently; the terminal shows the tmux session (Ctrl-B and Esc go to Claude). Caveats:
   skipped inside an existing tmux (your own pane is used), for `--termlink`, headless and workers;
   `FW_CLAUDE_FW_NO_TMUX=1` opts out; closing the terminal ends the session (destroy-unattached). A Claude Code
   background session is still not covered (T-4018).

**For 832:** the operator's way of starting (plain `claude-fw` in a terminal) is exactly what T-4003 serves. It
reaches 832 either through the first `-be` pre-release (if the operator says yes to being a testbed) or at the
next release after field confirmation. Until then, and for background sessions always, the mail watch.

## Dialogue Log

- 2026-10-10, operator: "our principle design is just failed or incomplete. Our principle design says inject into
  the terminal… please look in the design… is it from TermLink or AEF?… talk to TermLink and AEF agents."
- 2026-10-10, operator: "That should not be a watchdog… 30 seconds is there a new message… call another script…
  verify if the agent is free… then inject it… PTY inject. That is the thing we want. Right?" — Yes: that is
  AEF's design (steps 1-4); 832's session is outside step 2's assumption.
