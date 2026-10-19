# T-282 — callActivity: a synchronous sub-workflow call with return

Inception research artefact (C-001). Started 2026-10-19, after the operator revived T-282 (H1 reversed,
`operator-decisions.yaml`). Status: exploration; no build before `fw inception decide T-282`.

## The question

Should the designer gain a `callActivity` node (a step that calls another map and waits for its result, with explicit
input and output mapping), and in what shape, so that a business step can be refined by a technical sub-workflow
without a second copy of the same process?

## Where it comes from

AEF's process-layer package (`docs/proposals/aef-workflow-process-layer-2026-07-02/`, INSTRUCTIONS §2.1, §2.3, SD-9):

- "New node type `callActivity` — synchronous sub-workflow invocation with awaited return and explicit I/O mapping
  (SD-9). Distinct from link events (asynchronous transfer, no return)."
- "Granularity refinement across files uses `callActivity` (business step → technical sub-workflow), not duplicated
  parallel documents. One source, no drift."
- §2.3 contract: `calledWorkflow` must resolve; the callee has exactly one startEvent and at least one endEvent;
  `ioMapping.inputs` must satisfy every required input of the callee's start contract; `ioMapping.outputs` must name
  callee end-event inputs; the call graph must be acyclic (error).
- Example node: `aef: { calledWorkflow: context-bundle-build, ioMapping: { inputs: { task_id: task_id }, outputs:
  { bundle: bundle_path } } }`.
- It also feeds two other revived items: component rollup (SD-13, "derived by rollup through callActivity") and the
  logical/pseudocode lenses (T-281, "calls for callActivity").

## What already exists

| Piece | State in the designer today |
|---|---|
| Link events (`linkEventThrow`/`linkEventCatch`) | Built. Asynchronous transfer, no return. The target map is pinned by `workflowRef` (its immutable uuid, T-225); `targetWorkflow` (slug) is the legacy leg; `linkId` pairs throw and catch; double-click jumps to the target map (T-160). |
| Embedded `subProcess` | Round-trips (collapsed composite); nested nodes are flattened on import (T-523, T-1131). |
| Node I/O contracts | Built: `aef:io` inputs (name, type, required) and outputs on every node. |
| Validator link rules | Resolution and pairing checks for link events exist; nothing for a call. |
| Corpus usage | 21 maps use link events, 20 use subProcess (repo-wide count, 2026-10-19). |

So the designer already has the parts a call needs: a durable reference to another map (`workflowRef`), a jump to
it, and I/O contracts on both sides. What is missing is a node that says "wait for that map and map its inputs and
outputs".

## AEF's position (2026-10-19, msgs 705e7d58 / b3ad7152)

- **No call-with-return need on their side today:** their corpus is descriptive, embedded subProcess round-trips,
  and link events are unused.
- **A `bpmn:callActivity` hard-fails their intake today** (`tools/corpus_spec.py`, strict parse, T-2614). They filed
  **T-4374** (horizon next) to accept it, round-trip only, with no execution semantics.
- **Their proposed v1 shape (provisionally agreed, final after this inception):** `calledElement` = the called map's
  corpus id; `extensionElements/aef:ioMapping` with `aef:in` and `aef:out` entries (source, target), no expressions
  in v1. AEF validates that `calledElement` resolves to an existing map; unknown tags stay a hard error.
- **Ordering (both sides recorded it):** no designer release emits callActivity before T-4374 lands.

## The deferral trigger, honestly

T-282 was parked until "a corpus map or AEF compile case needing call-with-return semantics that link events cannot
express". That trigger has **not** fired: AEF says no such case exists today. The revival rests on the operator's
ruling of 2026-10-19 (build the roadmap's Arc 4-6 features), not on new evidence of need. That is a legitimate basis,
because it is the operator's call. But it shapes the scope: build the smallest useful slice, and let a real first
user drive the rest (see the hypothesis).

## Design tension: how the called map is named

| Option | Pro | Con |
|---|---|---|
| **A. AEF v1:** `calledElement` = corpus id | BPMN-standard attribute; AEF validates it as-is | A corpus id or slug can be renamed; our link events moved away from exactly that (T-225 pinned the uuid) |
| **B. SD-9:** `aef:calledWorkflow` = workflow id | Matches the package text | Same drift risk, and not the BPMN attribute |
| **C. Both:** `calledElement` = corpus id (readable, standard) **plus** `aef:callRef workflowRef="<uuid>"` (durable) | Standard for AEF and third-party tools; durable for the designer; same identity model as link events | Two values that could disagree; needs a rule (uuid wins, a mismatch is a finding) |

**Leaning: C**, offered to AEF as a counter before any build. It reuses the link-event identity model the designer
already ships, and keeps AEF's v1 attribute untouched.

**AEF accepted C (msg bddf222c, recorded on their T-4374).** Settled shape:
- `calledElement` = the called map's corpus id: readable, unchanged.
- `<aef:callRef workflowRef="<uuid>"/>` in `extensionElements` as a SIBLING of `aef:ioMapping`, not inside it, so
  identity and data mapping stay separate.

AEF does more than tolerate it. All 16 AEF corpus maps carry a uuid, so their intake validates that `workflowRef`
resolves, and reports a `calledElement`/uuid disagreement as a finding naming both (the uuid wins, never a silent
rewrite). A map with `calledElement` and no `callRef` stays valid. Dependency on their side: T-4387 (aef children
matched by namespace, not local name) lands first, so callRef is read as aef by namespace. IW-1 is answered.

## Slices (if GO)

1. **Round-trip only:** import and export `bpmn:callActivity` with `calledElement`, the `aef:ioMapping` (in/out) and
   the identity reference; draw it (BPMN's thick-bordered task); the properties panel shows and edits the called map
   and the mappings; double-click jumps to the called map (as link events do). No validation beyond well-formedness.
   Released only after AEF T-4374 lands.
2. **Validation:** the called map resolves; in/out mapping names exist in the callee's start/end contracts; required
   inputs are covered (§2.3).
3. **Acyclicity:** a call graph across the library has no cycle (needs the map library, as the handoff registry
   does).
4. Later and separate: component rollup (SD-13) and lenses (T-281) consume it.

## Open questions

- **IW-1:** C (corpus id + uuid) or AEF's A? **Answered: C**, accepted by AEF with `aef:callRef` as a sibling of
  `aef:ioMapping` (msg bddf222c). (Confidence 3.)
- **IW-2:** Does the designer validate (slices 2-3), or does the Python validator, or both (parity, as the YAML/XML
  forms do)? (Confidence 2: both, as for every other rule.)
- **IW-3:** Who is the first user? AEF has no case. Candidates: the operator's onboarding maps (a business map whose
  step is refined by a technical one), or 832's own corpus (21 link-event maps: does any of them actually wait for
  a result and so really want a call?). (Confidence 0.)
- **IW-4:** Expressions in mappings: none in v1 (AEF's position, accepted).

## Hypothesis (draft)

We believe that a round-trip `callActivity` (slice 1) lets an author refine a business step into a technical
sub-workflow in ONE place, and we will achieve that without a second copy of the process. We will know we succeeded
when at least one real map pair (a caller and its callee, from the operator's onboarding routes or the corpus)
round-trips through the designer and AEF unchanged, with the jump working and the mapping visible in the panel.

## Dialogue log

- 2026-10-19, operator: revived T-279/280/281/282 ("definitely want all this stuff … build it"), confirmed "1":
  callActivity first; lenses raised with AEF.
- 2026-10-19, AEF: no need today; T-4374 for intake; v1 shape proposed; release ordering agreed.

## Recommendation (draft, for the go/no-go)

**GO for slice 1 only, behind AEF T-4374**, with IW-1 settled with AEF first (counter-propose C). Slices 2-3 become
their own build tasks once slice 1 has a real user (IW-3). Reason: the operator ruled to build; the designer already
has the identity, jump and I/O pieces, so slice 1 is small; but no case needs it yet, so the validation work should
wait for one.
