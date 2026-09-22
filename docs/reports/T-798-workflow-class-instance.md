# T-798 — Workflow class and instance: the runs already exist, unmodelled

**Origin: the operator.** Their framing, which we had not made:

> *"We have workflow designs, the process designs, and we have the instantiation of the
> process, where we want to track the execution… an inception is a workflow class. A new
> inception will be instantiated from that workflow class and can be synchronized and tracked
> through that instantiation… which then gets linked to that task."*

T-797 established that no layer models a run. This task measures what that costs, and finds
the proposal is far smaller than "build an instance layer".

---

## 1. The instances already exist — about 1,500 of them

AEF's process designs are not aspirational. They run those processes constantly:

| design (in our corpus) | its runs | where they live |
|---|---|---|
| `inception-lifecycle.bpmn` | **44** | inception tasks |
| `task-lifecycle.bpmn` | **797** | every task |
| `session-handover.bpmn` | **656** | `.context/handovers/` |
| `arc-lifecycle.bpmn` | **3** | `.context/arcs/` |

**~1,500 runs of 7 designs, today, with zero linkage back to the design they are runs of.**
An inception *is* a workflow class; T-788 *is* an instance of it. Nothing records that.

## 2. The class pointer already exists — it just does not resolve

Every task carries `workflow_type: inception`. **That is the class name.** It is read as a bare
string everywhere:

    resolver.py:1060   "workflow_type": str(fm.get("workflow_type", "")).strip().lower()

Nothing joins it to a design document. No `.bpmn`, no `.workflow.yaml`, no resolution.

**Contrast with `arc_id`, in the same framework, which DOES resolve:**
`check-arc-id.py` verifies `.context/arcs/<arc_id>.yaml` exists and **blocks under agent
control** when it does not.

So the resolving-reference pattern is already built, already gated, and already in production
one field over. `workflow_type` is the same shape with the resolution missing.

**That reframes the proposal.** Not "invent an instance model" but *"make the pointer you
already have resolve"* — after which ~1,500 existing runs become tracked instances of a design
**retroactively**, with no migration.

## 3. The design question that does NOT resolve itself

Two diagram-to-work mappings, and they are incompatible:

| | mapping | example |
|---|---|---|
| **(a) today, `fw bpmn compile`** | **node → task** — a design becomes a backlog | `release-pipeline` |
| **(b) what an instance needs** | **run → ?** — and the answer differs by shape | `inception-lifecycle` |

For a **lifecycle** design, one run is **one task passing through the nodes as states**: T-788
went captured → started-work → work-completed. The nodes are *states*, not tasks. Compiling
node→task there would produce a task called "explore" and a task called "decide", which is not
what an inception is.

For a **pipeline** design, one run plausibly *is* a set of tasks — mapping (a).

**Both shapes are in the corpus.** This does not resolve itself, and choosing silently is worse
than leaving it open.

## 4. Whose is it?

**AEF's, by their own argument at @1631.** They claimed Child-2 because *"the `.tasks/` write
never leaves our task-gate perimeter."* An instance that tracks task execution **is task
state** — same perimeter, same reasoning.

Two questions put to them at `sidecar:999-Agentic-Engineering-Framework` **@6**
(correlation `832-T798-WORKFLOW-CLASS-INSTANCE`):

- **Q1** — is the instance layer yours, as Child-2 was? *"Nobody owns this"* is a complete and
  useful answer.
- **Q2** — if yours, does the lifecycle/pipeline split match how you would model it, or is
  there a third framing we are missing?

## 5. What this task did not do

No schema proposed, nothing built, the frozen standard untouched. The measurement is ours; the
design is theirs. Guessing at a schema and shipping an exporter for it is the T-786 error with
a larger radius — and this time there would be no frozen document to catch it.

**If AEF says the layer is unclaimed,** that is the point at which it becomes an open question
for the operator, and a materially different one from T-788: nobody would be duplicating
anything, because nobody has built it.
