# T-175 Framing Inception — Workflow Designer as AEF's process-authoring surface

**Arc:** `designer-authoring-surface` (arc-001) · **Task:** T-175 (framing inception) · **Created:** 2026-07-10
**Owner:** agent → decision: human · **Collaborator:** AEF agent (`aef`, `tl-uhqt63fb`, `/opt/999-Agentic-Engineering-Framework`)

> C-001 thinking-trail artifact. This is the **framing inception** for a program (arc-001): deep,
> bidirectional integration of the Workflow Designer into AEF as its **visual process-authoring surface**.
> It sits ABOVE the phase-1 beachhead already GO'd in T-173 (embed the single-file editor). Its job is to
> lock the architecture (done — 7 decisions with the operator) and **decompose** into child inceptions,
> co-designed with the AEF agent, before any build.

## Problem

The operator's directive escalated from "AEF hosts the designer" to a much larger vision: the Workflow
Designer becomes **the framework's visual front door** — where drawing a process is a first-class way to
*drive* governed work (forward) and where existing work is *rendered back* as an editable process map
(reverse). Three axes:

1. **Forward / generative** — a human drafts a process; it kicks off framework activity (inception / build
   task / collaborative design session). The diagram *seeds* governed work.
2. **Reverse / discovery** — ingest an existing codebase (or AEF's own record) → discover the processes
   implicit in it → render + document them as workflow maps.
3. **Reach / tenancy** — two audiences: AEF **dogfooding** its own processes, and AEF **offering the
   designer as a development tool** to downstream applications built on the framework.

Through-line: **process diagram ⇄ governed tasks ⇄ code**, in both directions, over a portable standard.

## Relationship to T-173 (phase-1)

- **T-173 (GO'd):** embed the self-contained single-file editor into AEF via M3 + `fw designer` (832 = SoT,
  AEF vendors a pinned build). That is the **beachhead** — the editor must exist inside AEF before any of
  this is reachable. Build tasks: T-174 (832 release) + the AEF-side `fw designer` task.
- **T-175 (this):** the program that turns that embedded editor into the *authoring surface*. T-173 is not
  superseded; it is the foundation T-175 builds on.

## Resolved architecture (7 decisions — operator dialogue 2026-07-10)

Mirrors T-175 `## Open Questions` (IW-1..IW-8). Summary:

| # | Question | Decision |
|---|----------|----------|
| **IW-1** | Direction of authority | **Round-trip, tasks canonical.** Diagram *proposes*; never silently authors. |
| **IW-2** | Vocabulary bridge | **Explicit canonical mapping** BPMN ⇄ task/inception concepts. The mapping IS the contract. |
| **IW-3** | Forward trigger | **Agent enriches → human approves batch** in one sovereignty gate → tasks created. |
| **IW-4** | Reverse first target | **AEF's own process record** (tasks/fabric/decisions/episodic) first; arbitrary code later. |
| **IW-5** | Collaboration + concurrency | Channels: **agent↔agent = termlink, human↔framework = browser.** Async + turn-based. **Fine-grained claim/lease** (per element, TTL) for concurrency. |
| **IW-6** | Tenancy | **Both audiences from day one** → tenant-neutral architecture; validate on AEF as first tenant. |
| **IW-7** | Portability | **Standard BPMN⇄task-YAML contract + this designer as reference implementation.** |
| **IW-8** | Decomposition | *Open* — proposed 5 children (below); to be confirmed with the AEF agent. |

### How the decisions lock together

- **Keystone = the mapping standard (IW-2 + IW-7).** A documented BPMN ⇄ task/inception-YAML mapping is
  *the* interface. The framework talks to the format; this designer is the blessed reference editor. Any
  conformant tool (or a downstream tenant's own) could drive the same loop. Everything else rides on this.
- **Forward (IW-1 + IW-3):** draw → AEF agent translates + enriches into a proposed task/inception graph →
  human approves the batch (one gate) → governed tasks. Diagram proposes, tasks stay canonical.
- **Reverse (IW-4):** reconstruct process maps from AEF's structured record first (deterministic dogfood),
  before fuzzy source-code parsing.
- **Collaboration (IW-5):** the human is always in the **browser**; agents coordinate over **termlink**.
  Concurrency is a **fine-grained claim/lease** (reusing termlink's existing claim primitive) so human and
  agent work different regions of the flow simultaneously — no stalling, no conflict on a claimed element.
- **Tenancy (IW-6):** tenant-neutral from the start; AEF is the first tenant, not a hardcoded assumption.

## Proposed decomposition (IW-8 — to confirm with the AEF agent)

Child inceptions/arcs under arc-001, roughly in dependency order:

1. **Mapping standard** (keystone) — define + document BPMN ⇄ task/inception-YAML. *Do first; everything
   depends on it.*
2. **Forward bridge** — diagram → agent-enriched proposed graph → approval gate → governed tasks.
3. **Reverse discovery** — AEF process record → rendered/editable process map.
4. **Collaboration & concurrency** — browser channel + fine-grained claim/lease; termlink for agents.
5. **Hosting & tenancy** — designer served, tenant-neutral, multi-tenant.

Bundling these into one inception would create an all-or-nothing decision (the framework warns against
"umbrella inceptions"). Each child is a single question.

## Collaboration plan (with the AEF agent)

1. Share this framing + the 7 resolved decisions on termlink thread T-175 (or a new arc thread).
2. Joint design pass to confirm/sequence the decomposition (IW-8) and split ownership (which children the
   AEF side leads vs the 832 side).
3. Bring the decomposition + per-child GO/NO-GO framing to the operator.
4. No build under T-175 — children get their own inceptions, then build tasks, after GO.

## Proposed decision

**DEFER** — architecture is resolved (IW-1..7); the framing inception's remaining job is to close IW-8
(decomposition) with the AEF agent and hand the operator a set of scoped child inceptions. Phase-1 (T-173
/ T-174 + AEF `fw designer`) proceeds independently as the beachhead.

## Dialogue Log

- 2026-07-10 — Operator escalated the T-173 directive to the full vision: designer as framework authoring
  surface — forward (draw → dev activity / collective inception / collaborative design), reverse (ingest
  codebases → discover + document processes), and both dogfood + downstream-tool audiences. Asked for
  reflection + playback + deepening questions.
- 2026-07-10 — Walked the operator through 7 questions 1-by-1:
  - IW-1 → round-trip, tasks canonical.
  - IW-2 → explicit canonical mapping.
  - IW-3 → agent enriches, human approves batch.
  - IW-4 → AEF's own process record first.
  - IW-5 → **operator corrected my framing twice:** (a) termlink is agent↔agent, the human is in the
    browser — not termlink; (b) it's inherently async/turn-based, so the real problem is *stalling +
    conflict*, solved by a lock. Refined to a **fine-grained claim/lease** per element. Operator confirmed.
  - IW-6 → operator chose **both audiences from the start** (over my dogfood-first lean).
  - IW-7 → standard contract + reference editor.
- 2026-07-10 — Operator asked "should we make it an arc?" → **yes.** Created arc-001
  (`designer-authoring-surface`), anchored T-175, tagged it in. This artifact + the framing inception are
  the arc's first activity.
