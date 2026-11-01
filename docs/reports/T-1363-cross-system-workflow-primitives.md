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
