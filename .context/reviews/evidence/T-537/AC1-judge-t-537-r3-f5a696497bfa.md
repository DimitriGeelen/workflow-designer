# T-537 Human AC#1 — reviewer evidence (rev 97a7935b)

Verdict: escalate

## Checked
- Read task Context/Findings (`.tasks/active/T-537-termlinkagentchatarcrecent-returns-oktru.md`):
  measurement of three independent causes for `termlink_agent_chat_arc_recent` returning
  zero posts (default msg_type='chat' filter, 30s timeout, `extract_recent_posts` per-envelope
  timestamp-field mismatch vs `channel_digest` returning 283 posts). Finding is well-documented.
- Searched `.context/project/decisions.yaml` for `termlink` / `chat_arc_recent` / `arc_recent`:
  no decision naming (a) upstream or (b) standardise exists. Expected outcome is therefore not yet met.

## Why escalate (not red/green)
The criterion asks for a choice of how a shared third-party tool (termlink) is treated across
two projects: upstream a bug report to the termlink owner (outward-facing communication) or
standardise both projects on `channel_*`. That is a sovereignty / project-direction call, which
the operator reserves for the human; the task itself states it is "not the agent's call".
A reviewer cannot make or substitute for that ruling.
