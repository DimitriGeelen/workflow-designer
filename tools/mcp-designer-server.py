#!/usr/bin/env python3
"""AEF Workflow Designer — MCP server (local stdio, zero dependencies).

Exposes the designer's validator to any MCP client. Authorised by the operator on T-792,
scoped by T-791.

── WHY THIS IS HAND-ROLLED RATHER THAN BUILT ON THE `mcp` SDK ────────────────────────────
The SDK is installed on this machine and would be the conventional choice. It was not used,
deliberately, and the reason is the whole point of this server.

The measured demand (T-791) is AEF sending us THEIR bytes to validate — 32 dogfood tasks,
four formal pair rounds — over a transport that needed a human to coordinate, a live URL,
and bytes hand-copied into a scratchpad. That transport died, and this morning it was proven
lossy: the scratchpad was reaped and took a published claim with it (T-787).

If adopting the replacement requires `pip install mcp` into whatever environment another
project's agent runs in, that is the same class of friction again. This file runs under any
`python3` with nothing installed. Copy it, point a client at it, done.

The cost is real and is accepted knowingly: spec compliance is now ours to maintain. It is
bounded — tools-only stdio MCP is `initialize`, `tools/list`, `tools/call` — and it is
verified empirically rather than assumed (T-792 AC1 spawns this file and speaks to it).

── SCOPE FENCE (T-791 §4, and it is enforced below, not merely documented) ───────────────
Governance does not travel over MCP: no PreToolUse, no task gate, no sovereignty boundary.
So every tool here is a PURE FUNCTION or a READ, and nothing writes into a governed tree.
A pure function has nothing for P-002 to protect. `_resolve_repo_path` is the teeth: a
caller cannot walk out of the repository, because there is no gate behind this one.

Protocol: newline-delimited JSON-RPC 2.0 on stdin/stdout.
**stdout carries the protocol and nothing else.** All diagnostics go to stderr; a stray
print() here corrupts the stream for every client.
"""

import json
import os
import subprocess
import sys
import tempfile

# Versions this server knows how to speak. On initialize we echo the client's requested
# version when we recognise it, else offer the newest we know — which is what the spec's
# negotiation asks for. Kept as a set so adding one is a one-line change.
KNOWN_PROTOCOL_VERSIONS = ("2024-11-05", "2025-03-26", "2025-06-18", "2025-11-25")
FALLBACK_PROTOCOL_VERSION = "2025-03-26"

SERVER_NAME = "aef-workflow-designer"
SERVER_VERSION = "0.1.0"

# PL-193: a harness that derives its subject from its own file location answers confidently
# about the wrong subject. Here the derivation is legitimate — the server ships inside the
# repo whose validator it wraps — but it is overridable, and its result is CHECKED below
# rather than trusted, so a misplaced copy fails loudly instead of validating nothing.
REPO_ROOT = os.environ.get(
    "DESIGNER_REPO_ROOT",
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
)
VALIDATOR = os.path.join(REPO_ROOT, "tools", "validate-workflow.py")


def log(msg):
    """Diagnostics to stderr. NEVER stdout — that is the protocol channel."""
    print("[%s] %s" % (SERVER_NAME, msg), file=sys.stderr, flush=True)


# ── the one tool ──────────────────────────────────────────────────────────────────────────

VALIDATE_TOOL = {
    "name": "validate_workflow",
    "description": (
        "Validate an AEF Workflow Designer document — BPMN XML or workflow YAML — against "
        "the aef-bpmn-mapping-v1 standard. Returns every finding with its severity, rule id, "
        "location and message.\n\n"
        "Pass `content` to validate bytes you hold (the usual case: you have a document and "
        "want a verdict on it). Pass `path` only for a file inside the designer repository. "
        "Exactly one of the two.\n\n"
        "Verdict: valid = no findings; warnings = advisory, the document is still usable; "
        "errors = the document is invalid. This tool only reads — it never modifies anything."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "content": {
                "type": "string",
                "description": "The document's bytes, as text. Use this to validate your own "
                               "document. Mutually exclusive with `path`.",
            },
            "path": {
                "type": "string",
                "description": "Repository-relative path to a document inside the designer "
                               "repo (e.g. 'examples/aef-processes/rendered/task-gate.bpmn'). "
                               "Paths outside the repository are refused. Mutually exclusive "
                               "with `content`.",
            },
            "format": {
                "type": "string",
                "enum": ["auto", "yaml", "xml"],
                "description": "Input format. Defaults to 'auto', which sniffs the content. "
                               "Set it explicitly when passing `content` whose shape is "
                               "ambiguous.",
            },
        },
        "additionalProperties": False,
    },
}

YAML_TO_BPMN_TOOL = {
    "name": "yaml_to_bpmn",
    "description": (
        "Convert a workflow YAML document into BPMN XML, and validate the result in the same "
        "call. Returns the BPMN plus the verdict — so a conversion that produced a structurally "
        "broken diagram tells you so instead of handing back bytes and staying quiet.\n\n"
        "SCHEMA NOTE, because this is the mistake that actually happens: the edge list key is "
        "`edges:`, NOT `flows:`. A document using `flows:` converts without complaint and "
        "produces a diagram in which every node is unreachable; the verdict is what catches it. "
        "Top-level keys are `workflowMeta`, `pool`, `lanes`, `nodes`, `edges`. Each edge is "
        "`{uid, source, target}` referencing node `uid`s.\n\n"
        "Pass `content` for YAML you hold, or `path` for a *.workflow.yaml inside the designer "
        "repository. Exactly one. This tool only reads — nothing is written to any repository."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "content": {
                "type": "string",
                "description": "The workflow YAML, as text. Mutually exclusive with `path`.",
            },
            "path": {
                "type": "string",
                "description": "Repo-relative path to a *.workflow.yaml inside the designer "
                               "repo. Paths outside it are refused. Mutually exclusive with "
                               "`content`.",
            },
        },
        "additionalProperties": False,
    },
}

DESCRIBE_TOOL = {
    "name": "describe_workflow",
    "description": (
        "Read a BPMN document and report **what AEF's task compiler would see in it** — not a "
        "structural dump. Returns lanes with their authority, every task node with the owner "
        "DERIVED FROM ITS LANE, the edges, and per-document coverage of the three seam "
        "requirements (`aef:uid`, `aef:laneMeta authority`, inception subProcesses).\n\n"
        "Why lane-derived owner: AEF's compiler takes owner from the lane and IGNORES any "
        "node-level owner, so the lane is the fact that governs downstream. This tool does "
        "that derivation for you.\n\n"
        "Non-core `authority` values are surfaced under `authority_values_to_confirm`. They "
        "are flagged, NOT called invalid — the exact AEF lane dialect is unconfirmed on our "
        "side, so this is a question to ask, not a verdict.\n\n"
        "Pass `content` for bytes you hold, or `path` for a file inside the designer repo. "
        "Exactly one. Read-only."
    ),
    "inputSchema": {
        "type": "object",
        "properties": {
            "content": {"type": "string",
                        "description": "The BPMN XML, as text. Mutually exclusive with `path`."},
            "path": {"type": "string",
                     "description": "Repo-relative path to a .bpmn inside the designer repo. "
                                    "Mutually exclusive with `content`."},
        },
        "additionalProperties": False,
    },
}

TOOLS = [VALIDATE_TOOL, YAML_TO_BPMN_TOOL, DESCRIBE_TOOL]


def _resolve_repo_path(rel):
    """Resolve a caller-supplied path, refusing anything outside the repository.

    This is the scope fence with teeth. There is no framework gate behind an MCP server —
    no PreToolUse, no task check — so 'validate this file' must not become 'read any file
    on the host'. Symlinks are resolved BEFORE the containment test, because a symlink
    inside the repo pointing out of it would otherwise pass a naive prefix check.
    """
    root = os.path.realpath(REPO_ROOT)
    candidate = os.path.realpath(os.path.join(root, rel))
    if candidate != root and not candidate.startswith(root + os.sep):
        raise ValueError(
            "path %r resolves outside the designer repository and was refused. "
            "Pass the document's bytes as `content` instead." % rel
        )
    if not os.path.isfile(candidate):
        raise ValueError("no such file inside the repository: %r" % rel)
    return candidate


def _run_validator(target, fmt):
    """Invoke the validator and return its parsed JSON report."""
    cmd = [sys.executable, VALIDATOR, "--json", "--quiet"]
    if fmt and fmt != "auto":
        cmd += ["--format", fmt]
    cmd.append(target)
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    raw = proc.stdout.strip()
    if not raw:
        raise RuntimeError(
            "validator produced no output (exit %d): %s"
            % (proc.returncode, (proc.stderr or "").strip()[:400])
        )
    return json.loads(raw)


def tool_validate_workflow(args):
    content = args.get("content")
    path = args.get("path")
    fmt = args.get("format", "auto")

    if (content is None) == (path is None):
        raise ValueError("pass exactly one of `content` or `path`")

    if path is not None:
        target = _resolve_repo_path(path)
        report = _run_validator(target, fmt)
        source = path
    else:
        # The document is the caller's, not ours. It goes to a temp file, is read, and the
        # temp file is removed — nothing is written into the repository or any governed tree.
        # The suffix matters: with format 'auto' the validator sniffs by extension first.
        suffix = ".workflow.yaml" if fmt == "yaml" else ".bpmn"
        fd, tmp = tempfile.mkstemp(suffix=suffix, prefix="designer-mcp-")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as fh:
                fh.write(content)
            report = _run_validator(tmp, fmt)
        finally:
            try:
                os.unlink(tmp)
            except OSError:
                pass
        source = "<inline content>"

    findings = report.get("findings", [])
    code = report.get("exit_code", 2)
    verdict = {0: "valid", 1: "valid-with-warnings"}.get(code, "invalid")

    errors = sum(1 for f in findings if f.get("severity") == "ERROR")
    warnings = sum(1 for f in findings if f.get("severity") == "WARN")

    return {
        "verdict": verdict,
        "source": source,
        "error_count": errors,
        "warning_count": warnings,
        "findings": findings,
    }


CONVERTER = os.path.join(REPO_ROOT, "tools", "yaml-to-bpmn.py")


def tool_yaml_to_bpmn(args):
    """Convert workflow YAML to BPMN, and validate the RESULT in the same call.

    T-794 measured why the validation is not optional: a document using `flows:` where the
    schema says `edges:` converts WITHOUT COMPLAINT into a diagram whose every node is
    unreachable. Returning bytes alone would ship that silent failure to every caller, so
    the verdict travels with the output. The bytes are still returned when the verdict is
    bad — the caller needs them to see what went wrong.
    """
    content = args.get("content")
    path = args.get("path")
    if (content is None) == (path is None):
        raise ValueError("pass exactly one of `content` or `path`")

    tmp_in = None
    try:
        if path is not None:
            src = _resolve_repo_path(path)
            source = path
        else:
            fd, tmp_in = tempfile.mkstemp(suffix=".workflow.yaml", prefix="designer-mcp-")
            with os.fdopen(fd, "w", encoding="utf-8") as fh:
                fh.write(content)
            src = tmp_in
            source = "<inline content>"

        proc = subprocess.run([sys.executable, CONVERTER, src],
                              capture_output=True, text=True, timeout=120)
        if proc.returncode != 0 or not proc.stdout.strip():
            err = (proc.stderr or "").strip()
            # AC4: the one third-party dependency in the chain, named rather than leaked as
            # a traceback. The SERVER is stdlib-only; the converter it shells out to is not.
            if "yaml" in err and ("ModuleNotFound" in err or "ImportError" in err):
                raise RuntimeError(
                    "the converter needs PyYAML, which is not installed in this Python "
                    "(%s). Install it with: pip install pyyaml. Note that validate_workflow "
                    "has no such dependency and still works." % sys.executable
                )
            raise RuntimeError("conversion failed (exit %d): %s" % (proc.returncode, err[:600]))

        bpmn = proc.stdout
    finally:
        if tmp_in:
            try:
                os.unlink(tmp_in)
            except OSError:
                pass

    # ── the half that makes this safe to use ──────────────────────────────────────────────
    fd, tmp_out = tempfile.mkstemp(suffix=".bpmn", prefix="designer-mcp-")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(bpmn)
        report = _run_validator(tmp_out, "xml")
    finally:
        try:
            os.unlink(tmp_out)
        except OSError:
            pass

    findings = report.get("findings", [])
    code = report.get("exit_code", 2)
    verdict = {0: "valid", 1: "valid-with-warnings"}.get(code, "invalid")
    unreachable = [f for f in findings if f.get("rule") == "W-XML-UNREACHABLE"]

    out = {
        "verdict": verdict,
        "source": source,
        "bpmn": bpmn,
        "error_count": sum(1 for f in findings if f.get("severity") == "ERROR"),
        "warning_count": sum(1 for f in findings if f.get("severity") == "WARN"),
        "findings": findings,
    }
    if unreachable:
        # The measured failure mode, named where the caller will actually read it.
        out["hint"] = (
            "%d node(s) are unreachable from any startEvent. The usual cause is the edge list "
            "being written as `flows:` instead of `edges:` — the converter accepts that "
            "silently and produces a disconnected graph." % len(unreachable)
        )
    return out


# The three lane authorities the AEF authority model is built on. Non-core values are
# REPORTED, never rejected: the exact AEF lane dialect is unconfirmed on our side (asked at
# agent-chat-arc @1635) and our corpus emits "none" and "external" as well. Treating our
# prediction as a verdict is precisely the drift @1616 caught in the other direction.
CORE_AUTHORITIES = ("sovereignty", "authority", "initiative")

# Lane authority -> the owner AEF's compiler derives. Their words, @1631: "owner is compiled
# FROM the lane; node-level owner is ignored."
AUTHORITY_TO_OWNER = {"sovereignty": "human", "authority": "framework", "initiative": "agent"}

TASK_TYPES = ("userTask", "serviceTask", "scriptTask", "manualTask", "businessRuleTask", "task")


def _local(tag):
    """Strip the namespace. AEF matches by local name, so we do too (@1631)."""
    return tag.rsplit("}", 1)[-1] if "}" in tag else tag


def _attr_by_local(elem, name):
    for k, v in elem.attrib.items():
        if _local(k) == name:
            return v
    return None


def tool_describe_workflow(args):
    import xml.etree.ElementTree as ET

    content = args.get("content")
    path = args.get("path")
    if (content is None) == (path is None):
        raise ValueError("pass exactly one of `content` or `path`")

    if path is not None:
        with open(_resolve_repo_path(path), encoding="utf-8") as fh:
            content = fh.read()
        source = path
    else:
        source = "<inline content>"

    try:
        root = ET.fromstring(content)
    except ET.ParseError as exc:
        raise ValueError("not parseable as XML: %s" % exc)

    # ── lanes, and the owner each one implies ────────────────────────────────────────────
    lanes = {}
    lane_of_node = {}
    for lane_el in root.iter():
        if _local(lane_el.tag) != "lane":
            continue
        lid = _attr_by_local(lane_el, "id") or "<unnamed>"
        authority = None
        for sub in lane_el.iter():
            if _local(sub.tag) == "laneMeta":
                authority = _attr_by_local(sub, "authority")
                break
        lanes[lid] = {
            "id": lid,
            "name": _attr_by_local(lane_el, "name"),
            "authority": authority,
            "derived_owner": AUTHORITY_TO_OWNER.get(authority),
            "in_core_dialect": authority in CORE_AUTHORITIES,
        }
        for ref in lane_el.iter():
            if _local(ref.tag) == "flowNodeRef" and (ref.text or "").strip():
                lane_of_node[ref.text.strip()] = lid

    # ── nodes, with the owner AEF would derive ───────────────────────────────────────────
    nodes, inceptions = [], []
    for el in root.iter():
        kind = _local(el.tag)
        nid = _attr_by_local(el, "id")
        if kind == "subProcess":
            wf_type = None
            for sub in el.iter():
                if _local(sub.tag) == "meta":
                    wf_type = _attr_by_local(sub, "workflowType")
                    break
            if wf_type == "inception":
                lid = lane_of_node.get(nid)
                inceptions.append({
                    "id": nid,
                    "lane": lid,
                    "lane_authority": (lanes.get(lid) or {}).get("authority"),
                    # AEF @1631: a mis-laned inception FAILS FAST rather than being forced to
                    # owner:human. Reporting this is the point — it is a refusal predictor.
                    "sovereignty_laned": (lanes.get(lid) or {}).get("authority") == "sovereignty",
                })
            continue
        if kind not in TASK_TYPES or not nid:
            continue
        uid = None
        for sub in el.iter():
            if _local(sub.tag) == "uid":
                uid = (sub.text or "").strip() or _attr_by_local(sub, "value")
                break
            found = _attr_by_local(sub, "uid")
            if found:
                uid = found
                break
        if uid is None:
            uid = _attr_by_local(el, "uid")
        lid = lane_of_node.get(nid)
        lane = lanes.get(lid) or {}
        nodes.append({
            "id": nid,
            "type": kind,
            "name": _attr_by_local(el, "name"),
            "lane": lid,
            "lane_authority": lane.get("authority"),
            "derived_owner": lane.get("derived_owner"),
            "aef_uid": uid,
        })

    edges = []
    for el in root.iter():
        if _local(el.tag) == "sequenceFlow":
            edges.append({
                "id": _attr_by_local(el, "id"),
                "source": _attr_by_local(el, "sourceRef"),
                "target": _attr_by_local(el, "targetRef"),
            })

    missing_uid = [n["id"] for n in nodes if not n["aef_uid"]]
    no_owner = [n["id"] for n in nodes if not n["derived_owner"]]
    non_core = sorted({l["authority"] for l in lanes.values()
                       if l["authority"] and not l["in_core_dialect"]})

    out = {
        "source": source,
        "lanes": list(lanes.values()),
        "task_nodes": nodes,
        "edges": edges,
        "inception_subprocesses": inceptions,
        "seam_coverage": {
            "task_nodes": len(nodes),
            "with_aef_uid": len(nodes) - len(missing_uid),
            "nodes_missing_uid": missing_uid,
            "lanes": len(lanes),
            "lanes_with_authority": sum(1 for l in lanes.values() if l["authority"]),
            "nodes_with_no_derivable_owner": no_owner,
            "inception_subprocesses": len(inceptions),
        },
    }
    if non_core:
        out["authority_values_to_confirm"] = {
            "values": non_core,
            "note": (
                "These lane authorities are outside the three the AEF authority model is built "
                "on (%s). They are FLAGGED, not judged invalid — the exact AEF lane dialect is "
                "unconfirmed here and was asked at agent-chat-arc @1635. Nodes in these lanes "
                "have no derivable owner, which our own validator reports as W-LANE-NO-OWNER."
                % ", ".join(CORE_AUTHORITIES)
            ),
        }
    return out


HANDLERS = {
    "validate_workflow": tool_validate_workflow,
    "yaml_to_bpmn": tool_yaml_to_bpmn,
    "describe_workflow": tool_describe_workflow,
}


# ── JSON-RPC plumbing ─────────────────────────────────────────────────────────────────────

def _result(req_id, payload):
    return {"jsonrpc": "2.0", "id": req_id, "result": payload}


def _error(req_id, code, message):
    return {"jsonrpc": "2.0", "id": req_id, "error": {"code": code, "message": message}}


def handle(req):
    """Return a response dict, or None for a notification (which takes no reply)."""
    method = req.get("method")
    req_id = req.get("id")
    params = req.get("params") or {}

    # A notification has no id. The spec forbids replying to one; replying anyway is a
    # protocol violation that some clients treat as fatal.
    if req_id is None:
        return None

    if method == "initialize":
        asked = params.get("protocolVersion")
        version = asked if asked in KNOWN_PROTOCOL_VERSIONS else FALLBACK_PROTOCOL_VERSION
        return _result(req_id, {
            "protocolVersion": version,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
            "instructions": (
                "Validates AEF Workflow Designer documents against aef-bpmn-mapping-v1. "
                "To check a document you hold, pass its bytes as `content` — you do not need "
                "a copy of the designer repository. `path` is only for files already inside "
                "it. Read-only: nothing here modifies any file."
            ),
        })

    if method == "ping":
        return _result(req_id, {})

    if method == "tools/list":
        return _result(req_id, {"tools": TOOLS})

    if method == "tools/call":
        name = params.get("name")
        handler = HANDLERS.get(name) if isinstance(name, str) else None
        if handler is None:
            return _error(req_id, -32602, "unknown tool: %r" % name)
        try:
            payload = handler(params.get("arguments") or {})
        except Exception as exc:  # noqa: BLE001 — a tool fault is data, not a crash
            # MCP convention: a TOOL failure is a successful call carrying isError, so the
            # model can see and react to it. Only PROTOCOL faults become JSON-RPC errors.
            return _result(req_id, {
                "content": [{"type": "text", "text": "%s: %s" % (type(exc).__name__, exc)}],
                "isError": True,
            })
        return _result(req_id, {
            "content": [{"type": "text", "text": json.dumps(payload, indent=2)}],
            "isError": False,
        })

    return _error(req_id, -32601, "method not found: %r" % method)


def main():
    if not os.path.isfile(VALIDATOR):
        # Fail at startup with the reason, rather than answering every call with a confusing
        # tool error. A server that cannot reach its subject should say so once, loudly.
        log("FATAL: validator not found at %s (set DESIGNER_REPO_ROOT)" % VALIDATOR)
        return 2

    log("ready — %s %s, repo root %s" % (SERVER_NAME, SERVER_VERSION, REPO_ROOT))

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError as exc:
            sys.stdout.write(json.dumps(_error(None, -32700, "parse error: %s" % exc)) + "\n")
            sys.stdout.flush()
            continue

        try:
            resp = handle(req)
        except Exception as exc:  # noqa: BLE001 — never die on one bad request
            log("internal error: %r" % exc)
            resp = _error(req.get("id"), -32603, "internal error: %s" % exc)

        if resp is not None:
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()

    return 0


if __name__ == "__main__":
    sys.exit(main())
