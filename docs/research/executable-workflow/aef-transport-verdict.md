# AEF transport verdict — T-680

**Measured:** 2026-09-05, hub `workstation-107-public` (192.168.10.107:9100)
**Probe:** `tools/_t680-aef-reachability.py`
**Verdict:** the 999-AEF seam is **live**. It was recorded as unreachable. That record was wrong.

---

## What was believed, and why it was reasonable

Three true facts pointed at a dead counterparty:

1. The DM topic to `3bba15e681b3a078` holds 7 rows and **every one is ours**. That fingerprint
   resolves to `framework-agent-systemd` — an idle root bash prompt with no agent consuming it.
   We diagnosed this correctly ourselves at DM offset 7 and deliberately did not inject, because
   prose at that prompt executes as root.
2. ring20-manager measured `agent-chat-arc` as non-federating across hubs (`.122` at offset 3715
   against `.107` at 1022 — disjoint logs wearing one topic name).
3. No session tagged `project=999-Agentic-Engineering-Framework` is discoverable on our hub.

Conclusion drawn: both transports to AEF are dead, so Arc-0 is blocked on plumbing.

**Every step is true and the conclusion is false.**

## What is actually the case

| transport | verdict | evidence |
|---|---|---|
| `agent-chat-arc` | **live** | 66 posts labelled `999-Agentic-Engineering-Framework`, offsets 100–969 |
| `dm:3bba15e681b3a078:…` | no-reader | 6 rows, producers `0503-codex-cli-playground` and `832-Workflow-designer` only |

AEF's clause-1 answer sits at `agent-chat-arc` **offset 650** — substantive, numbered, and
deliberately red on their own measurement (1134 cards; 52 edgeless of 1047 assessed; 749 outside
any watch pattern; *"I would rather hand you a red number I trust than a green one neither of us
can reproduce"*). Their most recent post is **offset 897**, today, replying directly to our 879.

The seam was never broken. **One mailbox is.**

## The mechanism: a shared cohort identity

Every envelope on this mesh carries sender `d1993c2c3ec44c94` — ours. So do 001-CashWeb's,
010-termlink's, and 999-AEF's. Projects distinguish themselves by a **label written into the
payload**, never by key.

```
distinct sender_id on agent-chat-arc : 3
distinct producer labels             : 18
```

Labels outnumber fingerprints six to one. **`sender_id` cannot separate producers on this mesh.**

Any reachability, attribution, or provenance check keyed on `sender_id` is measuring the hub and
reporting the answer as if it were about the counterparty.

## The negative control, and the first version of it that lied

This task's original acceptance criterion said a transport counts as reachable "only on a message
authored by a fingerprint that is NOT ours." Applied to the live seam, that rule classifies 66
substantive AEF posts as our own outbox.

The first control asked *"does any foreign sender post here?"* — and answered **yes**, so the
discarded rule appeared vindicated. It was not. The foreign senders are ring20's. The rule said
`live` because *somebody* was there, not because *AEF* was: the right answer for a broken reason
(PL-177), and it would have certified a seam to a counterparty that had never appeared on it.

The discriminating question is the one the seam depends on — *is 999-AEF present?* Under
`sender_id` that question has **no answer**, because AEF has no fingerprint of its own:

```
999-Agentic-Engineering-Framework posts on agent-chat-arc : 66
of those, attributable to a non-ours sender_id            : 0

NEGATIVE CONTROL: PASS
```

## Federation, measured here rather than quoted

ring20's disjointness claim reproduces independently with our own numbers:

| hub | address | rows | max offset | producers |
|---|---|---|---|---|
| local-test | 127.0.0.1:9100 | 896 | 1095 | 18 |
| workstation-107-public | 192.168.10.107:9100 | 896 | 1095 | 18 |
| ring20-management | 192.168.10.122:9100 | 1000 | 2715 | 6 |
| ring20-dashboard | 192.168.10.121:9100 | 922 | 994 | 6 |

Two independent logs under one topic name, confirmed. **This does not affect the AEF seam** —
AEF posts to the same `.107` hub we read, so federation was never in that path.

One caveat worth recording: `ring20-dashboard` returned **0 rows on the first run and 922 on the
second, minutes apart**. Nothing was declared dead on that first reading, and nothing should be.

## What actually blocks EWCR Arc-0

Rulings, on both sides. Not plumbing.

- **clause 1 (topology)** — AEF measured it red and *declined to attest*. Not satisfiable now, by
  their deliberate choice, and correctly recorded as their refusal rather than as unsatisfied.
- **clause 2 (refusal matrix)** — AEF calls it a scope ruling for **their** operator: produce the
  DeepSeek/Mistral disposition tables, or rule those findings out of Arc-0.
- **clause 3 (source-of-truth)** — shared, unratified.
- All three carry `definition_ratified: false`, which is **our operator's** ruling to make. An
  agent that may invent a property and then declare it met has certified nothing.

`attestation:` and `definition_ratified:` are untouched by this task.

## The register was never wrong — the reader was

`arc-0-exit-clauses.yaml` required **no correction**. Its `clause-1` block already carried
AEF's offset-650 response in full: timestamp, rail, thread, their commit `d318223`, all four
measured numbers, and their own three-way verdict (`non_empty: yes`, `enriched: no`,
`validated: no`). It was recorded on 2026-08-27 by T-623 and has been accurate ever since.

So the false belief was not inherited from a stale artefact. **It was manufactured by reading
the DM thread and not the clause register** — one dead mailbox, read in isolation, outweighed a
correct record sitting in the repository the whole time. The most recent evidence was the least
complete, and recency won.

That is the actual failure mode here, and it is worth more than the transport verdict: when a
question has a register, the register is the source. A conversation is where the answer arrives,
not where it lives.

## Reproduction

```
cd /opt/832-Workflow-designer && python3 tools/_t680-aef-reachability.py
cd /opt/832-Workflow-designer && python3 tools/_t680-aef-reachability.py --by-fingerprint
```

The second must print `NEGATIVE CONTROL: PASS`. If it ever prints FAIL, the mesh's identity model
has changed and every conclusion above needs re-deriving.

## The learning

Nothing here was repaired. A false belief was removed.

The false belief was produced by three correct measurements and one unexamined assumption about
what a `sender_id` means. This is PL-314 one level up: a reader's compatibility union hides its
*producer's* defect; a shared identity hides the producer *itself* from every check keyed on
sender.
