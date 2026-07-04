# T-068 — Inception: constituents/subProcess construct for collapsed nodes

**Status:** exploration NOT started — this artifact frames the question (C-001: artifact before research).
**One question:** should the schema grow a first-class way to declare a node's constituents — and if so, as (a) a `constituents:` list vocabulary, (b) a real `subProcess` node type, or (c) neither (keep the `aef.x-*` workaround)?
**Decision owner:** human (go/no-go is sovereignty-gated).

## Problem statement

Workflow maps routinely collapse several real steps/gates into one node for legibility. The collapse is a faithful *modelling decision*, but the artifact cannot record it: nothing on the collapsed node says it is a composite, nor what it is composed of. Readers, validators, and downstream tooling (blast-radius, audits, episodic mining) see one opaque node where the ground truth has 4–8. The standing workaround is ad-hoc `aef.x-*` extension keys — invisible to the validator, un-greppable by vocabulary, and different per map.

## Evidence (why now)

**FC-11 — collapsed node cannot declare constituents. Four occurrences; rule-of-three EXCEEDED:**

| Map | Node | Workaround | Source |
|---|---|---|---|
| verification-gate | `g_gates` (6 gates, 3 policy families) | header comment only | T-056 §FC-11 |
| git-commit-flow | pre-commit checks | `aef.x-checks` | T-064 §FC-11 |
| resume-status | synthesis sources | `aef.x-sources` | T-066 §FC-11 (3rd, "if a third lands, first-class warranted") |
| session-capture | `n_capture` (4 capture actions) | `aef.x-captures` | T-067 §FC-11 (4th, "graduated from nice to warranted") |

**FC-15 — no scope construct (fabric-blast-radius, T-065):** iteration bodies are unboundable (nothing says where a `multiInstance` body ends); nested loops had to be collapsed into `decisionInput`; recursive traversal is inexpressible and was deliberately omitted (`x-seeAlso`) rather than faked. FC-15 likely shares one fix with FC-11 (T-067: "FC-15 and FC-11 likely share one fix" — a subProcess/scope subsumes a constituents list).

**Adjacent but separable:** FC-16 (missing parallelism) — explicitly OUT of this inception.

## Options to explore

- **(a) `constituents:` list vocabulary** — schema key on any node: list of `{id, name, ref?}`. Cheap: validator rule + one `<aef:constituents>` element at the seam; editor renders a badge/expander. Does NOT solve FC-15 (no boundary semantics, no nesting).
- **(b) real `subProcess` node type** — BPMN-native collapsed subProcess with child nodes. Solves FC-11 AND FC-15 (boundary, nesting, iteration scope). Expensive: editor needs expand/collapse rendering + child layout; bridge needs child-process emission; the biggest schema change since v2. BPMN standard alignment is a Portability (D4) win.
- **(c) keep `aef.x-*`** — zero cost, but the 4-map tally shows the cost is real and recurring: per-map vocabulary drift, validator-invisible, reader-invisible.

## Seam-cost dimensions to weigh (per option)

1. Bridge (`tools/yaml-to-bpmn.py`) emission + round-trip.
2. Editor parse/build/render (G-002 discipline: any new aef: field needs a cross-seam consistency test; note T-080's editor-internal parse/build asymmetry as the failure mode).
3. Validator rules (T-017's 34 rules) + schema docs.
4. Existing 24-map corpus migration (4 maps carry x-* today).

## Exploration plan (time-boxed, NOT started)

1. **Spike A (30 min):** draft `constituents:` YAML for the 4 hit sites; check expressiveness against each report's ground-truth description.
2. **Spike B (45 min):** paper-design collapsed subProcess in the editor (rendering only, no code): what does `g_gates` look like expanded? Does the bridge's flat-DI model survive?
3. **Assess (30 min):** score both against the seam-cost dimensions; test whether (a) is a strict subset of (b) that could ship first without blocking a later (b).
4. Write Recommendation; human decides.

## Spike B — subProcess paper design (executed 2026-07-04, after operator direction)

Structural facts examined (bridge `tools/yaml-to-bpmn.py` 317 lines; editor parse/build; T-079/T-080 findings):

1. **Element emission is nearly free.** `bpmn_element_name()` passes unknown node types through (TYPE_MAP only remaps link events) — a `subProcess` node type emits `<bpmn:subProcess>` with zero bridge changes at the element level. Editor needs: NODE_DEFAULTS entry, glyph (task-like box + [+] marker + constituent-count badge), palette item.
2. **There is no DI problem.** Neither bridge nor editor emits BPMN DI; all geometry rides per-node `aef:position` (confirmed T-079/T-080). Nested-layout cost — the scariest part of classic BPMN subProcess — does not exist in this stack for a collapsed-only v1.
3. **The real phase-2 cost is containment.** True child flow nodes must nest INSIDE `<bpmn:subProcess>`: bridge emission becomes recursive, laneSet flowNodeRefs must exclude children, and edge routing into/out of scope needs rules.
4. **HAZARD (G-002 class):** editor `parseBpmnXml` discovers nodes via `getElementsByTagNameNS`, which is RECURSIVE — nested children would be silently flattened into top-level nodes on import. Any phase-2 work must scope the parser FIRST (same silent-seam failure mode as T-080).

**Staged path (dissolves the a-vs-b tension):**
- **Phase 1 (small, S):** `subProcess` node type, collapsed-only rendering; constituents declared as structured metadata on the node (`constituents:` list riding an `<aef:constituents>` element, same pattern as T-063's `multiInstance`); optional `scopeOf:` back-reference gives FC-15 a boundary *marker*. Solves FC-11 fully. Option (a)'s content becomes (b)'s first phase, hosted on the BPMN-native element (Portability D4).
- **Phase 2 (larger, M, separate inception/build):** real nested children, bridge recursion, editor expand/collapse, parser scoping fix. Solves FC-15 fully (iteration bodies, nesting).

**Assumptions:** #1 (a ⊂ b, shippable first) — VALIDATED in the staged form above. #2 (option (a) alone cannot meet FC-15) — VALIDATED: a bare list has no boundary semantics; only the subProcess element gives FC-15 an anchor.

## Open questions

- IW-1 (task file): subProcess vs aef:constituents — ANSWERED (confidence 2): subProcess node type, staged; phase-1 seam cost ≈ option (a)'s (one aef: element + editor node type), phase-2 cost is real but deferred behind its own decision.

## Dialogue log

- **2026-07-04 — Q (agent):** presented the three options (a) `constituents:` list, (b) real subProcess node type, (c) keep `aef.x-*`, with evidence and spike plan, before executing spikes (inception discipline step 2).
- **A (operator):** "2" — real subProcess node type.
- **Course correction:** exploration refocused from three-way comparison to option-(b) feasibility; Spike A (constituents-list expressiveness drafting) DISSOLVED as a standalone spike — its content survives as phase 1 of the staged design.
- **Outcome:** Spike B executed same session; staged recommendation written (below in task file); formal go/no-go remains with the operator via `fw inception decide`.
