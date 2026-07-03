# T-057 — Friction-dry analysis: context-memory (three-tier fabric)

**Subject:** `examples/aef-processes/context-memory.workflow.yaml`
**Ground truth:** `.agentic-framework/agents/context/context.sh` (dispatcher, 62-96) + its
`lib/{init,focus,learning,pattern,decision,episodic,promote}.sh`; automatic episodic trigger
in `agents/task-create/update-task.sh:1254 / 1980`.
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and record
where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #19 — third of the four "constitutional gate" maps from the T-054 audit (after
task-gate / T-055, verification-gate / T-056).

## Verdict

**Schema expressivity: constructs available, 0 blocking gaps — but this map bent the lane axis
away from its intended meaning for the first time.** The three tiers mapped (Working seeded by
`init` + updated by `focus`; Project appended by `add-learning/pattern/decision`; Episodic
auto-generated on completion from task file + git log), plus the promotion path and the
completion→episodic auto-trigger. 12 nodes, 12 edges, 3 lanes; geometry clean on first author;
round-trip VALID (no findings — the reachability fix below was needed first); suite 23→24. The
map's `agentType` / `triggeredBy` / `emits` survived the bridge (dogfooding **T-060** a third
time). One headline schema friction, one sharpened recurrence, one authoring correction worth
recording.

## New candidate frictions

### FC-12 — the lane axis is single and authority-coupled  ⭐ headline
Every prior corpus map (18 of them) partitions lanes by the **AEF authority axis**
(initiative / authority / sovereignty). The Context Fabric's natural partition is the **three
memory tiers** — a *data* axis, orthogonal to authority. The schema offers exactly **one** lane
axis, and its lane-level `authority:` attribute presumes that axis *is* authority. Mapping by
tier therefore forced two compromises:
  1. Lanes carry `authority: none` — the attribute goes vacuous, because the partition isn't an
     authority partition.
  2. The real actor (agent-explicit `add-*` vs framework-automatic `generate-episodic`) had to
     migrate **out of the lane** and into per-node `aef.agentType` / `aef.determinism` metadata.
So a reader loses the at-a-glance "who acts" that lanes give every other map, and gains a
tier view the schema doesn't natively bless. **Why it matters:** BPMN pools express one
partition; when a process's meaningful structure is a *different* axis than authority, the
modeller must either abandon the tier view or abandon the authority view — they cannot coexist.
**Recommendation:** first map where the two axes genuinely compete — register, don't build
(PD-002). Candidates: a second (visual-only) grouping axis, or an explicit `lane.axis: authority
| data | none` field so `authority: none` reads as intent, not omission. Strongest
schema-expressivity finding in the corpus so far.

## Recurrences

### Cross-instance / temporal flow is not sequence flow (recurs: T-055 FC-8) ⭐
First draft drew two "recall" edges — `episodic → focus` and `learnings → focus` — to show the
fabric closing the loop (stored knowledge feeding the next session's briefing). The structural
validator correctly flagged **dead-ends / illegal endEvent-outflow**: an `endEvent` (`n_stored`)
cannot have an outgoing edge, and the recall is not a within-instance continuation at all — it is
a **new session** (`init`/`focus`) reading a durable file written by a *prior, terminated*
instance. Exactly T-055 FC-8's shape: a visible cycle that actually stitches a terminated
instance to a fresh one; the loop is **temporal, not control-flow**. Resolution: drop the recall
edges entirely and represent the read as `n_focus.aef.contextReads` (metadata: it reads
`learnings.yaml` / `patterns.yaml`). FC-8 now recurs 2× and is the clearest structural signal in
the corpus that the schema needs a **read/data-dependency edge distinct from sequence flow** (or
a link-event pair) to carry cross-instance recall without faking a control cycle.

### No datastore primitive — tier reads live in node metadata (sharpens FC-12)
Related: the schema has no `dataStore` / `dataObject`, so "focus reads the project tier" and
"episodic reads the task file + git" cannot be drawn as an artifact a node touches; both are
carried as `aef.contextReads` strings. Faithful and greppable, but invisible on the diagram — the
reads that make the fabric a *fabric* (not three disconnected flows) are textual, not visual.
Reinforces FC-12's data-axis gap. Modelling choice recorded, not a blocker.

## Authoring correction (recorded per §ACD)

The reachability failure was a *real* first-draft defect, caught by the validator, not a schema
gap: the session-capture flow (`start → init → focus → capture → learning/pattern/decision`)
had no terminating `endEvent`, and `promote`/`pattern`/`decision` were dead-ends. Fixed by adding
`n_persisted` (endEvent: "project memory durable") as the capture flow's terminal and routing the
three capture branches + promote into it. This is why the standalone structural validator
(reachability / dead-end, W-XML-DEADEND) earns its keep — it caught a genuine authoring error the
geometry gate cannot see. (PL-004: a gate is only worth its cost when run against the corpus — it
was, and it bit.)

## Outcome

Map committed to the corpus (24/24 suite, geometry sweep 19 clean, round-trip VALID). FC-12
(single authority-coupled lane axis) is the headline and the strongest expressivity finding to
date; FC-8 (cross-instance temporal flow) recurs 2× and now has two independent instances
pointing at the same missing primitive — a data/recall edge distinct from sequence flow. Per
PD-002 no schema change is built here. One constitutional-gate map remains (T-058,
error-escalation-ladder) to complete the T-054 audit series.
