# T-045 — Friction-dry analysis: promotion-pipeline (fw promote)

**Subject:** `examples/aef-processes/promotion-pipeline.workflow.yaml`
**Ground truth:** `.agentic-framework/lib/promote.sh` (`do_promote`)
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and
record where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #12.

## Verdict

**Schema expressivity: 4/4 constructs available, 0 blocking gaps.** The promotion pipeline
mapped cleanly: 3 authority lanes, 3 exclusive gateways, a human userTask, an advisory
sub-branch, and 3 terminal exits. No construct was missing. But two universal frictions
**sharpened** in ways worth recording, and the workflow is the first mapped corpus member
with **no stochastic node at all** — a useful negative data point for F3.

## Recurrences (frictions seen before, seen again)

- **F3 (determinism marker).** Every `fw` step is `deterministic`; the promote decision is
  `human`. Confirmed universal — the determinism dimension is meaningful on every node.
- **F7 (side-effect annotation).** The graduation is one file write (`practices.yaml`,
  L.310-313). Marked via `aef.sideEffect`. Recurs; still a free-text passthrough, not
  first-class.

## Sharpenings (a known friction took a new shape)

### F1 (human decision → edge) — sovereignty has TWO shapes, not one
In `inception-review` F1 was a **multi-way routing decision**: the human picks
go / no-go / defer and the choice fans to three outgoing edges (`userTask.decisionOutputs`
+ a downstream `exclusiveGateway`). Here the human decision is structurally different: the
human decides **which** learning graduates and supplies `--name`/`--directive`, but this is
a **proceed-authorization gate**, not a router. The code has no "human said no" branch —
if the human doesn't run `fw promote L-XXX`, nothing happens; the branching that *does*
occur downstream (`Already promoted?`, `≥3 applications?`) is **framework data-condition**,
not the human's choice.

So AEF sovereignty spans two idioms:
- **(a) Routing decision** — human picks among N outcomes → `userTask` + gateway, N edges.
- **(b) Proceed gate** — human authorizes *whether* to continue → `userTask` precondition,
  one downstream edge; the real branches are framework-owned data conditions after it.

**Why this matters:** a naive F1 detector keyed on "human-owned decision → multiple edges"
would flag (a) and **miss (b)** entirely, reporting the promotion pipeline as having no
human decision — when in fact the single most consequential act (graduating knowledge) is
human sovereignty. The schema expresses both fine; the *friction* is detection/semantics,
not expressivity. Recommend: treat any `userTask` with `authority: sovereignty` OR a human
`endpoint` as a sovereignty point, regardless of outgoing edge count.

### F3 (determinism) — the "no stochastic node" case
`inception-review` had a `stochastic` node (the agent authoring a recommendation).
`promotion-pipeline` has **none** — it is entirely `deterministic` (fw verbs) + `human`
(the promote decision). This confirms determinism is not a fixed three-value distribution
per workflow; some processes are purely mechanical + sovereign. Any F3 tooling must not
assume all three values are present.

## New candidate friction

### FC-1 — advisory (non-terminating) gate
`≥3 applications?` (L.260) is an `exclusiveGateway` whose "fail" branch does **not**
terminate or reroute — it emits a warning (`Warn "early promotion"`) and **rejoins** the
happy path. Both branches converge on `Generate practice id`. The schema handles it (two
edges, one to a scriptTask that flows back), but semantically this is a *soft gate*: it
annotates rather than blocks. Marked with `aef.advisory: true` on the warn node. Worth a
first-class "advisory gateway" concept later so soft gates are distinguishable from hard
ones (a hard gate's off-branch reaches a terminal or a genuinely different path).

### FC-2 — sovereignty-boundary revalidation
`≥3 applications` is checked **twice**: once by the framework at `suggest` time
(ready-gate, L.213) and again inside `promote` (apps-gate, L.260). The framework does not
trust that state is unchanged across the human's decision — it re-derives the condition at
the moment of the write. This "revalidate at the sovereignty boundary" pattern is good
antifragile design (D-1) and recurs implicitly in other human-in-the-loop flows
(e.g. inception marker gate). Candidate to note as a workflow *pattern*, not a schema gap.

## Outcome

Promotion pipeline mapped, validated, geometry-clean, renders faithfully in the editor
(Playwright-verified). No schema changes required (consistent with PD-002). Two friction
sharpenings (F1 two-shapes, F3 no-stochastic) and two new candidates (FC-1 advisory gate,
FC-2 sovereignty revalidation) recorded for the friction register.
