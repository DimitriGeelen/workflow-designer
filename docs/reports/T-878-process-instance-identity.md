# T-878 — What is a process instance, where does its identity live, and what binds it to real governed work

**Inception.** arc-005 S2. Deliverable is a decision and a design; no production change.
Research artifact created before research per C-001. Measured 2026-09-27.

**The question, one sentence:** when we say `T-873` is an instance of `task-lifecycle`, what
object is that, where does it live, and what makes the claim true?

**Why it is open:** SD-10 was raised in the July 2026 process-layer package and never decided.
`DISPOSITION-2026-07-28.md` records it verbatim — *"no binding, no instance files, no gated
setter"*.

**Inherited, not re-litigated:** tasks are canonical (T-175 IW-1). A diagram *proposes*
governed work and never authors it. An instance binds to the task graph; it does not become it.

---

## 1. Findings

### F1 — Nothing binds an entity to a template, and the one exception I kept citing is inert

Three candidates checked:

| candidate | what it actually binds |
|---|---|
| designer registry (`web/designer_registry.py`, `fw bpmn claim`) | an `aef:link` ref uuid → a live project in the designer store. **Workflow-to-workflow** off-page connectors. Not entity-to-template. |
| task frontmatter | the only map-ish field across 872 task files is `workflow_type`, which is a **category** (`build`, `inception`, …), not a map reference |
| `update-task.sh:249` | prints `Map: aef-task-lifecycle node tl_archive enforces this` when the AC gate trips |

**The third one does not run.** It is guarded on
`.context/designer/projects/aef-task-lifecycle/meta.json`, and that file is **absent** — the
store holds six projects and none is named `aef-task-lifecycle`. Control: the sibling
`audit-process/meta.json` *does* exist, so the path shape is right and only the name is wrong.

**This corrects me.** I cited that hairline twice — in the T-835 report and in the arc-005
scope — as "one hairline of the eventual mechanism exists". It exists as *source*. It has
never *executed* in this project. SD-10's "no binding" is not merely still true; it is more
completely true than I represented.

It is also a live, small defect on its own: a hint written to point an agent at the process
picture, silently pointing at nothing. Worth its own task, not this one's.

### F2 — The map's nodes are not task states, so position cannot be derived for free

`task-lifecycle.bpmn` node ids:

```
frw_1_task  frw_11_task  agt_1_write  agt_2_perform  hum_1_human  frw_3_start
frw_4_enter agt_3_request frw_6_run   frw_8_partial  frw_10_finalize
frw_2_build frw_5_outcome frw_7_all    frw_9_human
```

Lane-prefixed (`frw`/`agt`/`hum`) + index + verb — **15 nodes** describing who acts. Task
`status:` has roughly five values (`captured`, `started-work`, `issues`, `partial-complete`,
`work-completed`).

There is no 1:1 correspondence and no mapping table anywhere. So "which node is T-873 on"
**cannot be computed from `status:`**. Any derivation needs a status→node mapping, and that
mapping is itself an authored artifact — which moves the authoring problem rather than
removing it.

This is the finding that most shapes the answer, and it cuts against the cheap option.

### F3 — The template side of the binding *is* derivable; the position side is not

Every task in this corpus instantiates `task-lifecycle` — that is what the map models. Every
inception additionally instantiates `inception-lifecycle`. The relation "entity kind →
template" is a small, closed, derivable mapping.

So the binding decomposes into two halves with different answers:

- **which template** — derivable from `workflow_type`, no authoring, no new identifier
- **which node** — not derivable (F2), and the expensive half

Treating "instance" as one indivisible thing is what has made SD-10 look large for fourteen
months of project time. It is two questions and only one of them is hard.

## 2. Assumptions under test

| # | assumption | verdict |
|---|---|---|
| A1 | Nothing already binds a real entity to a process template | **HELD** — and more strongly than stated (F1) |
| A2 | Identity for an instance must be minted | **FALSE** — see IW-3 |
| A3 | The binding must be authored because it cannot be derived | **HALF FALSE** — template derivable, node not (F3) |

Two of three assumptions came back wrong, which is the outcome an inception is for.

## 3. Dispositions

- **IW-1 — does anything already bind?** **No.** Three candidates checked, all negative, and
  the nearest one is inert source (F1).
- **IW-2 — where does instance state live?** A per-entity record is only needed for the half
  that cannot be derived: current node. Recommend the state live **beside the entity it
  describes**, not in a parallel store — a parallel store is a join to keep in sync and the
  corpus already has one such store whose naming has drifted out of alignment (F1).
- **IW-3 — minted identity, or existing?** **Existing.** `T-873` is already stable, unique,
  human-legible, and referenced corpus-wide. A minted uuid for the same object is a second
  identifier for one thing, a join to maintain, and something to drift. The instance's
  identity should BE the entity's id. (Contrast the designer store, where a ghost uuid exists
  precisely because there is no other identifier yet.)
- **IW-4 — authored or derived?** **Both, split by half** (F3): template derived from
  `workflow_type`; node position recorded, because F2 shows it cannot be computed.
- **IW-5 — resolution with no instance?** An explicit `no instance` result, distinguishable
  at the call site from `template known, node unknown`. Three states, not two — and the
  middle one will be the common case for every task that predates the mechanism.

## 4. Recommendation

**Recommendation:** GO — on the reduced scope F3 identifies, not on the scope this inception
was filed with.

**Rationale:** The question is answerable and two of its three assumptions were wrong in the
cheap direction. No new identifier is needed (IW-3) and half the binding needs no authoring
at all (F3). What remains is one genuinely new thing: a recorded current-node per entity,
needed because F2 proves it cannot be derived from task status.

That is a materially smaller mechanism than "instance files, identity scheme, gated setter"
as SD-10 framed it, and it is smaller than what arc-005's scope document assumed when it
filed T-880 and T-881. Those two tasks should be rewritten against F3 rather than adapted —
their own bodies already say a different design means rewrite, not adapt.

**What a NO-GO would have looked like, so the GO is not reflexive:** if F2 had shown a clean
status→node correspondence, the honest answer would have been NO-GO on building anything —
resolution would have been a query over existing data and needed no instance object at all. I
checked for that first and it is not there.

**Evidence:**
- F1 — three binding candidates checked, all negative; `update-task.sh:249` guarded on an
  absent file, verified with a positive control on a sibling path.
- F2 — 15 lane-prefixed node ids against ~5 task statuses, no mapping table in the tree.
- F3 — `workflow_type` is a closed set and the corpus holds a template per entity kind.

**Not decided here, and not the agent's to decide:** whether to build it. This inception is
`owner: agent` and produces the proposal; the go/no-go is recorded by the operator, and I am
structurally barred from the verb that records it.
