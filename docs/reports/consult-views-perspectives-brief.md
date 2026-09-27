# Design review: is a swimlane partition a VIEW rather than a fact?

**Third round.** Round one asked whether to move process authority from the swimlane onto the
element. Four of four reviewers argued against it, and the strongest objection was that the
proposal *"replaces an architectural guarantee with a lint rule"* — lane-as-authority is
correct-by-construction (you cannot draw a human-sovereignty node inside an agent lane), while
element-authority is correct-by-validation (the node can claim anything, the file stays valid
and becomes semantically a lie).

**That objection landed and the proposal was dropped.** What follows is a different idea,
proposed by our operator after reading it. We want it killed if it can be killed, and we are
suspicious of it precisely because it feels elegant to us.

---

## 1. The system, briefly

Two components in a deliberately acyclic relationship. A **governance framework** holds a task
graph, enforcement tiers and audit rails, with an authority model: humans hold sovereignty and
are accountable; the framework holds authority and enforces; agents hold initiative and may
propose but never decide. A **process designer** (our project) authors BPMN diagrams that the
framework compiles into proposed governed work. We own the BPMN ⇄ task-YAML mapping standard,
frozen at v1.1; the framework vendors a pinned build of our editor and never edits it.

The purpose: *capture a process completely enough to execute it, and let humans and agents work
the same picture from idea to running implementation.* Processes are modelled as **classes** and
run as **instances** — a `task-lifecycle` diagram is a class; a real task id is an instance of
it — and an instance can be watched as it advances, with a step that is not permitted refused
rather than taken.

## 2. Where authority lives today

Every flow node has an authority: `sovereignty`, `authority`, `initiative`, `external`. It is a
property of the **lane**: `<laneMeta authority="sovereignty"/>`, and a node's owner is found by
scanning which lane's `<flowNodeRef>` list contains that node's id.

The frozen standard: *"a node's owner MUST be its lane — there is no node-level owner override.
The Lane (its `laneMeta authority`) is the sole authority-of-record."* An earlier version had a
node-level override and it was **deliberately removed**.

**Two real defects with the current model:**

1. **Authority is positional for the orphan case.** An unresolvable `flowNodeRef` reassigns the
   orphaned node to whichever lane comes first in document order. For imported third-party files,
   authority therefore depends on **laneSet serialisation order**.
2. **The lane is overloaded.** One of our 24 diagrams has lanes *Working Memory*,
   *Project Memory*, *Episodic Memory* — plainly **domains**, not authorities — so its author had
   to write `authority="none"` three times, a value absent from the vocabulary and from the
   standard. Across the corpus, 58 of 67 lanes are named for authorities
   ("Framework · Authority" ×22, "Agent · Initiative" ×21, "Human · Sovereignty" ×15) and only 3
   are named as domains. The lane is doing two jobs and the schema only admits one.

## 3. The proposal: a lane partition is a VIEW

**A process is partitioned many ways, and each partition is a view on the same reality.**

- an **authority** view — who acts (sovereignty / authority / initiative / external)
- an **architectural domain** view — which subsystem or component owns the step
- a **business domain** view — which business capability or department the step belongs to

The same flow nodes appear in all of them, grouped differently. One is declared **normative for
compile** — the authority view — and the compiler reads only that one.

BPMN appears to permit this natively: `laneSet` is `0..*` on `Process`, apparently for exactly
this reason, and a lane may carry a `childLaneSet`. Diagram interchange allows multiple
`BPMNDiagram`/`BPMNPlane` elements, so each view could carry its own geometry.

```xml
<process id="p">
  <laneSet id="ls_authority" name="Authority">        <!-- normative for compile -->
    <lane id="human" name="Human"><laneMeta authority="sovereignty"/>
      <flowNodeRef>approve</flowNodeRef></lane>
    <lane id="agent" name="Agent"><laneMeta authority="initiative"/>
      <flowNodeRef>draft</flowNodeRef><flowNodeRef>publish</flowNodeRef></lane>
  </laneSet>

  <laneSet id="ls_business" name="Business domain">   <!-- same nodes, regrouped -->
    <lane id="editorial"><flowNodeRef>draft</flowNodeRef><flowNodeRef>approve</flowNodeRef></lane>
    <lane id="distribution"><flowNodeRef>publish</flowNodeRef></lane>
  </laneSet>
</process>
```

### Why we think this is better than what round one rejected

- **Correct-by-construction survives.** In the authority view a node *is* in the sovereignty
  lane, visibly. Nothing is demoted to a validator's opinion. This was the objection that killed
  the previous proposal, and this design does not incur it.
- **The positional defect still dies.** Authority becomes membership in a partition *declared* to
  be the authority partition, rather than whichever lane happens to come first.
- **Zero element-level values.** The previous proposal would have turned 67 lane values into up
  to 306 element values. This adds none.
- **It may require NO change to the frozen standard.** "A node's owner MUST be its lane" remains
  true — its lane *in the authority partition*. No node-level override is introduced. That
  removes the largest political cost, since we do not own the standard and the counterparty has
  not answered our earlier proposal.
- **The overloaded lane is un-overloaded.** The memory-type diagram simply has a domain partition
  and no authority partition; `authority="none"` stops being a lie the schema forced.
- **Tenant portability.** A second, unrelated tenant reuses the business-domain view and supplies
  its own authority view — the same class serving a different actor model.

### Costs we already know about

- **Nothing supports it today, and we break it silently.** Our editor collects every `laneSet`
  and then iterates `laneSets[0]` only; our validator uses a singular `find`. A file with two
  partitions loses one **without a word**, and on save we would write the survivor back as the
  whole document. We have an existing bug of exactly this shape elsewhere (`processes[0]`
  discarding later processes in a real third-party file). No diagram in our corpus has more than
  one `laneSet`, so nothing exercises it.
- **Rendering.** Two partitions of the same nodes cannot both be horizontal bands at once. Views
  would switch, and each needs its own layout. Our diagram-interchange handling is already the
  most fragile part of our import path.
- **A new marker** is needed to say which partition is normative, e.g.
  `laneSetMeta kind="authority|architecture|business"`.
- **Partition totality becomes a per-view rule** — each node in exactly one lane per laneSet.
  More validation, though of a structural property rather than a semantic claim.
- **Authoring burden.** Someone must maintain N partitions and keep them coherent as the process
  changes.

## 4. Questions

1. **Kill it if you can.** What is the strongest argument that multi-view partitioning is worse
   than a single lane partition plus a separate authority mechanism? We are aware that "model the
   same thing three ways" is a classic source of drift.
2. **Is our reading of BPMN right?** Is `laneSet 0..*` genuinely intended for multiple
   *alternative* partitions of one process, or is it intended for something else — nested
   sub-partitions, or pool-scoped grouping — such that we would be abusing the construct? Cite
   the specification if you can. **If we are wrong about this, say so plainly; the whole design
   rests on it.**
3. **How do real tools behave?** If a mainstream BPMN tool imports a two-laneSet file, what
   happens? If the answer is "most tools drop the second", then this design is unportable in
   practice regardless of what the spec permits, and portability is one of our stated
   constitutional directives.
4. **Drift.** N partitions over one node set will diverge as the process is edited. Is
   per-view partition totality plus a coherence rule sufficient, or is there a known better
   pattern for keeping multiple classifications of one structure honest?
5. **Is the authority view special enough to deserve different treatment?** Governance is
   compiled and enforced; business domain is documentation. Should the normative partition be a
   laneSet at all, or something that cannot be confused with a view?
6. **Are we solving the right problem?** The concrete defects are (a) orphan nodes taking
   authority from document order and (b) one diagram whose lanes are domains. Both are small. Is
   a multi-view architecture a proportionate response, or would two narrow fixes — make orphan
   handling explicit, and allow a lane to declare itself non-authority-bearing — deliver the
   value at a fraction of the cost? **We would rather hear that than be encouraged.**
