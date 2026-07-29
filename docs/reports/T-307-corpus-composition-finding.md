# Shared exploration finding: the corpus expresses cross-process relationships as prose, not edges

**Produced during:** the T-307 exploration campaign, 2026-07-29 · **Bears on:** T-280 (Workflow Fabric SD-15), T-282 (callActivity SD-9), and secondarily T-184

## What was checked

All 24 rendered corpus maps (`examples/aef-processes/rendered/*.bpmn`) and all 24 YAML sources
(`examples/aef-processes/*.workflow.yaml`), for any structural cross-process reference:
`linkEventThrow`, `linkEventCatch`, `targetWorkflow`, `workflowRef`, `aef:link`.

## Result

**Structural cross-process references in the corpus: zero.** Not one rendered map contains an
`aef:link`, a `targetWorkflow`, or a link event. Every map is self-contained.

Four YAML sources matched a keyword search, but on inspection **all four are prose in comments**, not
model content:

- `assumption-validation` — *"invalidated assumptions become gaps/risks — cross-process handoff"*
- `healing-loop` — *"returns control to the task lifecycle (T-022) — cross-process handoff"*
- `audit-process` — *"a sub-process handoff (F5)"*
- `review-emission` — *`x-handoffTo: human sovereignty (Watchtower, out-of-band — see FC-7)`*

I checked this specifically because a source-vs-rendered mismatch would have indicated handoffs being
lost during rendering. It is not that: there is no rendering defect. The sources never carried
structural links either.

## Why this matters more than "the feature has nothing to operate on"

The naive reading is that cross-process composition is unused, so anything built on it (a dependency
graph, a call node) would operate on an empty set. That reading is wrong, and the correction is the
useful part:

**The relationships exist. They are simply recorded in a form no tool can query.** Four of
twenty-four maps have authors explicitly reaching for cross-process semantics and, finding no
vocabulary for it, writing an English comment instead. That is not absence of demand — it is demand
being absorbed by a workaround, which is the harder signal to see and the one that does not show up
in usage metrics.

## Bearing on the open inceptions

**T-280 (Workflow Fabric — process-dependency graph).** This reverses the framing in the T-307
brief. I wrote there that the graph would have nothing to operate on; that is only true of the
*machine-readable* corpus. The edges exist in four maps today and are invisible to tooling. The
real question for T-280 is therefore not "is there a graph to build" but "should these relationships
become modelled edges" — a question about vocabulary, which is 832-side and answerable, ahead of the
graph query layer, which is AEF-side. That is a materially better-shaped question than the one the
filing stub posed.

**T-282 (callActivity — synchronous call-with-return).** The finding cuts the other way. Every
prose relationship found is *handoff* or *return-of-control* semantics — asynchronous continuation,
which link events already model. None is call-with-return with an input/output contract, which is
what `callActivity` uniquely provides. So the corpus shows demand for **composition vocabulary in
general** but specifically **not** for `callActivity`. Its DEFER survives this evidence; the general
composition question does not belong to it.

**T-184 (reverse discovery).** Weak secondary signal: if AEF's record contains process
relationships that our corpus can only express as comments, a reverse render would face the same
vocabulary gap in the other direction. Worth carrying into that exploration.

## Suggested follow-up

The cross-cutting question this surfaced — *should cross-process relationships be modelled edges
rather than comments, and in what vocabulary?* — is not owned by any of the nine open inceptions. It
sits upstream of T-280 and T-282 both. It may deserve its own inception rather than being answered
twice, badly, inside two narrower ones.
