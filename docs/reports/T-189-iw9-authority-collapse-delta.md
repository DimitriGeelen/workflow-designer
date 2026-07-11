# IW-9 — v1.1 Mapping-Standard Delta: Collapse Triple-Encoded Authority

**Task:** T-189 · **Status:** DRAFT proposal — awaiting operator (Dimitri) sign-off · **Arc:** designer-authoring-surface
**Targets:** `docs/standards/aef-bpmn-mapping-v1.md` (FROZEN v1) — a v1 → **v1.1** delta
**Origin:** AEF design-review finding IW-9 (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, offset 20); 832-side BPMN read (offset 24); **AEF operator RATIFIED the framing** (offset 25, 2026-07-11).

> **This document is a proposal, not a graduation.** Under 832 governance, editing the FROZEN v1 standard
> requires the standard's change-control (version bump + conformance-test update) **and Dimitri's sign-off**.
> AEF's operator ratifying the framing clears the *AEF* side only; it is not transferable to the 832 side.
> Nothing in `docs/standards/` has been edited to produce this. The delta below is written so that, on GO,
> graduation is a mechanical apply — every before→after is spelled out.

---

## 1. The problem (IW-9)

Authority — *who is accountable for a unit of work* — is currently **triple-encoded** across three
independent carriers that can disagree with **no reconciliation rule**:

| Carrier | Where | Encodes |
|---|---|---|
| **Lane** (swimlane) | BPMN | who-performs (human lane vs agent lane) |
| **`workflow_type`** | `aef:meta workflowType` | kind-of-work — but `inception` also implies a *human* go/no-go authority |
| **node-level `owner`** | `aef:meta owner` | an explicit override of the lane default |

Frozen v1 makes the third carrier authoritative over the first via §3:
*"node-level `owner` MUST override the lane default; absent → lane default."*
So `workflow_type:build ⊕ Lane:human ⊕ owner:agent` is expressible and self-contradictory, and v1 gives no
rule to reconcile it. This extends IW-7 (owner↔Lane double-encoding) with a *third* drift axis.

## 2. The ratified direction — two orthogonal axes

Collapse to **exactly one authority-of-record axis and one kind axis**, which are orthogonal and therefore
cannot disagree:

- **Axis 1 — WHO performs (authority-of-record) = the Lane.** `owner:human` ⇔ human lane; `owner:agent` ⇔
  agent lane (per IW-7). The task-YAML `owner` field is compiled **from the node's lane, always**.
- **Axis 2 — WHAT KIND of work = `workflow_type`** (via `aef:meta workflowType`). `inception` = a
  decision / go-no-go unit; `build`/`test`/`refactor`/… = execution units. This is intrinsic to the type and
  is **not** a separate authority carrier.
- **REMOVED — the node-level `owner` override.** A node's owner *is* its lane, full stop. This deletes the
  redundant third encoding and the three-way-drift hazard.

Consequence for G-3 (ratified, offset 25): an inception's go/no-go carries `owner:human` — under this delta
that is expressed structurally by placing the go/no-go gateway **in the human lane**, not by a node-level
owner override. Editor + compiler read the same single carrier.

---

## 3. Exact delta to frozen v1 (before → after)

All line references are to `docs/standards/aef-bpmn-mapping-v1.md` as of the frozen v1 (sha cited in that
file's footer). Three edits, plus the version bump.

### 3.1 §2 — governance meta-keys table, `owner` row

**BEFORE**

| `aef:meta` key | Task-YAML field | Allowed values | Default when absent |
|---|---|---|---|
| `owner` | `owner` | `human` \| `agent` | lane default; node value overrides lane (§4) |

**AFTER**

| `aef:meta` key | Task-YAML field | Allowed values | Default when absent |
|---|---|---|---|
| ~~`owner`~~ *(derived — see below)* | `owner` | `human` \| `agent` | **derived from the node's lane; there is no node-level override** |

Rationale line to add under the table: *"`owner` is not an independently-authored governance scalar in
v1.1: it is compiled from the lane (Axis 1). It remains in task-YAML output but has no node-level BPMN
carrier of its own."*

### 3.2 §2 — the `conformance-governance-meta-keys` fenced block

**BEFORE**
```
horizon
workflowType
owner
tier
agentType
```

**AFTER**
```
horizon
workflowType
tier
agentType
```

(`owner` is removed from the frozen fence because it is no longer an *emitted node-level* governance meta-key —
it is derived from the lane. See §4 for why this specific removal is conformance-safe.)

### 3.3 §3 — the "owner precedence" line

**BEFORE**
> **owner precedence:** node-level `owner` MUST override the lane default; absent → lane default.

**AFTER**
> **owner is the lane (IW-9, v1.1):** a node's `owner` MUST be its lane. There is **no** node-level `owner`
> override. The Lane is the sole authority-of-record for who-performs; task-type (userTask vs
> service/scriptTask) SHOULD agree with the lane and is presentational where it does not (see Open Question O-1).

### 3.4 Version & change-control footer

- Bump the header **Version** `1.0` → `1.1`, dated at graduation.
- Add a v1.1 changelog entry: *"IW-9 — collapsed triple-encoded authority to two orthogonal axes (Lane =
  who; workflow_type = kind); removed the node-level `owner` override."*
- Move the IW-9 line out of any Part II provisional tracking (it is now frozen).

---

## 4. Graduation blast-radius (what the version bump touches)

Scoped *now* so the apply is bounded and no red slips past:

1. **`tests/test_mapping_standard_conformance.py`** — parses the `conformance-governance-meta-keys` fence and
   asserts `frozen ⊆ editor metaKeys ∧ frozen ⊆ bridge META_KEYS`. Removing `owner` from the fence makes the
   frozen set a **strict subset** of what editor/bridge emit, so the assertion **still passes** whether or not
   editor/bridge keep an `owner` key. **This removal is conformance-safe — no test edit is strictly required
   to stay green.** (A test comment noting the intentional removal is advisable but not gating.)
2. **Editor `metaKeys` / bridge `META_KEYS`** — MAY continue to carry `owner` for reverse-render laning
   (§4 reverse: "laned by `owner`"); they are not *required* to drop it, because the parity tests are subset
   checks. The **behavioral** change (forward-compile derives `owner` from lane; a node-level `owner` meta is
   ignored rather than honored as an override) is real code and is **out of scope for this doc-delta** — it is
   downstream build work the graduation authorizes, not part of editing the standard. Recommend a separate
   build task filed on GO. The T-187/T-188 round-trip guards will cover that serialization change when it lands.
3. **No fixture regen** — `aef:uid` and node/edge identity are untouched; this is a semantics/wording delta,
   not a geometry or identity change.

Net: the *standard* delta is three text edits + a version bump and is conformance-green as written. The
*implementation* of owner-from-lane is a separate, clearly-scoped build task.

---

## 5. Open questions requiring an operator ruling

These are genuine forks the delta should **not** silently resolve:

- **O-1 — Lane vs task-type tiebreak.** BPMN task-type also implies execution authority (userTask→human,
  service/scriptTask→agent). If a serviceTask sits in a *human* lane, which wins? Proposed: **Lane wins**
  (it is authority-of-record) and the forward-compile emits a validation warning on the mismatch; task-type
  becomes presentational where it disagrees. Alternative: treat the mismatch as a hard error the editor
  forbids at author time. **Needs your call** — it changes whether the editor blocks or warns.
- **O-2 — Keep or drop `owner` in editor/bridge `metaKeys`.** Conformance-safe either way (§4.2). Keeping it
  serves reverse-render laning symmetry; dropping it is a stronger "one carrier" guarantee but a wider code
  change. Recommend **keep** (reverse still writes `owner` for laning), but flag for your preference.
- **O-3 — `inception` authority.** With node-level `owner` gone, is `inception`'s human-decision authority
  fully carried by "gateway lives in the human lane" (structural), or should the standard additionally
  *require* an inception's go/no-go gateway to be human-laned (a MUST, machine-checkable)? The latter makes
  G-3 enforceable; recommend making it a MUST in the same v1.1.

---

## 6. Sign-off boundary (why this waits for Dimitri)

- Editing `docs/standards/aef-bpmn-mapping-v1.md` is a change to a **frozen** artifact → change-control gate.
- The 832-side authority for graduating a frozen standard is **the 832 operator (Dimitri)**, per T-175's
  source-of-truth model. AEF's operator ratifying the *framing* (offset 25) does not transfer that authority.
- This item also stacks with the Part II provisional items already awaiting Dimitri's ruling (inception
  marker shape, `tier` default, AC-seeding) — he may wish to rule on them together in one v1.1.

**On GO:** apply §3.1–§3.4 to the frozen standard, run `python3 tests/test_mapping_standard_conformance.py`
(expect green — §4.1), file the separate owner-from-lane build task (§4.2), resolve O-1..O-3, and complete
T-189. **Until then:** the standard is untouched and T-189 holds in partial-complete.

---

## Provenance (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`)

- **offset 20** — AEF relays IW-9 (authority triple-encoded), proposes one authority-of-record axis.
- **offset 24** — 832 BPMN-side read: agree; sharpen to Lane=who / workflow_type=kind / remove node `owner`
  override; flag as a v1.1 delta needing operator sign-off.
- **offset 25** — AEF operator ratifies the framing as sent.
- **offset 26** — 832 confirms + records the 832-side graduation-authority boundary (this task).
