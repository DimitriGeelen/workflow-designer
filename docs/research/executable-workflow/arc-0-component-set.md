# Arc-0 component set — what the Component Fabric fence ranges over

**Task:** T-671 · **Arc:** arc-002 `ewcr-governed-delivery` · **Date:** 2026-09-03

Roadmap §6 makes *"Component Fabric non-empty, enriched, validated"* a fence required
**before implementation decomposition**, with evidence owner "Arc 0 task owner". This
document defines the population that fence ranges over, and defends the choice.

The machine-readable manifest is [`arc-0-component-set.txt`](arc-0-component-set.txt).
This prose and that file must agree; a verification leg on T-671 asserts they do.

---

## 1. Why this is a scope and not the whole tree

The fence's own objective text is *"sufficient topology to decompose code **safely**"*,
and the Arc-0 exit gate reads *"topology is non-empty and validated"*. Neither says
"every file". A scope is therefore required, and choosing one is part of the work.

The repository's watch set is **358 files**. Of those, **256 are `tools/_tNNN-*` task
probes** — one-off instruments written to answer a single task's question and never
called again. Carding those would move `registered` from 28% toward 100% without
adding one edge of decomposition-relevant topology. That is optimising the metric
instead of clearing the fence, and the fence would still not be cleared, because the
thing it protects — knowing what breaks when you change the mapping surface — would be
no better known than before.

**The rule applied:** a file is in the Arc-0 set if it *implements or pins* the
Designer-side Arc-0 ownership row in roadmap §2.1 —

> "Inventory visual/mapping schema, stable IDs, import/export and round-trip
> constraints"

— plus the §2.1 joint-handoff surface ("canonical IDs, diagnostic shape, and worked
procedure fixture"). Runtime schemas, registries, ledgers and refusal matrices are
**AEF-owned** and deliberately excluded; that is the ownership boundary, not a gap.

## 2. The set — 28 files

**The product (1)**

| Path | Role |
|---|---|
| `src/aef-workflow-designer.html` | The authoring canvas, the `aef` extension vocabulary, stable element IDs, and the import/export round-trip itself |

**Mapping / export / diagnostic tooling (3)**

| Path | Role |
|---|---|
| `tools/yaml-to-bpmn.py` | The YAML→BPMN render bridge |
| `tools/validate-workflow.py` | The validator — the diagnostic shape named in the §2.1 joint handoff |
| `tools/bpmn-cli.py` | Headless off-page connector operations; canonical-ID surface |

**Contract and round-trip suites (24)**

`tests/run-bridge-tests.sh`, `tests/run-validator-tests.sh`,
`tests/test_bridge_aef_passthrough.py`, `tests/test_bridge_seam_roundtrip.py`,
`tests/test_corpus_fixture_pins.py`, `tests/test_designer_export_contract.py`,
`tests/test_editor_bridge_field_coverage.py`, `tests/test_editor_bridge_meta_parity.py`,
`tests/test_editor_bridge_structured_parity.py`,
`tests/test_editor_extension_shape_consistency.py`,
`tests/test_editor_namespace_consistency.py`, `tests/test_finding_anchorability.py`,
`tests/test_forward_fixtures.py`, `tests/test_mapping_standard_conformance.py`,
`tests/test_roundtrip_serialization.py`, `tests/test_rule_dialect_axis.py`,
`tests/test_rule_form_parity.py`, `tests/test_t259_eventdef_preservation.py`,
`tests/test_t311_doc_comment_roundtrip.py`, `tests/test_two_lane_joint_contract.py`,
`tests/test_typed_event_fixture_contract.py`, `tests/test_typed_events.py`,
`tests/test_validate_iw9.py`, `tests/test_xml_node_type_vocab.py`

## 3. What the fence found

Before this task, measured rather than assumed:

| | Count |
|---|---|
| Arc-0 members with a component card | 6 of 28 |
| …of those, cards that were **stubs** (TODO purpose) | **6 of 6** |
| …of those, cards with **no edges at all** | 3 of 6 |
| Arc-0 members with a *complete* card | **0 of 28** |

Two findings worth stating plainly:

1. **`src/aef-workflow-designer.html` had no component card.** The ~10k-line file this
   entire arc is about — the one with 112 inbound references — was absent from the
   topology the fence is supposed to guarantee.
2. **`registered` was counting stubs.** All six pre-existing cards carried
   `purpose: "TODO: describe what this component does"`. A count of cards is not a
   measure of topology, which is exactly why the fence has three words and not one.

## 4. The denominator, and why ours is honest

AEF refused Arc-0 exit clause 1 partly on our fabric coverage, and separately their own
clause-1 numbers turned on a denominator defect: **749 of their 1134 cards point outside
any watch pattern (66%)**, so their drift check ranged over a silently shrinking
population. `tools/_t623-fabric-denominator-scope-probe.py` asserts ours does not have
that defect and is re-run as a T-671 verification leg:

```
cards outside watch set .... 3  (2.9%)   [all three documented fixtures]
arithmetic closes: 358 watched - 99 carded = 259 unregistered
```

Every one of the 28 members is inside the watch set, so an absent card for any of them
would be **reported**, never silently out of scope. That property is asserted by the
fence's VALIDATED check, not left to inspection.

Our coverage number is **low, not blind**. Those are different criticisms and only the
second is a defect; the first is accepted and is what §5 is about.

## 5. Scoped pass — what this does NOT clear

The repo-wide audit warnings persist after this work and are **expected to**:

```
[WARN] Fabric: 102 registered, 259 unregistered (of 358 watched — 28% covered)
[WARN] Fabric: 46/102 cards have no edges
```

This is a **scoped pass over the Arc-0 set**, not a cleared warning. The whole-tree
figure moved 22%→28% as a side effect of carding the set; that movement is not the
deliverable and should not be cited as one. Reporting a scoped pass as a cleared
warning would be precisely the false green this fence exists to prevent.

## 6. How the topology was built

Edges are **derived, not asserted** — `tools/_t671-arc0-edge-derive.py` extracts them
from each referring file's own non-comment bytes, so every edge on every card traces to
a line of source. Three properties were established the hard way:

- **Mention is not invocation.** `tests/run-bridge-tests.sh` names 156 tool paths, many
  in comments pointing at sibling probes. `src/aef-workflow-designer.html` named its own
  generator and its own test in comments — one of them backwards in direction. Comment
  stripping removed ~70 candidate edges that would have been false records.
- **The stripper must follow the language.** Stripping only `#` was correct for `.py`
  and `.sh` and silently inert on `.html`/`.mjs` — so the false edges survived exactly
  where the fix did not reach.
- **Ambiguity, not the slash, was the real objection to basenames.**
  `_bpmn-claim-cli-verify.py` invokes the CLI as `os.path.join(HERE, 'bpmn-cli.py')`.
  Refusing all basenames missed that real edge; refusing only *ambiguous* ones (a
  basename more than one tracked path ends in) keeps the guarantee and finds the edge.

The fence itself (`tools/_t671-arc0-fabric-fence.py`) has had all three of its red arms
driven against a throwaway fixture via `T671_SET_FILE` / `T671_CARD_DIR` — a guard that
has only ever been green is a hand-maintained claim until something has made it fail
(PL-308). Doing so found a false green in the fence: with no card present at all,
`ENRICHED` reported PASS, because it ranged over the cards that existed and an empty
population satisfies "all of them are enriched". A missing card now fails ENRICHED too.

## 7. What this does not decide

This fence is **one input to Arc-0 exit clause 1**, not the clause itself. Clause
ratification is an operator decision recorded in `arc-0-exit-clauses.yaml`, where all
three clauses remain `definition_ratified: false`. Nothing in this document changes
that, and a green fence is not a ratified clause.
