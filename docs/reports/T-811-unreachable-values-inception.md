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

## S-5 — Content vs. empty (the check that overturned this report's first recommendation)

§S-3 above concluded "23 of 30 are mapping-class, fixable with three `AEF_FIELDS` entries",
and recommended GO on that. Before writing it up I checked whether the values actually carry
content. **They do not all carry content, and the recommendation does not survive the check.**

| group | n | carries | |
|---|---|---|---|
| `endpoint` on exclusiveGateway | 11 | text, all unique | content |
| `endpoint` on startEvent | 7 | text, all unique | content |
| `aggregation` on scriptTask | 2 | **attributes** — `over="FINDINGS[]" reduce="severity-max"` | content, structured |
| `multiInstance` on scriptTask | 2 | **attributes** — `over="${changed_files}"` | content, structured |
| `multiInstance` on serviceTask | 1 | **attributes** | content, structured |
| `timer` on startEvent | 1 | **attributes** — `kind="cron" cycle="daily" anchor="G-053"` | content, structured |
| `emits` on scriptTask | 5 | nothing — `<aef:emits/>` | **EMPTY** |
| `compensates` on scriptTask | 1 | nothing | **EMPTY** |

**24 carry content. 6 are empty elements.**

Three consequences, each of which changes the answer:

1. **The `emits` group is empty, so it cannot be part of a fix.** Adding `emits` to
   `AEF_FIELDS['scriptTask']` would offer an editable field for five values that do not
   exist. Corroborating: `emits` on `endEvent` — the one type where the panel *does* offer
   it — occurs **zero** times in the corpus. The field is offered where nothing uses it and
   withheld where five empty tags sit.

2. **The content-bearing mapping-class population is therefore 18, not 23 — and all 18 are
   `endpoint`.** That is precisely the semantically overloaded field. There is no subset of
   this work that avoids SQ-1 by being scoped smaller; the scoping trick §S-3 relied on does
   not exist.

3. **The four structured groups are invisible even to the residue panel.** `hiddenKeys` at
   `src/aef-workflow-designer.html:6310` filters to scalars (`typeof v !== 'object'`), so
   attribute-bearing elements never reach "Other extensions". For these six values the
   original "unreachable" framing is exactly right — §S-3's correction applies only to the
   18 scalar `endpoint` values.

**Instrument finding (independent of the decision).** The census counts empty elements as
authored values, so its headline figure overstates the reachable-content gap by 6 (30 vs 24).
A probe that reports absent content as present content does not merely stop informing, it
**misinforms** (PL-332). This is a cheap, bounded fix to `tools/_t810-unreachable-values-census.py`
and it is independent of every question below.

---

## Recommendation

**DEFER stands. My own GO, written at §S-3, is withdrawn — S-5 disproved it.**

The task's pre-existing DEFER rationale was half right and half wrong, and the half it got
right is the load-bearing half:

- **Wrong:** *"endpoint on exclusiveGateway and startEvent may be corpus mistakes."* They are
  not. §S-2 shows 18 unique, hand-authored, semantically coherent values.
- **Right:** *"that judgement touches the frozen mapping standard where 999-AEF is the
  counterparty … determinism was safe because it is semantically type-neutral, and endpoint
  is not."* §S-2 **confirms** the non-neutrality directly: `endpoint` means call-target on a
  task, trigger command on a start event, and implementation citation on a gateway.

Shipping an editable field would ship its label and hint too. `FIELD_META.endpoint` reads
`label: 'Endpoint', hint: 'fw … | agent prompt | watchtower view'`. On
`verification-gate · frw_7_every`, whose value is `update-task.sh:1010-1026`, that label and
that hint are both wrong. Making the value editable under a misdescribing label is not an
improvement on read-only — it is a worse state, because it invites the author to write the
wrong kind of thing there.

**What the DEFER is now waiting on has changed, and that is this inception's real output.**
Before: *"are these corpus mistakes?"* — answered, no. Now: **SQ-1**, below — a sharper,
answerable question for the counterparty.

**One thing is recommended for immediate action and needs no ruling:** fix the census to
separate content-bearing from empty elements. It is an instrument correction, touches no
standard, no seam and no panel, and until it lands every future reading of this population
starts from a number that is wrong by 6.

**Against the Go/No-Go criteria as written:** the fix path is *not* bounded — every
content-bearing mapping-class value is `endpoint`, and `endpoint`'s repair requires a dialect
ruling this project does not own. That meets the stated NO-GO test ("requires fundamental
redesign or unbounded scope") for the panel work, while the census fix is a separate,
bounded, non-gated item.

---

## Sovereign questions raised (surfaced, not resolved)

**SQ-1 — Does the dialect sanction `endpoint` carrying three semantics, and should the panel
label it per node kind?** The corpus uses it as call-target (tasks), trigger command (start
events, 7) and implementation citation (gateways, 11). Either the dialect blesses the
overload and the panel needs per-node-kind labels and hints, or the field splits and the
corpus migrates. **999-AEF is the counterparty; `docs/standards/aef-bpmn-mapping-v1.md` Part I
is frozen and not editable under agent control.** Not an agent's call, and not answerable from
this corpus alone.

**SQ-2 — Is read-only sufficient for the 18 scalars?** They already render under "Other
extensions". If read-only visibility is adequate, the panel work may not be worth its
mandatory visual-verification cost even after SQ-1 resolves. A UX judgement, explicitly
outside reviewer delegation under PD-302.

**SQ-3 — `timer` vs `timerSpec`.** The corpus writes `<aef:timer kind="cron" cycle="daily"
anchor="G-053">` on a `startEvent`; the panel defines `timerSpec` on node type `eventTimer`.
Corpus-vs-panel naming drift that should be resolved as a drift before any field is built
for it.

---

## Note on this report's own method

§S-3's recommendation was written from a structural read of the panel and was internally
consistent. It was wrong because it never asked whether the values it proposed to expose
contained anything. The check that caught it cost one command. Recorded here rather than
silently corrected, because the failure shape — reasoning forward from mechanism without
measuring the population it acts on — is the one this whole task exists to document in F-11.
