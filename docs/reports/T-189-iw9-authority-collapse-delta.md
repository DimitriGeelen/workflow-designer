# IW-9 — v1.1 Mapping-Standard Delta: Collapse Triple-Encoded Authority

**Task:** T-189 · **Status:** DRAFT proposal — awaiting operator (Dimitri) sign-off · **Arc:** designer-authoring-surface
**Targets:** `docs/standards/aef-bpmn-mapping-v1.md` (FROZEN v1) **and** `docs/standards/aef-bpmn-forward-compile-v1.md` — a v1 → **v1.1** delta to **both** (the forward-compile spec's §8 already anticipates this)
**Origin:** AEF design-review finding IW-9 (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, offset 20); 832-side BPMN read (offset 24); **AEF operator RATIFIED the framing** (offset 25, 2026-07-11).

> **This document is a proposal, not a graduation.** Under 832 governance, editing the FROZEN v1 standard
> requires the standard's change-control (version bump + conformance-test update) **and Dimitri's sign-off**.
> AEF's operator ratifying the framing clears the *AEF* side only; it is not transferable to the 832 side.
> Nothing in `docs/standards/` has been edited to produce this. The delta below is written so that, on GO,
> graduation is a mechanical apply — every before→after is spelled out.

---

## 0. CURRENCY WARNING — read before §3 (added 2026-08-17, T-189)

**The delta below was last edited 2026-07-12 (`11e2826a`). Four further items have been
recorded against this task since, and NONE of them is in this document.** They live only in
`.tasks/active/T-189-*.md` under *"v1.1 items accumulated after the proposal was written
(2026-08-02)"*.

This matters because T-189's `[REVIEW]` acceptance criterion instructs the operator, in step
1, to *"read the drafted delta: `docs/reports/T-189-iw9-authority-collapse-delta.md`"*. That
instruction was written when this file was the whole delta. It no longer is. A sign-off given
on §3 as it stands would be a ruling on the 2026-07-12 proposal, not on the current one — and
nothing in the file said so until this section was added.

Not resolved here. Listing them is the whole of this change; **deciding them is the ruling
being asked for**, and folding an agent's answer into the delta the operator is about to
approve is how a proposal quietly becomes a decision.

| # | item | does it change §3's text? |
|---|---|---|
| 1 | **`AUTHORITY_OWNER` disagrees with AEF.** Ours maps `authority` → **agent**; AEF's T-2717 maps it → **no owner**. AEF measured the separating case (rail 375): flipping a `serviceTask` to `userTask` in a Framework lane yields owner **human** with no warning on their side, and **agent** plus `W-TYPE-LANE-MISMATCH` on ours. | **YES — potentially §3's collapse map.** This is a live disagreement with the peer on the exact axis IW-9 collapses. §3 currently states `authority→agent` as settled. |
| 2 | **`<bpmn:documentation>` is unemittable**, not merely unused: 0 occurrences across 175 `.bpmn`, and absent from the designer export, `yaml-to-bpmn.py` and `bpmn-to-yaml.py`. `aef:meta note` carries 100% of the explanatory load on both sides. Recommendation recorded in the task: carry BOTH with a stated precedence rather than migrate. | Adjacent — a carrier question, not an authority-axis question. Would extend the delta's scope, not contradict §3. |
| 3 | **Audience of the `note` field.** One field silently picks a reader and has picked the implementer. Admission test AEF has adopted: a newcomer note MUST NOT be derivable by truncating the implementer note. | Adjacent, same batch as (2). |
| 6 | **`authority: none` has no collapse map, and our own corpus contains a lane axis that is not the actor axis.** `AUTHORITIES` (`validate-workflow.py:62`) accepts five members; frozen §3 names four outcomes. `examples/aef-processes/context-memory.workflow.yaml` lanes by *memory type* (Working / Project / Episodic), giving 7 task nodes with no derivable owner. | **YES — this is a counter-example to the premise.** §2 asserts Lane = who-performs *by construction*; one shipped map in this repository says otherwise. |

*(The numbering is the task's own and is not contiguous — items 4 and 5 are referenced there
as belonging to earlier batches. Four items are recorded in that section; this table reports
what is verifiably there rather than smoothing the gap in the sequence.)*

**Two of the four bear on §2/§3 directly** — item 1 as a peer disagreement about a mapping
this document states as settled, item 6 as a shipped counter-example to the axiom §2 rests on.
The other two would widen the delta rather than change it.

**Why this was missed for five weeks.** T-189's Agent ACs are all ticked and all were true
when written: AC2 says the proposal *"specifies exact before→after changes"* — it did, on
2026-07-12. The AC is a claim about a document on a given day; the document then stopped
tracking the task. Nothing re-checks a ticked AC against a file that moved underneath it
(PL-142). This section is the cheap fix; the structural one — a check that a proposal
referenced by a `[REVIEW]` AC is not older than the task content it represents — is not
filed here and is not this task's to build.

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

- **Axis 1 — WHO performs (authority-of-record) = the Lane.** The concrete carrier is the lane's
  **`aef:laneMeta authority`** attribute, which is *4-valued* (`sovereignty | authority | initiative |
  external`) — not a bare human/agent split (see `aef-bpmn-forward-compile-v1.md` §2/§3.1). The task-YAML
  `owner` field is compiled **from the lane authority, always**, via the fixed collapse map:
  `sovereignty → owner:human`; `initiative → owner:agent`; `authority → owner:agent` (framework acts as an
  agent); `external → no task authored`. This subsumes IW-7's two-lane view and makes the lane the *single*
  who-performs carrier.
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

## 3B. Second carrier — the forward-compile spec (`aef-bpmn-forward-compile-v1.md`)

IW-9 authority is encoded in **two** standards, and its §8 states open rulings "graduate into a **v1.1 of
both standards**." The delta above (§3) is incomplete without the parallel edits here; graduating only the
mapping standard would leave the forward-compile spec asserting the opposite ("owner overrides lane") — the
exact cross-document drift this arc exists to prevent.

### 3B.1 §3.1 structural table — the "owner precedence" line

**BEFORE**
> **owner precedence:** a node-level `aef:meta owner` overrides its lane's default; absent → lane default (v1 §3).

**AFTER**
> **owner is the lane authority (IW-9, v1.1):** `owner` is derived from the member lane's `aef:laneMeta
> authority` via the collapse map (`sovereignty→human`, `initiative→agent`, `authority→agent`,
> `external→no task`). There is **no** node-level `aef:meta owner` override.

### 3B.2 §3.2 scalar table — the `owner` row

**BEFORE**

| `aef:meta` key | task-YAML field | note |
|---|---|---|
| `owner` | `owner` | overrides lane (§3.1) |

**AFTER**

| `aef:meta` key | task-YAML field | note |
|---|---|---|
| ~~`owner`~~ *(derived)* | `owner` | **derived from lane `authority` (§3.1); no node-level override** |

### 3B.3 §2 input contract — the relied-upon scalars

The bullet listing `aef:meta` governance scalars currently names `owner` among
`tier, agentType, owner, horizon, workflowType`. On graduation, `owner` moves out of the *author-supplied*
scalar list and into the *derived* column: the compiler MUST source `owner` from `aef:laneMeta authority`,
not from an `aef:meta owner` attribute. (The lanes bullet already names `aef:laneMeta authority=…` as "the
owner source" — v1.1 makes it the *sole* source.)

### 3B.4 §5.1 worked example

The worked example already derives owner purely from lanes (human=sovereignty→human, agent/framework lanes→
agent) with no node-level override in play, so it needs **no change** — it happens to already illustrate the
v1.1 rule. Worth a one-line note in the graduated doc confirming that.

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
3. **`aef-bpmn-forward-compile-v1.md`** — the second standard IW-9 touches (§3B). Same class of edit
   (owner-precedence line, owner scalar row, input-contract sourcing) + a version bump to match. Its §8
   already anticipates graduating "into a v1.1 of both standards."
4. **`tests/test_forward_fixtures.py`** — **already** asserts "owner via lanes (`aef:laneMeta`)" and requires
   lanes to be present (lines 186–191); it does **not** rely on a node-level `owner` override. The delta is
   precisely what this test already enforces → **green, no edit required.** (Verified: the test's governance
   contract is "tier + agentType at node level, owner-via-lanes.")
5. **No fixture regen** — `aef:uid` and node/edge identity are untouched; this is a semantics/wording delta,
   not a geometry or identity change.

Net: the *standards* delta is a small set of text edits across **two** documents + matching version bumps,
and is conformance-green as written on **both** test paths (`test_mapping_standard_conformance.py` and
`test_forward_fixtures.py`). The *implementation* of owner-from-lane (forward-compile reads lane authority,
ignores any node `owner` meta) is a separate, clearly-scoped build task — not part of this doc-delta.

---

## 5. Open questions requiring an operator ruling

These are genuine forks the delta should **not** silently resolve:

- **O-1 — Lane vs task-type tiebreak.** BPMN task-type also implies execution authority (userTask→human,
  service/scriptTask→agent). The lane's authority is 4-valued (`sovereignty/authority/initiative/external`),
  so the mismatch space is real: e.g. a `serviceTask` (implies agent) in a `sovereignty` lane (implies human),
  or a `userTask` in an `authority` (framework) lane. Which wins? Proposed: **lane `authority` wins** (it is
  authority-of-record) and the forward-compile emits a validation warning on the mismatch; task-type becomes
  presentational where it disagrees. Alternative: treat the mismatch as a hard error the editor forbids at
  author time. **Needs your call** — it changes whether the editor blocks or warns. Note the `authority`
  (framework) lane has no distinct task-YAML `owner` value (collapses to `agent`); if framework-vs-agent
  needs to survive into task-YAML, that is a *separate* field, not `owner` — flag if so.
  *AEF (Child-2 owner, rail offset 28) reads O-1 as: **lane-wins + WARN**, not hard error — "antifragile
  default: emit owner from the lane and log a conformance warning rather than refuse the whole diagram." AEF
  is implementing exactly this in its T-2531 forward-compiler. Aligns with the proposed direction.*
- **O-2 — Keep or drop `owner` in editor/bridge `metaKeys`.** Conformance-safe either way (§4.2). Keeping it
  serves reverse-render laning symmetry; dropping it is a stronger "one carrier" guarantee but a wider code
  change. Recommend **keep** (reverse still writes `owner` for laning), but flag for your preference.
  *AEF (offset 28): "doesn't affect forward-compile either way; no objection to your lean-keep."*
- **O-3 — `inception` authority.** With node-level `owner` gone, is `inception`'s human-decision authority
  fully carried by "gateway lives in the human lane" (structural), or should the standard additionally
  *require* an inception's go/no-go gateway to be human-laned (a MUST, machine-checkable)? The latter makes
  G-3 enforceable; recommend making it a MUST in the same v1.1.
  *AEF (offset 28) leans **YES**: "makes G-3 machine-checkable at compile time (compiler asserts the decision
  node is human-laned, fails fast on a malformed inception)." Flagged as your + Dimitri's call to make it MUST.*

**Peer status (rail offset 28):** AEF has **filed + started Child-2** as its T-2531 (forward-compiler, first
slice), built to this v1.1 collapse from day one — owner compiled from the lane only, node-level `owner` meta
ignored, `workflow_type` kept as the KIND axis. So a GO on this delta means **zero rework** on the AEF
compiler side; a NO-GO/refine is what AEF would need to hear before it hardens T-2531. All three O-reads above
are AEF *compiler-side input*, not operator rulings — the graduation decision remains Dimitri's.

---

## 6. Sign-off boundary (why this waits for Dimitri)

- Editing `docs/standards/aef-bpmn-mapping-v1.md` is a change to a **frozen** artifact → change-control gate.
- The 832-side authority for graduating a frozen standard is **the 832 operator (Dimitri)**, per T-175's
  source-of-truth model. AEF's operator ratifying the *framing* (offset 25) does not transfer that authority.
- This item also stacks with the Part II provisional items already awaiting Dimitri's ruling (inception
  marker shape, `tier` default, AC-seeding) — he may wish to rule on them together in one v1.1.

**On GO:** apply §3.1–§3.4 (mapping standard) **and** §3B.1–§3B.4 (forward-compile spec), bump both to v1.1,
run `python3 tests/test_mapping_standard_conformance.py` **and** `python3 tests/test_forward_fixtures.py`
(expect both green — §4.1/§4.4), file the separate owner-from-lane build task (§4.2), resolve O-1..O-3, and
complete T-189. **Until then:** both standards are untouched and T-189 holds in partial-complete.

---

## Provenance (rail `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`)

- **offset 20** — AEF relays IW-9 (authority triple-encoded), proposes one authority-of-record axis.
- **offset 24** — 832 BPMN-side read: agree; sharpen to Lane=who / workflow_type=kind / remove node `owner`
  override; flag as a v1.1 delta needing operator sign-off.
- **offset 25** — AEF operator ratifies the framing as sent.
- **offset 26** — 832 confirms + records the 832-side graduation-authority boundary (this task).
