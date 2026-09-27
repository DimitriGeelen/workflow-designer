# Design review: a lane is a partition; the element carries authority; a lane may optionally *force* one

**Round four.** Three previous rounds of this consult reached verdicts that we now believe rested
on a premise **we supplied wrongly**. That is stated up front because it is the main reason for
asking again, and because we would rather you re-examined your own strongest argument than
repeated it.

- **Round 1** proposed moving authority from the swimlane to the element. 4/4 rejected it. The
  decisive objection: *"the proposal replaces an architectural guarantee with a lint rule"* —
  lane-as-authority is correct-by-construction, element-authority is correct-by-validation.
- **Round 3** proposed multiple lane partitions as views. 5/5 rejected it. The decisive
  objection: *"a view is a function of a stored fact; independently edited `flowNodeRef` lists
  are N facts."*
- **The premise we got wrong:** all three briefs presented lane-as-authority as the established
  model, and offered our corpus statistics as evidence for it. **That corpus is one tenant
  modelling its own governance processes.** 60 of 67 lanes in it are named `Framework`, `Agent`
  or `Human` — the actor triple. That is not what lanes are for in general, and it is not what
  this product is for.

So please read the following with the earlier verdicts held loosely.

---

## 1. What this project is for — its own stated purpose and goals

Included verbatim from our project charter, because the last question below asks you to judge the
design against it rather than against our enthusiasm.

### Purpose

> **Capture a process completely enough to execute it, and let humans and agents work the same
> picture from idea to running implementation.**
>
> Processes are modelled as **classes** and run as **instances**. A class carries its steps,
> decisions, dependencies, inputs and outputs, pseudocode, decision trees and artifacts. An
> instance binds that class to real work — a task number, an exploration, a sprint item — and can
> be watched as it advances, step by step, with a step that is not permitted **refused** rather
> than taken.

### The organising idea

**Class and instance.** A workflow is modelled once as a template and instantiated many times,
exactly as a class is to an object. A `task-lifecycle` diagram is a class; a real task id is an
instance of it. *"Everything else in this project is downstream of that distinction. Capture
gives the class its content; forward-compile turns a class into proposed work; instantiation
binds a real entity to its class; execution monitoring says which node of the class a given
instance is standing on."*

### Who the users are

| user | what they get |
|---|---|
| **process author** (human) | draws a process — steps, decisions, dependencies — and attaches everything an implementer needs: inputs, outputs, pseudocode, decision trees, the artifacts each step reads and writes |
| **framework agent** | reads that picture as a *proposal* for governed work and compiles it into a task graph |
| **operator** | sees a live instance and knows which step it is standing on, which it failed at, and why |
| **second tenant** | models its own processes with the same machinery — *"proving this is a modelling substrate, not one bespoke diagram set"* |

### The six goals, each with a falsifiable signal

- **G1 capture completeness** — *if a step carries its inputs, outputs, decisions, artifacts and
  pseudocode, an implementer needs nothing outside the picture.* Signal: a reader implements a
  step from the diagram alone.
- **G2 class ≠ instance** — the serialised form says whether a diagram is a template or an
  actionable plan, so nothing promotes a picture into real work. **Shipped this week.**
- **G3 an instance knows its class** — a real entity resolves to its template and its current
  node.
- **G4 execution observable and guarded** — *if instance state is held by the framework and
  advanced only through a validated transition, an illegitimate step is refused and audited.*
  Signal: an out-of-order advance, a skipped human gateway, and an unmet input contract are each
  refused and each land in the audit log.
- **G5 more than one tenant** — a second, unrelated application models its processes with the
  same machinery. **Tenant-neutrality is a stated design property, and is currently unproven:
  all 24 diagrams are framework-internal.**
- **G6 idea → implementation round-trips** — forward-compile (diagram → proposed task graph) and
  reverse render (existing work → editable diagram).

### Stop conditions the project declares about itself

> *"If the class/instance model cannot be made to hold… the monitoring goal collapses and what
> remains is documentation tooling, which is a smaller and honest thing to admit."*
>
> *"If a second tenant cannot use it. Tenant-neutrality is a stated design property; a substrate
> that only ever serves [one tenant's] 24 maps has not been shown to be one."*

### How we judge any piece of work

Every programme of work must answer: what is the goal, as something a **user observes**; which
project goal does it advance; is it bounded or continuous; and per task — *does this deliver arc
purpose and project purpose?* With an explicit rule that **a check which has never once produced
a "no" is decoration, not governance.**

## 2. The governance model being questioned

Every step has an **authority** — who acts. Four values: `sovereignty` (a human must decide),
`authority` (the framework enforces), `initiative` (an agent may act), `external`.

Today the framework's frozen standard (v1.1) states: *"a node's owner MUST be its lane — there is
no node-level owner override. The Lane (its `laneMeta authority`) is the sole
authority-of-record."* An earlier version had a node-level override and it was **deliberately
removed**.

**We are now questioning that model, and this is the reason:** a lane's meaning is the modeller's
choice. It might partition by actor, but equally by business domain, subsystem, department,
system boundary, or phase. BPMN itself takes this position — lane meaning is modeller-defined and
lanes carry no execution semantics. Our own standard hardened **one tenant's convention** into a
universal `MUST`. A general mechanism, applicable across arbitrary projects (G5), cannot require
that every project's chosen partition also be its authority partition.

One reviewer already said as much unprompted: *"Lane meaning is modeler-defined. Lanes have no
execution semantics. Authority-in-the-lane is already your extension, not a BPMN fact."*

## 3. The proposal

Three parts:

1. **A lane is a partition.** Its meaning is declared by the modeller. No authority semantics are
   implied by membership.
2. **The element carries its authority.** One field, one home. The compiler reads it directly —
   never by scanning lanes, never resolved by document order.
3. **A lane may OPTIONALLY declare a forced authority**, and which one. When it does, an element
   created in or dragged into that lane **automatically receives that authority, written onto the
   element.**

```xml
<lane id="approvals" name="Approvals" forceAuthority="sovereignty"/>
<!-- any element placed here is stamped: -->
<userTask id="approve"><meta authority="sovereignty"/></userTask>

<lane id="storage" name="Storage subsystem"/>   <!-- a plain partition; forces nothing -->
<serviceTask id="persist"><meta authority="initiative"/></serviceTask>  <!-- authored -->
```

### Why we think this answers round one rather than ignoring it

The earlier objection was that element-authority replaces a structural guarantee with a
validator's opinion. Here the lane is a **generator**, not a checker: it *writes* the value onto
the element at authoring time, and the invariant "every element in this lane carries this
authority" is then trivially true and cheaply assertable. The visual guarantee returns for any
project that wants it — the lane really does tell you, because it stamped every member — while no
project is forced to make its partition mean authority.

Authority still has exactly **one** storage location, so there is no second fact to drift.

### Costs and open edges we already see

- **Amends the frozen standard.** §3's "sole authority-of-record" is precisely the universal claim
  this replaces. We do not own that standard; the counterparty has not responded to an earlier
  proposal. This is the largest real cost and it is political, not technical.
- **Drag semantics.** Moving an element *out* of a forcing lane: keep the stamped value or clear
  it? Moving between two forcing lanes: re-stamp silently?
- **Author override vs re-stamp.** If an author deliberately sets an authority and the element is
  later dragged, a silent re-stamp destroys intent. We have an existing pattern for this
  elsewhere in the project: a value set by a human is marked as such and becomes **sticky**
  against automatic recomputation. We would apply the same, so a lane's force cannot overwrite an
  explicit authorial choice and the conflict surfaces instead.
- **Retroactive forcing.** Adding `forceAuthority` to a lane that already has members should stamp
  them as a *visible operation*, not a silent sweep.
- **Imported third-party files** carry neither element authority nor forcing lanes. Every node
  would then have no authority. We think that must be a hard error rather than a default, but it
  is a decision.
- **Migration.** 67 lane authority values across 24 diagrams become element values — generated by
  the forcing rule, not hand-written, but still a corpus rewrite of a seam the counterparty pins.

## 4. Questions

1. **Does the generator-not-checker distinction actually answer the round-one objection**, or is
   it a restatement of it? Be blunt if it is. The invariant still needs a validator to hold over
   time, and an element can presumably be edited directly after being stamped.
2. **Is there a failure mode in the stamping model we have not named?** Our instinct is that
   authoring-time generation plus a stickiness rule is sound, but authoring-time generation has a
   general reputation for producing values nobody remembers agreeing to.
3. **Is "a lane is a partition, meaning declared by the modeller" the right generalisation** — or
   is there a reason a governance framework *should* constrain lane meaning that we are
   discarding too casually? The previous version of the standard chose to constrain it, and
   deliberately.
4. **Judge it against §1.** Does this design serve the stated purpose and the six goals, and in
   particular G5 (tenant-neutrality) which is the reason we are generalising at all? If the
   honest answer is that it serves G5 and damages another goal, say which.
5. **Is this proportionate?** The concrete measured defects are small: an orphan node inheriting
   authority from document order, and one diagram whose lanes are domains and had to write a
   non-vocabulary value. Would two narrow fixes deliver the value at a fraction of the cost, and
   is the general mechanism therefore premature? **Three of five reviewers said exactly this last
   round, and we want to know whether the generality premise changes it.**
6. **What would settle it with evidence rather than argument?** We would rather run a measurement
   than continue reasoning.
