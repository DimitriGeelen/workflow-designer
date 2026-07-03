# T-048 — Friction-dry analysis: harvest-pipeline (fw harvest)

**Subject:** `examples/aef-processes/harvest-pipeline.workflow.yaml`
**Ground truth:** `.agentic-framework/lib/harvest.sh` (`do_harvest`, L.12-149)
**Method:** friction-dry — map a real AEF process with the Workflow Designer schema and
record where the schema strained, where known frictions recurred, and where they sharpened.
Dogfood mapping #15 (capstone — 24 nodes, 28 edges, the largest map in the corpus).

## Verdict

**Schema expressivity: all constructs available, 0 blocking gaps — and the schema's LAST
un-dogfooded node type is now exercised.** The harvest flow mapped faithfully: parse →
resolve → 3 sequential guard gates (each with an error/refuse terminal) → read source project
(external) → **parallel fan-out of 6 category harvesters** → join → tally → 3-way outcome
(dry-run / nothing-new / logged+written). Renders legibly (Playwright-verified); the two
`parallelGateway` nodes draw as the distinctive ⊕ diamond, visually separable from the ×
exclusive gateways.

**Coverage milestone:** with `parallelGateway` used here and `external` first used in T-046,
**every node type in `NODE_TYPES` and every value in `AUTHORITIES` now appears in the corpus**
except `linkEventThrow`/`linkEventCatch` (off-page connectors — a pure layout convenience with
no process-semantic counterpart in the mapped CLIs, so absence is expected, not a gap).

## New / headline finding

### parallelGateway first use — and the sequential-code-vs-concurrent-model gap
The 6 harvesters (`harvest_patterns` … `harvest_claude_additions`, L.102-124) are
**data-independent**: each compares one project memory file to the framework's and appends new
items; none reads another's output. The **code runs them sequentially** (six `echo` + call
lines in a fixed order). But sequential *execution* is an implementation choice, not a
*dependency*. In BPMN, sequence edges assert ordering; modelling six independent activities as
a chain would falsely claim "learnings must wait for patterns." The **truthful** model of the
dependency graph is a `parallelGateway` split → 6 branches → join, which asserts *no ordering
constraint*.

This is the inverse of the usual friction: here the **schema is MORE expressive than the
code** — it can state the latent concurrency the implementation forgoes. Worth recording as a
process-insight: the map documents that `fw harvest` *could* parallelise its six scans with no
correctness change (they only ever append to distinct framework files). Whether that's worth
doing in the framework is a separate question — but the map made the opportunity legible, which
is exactly the point of authoring these diagrams.

## Recurrences

- **F3 (determinism).** Entirely `deterministic` — no human, no stochastic (fourth autonomous
  map). Consistent with the emerging taxonomy: framework plumbing (harvest, release, dispatch)
  is human-free; the human-sovereignty maps are the decision flows (inception, promotion).
- **F7 (side-effect annotation).** Six append-writes (one per category) + a harvest.log line,
  all free-text `aef.sideEffect`. Recurs; the T-047 "structured side-effect" wish applies.
- **FC-3 (participant flattened to a lane, T-046).** Third `external`-lane use: the source
  project being harvested is read-only, outside the framework's authority. Reinforces the
  recommendation to document `authority: external` ⇒ separate participant.
- **Terminal taxonomy (T-047).** Five terminals: three error/refuse (no-dir, refused,
  no-context → exit 1) and three success (dry-run, nothing-new, harvested). `aef.terminalKind`
  carries the distinction; a rendered success/error ring colour would make it visible.

## Product findings (feed T-043 / editor)

- **No clipping** once labels were kept short (bbox x=30 … right=2006 inside viewBox
  `[0,2036]`). The T-046 short-label discipline scaled to a 24-node map.
- **The 6-way fan is legible** at ~80px vertical pitch between branches with the pool/lane
  width content-driven (T-043's `contentRightEdge`-based pool width held for a 2036px-wide
  diagram). No layout-engine changes were needed to render a parallel fan — the authored
  coordinates + `check-lane-bands` geometry gate were sufficient.
- **Guard-terminal label overlap** (three error terminals 130px apart with ~150px labels) was
  the only cosmetic issue; trimmed the labels. Same class as the T-046 fit-to-view finding —
  another vote for measuring text extent, but the short-label workaround remains reliable.

## Outcome

Harvest pipeline mapped, validated, geometry-clean, round-trips (bridge suite 16/16), renders
faithfully **and legibly** (Playwright-verified — parallelGateway ⊕ fork/join, 6-way fan,
external source-read, 3-way outcome all clear). **First `parallelGateway` use** completes the
schema's node-type coverage across the corpus. No schema changes required (consistent with
PD-002). Recorded: the parallelGateway sequential-code-vs-concurrent-model insight (headline),
plus F3/F7/FC-3/terminal-taxonomy recurrences.
