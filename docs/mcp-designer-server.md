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

## The tool

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

Expected: `probe: 21 passed, 0 failed`.

The probe checks both directions (a valid document must come back `valid` AND an invalid one
`invalid`, in the same run, with differing verdicts — so the tool cannot pass as a constant),
and it checks the scope fence by attempting traversal. It is negative-controlled: with the
containment test disabled, the traversal legs go red (`18 passed, 3 failed`).
