# T-925 — should `yaml-to-bpmn.py` emit `<aef:workflowMeta>`? The seam question, priced

**Task:** T-925 (slice 1) · **Date:** 2026-09-30 · **Decision owner:** operator
**Status:** awaiting ruling. No emitter change and no corpus bytes moved by this slice.

---

## The ruling being asked for

`tools/yaml-to-bpmn.py` reads `workflowMeta` at `:141` and uses it **only** to derive
`wid`/`process_id`. It emits no `<aef:workflowMeta>` element, so **all ten** document-level
attributes are destroyed on every document it compiles:

> `id, uuid, version, schemaVersion, title, description, source, tier_default, pageWidth, kind`

T-925 deferred the fix on one explicit ground, and asked for that ground to be settled first:

> *"whether the bridge SHOULD emit workflowMeta is a seam question (**the corpus is pinned by
> AEF and 24/24 rendered maps are bridge-produced, so emitting it changes bytes AEF pins
> against**) — that is the first thing this task must settle, before any code."*

**That premise is false.** Measured below. It is the entire reason this task has sat at
`captured`, and it does not hold.

---

## Measurement 1 — the bridge produced ONE of the 25 served renders, not 24

`grep -rl 'by tools/yaml-to-bpmn.py'` across `examples/` and `build/` returns exactly two
files, and they are the same document:

```
examples/app-processes/rendered/customer-refund.bpmn     (tracked)
build/gallery/rendered/customer-refund.bpmn              (untracked build copy)
```

The 24 AEF-process renders carry no such header. They also carry `<aef:workflowMeta>`, which
the bridge provably cannot emit (`grep -c 'aef:workflowMeta' tools/yaml-to-bpmn.py` → **0**).
Both facts cannot be true of one producer.

## Measurement 2 — they are from a different emitter entirely

Re-rendered `examples/aef-processes/task-lifecycle.workflow.yaml` through the bridge into a
scratch path and diffed against the committed render. **15,831 bytes committed vs 14,503
re-rendered, and structurally different documents:**

| | committed AEF render | bridge output |
|---|---|---|
| namespaces | `bpmn`, **`bpmndi`, `dc`, `di`**, `aef` | `bpmn`, `aef`, `xsi` — **no DI** |
| top structure | `collaboration` + `participant` + `process` | bare `process` |
| definitions id | `Definitions_task-lifecycle` | *(none)* |
| targetNamespace | `https://aef.anchorpoint.dev/workflows` | *(none)* |
| process id | `Process_task-lifecycle` | **`Pool_task_lifecycle`** |
| laneSet id | `LaneSet_1` | `LaneSet_task-lifecycle` |
| `aef:workflowMeta` | **present, with `uuid`** | **absent** |

The committed AEF corpus is the **designer's own exporter** output — it emits diagram
interchange, a collaboration/participant pair, and workflowMeta. The bridge is a separate,
simpler emitter.

Incidentally this explains the T-301 divergence completely: the bridge emits
`<bpmn:process id="Pool_<underscored-name>">`, so customer-refund's process id is
`Pool_customer_refund`, and with workflowMeta erased the designer's derivation chain
(`authored || sanitize(procId) || sanitize(procName)`) falls to `pool_customer_refund`
against a card stem of `customer-refund`.

## Measurement 3 — AEF pins nothing that would move

`customer-refund` appears in **no** pin manifest, `MANIFEST*`, or `.json` in this repository.
The `source_bpmn_sha` pinning discussed in T-357/T-423 concerns the 24 AEF-process maps — the
ones the bridge does not produce and this change does not touch.

## Measurement 4 — the real blast radius is tests, and it is a gain

The bridge has **10 test consumers**:

```
test_bridge_aef_passthrough        test_bridge_seam_roundtrip
test_editor_bridge_field_coverage  test_editor_bridge_meta_parity
test_editor_bridge_structured_parity
test_editor_namespace_consistency  test_finding_anchorability
test_harness_cross_form_agreement  test_harness_emitter_fidelity
test_xml_node_type_vocab
```

- **No golden-byte or exact-file comparison** in any of them.
- **None asserts `workflowMeta` absence as correct.** Three mention it: two only in fixture
  YAML or comments; the third, `test_harness_cross_form_agreement.py`, **documents this hole
  as a KNOWN disagreement citing T-925 by name** (`:170-177`). Fixing the bridge makes that
  entry *retireable* — the opposite of a breakage.

## The precedent that settles the principle

`test_editor_bridge_meta_parity.py`'s docstring describes **T-060**, the same bug one level
down:

> *"the editor writes a fixed set of scalar keys into `<aef:meta>` … The bridge emits
> `<aef:meta>` from its own separate `META_KEYS` whitelist. Because the editor read side is
> generic, no editor test could notice that the bridge's whitelist was missing
> `agentType`/`triggeredBy`/`emits` — a YAML carrying those keys simply lost them on
> YAML→bridge→BPMN, with no failing test anywhere."*

T-060 ruled that a bridge losing authored keys is a defect and fixed it for **node-level**
meta, and added a standing parity guard. T-925 is the identical defect for **document-level**
meta, still unfixed. The principle is not open; only this instance is.

---

## Why it matters beyond one file

`test_harness_cross_form_agreement.py` compares the YAML and XML validator forms by driving
YAML fixtures **through this bridge**. So no document-level rule can ever be compared. Its
own docstring is blunt about what that means:

> *the bridged document is clean because the carrier was **ERASED**, not because the value
> became legal … Inferring BRIDGE_REPAIRED from "XML said nothing" is how a real hole gets
> absorbed as a repair.*

A document-level rule therefore cannot fail on a bridged document **for any input**. That is
a false-green generator inside the comparison harness, and it is the reason to fix the bridge
rather than the one corpus file.

## Scored against the project's drivers

`yaml-to-bpmn.py` is the **compile** step, which is F1's own level-3 vocabulary
(`compile`, `forward compile`, `executable workflow`), and `examples/app-processes/*` is a
named F1 level-3 path. F1 is the yardstick driver at weight 9.

| driver | w | score | why |
|---|---:|---:|---|
| D1 Antifragility | 9 | 5 | removes a defect class and a false-green from the comparison harness |
| D2 Reliability | 7 | 5 | ten attributes vanish today with no error anywhere |
| D3 Usability | 5 | 4 | authored metadata survives compilation |
| D4 Portability | 3 | 5 | the `.bpmn` carries its own identity, readable standalone |
| F-RECALL | 6 | 3 | durable fix plus this brief |
| F2 Fabric | 6 | 0 | no topology work |
| F4 Routing | 9 | 3 | a corpus-wide emitter rule, not one map's content |
| F3 AEF Seam | 9 | 4 | seam artifact; divergence now detected mechanically (T-951) |
| F1 SDLC | 9 | 4 | repairs the compile stage of the workflow-to-app chain |
| **weighted** | **63** | **232 / 315 = 0.74** | |

---

## Options

**A — Emit `<aef:workflowMeta>` from the bridge (recommended).**
Changes bytes on 1 tracked file and 1 build copy. Pins: none affected. Tests: no expected
breakage; one KNOWN-disagreement entry becomes retireable. Restores all ten attributes and
closes the T-301 divergence at its cause rather than recording it. Follows the T-060
precedent.

**B — Emit only `id`, leave the other nine.**
Smaller diff, closes T-301's symptom, and leaves nine attributes still silently destroyed
plus the cross-form hole intact. Mitigation, not prevention (G-019).

**C — Rule that the bridge is not required to round-trip document metadata.**
Legitimate if the bridge is deliberately a lossy convenience compiler. Then the T-301
divergence is expected behaviour and the baseline entry should say *that* — and
`test_harness_cross_form_agreement.py` must keep a permanent known-disagreement for every
document-level rule, which should be recorded as an accepted limitation rather than a bug
waiting to be fixed.

**What this slice deliberately did not do:** touch the emitter, or move a single corpus byte.
The ruling is the operator's; slice 2 is the code.
