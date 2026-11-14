# Brief for an external review: the project objectives of a workflow designer (T-1072)

You are reviewing a set of written project objectives before the project's owner (the "operator") ratifies them.
Your job is to find the **strongest objection**: where an objective is wrong, unmeasurable, contradicts the
operator's own words below, contradicts the main consumer's position below, or where something important is missing.
Be concrete; cite the objective id. Do not rewrite the whole document; name problems and propose the smallest fix.

## The product

A browser-based workflow designer (a single HTML file, BPMN as the portable format) used as the process-authoring
surface of an agentic engineering framework ("AEF", its main consumer). Humans and AI agents draw processes as
templates; instances of those processes are tracked; AEF has (or is building) a runtime that executes ratified
procedures exported from the designer. The designer never executes anything itself.

## The operator's own words (verbatim, from recorded conversations)

- The yardstick: "The workflow designer and its integration with AEF, and our ability to facilitate the agent and
  human collaboration to iterate from the workflow to actual working applications."
- On guarding: "I always want to override, or have to override option. Yes, it can give me friction. Can it really
  ask me… or ask me not to do it lightly. But I want to be the final authority." Ruled: advisory plus friction, never a
  hard block; "the hatch never closes"; strictness is earned by repetition.
- On drafts vs runs: "When you're still drafting a process … the instance can be run and the boundaries are less
  strict. … you need to have the ability to navigate around blockades."
- On execution: "we want to go very much to deterministic execution. That's most effective. Repeatable, reliable,
  quick. However we do want to fall back on stochastic if it goes wrong, or is an error, or an edge case, or on
  unclarity." And: "the more we get confident, the more we go to deterministic execution of our processes."
- On routing: worker kinds "framework, primary, coder or any … needs to be expandable … this will also tie in to
  orchestration … we want it in the box" (i.e. captured on the workflow element).
- On observability: "If we fire something off and it has no output, I want to know that. … I want to know if it
  succeeds in an hour, or if it just fades into darkness." And: "If I am not getting data or telemetry showing that
  they are executed, that warrants an investigation."
- On learning: "how do we build in signals that we can have a feedback loop for learning and adjusting that risk
  assessment. That's key. Otherwise we just keep doing stupid things."
- On humans in the loop: "We want them in the spots where it really matters, which is destructive actions, risky
  actions, or just where the agent is just not sure what to do."
- Product constraint: plugins must be independent and standalone, no dependency on any service.

## The main consumer's position (AEF, 2026-11-14, on an earlier version of this draft)

1. Advisory-not-block fits the designer, but hard refusal must stay on the runtime side: the designer warns and adds
   friction and never blocks authoring; refusal is runtime behaviour the designer shows faithfully.
2. The designer must not ratify, resolve secrets, launch actions or approve gates; authoring conforming definitions
   and the diagram-to-procedure export are the designer's side.
3. Routing should be phrased as a captured preference, not a guarantee (the runtime selects and refuses). A learning
   loop must be a proposal (a new version, re-ratified), never a silent edit: a ratified procedure is immutable.
4. Missing objective they want: a lossless round trip of the versioned interchange contract (BPMN to procedure) within
   the frozen mapping-standard boundaries; "that is what we consume".

## The draft under review (verbatim)

Headline: Workflow Designer is AEF's process add-on, for process authors, AEF agents and operators: it captures a
process completely enough to execute it, so that a human and an agent can work the same picture from idea to running
implementation. Processes are modelled once as templates (classes) and run many times as instances, for AEF and for
other tenants.

- **O-1** A step on the diagram carries everything an implementer needs (its inputs, outputs, decisions, the artifacts
  it reads and writes, and its pseudocode), so the picture alone is enough to implement from. *Measure:* a reader
  implements a step from the diagram with no recourse to the task text; proxy until then: every carrier, pseudocode
  included, exists and round-trips.
- **O-2** A map says whether it is a template or a work-plan, so a picture of a process is refused when something tries
  to promote it into real governed work. *Measure:* the marker exists and survives save and load, and AEF's promote
  path refuses an unmarked documentation map.
- **O-3** Every real instance knows which template it follows and which step it is on, and the system can answer that.
  *Measure:* asked "what process is T-NNN following?", the framework answers with its template and its current node.
- **O-4** A running process is observable, and the designer guards with advice and friction, never a hard block: it
  warns when a step is out of order, a human gateway is skipped or an input contract is unmet, always lets the author
  override with a record, and grows stricter only as a process earns it by repetition. Refusal is AEF's runtime
  behaviour, which the designer shows faithfully; the designer itself never blocks authoring. *Measure:* each case
  raises a visible warning and a logged override, never a block; a runtime refusal is shown on the step it refused;
  the operator can see which step an instance is on, which it failed at, and why; the override is never removed.
- **O-5** The machinery is tenant-neutral: a second, unrelated application models and runs its own processes with it.
  *Measure:* the second tenant (a named second application) carries its own templates and instances.
- **O-6** Work can start as a picture and existing work can be seen as one: forward-compile and reverse-render both
  hold between the designer and AEF. *Measure:* a re-pin round-trips the corpus byte-identically with no hand repair;
  rendering existing work as a picture: not measured yet.
- **O-7** A step can declare how it is meant to run: deterministic first (script or service), with an agentic fallback,
  and which kind of worker or model should take it. This routing is a preference captured in the workflow element;
  selection and refusal stay with the runtime. *Measure:* executor kind and a routing preference are authorable on a
  step, survive save, load and export, and reach AEF as declared preferences; nothing in the designer selects or
  guarantees a worker.
- **O-8** A process learns from use: deviations from the template can be turned into a proposed change, sent to AEF as a
  new version for ratification, never applied silently to a ratified procedure. *Measure:* a recorded deviation can be
  raised as a template-change proposal naming the version it departs from; the ratified template stays unchanged until
  AEF ratifies the new version.
- **O-9** The interchange with AEF is lossless: a map round-trips through the versioned interchange contract (BPMN to
  procedure and back) within the frozen mapping standard's boundaries. *Measure:* every corpus map exports to the
  procedure form and back with no loss and no hand repair under the current frozen version, and a change outside those
  boundaries is refused by the conformance tests.

Out of scope: a general-purpose BPMN editor; replacing the task system (tasks are canonical); executing or
authorising (the designer never executes, ratifies, resolves secrets, launches actions or approves gates; authoring
for execution and the diagram-to-procedure seam are in scope).

## What we especially want challenged

1. Does any objective still contradict the operator's words above (O-2's "refused" in particular, next to O-4)?
2. Are the measures checkable by someone who was not in the room, or are some untestable?
3. O-5 names a second tenant; no operator quote names one. Is O-5 earned?
4. Is anything the operator said above still missing (observability of *absence*, humans only where it matters)?
