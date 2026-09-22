# T-788 — Does 832 build any part of the workflow→application executor?

**Inception. One question, one go/no-go.** Recommendation as filed: **DEFER**.
Origin: SQ-1 of the Phase 5 value review (`VALUE-REVIEW-repo-2026-09-21.md` §12).

This file is the artifact, per C-001: the thinking trail is written before and during the
research, not reconstructed after it. Conversations are ephemeral; this file is not.

---

## 1. The question, stated so it can be answered wrongly

> Under the operator's confirmed yardstick — *"the workflow designer and its integration with
> AEF and our ability to facilitate the agent and human collaboration to iterate from the
> workflow to actual working applications"* — does **this project** build any part of the
> component that turns a workflow into running work?

Not "should an executor exist." It exists in the specification and the operator's yardstick
makes it central. The question is **ownership**, and it is a scope decision, not a technical one.

## 2. What is already established (evidence, not recollection)

| # | Fact | Source |
|---|---|---|
| E-1 | The forward bridge is **AEF-led**; the frozen standard says *"No translator is built here."* | `docs/standards/aef-bpmn-mapping-v1.md` Part I (frozen, not ours to edit) |
| E-2 | Child-2's translator `tools/bpmn_to_tasks.py` **exists in AEF's tree** | AEF at `agent-chat-arc` @1616, their T-3409 |
| E-3 | Our derived `aef-bpmn-forward-compile-v1.md` **does not exist in AEF's tree** — the drift was ours | same |
| E-4 | 832's four bridge deliverables are **intact** — the consumer-side slice is in place | Phase 5 review F-10 |
| E-5 | `fw workflow` verb, dispatch templates, `policy/prompts` are **absent** here | Phase 5 §2 data-availability map, verified |
| E-6 | The README lists *"usable without `fw workflow run`"* as an **accepted non-goal** | Phase 5 §10, recorded as a contradiction against the yardstick |

The shape of the bridge, as the frozen spec states it:

> diagram → agent-enriched proposed task graph → one sovereignty approval → governed work

E-1 through E-4 say: the middle of that chain is upstream, and our end of it is already built.

## 3. Why DEFER rather than NO-GO

NO-GO would be the tidier answer and it is the wrong one, for a reason worth stating plainly:
**NO-GO forecloses a scope decision the operator has not been given the evidence to make.**

The missing datum is small and specific — *is Child-2 scheduled, or is it hypothetical?* E-2
establishes only that a file exists. A translator that exists as a spike and a translator on a
delivery plan license very different decisions here:

- **Scheduled** → 832 builds nothing of it, defines its consumer-side slice against a known
  interface, and the yardstick is served by integration work.
- **Hypothetical / unscheduled** → the operator has a real choice about whether the path from
  workflow to working application can be demonstrated at all without 832 building something,
  and they should make it knowing that.

Deciding today means deciding without the one fact that separates those branches.

## 4. Why not just build a small one anyway

Because the yardstick puts **F3 AEF_INTEGRATION at 9**, and the most reliable way to damage an
integration score is to build the other side of the seam while the other side is building it.
This project has already paid for the inverse of that mistake once: T-786 corrected a *derived*
document that had reclassified a field the frozen parent owns. The correction was ours to make
because the drift was ours. Building a translator would be the same error with a larger radius
and no frozen document to catch it.

## 5. The unlocking datum, and how it is obtained

**One message to AEF asking for a Child-2 delivery position.** Contacting 999-AEF is mandated,
not gated. Sent under this task — see §7.

This is research, not a build artifact: no code is written under this inception. The Scope
Fence in the task file states what is explicitly out, including the temptation in §4.

## 6. Open questions, as filed

The three IW questions live in the task file under `## Open Questions`, where the disposition
gate can see them. Restated here for a reader of this artifact alone:

- **IW-1** — does Child-2 have a delivery position, or is it a spike? *(confidence 1)*
- **IW-2** — what does AEF expect 832 to hold on the consumer side? *(confidence 1)*
- **IW-3** — is the README's `fw workflow run` non-goal still the project's position, or did
  the confirmed yardstick supersede it? *(confidence 2 — operator's to settle, not AEF's)*

IW-3 is the one that does not go on the wire. It is an internal contradiction the value review
surfaced and only the operator can retire a published non-goal.

## 7. Dialogue Log

### 7.1 → AEF (outbound)

Question put on the wire: *does Child-2 have a delivery position, and what does AEF expect
832 to hold on the consumer side of it?* Full text and rail offset recorded below once sent.

### 7.2 ← AEF (inbound)

Pending. **This section is empty on purpose** — it is not a placeholder to be filled with a
prediction. Nothing here is treated as answered until a reply is quoted inline with its offset
(rail timestamps are not evidence). This project has made the opposite mistake before:
reporting a message as awaiting an answer that had in fact already been answered, and once
describing an unsent draft as sent.

## 8. Decision

**NOT DECIDED.** `fw inception decide` is the operator's, and agents must not invoke it at all.
This file records the recommendation and the evidence behind it; it does not record an outcome.
