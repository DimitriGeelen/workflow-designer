# Design review: should process authority live on the swimlane or on the element?

This is the second version of this consult. The first sent the schema question with almost no
project context, and two reviewers correctly said so — one raised end-user impact we had not
described, another argued we were optimising for a compiler at the expense of a human audience
whose existence we had not established either way. So here is the whole picture.

---

## 1. What the system is

Two components in a deliberately acyclic relationship:

**The framework (AEF — an Agentic Engineering Framework).** A governance layer for software
work. Nothing gets done without a task; every commit references one; gates refuse actions rather
than warning about them. It holds a task graph, enforcement tiers, audit rails, and an authority
model: *humans hold sovereignty and are accountable, the framework holds authority and enforces
rules, agents hold initiative and may propose but never decide.*

**The Workflow Designer (our project).** A browser-based process authoring tool, shipped as a
single self-contained HTML file, versioned and vendored into the framework by checksum. The
framework references only a build artifact of ours, never our source, so the dependency cycle
never closes.

We author the standard that joins them: a BPMN ⇄ task-YAML mapping, frozen at v1.1. The
framework side vendors a pinned release and serves it; it never edits its vendored copy.

## 2. What the Designer is for

> **Capture a process completely enough to execute it, and let humans and agents work the same
> picture from idea to running implementation.**
>
> Processes are modelled as **classes** and run as **instances**. A class carries its steps,
> decisions, dependencies, inputs and outputs, pseudocode, decision trees and artifacts. An
> instance binds that class to real work — a task number, an exploration, a sprint item — and
> can be watched as it advances, step by step, with a step that is not permitted **refused**
> rather than taken.

Concretely: `task-lifecycle` is a class. A real task id is an instance of it. `inception-lifecycle`
is a class; each real exploration is an instance. We have 24 such classes modelling the
framework's own processes — audit, release, handover, escalation, verification.

**What it is not:**
- Not a BPMN editor. BPMN is the portable serialisation, not the point.
- **Not a replacement for the task system.** Tasks are canonical. A diagram *proposes* governed
  work and never authors it. An instance binds to the task graph; it does not become it.
- Not a runtime. Execution *monitoring* is in scope; a mode where the framework drives execution
  node-by-node is explicitly out of scope and is a separate programme.

## 3. What a step already carries (the capture vocabulary)

This is not a boxes-and-arrows tool. Measured counts of our own extension attributes across the
24-diagram corpus:

| concern | attributes | uses |
|---|---|---|
| decisions and decision trees | `decisionInput`, `decisionOutputs`, `meta decisionOwner` | 102 / 46 / 54 |
| inputs and outputs | `io`, `input`, `output`, `contextReads` | 56 / 12 / 31 / 19 |
| artifacts a step writes | `artifactsWrites`, `emit` | 21 / 25 |
| dependency and routing | `link`, `anchors`, `routingHint` | — / 55 / 9 |
| execution semantics | `meta guard`, `exitCode`, `state`, `terminalKind`, `triggeredBy`, `autoTrigger` | 8 / 7 / 19 / 18 / 3 |
| enforcement tier | `meta tier` (0..3) | 74 elements, 14 diagrams |

**Pseudocode is the one thing on the intended list with no carrier at all** — zero occurrences.

## 4. Our six goals, each with a falsifiable signal

Stated because "does this proposal serve the project" is a question we want tested, not assumed.

- **G1 capture completeness** — *if a step carries its inputs, outputs, decisions, artifacts and
  pseudocode, an implementer needs nothing outside the picture.* Signal: a reader implements a
  step from the diagram alone. **Largely built; pseudocode missing.**
- **G2 class ≠ instance** — *if the serialised form says whether a diagram is a template or an
  actionable plan, nothing promotes a picture into real work.* Signal: the marker exists,
  round-trips, and the promote path refuses an unmarked documentation diagram. **Decided, and we
  shipped the marker this week.** The defect is live: the framework's promote path has minted
  real human-owned tasks from purely illustrative nodes.
- **G3 an instance knows its class** — Signal: a real task id resolves to its template and its
  current node. **Does not exist.** Just explored: the template half is derivable from the task's
  type, the *node position* is not, so position must be recorded.
- **G4 execution observable and guarded** — *if instance state is held by the framework and
  advanced only through a validated transition, an illegitimate step is refused and audited.*
  Signal: an out-of-order advance, a skipped human gateway, and an unmet input contract are each
  refused and each land in the audit log. **Not started.**
- **G5 more than one tenant** — Signal: a second, unrelated application models its processes with
  the same machinery. **Not started;** all 24 diagrams are framework-internal.
- **G6 idea → implementation round-trips** — forward-compile (diagram → proposed task graph, the
  framework side owns the translator) and reverse render (existing work → editable diagram).
  **Round-trip byte-identity delivered and guarded; reverse render partial.**

## 5. The arc this sits in

We opened an arc — a bounded programme of work — whose stated user-observable goal is:

> *An operator opens `task-lifecycle` in the designer, sees it marked as a template rather than
> an actionable work-plan, creates an instance of it bound to a real task number, and watches
> that instance advance node by node as the task moves — with an out-of-order advance refused
> and written to the audit log.*

It delivers G2, G3 and G4. Ten tasks, four slices: the class marker (shipped), instance identity
(explored, awaiting a go/no-go), the guarded-advance ladder, and the operator-visible view.

**The lane-authority question below is a dependency of that arc**, which is why we are asking.

## 6. Authority today, and the proposal

Every flow node has an **authority** — who acts on that step. Four values: `sovereignty` (a human
must decide), `authority` (the framework enforces), `initiative` (an agent may act), `external`.

**Today authority is a property of the swimlane.** A lane carries
`<laneMeta authority="sovereignty"/>`, and a node's owner is found by scanning which lane's
`<flowNodeRef>` list contains that node's id. The frozen standard says so explicitly: *"a node's
owner MUST be its lane — there is no node-level owner override. The Lane is the sole
authority-of-record."* An earlier version HAD a node-level override and it was **deliberately
removed** to make the lane the single source.

Note the orthogonal attribute already on elements: `meta tier` (0..3), an enforcement tier.
`tier` is **not** authority — a tier-0 action is typically agent-*initiated* and human-*approved*,
i.e. `initiative` + `tier=0` on one element. Conflating them would make that unsayable.

### The proposal (M2): move authority onto the element

```xml
<!-- today -->
<lane id="human" name="Human · Sovereignty">
  <laneMeta abbr="hum" authority="sovereignty" height="88"/>
  <flowNodeRef>hum_1_human</flowNodeRef>
</lane>
<userTask id="hum_1_human" name="Human checks">
  <meta tier="0"/>
</userTask>

<!-- M2 -->
<lane id="human" name="Human">
  <laneMeta abbr="hum" height="88"/>                 <!-- no authority -->
  <flowNodeRef>hum_1_human</flowNodeRef>
</lane>
<userTask id="hum_1_human" name="Human checks">
  <meta tier="0" authority="sovereignty"/>
</userTask>
```

The lane becomes a **domain** — a grouping for layout and reading — and stops deciding anything.

**M1**, the cheaper variant: the element wins when it declares an authority, and lane authority
remains a *fallback default* when it does not. No migration, but it re-introduces the override
the standard deliberately removed.

### Why we want it

1. **Positional authority cannot survive instantiation.** G4 gates each step of a walked instance
   by who acts. Today that answer depends on which lane box a node was drawn in, and for imported
   third-party files on **laneSet serialisation order** — first lane wins. Gating execution on
   diagram layout is untenable.
2. **A measured defect.** An unresolvable `flowNodeRef` currently reassigns the orphaned node to
   whichever lane comes first in document order. Under M2 the defect disappears rather than being
   patched.
3. **One diagram is already built the M2 way.** Its three lanes are *Working Memory*,
   *Project Memory*, *Episodic Memory* — genuine domains, not authorities — so its author had to
   write `authority="none"` three times, a value absent from the four-value vocabulary and from
   the standard. The schema forced a lie.
4. **Tenant portability (G5).** Lanes-as-authority bakes in one actor model (human / framework /
   agent). A second tenant with different actors cannot reuse the templates. Domains are portable.

### Measured costs

- **24 of 24** diagrams carry lane authority — **67 lane values** (23 `authority`,
  23 `initiative`, 15 `sovereignty`, 3 `external`, 3 `none`).
- **306 `flowNodeRef`s** in the corpus. Under M2 each element needs its own value: 67 → up to
  306. **~4.5× more places to omit or get wrong.**
- **Lane names are overwhelmingly authority-shaped**: "Framework · Authority" ×22,
  "Agent · Initiative" ×21, "Human · Sovereignty" ×15. Only 3 lanes corpus-wide are named as
  domains. So 23 of 24 diagrams were *drawn* on the lane-as-authority model, and under M2 their
  lanes retain no meaning beyond visual grouping.
- A compile-time rule requiring a human-decision step to sit in a human lane must be rewritten
  against the element (3 implementation sites our side).
- **The standard is frozen and owned by the framework side, not by us.** We proposed this to them
  and have had no reply. A decision on our side does not bind them.
- Separately measured this week: document-level metadata attributes in our serialisation have
  **no round-trip guard** — proved by mutation that an identity attribute can be dropped from the
  writer with every test still passing. The seam we would migrate 306 values into has a known
  coverage hole. (Local repository only; not a remotely reachable weakness.)

## 7. The objection the first round produced, which we now carry

One reviewer argued M2 *"demotes the diagram from a primary governance artifact to mere compiler
input"* — that lane-as-authority is **visually auditable**, a stakeholder sees at a glance that
everything in the Human lane requires human sovereignty, and under M2 an
`authority="sovereignty"` node can sit in a lane named anything, so *"the diagram is no longer a
trustworthy document; it's a source of lies."*

We think that is the strongest argument against, and it cuts at our own purpose — §2 says humans
and agents work **the same picture**. Two of our success criteria (a non-technical reader answers
process questions correctly from the diagram; a business view lets a stakeholder answer
what/who/when) are unstarted and untested, so we cannot currently say whether that audience is
real or hypothetical for us.

## 8. Questions

1. **Is element-level authority right**, given the whole picture above — or is there a
   substantive argument for the lane remaining authority-of-record that we have dismissed? What
   might the standard's authors have been protecting when they removed the node-level override?
2. **Does the visual-auditability objection defeat M2, or is it satisfiable another way** — a
   validator rule that refuses an element whose authority contradicts its lane's declared domain,
   a rendering that paints authority per node, something else? We would rather keep the property
   than the mechanism.
3. **Is "rule M2 as the direction, implement M1's mechanism first" sound sequencing or a fudge?**
   M1 gives the execution property with zero migration and is forward-compatible; it is also
   knowingly non-conformant to a frozen standard we do not own. Is temporary deliberate
   non-conformance defensible here, or the start of permanent divergence?
4. **Is 67 → 306 the wrong trade?** Is there a third design — authority derived from element type
   plus a sparse override, or an explicit non-positional lane→authority binding — that gets the
   non-positional property without 4.5× duplication?
5. **Sequencing against the coverage hole:** guard first, or migrate first and guard after?
6. **Given goals G1–G6, is this the right thing to be working on at all?** One of us derived the
   trace from this proposal to five of the six goals, which is precisely the kind of reasoning
   that convinces its author and should not convince you.
