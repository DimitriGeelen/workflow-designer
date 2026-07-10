# T-175 — Child-inception decomposition (IW-8): per-child GO/NO-GO framing

**Status:** Operator hand-off deliverable. The framing inception T-175 is **GO** (2026-07-10); IW-1..IW-7
answered, IW-8 (decomposition) scoped here for the operator's **per-child** go/no-go.
**Arc:** `designer-authoring-surface` (arc-001), anchor T-175.
**Grounds:** `docs/reports/T-175-designer-authoring-surface-inception.md` (architecture),
`docs/reports/T-175-mapping-strawman.md` (keystone, converged).

> **How to use this.** Each child below is a *single-question* inception (not a build). This document
> presents each scoped to a go/no-go decision so you can GO/DEFER them **individually** — not all-or-nothing
> (the framework warns against umbrella inceptions). Nothing here authorizes build. On a GO, the child gets
> its own inception task; build tasks follow that child's own go/no-go. My recommendation per child is in the
> last column; the decision is yours.

---

## Summary — recommended decision set

| # | Child | Owner (lead) | Depends on | Readiness | **My recommendation** |
|---|-------|--------------|-----------|-----------|------------------------|
| 1 | **Mapping standard** (keystone) | 832 (AEF ratifies concept-half) | — | **High** — strawman converged; emission shipped (T-177); uid verified | **GO now** |
| 2 | **Forward bridge** | AEF (832 editor-side done) | Child-1 | Medium — editor emits; AEF translator+gate is new | **GO next** |
| 3 | **Reverse discovery** | AEF (or joint) | Child-1 | Low-med — editor consumes arbitrary `aef:uid` today; reverse renderer is new | **DEFER** (revisit after 2) |
| 4 | **Collaboration & concurrency** | Joint | Child-1, hosting | Low — new lease substrate; browser↔termlink bridge unproven | **DEFER** |
| 5 | **Hosting & tenancy** | AEF | — (beachhead exists) | Med — single-tenant serve works; multi-tenant is new | **DEFER** (partial already live) |

**Net recommendation:** **GO child-1 now, GO child-2 next, DEFER 3–5** with the revisit triggers noted per
child. This funds the primary value path (draw → governed work) while keeping the speculative halves
(reverse, live co-editing, multi-tenancy) parked until the forward loop proves out.

---

## Child-1 — Mapping standard (keystone)

- **One-line:** Ratify + version the BPMN ⇄ task/inception-YAML contract as the blessed, portable standard.
- **Problem:** Everything else compiles *through* this mapping (IW-2 + IW-7). Without a frozen, versioned
  contract, forward/reverse bridges drift and portability (Directive 4) is unenforceable.
- **Key question (single):** Is the strawman's two-class vocabulary (semantic attributes → task YAML;
  presentational attributes → diagram-only) + `aef:uid` identity hinge the correct, complete contract — and
  what's the AEF-side ruling on the open points (inception shape G-3, tier default, AC seeding)?
- **Scope fence — IN:** freeze the semantic/presentational attribute lists; ratify the forward + reverse
  mapping tables; version the contract (`v1`) in `docs/standards/`; conformance checklist. **OUT:** building
  either bridge (children 2/3); editor changes (emission already ships).
- **Owner:** **832** owns the document + reference editor; **AEF** ratifies the framework-concept half
  (task-model receive, inception shape). Cross-repo sign-off over termlink thread T-175.
- **Readiness — HIGH:** strawman converged and validated against source; **G-1 emission shipped (T-177**:
  horizon/workflowType/owner now emit as `aef:meta`); **G-2 `aef:uid` round-trip verified** (import honors
  arbitrary uid → externally assignable, no editor change); IW-1..IW-5 ack'd by the AEF agent. The only
  genuinely-open items are AEF rulings on G-3 (inception marker shape) and a couple of defaults.
- **What GO authorizes:** a short child-1 inception to close the AEF rulings, then a **build task** to
  publish `docs/standards/aef-bpmn-mapping-v1.md` + a conformance test (extends the existing parity test).
- **Recommendation: GO now.** Lowest risk, highest leverage; ~90% done; unblocks 2 and 3.

## Child-2 — Forward bridge

- **One-line:** Diagram → agent-enriched proposed task/inception graph → **one** sovereignty approval →
  governed work (IW-3).
- **Problem:** The generative direction — the primary value. A drawn process must *propose* (never silently
  author) governed work, enriched with ACs/types/ownership, approved as a batch in one gate.
- **Key question (single):** Can the AEF side translate a child-1-conformant BPMN into a *proposed* task
  graph, enrich it, and present it for a single batch sovereignty approval — without violating "nothing gets
  done without a task"?
- **Scope fence — IN:** BPMN(+`aef:`) → proposed-graph translator; enrichment pass; batch approval gate;
  task creation on approve. **OUT:** reverse (child-3); live co-editing (child-4); the mapping itself
  (child-1).
- **Owner:** **AEF-led** (owns task-model, enrichment, sovereignty gate). **832** side is largely **done** —
  the editor emits the full semantic vocabulary and stable `aef:uid` (modify-vs-create is the uid-resolves
  test). Needs an **AEF inception**.
- **Readiness — MEDIUM:** the contract (child-1) is stable and the editor half ships; the translator +
  enrichment + gate are net-new AEF work.
- **What GO authorizes:** an AEF-side inception for the forward translator + gate; 832 supplies the
  emission spec (strawman G-1) and reference fixtures.
- **Recommendation: GO next** (once child-1 is ratified). This is the arc's main deliverable.

## Child-3 — Reverse discovery

- **One-line:** AEF's own process record (tasks/fabric/decisions/episodic) → rendered, editable process map
  (IW-4), each element carrying `aef:uid=<task-id>`.
- **Problem:** Closes the round-trip — existing governed work becomes visually editable, and edits map back
  to *modify* proposals via the uid hinge.
- **Key question (single):** Is AEF's record structured enough to deterministically reconstruct a
  child-1-conformant BPMN map (lanes=owners, subProcess=arc, gateway=decision), first target = AEF's own
  record?
- **Scope fence — IN:** record → BPMN(+`aef:uid`) renderer; layout; "open my task graph as a diagram".
  **OUT:** arbitrary source-code parsing (explicitly deferred, IW-4); forward (child-2).
- **Owner:** **AEF-led / joint.** 832's editor already **consumes arbitrary `aef:uid` unchanged** (verified)
  — reverse-render needs **zero editor change** for identity; the renderer is the new part (AEF owns the
  record; the BPMN-emission spec is 832's).
- **Readiness — LOW-MEDIUM:** identity anchor solved; renderer + layout are new and depend on child-1.
- **What GO authorizes:** an inception on the reverse renderer (record→BPMN) against AEF's own record.
- **Recommendation: DEFER.** Revisit once child-2 lands — forward is the value path; reverse is
  complementary, not blocking. **Revisit trigger:** child-2 shipped + demand to edit existing task graphs.

## Child-4 — Collaboration & concurrency

- **One-line:** Human (browser) and agents (termlink) co-design the same map without stalling or clobbering,
  via fine-grained per-element claim/lease (TTL auto-release) (IW-5).
- **Problem:** Multi-party authoring needs conflict-free regions. Single-author authoring works **today**;
  this is only needed when >1 party edits concurrently.
- **Key question (single):** Can termlink's claim primitive (agent-side) be bridged to the browser
  (server-mediated lease) to give per-node/lane/subProcess leases with TTL — without a heavyweight
  realtime-collab stack?
- **Scope fence — IN:** lease model + bridge; lease-aware editor UI (locked regions); conflict policy.
  **OUT:** the bridges themselves (2/3); OT/CRDT full realtime (unless proven necessary).
- **Owner:** **Joint** — AEF hosts the lease service; 832 adds lease-aware UI to the editor.
- **Readiness — LOW:** most architecturally-open child; the browser↔termlink lease bridge is unproven
  (flagged in the inception's Technical Constraints).
- **What GO authorizes:** a spike inception on the lease bridge feasibility.
- **Recommendation: DEFER.** **Revisit trigger:** concurrent multi-party editing becomes a real workflow
  (e.g., collaborative inception sessions) — not before.

## Child-5 — Hosting & tenancy

- **One-line:** The designer served tenant-neutral, eventually multi-tenant (IW-6): AEF dogfoods **and**
  offers the surface to downstream apps.
- **Problem:** Reach — two audiences from day one means no hardcoded AEF-internal assumptions.
- **Key question (single):** What's the minimal tenant-neutral hosting contract (auth, per-tenant storage,
  isolation) beyond the current single-tenant AEF serve?
- **Scope fence — IN:** tenancy model; per-tenant isolation; served-app hardening. **OUT:** the authoring
  features (1–4); the single-tenant beachhead (already live at `:3001/designer`).
- **Owner:** **AEF** (hosting/serving is AEF-side).
- **Readiness — MEDIUM (partially live):** single-tenant serve already works (`fw designer`,
  `:3001/designer`); tenant-neutrality is being honored as a *design constraint* now (no AEF-hardcoding).
  Full multi-tenancy is a later scaling concern.
- **What GO authorizes:** an AEF inception on the tenancy model when a second tenant is real.
- **Recommendation: DEFER.** The beachhead covers dogfood today. **Revisit trigger:** a concrete second
  tenant/downstream app appears.

---

## Ownership split (IW-8 sub-question) — at a glance

- **832 (source of truth):** the mapping standard doc + conformance test (child-1); the reference editor and
  its emission/round-trip (already ships the semantic vocabulary + `aef:uid`); BPMN-emission fixtures for
  the bridges.
- **AEF:** the framework-concept half of the mapping (task-model receive, inception shape); the forward
  translator + enrichment + sovereignty gate (child-2); the reverse renderer over its own record (child-3);
  hosting/tenancy (child-5).
- **Joint:** the concurrency lease bridge (child-4); cross-repo sign-off of the mapping contract.

## Sequencing rationale

1. **Child-1 first** — it's the contract; 2 and 3 compile through it, and it's ~done.
2. **Child-2 next** — the primary value path (draw → governed work); AEF-led, 832 half ready.
3. **3–5 deferred** — reverse, live co-editing, and multi-tenancy are each valuable but each depends on the
   forward loop existing and carries more uncertainty. Each has an explicit revisit trigger above so nothing
   is silently dropped (the framework's DEFER + revisit discipline).

## Requested operator action

Record a go/no-go **per child** (e.g. GO 1, GO 2, DEFER 3–5). On each GO I create that child's inception
task (single question, owner as noted) — no build starts until that child's own go/no-go. The strawman
(child-1) is ready to formalize the moment child-1 is GO'd.
