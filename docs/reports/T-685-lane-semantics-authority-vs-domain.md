# T-685 — Should authority live in the box, and the lane mean domain?

**Type:** inception · **Arc:** arc-002 `ewcr-governed-delivery` · **Opened:** 2026-09-06
**Decision owner:** operator. Agents may not run `fw inception decide` (two gates enforce it).
**Status:** exploration open. No spikes run yet. Nothing here is decided.

> **This document exists because the conversation that produced it is ephemeral (C-001).**
> Everything below emerged in operator dialogue on 2026-09-05/06. The Dialogue Log at the end
> is the primary record; the analysis above it is derived from that record.

---

## 1. The question

One question: **does authority belong in the box (element) or in the lane?**

Concretely: should a step's accountability be carried by `<aef:meta tier= owner=>` on the
element — leaving the lane free to mean *domain* (customer, system, memory) — instead of by
`<aef:laneMeta authority=>` on the lane, which is the sole authority-of-record today?

## 2. Why the question exists now

It surfaced from underneath T-341, not from a design review. T-341 asks where an orphaned node
should land when its `flowNodeRef` is unresolvable. The operator's response to being asked for a
ruling was, in substance: *the lane rationale itself needs strengthening — we assign by role, but
we also have domains, and the role is already on the element.*

That reframes T-341 entirely: **"where does an orphan land" is unanswerable while "what is a lane
for" is unsettled.**

## 3. What a lane means today, and what it cost to make it mean that

`docs/standards/aef-bpmn-mapping-v1.md:97`, v1.1 (IW-9, T-189):

> *"a node's `owner` **MUST** be its lane — there is **no** node-level `owner` override. The Lane
> (its `aef:laneMeta authority`) is the sole authority-of-record for who-performs, compiled via
> the collapse map `sovereignty→human`, `initiative→agent`, `authority→agent`, `external→no
> task`. Task-type (userTask vs service/scriptTask) SHOULD agree with the lane and is
> **presentational** where it does not."*

Two things follow, and both matter:

1. v1.1 **collapsed to two orthogonal axes** — Lane = who-performs, `workflow_type` = kind — and
   **deliberately removed** the node-level `owner` override. This was a decision, not an omission.
2. The payoff is a machine-checkable guarantee: **O-3** makes "an inception's go/no-go boundary
   MUST sit in a sovereignty lane" a **compile-time MUST**. That check is only possible because
   authority has exactly one home.

Any proposal to move authority into the element must pay for O-3 somewhere else.

## 4. The evidence that the lane axis is already carrying two things

Lane names across the 24-map corpus, with their declared authority:

| lane | count | `authority=` | kind |
|---|---|---|---|
| Framework · Authority | 22 | `authority` | role |
| Agent · Initiative | 21 | `initiative` | role |
| Human · Sovereignty | 15 | `sovereignty` | role |
| Working / Project / Episodic Memory | 3 | **`none`** | **domain** |
| Remote host / Source project / Remotes+GitHub · External | 3 | `external` | **domain** |

Six lanes are domains wearing an authority attribute. To fit them onto the axis, someone wrote
`authority="none"` — a value meaning *"this is not an authority."*

### The defect this produced (IW-4, measured, confidence 3)

`authority="none"` is **not in the collapse map** and is handled **nowhere** in the standard or in
`tools/bpmn-cli.py`. Verified by grep on 2026-09-06: zero hits.

`examples/aef-processes/rendered/context-memory.bpmn` carries all three `none` lanes and **12
`flowNodeRef`s**. Those 12 steps have **no derivable owner**, and nothing detects it.

This is the same failure class the project hit four times last week (T-674/675/677/678): a value
that cannot distinguish *"no authority applies"* from *"nobody recorded one."*

**Consequence for EWCR.** The contract promises *"every step traceable to the evidence that
justified it and the operator decision that authorised it."* The lane carries the second half of
that sentence. On this map, for 12 steps, it carries nothing — silently.

### Half the operator's proposal is already built and undocumented

```xml
<aef:meta tier="1" agentType="primary"/>
<aef:meta tier="0"/>
```

`tier` is **already on elements**: 27 at `tier="1"`, 10 at `tier="0"`, across 10+ corpus maps
(`inception-lifecycle`, `arc-lifecycle`, `error-escalation-ladder`, `healing-loop`,
`tier0-escalation`, `assumption-validation`, `git-commit-flow`, `session-capture`,
`task-lifecycle`, `task-gate`). The standard mentions `tier` **4 times** and never as an
authority carrier.

So box-level risk classification is in production use with no specification behind it.

## 5. What the literature says

**BPMN itself declines to help.** The spec's position is that *"Lanes are used to organize and
categorize Activities within a Pool. The meaning of the Lanes is up to the modeler."* Lane
semantics are deliberately undefined; in practice lanes are used for roles, systems, **or**
departments interchangeably. There is no standard to defer to — BPMN offers **one** dimension and
reality has several.

**Common practice (Silver's *Method & Style* lineage)** contributes two rules:

1. Use **stable functional roles**, not job titles or transient org structure. Our
   `Human · Sovereignty` / `Agent · Initiative` naming already complies.
2. Where two dimensions genuinely exist, the BPMN-native answer is **nested lanes** — an outer
   set for departments, inner for roles.

**Directly on our problem:** *"Towards Modeling Human-Agentic Collaborative Workflows: A BPMN
Extension"* (arXiv 2412.05958) introduces `AgenticTask` / `AgenticLane` / `AgenticGateway` as a
**separate dimension**, explicitly to avoid *"conflating role-based organization with
agent-vs-human distinction"*, and treats **autonomy/authority as attributes of elements** rather
than as lane position.

**Note the divergence honestly.** The nearest published work in our exact domain puts authority
**on the element**; v1.1 deliberately took it **off** the element. Theirs is not automatically
right — ours buys a compile-time sovereignty check theirs does not have — but our position is a
minority one relative to the closest literature, and that was a choice rather than an oversight.

Sources: [Signavio — Pools and Lanes](https://www.signavio.com/post/bpmn-pools-and-lanes/) ·
[Camunda BPMN reference](https://camunda.com/bpmn/reference/) ·
[Trisotech — BPMN Style Rules](https://www.trisotech.com/bpmn-style-rules/) ·
[Visual Paradigm — Pools and Lanes](https://www.visual-paradigm.com/guide/mastering-bpmn-pools-and-lanes-for-precision-process-modeling/) ·
[arXiv 2412.05958](https://arxiv.org/pdf/2412.05958)

## 5b. What "domain" means in three bodies of knowledge (IW-1)

Researched 2026-09-06 at operator request, across the three traditions this system actually sits in.

### BABOK / IIBA — domain is a *boundary of change*, and IGOE already splits our axes

BABOK's relevant technique is **Scope Modelling** (10.41): *"Scope models are commonly used to
describe the boundaries of control, change, a solution, or a need."* Domain, in BA practice, is a
**boundary** — not a performer.

More directly useful: BABOK's **Process Modelling** (10.35) names **IGOE** as a scoping notation —
**I**nput, **G**uide, **O**utput, **E**nabler. IGOE separates, for every activity:

- the **Guide** — the policy/rule/constraint that governs how the activity may be performed;
- the **Enabler** — the resource or actor that performs it.

**That is our exact decomposition, arrived at independently.** A guide is not an enabler. What
constrains an action and who performs it are different things, and neither is *where it happens*.

### TOGAF — BDAT, and the direct answer to "is customer the same kind of thing as system?"

TOGAF defines four architecture domains, the **BDAT** set — Business, Data, Application,
Technology — described as *"sub-architectures of a single enterprise architecture"*, i.e. **layers
of one stack, not peers on one list.**

- **Business Architecture** — strategy, governance, organisation, key business processes. A
  *customer* domain lives here.
- **Application / Technology Architecture** — application systems and their interactions; the
  logical software and hardware capabilities beneath them. A *system* domain lives here.

**So: no.** `customer` and `system` are **not the same kind of thing** — they sit at different
BDAT layers. Putting both on one lane axis reproduces precisely the collision this inception
exists to escape, one level up.

### DDD — bounded context, and our problem stated in someone else's vocabulary

A **bounded context** is *"an explicit boundary within which a particular model applies and the
language is consistent. Inside a bounded context, every term has exactly one meaning."* And it is
*"a deliberate decision"*, not something that emerges.

Our lane is a bounded context whose ubiquitous language has broken: **the term "lane" has two
meanings inside one boundary** (authority for 58 lanes, domain for 6). DDD's central claim is that
this is the one thing you must not permit.

DDD's subdomain classification (**core / supporting / generic**) is worth noting for what it is
*not*: it classifies **strategic importance**, to decide where to invest modelling effort. It is a
third axis again — not location, not performer.

### The convergent finding

All three traditions separate the same three things, and **none of them uses "domain" to mean
"who performs":**

| axis | BABOK | TOGAF | DDD | our carrier today |
|---|---|---|---|---|
| **WHERE / what area** | scope boundary | BDAT layer | bounded context / subdomain | *(nothing — squatting in the lane)* |
| **WHO performs** | **Enabler** | actor / role | — | **lane `authority=`** |
| **WHAT constrains** | **Guide** | governance | — | **box `tier=`** (undocumented) |

**Three axes, not two.** The lane is currently trying to be axes 1 and 2 simultaneously, which is
the measured defect in §4. The operator's proposal B maps onto the IGOE decomposition almost
exactly — lane = boundary, box owner = enabler, box tier = guide — which is meaningful independent
support, since IGOE was derived from process-analysis practice and not from our problem.

**The caution it also produces:** because customer and system are different BDAT layers, "the lane
means domain" is under-specified until we say **which layer's domain**. One lane axis still cannot
hold two BDAT layers. That is either a constraint (pick one layer) or an argument for nesting
(shape C).

Sources: [BABOK 10.35 Process Modelling](https://www.iiba.org/knowledgehub/business-analysis-body-of-knowledge-babok-guide/10-techniques/10-35-process-modelling/) ·
[BABOK 10.41 Scope Modelling](https://www.iiba.org/knowledgehub/business-analysis-body-of-knowledge-babok-guide/10-techniques/10-41-scope-modelling/) ·
[TOGAF architecture domains](https://togaf.visual-paradigm.com/2025/02/18/comprehensive-guide-to-architecture-domains-in-togaf/) ·
[TOGAF (Wikipedia)](https://en.wikipedia.org/wiki/TOGAF) ·
[Subdomains and Bounded Contexts](https://www.arhohuttunen.com/domain-driven-design-bounded-contexts/) ·
[Nick Tune — Domains, Subdomains, Bounded Contexts](https://medium.com/nick-tune-tech-strategy-blog/domains-subdomain-problem-solution-space-in-ddd-clearly-defined-e0b49c7b586c)

## 5c. The operator's answer on who sets the tier (IW-2)

**Operator, 2026-09-06:** *"it's very good that the agent does that when it's scanning and proposes
or detects. But we have a draft version and we have a final version. So I think as long as it's in
draft, it can be set by anyone. When it is locked, any changes becomes a managed change or becomes
a tier zero decision."*

This is **lifecycle-gated mutability**: agent proposes/detects; free to edit while draft; once
locked, changing a tier is itself a tier-0 action requiring human approval.

**It already has a carrier.** The draft/final split exists in the product today:
`.editor-versions/<id>/vN.bpmn` is the scratch version store, and
`examples/aef-processes/rendered/<id>.bpmn` is the committed corpus, reachable only through the
**existence-or-promotion gate** (T-138) — a new id is scratch and is *not* published unless
explicitly promoted. Draft vs locked is not a new concept to build; it is a concept to *name*.

**Objections that must be resolved before this is a design (open):**

1. **A lock protects a value; it does not validate it.** If a tier is mis-set in draft and then
   locked, the lock defends the wrong value exactly as strongly as the right one — and now costs a
   tier-0 approval to correct. This is the same shape as every other finding this week: a control
   that is *stable* rather than *correct*. **What validates a tier at lock time?**
2. **Who may lock?** If an agent can both propose a tier and lock the document, it can make its own
   guess expensive to reverse without any human ever having ruled on it. Lock authority may need to
   be sovereignty-only.
3. **Determinism holds for a subset, not the corpus.** An agent can derive a tier where the step
   maps to a known consequential operation (CLAUDE.md §Enforcement Tiers names force push, hard
   reset, `rm -rf`). For a general business step — "send invoice to customer" — the tier is a
   judgement, not a derivation. So "deterministic" is true of framework-operation maps and unproven
   for business-process maps, which is most of what a workflow designer is *for*.

## 5d. Operator rulings, 2026-09-06 — and the marriage of the two lenses

**Lenses kept:** BABOK (business lens) and TOGAF (architecture lens). **DDD demoted** by operator
ruling — *"doesn't seem to bring really much here"*. It is retained in §5b only as diagnosis (it
names the disease: one term, two meanings, inside one boundary), not as a source of design.

### The two lenses do not compete — they operate at different granularities

This is the answer to *"can you marry those two concepts in the workflow designer?"*: **yes, and
they don't collide, because TOGAF classifies an AREA and IGOE decomposes an ACTIVITY.**

- **TOGAF BDAT** → a property of the **lane** (which architecture layer this band belongs to)
- **BABOK IGOE** → a decomposition of the **box** (Input, Guide, Output, Enabler)

### And the box is already three-quarters IGOE

Measured in the corpus:

| IGOE | carrier | count | status |
|---|---|---|---|
| **I**nput | `<aef:decisionInput>`, `<aef:io>` | 51, 28 | **on the box already** |
| **G**uide | `<aef:meta tier=>` | 37 tiered | **on the box already** (undocumented) |
| **O**utput | `<aef:output>`, `<aef:io>` | 31, 28 | **on the box already** |
| **E**nabler | `<aef:laneMeta authority=>` | 67 lanes | **on the LANE — the odd one out** |

**Proposal B is not a new pattern. It completes one that is 3/4 built.** Three of IGOE's four
elements already live on the box; only the Enabler was placed elsewhere, and that placement is the
defect §4 measures. This is the strongest structural argument in this document and it was found by
counting, not by reasoning.

### Operator ruling on IW-9 — WHO MAY LOCK

**Answered, confidence 3. Always the human.** Operator, verbatim: *"That's very clear. That's
always human. So the agent can propose. But it cannot lock the document… It cannot publish it as a
ratified document."*

This closes the agent-lock-in objection outright and is consistent with every comparable boundary
in this project (G-007 release immutability; `fw inception decide` agent-blocked; the §ACD gates).

**But it is not enforced today, and that is a finding.** `tools/gallery-serve.py:653` reads
`promote = bool(payload.get('promote')) or ALLOW_NEW_CORPUS` — **`promote` is a
client-supplied payload flag**, and the server has no authentication of any kind. Any caller that
can POST `/api/save`, an agent included, can publish straight into the committed corpus at
`examples/aef-processes/rendered/`. The operator's rule is right; the code does not implement it.
Registered as a gap (G-049) rather than left inside this inception.

### Operator ruling on IW-8 — WHAT VALIDATES A TIER AT LOCK

**Answered, confidence 2.** Validation is **human assessment and experience**, not a mechanical
check, and the control mechanism is **change control**: *"that validation is either problematic or
it's from human or comes from experience… it's an assessment or an experience. So we will and have
to apply change control and we can always apply change control."* Plus: *"human has to approve.
And also change if needed. No, it's not a decoration."*

Accepted. The agent's objection was that a lock over an unvalidated value is decoration; the
operator's answer is that the validating step is the human approval itself, which is a real step
performed by a real assessor, and change control provides the reversal path. The lock is therefore
a **ratchet with a human gate**, not a green check.

### Operator ruling on IW-10 — DETERMINISM, and the agent's objection partly withdrawn

Operator's position: the target use case includes **systems development and software development
workflows**, and human-operator/agent collaboration modelling — *"That's a workflow we definitely
want to support with this."*

**This weakens the agent's own objection and it should be recorded as weakened.** The objection
was that tier derivation works for framework operations (`rm -rf`, force push) but not for
arbitrary business steps ("send invoice"). If the target corpus is systems/software delivery —
deploy, migrate, release, revoke, grant, delete — those steps *do* map onto known consequential
operations, and derivation is far more tractable there than for general business process.

**Residual, narrowed to a design principle rather than a blocker:** derivation must be
**fail-safe**. An agent that cannot classify a step must propose the *higher* tier, never the
lower — over-tiering costs an unnecessary approval, under-tiering silently removes one. Combined
with IW-9 (human always approves) the risk is bounded, but only in the safe direction.

## 5e. The fourth axis — executor kind (deterministic / stochastic / authority)

Raised by the operator 2026-09-06: *"there is a distinction between the stochastic response and
the deterministic execution… we want something to be picked up by the agent or we want something
to be executed by machine. Where the machine is deterministic and the agent is stochastic and the
human is tier zero authority."*

### It exists in three places today and is authoritative in none

| carrier | coverage | status |
|---|---|---|
| BPMN task type — `scriptTask` 111, `serviceTask` 40, `userTask` 12 | 163 tasks | **explicitly demoted** — the standard calls task-type *"presentational"* where it disagrees with the lane (§3) |
| `aef:meta agentType=` — `framework` 4, `primary` 9, `coder` 1, `any` 3 | **17 tasks (10%)** | not in the standard's collapse map at all |
| lane `authority=` — `authority` (framework/deterministic) vs `initiative` (agent/stochastic) | 67 lanes | **the collapse DESTROYS it** |

**The last row is the finding.** The collapse map is `sovereignty→human`, `initiative→agent`,
`authority→agent`, `external→no task`. Both `authority` and `initiative` resolve to **`owner:
agent`**. So the one carrier where the distinction is authoritative erases it at compile time: a
deterministic framework-enforced step and a stochastic LLM-judgement step compile to the same
owner, and nothing downstream can tell them apart.

The operator's instinct is not an enhancement request. **The model actively erases a distinction
it already encodes.**

### Why this is evidence semantics, not a label

The EWCR contract promises *"every step traceable to the evidence that justified it."* What counts
as evidence is **different for each executor kind**, and this is the load-bearing consequence:

| executor | reproducibility | what evidence IS |
|---|---|---|
| **deterministic machine** | same input → same output | the code + the input. Verifiable by **re-running**. |
| **stochastic agent** | same input → a *distribution* | the actual output + its trace. **Not regenerable** — re-running produces a different answer. |
| **human** | not an executor at all | a **ruling**. There is no output to verify, only a decision to record. |

**A stochastic step's evidence is perishable.** If it is not captured at execution time it is gone
permanently, because it cannot be recomputed. A deterministic step's evidence can always be
re-derived. That is a hard architectural requirement and it falls directly out of the distinction
the current collapse map throws away.

It is also the same disease this project has been treating all week (T-674/675/677/678, PL-178):
a system that cannot tell *"this was measured and the answer was nothing"* from *"nobody looked."*
For stochastic executors that distinction is not recoverable after the fact.

### Where it belongs in the two lenses (and the honest answer: neither)

- **TOGAF** — not a BDAT layer. It is a property of a technology/application component, not a
  layer of the stack.
- **BABOK IGOE** — a **qualifier on the Enabler**, not a fifth IGOE element. *Who* performs and
  *what kind of thing* they are, are different questions.
- **Neither names it**, because both predate stochastic executors.

**Closest literature that does:** arXiv 2412.05958's `AgenticTask` vs ordinary `Task` — the same
distinction, made as an **element-type** distinction on the box. Which is consistent with proposal
B and inconsistent with lane-carried authority.

**This is the one axis where we must invent rather than adopt.** Worth stating plainly so nobody
later mistakes the absence of a citation for an oversight.

### A caution: "human" is about to become the overload we just diagnosed

The operator's framing — *"the machine is deterministic and the agent is stochastic and the human
is tier zero authority"* — puts two different things on the human:

1. human as **executor kind** (a `userTask`: someone does the work), and
2. human as **authority** (the tier-0 approver: someone rules on it).

Those are separate. A human can perform a tier-3 action (read a status page). An agent can be
*assigned* a tier-0 action — which then requires human approval, and that is precisely the
interesting case identified in §6. Collapsing executor-kind and authority into the single word
"human" reproduces, on a new axis, the exact defect §4 measures on the lane.

**Recommendation: keep them separate.** Executor kind ∈ {deterministic, stochastic, human};
authority/tier is a different field on the same box.

## 5f. The concepts → workflow → pseudocode → code ladder, and stepping back

The operator asked for this to be a supported workflow: iterate from concepts to workflow to
pseudocode to working code, and step back again.

**This is MDA (CIM → PIM → PSM → code) and its failure mode is well documented:** round-tripping
breaks because generated code gets edited by hand, the model goes stale, and the model becomes *a
lie that was true once*. Teams then either abandon the model or freeze the code.

**Our version is harder, and it is worth being explicit about why.** With an agent in the loop
**both directions are stochastic**: model→code is a *proposal*, not a compilation; code→model is
*inference*, not extraction. Errors accumulate in both directions, and the classical remedy
("model is authoritative, generate one-way, never hand-edit the output") is unavailable because
human-agent collaboration on the code is the entire point.

### The proposed resolution: round-trip the contract, not the algorithm

> **The model is authoritative for the contract. The code is authoritative for the how.**

- The model owns: who may act, at what tier, in what domain, what evidence is required, which
  gates authorise.
- The code owns: the implementation.
- **"Stepping back" is then VERIFICATION — does this code still satisfy the contract? — not
  REGENERATION.** No attempt is made to re-derive the model from the code.

This degrades gracefully (an edited implementation does not invalidate the model), it is
mechanically checkable, and it is the only reading under which "Executable Workflow **Contract**
Runtime" means something stronger than "code generator."

### The structural principle underneath it

> **Put a deterministic check between the stochastic steps.**

Agent proposes (stochastic) → contract check (deterministic) → human ratifies (authority). Each
stochastic step is bracketed by something that is not stochastic. This is the same shape as every
control that has survived scrutiny in this project: the tier proposal validated by a human gate
(§5c), the human-only lock (IW-9), the mutation control's demonstrated red state (T-681 S2).

### Candidate design principles for the workflow designer

Offered for operator review, not adopted:

1. **The model owns the contract; the code owns the how.** Round-trip governance, never
   algorithms.
2. **Evidence semantics follow executor kind.** Stochastic output is perishable and must be
   captured at execution; deterministic output may be re-derived.
3. **A stochastic step may never be the sole author of its own authorisation.** Otherwise the
   governance is circular — this is why IW-9's human-only lock matters structurally, not just
   procedurally.
4. **Put a deterministic check between stochastic steps.**
5. **Authority is a property of the step, not of its position.** (§7)
6. **The unknown must be representable** — "no value applies" must be distinguishable from
   "nobody looked." (§4, the `authority="none"` defect)
7. **Every stochastic proposal has a fail-safe direction** — unknown proposes the *higher* tier,
   never the lower. (§5d)

## 5g. Operator response on the fourth axis, 2026-09-06 — corrections and new requirements

Taken point by point, as the operator gave it.

### "Presentational" — what the standard actually means by it

Operator: *"Standard calls it presentational. I don't really understand what that means."*

It means: **when the task type and the lane disagree, the lane wins and the task type becomes
decoration.** If a `scriptTask` (machine-executed) is drawn in a `Human · Sovereignty` lane, the
compiler emits `owner: human` from the lane and raises a WARNING — it does **not** treat the
`scriptTask` shape as evidence about who executes. The shape survives visually and carries no
authority. That is O-1, *"lane wins, warn-not-refuse"* (§3).

So the 111 `scriptTask` / 40 `serviceTask` / 12 `userTask` in the corpus are, per the standard,
**pictures rather than claims**. That is precisely why the deterministic/stochastic distinction has
no authoritative carrier today.

### Symbols — the distinction should be visible in the palette

Operator: *"script, service and user task still make sense. I guess we need to have symbols for
it… you have suggested a number of new symbols which I guess will be sensible to add to our left
column, our library of symbols."*

Accepted as a requirement. If executor kind becomes authoritative it must be **drawable** — the
palette should offer distinct symbols for deterministic-machine, stochastic-agent and human steps,
so the distinction is made at authoring time rather than inferred later. BPMN already supplies the
glyph vocabulary (`scriptTask` gear/script, `userTask` person); what is missing is a distinct
**agentic** symbol, which is exactly the gap arXiv 2412.05958 fills with `AgenticTask`.

### `agentType` must be expandable, and it carries ROUTING (new requirement)

Operator: *"framework, primary, coder or any. This needs to be expandable right? So we're going to
have a number of agents — could be a coder, could be TDD, could be an architect. And this will
also tie in to orchestration… we want it in the box, right? Because based on that we can make a
routing decision to the type of agents. Also the type of model. Our routing decisions we want to
capture in a workflow element."*

**This is a new requirement and it strengthens proposal B considerably.** The box is not merely
recording who acted; it is **carrying the routing decision** — which agent specialisation, and
which *model*, should pick the step up. That is orchestration input, and it cannot live on a lane
without forcing every step in a band to share one routing policy.

Current `agentType` values (`framework` 4, `primary` 9, `coder` 1, `any` 3) are therefore a seed
vocabulary, not a closed enum. Open design question: whether agent-type and model-type are one
field or two (an architect agent on a small model and a coder agent on a large one are different
routing outcomes).

### Governance is RISK-BASED, and that is the existing model to reuse

Operator, restating the AEF construct: tiers 0–3; pre-approved activities; agent initiative is
*"primarily risk based"*; riskier work puts the human in the loop; **an agent may perform a risky
action if it is pre-approved — either from a library of pre-approved activities, or because a
human has given an explicit go.**

Recorded so it is not re-derived: the authority model already exists and is risk-graded. This
inception should *reuse* it, not invent a parallel scheme.

### Deterministic-first with stochastic fallback (the operator's core execution principle)

Operator: *"we want to go very much to deterministic execution. That's most effective. Repeatable,
reliable, quick. However we do want to fall back on stochastic if it goes wrong, or is an error, or
an edge case, or on unclarity. We want AI to come in and react on that."*

The fallback repertoire the operator named, in order:

1. **redirect**
2. **analyse and fix** in place
3. **fix, and capture it for learning**
4. **forward to another agent** for structural remediation
5. **forward to a human** for intervention

**This inverts the usual framing and should be stated as a principle:** the machine is the default
executor; **the stochastic agent is the exception handler.** Agents are not the primary workforce
with machines as helpers — machines run the happy path, agents handle error, edge and ambiguity.

This also gives the escalation ladder an execution-layer meaning it did not previously have: the
five fallbacks above map onto the A/B/C/D error-escalation ladder already in CLAUDE.md.

### The maturation ladder: stochastic → deterministic as confidence accrues

Operator: *"we start with a lot of stochastic judgment… but we want to minimize that within
acceptable risks. And the more we get confident, the more we go to deterministic execution of our
processes and workflows."*

**Executor kind is therefore not a fixed property of a step — it is a position on a maturity
ladder.** A step begins stochastic (an agent works out how), and is *promoted* to deterministic
once the procedure is understood well enough to encode. That has a direct modelling consequence:
the box must be able to record **which kind it is now**, and ideally *why it moved*.

This is the single most design-relevant thing in this exchange. It means the designer is not
drawing a static allocation of work; it is drawing a **system that is supposed to migrate work
from stochastic to deterministic over time**, and the diagram should make that migration visible.

### Operator DISAGREES: stochastic evidence is not perishable here — and the reconciliation

Operator: *"I disagree there. I can refer back to what we have in our framework. We want a body of
knowledge… that's why we have the principle of nothing gets done without a task. We capture what we
do in our sessions, we capture conversations, we capture our research, we also capture our
considerations why we decided for something and against."*

**The disagreement is about framing, and the operator is right on the substance.** The agent's
claim was that a stochastic output cannot be *regenerated*, therefore capture is mandatory. The
operator's point is that capture is *already structural here* — so within this system the evidence
is not perishable, because the framework refuses to let it perish.

**The synthesis, and it reframes the framework's core principle:** *"nothing gets done without a
task"* is usually read as process discipline. It is better read as **the necessary consequence of
stochastic execution.** A deterministic system could afford to skip capture, because its evidence
can always be re-derived from code plus input. A stochastic system cannot — so the capture
discipline is not bureaucracy, it is the *only* mechanism by which a stochastic step can produce
evidence at all.

What survives of the agent's original point, narrowed: **capture must be complete and at the
time**, because there is no second chance to re-derive. That is a statement about why the
discipline is load-bearing, not a claim that this system lacks it.

### Analysis vs algorithm

Operator: *"analysis is never deterministic in that sense. Except if it's discriminatory, but then
it's not actually analysis, it's an algorithm. So it's not creative thinking."*

A useful sharpening, recorded as a classification test: **if a step's output is fully determined by
its inputs under a stated rule, it is an algorithm and belongs on the deterministic side, whatever
it is called.** "Analysis" that merely discriminates against fixed criteria is deterministic
classification. Only judgement that could reasonably produce a different defensible answer on a
second pass is stochastic.

### THE KEY OPEN QUESTION the operator posed (IW-11)

Operator: *"The big question is how do we build in signals that we can have a feedback loop for
learning and adjusting that risk assessment. That's key. Otherwise we just keep doing stupid
things."*

**This is the hardest and most important question raised in this inception**, and it is not
answered anywhere in this document. A tier is a *risk assessment*. Risk assessments made once and
never revised ossify: the system keeps demanding approval for things that have proven safe, and
keeps auto-running things that have proven dangerous, and nothing corrects either drift.

What a feedback loop would need, sketched only:

- an **outcome signal** per executed step (did it succeed, need rework, cause harm, get rejected at
  the human gate?);
- **attribution** from outcome back to the tier that governed it;
- a **revision proposal** path that is itself subject to principle 3 — the agent may propose a tier
  change on evidence, but may not ratify it (IW-9);
- protection against the obvious failure: a tier that is lowered because nothing bad happened *yet*
  is confusing absence of incident with evidence of safety — the same absence-vs-not-looked defect
  this project keeps hitting.

Filed as **IW-11** and explicitly not answered here.

### On keeping humans out of the low-value spots

Operator: *"we definitely don't want that. We want them in the spots where it really matters, which
is destructive actions, risky actions, or just where the agent is just not sure what to do, or
unclear about direction."*

Agreed, and it is consistent with §5e's caution: precisely because human attention is the scarce
resource, "human" must not be overloaded to mean both *executor* and *approver*. The three
human-in-the-loop triggers the operator names — destructive, risky, agent-uncertain — are all
**authority** triggers, not executor-kind assignments.

## 5h. The lock boundary flips the direction of derivation (operator refinement)

Operator, 2026-09-06, on "round-trip the contract, not the algorithm": *"In principle that's
correct. But with one caveat… that is when the model is locked under change control… once it's out
of the drafting stage, it's published, then that's definitely true… There are some exceptions
because when we're drafting, we might take an existing body of knowledge, which could be code,
which could be process descriptions or regulations, and we want to ingest it and infer an existing
workflow from that."*

**This is a material correction, not a footnote.** §5f stated flatly that we never re-derive the
model from the code. That is wrong before publication and right after it. The rule is not a
constant — **it flips at the lock boundary:**

| phase | authoritative direction | reverse derivation |
|---|---|---|
| **draft / ingestion** | code, regulations, process descriptions, existing docs **→ model** | **legitimate and desirable** — this is how a workflow gets discovered from an existing body of knowledge |
| **published / locked** | **model → code**, pseudocode, scripts | **forbidden as regeneration**; permitted only as *verification* (does this code still satisfy the contract?) |

Changing a published model is therefore not an edit — it is a **change-control event, tier 0,
human-approved**, and only that event may alter the flow or anything in it.

**Why this matters beyond tidiness:** ingestion is stochastic inference over someone else's
artefacts, and it is exactly where a wrong inference is cheapest to make and most expensive to
discover later. Putting the lock boundary at the point where inference stops being authoritative
is what makes the whole scheme safe. Before the lock, the model is a *hypothesis about* the
existing world; after it, the model is a *commitment the world must satisfy*.

## 5i. Worked examples requested by the operator

### Principle 4 — "put a deterministic check between the stochastic steps"

**The failure it prevents:** stochastic steps chained back-to-back compound error, and each one
reports confidence regardless. *Agent writes code → agent reviews the code → agent declares it
done* is three stochastic steps in a row with nothing mechanical in between; nothing in that chain
can discover that step one was wrong.

**The shape:** `stochastic → mechanical filter → stochastic or human`. The filter cannot be
persuaded by a confident wrong answer, because it does not read the answer's confidence.

Four instances, all real in this project:

1. **P-011 Verification.** The agent (stochastic) claims a task is complete. The framework
   *executes* the shell commands in `## Verification` and blocks completion on a non-zero exit.
   Agent self-assessment never reaches the gate. This is the canonical instance and it already
   exists.
2. **T-681's mutation control.** The agent proposes an isolation fence. The mechanical check is
   *does the fence go RED when a breach path is introduced, and GREEN when it is reverted?* Without
   it, the only evidence that the fence works is the agent saying so.
3. **The importer's repair path.** The agent infers what a malformed third-party file *meant*
   (stochastic). The mechanical check is: does the repaired document validate against the schema,
   and does the round-trip hash match? Only then does it reach a human.
4. **Tier proposal — the one this design needs.** The agent scans a step and proposes `tier=1`.
   The mechanical check matches the step's declared action against the **human-curated library of
   known tier-0 operations and pre-approved activities**. If the step invokes `rm -rf` and the
   agent proposed tier 1, the filter catches it *before* a human is asked to approve — so the human
   reviews a claim that has already survived a check that cannot be talked round.

### Principle 3 — "a stochastic step may never be the sole author of its own authorisation"

**Plain statement:** the thing that decides an action is *allowed* must not be the same stochastic
process that *wants to perform* it. Otherwise the constraint is chosen by the party it constrains,
and governance is circular.

**Crucial distinction:** *matching against an authorisation someone else granted* is fine — that is
what a pre-approved library is for. *Authoring the authorisation* is not. An agent may say "this
matches pre-approved activity #12"; it may not say "I judge this pre-approved."

Instances, three of which are already enforced here:

1. **Self-tiering.** An agent decides a step is tier 3 (pre-approved) and then executes it under
   that tier. The tier existed to constrain the agent; the agent picked its own constraint.
2. **`--force` / `--skip-*` bypasses.** An agent blocked by a gate deciding to bypass that gate is
   authorising itself past its own constraint. **Already operator-only in this framework** — this
   principle is why.
3. **The lock (your IW-9 ruling).** An agent that could publish would convert its own draft into an
   authoritative document. **Already ruled human-only** — same principle.
4. **Today's live instance.** The agent recommended GO on T-681. If it could also *record* the GO,
   its recommendation would silently become the decision. `fw inception decide` is agent-blocked
   for exactly this reason.
5. **The subtle one, and the one to watch.** An agent proposes a tier *and* writes the check that
   validates tiers. Even with a human ratifying, the human is approving a **self-consistent pair**
   from one stochastic source — the check will agree with the proposal because both came from the
   same place. **Consequence for this design: the pre-approved library and the tier-validation
   rules must be human-curated, not agent-generated.** Otherwise principle 4's mechanical filter
   quietly becomes stochastic again.

### Principle 2, restated after the operator's correction

Operator: *"stochastic output… becomes part of our knowledge fabric… we want to know what decisions
we made, why we did something, why we made an architectural choice, what rationale, what risks we
assessed — same as the conversation we're having now."*

Recorded: the word is **knowledge fabric**, and the retained content is not just outputs but
**decisions, rationale, rejected alternatives, and risk assessments**. §5g's reconciliation stands
— capture is the mechanism by which stochastic work produces evidence at all — and the operator's
framing extends what must be captured beyond step outputs to the reasoning around them.

## 5j. RESUME HERE — the agenda for the next session

Written 2026-09-06 immediately before a `/compact`, at operator instruction: *"when we come back
after compaction we continue with open questions and the grilling and we capture everything we
discuss properly. So when we've completed with our analysis and thinking we can really start
working from that."*

**This section is the continuation contract. The conversation will not survive; this file will.**

### Standing discipline for the resumed session

1. **Capture as we go, not at the end.** Every dialogue segment gets written into this artifact and
   committed before the next segment starts. That rule was itself an operator correction earlier in
   this task, and it is the reason anything here still exists.
2. **The register is the source, not the conversation.** If an IW disposition on the task and a
   claim in this artifact disagree, fix the task — a stale `deferred` is how a settled question gets
   re-asked. (Both were reconciled at 2026-09-06; IW-8/9/10 are now `answered`.)
3. **No build work yet.** This is still an inception with no decision. The operator's stated
   sequence is: finish the analysis, *then* start working from it.

### The grilling still owed — in priority order

- **IW-11 — the feedback loop.** *The* question. How do outcome signals flow back to revise the
  risk assessment a tier encodes? Needs: an outcome signal per executed step; attribution from
  outcome back to the governing tier; a revision path where the agent proposes and the human
  ratifies (principle 3); and protection against lowering a tier because nothing bad has happened
  *yet*. **Nothing here answers it.** Everything else in this document is structure; this is the
  loop that decides whether the system learns or ossifies.
- **IW-13 — routing.** One field or two for agent-type and model-type? An architect agent on a
  small model and a coder agent on a large one are different routing outcomes.
- **IW-7 — BDAT layer.** Agent proposed *dissolving* this: don't make the lane BE the layer; make
  it a named domain that CARRIES a `bdat=` attribute, so mixed-layer diagrams are legal and
  self-describing. **Operator has not ruled on that proposal.**
- **The symbol palette.** Operator requirement from §5g: if executor kind becomes authoritative it
  must be drawable. Which symbols enter the left-column library, and does an agentic task get a
  distinct glyph (as arXiv 2412.05958 does)?
- **The `authority="none"` defect (IW-4).** Answered as a defect, unfixed. 12 nodes still have no
  derivable owner. Whatever the lane decision turns out to be, this needs closing.

### Questions the agent has NOT yet put, and should

- If executor kind is a **maturity ladder** (IW-12), what is the *promotion event*? Who authorises
  a step moving from stochastic to deterministic, and what evidence justifies it? This is
  IW-11-adjacent and currently unowned.
- Does the **pre-approved library** live in the model, the framework, or both? Principle 3's subtle
  case says it must be human-curated; nothing says where it lives.
- What happens to a **published** model when the code it authorises drifts? Verification says
  "satisfies or does not" — but the response to "does not" is unspecified.

### Decision state

No inception decision on T-685. Six IWs answered, seven open. `voi_score` / `target_blast_radius`
remain planted template defaults and are operator-owned. **Nothing has been sent to AEF, and
nothing in this document authorises editing the frozen standard** (IW-6).

## 5k. IW-11 — the feedback loop, opened by measurement first

Resumed 2026-09-07 after compaction, per §5j. Before asking the operator how the loop should work,
one thing was worth checking: **we already built this loop once.** At task granularity the framework
runs exactly the cycle IW-11 describes — observe an outcome, name a pattern, generalise it, and
ratify the generalisation into a rule:

```
learning  →  pattern  →  practice  →  directive
   (observed)   (recurring)   (codified)   (constitutional)
                              ^ fw promote — agent proposes, human ratifies (IW-9's shape exactly)
```

The recurrence detector exists too: the audit's TREND ANALYSIS block counts repeats over 14 days
("Fabric: 72/367 cards have no edges — **15 times**") and closes with *"Consider creating a practice
to address these recurring issues."* That is a feedback loop, fully specified, wired into a gate,
running daily.

### What it has actually produced

Measured `fw promote status`, 2026-09-07:

| | count |
|---|---|
| Learnings recorded | **319** |
| Practices | 10 |
| **Promoted** | **0** |
| Candidates marked `ready` | 41 |
| Candidates marked `almost` | 32 |

**Zero.** Three hundred and nineteen observations, forty-one of them past the evidence threshold and
queued for a decision, and the ladder's top rung has never once been climbed.

> **PL-319 (candidate): a loop whose closing step is a human act that has never occurred is not a
> loop — it is a queue with good manners.** It detects, it ranks, it recommends, it waits. Every
> stage reports success. Nothing is ever revised. From the inside this is indistinguishable from a
> working system, because the only evidence of failure is an *absence* — the same absence-vs-not-
> looked defect as T-674/675/677/678, and the same shape as PL-317: a mechanism that cannot report
> its own inertness.

This is the single most important finding for IW-11, and it is a warning about the answer, not the
question. **Whatever we design for tier revision must not be another ladder of the same shape**, or
in twelve months the tiers will be exactly what they are today with 300 unactioned signals behind
them, and the audit will still be green.

### What the measurement does settle

Two design constraints fall straight out, and neither needs the operator to invent anything.

**1. Only a positive observation may lower a tier.** The trap named in IW-11's filing — lowering a
tier because nothing bad has happened *yet* — has a mechanical answer derived from our own
PL-317/PL-318: a tier may be lowered only on evidence that the step's **guard fired and passed**,
never on evidence that *nothing happened*. "Ran 200 times without incident" is a null observation
and is worth nothing if no check was watching; "the guard evaluated 200 times and went green 200
times" is a positive one. A step whose tier cannot be justified by a firing control is a step whose
tier should not move.

**2. The loop must be asymmetric.** Fail-safe direction (IW-10's surviving principle) says the two
directions are not the same act:

| direction | trigger | who | ratification |
|---|---|---|---|
| **raise** a tier | one incident | agent, automatic | none — safety direction, act first |
| **lower** a tier | N positive guard-passes | agent proposes | **human ratifies** (IW-9) |

Symmetric treatment is what jams the queue: if both directions need a human, the human becomes the
bottleneck for the *safe* direction too, and 319/0 is what that looks like. Making the raise
automatic is also what stops the register filling with recommendations nobody will ever act on.

### What the measurement does NOT settle — the questions for the operator

- **Q1. What is the outcome signal, concretely?** Candidates: step succeeded/failed; the guard
  fired and its verdict; a human overrode the step; the step was escalated to a fallback (the five
  from §5g). These are not the same signal and they do not all exist yet.
- **Q2. Where does it live?** In the model (`.bpmn` accumulates run history — self-describing but
  mutates a locked artefact); beside it (a run ledger keyed by node id — clean, but a second source
  of truth); or in the framework's existing memory (patterns/learnings — reuses the machinery, but
  that machinery is the one that just measured 0/319).
- **Q3. The ratification volume problem.** If every lowering needs a human ruling, how does this not
  become the promote queue? Options: batch review at a cadence; auto-lower with a human veto window;
  restrict ratification to tier-0↔1 boundaries and let 2↔3 move on evidence alone.
- **Q4. Does a tier assessment expire?** A tier justified by evidence from a system that has since
  changed is a stale claim. Nothing currently ages it out.

## 5l. Operator response on IW-11 — telemetry, and a concession

Operator, 2026-09-07, responding to §5k. Six points, and the second one corrects me.

### 1. The mechanism is not wrong, its follow-up is

> *"the mechanism might be good, but it needs strengthening, enhancing, and better implementation
> of follow-up activities."*

Accepted, and it is a better reading of the 319/0 measurement than mine. I wrote *"the answer must
not be another ladder of the same shape"*, which points at the ladder. The operator points at the
**rung that was never built**: detection, ranking and recommendation all work; nothing acts. The
defect is not the shape, it is that the loop terminates in a queue nobody drains. Redesigning the
detector would have fixed the part that already works.

### 2. CONCEDED — null results are data

> *"you say we don't record anything about anything that doesn't do anything. I actually disagree.
> If we fire something off and it has no output, I want to know that. I also want to know if I have
> a success. I want to know if it succeeds in an hour, or if it just fades into darkness."*

The operator is right and my option D was wrong as stated. I collapsed two different rules into one:

| | rule | verdict |
|---|---|---|
| **recording** | do not record absences | **WRONG — withdrawn** |
| **inference** | do not treat an absence as evidence of safety | stands |

Recording is not inference. An absence is a first-class observation — *"fired, produced nothing"* is
a fact worth storing, and so is *"succeeded, took an hour"*. Withholding it does not protect the
tier logic; it just blinds everything else. Constraint (1) from §5k narrows to its inference half:
**record everything; lower a tier only on a positive guard-pass.** Latency belongs in the record
too — the operator's *"succeeds in an hour, or just fades into darkness"* is the distinction between
slow, dead, and never-started, and no boolean carries it.

### 3. Expected-but-not-executed is an alarm, not a silence

> *"if there are features or steps that should be executed, I expect them to be executed. If I am
> not getting data or telemetry showing that they are executed, that warrants an investigation."*

This is the strongest structural idea in the message, and it is free: **the model already declares
what should execute.** A workflow contract states the steps; the ledger states what actually ran;
the gap between them is a signal that requires no new declaration. Two useful outcomes, both named
by the operator: strengthen a process that was designed but is not working, or discover it has no
value and **recommend decommissioning**. Dead-feature detection falls out of the same subtraction.

### 4. The repetition cycle — and a measurement that proves the point within the hour

> *"I regularly see that you repeat something ten times and then repeat it again ten times. I want
> us to have a quick recurring cycle that we learn from directly so we can act on it."*

I went looking for whether anything watches for this. Something does, and it is dead. Full detail in
**G-050**; the short form:

- `.claude/settings.json` registers `fw hook loop-detect` on **PostToolUse, empty matcher** (every
  tool). `lib/ts/src/loop-detect.ts` implements three detectors — no-progress, ping-pong,
  generic-repeat — and **BLOCKS at critical**. Exactly the mechanism the operator just asked for.
- Bisected with one identical payload: `node dist/loop-detect.js` records. `bash
  agents/context/loop-detect.sh` records. **`fw hook loop-detect` records nothing.**
- The counter says loop-detect has fired **341 times**. The state file holds **one** entry, sixteen
  hours old, and it reads `toolName: "unknown"`, `argsHash: "unknown:44136fa355b3678a"` — SHA-256
  of the literal string `{}`. Both payload fields absent. The detector fails open on empty stdin.
- Cause: `bin/fw:7039` was changed from `exec bash "$_hook_script"` to run-and-capture so that hook
  exit codes could be recorded as telemetry (T-1628). **The telemetry is where the 341 comes from.
  The payload does not survive.** The instrumentation added to make hooks observable is what broke
  the hook it observes.

**This is the operator's point 3 executing on itself.** A step that should run, no telemetry showing
it ran, investigated → live defect. The principle earned its keep before it was written down. And
the failure class is one we have already named twice: PL-306 *"being wired is not being watched"*,
PL-317 *"a control that cannot go red for its own reasons"*. Every health surface reports this hook
as firing and healthy, because the only signal is a fire counter, and a fire counter measures
invocation, not function.

> **PL-320 (candidate): a fire counter is not a function check.** Counting invocations of a control
> proves it was called, and proves nothing about whether it did anything. Where a control has state,
> the health check must assert the state moved — not that the control was entered.

### 5. Recall on failure, not only on focus

> *"I would invoke a query of a vector database after two, three, or four failures to find out how
> other times we resolved that."*

Partly built, wired to the wrong trigger. `agents/context/lib/memory-recall.py` does hybrid search
(T-245) over learnings, patterns and decisions — but it is called by **`fw context focus`** and
`fw recall`, i.e. when you *start*, not when you *fail*. The operator's trigger is the valuable one:
N consecutive failures on the same thing is the moment the prior resolution is worth most, and it is
precisely when nobody thinks to run `fw recall`. AEF has already grilled the embeddings question
(`docs/reports/T-1717-embeddings-strategy-grill.md`), so the substrate question may be settled
upstream — worth asking them rather than re-deciding.

### 6. Cross-instance telemetry, scored and actioned

> *"this data doesn't come from a single project or a single AF instance… If we then do something
> with that data, we could use a value estimator or a points estimator to assess, value, and score
> them, and then action them as a follow-up. We must do something with that data."*

The shape already exists in one place: **`agents/termlink/bvp-estimator/estimator.py`** — a value
estimator that lives under the *transport* agent, which is what a cross-instance scorer would need
to be. Note the sovereignty boundary this must respect (T-1924): the estimator may *propose*
(`bvp_scores` proposed, advisory), and only the operator confirms. That is the same
agent-proposes/human-ratifies gate as `fw promote` — **and `fw promote` is the one measured at
0/319.** So point 6 inherits point 1's problem exactly, and must not be designed without answering
it: what drains the queue?

### Scope note — IW-11 has outgrown T-685

T-685 asks one question: *does authority live in the box or the lane?* IW-11 now carries an outcome
signal schema, a run ledger, non-execution detection, a repetition cycle, failure-triggered recall,
and cross-instance telemetry scoring. That is a subsystem, not a sub-question, and framework rule
**"one inception = one question"** says bundling them creates an all-or-nothing decision on
independent explorations.

**Recommendation:** IW-11 splits out as its own inception — *"how does executed-workflow telemetry
feed back into governance?"* — and T-685 keeps only the part it actually needs to answer: **if a tier
lives in the box, what revises it, and who ratifies the revision?** That question is answerable
inside T-685. The rest is a second arc, and G-050 is a build task that should not wait for either.

## 5m. Where does a framework capability get built? — the balance, measured

Operator, 2026-09-07, on splitting IW-11 out:

> *"it is a built-in engineering framework capability… It needs to be incorporated in the overall
> framework so it gets vendored in other project instances too. Consider how we can get a good
> balance there that we don't just kick it over there and wait and see if anything turns out. But
> also… we start with a complete isolation and nothing happens in AEF."*

Two failure modes, correctly named. **Throw it over the wall:** we lose the timing, and the evidence
that motivates the design does not live where the code would be written. **Build it locally:** it
works here, propagates nowhere, and diverges until someone upstream builds a second one.

### The measurement: one of those two failure modes is already the status quo

We have a sanctioned local-first lane. G-008 permits fixing the vendored `.agentic-framework/`
in-tree and upstreaming; `.vendor-divergence.yaml` declares every diverged path against baseline
`ebf0c721` (T-276, framework v1.6.763); and the audit asserts every divergence is declared —
`[PASS] Vendor divergence: all 50 diverged path(s) declared`.

Contents, measured 2026-09-07 — 62 entries:

| `upstream:` | count | meaning |
|---|---|---|
| **`fix`** | **46** | a repair that should go upstream |
| `vendoring-repair` | 10 | local re-vendor damage |
| `local-config` | 4 | deliberately never upstream |
| `superseded` | 2 | upstream changed underneath us |

Schema fields, complete: `kind`, `path`, `reason`, `task`, `upstream`, `superseded_by`,
`superseded_changes`.

**There is no delivery state.** No `delivered`, no `upstream_ref`, no date, nothing. Forty-six fixes
are marked as belonging upstream and the register cannot express whether a single one ever got
there. The two `superseded` entries are not deliveries — they record upstream moving on *without*
our fix.

### Three registers, one defect, escalating

| register | measured today | can it report its own emptiness? |
|---|---|---|
| `fw promote` | 319 learnings, 41 ready, **0 promoted** | yes — it prints the 0 |
| loop-detect (G-050) | **341 fires, 0 records** | no — the fire counter reads healthy |
| vendor divergence | **46 fixes queued, delivery unmeasurable** | **no — the schema has no terminal state** |

The third is the worst of the three. `fw promote` at least *says* zero. The divergence register
cannot say anything, because "delivered" was never a value it could hold. It is not an empty queue;
it is an unmeasurable one, and it passes its audit line every single day.

> **PL-321 (candidate): a queue with no terminal state is a landfill with an audit line.** Any
> register that accepts proposals must carry the state that ends a proposal's life and a measure of
> throughput to it. Without both, "we'll upstream it later" is not a plan with a schedule — it is a
> plan with no observable difference from never.

### What this settles about the operator's question

The balance is not a choice between the two failure modes. **Local-first is already what we do**
(46 fixes deep), so "build it in the vendored copy and upstream later" is not a proposal — it is a
description of the status quo, and the status quo has an unmeasured exit. Any plan of that shape is,
on today's evidence, a plan to build it here and leave it here.

So the balance needs the exit instrumented before it carries anything as large as a telemetry
subsystem. Recommended shape, split by **coupling to AEF** rather than by size:

1. **G-050 — fix in the vendored copy now, and use it as a probe of the upstream channel.** A
   one-line stdin defect with a three-step bisect and a 341-vs-1 counter is the most
   uncontroversial patch we will ever have. If *this* cannot reach upstream, we learn the channel
   is dead **before** betting a subsystem on it. Cheap, and informative whichever way it goes.
2. **Single-instance mechanism — build in `.agentic-framework/`, written as if upstream.** Recording
   outcomes (including nulls and latency), expected-vs-actual execution detection, the repetition
   cycle, recall-on-failure: none of these need AEF's agreement, and all of them are framework
   capability, not product code. Discipline: no 832-specific assumptions, so upstreaming is a copy
   rather than a rewrite. Declared as divergence like everything else.
3. **Cross-instance aggregation (operator point 6) — contract first, code second.** This one
   genuinely cannot be built unilaterally: it needs an agreed envelope before either side writes a
   line. This is the part that goes to AEF as a proposal, and the only part that should wait.
4. **Prerequisite for 1–3: give the divergence register a terminal state.** `delivered` +
   `upstream_ref` + date, and an audit line that goes red on age rather than green on declaration.
   Without this, lane 2 is complete isolation with paperwork — exactly the outcome the operator
   named.

Item 4 is small, and it is the one that decides whether the other three are real.

## 6. Tier and authority are not the same axis (IW-3, answered)

| | question | values | scope |
|---|---|---|---|
| **authority** | **WHO** — which kind of actor | sovereignty / initiative / authority / external | per actor-role |
| **tier** | **HOW RISKY** — what permission this action needs | 0 / 1 / 2 / 3 | per action |

From CLAUDE.md §Enforcement Tiers: tier 0 = consequential (force push, hard reset, `rm -rf`),
human approval required; tier 1 = standard; tier 2 = human situational authorisation, logged;
tier 3 = pre-approved categories.

**Neither subsumes the other.** *A tier-0 action performed under agent initiative* is the
interesting case, and no single field expresses it. Any box-authority design must carry both.

## 7. The operator's argument, and why it is the strongest part

> *"the boxes that this authority decision is contained in the box set in the box — can it be
> changed by agents. In principle and they are deterministic."*

Restated: the tier is a property of **what the action is**, so it cannot drift by editing.

Today, **authority lives in position, and position is precisely what a drawing tool lets you
move.** An agent can change who is accountable for a step by dragging its box into a different
lane.

And that is exactly what T-341 is. A broken lane reference sends the node to `lanes[0]`, and
`lanes[0]` is positional — human is first on 13 of 24 corpus maps, agent on 10, working on 1. So
today **the authority an orphaned step acquires is decided by the order a third-party tool
happened to serialise its `laneSet` in.**

If authority lived in the box:

- moving a box between lanes could not change accountability;
- a broken lane reference would be a **display** problem, not a **sovereignty** problem;
- and T-341's half B would largely dissolve rather than need a ruling.

**Caveat (IW-2, confidence 1, deferred).** Determinism is currently an *intent*, not an enforced
property: `aef:meta tier=` is author-set in the editor like any other attribute. The argument
holds only if something makes the tier follow from the action. That is a spike, not an assertion.

## 8. Candidate shapes

| | shape | preserves O-3? | domain visible? | cost |
|---|---|---|---|---|
| **A** | Lane stays authority; domain becomes a separate element attribute | yes | **no** | lowest |
| **B** | **Lane means domain; authority moves to the box (tier + owner)** — *operator's proposal* | **needs rewrite** | yes | high; re-opens frozen standard |
| **C** | Nested lanes: outer domain, inner authority | yes | yes | lane hierarchy in importer/editor/validator; patchy third-party support |
| **D** | Domain as BPMN `Group` (crosses lanes, no execution semantics) | yes | yes | 0 mentions in standard, ~1 in editor — new work, but additive |

**B is the operator's proposal and the current leading candidate.** D remains interesting as the
BPMN-native answer to "a second dimension that is not a lane" and is the cheapest way to get
domain *drawn* without touching authority at all.

**A genuine NO-GO exists.** If B/C/D all cost more than simply **defining what `none` means** and
accepting that domain is not visualised, then keeping today's model with one honest fix is the
correct outcome. That is a result, not a failure.

## 9. Constraint carried into any GO (IW-6, answered, confidence 3)

Part I of `docs/standards/aef-bpmn-mapping-v1.md` is **frozen** and shared with 999-AEF, and v1.1
deliberately removed the very override option B restores. **A GO here authorises a standard-change
conversation with AEF. It does not authorise editing the frozen standard.**

## 10. What has NOT been done

- No spike has been run. IW-1, IW-2 and IW-5 are all deferred and all need measurement.
- Nothing has been sent to AEF.
- T-341 half B remains unruled, and this document is the reason it should stay unruled for now.
- No BVP scoring: `voi_score` / `target_blast_radius` are operator-owned with no `_proposed:`
  lane and have been left at template defaults rather than filled in by an agent.

---

## Dialogue Log

**2026-09-05 — agent presented T-341 for ruling.** Recommended announce = YES (high confidence),
placement deliberately unrecommended as the reserved sovereignty question, with the measurement
that `lanes[0]` is positional (human first on 13/24, agent 10, working 1).

**2026-09-06 — operator:** *"Booh, this is difficult call to make because our lane assignment
rationale is... need strengthening. We did it based on roles. And the role has an authority like a
human operator, point agent or dispatch agent. But actually we also have domains. For instance
like a system domain which we also want to see in workflows. And I'm not sure if we better switch
to system domains for workflows. And do the roles have a different way to identify the roles. It's
already in the elements, we know that's the role, so that gives a limitation. Do you know what I
mean? Can we reflect on this? Can you also research in common literature how the general approach
is to order this?"*

**Agent response:** measured the corpus (§4), found the six domain lanes and the
`authority="none"` filler; cited the frozen standard's "lane is sole authority-of-record" and the
explicit demotion of task-type to *presentational* — which is the "limitation" the operator was
sensing, and it is deliberate, not accidental. Researched BPMN spec position, Silver-lineage
practice, and arXiv 2412.05958 (§5). Laid out shapes A–D.

**Course correction #1 (agent, same turn):** withdrew the request for a T-341 half-B ruling.
Option 2's *"lowest-authority lane present"* is undefined on exactly the `authority="none"` maps,
so the orphan question is hardest precisely where the lane axis has already stopped meaning what
it claims. Pressing for a ruling would have produced a policy that gets re-litigated the moment
the lane axis changes meaning. **Half A (announce) still stands** — it is strictly better under
all four shapes.

**2026-09-06 — operator:** *"Can you explain this please again to me like a 10 year old child
because I lost it and name concrete examples or concrete terms we are using."* Plus the design
proposal: consistent naming for boxes and diamonds; *"there are often already tier 0 to tier 3 I
think levels of authority"*; *"we could set a specific authority there. Who is the owner right? So
that the boxes that this authority decision is contained in the box set in the box can it be
changed by agents. In principle and they are deterministic. And the lanes are more like streaming
lanes show where in the flow it takes place. Yeah in which domain. It can be customer domain can
also be system domain."*

**Agent response:** supplied BPMN vocabulary (box = Task; diamond = Gateway; circle = Event; band
= Lane; dotted frame = Group); explained the collision in plain terms; **measured that `tier` is
already on elements in 10+ maps and undocumented in the standard** (§4); distinguished tier
(per-action risk) from authority (per-actor role) as non-substitutable (§6); and identified the
operator's determinism point as the strongest argument, because it removes authority from
drag-movable position (§7).

**Finding produced by the dialogue, not brought to it:** the 12 ownerless nodes in
`context-memory.bpmn`. Nobody was looking for them; they fell out of checking whether `none` was
in the collapse map.

**2026-09-06 — operator:** *"Before we go any further, should we capture this in an ongoing
inception document or somewhere in the task, so we don't lose the transcript of our discussion and
dialogue and decision and consideration so far?"*

**Outcome:** T-685 opened and this artifact created. The operator was right that it was overdue —
C-001 requires the research artifact *before* the research, and four exchanges of findings existed
only in conversation. Open questions IW-1..IW-6 filed on the task.

**Still owed to the operator (agent's next move on resumption):** the promised grilling on the
unpinned parts of proposal B — starting with IW-1 (*what is a domain, and is `customer` the same
kind of thing as `system`?*) and IW-2 (*who sets the tier, if not the person drawing the
diagram?*).

*(Segments from 2026-09-06 onward are captured in-section: operator's tier/lock ruling §5c–§5d, the
fourth axis §5e, the philosophical pass §5f, the point-by-point response §5g, the lock boundary §5h,
worked examples §5i.)*

**2026-09-07 — agent, resuming after compaction:** opened IW-11 by measuring rather than asking
(§5k). Found `fw promote status` = 319 learnings, 41 ready, **0 promoted** — the framework already
runs the loop IW-11 asks for, and its closing rung has never been used.

**2026-09-07 — operator, six points (§5l verbatim):** the mechanism needs *strengthening*, not
replacing; **null results are data** — *"if we fire something off and it has no output, I want to
know that… whether it succeeds in an hour, or just fades into darkness"*; expected-but-not-executed
warrants investigation and may end in decommissioning; a fast repetition-learning cycle, because
*"I regularly see that you repeat something ten times and then repeat it again ten times"*; query a
vector database after 2–4 failures for how it was resolved before; and aggregate telemetry across AF
instances, score it with a value estimator, and **act on it** — *"we must do something with that
data."*

**Agent concession:** option D from §5k was wrong as stated. I had conflated *do not record
absences* with *do not infer safety from absences*. The first is withdrawn; the second stands.

**Finding produced by the dialogue, not brought to it (second time this has happened):** chasing
the operator's repetition point uncovered **G-050** — the loop detector is registered on every
PostToolUse call, has fired **341 times**, and has recorded exactly one entry, whose payload fields
are both absent. `fw hook` eats the stdin payload. The operator's own principle #3 — *no telemetry
showing it executed warrants an investigation* — found a live defect within the hour of being
stated, in the control that was supposed to catch the behaviour they were complaining about.
