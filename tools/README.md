# tools/

Standalone tooling for the AEF Workflow Designer. These are product tools, kept
separate from the vendored `fw` framework CLI to respect the product/framework
boundary (Directive 4: Portability).

## validate-workflow.py

Structural schema validator for the two workflow formats the designer produces
(see [`docs/designer/schema.md`](../docs/designer/schema.md)):

- **YAML canonical form** (§3) — the AEF-canonical, source-controlled
  representation. Edges reference node `uid`s.
- **BPMN 2.0 XML export** (§7) — what the designer's **Save** action emits. Flow
  references use `bpmn:id`; `aef:uid` carries stable identity.

It checks structure only — it does **not** execute workflows (the
`fw workflow run` executor is a separate, out-of-scope effort).

```bash
python3 tools/validate-workflow.py path/to/workflow.yaml         # YAML (auto)
python3 tools/validate-workflow.py path/to/workflow.bpmn         # BPMN-XML (auto)
python3 tools/validate-workflow.py path/to/file --format xml     # force format
python3 tools/validate-workflow.py path/to/workflow.yaml --json  # machine output
```

Format is auto-detected by extension (`.yaml`/`.yml` vs `.bpmn`/`.xml`), falling
back to a content sniff (leading `<` ⇒ XML); `--format {auto,yaml,xml}` overrides.

**Exit codes** (AEF audit convention): `0` valid · `1` warnings only · `2`
invalid (hard-rule errors or load/parse failure).

### YAML rules

Hard rules (ERROR, exit 2) — from `schema.md` §7.3 plus the required-field
tables in §3/§4.1/§5/§6.1:

| Rule | Meaning |
|---|---|
| `E-TOPLEVEL-MISSING` | Missing a required top-level key (`workflowMeta`, `pool`, `lanes`, `nodes`, `edges`) |
| `E-LANES-EMPTY` | `lanes` present but empty (at least one required) |
| `E-NODE-FIELD` | Node missing a required field (`uid`, `type`, `name`, `lane`, `x`, `y`) |
| `E-LANE-FIELD` | Lane missing a required field (`id`, `name`, `authority`, `height`) |
| `E-EDGE-FIELD` | Edge missing a required field (`uid`, `source`, `target`) |
| `E-NODE-TYPE` | Node `type` not one of the eight-element BPMN subset |
| `E-AUTHORITY` | Lane `authority` outside `{sovereignty, authority, initiative, external, none}` |
| `E-UID-DUP` | A `uid` used more than once across nodes and edges |
| `E-EDGE-DANGLING` | Edge `source`/`target` does not resolve to a node `uid` |
| `E-NODE-LANE` | Node `lane` does not match any declared lane `id` |
| `E-ABBR-DUP` | Two lanes share the same `abbr` |
| `E-GW-OUTGOING` | An `exclusiveGateway` has fewer than two outgoing edges |

Convention rules (WARN, exit 1) — usable but flagged:

| Rule | Meaning |
|---|---|
| `W-GW-AMBIGUOUS` | An `exclusiveGateway` has more than one unconditioned outgoing edge (only one may be the default) |
| `W-IO-INPUT` | A required `io.input` has no upstream node emitting a matching-name output |

### BPMN-XML rules

Hard rules (ERROR, exit 2) — the §7.3 rules expressed on the XML structure
(§7.1 identifier mapping, §7.2 `aef:` namespace):

| Rule | Meaning |
|---|---|
| `E-XML-PARSE` | Malformed XML |
| `E-XML-STRUCTURE` | No `<bpmn:process>` under `<bpmn:definitions>` |
| `E-XML-ID-DUP` | A `bpmn:id` is not unique in the document |
| `E-XML-UID-DUP` | An `aef:uid` is not unique in the document |
| `E-XML-FLOW-DANGLING` | A `sequenceFlow` `sourceRef`/`targetRef` does not resolve to a flow-node `bpmn:id` |
| `E-XML-LANEREF-DANGLING` | A lane `flowNodeRef` does not resolve to a flow-node `bpmn:id` |
| `E-XML-GW-OUTGOING` | An `exclusiveGateway` has fewer than two outgoing sequence flows |

Convention rule (WARN, exit 1):

| Rule | Meaning |
|---|---|
| `W-XML-NODE-UNASSIGNED` | A flow node is not assigned to any lane |

Note: in the YAML canonical form, edges reference node **`uid`**s; in the XML
export, flow references use **`bpmn:id`** (displayId) while `aef:uid` carries
stable identity. The two forms carry the same information (schema.md §3).

## bake-clean-layout.py

Bakes the editor's **Clean layout** into the shipped corpus so every
`examples/aef-processes/rendered/*.bpmn` opens already-tidy (rows aligned, stacks
respaced) and the T-100 Clean nudge stays quiet on the shipped maps (T-101).

Clean (`cleanLayout()` = tidy row-snap + T-093 branch pitch + T-094 align-rows)
lives **only** in the editor JS. Rather than reimplement it in Python (PL-005:
editor/bridge drift), the bake runs the *real editor* headless and reuses its own
`cleanLayout()` verbatim:

- `tools/_clean-layout-cdp.mjs` — drives `src/aef-workflow-designer.html` in
  headless Chromium over the DevTools Protocol, iterating `cleanLayout()` to a
  fixpoint per map. **Dependency-free**: native Node (≥22) `WebSocket`/`fetch`
  and the cached Playwright Chromium — no `npm install`.
- `bake-clean-layout.py` — line-surgically writes the tidied `y`/lane-`height`
  back into the **yaml source** (preserving comments/order — diff is only the
  changed numbers), re-renders via `yaml-to-bpmn.py`, and mirrors `build/gallery`.

Geometry lives in the yaml and the `.bpmn` is a pure projection of it, so baking
into the source means a naive `yaml-to-bpmn.py` regen can never silently un-tidy
the corpus.

```bash
python3 tools/bake-clean-layout.py            # re-bake all 24 maps (run after Clean logic changes)
python3 tools/bake-clean-layout.py --check    # assert the corpus is a Clean fixpoint (mapMessiness < 3, moves 0)
python3 tools/bake-clean-layout.py <map ...>  # limit to named maps
```

Re-run the bake whenever `cleanLayout()` (or its sub-passes) changes, so the
shipped corpus tracks the editor's current tidy standard.

## Tests

```bash
bash tests/run-validator-tests.sh
```

Golden fixture: [`tests/fixtures/valid/`](../tests/fixtures/valid/). One
invalid fixture per hard rule under `tests/fixtures/invalid/` and one per
convention rule under `tests/fixtures/warn/`, each named `<RULE-ID>.yaml`.
