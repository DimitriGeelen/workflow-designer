# tools/

Standalone tooling for the AEF Workflow Designer. These are product tools, kept
separate from the vendored `fw` framework CLI to respect the product/framework
boundary (Directive 4: Portability).

## validate-workflow.py

Structural schema validator for workflow files in the **YAML canonical form**
(the AEF-canonical, source-controlled representation; see
[`docs/designer/schema.md`](../docs/designer/schema.md) §3). It checks structure
only — it does **not** execute workflows (the `fw workflow run` executor is a
separate, out-of-scope effort).

```bash
python3 tools/validate-workflow.py path/to/workflow.yaml        # human report
python3 tools/validate-workflow.py path/to/workflow.yaml --json # machine output
```

**Exit codes** (AEF audit convention): `0` valid · `1` warnings only · `2`
invalid (hard-rule errors or load failure).

### Rules

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

Note: in the YAML canonical form, edges reference node **`uid`**s (not
displayIds). displayId/`bpmn:id` uniqueness is a BPMN-XML concern; XML
validation is a possible later slice.

## Tests

```bash
bash tests/run-validator-tests.sh
```

Golden fixture: [`tests/fixtures/valid/`](../tests/fixtures/valid/). One
invalid fixture per hard rule under `tests/fixtures/invalid/` and one per
convention rule under `tests/fixtures/warn/`, each named `<RULE-ID>.yaml`.
