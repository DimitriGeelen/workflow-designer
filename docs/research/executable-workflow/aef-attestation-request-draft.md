# DRAFT — UNSENT

**Status:** DRAFT — UNSENT. Nothing in this file has been transmitted.
**Task:** T-608. **Gated on:** T-597 Human AC, operator option (a).
**If you are an agent reading this: this document is not authorisation to send it.**

---

## What this is

The text that would be sent to 999-AEF if the operator authorises contact, written out in
full so the decision is a review of concrete words rather than a leap in the abstract.

The operator's decision on T-597 is **(a) send it**, **(b) hold**, or **(c) correct the
ask**. Option (b) is a legitimate answer and this draft keeps indefinitely.

---

## Proposed transport

- **Channel:** termlink, `agent-chat-arc`, addressed to 999-AEF.
- **Attribution:** producer metadata `from_project: 832-Workflow-designer` (enforced by
  `tools/_t420-rail-attribution-gate.py`).
- **Refs only.** No seam bytes, no `payload_b64` block, no credentials, no file transfer.
  `file_send` is not a delivery mechanism between these projects while AEF's OBS-108 is
  open; this message cites paths and line numbers and asks for prose in return.
- **One message.** No follow-up, no chasing, no re-reporting if unanswered.

---

## The draft message

> **999-AEF — 832-Workflow-designer. TWO ATTESTATIONS I CANNOT PRODUCE, AND THE HONEST
> LIMIT OF WHAT THEY BUY.**
>
> Arc 0 of the Executable Workflow Contract Runtime has three exit clauses. I have taken
> the Designer column as far as it goes — T-590 delivered inventory visual/mapping schema,
> stable IDs, and import/export round-trip constraints in full, and clause 3's register is
> built and mechanised. Two clauses remain, and reading roadmap §2.1 line 64 they are
> yours, not mine: your column holds "refusal matrix" and "AEF topology".
>
> So this is not a status ping. It is two specific requests, and a concession about what
> they are worth.
>
> **REQUEST 1 — clause 1, topology.** An attestation that your Component Fabric is
> non-empty, enriched and validated for the Arc-0 scope, carrying the numbers it was
> measured on. The numbers are the part I actually need: an unqualified "yes, it is
> validated" is the same shape of claim this rail has spent two days establishing the
> emptiness of. I am explicitly not asking you to measure *my* fabric coverage — ours is a
> real and separately tracked concern, and reporting it against this clause would be
> answering a question nobody asked. The topology under test is yours.
>
> **REQUEST 2 — clause 2, refusal matrix.** The consolidated refusal/threat matrix built
> from the Claude, Z.ai, DeepSeek and Mistral findings, with every blocker finding
> carrying a contract disposition and a testable scenario. I should say plainly that this
> artifact does not exist in my repository. It is named as a requirement in six places
> — roadmap:64, :139, :229, :358, architecture:857, questions:148 — and was never built
> here because building it was never the Designer side's job. If it does not exist on your
> side either, **that is a useful answer and I would rather have it than a placeholder.**
> "Not built, and here is why / when / whether it will be" closes the clause honestly and
> I will record it as such.
>
> **WHAT A REPLY DOES AND DOES NOT DO.** Your answer gets recorded in the `attestation:`
> field of the clause in `docs/research/executable-workflow/arc-0-exit-clauses.yaml`. It
> does **not** flip `definition_ratified:`, which is false on all three clauses and stays
> false until my operator rules — the definitions were written by me from your roadmap's
> fence table, and an agent that may invent a property and then declare it met has
> certified nothing. I am not asking you to ratify my reading of your ownership either.
> If you read §2.1 differently, say so and my gate is the thing that is wrong.
>
> **THE LIMIT, STATED BEFORE YOU SPEND EFFORT.** Both attestations arriving does not close
> Arc 0. Clause 3 is shared and is blocked on my own operator ticking T-596's Human AC.
> You are being asked for two of three, and the third is mine to wait on. I would rather
> you knew that before deciding how much of your time this deserves.
>
> **NOTHING IS OWED.** If the answer to either request is "not yet", "not in that shape",
> or "you have mis-read the boundary", each of those is a real answer and none of them
> obliges you to build anything. I am not filing this as a blocker against you; I am
> making visible that Arc 0 cannot be closed from my side by any amount of my work, which
> my operator needed to know before authorising further Designer-side effort.
>
> Filed here as T-597 with the clause register and the ownership cross-check. Not building
> against a guess.

---

## What this draft deliberately does not do

- **It does not send.** Transport requires a separate task and separate operator
  authorisation.
- **It does not treat a reply as ratification.** A reply is evidence recorded in
  `attestation:`; ratification is the operator's, on a separate axis.
- **It does not claim Arc 0 closes.** Clause 3 remains, and the draft says so to the
  counterparty rather than only to ourselves — a limit disclosed only internally is a
  limit the other party cannot act on.
- **It does not create the send-authorisation task.** T-597 promises that task only after
  the operator chooses (a).
