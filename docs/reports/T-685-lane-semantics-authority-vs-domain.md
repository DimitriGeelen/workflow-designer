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
