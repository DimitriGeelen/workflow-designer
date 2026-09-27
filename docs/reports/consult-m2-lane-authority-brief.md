# Proposal under review: move authority from the swimlane to the element

## Context

We maintain a BPMN-based process modelling tool and a mapping standard that compiles BPMN
diagrams to and from a task/governance graph. Diagrams model organisational processes; a
compiler reads them and produces governed work items.

Every flow node in a diagram has an **authority** — who acts on that step. The vocabulary is
four values: `sovereignty` (a human must decide), `authority` (the framework enforces),
`initiative` (an agent may act), `external` (outside party).

**Today authority is a property of the swimlane.** A lane carries
`<aef:laneMeta authority="sovereignty"/>`, and a node's owner is derived by finding which
lane's `<bpmn:flowNodeRef>` list contains that node's id. The standard (frozen at v1.1) states
it explicitly: *"a node's owner MUST be its lane — there is no node-level owner override. The
Lane is the sole authority-of-record."* An earlier version had a node-level override and it was
**deliberately removed** to make the lane the single source.

There is a separate, orthogonal attribute already on elements: `<aef:meta tier="0..3"/>`,
an enforcement tier (0 = needs human approval, 3 = pre-approved). 198 elements carry `aef:meta`
today. Tier is *not* authority — a tier-0 action is typically agent-initiated and
human-approved, i.e. `initiative` + tier 0 on the same element.

## The proposal (call it M2)

Move authority onto the element:

```xml
<!-- today -->
<bpmn:lane id="human" name="Human · Sovereignty">
  <aef:laneMeta abbr="hum" authority="sovereignty" height="88"/>
  <bpmn:flowNodeRef>hum_1_human</bpmn:flowNodeRef>
</bpmn:lane>
<bpmn:userTask id="hum_1_human" name="Human checks">
  <aef:meta tier="0"/>
</bpmn:userTask>

<!-- M2 -->
<bpmn:lane id="human" name="Human">
  <aef:laneMeta abbr="hum" height="88"/>            <!-- no authority -->
  <bpmn:flowNodeRef>hum_1_human</bpmn:flowNodeRef>
</bpmn:lane>
<bpmn:userTask id="hum_1_human" name="Human checks">
  <aef:meta tier="0" authority="sovereignty"/>
</bpmn:userTask>
```

The lane becomes a **domain** — a grouping for layout and reading — and stops deciding anything.

A cheaper variant (**M1**) keeps lane authority as a *fallback default* used only when the
element does not declare one. No migration; but it re-introduces the node-level override the
standard deliberately removed.

## Why we want it

1. **Positional authority cannot survive execution.** We intend to instantiate a template and
   walk instances of it, gating each step by who acts. Today "who acts" depends on which lane
   box a node was drawn in, and for imported third-party files on **laneSet serialisation
   order** — the first lane wins. Gating execution on diagram layout is untenable.
2. **A measured defect.** An unresolvable `flowNodeRef` currently reassigns the orphaned node to
   whichever lane is first in document order. That defect disappears under M2 rather than being
   patched.
3. **One of our 24 corpus diagrams is already built the M2 way.** Its three lanes are
   *Working Memory*, *Project Memory*, *Episodic Memory* — genuine domains, not authorities —
   so its author had to write `authority="none"` three times, a value that is not in the
   four-value vocabulary and appears nowhere in the standard. The schema forced a lie.
4. **Tenant portability.** Lanes-as-authority bakes in one actor model (human/framework/agent).
   A second tenant with different actors cannot reuse the templates. Domains are portable.

## Measured costs

- **24 of 24** diagrams carry lane authority — **67 lane values** total (23 `authority`,
  23 `initiative`, 15 `sovereignty`, 3 `external`, 3 `none`).
- **306 `flowNodeRef`s** across the corpus. Under M2 each element needs its own authority value:
  67 values become up to 306. **~4.5× more places to omit or get wrong.**
- **Lane naming is overwhelmingly authority-shaped**: "Framework · Authority" ×22,
  "Agent · Initiative" ×21, "Human · Sovereignty" ×15. Only 3 lanes in the whole corpus are
  named as domains. So 23 of 24 diagrams were *drawn* on the lane-as-authority model; under M2
  their lanes retain no meaning beyond visual grouping.
- A compile-time rule requiring a human-decision step to sit in a human lane must be rewritten
  against the element (3 implementation sites on our side).
- **The standard is frozen and owned by a counterparty**, not by us. We proposed this to them
  and have had no reply. A decision on our side does not bind them.
- Separately measured this week: document-level metadata attributes in our serialisation have
  **no round-trip guard** — we proved by mutation that an identity attribute can be dropped from
  the writer with every test still passing. So the seam we would migrate 306 governance values
  into has a known coverage hole.

## The questions we want answered

1. **Is element-level authority the right model**, or is there a substantive argument for the
   lane remaining the authority-of-record that we have dismissed too quickly? The standard's
   authors deliberately removed the node-level override — what might they have been protecting
   that we are about to reintroduce?
2. **Is "rule M2 as the direction, implement M1's mechanism first" sound sequencing, or a
   fudge?** M1 delivers the execution property with zero migration and is forward-compatible;
   it also re-introduces the override the standard removed, so we would be non-conformant in a
   way we intend to fix later. Is "non-conformant on purpose, temporarily" a defensible
   engineering position here, or the beginning of a permanent divergence?
3. **Is 67 → 306 values the wrong trade?** Redundancy at 306 sites is real. Is there a third
   design we have not considered — for example authority derived from element *type* plus a
   sparse override, or a declared lane-to-authority binding that is explicit rather than
   positional — that gets the non-positional property without the 4.5× duplication?
4. **Sequencing against the coverage hole:** we know document-level attributes are unguarded.
   Should the guard come first, or is migrating first and guarding after acceptable?
5. **What are we not seeing?** We have been inside this problem for weeks and one of us
   generated the trace from proposal to project goals, which is exactly the kind of reasoning
   that convinces its author.
