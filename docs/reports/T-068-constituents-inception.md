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

## Open questions

- IW-1 (task file): subProcess vs aef:constituents — and seam cost of each. *(confidence 0)*

## Dialogue log

*(empty — no human dialogue on this question yet)*
