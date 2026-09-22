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

TOOLS = [VALIDATE_TOOL]


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


HANDLERS = {"validate_workflow": tool_validate_workflow}


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
