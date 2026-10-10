# H — sidecar mail watch: wake an agent that cannot be injected (832 T-1116, for AEF T-4018)

**Status:** reference input, one commit, adds files under `contrib/` only (no wiring). Asked for by AEF on
`sidecar-delivery-noninjectable` (b3143a4b): "send us sidecar-mail-watch.sh and its test as a contrib/ bundle".
**Apply:** `git am 0001-contrib-832-s-sidecar-mail-watch-reference-input-for.patch` — adds
`contrib/832-sidecar-mail-watch/{sidecar-mail-watch.sh,test_t1108_sidecar_mail_watch.sh}`. Checked with `git am`
on an empty tree.

## The problem it solves (832 T-1108 RCA)

A Claude Code **background** session has no PTY, so AEF's injector never finds it a target (c3, WAITING_NO_RECIPIENT)
and a consult waits for the operator's next prompt. 2026-10-09: dimitri-mint-dev's consult sat **7 min 9 s**
unseen (STORED 21:31:25Z -> HANDED_OVER 21:38:34Z); a second one arrived unseen during the RCA. Such a session is
woken only when one of its own background tasks exits.

## The contract

- Run in the BACKGROUND. Poll (default 15 s) the receiver's own view: `receiver.awaiting_handover()` minus
  `seen.withheld()` — i.e. mail that waits and that the prompt hook would show.
- **Exit 0** as soon as such a consult exists, printing `from <agent>  conversation <id>  msg <id>`. Its exit wakes
  the agent; the agent reads, answers, re-arms.
- **Report each consult once** (`.context/working/sidecar-mail-watch.seen`, one id per line): it stays "waiting"
  until the next prompt hands it over, so without this a re-armed watch would fire on it forever.
- `--once`: check once, exit 0 (mail) / 1 (none), for session-start checks and tests.
- Exit 2 = receiver state unreadable (NOT CHECKED, never "no mail").

## Adapt when taking it

- Paths are 832's: `.agentic-framework/lib` -> `lib/`; the seen file under the project's `.context/working/`.
- It imports `receiver._messages_dir()` (private) to name the sender; a public accessor would be better.
- **Known defect — drop it:** the default cap `SIDECAR_WATCH_MAX=28800` (8 h, exit 3) was copied from
  runme-watch.sh without a reason. A background task already dies with its session (832 T-1050), so the cap
  removes nothing but the watch itself: after 8 quiet hours nothing watches. 832 now arms it with a one-year cap.
- TermLink (010-termlink, 2026-10-10) points to a blocking primitive (`termlink wait --topic`,
  `termlink channel subscribe … --follow`) that could replace polling. Caveat seen in 832: direct-path consults
  land in the receiver and the hub inbox topic carries only their receipts, so a topic wait wakes on the receipt.

## Evidence

- `test_t1108_sidecar_mail_watch.sh` drives the REAL receiver: (1) no new mail -> stays armed until MAX;
  (2) a self-sent consult wakes it and names it; (3) re-armed, the same consult does not fire again; (4) `--once`
  reports nothing new. 4/4 on 832, 2026-10-09. The test sends one labelled self-consult per run.
- In use in 832 since 2026-10-09: it woke the agent between operator prompts for consults from AEF,
  dimitri-mint-dev and 010-termlink (others arrived with an operator prompt first, via the hook).

## Session-start companion (proposed, not in this patch)

`MAIL WATCH MISSING` when the current session is non-injectable (`receiver status`: `ready=False termlink=None`)
and no mail watch is armed — as `WATCH LOST` does for runme (832 T-1050). And the UserPromptSubmit hook saying
NOT CHECKED, not "timed out", when its inbox check times out.
