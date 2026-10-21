# T-671 Human AC#1 — Arc-0 component set scope (reviewer evidence)

Revision reviewed: 4f4db0b5ca4e9beda8cbcf87ea9c18c357217142 (read via `git show 4f4db0b5:<path>`).

## What I checked
1. `docs/research/executable-workflow/arc-0-component-set.md` and `arc-0-component-set.txt` (28 paths).
2. Roadmap `docs/research/executable-workflow/roadmap-5be23719.md` §2.1 (Arc 0 row), §4 Arc 0 Candidate tasks, §6 fence table.
3. All 28 manifest paths exist at the revision (`git cat-file -e`, no MISSING); prose list and .txt agree (1 + 3 + 24 = 28, same names).
4. Non-probe tests/tools in the tree, looked for in-scope files that were left out.

## Findings
- **Matches the roadmap.** §2.1 Designer Arc-0 column: "Inventory visual/mapping schema, stable IDs, import/export and round-trip constraints". Joint handoff: "canonical IDs, diagnostic shape, worked procedure fixture". §4 candidate task 1 ("Register/enrich the relevant Component Fabric baseline and validate edges") is the task this set is for. The set's rule (§1) quotes the Designer column exactly.
- **What is in is correct.** The editor `src/aef-workflow-designer.html` (canvas, aef vocabulary, IDs, round trip), the bridge `tools/yaml-to-bpmn.py`, the validator `tools/validate-workflow.py` (diagnostic shape), `tools/bpmn-cli.py` (canonical IDs), and 24 contract and round-trip suites (export contract, namespace, meta/field parity, roundtrip serialization, typed events, two-lane joint contract, fixture pins, mapping-standard conformance and so on). Each fits the rule.
- **The exclusion is correct.** No runtime schemas, registries, ledgers or refusal matrices are in the set. These are AEF-owned under §2.1, and §1 states the exclusion. Leaving out `tools/_tNNN-*` probes is also justified.
- **Gap: in-scope suites left out with no stated reason.** These non-probe tests pin import/export/round-trip or fixture constraints under the doc's own rule, but they are not in the set. Neither the doc nor the task file mentions them (grep count 0 in both):
  - `tests/test_t315_lane_grow_on_import.py`: an import constraint (the lane band grows on import).
  - `tests/test_harness_emitter_fidelity.py`: export fidelity (the shapes the bridge TYPE_MAP and designer TYPE_TAG emit).
  - `tests/test_harness_cross_form_agreement.py`: bridge → BPMN → both validators give the same verdict (bridge plus diagnostic shape).
  - `tests/test_emitted_comment_claims.py`: what exported .bpmn bytes may claim.
  - `tests/test_t314_fixture_repin.py`: the shared producer-contract fixtures (inception-gonogo, two-lane-joint) stay zero-semantic. This is a joint-handoff fixture surface.
  - Possibly also `tests/test_t258_annotation_seam.py` (the uid handshake with AEF, i.e. canonical IDs over the seam) and `tests/test_t1159_yaml_element_authority.py` (YAML/XML form parity).
  None of these is a runtime schema, so each one is either a wrong omission or an exclusion that needs a sentence of justification.

## Verdict: amber
The scope is right in principle and the AEF/Designer boundary is drawn correctly. The member list is not shown to be complete against its own rule. At least five files that fit the rule are absent with no stated reason.
