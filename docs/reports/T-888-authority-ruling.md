# Ruling — a lane is a partition; the element carries authority

**Operator ruling, 2026-09-27.** Recorded under T-888. Supersedes the M1/M2/M0 framing that
T-835 put to the operator.

**Evidence:** four external consults, five models each, in
`.context/consults/{m2-lane-authority, m2-lane-authority-full, views-perspectives,
lane-partition-forced-authority}.json`. Three proposals were killed in the process — two of the
agent's and one of the operator's.

---

## The ruling

1. **A lane is a partition. Its meaning is declared by the modeller** — actor, business domain,
   subsystem, department, phase, anything. The framework does not fix one meaning.
2. **The element carries its authority.** One field, one home, **the single semantic fact**. The
   compiler reads it directly: never by scanning lane membership, never resolved by document
   order.
3. **A lane MAY carry a presentational `authoringDefault`.** It pre-fills the authority of
   elements newly created in that lane. It is in the **presentational** class of the frozen
   standard's §1 partition, so the forward compile is *forbidden* to read it and a change to it
   **MUST be a no-op for the task graph**. Absent means the lane declares no default — there is
   deliberately no `none` sentinel.
4. **Authority is rendered per element**, and mismatch against the lane default is indicated —
   **in the editor and in the validator**, distinguishing *differs* from *missing*.

## Why lane-as-authority is retired as a universal rule

The frozen standard v1.1 §3 says *"a node's owner MUST be its lane — there is no node-level owner
override. The Lane is the sole authority-of-record."*

That hardened **one tenant's convention into a universal MUST**. Measured: 60 of 67 lanes in the
whole authored corpus are named `Framework`, `Agent` or `Human` — the actor triple — because all
24 diagrams are that one tenant modelling its own governance processes. There is not one lane
named for a business domain, a subsystem or a department anywhere in the corpus.

A general mechanism (project goal **G5**, tenant-neutrality) cannot require that every project's
chosen partition also be its authority partition. BPMN's own position agrees: lane meaning is
modeller-defined and lanes carry no execution semantics. As one reviewer put it unprompted —
*"Authority-in-the-lane is already your extension, not a BPMN fact."*

## How this answers every surviving objection

Four rounds of external review produced five distinct objections. Each is answered by a specific
clause rather than overridden:

| objection | round | answered by |
|---|---|---|
| *"Replaces an architectural guarantee with a lint rule"* — lane-as-authority is correct-by-construction | 1 | **clause 4.** The picture is honest at the level where the fact lives. Authority is drawn on the node, so the lane no longer needs to imply it. |
| *"A view is a function of a stored fact; independently edited `flowNodeRef` lists are N facts"* | 3 | **clause 2.** One semantic fact. No second partition, no discriminator. |
| *"`forceAuthority` is a second stored claim; stickiness is a third. Three homes, one semantic"* | 4 | **clause 3.** Presentational. The compiler is structurally forbidden to read it, so it cannot be a claim about authority at all. |
| *"Cognitive load of invisible state"* — was it sticky, which lane now, did a drag re-stamp it | 4 | **clause 4.** The state is visible **by design**. No stamping, no stickiness rule, nothing hidden. |
| *"A git merge of non-overlapping lines produces a contradiction"* | 4 | **clause 3.** Nothing to contradict. A merge that changes the default only changes which elements are flagged. |

**The decisive move is that the default never writes.** Changing a lane's `authoringDefault`
re-renders; it never re-stamps. That removes the drift vector that killed the previous three
designs, and it makes the default *more* useful rather than less: set it on a lane and every
exception lights up at once. It is an audit affordance, not only a convenience.

## What the indicator must distinguish

Following this project's own grammar — *not evaluated* is not *passed*, and *missing* is not
*different*:

| element state | indicator | meaning |
|---|---|---|
| authority matches the lane's `authoringDefault` | **none** | the common case must not shout |
| authority **differs** from the default | subtle marker | a legitimate authorial choice, made visible |
| **no** authority at all | louder marker | not a choice — a hole, and a compile error |

## What this decision does NOT change

- **arc-005 (class and instance) is unaffected** and proceeds independently. The lane-authority
  question was framed as a G4 dependency and, on measurement, is not one beyond the orphan case:
  for a node that *is* in a lane, authority is deterministic today. The positional defect is
  **only** the orphan/unresolvable-`flowNodeRef` case.
- **The frozen standard's Part I is not edited by the agent**, under any circumstance. This
  ruling is a proposal to the counterparty for §3 and an additive request for §1's presentational
  list. It does not bind them and nothing is edited on their behalf.
- **T-341 and T-358 are not closed here.** Their open `[REVIEW]` criteria are the operator's and
  are untouched. What this ruling does is make them answerable — see below.

## Downstream, named and checked

**T-341** — *an unresolvable `flowNodeRef` silently reassigns the orphaned node to the human
lane.* Under clause 2 the authority half dissolves: an element's authority no longer depends on
lane membership at all, so no orphan inherits anything. The surviving half is the **placement**
question (which lane box does an unassigned node draw in), which is layout, not governance. The
hard-error fix for an unresolvable ref is correct under every version of this design and is
filed as its own task.

**T-358** — *the importer fabricates 3 lanes and 1 participant.* Under clause 1 a third-party
file with no lanes declares no partition; nothing is missing, so nothing needs fabricating, and
`E-XML-LANES-EMPTY`'s objection to option A dissolves. The **participant/pool** fabrication
survives as a separate question — a pool is not a lane.

**`E-XML-LANES-EMPTY`** should be re-pointed at the real predicate. Measured under T-835: it
already fails in both directions — it rejects a lane-less third-party document that is fine, and
it **passes** `context-memory.bpmn`, the one file with 12 nodes that have no derivable owner,
because that file *has* lanes. Under this ruling the honest rule is "every task-like element has
an authority", which is clause 4's louder marker promoted to an error.

**`authority="none"`** retires. `context-memory.bpmn`'s three lanes — *Working Memory*,
*Project Memory*, *Episodic Memory* — are a domain partition. Under clause 1 they need no
authority, and the sentinel its author was forced to invent goes away.

## Cost, stated plainly

- **67 lane authority values across 24 diagrams** become element values. Generated from the lane
  during migration rather than hand-written, but it is a rewrite of a seam the counterparty
  byte-pins.
- **A compile-time rule** requiring a human-decision step to sit in a human lane must be
  rewritten against the element — 3 implementation sites our side.
- **Two schema additions**, one semantic and one presentational, both requiring the counterparty's
  agreement. The presentational one is a much smaller ask than amending §3.
- **The migration is sequenced behind a guard that does not yet exist.** Document-level metadata
  attributes in our serialisation have no round-trip guard — proved by mutation under T-885 that
  an identity attribute can be dropped from the writer with every test still passing. Migrating
  governance values into that seam before the guard exists is the wrong order.

## Provenance of the design, recorded because it matters

The surviving design is the operator's. Every agent contribution to it was killed by external
review:

- the agent proposed **element-authority alone** → killed round 1
- the agent proposed **multi-laneSet views** (elaborating the operator's view idea) → killed round 3
- the agent proposed **generator-not-checker stamping** → killed round 4 as *"semantic trickery"*
- the agent's trace from proposal to five of six project goals was flagged **by the agent** at the
  time as reasoning that convinces its author, and it was

What survived four rounds is clauses 1 and 2, which the operator stated. Clauses 3 and 4 are the
operator's refinements, constrained by the standard's own two-class rule rather than by anyone's
discipline — which is what the panel kept asking for.
