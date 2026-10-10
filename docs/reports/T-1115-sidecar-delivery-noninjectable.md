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

- AEF: sent 2026-10-10, conversation sidecar-delivery-noninjectable, a3709881, RECEIVED; answer pending
- TermLink (`termlink`, /opt/termlink): sent 2026-10-10, same conversation, HUB_ACCEPTED in
  inbox:cacc73ea32b121dd/termlink; answer pending

## Dialogue Log

- 2026-10-10, operator: "our principle design is just failed or incomplete. Our principle design says inject into
  the terminal… please look in the design… is it from TermLink or AEF?… talk to TermLink and AEF agents."
- 2026-10-10, operator: "That should not be a watchdog… 30 seconds is there a new message… call another script…
  verify if the agent is free… then inject it… PTY inject. That is the thing we want. Right?" — Yes: that is
  AEF's design (steps 1-4); 832's session is outside step 2's assumption.
