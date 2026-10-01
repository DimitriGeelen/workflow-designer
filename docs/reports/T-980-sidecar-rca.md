# T-980 — Why the peer-consult sidecar never works for 832, and works for the agents that built it

**Task:** T-980 (inception, RCA) · **Date:** 2026-10-01 · **Trigger:** operator: *"I really want
to find this to the bottom. What is, how come this is overlooked? This is essential for
interactive communication ... you need to help your engineering upstream agent to solve that."*

Every claim below was measured on this host today; the command or file:line is given.

---

## 1. Symptoms

| symptom | evidence |
|---|---|
| `fw sidecar inbox` shows nothing | returns `{"consults": [], "dm_posts": []}` |
| the real inbox holds 79 consults, never read | `inbox:cacc73ea32b121dd/832-Workflow-designer`; cursor `@0`; AEF nudged up to 10 times per consult |
| every consult we send is signed `.agentic-framework` | `fw sidecar status` -> `agent: .agentic-framework`; ledger rows from today's sends |
| sends report success and are never read | 4 sends, all `INJECTED_NOW, delivered:true`; 0 acknowledged; `expired unswept` 3 + 1 |
| nothing ever warned | no hook, no audit line, no handover line, no doctor line |

## 2. The causal chain: seven defects, each sufficient on its own

### D1 — identity comes from the FRAMEWORK directory, not the project (AEF)
`lib/sidecar/outbox.py:36` `_root()` returns `FRAMEWORK_ROOT`, else `Path(__file__).parents[2]`.
`lib/sidecar/circuit.py:145` derives the project id as `outbox._root().name`. In a **vendored**
install that directory is `<project>/.agentic-framework`, so the id is `.agentic-framework` in
every consumer project. Sends are signed with it; the inbox read is for it.
Proven: `FRAMEWORK_ROOT=/opt/832-Workflow-designer python3 .agentic-framework/lib/sidecar_cli.py whoami`
-> `832-Workflow-designer`, inbox topic correct, 79 consults visible.

### D2 — the consult-surfacing hook ships but is never installed (AEF)
`agents/context/sidecar-inbox.sh` (T-3407) is a UserPromptSubmit hook that surfaces pending
consults at each turn. `lib/init.sh` writes the other hooks and never registers it; our
`.claude/settings.json` has **zero** UserPromptSubmit hooks. It exists in every consumer as an
unwired file.

### D3 — the hook cannot parse what the CLI returns, and fails silent (AEF)
The hook requires a JSON **list** (`if not isinstance(msgs, list) ... sys.exit(0)`).
`fw sidecar inbox --json` returns a **dict** `{"consults": [...], "dm_rails": [...]}`.
Measured: the hook's own parser fed the real 79-consult inbox prints **0 bytes**. Its design
rule "SILENT when empty / FAIL OPEN" cannot tell an empty inbox from a changed contract, so
even with D1 and D2 fixed it would stay silent.

### D4 — the escalation sweep runs only for AEF (AEF)
The 5-minute sweep (T-3418) that advances unacknowledged consults is in
`/etc/cron.d/agentic-audit-999-agentic-engineering-framework` only. Our cron file has none, so
an unread send from 832 never escalates (`expired unswept` stays forever).

### D5 — listeners exist only for agents declared in TermLink's own config (TermLink)
`notify-sidecar-supervisor.sh` starts the agents listed in
`/opt/termlink/.context/cron/notify-sidecar-agents.conf`: `claude-termlink`,
`framework-agent-systemd`, `claude-termlink-alt`. Nothing declares 832 or Ring20.
`notify-sidecar.sh:46` defaults `SELF_PROJECT=010-termlink`. A listener only writes a local flag
file; the agent must also check that flag (D2's job), so even a listener alone would not wake us.

### D6 — one shared host identity, receipted by someone else (TermLink)
All local projects post DMs as the shared host key `d1993c2c3ec44c94`. TermLink's
`claude-termlink` sidecar watches that key with `--auto-confirm`, which posts a delivery receipt
and mirrors the message into **TermLink's** journal. Observed: our DM to Ring20 at offset 72 was
followed by receipts at 71/73 from `(010-termlink)`. Mail addressed to "this host" is marked
delivered on behalf of whichever project runs the sidecar, not the one it was for.

### D7 — Ring20 does not read sidecar inboxes at all (Ring20)
`inbox:cacc73ea32b121dd/proxmox-ring20-management` contains only our 3 posts, ever. Ring20
converses on DM topics keyed by its own fingerprint `9219671e28054458`
(`dm:9219671e28054458:d1993c2c3ec44c94`), which is where Pen reaches it. Ring20 also vendors
AEF, so D1-D4 most likely apply to it as well.

## 3. Why it was overlooked

**The mechanism works exactly where it was built, and was never run where it is used.**

- AEF's own repo is not vendored: there `FRAMEWORK_ROOT` *is* the project root, so D1 yields
  the right name. TermLink's listener defaults to TermLink's project. The two agents the operator
  sees "working" are the two producers. Every vendored consumer is deaf, and no test runs the
  sidecar from inside a vendored consumer.
- **Every guard reads through the same broken identity**, so each reports healthy from its own
  vantage: `fw sidecar inbox` (empty), the audit's `check_sidecar_ledger` (reads the
  `.agentic-framework` ledger), the hook (silent by design). None can see the real inbox.
- **`delivered:true` measures transport, not reading.** The sender sees success; the reader's
  absence is invisible. The only party that noticed was AEF, whose nudges landed in the inbox
  nobody read.
- **Fail-open silence** (D3) is the same defect class this project kept finding all day: a check
  confident because it has nothing left to be wrong about. "Empty" and "broken" produce the same
  output.

## 4. Fixes, by owner

| # | owner | fix | how it is proven |
|---|---|---|---|
| D1 | AEF | derive the project id from `PROJECT_ROOT` (or the `.framework.yaml` project name), never from the framework dir; refuse to send if the id resolves to `.agentic-framework` | `fw sidecar whoami` in a vendored consumer prints the project name |
| D2 | AEF | `init`/`upgrade` register `sidecar-inbox` as a UserPromptSubmit hook; `fw doctor` fails when it is absent | a consumer settings.json carries the hook after upgrade |
| D3 | AEF | the hook accepts the dict contract; unparseable output prints a visible one-line warning instead of nothing; a contract test feeds it real `inbox --json` output | 79 consults in -> 79 surfaced |
| D4 | AEF | the consumer cron installer includes the sweep | `expired unswept` drains in a consumer |
| — | AEF | `fw sidecar e2e` runs inside a vendored consumer in AEF's CI | the e2e passes from a vendored tree |
| D5 | TermLink | a consumer project can declare its own listener (or vendoring declares it) | a listener for 832 appears and heartbeats |
| D6 | TermLink | `--auto-confirm` must not receipt mail for the shared host key on behalf of other projects; per-project identities | a DM to 832 is receipted by 832 |
| D7 | Ring20 | read its sidecar inbox, or publish that it is reachable only by DM | — |

**Local, ours, now:** a documented workaround (OBS-469/470):
`FRAMEWORK_ROOT=/opt/832-Workflow-designer python3 .agentic-framework/lib/sidecar_cli.py <cmd>`
for sidecar, and `termlink channel dm 9219671e28054458 --send ...` for Ring20. Patching the
vendored files here would be lost at the next upgrade and is the operator's call (vendor
divergence); the fix belongs upstream, and the next bleeding-edge upgrade is where it lands.

## 5. Dialogue log

- **Operator:** *"Seems happy with other agents too."* Correct, and it is the key fact: it works
  for the two producers and for no consumer.
- **Operator:** *"you need to help your engineering upstream agent to solve that."* This report,
  and a pickup sent to AEF with it.
