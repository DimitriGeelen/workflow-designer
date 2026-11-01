# T-1363 — What real cross-system workflows carry, and how the designer should show it

Research artifact (inception, C-001). Started 2026-11-01 from greenfield's map WT-01 (T-1361). Status: exploration
not started; waiting for greenfield's account of the process (IW-1).

## Starting point

WT-01 ("Walkthrough to-be verkoop — wie doet wat, welke gegevens gaan over") has 25 steps and 36 io contracts, all in
greenfield's free-text form. By kind (agent inventory, 2026-11-01; the map itself is greenfield's data, kept out of
this repo):

- ~13 business objects with their attribute lists (Lead, Account, Contact, Opportunity, Novis organisatie, Tacton
  opportunity, Solution, configured product, Tacton Solution and line items, Sofon2Novis): convert directly to mapping
  v1.1 (typeRef + system + field rows). Proven on the Lead (T-1361: 0 io findings, round trip kept, catalog resolves).
- ~10 free-text data flows: need splitting into objects or naming the single field.
- ~12 not data: screen states, instructions, documents (quote PDF, signed PDF), the TactonEvent.

## What BPMN already offers (to verify, IW-2)

| Kind | WT-01 example | BPMN 2.0 primitive | Designer today |
|---|---|---|---|
| Instruction (what someone does) | "Klikt op tabblad CPQ" | `bpmn:documentation` on the task | kept on save; shown? to check |
| Screen state (what someone sees) | "opportunity zichtbaar met tabblad CPQ" | documentation / text annotation | annotations kept, not shown |
| Document | offerte-PDF, getekende PDF | `bpmn:dataObjectReference` + data associations | kept on save, not drawn |
| System of record | Salesforce, Novis | `bpmn:dataStoreReference` | kept on save, not drawn |
| State change as trigger | signed PDF -> Closed Won -> create order | intermediate message / signal / conditional event | events drawn; no state model |
| System-to-system message | TactonEvent, Sofon2Novis | message flow between pools, or an io object | io object today |

## Greenfield's practice case (received 2026-11-01, owner-approved)

Greenfield's T-373 "practice case for 832" (12885 bytes, sha256 eee87c48…, msg 6914e504) describes the real process
behind WT-01: a build-to-order quoting process across a CRM, a CPQ tool, two pieces of middleware, a legacy order system
and finance, with each system's role and what it is master of; every step with who, which system, and what decides the
next step; every cross-system exchange with object, means and trigger; the documents and which change state; the
state transitions that start other steps; and why WT-01 carries screen states and instructions. The document itself is
greenfield's client data and is kept out of this repo (session scratchpad only); what follows is 832's generalised
reading of it.

**Requirements greenfield draws for the designer (its §6), with 832's first mapping to BPMN:**

| # | Need (generalised) | BPMN 2.0 already has | Gap in the designer |
|---|---|---|---|
| 1 | Documents as first-class items: maker, store, whether they change state (a signed confirmation is the binding trigger; a quote explicitly is not) | `dataObjectReference` (+ `dataState`), data input/output associations | kept on save, not drawn; no "changes state" mark |
| 2 | State transitions as triggers: "transition X in system Y starts this step" | intermediate catch events (message / signal / conditional), event-based gateways | no way to name the source system and transition |
| 3 | Human vs system vs embedded actions (a user click that acts in two systems on the user's behalf) | task types (user / service / send / receive / manual) | no "user-started system action" kind |
| 4 | Status per step (proven / partly / designed / failed + date) and decision status (decided / working assumption / open) | nothing native (extension) | today written into step names |
| 5 | Keys between systems (which id of A is stored where in B) as part of an io | nothing native | mapping v1.1 has `role="match"`; no cross-system key mapping |
| 6 | Several objects on one flow; replace-as-a-set semantics | data associations per object | io supports several objects; no `operation="replace"` |
| 7 | Screen states and instructions visible as non-data: acceptance criteria and human triggers | `bpmn:documentation`, text annotations | to check how documentation is shown and edited |

**Answers so far:** IW-1 answered by the practice case (confidence 2: greenfield's own account, not yet checked against
WT-01 step by step). IW-2: needs 1-3 and 6-7 map onto existing BPMN elements the designer preserves but does not show
or edit; 4 and 5 need an AEF extension. IW-3: all seven are stated as general by greenfield and match the operator's
generalisation request; to be confirmed with a second project's map.

## Dialogue log

- **2026-11-01, operator:** WT-01's io lump bedrijf/naam/e-mail/telefoon/adres/bron/status into one object; an io should
  be one object with a name, a source, and attributes (values at run time). -> T-1361, proven on the Lead io.
- **2026-11-01, operator,** on screen states and instructions: "Workflow is also an instruction for people to do. That can
  be in a command or somewhere"; status "something we can maybe put in our comments"; "the quote in pdf and the signed
  pdf, well that's a state right, and a state creates a state change, it's a trigger point"; "ask Greenfield to explain
  you how the process goes so you understand what we need and also what kind of data exchange between the different
  systems, so you can understand how we need to shape this workflow designer to really support that kind of
  development"; "from this we also want to generalize ... a lot of these things are transferable to other projects".
- **2026-11-01, greenfield (msg ad74698d):** the screen-state and instruction labels were deliberate in the walkthrough
  (what the seller sees and does); a form that keeps them visible as non-data suits them. Holding its generator change
  (its T-372) for the per-io proposal.
- **2026-11-01, agent -> greenfield (msg dfb7c376):** asked for the process start to end, every system-to-system exchange
  (object, means, trigger), the documents and which change state, the state changes that trigger, and what the
  walkthrough labels are for.
- **2026-11-01, greenfield (msg 7a3f87a1):** the five questions need a full description of their client process, more
  than the map the owner approved; asked the owner first. If approved, the answer follows in greenfield's next session.
- **2026-11-01, operator:** greenfield's first send of the practice case failed on its side (credential missing in a hub
  profile); greenfield fixed its local sidecar and resent through its normal route.
- **2026-11-01, greenfield (msg 6914e504):** the practice case, owner-approved ("share as much as is sensible — this is a
  development exercise that should make the designer better for other projects too"). Arrived intact (trailing newline
  dropped in transit; restored, sha matches).
