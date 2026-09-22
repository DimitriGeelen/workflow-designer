# AEF Workflow Designer — MCP server

A local stdio MCP server exposing the designer's validator to any MCP client.
**Zero dependencies.** One file, any `python3`, nothing to install.

Authorised on T-792; scoped by T-791; shape decided in T-790.

---

## What it is for

Another project holds a BPMN or workflow-YAML document and wants a verdict on it against
`aef-bpmn-mapping-v1`. Before this server, that meant a human coordinating a round trip: a
live URL, bytes copied by hand, and a rail message. That transport was measured in use 32
times (the `dogfood` pair rounds with AEF) and was **proven lossy** — T-787 found an archived
verification line citing scratchpad bytes that had been reaped, which took a published claim
down with it.

**You do not need a copy of this repository to use the tool.** Pass your document's bytes as
`content`.

## Install

Single line, from anywhere:

```
claude mcp add aef-workflow-designer -- python3 /opt/832-Workflow-designer/tools/mcp-designer-server.py
```

Running it from a checkout elsewhere? Point it at that checkout:

```
claude mcp add aef-workflow-designer -e DESIGNER_REPO_ROOT=/path/to/832-Workflow-designer -- python3 /path/to/832-Workflow-designer/tools/mcp-designer-server.py
```

Or as a `.mcp.json` fragment, for a client that reads one:

```json
{
  "aef-workflow-designer": {
    "command": "python3",
    "args": ["/opt/832-Workflow-designer/tools/mcp-designer-server.py"]
  }
}
```

**This is not wired into any live configuration by the build task.** Enabling it changes the
operator's environment and is their decision, not a side effect.

## The tools

### `validate_workflow`

| argument | meaning |
|---|---|
| `content` | the document's bytes, as text — **the usual case** |
| `path` | repo-relative path to a file inside the designer repo |
| `format` | `auto` (default), `yaml`, or `xml` |

Exactly one of `content` or `path`.

Returns:

```json
{
  "verdict": "valid | valid-with-warnings | invalid",
  "source": "<inline content>",
  "error_count": 0,
  "warning_count": 7,
  "findings": [
    {"severity": "ERROR", "rule": "E-XML-NODE-TYPE", "location": "node 'n_typo'",
     "message": "unknown flow-node element 'serviceTaks'; …"}
  ]
}
```

The rule id travels with every finding, so the caller learns **why**, not just whether.

### `yaml_to_bpmn`

Converts workflow YAML to BPMN **and validates the result in the same call**.

| argument | meaning |
|---|---|
| `content` | the workflow YAML, as text |
| `path` | repo-relative path to a `*.workflow.yaml` |

Exactly one of the two.

**Why the validation is not optional.** T-794 measured the failure this closes: a document
written with `flows:` where the schema says `edges:` converts **without complaint** into a
diagram whose every node is unreachable. Guessing `flows:` is the most natural mistake an LLM
can make here. Returning bytes alone would hand that silent failure to every caller, so the
verdict travels with the output — and when nodes come back unreachable, a `hint` names the
likely cause.

The bytes are returned even when the verdict is bad: you need them to see what was built.

```json
{
  "verdict": "valid-with-warnings",
  "bpmn": "<?xml version=\"1.0\" …",
  "warning_count": 2,
  "findings": [{"severity": "WARN", "rule": "W-XML-UNREACHABLE", …}],
  "hint": "2 node(s) are unreachable from any startEvent. The usual cause is the edge list being written as `flows:` instead of `edges:` …"
}
```

**Schema, so you do not have to guess it:** top-level keys are `workflowMeta`, `pool`, `lanes`,
`nodes`, `edges`. Each edge is `{uid, source, target}` referencing node `uid`s.

**One dependency, and only here.** The converter needs PyYAML. The server itself is
stdlib-only, and `validate_workflow` has no such dependency — if PyYAML is missing, this tool
says so and names the fix, and the other tool keeps working.

### `describe_workflow`

Reports **what AEF's task compiler would see** in a BPMN document — not a structural dump.

| argument | meaning |
|---|---|
| `content` | the BPMN XML, as text |
| `path` | repo-relative path to a `.bpmn` |

Returns lanes with their authority, every task node with its **lane-derived owner**, the edges,
inception subProcesses, and per-document `seam_coverage`.

**Why lane-derived owner is the whole point.** AEF at `agent-chat-arc` @1631: *"owner is
compiled FROM the lane; node-level owner is ignored."* The lane is the fact that governs
downstream, so this tool does that derivation rather than leaving the caller to do it.
`sovereignty → human`, `authority → framework`, `initiative → agent`.

**Non-core authorities are flagged, not judged.** Our corpus emits `none` and `external`
alongside the three core values. Those surface under `authority_values_to_confirm` with the
note that they are *"FLAGGED, not judged invalid — the exact AEF lane dialect is unconfirmed
here and was asked at agent-chat-arc @1635."* Calling a prediction a verdict is the drift
@1616 already caught once, in the other direction.

Worked example, the two documents that discriminate:

| | `task-gate.bpmn` | `context-memory.bpmn` |
|---|---|---|
| task nodes / with `aef:uid` | 5 / 5 | 7 / 7 |
| lane authorities | sovereignty, authority, initiative | `none` ×3 |
| nodes with **no derivable owner** | 0 | **7** |
| dialect flag | — | `["none"]` |

Those 7 ownerless nodes are **exactly** the 7 `W-LANE-NO-OWNER` findings `validate_workflow`
reports for the same file — two independently implemented tools agreeing node-for-node. The
probe asserts that equality, so the two cannot drift apart silently.

## What it will not do, by design

- **It never writes.** Every tool is a pure function or a read. Governance does not travel
  over MCP — there is no `PreToolUse`, no task gate, no sovereignty boundary behind this
  server — so the scope fence is what keeps that gap harmless. A pure function has nothing
  for P-002 to protect.
- **It refuses to leave the repository.** A `path` that resolves outside the repo root is
  rejected, symlinks resolved *before* the containment test. "Validate this file" must not
  become "read any file on the host", and there is no second gate behind this one.
- **It is not a translator.** The frozen `aef-bpmn-mapping-v1` says *"No translator is built
  here"*, and T-788 has the ownership question open with AEF. Validation is consumer-side.
- **It is not packaged.** MCPB is deferred until somebody asks to install it without a
  checkout (G-007: shipped bytes are a sovereignty promise).

## Why it is hand-rolled rather than built on the `mcp` SDK

The SDK is installed on this machine and would be the conventional choice. The deciding
argument against it is the server's whole reason for existing: if adopting it requires
`pip install mcp` into whatever environment another project's agent runs in, that is the same
class of friction that killed the manual transport.

The cost is accepted knowingly — spec compliance is ours to maintain. It is bounded
(`initialize`, `tools/list`, `tools/call`) and it is **verified empirically**:
`tools/_t792-mcp-server-probe.py` spawns the server as a subprocess and speaks real MCP to it.

## Verify

```
cd /opt/832-Workflow-designer && python3 tools/_t792-mcp-server-probe.py
```

Expected: `probe: 53 passed, 0 failed`.

The probe checks both directions (a valid document must come back `valid` AND an invalid one
`invalid`, in the same run, with differing verdicts — so the tool cannot pass as a constant),
and it checks the scope fence by attempting traversal. It is negative-controlled: with the
containment test disabled, the traversal legs go red (`18 passed, 3 failed`), and with
`yaml_to_bpmn`'s self-validation stubbed out the bad-document legs go red (`31 passed, 4 failed`); and with the lane→owner mapping collapsed to all-human,
`describe_workflow`'s authority leg goes red (`52 passed, 1 failed`).
