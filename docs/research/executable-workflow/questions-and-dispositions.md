# Questions and dispositions — executable workflow-contract ingestion

**Task:** T-587 · **Sources:** `architecture-c9070637.md`, `roadmap-5be23719.md`
· **Shape:** per the local inception convention — `confidence: 0-3`
(0 = guess, 3 = verified), `disposition: answered | deferred | dissolved`,
`rationale` citing file:section or task id.

Questions marked **deferred** are the operator's to resolve or to route to the
peer project. Nothing here is a decision.

---

- **IW-1: Does the proposed runtime move, reinterpret, or weaken the frozen
  Mapping Standard Part I?**
  confidence: 3
  disposition: answered — **no, and it says so explicitly**
  rationale: `architecture-c9070637.md` §0.1 Non-objective ("does not alter the
  Mapping Standard's frozen Part I; a runtime contract is a separately versioned
  extension") and §6.1 Compatibility boundary ("frozen mapping v1.1 continues to
  compile a diagram only into *proposed* governed work"). This agrees exactly
  with `docs/standards/aef-bpmn-mapping-v1.md` §3 ("produces a **proposed**
  task/inception graph… approval is a separate sovereignty gate"). No boundary
  conflict exists at the level of stated intent.

- **IW-2: Does the roadmap's Designer column describe new work, or does it
  re-open questions this project has already dispositioned?**
  confidence: 3
  disposition: answered — **it silently re-opens four standing DEFERs and one
  peer NO-GO**
  rationale: `roadmap-5be23719.md` §2.1 assigns the Designer "runtime
  visualisation / operator interaction UX / diagram↔Fabric navigation" (Arc 4),
  "author/visualise agent nodes" (Arc 5) and "sub-procedure composition"
  (Arc 6). Those are SD-15, SD-8/10/11, SD-14 and SD-9, all dispositioned on
  2026-07-28 in
  `docs/proposals/aef-workflow-process-layer-2026-07-02/DISPOSITION-2026-07-28.md`
  as **STILL OPEN → T-280 / T-279 / T-281 / T-282**, and all four were "filed
  DEFER, owner human — decision placeholders, not scheduled work". Verified
  still `status: captured, workflow_type: inception` in `.tasks/active/` on
  2026-08-25. The same addendum records AEF's mirror tasks T-2668 (DEFER),
  T-2670 (DEFER) and **T-2669 NO-GO** ("write-mostly corpus, no read-pull yet").
  The dossier cites this disposition file in §15 but only for the weaker claim
  that these are "open rather than shipped"; neither source records that both
  projects had already recommended *against* scheduling them. **A roadmap that
  reverses a standing DEFER needs a superseding decision, not silence.**

- **IW-3: Is the roadmap's Component Fabric premise true for this project?**
  confidence: 3
  disposition: answered — **no; and our own topology is present-but-unreliable**
  rationale: `roadmap-5be23719.md` §1 and §8 cite `fw fabric stats`: 0
  components, 0 edges. That is the **authoring** project's measurement
  (0503-codex-cli-playground), not ours. This project has 67 component cards in
  `.fabric/components/`. But the instrumentation carries open defects:
  T-342 (audit's standing fabric measurement), T-343 (`fw fabric enrich`
  silently discards edges), T-344 (`watch-patterns.yaml` is untailored),
  T-345 (audit fabric coverage check broken), T-524 (`fw fabric validate` exits
  0 while validation fails), T-525 (coverage warn reports a raw count). So the
  correct local statement is **"measured but not yet trustworthy"**, which is
  precisely the "unmeasured, never zero-impact" state the dossier §7.5/§8.2
  requires be routed to policy rather than assumed cheap. Arc 0's blast-radius
  claim cannot rest on our Fabric until those six are resolved.

- **IW-4: Are our stable IDs actually stable enough to be a joint contract
  input in Arc 0?**
  confidence: 3
  disposition: answered — **no; identity has open, already-filed defects**
  rationale: `roadmap-5be23719.md` §2.1 Arc 0 asks the Designer to supply
  "stable IDs… and round-trip constraints" as if settled.
  `docs/standards/aef-bpmn-mapping-v1.md` §5 makes `aef:uid` **externally
  assignable** — which is the collision surface itself. Open local tasks:
  T-501 (map ID round-trip defect triage), T-518 (uid collision: an externally
  assigned `aef:uid`), T-520 (does `aef:uid` round-trip for values that…),
  T-523 (does `aef:uid` survive nesting), T-564 (load-time ID normalisation).
  Round-trip *identity* is delivered at fixture level (V3 DELIVERED, G-002,
  T-187/T-188) but not at the externally-assigned-value level the runtime needs.

- **IW-5: Is the interchange geometry form stable enough to pin a version
  matrix against?**
  confidence: 3
  disposition: answered — **no; it is mid-migration**
  rationale: T-357 (adopt BPMN DI as the designer geometry authority) is in
  flight with T-423 (step 2 — emit BPMN DI additively alongside) and T-424
  (step 3 — retire `aef:position`), plus T-340 (standard BPMN DI silently
  discarded on import) and T-361/T-425 (exported bytes / DI trailer claims).
  `aef:position` is Part I **presentational** class
  (`aef-bpmn-mapping-v1.md` §1), so the migration does not move Part I's
  semantic contract — but any Arc 0 "version matrix" agreed before T-424 lands
  pins AEF to a form we intend to retire.

- **IW-6: How much of Arc 4's Designer half already exists?**
  confidence: 3
  disposition: answered — **the read half ships; the write half does not**
  rationale: The annotation seam is ratified and shipped (T-250 GO, shape A,
  2026-07-27) and advertised structurally: `dist/MANIFEST.yaml` at release
  0.11.0 carries `capabilities: { annotation_seam: 1 }`. Contract in
  `docs/aef-designer-integration-protocol.md` §Annotation seam:
  designer→parent `aef:ready`, parent→designer `aef:annotate`, "read-only
  overlay: never serialized into BPMN, never in autosave… Malformed payloads
  are ignored without error." That is exactly the dossier's §10 requirement that
  the browser be a read-only projection surface. **What does not exist** is the
  Arc 4 requirement that "operator interactions submit authenticated proposals"
  (`roadmap` §4 Arc 4; dossier §10, §13 scenario 20). There is no proposal
  channel, and the seam's stated **origin policy v0 is `targetOrigin: '*'`,
  accept-parent-only**, with tightening to an allowlist named as "the designated
  next step if a second embedder class appears". An authenticated proposal path
  *is* a second embedder class in all but name.

- **IW-7: Can the Designer render a runtime fixture "without inventing
  semantics" (roadmap §2.1, Arc 1 joint gate) as it stands today?**
  confidence: 2
  disposition: answered — **not without the runtime contract stating defaults
  explicitly**
  rationale: our forward mapping infers. `aef-bpmn-mapping-v1.md` §2 defaults
  `horizon` to `now` when absent and infers `workflowType` from the BPMN type
  when absent; §3 **derives** `owner` from lane authority with no node override
  (IW-9, v1.1), warning rather than refusing on task-type/lane mismatch (O-1).
  Meanwhile `tier`'s absent-value default is still **Part II provisional —
  unratified** since 2026-07-11 (requested on thread T-175). A renderer that
  supplies defaults is inventing semantics unless the runtime contract declares
  the same defaults normatively. This is a concrete, cheap Arc 0 joint item.

- **IW-8: Which project is the "AEF" counterparty for envelopes and paired
  tasks?**
  confidence: 2
  disposition: deferred — **operator must name it**
  rationale: three projects are in play. The packet was authored and is governed
  in `0503-codex-cli-playground` (T-027/T-033/T-034/T-036/T-037); the roadmap's
  header names `/opt/999-Agentic-Engineering-Framework` as the "Intended
  recipient"; this project (832) is the Designer. Phase 4's envelope requires a
  concrete `to_project`. `docs/aef-designer-integration-protocol.md` documents
  the 832⇄999 seam only, including the T-559 project-boundary enforcement that
  blocks each side from reading the other's filesystem. No 832⇄0503 protocol
  exists.

- **IW-9: What correlation binds this dispatch?**
  confidence: 3
  disposition: deferred — **none was assigned; Phase 4 is undefinable until one is**
  rationale: the prompt artifact's operator dispatch checklist requires "one
  correlation per agent and one shared initiative correlation". Neither appears
  in the dispatch. Phase 4 defines handoff completion as read-back "on the same
  correlation", so no peer handoff can be *completed* — only transported —
  until the operator assigns them.

- **IW-10: Are the review findings the roadmap depends on actually in the
  pinned packet?**
  confidence: 3
  disposition: answered — **partially; two of four are undispositioned**
  rationale: `roadmap-5be23719.md` §4 Arc 0 task 3 requires "the consolidated
  refusal/threat matrix from Claude, Z.ai, **DeepSeek, and Mistral** findings",
  and §8 lists all four as evidence consulted. The pinned dossier carries
  disposition tables for **Claude only (§17) and Z.ai only (§18)**. DeepSeek
  (task TOCTOU, compensation idempotency, immutable evidence ordering) and
  Mistral (secret-binding refusals, confused deputy, provider divergence,
  command-boundary refusal tests) have no disposition section in the pinned
  source and no artifact in this project. Arc 0's exit gate ("every blocker
  finding has a contract disposition") is therefore not satisfiable from the
  packet alone.

- **IW-11: Does the dossier reconcile with AEF's already-ratified SD-1?**
  confidence: 2
  disposition: deferred — **needs a peer answer, not a Designer answer**
  rationale: `DISPOSITION-2026-07-28.md` addendum records **AEF T-2663 SD-1
  RATIFIED** (AEF operator via Watchtower, 2026-07-28T17:10Z, rail offset 287):
  "corpus + conformance rails + overlay ARE the AEF Process layer; code is the
  enforced machine, maps conform." The dossier proposes a different centre of
  gravity — a ratified *procedure* driving a runner. These may be compatible
  (layer identity vs execution machinery) but the pinned dossier never cites or
  reconciles T-2663. Escalate rather than average: the AEF agent owns this.

- **IW-12: What is the smallest Designer-owned slice that produces
  operator-visible value and cannot be wrong?**
  confidence: 2
  disposition: answered — see `reflection-designer.md` §6. In short: a
  **read-only contract inventory + a canonical worked fixture rendered through
  the existing frozen mapping**, delivered as a versioned artifact with a hash,
  and nothing else. It is Arc 0's Designer column exactly, it needs no AEF code
  to land first, and it is falsifiable.

- **IW-13: What would falsify the selected plan?**
  confidence: 2
  disposition: answered
  rationale: (a) the operator resolves IW-2 by **confirming** the DEFERs, which
  removes Arcs 4–6 from Designer scope entirely; (b) AEF answers IW-11 by
  ruling the runtime a *successor* to SD-1 rather than an extension, which
  changes the interchange contract's owner; (c) IW-5 resolves toward keeping
  `aef:position` authoritative, which invalidates any DI-based version matrix;
  (d) the runtime contract turns out to require the Designer to *evaluate*
  guards or outcome expressions, which would breach §5.1 prohibited overlap and
  make the whole Designer column refusable rather than schedulable.
