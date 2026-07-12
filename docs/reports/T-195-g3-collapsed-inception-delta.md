# G-3 collapsed-inception marker — v1.1 delta proposal

**Task:** T-195 · **Status:** proposal (frozen standards untouched — graduation is Dimitri's) · **Arc:** designer-authoring-surface
**Parallel to:** `docs/reports/T-189-iw9-authority-collapse-delta.md` (IW-9 authority-collapse delta). Both graduate together into a **v1.1** of the two standards.

---

## 1. Problem — the standards carry a superseded strawman

The AEF mapping standard's provisional **G-3 (inception marker shape)** was first written as a *strawman*: an
inception is a `subProcess` whose **terminal element is an `exclusiveGateway`** carrying the go/no-go. On the
termlink rail (T-175 thread, operator offsets 25/26/32) the AEF operator **ratified a different form**:

> **Ratified G-3 form.** An inception is a **collapsed `subProcess`** carrying `aef:meta workflowType="inception"`,
> laned in a **sovereignty** lane (so `owner` derives to `human`), with the go/no-go gateway **IMPLIED at the
> subProcess boundary** — there is **no child `exclusiveGateway`** (T-081 phase-1 emits no child / no nesting).
> Members are listed in `<aef:constituents>`. The go/no-go is *constitutive* (every inception has one); the
> collapsed boundary carries it implicitly rather than drawing it as a node.

The ratified form is already realised in the reference corpus — `tests/fixtures/aef-bpmn/inception-gonogo.bpmn`
(T-192) embodies it exactly, and `tests/test_forward_fixtures.py` guards it. But two frozen/support docs still
carry the strawman:

- **`docs/standards/aef-bpmn-mapping-v1.md:133`** (Part II, provisional) — still "terminal element is an `exclusiveGateway`".
- **`docs/standards/aef-bpmn-forward-compile-v1.md:164`** (§8 open items) — still poses "subProcess-with-decision vs. single-node-with-marker" as open.

Meanwhile forward-compile **§5** (:104/:115, updated in T-194) already describes the ratified collapsed form —
so §5 and §8 now contradict each other *within the same document*. This delta resolves all three.

**Scope boundary.** This is the *shape* of the inception marker only. It is orthogonal to the T-189 IW-9
authority-collapse delta (which is about Lane=who / workflow_type=kind / no node-owner-override). The two share
the v1.1 graduation event but touch different clauses.

---

## 2. The ratified form, precisely

| Aspect | Strawman (superseded) | Ratified (this delta) |
|---|---|---|
| Marker | `subProcess` + `aef:meta workflowType="inception"` | same |
| Go/no-go | explicit child `exclusiveGateway` (terminal) with `aef:decisionInput`/`aef:decisionOutputs` | **implied at the subProcess boundary** — no child gateway (T-081 phase-1: collapsed-only, no nesting) |
| Owner | (unspecified) | **derived from the sovereignty lane** (`aef:laneMeta authority="sovereignty"` → `owner: human`); no node-level override (IW-9) |
| Members | `aef:constituents` | same |
| Lightweight variant | "*Open:* single task-node-with-marker?" | **Resolved: NO.** The go/no-go is constitutive; the lightweight form is the *collapsed subProcess with the gateway implied at the boundary*, **not** a gateway-less task-node (operator ruling, T-190 context :44). |

**Forward-compile reading.** A compiler detects an inception by `subProcess` **carrying `aef:meta
workflowType="inception"`** — NOT by locating a child `exclusiveGateway`. It synthesises `workflow_type:
inception` + `owner: human` (from the sovereignty lane) directly from the marker; it does **not** parse a child
decision node (there is none). Distinguisher: `subProcess` **with** `workflowType="inception"` ⇒ inception;
`subProcess` **without** ⇒ ordinary composite/arc.

---

## 3. Exact before → after edits (for the v1.1 graduation — Dimitri applies)

### 3A. `docs/standards/aef-bpmn-mapping-v1.md` — Part II, G-3 bullet (line ~133)

**BEFORE:**
> - **Inception marker shape (G-3):** proposed — an inception is a `subProcess` with `aef:meta workflowType=inception`
>   whose terminal element is an `exclusiveGateway` carrying `aef:decisionInput`/`aef:decisionOutputs` (the
>   go/no-go), reusing `aef:constituents` for members. *Open:* whether a single task-node-with-marker is also
>   acceptable for lightweight inceptions.

**AFTER (graduates from Part II provisional into Part I frozen, under v1.1):**
> - **Inception marker shape (G-3) — ratified v1.1:** an inception is a **collapsed `subProcess`** with
>   `aef:meta workflowType="inception"`, laned in a **sovereignty** lane (`owner` derives to `human`; no
>   node-level override, IW-9). The go/no-go gateway is **implied at the subProcess boundary** — a conformant
>   inception MUST NOT emit a child `exclusiveGateway` (T-081 phase-1: collapsed-only, no nesting). Members are
>   listed in `<aef:constituents>`. A gateway-less task-node is **not** an acceptable inception form; the
>   lightweight inception IS the collapsed subProcess.

(On graduation, delete the strawman bullet from the Part II list and add the frozen clause; update the
`test_mapping_standard_conformance.py` guard if it asserts G-3 shape.)

### 3B. `docs/standards/aef-bpmn-forward-compile-v1.md` — §8 open item (line ~164)

**BEFORE:**
> - **Inception marker shape (G-3)** — subProcess-with-decision vs. single-node-with-marker.

**AFTER (remove from §8 open items; the question is resolved):**
> - ~~Inception marker shape (G-3)~~ — **RESOLVED (v1.1):** ratified as the collapsed `subProcess` +
>   `aef:meta workflowType="inception"` in a sovereignty lane, go/no-go implied at the boundary (no child
>   gateway). See §5 corpus (`inception-gonogo.bpmn`) and mapping-v1 §G-3. No longer open.

> **Note — §8 reconcile lands now (this task), not at graduation.** Item 3B is a *support-deliverable status
> update* on the 832-owned forward-compile doc — it corrects a stale open-item line that already contradicts
> §5 (:104/:115). It changes no contract (§2/§3 untouched). Item 3A edits the *frozen* mapping standard and is
> held for Dimitri's v1.1 graduation. This task applies **only 3B**; 3A is the proposal.

---

## 4. Graduation blast-radius — conformance-safe

- `tests/fixtures/aef-bpmn/inception-gonogo.bpmn` already **is** the ratified form; `test_forward_fixtures.py`
  is green now. Graduating the clause makes the standard match the fixture, not the reverse — **no fixture churn.**
- Editor (`src/aef-workflow-designer.html`) already emits `workflowType="inception"` on collapsed subProcesses
  (T-081 phase-1, no child nesting) — the ratified form is what it produces; **no editor change.**
- Bridge (`tools/yaml-to-bpmn.py`) META_KEYS already whitelists `workflowType`; **no bridge change.**
- The only edits are documentary: mapping-v1 Part II (3A, at graduation) and forward-compile §8 (3B, now).

---

## 5. Sign-off boundary

AEF's operator **ratified** the collapsed form on the rail — that clears the *AEF side*. Graduating it into the
**frozen** 832 mapping standard (3A) is **Dimitri's sovereignty**, not transferable from AEF's operator
ratification (same boundary as the T-189 IW-9 delta). This proposal presents the exact edits; it does not
apply 3A. The §8 support-doc reconcile (3B) is non-normative 832-side maintenance and lands with this task.

**Recommended batching:** graduate G-3 (this delta) together with IW-9 (T-189) in a single v1.1 bump of both
standards — they are independent clauses but share the version event and the conformance-test refresh.
