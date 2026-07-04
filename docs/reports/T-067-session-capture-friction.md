# T-067 — session-capture friction catalogue

**Map:** `examples/aef-processes/session-capture.workflow.yaml` (7 nodes, 7 edges, 2 lanes)
**Ground truth:** `.agentic-framework/agents/session-capture/AGENT.md` (80 lines) — the whole
ground truth; no script exists.
**Dogfood role:** the P-007 session-end capture gate; completes the session-lifecycle trio
(session-handover write / resume-status read / session-capture close-gate). First
**100%-doctrine** corpus map.

## Findings

### Observation (new class, no FC yet) — doctrine-only flows map, but `endpoint` stretches
Every node cites `AGENT.md:NN` instead of executable script lines. The map works — the
schema never required endpoints to be executable — but the key now carries two meanings
(code ground truth vs doctrinal citation) with no marker distinguishing them. error-ladder
handled the mixed case by tagging node NAMES `[CODE]`/`[DOCTRINE]`; a doctrine-only map
makes per-node tags redundant, so this map declares it once in the header. **Watch:** if a
third flavor appears (e.g. external-system ground truth), promote a `groundTruth:
code|doctrine|external` key; two flavors + header note is not yet worth vocabulary.

### FC-11 (4th recurrence) — rule-of-three now EXCEEDED
`n_capture` collapses four capture actions, constituents in `aef.x-captures`. Tally:
verification-gate (`g_gates`), git-commit-flow (`x-checks`), resume-status (`x-sources`),
session-capture (`x-captures`). Four maps, same shape, same workaround. Per rule-of-three,
a first-class **constituents construct** (or the FC-15 scope/subProcess, which subsumes it)
has graduated from "nice" to "warranted" — recommend an inception to choose between
`constituents:` list vocabulary vs a real subProcess node type. Filed as the standing
top schema-evolution candidate; FC-15 and FC-11 likely share one fix.

### Upstream observation — the agent violates its own "Gaps" category
`AGENT.md:52` instructs humans to run `./agents/session-capture/capture.sh`; no such file
exists in the vendored tree. That is precisely the agent's own category "Gaps: things
referenced but don't exist → capture as Tasks". Vendored = read-only, so flagged for
framework maintainers rather than fixed here.

## Clean signals
- Stochastic self-scan expressible: `determinism: stochastic` + `multiInstance` over the
  five scan categories reads naturally.
- The close-gate semantics ("session may close only after capture") land in the endEvent
  `note` — sufficient for an advisory doctrine gate; nothing structural enforces it, which
  is faithful (the real enforcement lives in CLAUDE.md's session-end protocol, not a hook).
- 0 warns; VALID; geometry clean first try; corpus 23 → 24; suite 31/31.
