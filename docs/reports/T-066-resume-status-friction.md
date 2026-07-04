# T-066 — resume-status friction catalogue

**Map:** `examples/aef-processes/resume-status.workflow.yaml` (10 nodes, 10 edges, 2 lanes)
**Ground truth:** `.agentic-framework/agents/resume/resume.sh` `cmd_status` (90-276) +
helpers (`get_session:81`, `get_focus:72`, `get_git_state:61`, `get_active_tasks:30`).
**Dogfood role:** the post-compaction recovery flow — the read-side counterpart of the
already-mapped session-handover flow (antifragility pair: write state down / rebuild from it).

## Findings

### FC-16 (NEW) — independent-but-sequential gathering has no honest shape
The seven state sources (working memory, git, tasks, handover, discoveries, scan, research)
are **independent reads** — order is irrelevant, any subset may be absent — but bash executes
them **sequentially**. The mapper must choose a lie:
- **sequential chain** (chosen here): faithful to execution, but a reader infers false
  dependency ("git state needs working memory first" — it doesn't);
- **parallel fork/join**: faithful to the dependency structure, but the schema has **no
  parallelGateway** — audit-process already had to stash `gatewayKind: fork/join` on
  exclusive gateways for exactly this reason (that stash was one of the T-062 promoted keys).

Distinct from FC-10 (guard chains): these aren't gates, they're *gathers*. **Gap:** either a
first-class parallelGateway node type, or an edge/node annotation for "order-independent"
(`aef.independent: true` on a chain segment). Second corpus site for the missing-parallelism
family; audit-process was the first.

### FC-11 (RECURRENCE, 3rd) — collapsed node constituents, again mitigated by x-*
`n_intel` collapses three optional intelligence sources into one node, constituents declared
via `aef.x-sources` — same mitigation as git-commit-flow's `x-checks`. The x-* channel is now
the *standing workaround* for FC-11 (2 uses); if a third lands, a first-class
`constituents` construct graduates from "nice" to "warranted" (rule-of-three).

### Clean signal — "every source is optional" degradation is expressible
The handover-missing branch (`n_noho`, `softFail: advisory`, "synthesis proceeds from the
remaining sources") plus per-node `softFail`/`note` captured the flow's defining property —
graceful degradation — without any new vocabulary. The T-062 promoted scalars (`guard`,
`note`, `softFail`, `state`, `exitCode`, `terminalKind`, `advisory`) did all the work; this
map needed zero new keys and zero warns.

## Out-of-frame (recorded, not drawn)
- BVP focus-scoring side quest (resume.sh 104-116): advisory, timeout-guarded, vendored-
  framework concern — noted in the map header.
- `cmd_sync` (276-364) repairs stale working memory — a separate command; candidate for a
  future map if the sync/repair loop becomes interesting (it pairs with FC-8's
  cross-instance-recall finding from context-memory).

## Clean signals (gates)
- 0 warns; converts + validates clean; geometry clean first try; corpus 22 → 23; suite 30/30.
