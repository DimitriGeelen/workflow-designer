# T-1151 — Should 832 sign with its own TermLink identity?

Inception research artifact (C-001). Origin: OBS-251 (2026-08-15). Exploration done read-only on 2026-10-18: no key was
created, rotated or pointed at, no TOFU or hub state was changed, and no other project's message content was opened
(DM rails were counted by name only). The decision is the operator's: it changes this project's identity on the
fleet.

## Findings

### F1 — The identity is still shared, and more widely than in August (IW-1: answered, confidence 3)

`termlink whoami` (termlink 0.12.665): `Identity FP: d1993c2c3ec44c94 — shared with 126 other sessions on this hub`.
`termlink identity show --resolve --no-create` (the read-only resolver) resolves the same key, the host file
`/root/.termlink/identity.key`; no `TERMLINK_IDENTITY_FILE` / `TERMLINK_AGENT_ID` / `TERMLINK_IDENTITY_DIR` is set
in this session. The framework's own check agrees: `fw rail status` → `state: host … posts are attributed to the
HOST — indistinguishable from co-resident agents`.

Per-project identity is already practised on this hub: the last 15 posts on 832's own inbox topic come from
`aef-greenfield-test` signed `90d4553895d5a9a6`, a key of its own, and `~/.termlink/` holds a separate
`cashweb-integration-agent.key`.

### F2 — What sharing exposes, measured (IW-2: answered, confidence 2)

- **Attribution.** Anything 832 posts on the hub is signed with a key 126 other sessions hold, so a signature proves
  nothing about the sender. Attribution rests on the `from_project` metadata convention, which our hook enforces
  on our posts and no one enforces on anyone else's.
- **Other projects' DMs land in our directory.** `termlink agent dms` lists **28** DM rails on the shared
  fingerprint. They are topics `dm:<peer>:d1993c2c3ec44c94`, addressed to whoever holds the key, so they include other
  projects' conversations (the August case: an AP-fleet operations thread with a credential-custody discussion).
- **Read state is shared too (new).** Unread counts come from the host-wide cursor store
  (`${TERMLINK_IDENTITY_DIR:-~/.termlink}/cursors.json`). The ring20-manager DM showed 12 unread in this morning's
  audit (00:38) and 0 unread now, though this session never read it: another session on the shared key and shared
  store advanced it. So one project reading marks another project's mail as read.
- **What an own key does NOT fix: confidentiality.** DM envelopes are signed, not encrypted (TermLink help: "Post a
  signed envelope"), and `agent dms` finds DMs by filtering all hub topics on the client ("Filters all hub topics
  through dm_list_filter"). No access control is visible in the CLI. Anyone with hub access can still list and read
  any `dm:` topic, whatever key they hold. Confidence 2, not 3: confirming it would mean reading someone else's DM,
  which this exploration deliberately did not do.

### F3 — How 832 would get its own key (IW-3: answered, confidence 3)

TermLink resolves the signing key by environment precedence: `TERMLINK_IDENTITY_FILE > TERMLINK_AGENT_ID >
TERMLINK_IDENTITY_DIR > host default` (termlink PL-236 / T-2324; also documented in the framework's
`lib/rail-identity.sh`, AEF T-2904). The framework already supports a project key: `fw config set RAIL_IDENTITY_FILE
.context/rail-identity.key`, which keeps the key inside the project (AEF D-377: nothing of the project in `$HOME`).

Two traps, both from the framework's own notes:
1. `TERMLINK_IDENTITY_FILE` **creates** the key when the path is absent. It is not a read-only selector; pointing it
   at a path is minting.
2. **Coverage.** In the vendored framework, only `fw rail` (`lib/rail-identity.sh`) applies `RAIL_IDENTITY_FILE`. The
   sidecar (`lib/sidecar/circuit.py`, `dm.py`) calls `termlink` without it. Setting the config alone would leave
   the sidecar, 832's main channel to AEF, signing with the host key. Full coverage needs `TERMLINK_IDENTITY_FILE` in
   the environment of every 832 process that runs `termlink`: Claude sessions and their TermLink MCP server, the
   sidecar receiver, the mail and runme watchers, and dispatched workers.

### F4 — What a switch touches (IW-4: answered, confidence 2)

| touched | effect | evidence |
|---|---|---|
| hub authentication | none expected: the hub authenticates with `hub.secret`, not the signing key | `~/.termlink/hub.secret` is a separate file |
| TOFU pins | none expected: pins are hub certificates (`tofu` tools, "fleet-wide TOFU pin verification across all profiles in hubs.toml") | TermLink help |
| sidecar mail to AEF | addressing unchanged: it is project-addressed (`inbox:<hub>/<project>`, direct receiver), not fingerprint-addressed; signatures change to the new key | `lib/sidecar/circuit.py` |
| DM rails | fingerprint-addressed: new DMs to 832 land on `dm:<peer>:<new-fp>`; the 28 old rails stay where they are and stop being "ours" | `agent dms` |
| read cursors | still shared if only `TERMLINK_IDENTITY_FILE` is set; isolated only with `TERMLINK_IDENTITY_DIR`, which also moves the outbound queue and possibly where TermLink looks for other files (unmeasured: needs a spike) | TermLink help (cursors.json, outbound.sqlite under `TERMLINK_IDENTITY_DIR`) |
| peers | gain nothing until they know 832's new fingerprint; the switch needs an announcement (AEF first) | — |
| the key itself | a secret: must be gitignored, mode 600, never committed (`tools/tracked-secret-artifacts.py` exists for this) | — |

Confidence 2: the hub-auth and `TERMLINK_IDENTITY_DIR` rows are read from documentation and file layout, not
exercised. Exercising them means registering a new identity on the shared hub, which is the act this decision
authorises.

## Options

1. **Own key, everywhere (A).** One project key (`.context/termlink/identity.key`, gitignored, mode 600), applied
   through `TERMLINK_IDENTITY_FILE` to every 832 process that runs termlink, plus `RAIL_IDENTITY_FILE` for `fw rail`;
   announce the new fingerprint to AEF. Fixes attribution and stops other projects' DMs landing in 832's directory.
   Optionally `TERMLINK_IDENTITY_DIR` to isolate read cursors as well, after a spike.
2. **Rail only (B).** Just `fw config set RAIL_IDENTITY_FILE`. Cheap, but covers `fw rail` posts only; the sidecar
   keeps the host key, so attribution stays split by code path (the exact T-2904 finding).
3. **Do nothing (C).** Keep the `from_project` convention. Attribution stays unprovable; 832 keeps receiving
   other projects' DMs and sharing their read state.
4. **Upstream confidentiality (D), alongside 1.** Ask TermLink/AEF for hub-side access control (or encryption) on
   `dm:` topics. That is the only fix for "anyone can read any DM", and it needs distinct keys first (an ACL by
   fingerprint means nothing while 127 sessions share one).

## Recommendation

**GO on option 1 plus option 4**, built in this order:
1. A spike in the build task, with operator approval because it registers a new identity on the shared hub: one
   throwaway session with a project key confirms hub authentication, sidecar delivery to AEF, and what
   `TERMLINK_IDENTITY_DIR` moves.
2. The key minted by a runme job (operator), kept out of git, mode 600.
3. `TERMLINK_IDENTITY_FILE` applied at every 832 entry point, checked by `fw rail status` reading `state: project`
   and a test that every launcher sets it.
4. The new fingerprint announced to AEF; the 28 old DM rails left alone (not read, not deleted).
5. A report to AEF/TermLink asking for DM access control.

Scope note: this makes 832's posts attributable and stops it receiving other projects' DMs. It does not make DMs
private on this hub: that needs option 4.

## Dialogue log

- 2026-10-18: operator chose this inception next ("begin met 1"). Research only, read-only; no operator dialogue on
  the question itself yet.
