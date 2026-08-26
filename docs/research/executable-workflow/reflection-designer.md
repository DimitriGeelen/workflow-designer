# Designer-side reflection — executable workflow-contract initiative

**Task:** T-587 · **Written:** 2026-08-25 · **Role:** workflow-designer-agent
**Dispatch:** prompt artifact T-036, Prompt B; source task T-037
**Status:** research output. Nothing here is a decision, a ratification, an arc,
or a confirmed BVP score.

---

## 1. Source ingestion receipt and local immutable paths

| Document | Expected SHA-256 | Observed | Stored at |
|---|---|---|---|
| Architecture dossier | `c9070637b09493a24abc99982ae966a3b3ae8cd4a358a44fdceb59bdceb6ac2d` | **match** | `docs/research/executable-workflow/architecture-c9070637.md` |
| Delivery roadmap | `5be23719b976e37a6461b4b1f6f309985b5ba033ef0b801769edd2627fbae5b8` | **match** | `docs/research/executable-workflow/roadmap-5be23719.md` |

Both hashes were verified **before** copying and re-verified **after** storage
(read-back succeeded). Manifest: `source-manifest.yaml`; machine-checkable
checksum file: `source-manifest.sha256`
(`sha256sum -c docs/research/executable-workflow/source-manifest.sha256`).

Transport note: HTTP retrieval from `192.168.10.107:3001` was not possible in
this session (`curl` denied). Bytes were taken from the authoring project's
working tree, an explicitly configured additional working directory. The pinned
hash is the trust boundary and it matched exactly — the same argument
`docs/aef-designer-integration-protocol.md` §"Delivery across the T-559 project
boundary" already makes for release delivery ("the checksum is the trust
boundary — the transport is irrelevant as long as the received bytes match").

## 2. Understanding of the architecture and the ownership boundary

See `operating-digest.md` for the navigable version. In five points:

1. **A procedure is not a diagram and not a task.** Dossier §2 separates
   procedure (ratified reusable method), router (a procedure that selects a
   procedure), instance (one live enactment of one pinned version), and task
   (AEF's canonical work record). Collapsing any two is the primary design
   failure mode the dossier is written to prevent.
2. **Execution authority lives in one privileged runner, outside every agent
   identity** (§0.1, §7.3, §11, §18). Current state is a deterministic fold of
   an append-only ledger; a projection is never recovery or audit authority.
3. **Our frozen boundary is explicitly protected.** §0.1 and §6.1 state the
   runtime does not alter Mapping Standard Part I; frozen v1.1 keeps compiling a
   diagram only into *proposed* governed work. An executable procedure needs a
   **separately versioned runtime-contract extension**. Our standard already
   says the same thing from the other side (`aef-bpmn-mapping-v1.md` §3).
4. **The Designer is a proposal surface, never an authority.** §5.1 prohibited
   overlap: browser code must not validate itself as authoritative, ratify,
   mutate runner state, resolve secrets, launch actions, or approve a gate.
   Ratification contract: "a Designer save/export never ratifies or executes."
   This is the rule we must actively preserve, not merely comply with.
5. **Collaboration completes on read-back, not on delivery.** Hub delivery /
   `file_send` / inject is transport evidence only; completion is receiver
   read-back of the exact version+hash plus a substantive
   accepted/refused/needs-decision on the **same correlation**.

## 3. Current-state / gap matrix (evidence-backed)

| Surface | Current state here | Evidence | Gap against the proposal |
|---|---|---|---|
| **Authoring UX** | Mature single-file editor, release **0.11.0**, 966 087 bytes, sha `4f20b146…` | `dist/MANIFEST.yaml`, `src/aef-workflow-designer.html` (10 940 lines) | No node kinds for the §6.2 vocabulary (`script`, `command`, `agent prompt`, `service`, `wait event`, `compensate`). `callActivity` absent → **T-282, DEFER** |
| **Mapping / semantics** | Standard **v1.1**, Part I frozen, conformance-fenced by `tests/test_mapping_standard_conformance.py`; two-class semantic/presentational partition is normative | `docs/standards/aef-bpmn-mapping-v1.md` §1–§7 | Part II (`tier` default, AC-seeding) **still unratified since 2026-07-11**. Compiler *infers* `workflowType`, defaults `horizon`, derives `owner` from lane — a runtime fixture renderer must not invent these (IW-7) |
| **Identity / round trip** | `aef:uid` on every node/edge, **externally assignable**; byte-identical fixture guard (V3 DELIVERED, G-002, T-187/T-188) | standard §5; `DISPOSITION-2026-07-28.md` scorecard | Open defects at the externally-assigned-value level: **T-501, T-518, T-520, T-523, T-564**. Geometry authority mid-migration: **T-357 → T-423 → T-424**, plus T-340 (standard BPMN DI discarded on import) |
| **Diagnostics presentation** | `tools/validate-workflow.py` (YAML+XML) + conformance suite; judge separation DELIVERED (V6) | `DISPOSITION-2026-07-28.md` V6 | No presentation of *AEF-originated* diagnostics with stable codes + affected element IDs. Surfacing validator findings in the editor is **T-309** (open; file unreadable this session). Rule-parity debt: T-317, T-320, T-321, T-325 |
| **Runtime projection** | **Annotation seam ships** — `capabilities: { annotation_seam: 1 }`, read-only badge overlay, never serialised into BPMN, malformed payloads ignored | `docs/aef-designer-integration-protocol.md` §Annotation seam; T-250 GO 2026-07-27; T-258/T-261 | Badges only. No instance/attempt/evidence projection, no version projection, no diagram↔Fabric navigation (**T-280, DEFER**), no audience lenses (**T-281, DEFER here / NO-GO on the AEF side**) |
| **Operator interaction** | **Nothing.** The seam is one-way parent→designer display | same | Arc 4 requires *authenticated typed proposals* from the operator surface. No proposal channel exists, and the seam's **origin policy is v0 `targetOrigin: '*'`**, accept-parent-only, with allowlist tightening already named as the next step. A proposal path is a security-relevant change to that seam |
| **Component Fabric** | **67 component cards** — not the 0/0 the roadmap assumes | `.fabric/components/` | Instrumentation is defective: **T-342, T-343, T-344, T-345, T-524, T-525**. Correct state is *measured but not trustworthy* — which dossier §8.2 says must route to policy, never be read as low impact |
| **Guided/strict enforcement** | Advisory-by-convention only; verified absent both sides | `DISPOSITION-2026-07-28.md` SD-8 | **T-279, DEFER**; mirror AEF **T-2668, DEFER** |

## 4. Proposed arc/task dispositions (proposals only)

| Roadmap arc | Designer disposition | Evidence |
|---|---|---|
| **Arc 0 — contract baseline** | **ACCEPT, revised.** This is the only arc whose Designer column is genuinely unclaimed work, and it is read-only inventory | roadmap §2.1, §4 Arc 0 |
| **Arc 1 — semantics kernel** | **ACCEPT as a constraint, not as work.** "Read fixture/projection prototypes only; no execution code" is exactly right. Our contribution is one rendered fixture, and the joint gate must be worded so rendering it does not require us to supply defaults (IW-7) | roadmap §2.1 Arc 1 |
| **Arc 2 — isolation proof** | **ACCEPT, and volunteer the adversarial claim.** "Prove browser/editor cannot reach execution/secret/ledger authority" is *already substantially true by construction* and cheap to evidence. But it must be re-proved **after** any proposal channel lands, not before | roadmap §2.1 Arc 2; annotation-seam contract |
| **Arc 3 — actions/providers** | **DEFER.** Depends on an action catalogue and profile vocabulary that do not exist and are AEF-owned. Nothing for us to author against | dossier §6.2.1, §14.3 |
| **Arc 4 — operator/Fabric** | **REVISE and split.** Read half partly delivered (annotation seam). Write half (authenticated proposals) is a genuine new surface with a security dependency. Fabric-navigation half collides with **T-280 (DEFER)** and **T-281 (DEFER / AEF NO-GO)** | IW-2, IW-6 |
| **Arc 5 — guided agentic** | **REJECT as scheduled work; route to the existing DEFER.** This is SD-8/10/11 = **T-279**, already deferred here and mirrored as AEF **T-2668 DEFER**. The disposition addendum states its GO "begins with a rail conversation", and ownership is *theirs* | `DISPOSITION-2026-07-28.md` §Addendum |
| **Arc 6 — routing/composition** | **REJECT as scheduled work.** SD-9 = **T-282 DEFER**; migration presentation has no contract to present | same |

**The single most important disposition:** Arcs 4–6's Designer column reverses
four standing DEFER recommendations and one peer NO-GO **without a superseding
decision**. That is an authority question, not a scheduling question. It is
listed in §8 below as a human decision.

## 5. The next justified slice (one, and only one)

**Proposed slice — Designer-owned, joint-reviewed: "Contract inventory and one
canonical rendered fixture."** This is Arc 0's Designer column, nothing more.

Deliverables:
1. A versioned, hash-addressed **Designer contract inventory** stating, for the
   runtime-contract negotiation: the frozen Part I surface, the semantic /
   presentational partition, the governance meta-keys and their **defaults and
   inference rules** (this is what makes IW-7 resolvable), the `aef:uid`
   identity model **including its known open defects**, and the current
   import/export/round-trip guarantees with their guard tests named.
2. One **worked procedure fixture** rendered through the existing frozen
   mapping — the dossier's §2.5 `human gate → registered script → human gate`
   pilot — exported as BPMN with its sha256, delivered as a proposal.
3. An explicit **"what we cannot represent yet"** list derived from §6.2's node
   vocabulary, so AEF designs the runtime extension knowing our real surface.

Why this one:
- It is **read-only and additive**. It moves no Part I boundary, adds no node
  kind, changes no compiler behaviour, and cannot ratify anything.
- It **lands without AEF code**. Its exit evidence is executable here today.
- It is **falsifiable**: either AEF reads back the hash and answers, or the
  collaboration protocol has failed and we learn that cheaply.
- It **discharges the real Arc 0 blocker**, which is not topology — it is that
  neither side has written down what our defaults and inference rules are.

Explicitly **out** of this slice: any proposal channel, any new node kind, any
DI/geometry decision, any Fabric navigation, any lens, any BVP confirmation.

## 6. Proposed BVP scores (proposals — NOT confirmed)

⚠ **Driver-ID collision hazard — do not import the roadmap's table.** The
roadmap (§3) uses `F1 = Context Fabric`, `F2 = Component Fabric`,
`F3 = Prompt Quality`. This project's `policy/value-drivers.yaml` v3 uses
`F1 = V_SDLC_ENABLEMENT (9)`, `F2 = V_COMPONENT_FABRIC (6)`,
`F3 = V_AEF_INTEGRATION (9)`, `F4 = V_WORKFLOW_ROUTING (9)`,
`F-RECALL (6)`. Only F2 happens to agree. Copying the roadmap's per-arc scores
verbatim would silently mis-score F1 and F3.

Note also that this project applies an **inception scoring exception**: a task
with `workflow_type: inception` is ranked by `voi_score` alone, not per-driver
(`policy/value-drivers.yaml` §inception_scoring_exception). T-587 carries
`voi_score: 0.9`, `target_blast_radius: 5`.

For the §5 slice, scored as build work under **local** drivers:

| Driver (local) | Proposed | Confidence | Counterargument |
|---|---:|---|---|
| D1 Antifragility (9) | 2 | medium | Writing down defaults prevents a whole class of silent-divergence failure. But it adds no *mechanical* protection — no gate refuses anything new. If it lands as a document rather than a conformance test, this is a 1 |
| D2 Reliability (7) | 3 | high | Makes the interchange contract explicit and hash-pinned, which is reliability-through-not-relitigating. Capped because it changes no runtime behaviour |
| D3 Usability (5) | 1 | high | Operator-visible value is thin — a document and a fixture. Honest score |
| D4 Portability (3) | 4 | high | Directly serves the standard's stated purpose: "the framework talks to this format, not to any one editor" (standard §Purpose). Writing the defaults down is what makes a *second* conformant editor possible |
| F3 V_AEF_INTEGRATION (9) | 4 | high | This is squarely the 2026-08-16 operator directive. Not 5: it produces a proposal, not an integration |
| F1 V_SDLC_ENABLEMENT (9) | 2 | medium | Enables the SDLC-on-workflows direction but delivers none of it |
| F4 V_WORKFLOW_ROUTING (9) | 1 | high | Almost nothing. Routing is Arc 6 and rejected here |
| F2 V_COMPONENT_FABRIC (6) | 0 | high | Touches no topology. Deliberately 0 — see IW-3; claiming otherwise would launder an untrustworthy Fabric into a value claim |
| F-RECALL (6) | 4 | high | The artifact's whole purpose is that future sessions and the peer stop rediscovering our defaults |

**Global counterargument to the roadmap's own scoring:** its §5 table gives
Arcs 5–6 the highest values while marking them "after Arc 5" / "low-medium"
confidence. Its own §3 says a high score does not make a blocked arc actionable,
and §5 warns the scores "must not bypass their predecessor gates". Combined with
IW-2 (those arcs sit on standing DEFERs), the highest-scoring rows in that table
are the least actionable work in the initiative. **Dependency and safety gates
outrank BVP rank.**

## 7. Required AEF contract requests, versions, fixtures, acceptance evidence

Each is a **paired task** — one in each project, same contract version + hash,
named integration fence. None may be opened until a correlation exists (IW-9)
and the counterparty project is named (IW-8).

| # | Request to AEF | We supply | We need back | Acceptance evidence |
|---|---|---|---|---|
| R1 | **Runtime-contract extension form** — BPMN extension vs companion manifest (dossier §6.1, §14.1) | our inventory + the constraint that Part I is unmoved | a decision with a version identifier | a named `runtime-contract v0.x` with a compatibility statement against mapping v1.1 |
| R2 | **Ratify Part II** — `tier` default and AC-seeding, open since 2026-07-11 on thread T-175 | the standard's §Part II text verbatim | ruling | Part II graduates or is explicitly re-deferred with a date |
| R3 | **Normative defaults** — does the runtime contract adopt our inference rules (`horizon→now`, `workflowType` inferred from BPMN type, `owner` derived from lane, O-1 warn-not-refuse) or override them? | the rule set with citations | accept / override per rule | resolves IW-7; without it Arc 1's "render without inventing semantics" gate is unpassable |
| R4 | **Diagnostic schema** — stable codes, affected element IDs, failed predicate, severity, lawful remediation (dossier §5.1 contract 3) | our current rule vocabulary and its parity gaps (T-317/T-320/T-321/T-325) | the schema | T-309 becomes buildable |
| R5 | **Canonical pilot fixture** — the §2.5 human-gate → registered-script → human-gate procedure | our BPMN rendering + sha256 | read-back of our hash + accept/refuse | Arc 1's joint gate |
| R6 | **Disposition of DeepSeek and Mistral findings** (IW-10) | nothing | the two missing disposition tables | Arc 0's exit gate becomes satisfiable |
| R7 | **Reconciliation with ratified SD-1** (T-2663, IW-11) | the disposition record we hold | their ruling | no unresolved source-of-truth conflict, per Phase 7 |

## 8. Governance monitoring plan, stop conditions, human decisions

**Dashboard (deltas only) —** to live at
`docs/research/executable-workflow/status.md` once the slice is authorised:

```text
source revision | current arc/task | gate state | peer contract/receipt state
latest evidence | blockers/risks | human decisions needed | next safe action
```

**Reconcile at:** session start, task transition, handoff, verification failure,
arc boundary, before completion. Re-verify
`sha256sum -c docs/research/executable-workflow/source-manifest.sha256`
at session start and before every cross-project handoff.

**Stop conditions — halt and escalate, do not route around:**
1. A source hash stops matching → `VERSION MISMATCH`, stop, require a new manifest.
2. Any request to author, evaluate, or store a guard/outcome expression, a
   secret, a capability grant, or a ratification state in the Designer → refuse
   under §5.1 prohibited overlap.
3. Any peer handoff whose read-back does not return the exact version+hash on
   the same correlation → incomplete; do not treat delivery as acceptance.
4. Any proposal to move Mapping Standard Part I without a version bump and a
   conformance-test update.
5. Any instruction to confirm BVP, start or close an arc, or complete a
   human-owned task.
6. Fabric-derived blast-radius claims while T-342/343/344/345/524/525 are open.

**Human decisions required (operator):**

| # | Decision | Why it cannot be an agent call |
|---|---|---|
| H1 | **Do the roadmap's Arcs 4–6 supersede the standing DEFERs (T-279/280/281/282) and AEF's T-2669 NO-GO?** | Reversing a recorded disposition is a sovereignty act. Until answered, treat those arcs as *not actionable*, whatever they score |
| H2 | **Name the AEF counterparty project** — 0503 (author/governance) or 999 (intended implementer)? | Determines `to_project` for every envelope and every paired task (IW-8) |
| H3 | **Assign the two correlations** — one for this agent, one for the initiative | Phase 4 completion is undefined without them (IW-9) |
| H4 | **GO/NO-GO on the §5 slice** | Phase 3: only the next justified slice, operator-authorised |
| H5 | **Reconcile the governance deviations in §9** | The framework CLI was unavailable; task state needs operator reconciliation |
| H6 | **Route R6 and R7 to AEF** | Cross-project asks with a named decision owner |

## 9. Governance deviations in this session (disclosed, not routed around)

The session permission profile denied **every** `fw`, `git` and `curl` Bash
invocation, and the session is non-interactive so approval could not be
obtained. `.claude/settings.json` and `.context/working/session.yaml` are
root-owned `0600` and unreadable, so the enforcement config could not be
inspected. Three relevant task files (T-309, T-357, T-501) are likewise
unreadable; their content is inferred from filenames only and is marked as such.

Consequences and exactly what was done instead:

1. **Phase 0 steps 2–3 not performed mechanically.** No `fw doctor --quick`,
   `fw context status`, `fw resume status`, `fw fabric`, `fw arc`, `fw bvp`.
   Health state below is filesystem-derived, not tool-attested.
2. **T-587 was created by writing a conforming task file**, not via
   `fw task create`. Format was matched against `.tasks/templates/inception.md`
   and a current live task. ID `T-587` chosen as max(active ∪ completed)+1.
3. **`focus.yaml` was deliberately NOT edited.** It still reads
   `current_task: T-586`. Hand-moving focus would disturb T-586, which is
   mid-flight with an unfinished Human AC. Focus is therefore *stale relative to
   T-587* and the operator must set it.
4. **No commit was made.** All artifacts are uncommitted in the working tree.
5. **No assumption/learning/decision was registered** in the Context Fabric
   (`fw assumption add`, `fw context add-learning` unavailable). The content
   that would have gone there is in `questions-and-dispositions.md`.

**Operator reconciliation — copy-pasteable, one line each:**

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context focus T-587
```
```
cd /opt/832-Workflow-designer && sha256sum -c docs/research/executable-workflow/source-manifest.sha256
```
```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw task show T-587 && .agentic-framework/bin/fw doctor
```

If `fw task show T-587` reports a malformed task, the hand-written file is the
fault and should be replaced by a real `fw task create` with this file's body.
