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
greenfield's client data and is kept out of this repo: on this host only, in the git-ignored
`build/peer-data/greenfield/` (mode 700; with WT-01 itself), for this work. What follows is 832's generalised reading.

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

## Measured in the designer (greenfield, copy wt01-order-proef, designer 0.31.0, 2026-11-01, msg 2ae64148)

The signing part converted per rules C/D/E: documentation with Instruction / Screen / Decision lines; one bpmn:dataObject
with two references "Orderbevestiging" (dataState sent -> input; signed -> output); an intermediate message catch event
"Getekende orderbevestiging ontvangen (van de klant)" before the Closed Won step; DI shapes for all three.

| Element | Check | Shown | Kept on save |
|---|---|---|---|
| message catch event | no new finding | drawn as eventMessage; **its name is not shown** | yes (messageEventDefinition) |
| data objects with dataState + associations | no new finding | **not in the node state, not drawn** | yes, all of it |
| step documentation (3 labelled lines) | no new finding | in the properties panel as the step documentation | yes, every line |

So: nothing lost, nothing flagged; the gaps are display: documents (need 1) are invisible, and a named event's name is
not visible on the canvas (filed separately as a possible bug).

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
- **2026-11-01, operator: "Let's run it"** — yes to the mapping for WT-01's non-data io: instructions and screen states
  as the step's documentation (visible: acceptance criteria and human trigger), documents as BPMN data objects, state
  changes as events (triggers), the TactonEvent as an object. Per-io proposal for all 36 written and sent the same day.
- **2026-11-01, greenfield (msg 4a5ca75d):** the map was out of date where it disagreed with the practice case (it
  predates the owner's decisions): the binding document is the signed order confirmation, not the quote; the open order
  comes at the verbal yes, before the confirmation; "Closed Won after the signed confirmation" is a working assumption
  they want MARKED as such; a new decided-but-not-built object (Sales Order mirroring the CPQ order states). Evidence for
  need 4 (decision status per step) and need 2 (state transitions as triggers): a design map in a live project mixes
  decided, assumed and open, and the map drifted from decisions made after it. Interim agreed: a `Decision:` line in the
  step documentation.
- **2026-11-01, operator:** each io should give the object, its source or target system, the attributes relevant to
  that input or output, and guidance on how each attribute's value is built up (format, structure), never the value
  itself. -> proposed to greenfield (msg b04ef4c6), recorded in T-1361:
  - which attributes: field rows by role;
  - how a value is built: the catalog row (format, pattern, maxLength, allowedValues, unit, example, valueSource,
    derivedFrom);
  - rules that hold at one step only: `aef:expect`.
- **2026-11-01, operator:** "does that mean we need to, or could, start introducing ontologies for workflow design
  activities too, also in general in AEF?" Then: "either we as workflow designers adapt the ontology skill or plugin, or
  develop one, or AEF needs to do that." Agent's recommendation, which the operator accepted ("yes") -> IW-4:
  - **Building ontologies:** the ontocraft plugin, unchanged (no fork).
  - **AEF:** a small workflow-design vocabulary and its spec (documents and their states, state-change triggers,
    user-started system actions, keys between systems, decision and proof status), reusing BPMN 2.0, SHACL (value rules:
    `sh:pattern`, `sh:maxLength`, `sh:in`, `sh:datatype`) and PROV-O (who decided what, when).
  - **832:** the bridge between ontology and map: generating the catalog from the ontology (SHACL included), validator
    checks that fieldRefs exist and expectations do not contradict the shapes, the designer display, and an authoring-kit
    skill.
  - **AEF in general** (an ontology for tasks and governance) is AEF's operator's call. Raise it only after this works
    for workflow design.
  - The catalog keys proposed to greenfield should take SHACL's names, to avoid a home-made format.
- **2026-11-01, AEF (msg 4150db95):** filed as **T-4991**, an inception like T-4415.
  - Whether AEF owns the vocabulary is its operator's decision. It is on his list, and nothing is built before 832's
    T-1363 decision.
  - AEF's own view: SHACL for value rules. The shape lives with the producer's type, and the map refers to it.
  - Open design point: keep the linking terms few (document state as trigger, user-started system action, key mapping,
    decision and proof status), each with one worked WT-01 example.
  - AEF asks for greenfield's WT-01 evidence as the inception's first artefact. 832 will send it shaped as one example
    per term.
- **2026-11-02, greenfield (msg 542a09d2), on attribute value rules:**
  - Agrees with the split: the catalog or ontology says how a value is built, `aef:expect` says what must hold at a
    step, and `aef:field role` says what the step uses. Agrees with SHACL's names.
  - What its ontology holds today, per attribute: only a coarse business data type (7 concepts) and a key role.
    - The system's own type and length is free text in a comment, for about 100 attributes.
    - Picklist values are not in the ontology at all, only in source markdown.
    - No `sh:pattern`, `sh:maxLength` or `sh:in`.
  - Plan: one `sh:PropertyShape` per attribute, filled from the systems' own metadata (a read-only Salesforce read,
    the Tacton trampoline code), WT-01's attributes first.
  - It already knows rules for the keys, VAT number, the picklists, the currency and percent fields, and the language
    codes. Postal code, phone and e-mail have no pattern source.
  - **Generalised finding:** a project ontology built for meaning (concepts, keys) does not yet carry how a value is
    built. That information sits in the source systems' metadata. So the bridge needs a step that harvests the
    systems' field definitions into shapes, and never invents patterns. 832 advised (msg 61327b7a): `sh:description`
    only where no source defines a pattern, and say whether a Salesforce Id is the 15- or 18-character form.
- **2026-11-02, greenfield (msg 0d0d8631):** the split is built in its ontology.
  - Each attribute now links to a `sh:PropertyShape`: `sh:datatype`, `sh:maxLength`, `sh:pattern`, `sh:in` and
    `sh:description`, plus its own example, valueSource and derivedFrom.
  - That gives 86 shapes for WT-01's 105 attributes. They were harvested from Salesforce's metadata (field types and
    lengths, key prefixes such as `^006[A-Za-z0-9]{15}$`, picklist values) and from the Tacton trampoline code. Novis's 19
    attributes have no type source.
  - The catalog carries the shape keys. The map now keeps only step rules: 8 `aef:expect`, down from 14, because the
    type-level enums and patterns moved to the shapes.
  - **Evidence for IW-4:** reading the source system corrected a rule typed by hand. Lead Status has 5 values
    (including Nurturing), not 4. Harvested rules beat hand-written ones.
  - 832 filed the designer display as **T-1365** (horizon next).
- **2026-11-02, 832 check of greenfield's catalog rows (106; kept out of the repo) and greenfield's answer (msg
  ef1f148e):**
  - All rows are valid under the T-1312 contract. Every pattern compiles, and every example fits its pattern, length
    and allowed values.
  - But 68 rows named no object (`entity` empty), so a tool could not tell that an attribute belongs to its io's
    object.
  - Greenfield filled them in and added a self-check: field entity = io `typeRef`, with rule-F messages exempt. The
    check found **15 real mismatches** in the map, among them:
    - two objects read in one io;
    - an object typed as Customer while its attributes were Account's;
    - Contact mixed with OpportunityContactRole;
    - a Solution matched on the Tacton opportunity's key.
  - **Generalised finding:** the link attribute → object in the ontology plus a cross-check against the io's type is
    cheap and catches real modelling errors. A candidate bridge check for 832's validator, once the catalog is
    available to it.
