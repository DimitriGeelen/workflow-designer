# T-811 Inception — Thirty authored corpus values still unreachable in the panel

**Date:** 2026-09-23 · **Arc:** arc-001 (Designer as AEF's authoring surface) ·
**Origin:** T-810 census residue · **Status:** recommendation written, decision is the operator's

Every figure below was produced by a command over the corpus on the date shown, not carried
forward from T-810's prose (PL-175: a name in a coverage list is a CLAIM; only a value that
varies is EVIDENCE).

---

## S-1 — Re-measure (answers A-3)

`tools/_t810-unreachable-values-census.py`, re-run 2026-09-23:

```
corpus: 24 document(s), 246 authored aef value(s)
reachable in panel: 204   UNREACHABLE: 30   unmapped node type: 12
```

**30, unchanged from 2026-09-22.** A-3 holds; the population is stable.

---

## S-2 — Read the 18 (answers IW-3)

The single highest-leverage question was whether the 18 `endpoint` values on
`exclusiveGateway` and `startEvent` are authored intent or corpus noise. If noise, the repair
is deletion and the count drops to 12.

**They are authored intent. All 18 values are unique — zero duplicates.** And they carry two
distinct semantics, neither of which is `endpoint`'s original "the thing this task calls out to":

**On `startEvent` (7) — the command that triggers the process:**

| document | value |
|---|---|
| release-pipeline | `fw release` |
| harvest-pipeline | `fw harvest` |
| inception-review | `fw task review T-XXX` |
| promotion-pipeline | `fw promote suggest` |
| review-emission | `fw review` |
| cross-host-dispatch | `fw dispatch send` |
| task-lifecycle | `agents/task-create/create-task.sh` |

**On `exclusiveGateway` (11) — a source citation for where the branch is implemented:**

| document · gateway | value |
|---|---|
| verification-gate · `frw_7_every` | `update-task.sh:1010-1026` |
| verification-gate · `frw_1_owner` | `update-task.sh:1406-1408 (fn 58-75)` |
| verification-gate · `frw_3_agent` | `update-task.sh:1412-1413 (fn 80-190)` |
| git-commit-flow · `agt_3_bypass` | `commit.sh:66 ($bypass == true)` |
| git-commit-flow · `frw_5_pre` | `hooks.sh:271-358 (pre-commit) + hooks.sh:55-88 (commit-msg)` |
| fabric-blast-radius · `frw_2_any` | `traverse.sh:162-165` |
| resume-status · `frw_4_handover` | `resume.sh:147` |

**Why this matters beyond T-811.** The gateway group is EWCR's traceability payload in
literal form — arc-002's headline mechanic is *"every step traceable to the evidence that
justified it and to the operator decision that authorised it."* A gateway annotated
`update-task.sh:1010-1026` **is** that link. The authoring surface currently cannot edit the
one field that carries arc-002's central claim.

**IW-3 disposition: answered, confidence 3 — authored intent, not noise. A-1 holds.**

A second-order finding, recorded not acted on: `endpoint` is **one attribute name carrying
three different semantics** (call-target on tasks, trigger on start events, implementation
citation on gateways). Whether to split it is a standard question — `docs/standards/aef-bpmn-mapping-v1.md`
Part I is frozen and not editable under agent control — and is raised as SQ-1 below.

---

## S-3 — Read the panel (answers IW-1 and IW-4)

Two mechanisms decide whether a value is editable:
`FIELD_META` (does the field have a definition?) and `AEF_FIELDS[nodeType]`
(is it offered on this node kind?), both in `src/aef-workflow-designer.html`.

| group | n | FIELD_META | in AEF_FIELDS for that type | class |
|---|---|---|---|---|
| `endpoint` on exclusiveGateway | 11 | **yes** | no | **mapping** |
| `endpoint` on startEvent | 7 | **yes** | no | **mapping** |
| `emits` on scriptTask | 5 | **yes** | no | **mapping** |
| `aggregation` on scriptTask | 2 | no | no | definition |
| `multiInstance` on scriptTask | 2 | no | no | definition |
| `multiInstance` on serviceTask | 1 | no | no | definition |
| `compensates` on scriptTask | 1 | no | no | definition |
| `timer` on startEvent | 1 | no (`timerSpec` exists) | no | **naming drift** |

**IW-1 disposition: answered, confidence 3 — two repairs, not one.**

**23 of 30 are mapping-class.** The field is already defined; only the per-node-kind
allow-list withholds it. The fix is three entries in `AEF_FIELDS`, which is exactly what
T-810 did for `decisionOutputs` and T-618 for `determinism`. The code comment already states
the governing principle verbatim: *"offer the field on exactly the types the corpus annotates."*

**7 of 30 are definition-class** and need a field definition designed, not a list edit.
One of those seven is not a missing field at all: the corpus writes `<aef:timer>` while the
panel defines `timerSpec` on node type `eventTimer`. That is a **naming drift between corpus
and panel**, and it should be resolved as a drift before anything is built for it.

**IW-4 disposition: answered, confidence 3 — the generic affordance already exists, and the
problem statement was overstated.** `src/aef-workflow-designer.html:6310` builds a
`hiddenKeys` set and renders an **"Other extensions · N"** section carrying every scalar the
panel does not offer, with the text *"Carried by this node in the source document. Shown
read-only — these keys are either derived from the diagram or not authored here. They are not
lost."*

So the 30 values are **not invisible. They are visible and read-only.** "Unreachable" in the
census means "not offered as an editable field", which is a materially smaller defect than the
task description implies. This is recorded as a correction to this task's own framing.

---

## S-4 — F-11 vs the census (answers IW-2)

Value review F-11 enumerated the fields it believed were authored; the general census found
three groups F-11 never listed. The mechanism is the one already named as **PL-288 — a
chosen-set assertion cannot find what you forgot to choose.** F-11 asserted over a
hand-enumerated field list; the census asserts over the corpus population. Any finding that
rests on F-11's list inherits the same blind spot.

**IW-2 disposition: answered, confidence 2.** The generalisable rule — prefer a census over
the population to a review over an enumerated list — is the durable output here, and it is
larger than T-811. Confidence is 2 rather than 3 because the *date* at which each of the
three groups entered the corpus was not established, and that would distinguish
"F-11 was wrong then" from "the corpus moved after F-11".

---

## S-5 — Carrier shape (two wrong answers before the right one)

§S-3 concluded "23 of 30 are mapping-class, fixable with three `AEF_FIELDS` entries" and
recommended GO. Two further measurements were needed, and the first of them was also wrong.
Both are recorded, because the shape of the error is the point.

**Wrong answer 1 — "6 are empty."** Testing whether each element carried non-whitespace text
or attributes produced 24 content-bearing and 6 empty (`emits` ×5, `compensates` ×1). That
became a filed task (T-836) on the claim that the census overstated the gap by 6 and therefore
misinformed (PL-332).

**It was false.** `<aef:emits>` is not empty — it carries child elements:

```xml
<aef:emits>
  <aef:emit value="pass"/>
  <aef:emit value="warn"/>
</aef:emits>
```

and `<aef:compensates>` carries `<aef:compensate ref="n_apply_settings"/>`. The test looked
for two carriers and the corpus uses three. **Measured correctly: 30 of 30 carry content, 0
are empty.** The census's headline `30` was right the whole time.

This error was committed *inside the task that documents this exact failure shape*, minutes
after writing §S-4's note that a chosen-set assertion cannot find what you forgot to choose
(PL-288). The chosen set here was "text or attributes". Naming a pattern does not confer
immunity to it.

**Right answer — carrier shape.** The useful question is not *whether* there is content (the
answer is always yes, so it carries no information) but *what shape* it is, because the shape
decides whether a repair is a list edit or a field design:

| group | n | carrier | what a repair must hold |
|---|---|---|---|
| `endpoint` on exclusiveGateway | 11 | **text** | a text field can hold it |
| `endpoint` on startEvent | 7 | **text** | a text field can hold it |
| `emits` on scriptTask | 5 | **children** | repeated `<aef:emit value=…>` |
| `compensates` on scriptTask | 1 | **children** | repeated `<aef:compensate ref=…>` |
| `aggregation` on scriptTask | 2 | **attrs** | `over=` + `reduce=` |
| `multiInstance` on scriptTask | 2 | **attrs** | `over=` |
| `multiInstance` on serviceTask | 1 | **attrs** | `over=` |
| `timer` on startEvent | 1 | **attrs** | `kind=` + `cycle=` + `anchor=` |

**18 text · 6 attrs · 6 children · 0 empty.**

**This kills §S-3's GO more decisively than the empty theory did.** §S-3 proposed adding
`emits` to `AEF_FIELDS['scriptTask']` because `emits` is already in `FIELD_META`. It is — as
**`{ label: 'Emits', hint: 'event name(s)', textarea: false }`, a plain single-line text
field.** Wiring that over a children carrier would put a text box on top of repeated
sub-elements: at best it misrepresents the value, and on save it plausibly destroys it. The
field definition exists and is *the wrong shape*, which is worse than absent, because absence
is visible and a wrong-shaped definition looks like a working one.

So of the 30: **18 are text carriers and all 18 are `endpoint`**, the overloaded field that
SQ-1 governs; the other **12 are structured** and need field design. **Not one of the thirty
is the clean list edit §S-3 proposed.**

**On the residue panel:** `hiddenKeys` at `src/aef-workflow-designer.html:6310` filters to
scalars (`typeof v !== 'object'`), so only the 18 text carriers reach "Other extensions". The
12 structured values are genuinely invisible — §S-3's correction to this task's framing
applies to the 18, not to all 30.

---

## Recommendation

**DEFER stands. The GO drafted at §S-3 is withdrawn, and the instrument finding that replaced
it (T-836, "the census overstates by 6") is withdrawn too — it was false.**

The task's pre-existing DEFER rationale was half wrong and half load-bearing:

- **Wrong:** *"endpoint on exclusiveGateway and startEvent may be corpus mistakes."* They are
  not. §S-2: 18 unique, hand-authored, coherent values.
- **Right, and now doubly so:** *"determinism was safe because it is semantically
  type-neutral, and endpoint is not."* §S-2 confirms the overload directly (call-target /
  trigger / implementation citation).

And §S-5 adds a second, independent reason the panel work is not bounded: **12 of the 30 are
structured carriers**, and one of them already has a text-shaped `FIELD_META` entry that would
misrepresent it. Shipping the field ships its label and its widget — `FIELD_META.endpoint`'s
hint `'fw … | agent prompt | watchtower view'` is wrong on a gateway holding
`update-task.sh:1010-1026`, and `FIELD_META.emits`'s single-line text input is wrong on a
repeated-child payload. Editable under a wrong label, or in a wrong widget, is worse than
read-only — it invites the author to write something the carrier cannot hold.

**What the DEFER waits on has changed, and that is this inception's real output.** Before:
*"are these corpus mistakes?"* — answered, no. Now: **SQ-1**, does the dialect sanction the
three-way `endpoint` overload; and **SQ-4**, what shape should the structured twelve take.

**Against the Go/No-Go criteria:** the fix path is not bounded — every text carrier is
`endpoint` (dialect ruling not ours), and the remaining twelve need field design. Both stated
NO-GO conditions fire.

**What IS delivered and needs no ruling:** the census now reports carrier shape rather than a
flat count (`UNREACHABLE_CARRIER_TEXT/ATTRS/CHILDREN`, `UNREACHABLE_EMPTY`), with 8 controls
including a leg that fails if `emits` is ever classified EMPTY again. That is T-836, and its
value is the opposite of what it was filed for: not "the number is wrong by 6" but "the number
was right and hid three different repair classes behind one integer."

---

## Sovereign questions raised (surfaced, not resolved)

**SQ-1 — Does the dialect sanction `endpoint` carrying three semantics, and should the panel
label it per node kind?** 18 of 30 values ride on this. 999-AEF is the counterparty;
`docs/standards/aef-bpmn-mapping-v1.md` Part I is frozen and not editable under agent control.

**SQ-2 — Is read-only sufficient for the 18 text carriers?** They already render under "Other
extensions". A UX judgement, outside reviewer delegation under PD-302.

**SQ-3 — `timer` vs `timerSpec`.** Corpus writes `<aef:timer kind="cron" cycle="daily"
anchor="G-053">` on a `startEvent`; the panel defines `timerSpec` on node type `eventTimer`.
Corpus/panel naming drift, resolve as a drift before building for it.

**SQ-4 — What shape do the structured twelve take in the panel?** Six attribute carriers and
six child carriers. `FIELD_META` has no vocabulary for either, and `emits` currently has a
text-shaped entry that is actively wrong for its payload. Field design, not a list edit.

---

## Note on this report's own method

This report reached three successive answers: a structural GO (§S-3), an "empty elements"
instrument finding (§S-5 first pass), and the carrier-shape result that survived. The first
two were each internally consistent and each wrong for the same reason — reasoning forward
from a mechanism without measuring the population it acts on. Each was caught by one command
that cost under a minute. Recorded rather than silently corrected: the failure shape is the
one this whole task exists to document, and it was committed twice while documenting it.
