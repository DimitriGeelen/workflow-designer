# Operating digest — executable workflow-contract initiative (Designer side)

**Task:** T-587 · **Written:** 2026-08-25 · **Authority:** navigation aid only.
If this digest conflicts with a stored snapshot, **the snapshot wins** and this
file must be corrected under a task.

**Pinned sources**
- `architecture-c9070637.md` — sha256 `c9070637…6ac2d` (dossier, 18 sections)
- `roadmap-5be23719.md` — sha256 `5be23719…ae8bf` *(full: `5be23719b976e37a6461b4b1f6f309985b5ba033ef0b801769edd2627fbae5b8`)*

Load the full sources only for: initial ingestion, contract/version changes,
arc planning/close, architecture decisions, contradiction resolution, and audits
needing full coverage. Otherwise load this digest plus the cited section.

---

## 1. What is being proposed (dossier §0.1, §2, §6)

A **runtime control plane** that turns a *ratified workflow procedure* into a
*task-bound workflow instance*, admitting only policy-validated transitions and
executing only bounded approved action types, with durable redacted evidence.

Four concepts must not collapse (§2): **procedure** (reusable ratified method),
**router** (a procedure that selects a procedure), **instance** (one live
enactment of one pinned procedure version), **task** (AEF's canonical work
record). An instance is *not* a free-writable YAML file (§2.3).

Operator decision already recorded (§18, 2026-08-20): **GO** for a
semantics-first first slice, then a **mandatory boundary-isolation proof** as
slice two. No agent-prompt execution, external-service actions, model routing or
autonomy expansion until isolation passes.

## 2. The ownership boundary (dossier §5.1) — controlling text

> Workflow Designer owns authoring and visualisation. AEF owns governance,
> validation, authority, and execution.

Designer-owned: editing UX, layout, lanes, visual notation, import/export and
lossless round trips; compilation/export from visual representation to the
versioned interchange contract; authoring conforming definitions and declarative
profile *references*; presenting validation results; rendering the read-only
runtime projection; interaction design that submits *typed proposals*.

AEF-owned: procedure/runtime schemas, invariants, validation, refusal,
ratification, compatibility policy; runner, ledger, actions, identity, secrets;
Fabric canonical records and query semantics; the authenticated proposal API and
its admission/refusal decision; provider capability manifests and routing.

**Prohibited overlap (§5.1):** Designer/browser code must not validate itself as
authoritative, ratify a procedure, mutate runner state, resolve secrets, launch
actions, or approve a gate. Neither agent edits the other project's files.

**Five shared versioned contracts (§5.1):** (1) procedure interchange,
(2) mapping/compatibility, (3) validation/refusal diagnostics, (4) runtime
projection + operator proposal types, (5) ratification — *an authored definition
remains a proposal until AEF records the human decision; a Designer save/export
never ratifies or executes it.*

## 3. The compatibility fence that protects our frozen standard (dossier §0.1, §6.1)

The dossier explicitly does **not** alter Mapping Standard Part I. Frozen mapping
v1.1 "continues to compile a diagram only into *proposed* governed work. It must
not silently launch actions, bind a task, ratify a definition, or change task
authority." An executable procedure requires a **separately versioned
runtime-contract extension**, explicit human ratification, and a new
validator/runner.

This is the single most important sentence for this project: **the runtime is an
extension alongside our standard, not a redefinition of it.**

Open decision (§14.1): the execution-extension *format* and its
compatibility/versioning mechanism are undecided — BPMN extension vs referenced
companion manifest (§6.1).

## 4. The delivery shape (roadmap §2, §4)

`Arc 0 baseline → Arc 1 semantics kernel → Arc 2 isolation proof (hard gate) →
{Arc 3 actions/providers ‖ Arc 4 operator/Fabric} → Arc 5 guided agentic →
Arc 6 routing/composition`

Designer column per arc (roadmap §2.1):
- **Arc 0** — inventory visual/mapping schema, stable IDs, import/export and
  round-trip constraints. Joint: agree version matrix, canonical IDs, diagnostic
  shape, worked procedure fixture.
- **Arc 1** — read fixture/projection prototypes only; *no execution code*.
  Joint: Designer proves it can render the canonical fixture **without inventing
  semantics**.
- **Arc 2** — prove browser/editor cannot reach execution/secret/ledger
  authority. Joint attack review, human GO.
- **Arc 3** — author declarative profile references; render structured refusals.
- **Arc 4** — runtime visualisation, operator interaction UX, diagram↔Fabric
  navigation.
- **Arc 5** — author/visualise agent nodes, scopes, outcomes, handoffs.
- **Arc 6** — visual routing explanations, sub-procedure composition, migration
  presentation.

BVP scores in roadmap §5 are **estimator proposals only** — they do not start,
approve or reorder arcs, and a high score does not make a blocked arc actionable
(§3, §5 calibration notes). At most three operator-approved scoped drivers per arc.

## 5. Collaboration completion is read-back, not delivery (dossier §5.1; roadmap §2.3)

TermLink hub delivery, prompt injection, or `file_send` success is **transport
evidence only**. Completion requires the receiver to read back the exact
version/hash and return a substantive `accepted` / `refused` / `needs-decision`
response **on the same correlation**. Preserve envelope, receipt, response and
disposition in both projects under their own tasks.

---

## Section index for targeted re-reads

| Need | Dossier § | Roadmap § |
|---|---|---|
| Definition, objective, non-objective | 0.1 | — |
| Ownership contract, shared contracts, prohibited overlap | 5.1 | 2.1, 2.2 |
| Compilation, execution extension, frozen-v1 fence | 6.1 | — |
| Node type vocabulary | 6.2 | — |
| Action/script contract, failure routes, self-heal | 6.2.1, 6.2.2 | — |
| Edges as interfaces; profiles; secrets | 6.3, 6.4, 6.5 | — |
| Delivery artefacts as contract objects | 6.6, 6.6.1, 6.6.2 | — |
| Instance state machine, ledger, attempts, time, cancellation | 7.3, 7.4 | — |
| Per-node sequence; pause/resume | 7.5, 7.6 | — |
| Fabrics (Context / Component / Workflow) | 8.1–8.3 | — |
| Authority intersection and isolation | 9 | — |
| Operator/agent views (4 lenses) | 10 | — |
| Incremental delivery path | 11 | 2, 4 |
| Hard problems | 12 | — |
| Acceptance scenarios (20) | 13 | 6 |
| Open decisions (12) | 14 | — |
| Grounding record (cites this project) | 15 | 8 |
| Claude / Z.ai dispositions + operator GO | 17, 18 | — |
| BVP method and per-arc proposals | — | 3, 5 |
| Verification fences | — | 6 |
