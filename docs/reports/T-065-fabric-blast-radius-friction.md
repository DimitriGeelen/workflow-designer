# T-065 — fabric-blast-radius friction catalogue

**Map:** `examples/aef-processes/fabric-blast-radius.workflow.yaml` (10 nodes, 10 edges, 2 lanes)
**Ground truth:** `.agentic-framework/agents/fabric/fabric.sh:113-117` + `lib/traverse.sh:153-214`
(`do_blast_radius`), with `lib/traverse.sh:5-151` (`do_impact`) read for the fidelity boundary.
**Dogfood role:** the Component Fabric impact-analysis practice ("before committing:
`fw fabric blast-radius`") — and the first live exercise of the T-063 structured
`multiInstance`/`aggregation` keys.

## Findings

### FC-15 (NEW) — no scope construct: iteration bodies and nesting are unboundable
The per-file loop's body contains a real decision (card found → writes-lookup; no card →
advisory gap report). The schema can express:
- the **iteration marker** — T-063 structured `multiInstance` on `n_scan` (over/mode/
  predicate/collects) — and
- the **body** — ordinary nodes drawn once-through —

but nothing can say *where the body ends*: there is no subProcess/scope construct, so the
iteration boundary is invisible (does `n_total` run per file or once after the loop? Only
the prose note disambiguates). Worse, the ground truth has a **nested** loop (for each
changed file → scan all component cards) which had to be collapsed into `g_card`'s
`decisionInput`. And `do_impact`'s recursive traversal (visited set, max_depth) is
fundamentally unexpressible as flat sequence flow — it was deliberately left out
(`x-seeAlso` on `n_writes`) rather than faked. **Gap:** a scope/subProcess construct
(BPMN has one; the v2 subset doesn't). Candidate: `subProcess` node type or a
`scopeOf: <multiInstance-node>` grouping annotation.

### Dogfood WIN — T-063 structured keys carried the load
`multiInstance` (dict: over/mode/predicate/collects) and `aggregation` (dict: over/reduce/
outputs, list field auto-joined) both rode to BPMN as first-class `<aef:multiInstance>` /
`<aef:aggregation>` elements — the exact data that was **silently dropped** before T-063
(revisit-due-scan's multiInstance was the discovery case). Authored naturally, zero warns,
survived to output. The T-061→T-063 chain is now validated end-to-end by authoring, not
just by tests.

### FC-12 (RECURRENCE, mild) — authority lanes for a mechanical tool
Blast-radius involves no human. The 2-lane form (agent initiative / framework authority)
works, but "authority" overstates what a read-only advisory reporter does — recurrence of
the T-057 finding that the single authority-coupled lane axis is sometimes the wrong
partition. Mild here; noted for the pattern count.

## Clean signals
- Advisory semantics expressible: `softFail: advisory` (n_nocard), `advisory: true` +
  `exitCode: 0` + `terminalKind: success` (n_done) say precisely "informs, never blocks".
- Early-exit empty-diff path is a natural gateway + success end.
- 0 warns; converts + validates clean; geometry clean first try; corpus 21 → 22; suite 29/29.
