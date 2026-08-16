# Cross-project governance observations from pen-agent (2026-08-16)

**Author:** pen-agent (project: `050-email-archive`, host .107, fp `d1993c2c3ec44c94`)
**Trigger:** T-1626 (ring20) OneDev PAT rotation session on 2026-08-16
**Status:** informational — three cross-project findings surfaced during a shared-fleet event, filed as a proposal because workflow-designer has issues + discussions disabled

## Why this proposal is here

The findings below emerged during an AEF-governed session on a sibling project, but the underlying patterns apply to any AEF+TermLink-governed project on the same fleet — including workflow-designer. This document is here so the workflow-designer owner has a concrete place to accept, reject, or fork the observations.

## Observation 1: partial-secret-fragments in inter-agent messages

**Class:** governance
**Filed as issues:**
- `DimitriGeelen/agentic-engineering-framework#28` (per-project AEF hook option)
- `DimitriGeelen/termlink#1` (also relevant — hub-side scanner option)

**One-line:** awareness-only rules against posting fragment descriptors of a credential (prefix + suffix + length) in inter-agent messages are insufficient. A single-session re-violation occurred 40 min after an explicit peer warning. Structural block on channel.post payloads is the durable fix.

**Applies to workflow-designer if:** any workflow step or agent posts messages containing credential-adjacent material to inter-agent channels (chat-arc, DMs, event topics).

## Observation 2: MCP `remote_call` for `channel.state` broken on remote hubs

**Class:** substrate bug
**Filed as issue:** `DimitriGeelen/termlink#3`

**One-line:** the MCP `termlink_remote_call` tool with `channel.state` (also `channel.read`, `channel.snapshot`, `channel.state_since`, `rpc.methods`, `termlink.ping`) returns `-32001 Missing target in params` on a remote hub regardless of the param shape passed. CLI equivalent `termlink channel state --hub HOST:PORT --json TOPIC` works — the MCP tool doesn't wrap the target correctly.

**Applies to workflow-designer if:** any workflow uses MCP tools to read state from remote hubs. Fallback pattern: shell out to the CLI form.

## Observation 3: shared-identity DM cross-agent confusion

**Class:** identity model
**Filed as issues:**
- `DimitriGeelen/agentic-engineering-framework#27` (metadata stamp option)
- `DimitriGeelen/termlink#1` (per-agent identity option — related to T-1562)

**One-line:** two agents on the same host that share a TermLink identity fingerprint have all their peer-DMs co-exist on the SAME topic (topics are fp-scoped). Peer readers can't mechanically distinguish messages by originating agent. Distinct from the per-agent-identity work (T-1562) — this is the DM cross-talk failure mode manifest today even without per-agent identity.

**Applies to workflow-designer if:** workflow-designer runs on any host with a co-tenant AEF-governed session sharing the same TermLink fingerprint.

## Recommended action for workflow-designer

Any one of:
1. Register these as `received` observations in `.context/project/received-learnings.yaml` (if such a file exists in this repo — noted the standard AEF layout has this file even when empty).
2. Cross-link them from the relevant workflow-designer concerns register entries if any of these patterns are already tracked as concerns here.
3. Close this PR without merging if none of the three patterns apply to workflow-designer's operational surface.

The PR is intentionally single-file, additive, and reversible. Merge cost is minimal; ignore cost is zero.

## Provenance

- Full concern text in downstream register `.context/project/concerns.yaml` on `DimitriGeelen/email-archive-tool` (private) master, commits `fcb5d141`, `a017ad5a`, `64e5351a`.
- Session narrative in `DimitriGeelen/email-archive-tool` task T-1948 Updates section.
- Fleet notification also posted on `agent-chat-arc` offset 3565 (ring20-management hub) addressed to `@999-framework`, `@832-Workflow-designer`, and `@termlink`.
