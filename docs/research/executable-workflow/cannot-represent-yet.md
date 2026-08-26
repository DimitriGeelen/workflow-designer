# What the Designer cannot represent yet

**Task:** T-590 · **Written:** 2026-08-26 · **Role:** workflow-designer-agent
**Initiative:** `ewcr-v1` · **Correlation:** `ewcr-v1-designer-fixture`
**Measured against:** `docs/standards/aef-bpmn-mapping-v1.md` **v1.1**, Part I frozen
**Sources:** `architecture-c9070637.md` §6.2 (bounded action vocabulary), §6.2.1 (registered
action contracts), §6.2.2 (declared failure routes), §6.3 (edges as interfaces), §6.4
(execution / capability profiles), §6.5 (secrets)
**Status:** research artifact. A gap listed here is a **fact about our frozen surface**, not a
request to change it and not a scheduled piece of work.

---

## 0. How to read this

Roadmap Arc 1's joint gate asks the Designer to render the canonical fixture **without
inventing semantics**. The honest way to pass that gate is to render what we *can* carry and
say precisely what we *cannot* — so AEF designs the runtime extension knowing our real surface
rather than a hoped-for one.

Every row below is stated the same way:

- **the gap** — what the dossier requires and our surface has no carrier for;
- **Part I evidence** — the citation that proves the absence is a property of the frozen
  standard, not an editor limitation someone could patch;
- **standing disposition** — the recorded decision that governs it, so nobody re-opens a
  question that already has an answer.

**A gap is not a defect.** Almost every absence here is *correct*: dossier §5.1 prohibited
overlap says Designer/browser code must not validate itself as authoritative, ratify a
procedure, mutate runner state, resolve secrets, launch actions, or approve a gate. Most of
what follows is a thing we are **not allowed** to carry, and carrying it would be the
regression. The gaps that are genuinely ours to close are marked **OURS**.

---

## 1. The §6.2 node vocabulary, row by row

Dossier §6.2 defines the bounded action vocabulary. Our Part I surface has BPMN element types,
not runtime node kinds. This table maps each §6.2 row onto what we can actually emit today.

| §6.2 node type | §6.2 runtime boundary | What our frozen surface can carry | Gap | Part I evidence | Standing disposition |
|---|---|---|---|---|---|
| **human gate** | "Cannot auto-advance without mapped decision" | `userTask` in a **sovereignty** lane. The lane gives us the **authority** (`owner: human`, no node override) | **G-1 — the decision mapping itself.** No carrier for the admissible decision options, the mapping from option to route, or the "cannot auto-advance" property. `aef:decisionInput` / `aef:decisionOutputs` exist as structured semantic elements but have no ratified runtime meaning, and `decisionOwner` is an editor-internal key explicitly **outside** the frozen v1 governance-scalar contract | mapping §2 table (four frozen keys only); §2 note: `gatewayKind`, `scopeOf`, `decisionOwner` "are **not** part of the frozen v1 governance-scalar contract and MAY change without a standard bump"; §3 `owner` = lane | Not deferred — genuinely unspecified. Routed as request **R3**/**R1**. Also collides with **defect D-1** (see §4) |
| **script** | "Action-catalogue reference, typed args, project cwd" | `scriptTask`, disambiguated `build` vs `test` via `workflowType` | **G-2 — everything that makes it *registered*.** See §2 below: six named absences | mapping §3 row `scriptTask`; §1 semantic-class list contains no action, hash, interpreter, argv, cwd or typed-IO carrier | **Arc 3 → DEFER** (`reflection-designer.md` §4): depends on an action catalogue and profile vocabulary that do not exist and are AEF-owned |
| **command** | "No arbitrary shell interpolation" | Nothing distinct. A `command` node would be a `serviceTask` or `scriptTask` with a name | **G-2b — no node kind, and no way to distinguish `script` from `command`.** §6.2.1 makes them different contracts (repo-relative pinned implementation vs approved structured CLI invocation with an executable identity/version policy); we cannot express either, let alone the difference | mapping §3 element table — the closed set is process / lane / userTask / serviceTask / scriptTask / gateways / subProcess / events / sequenceFlow / annotation | Arc 3 **DEFER**, same rationale |
| **agent prompt** | "Versioned prompt, resolved profiles, outcome checks" | `serviceTask` in an initiative lane, `agentType` ∈ `primary` \| `termlink-worker` \| `human` | **G-2c — no versioned prompt reference, no resolved profile, no outcome check.** `agentType` names *a class of executor*, not a prompt version and not an execution profile | mapping §2 `agentType` row (closed set of three) | **Arc 5 → REJECT as scheduled work; route to the existing DEFER.** This is SD-8/10/11 = **T-279** here, mirrored as AEF **T-2668 DEFER**. Its GO "begins with a rail conversation" and ownership is theirs |
| **service** | "Typed connector, redaction, idempotency/retry policy" | `serviceTask` | **G-2d — no connector type, no redaction profile, no idempotency rule, no retry policy** | mapping §1 semantic-class list; §2 four frozen keys | Arc 3 **DEFER** |
| **call workflow** | "Invoke sub-procedure and await result; explicit I/O map and cycle detection" | **Nothing.** `callActivity` is **absent from the editor entirely** | **G-2e — no sub-procedure invocation at all.** No `callActivity` node type, therefore no I/O map, no await semantics and no cycle detection. `subProcess` is *not* a substitute: §7 gives it a ratified meaning (composite / collapsed child arc / inception marker) that is about **composition inside one document**, not invocation of another ratified procedure | mapping §3 `subProcess` row ("Arc or composite task"); §7 inception marker; `callActivity` appears nowhere in Part I | **T-282 DEFER** (SD-9, `DISPOSITION-2026-07-28.md`, 2026-07-28, owner human). **Arc 6 → REJECT as scheduled work** — "migration presentation has no contract to present". Confirmed still `status: captured, workflow_type: inception` in `.tasks/active/` |
| **wait event** | "Bound event/correlation source and timeout" | `intermediateCatchEvent` with `aef:eventDef kind=error\|timer\|message` and `binding=` — error → `status:issues`, timer → cron / `horizon`, message → bus topic (T-204) | **G-2f — partial.** The event *kind* and a *binding* are carried, and are the **closest thing on this whole page to a runtime hook**. Absent: a **timeout**, a **correlation source**, and any notion of the event *resuming an instance* — because we have no instance | mapping §3 `intermediateCatchEvent` row; note that kind "lives in the extension, never the tag" | Not deferred; the closest existing surface. Named to AEF as the natural attachment point for `wait event` if they want one |
| **gateway** | "Declared conditions or human decision only" | `exclusiveGateway` (XOR) and `parallelGateway` (AND). Outgoing edges = branches; **edge label = condition** | **G-2g — the condition is a *label*, not a predicate.** A human-readable string with no type, no evaluation model and no determinism guarantee. Dossier §6.1 requires the guard language be "constrained, typed, deterministic, and auditable… never arbitrary code". A label is none of those | mapping §3 `exclusiveGateway` row: "edge label = condition" | **Refusable, not deferrable.** `reflection-designer.md` §8 stop condition 2: any request to author, evaluate, or store a guard/outcome expression in the Designer is refused under §5.1 prohibited overlap. We may *carry* an opaque reference; we may not *author or evaluate* a guard |
| **compensate** | "Explicitly bounded and separately authorised" | **Nothing.** No compensation node, no compensation association, no boundary-event compensation semantics | **G-2h — absent entirely.** The bridge's `META_KEYS` mentions `compensatedBy` / `compensationSnapshot`, but these are **not** frozen v1 governance keys and have no ratified meaning; they are not a contract | mapping §2 — the frozen set is exactly `horizon`, `workflowType`, `tier`, `agentType`; §2 note on non-frozen keys | Arc 3 **DEFER**. Also §6.2.2's whole declared-failure-route model (below) |

**Summary of §6.2:** of nine node types, our frozen surface carries **one and a half** — the
human gate's *authority* (not its decision), and a partial `wait event`. `call workflow` and
`compensate` are absent outright.

---

## 2. §6.2.1 — registered action contracts (the `script` node in detail)

§6.2.1 is the sharpest gap, because `script` is the dossier's **primary deterministic
execution path** and the one node the pilot actually needs. Its illustrative contract names
each of the following. Our surface carries **none** of them.

| §6.2.1 field | Purpose | Carrier in Part I |
|---|---|---|
| `action:` — the **action-catalogue reference** | "A workflow node names an action-catalogue reference, never a free-form shell string" | **none** |
| `implementation.path` + `content_hash` | Repo-relative allowlisted path with a pinned hash | **none** |
| `implementation.interpreter` | Policy-approved interpreter reference | **none** |
| `invocation.argv` | **Structured** arguments — explicitly not shell | **none** |
| `invocation.cwd` | `selected_worktree` | **none** |
| `invocation.environment` | Declared non-secret names only | **none** |
| `inputs:` / `outputs:` typed | `component_ref`, `evidence_ref` and friends | **none** — `aef:io` / `aef:input` / `aef:output` exist as semantic elements but carry no type system and have no ratified runtime meaning |
| `controls.capability_profile` | What the executor may access | **none**, and **must not** — §6.5 |
| `controls.timeout_seconds` | Bound | **none** |
| `controls.idempotency` | `run_once_per_instance_node_input_hash` | **none** — presupposes an *instance*, which we do not model |
| `controls.retry` | Attempt budget | **none** |
| `controls.output_redaction_profile` | Validated against known secret shapes | **none**, and **must not** — §6.5 |

**G-2 in one sentence.** Our `scriptTask` asserts that *a step of this kind exists at this
position in the procedure*, and nothing whatever about **which** script, **how** it is invoked,
**where**, **with what**, or **under what budget**. A node `name` is a human-readable label and
**must not** be read as a resolvable reference.

**Why this is not a defect to fix here.** §6.2.1 says the catalogue is "versioned, validated,
project-scoped, and approved alongside the procedure" — every one of those verbs is AEF's under
§5.1. Inventing a carrier before the catalogue exists would produce a format AEF must then
either adopt sight-unseen or refuse. Request **R1** asks for the extension form first.

### 2.1 The three pilot steps with no node at all

Dossier §2.5 lists six steps. The fixture renders **three**. The other three are gaps, and
they are the finding rather than an omission:

| §2.5 step | Why it has no node |
|---|---|
| **2 — runner preflight** ("independently checks ratification, current task state, gate outcome, selected worktree, component scope, test-command allowlist, and capability profile") | **Runner-owned.** §5.1: AEF is "sole authority for execution, isolation, event admission, capability/secret resolution, and evidence". A Designer-drawn preflight node would be the Designer describing an enforcement it does not perform — the exact confusion §5.1 exists to prevent |
| **4 — evidence capture** ("attempt identity, procedure/task hashes, policy decision, typed inputs, executor identity, timestamps, redacted output reference, exit outcome, resulting instance state") | **Ledger-owned.** We have **no evidence reference type** and no ledger write path. §5.1: "no execution credential or direct ledger write path" |
| **6 — task handoff** ("the evidence is attached/referenced from T-123; the task's own governed lifecycle remains the authority for any completion decision") | **AEF task-lifecycle-owned.** Reaching our `endEvent` is a **procedure boundary**, not a task completion. Mapping §3 row: start/end events are "Process boundary markers — **no task**" |

A fixture that drew these three would be inventing precisely the semantics the Arc 1 gate
forbids. Their absence is the exhibit.

---

## 3. §6.2.2 and §6.3 — failure routes and edges as interfaces

### §6.2.2 — declared failure routes

"Every executable node declares its failure routes as part of its contract." Named:
`transient_failure` with a bounded `self_heal` (`action_ref`, `max_attempts`, `only_if`
classifier predicate), `retry_original`, `deterministic_failure → route_to`,
`policy_refusal → route_to`, `timeout_or_unknown_side_effect → route_to`.

- **G-4 — no failure-route carrier of any kind.** Our closest surface is a `boundaryEvent`
  with `aef:eventDef kind="error" binding="status:issues"`, which says *"if this errors, the
  bound task's status becomes issues"*. That is a **governance** consequence, not a runtime
  route: no classifier, no attempt budget, no idempotency rule, no post-remediation
  verification, no separately-catalogued remediation action.
- Part I evidence: mapping §3 `intermediateCatchEvent` row — the binding vocabulary is
  exactly `status:issues` / cron-`horizon` / bus topic.
- Standing disposition: Arc 3 **DEFER**. And self-healing is explicitly *not* a general
  permission — it is "a separately catalogued, policy-approved remediation action", which is
  AEF's to catalogue.

### §6.3 — edges as interfaces

§6.3 says each edge carries more than sequence order: legal predecessor/successor; **named
typed output-to-input mapping**; **outcome guard and required evidence**; **authority
handoff / eligible actor type**; **retry, compensation, escalation or terminal error route**;
**instance/task/action correlation data**.

- **G-5 — an edge carries a stable `aef:uid` and ordering. That is all.** Mapping §3:
  "sequence flow (edge) → Ordering dependency; A→B ⇒ B depends on A". Five of §6.3's six
  bullets have no carrier. The sixth (predecessor/successor) is the one we do carry.
- The **outcome guard** bullet is the same refusal as G-2g: we may carry an opaque reference,
  never author or evaluate a predicate (§5.1; stop condition 2).
- **Authority handoff** is the interesting near-miss: we *do* model authority, but as a
  **lane**, i.e. as a property of the **node**, not of the **edge**. A lane-crossing edge is
  an authority handoff *by construction* and is not labelled as one. If AEF wants edge-level
  authority, that is a genuine design question for R1 — it is not something we are hiding.

---

## 4. §6.4, §6.5, §6.6 — profiles, secrets, delivery artefacts

| Dossier requirement | Gap | Disposition |
|---|---|---|
| §6.4 **execution profile** (agent role, provider adapter, eligible model class, budget, retry) and **capability profile** (skills, tools, MCPs, repository scope, opaque secret-binding names) | **G-6 — no profile reference of any kind.** The dossier's own boundary is right: "Expose declarative preferences only; never claim provider equivalence" (§5.1). We do not even carry a preference | Arc 3 **DEFER**. We should carry an **opaque stable reference** and never a resolved profile |
| §6.5 **secrets** — "only opaque secret-binding references, never secret values"; output-redaction profiles validated against known secret shapes | **G-7 — nothing, and this is the one gap that must stay open forever.** §5.1 forbids the Designer resolving secrets; `reflection-designer.md` §8 stop condition 2 makes any request to store a secret or a capability grant a **refusal**, not a task | **Refusable, not deferrable** |
| §6.6 / §6.6.1 delivery artefacts as contract objects; §6.6.2 executor and model preference as policy inputs | **G-8 — no delivery-artefact type and no model-preference carrier** | Arc 3 **DEFER** |
| §7.3 **instance state machine**, §7.4 attempt outcomes, §7.5 per-node sequence | **G-9 — we do not model an instance at all.** A diagram is a *procedure shape*; there is no enactment, no attempt, no current state. Everything downstream of §7 is therefore unrepresentable by construction | The **annotation seam** (T-250 GO 2026-07-27, shape A; `capabilities: { annotation_seam: 1 }` at release 0.11.0) is the ratified read-only projection channel — parent→designer `aef:annotate`, "never serialized into BPMN, never in autosave, malformed payloads ignored without error". It carries **badges**, not state. Instance/attempt/evidence projection is **T-280 DEFER** |
| §10 operator interaction — "operator interactions submit authenticated proposals" | **G-10 — no proposal channel exists.** The seam is one-way parent→designer. Its **origin policy is v0 `targetOrigin: '*'`, accept-parent-only**, with allowlist tightening named as the designated next step "if a second embedder class appears" — and an authenticated proposal path **is** a second embedder class in all but name | **Arc 4 → REVISE and split.** Read half partly delivered; write half is a genuine new surface with a **security dependency**. Fabric-navigation half collides with **T-280 DEFER** and **T-281 DEFER / AEF T-2669 NO-GO** |

---

## 5. Gaps that are genuinely **OURS**

Everything above is either AEF-owned or correctly refused. These four are on our side of the
boundary and are the only rows a Designer task could close.

| # | Gap | Evidence | State |
|---|---|---|---|
| **D-1** **OURS** | `workflowType`'s frozen inference for `userTask` yields **`human-facing`**, which is **not a member** of its own closed value set `build\|test\|refactor\|decommission\|specification\|design\|inception`. A `userTask` with no explicit `workflowType` therefore has **no conformant compiled value** — and that is exactly the human-gate node the pilot needs | mapping §2, the `workflowType` row: allowed-values column vs absent-value column, in the same row | Raised as **R3a**. **Not fixed here:** moving Part I requires a version bump + a conformance-test update (§Versioning), which is out of scope for a read-only slice. The fixture leaves `workflowType` absent on both gates and says why in each node's `aef:meta note` |
| **M1** **OURS** | **No uid uniqueness requirement and none enforced** — two *authored* uids with the same value both survive, on nodes and edges. A record-keyed consumer collapses them silently | `tools/_t518-uid-collision.mjs`; T-518 `work-completed` | Measured and pinned. Whether uid is a **key** is a joint contract decision (R3/R5b), not a unilateral fix |
| **M3** **OURS** | **A uid survives containment; the containment does not** — a node inside `<bpmn:subProcess>` is hoisted to process level and the subProcess returns **empty**. The record silently changes parent | `tools/_t523-subprocess-nesting.mjs`, `tools/_t523-nesting.pin.json` | Measured and pinned. Directly limits any scope-bearing runtime construct — including `call workflow` (G-2e), whose natural rendering would be a nested scope |
| **T-501 / T-564** **OURS** | Map ID round-trip defect triage; load-time ID normalisation | both `status` active in `.tasks/active/` | **Open.** A runtime contract should not assume load-time ID behaviour is settled until T-564 closes |

For the closed measurement tasks and the one remaining uncovered gap (the **AEF-side reverse
renderer**, M4 — open by agreement at rail 11911, not by neglect), see
`designer-contract-inventory.md` §4.2.

---

## 6. What we *can* represent — stated so the gap list is not read as "nothing"

For symmetry, and because the fixture is the proof:

- **Procedure shape** — nodes, ordering, lanes, pools, boundary markers.
- **Authority** — via lane, with a compile-time collapse map and an O-3 compile-time MUST for
  inception go/no-go.
- **Stable identity** — `aef:uid` on every node and every edge, **externally assignable**, so
  AEF can key records on our documents (subject to M1 and M3).
- **Four frozen governance scalars** — `horizon`, `workflowType`, `tier`, `agentType`, with
  documented defaults and inference rules (`designer-contract-inventory.md` §3).
- **Typed event kinds and bindings** — `error` / `timer` / `message` with a binding
  vocabulary, the closest existing hook to a runtime concern.
- **Composition** — `subProcess` as composite / collapsed child arc, and the ratified
  inception marker (§7).
- **Cross-process reference** — `linkEventThrow` / `Catch` → `related_tasks`.
- **A lossless round trip** over all of the above, fenced by the guard tests named in
  `designer-contract-inventory.md` §5.

That is a **proposal surface**, exactly as §5.1 intends. It is not an execution surface, and
this document is the list of reasons why.
