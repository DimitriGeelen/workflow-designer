#!/usr/bin/env python3
"""_t792-mcp-server-probe.py — spawn the MCP server and speak real MCP to it.

Not a unit test of the functions: a SUBPROCESS, spoken to over stdin/stdout exactly as a
client would. A server that has only ever been imported has not been shown to be a server.
"""
import json, subprocess, sys, os

# T-787: a probe that hardcodes an absolute path stops reproducing the moment it moves.
ROOT = os.environ.get("DESIGNER_REPO_ROOT",
                      os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SERVER = os.path.join(ROOT, "tools", "mcp-designer-server.py")

passed = failed = 0
def check(cond, label):
    global passed, failed
    if cond: print("  ok   %s" % label); passed += 1
    else:    print("FAIL   %s" % label, file=sys.stderr); failed += 1

proc = subprocess.Popen([sys.executable, SERVER], stdin=subprocess.PIPE,
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=1)

def rpc(method, params=None, rid=[0]):
    rid[0] += 1
    msg = {"jsonrpc": "2.0", "id": rid[0], "method": method}
    if params is not None: msg["params"] = params
    proc.stdin.write(json.dumps(msg) + "\n"); proc.stdin.flush()
    return json.loads(proc.stdout.readline())

def notify(method, params=None):
    msg = {"jsonrpc": "2.0", "method": method}
    if params is not None: msg["params"] = params
    proc.stdin.write(json.dumps(msg) + "\n"); proc.stdin.flush()

def call(args):
    r = rpc("tools/call", {"name": "validate_workflow", "arguments": args})
    res = r["result"]
    body = json.loads(res["content"][0]["text"]) if not res.get("isError") else None
    return res, body

# ── AC1: handshake ────────────────────────────────────────────────────────────────────────
init = rpc("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                          "clientInfo": {"name": "t792-probe", "version": "1"}})
check(init.get("result", {}).get("protocolVersion") == "2025-06-18",
      "initialize echoes a protocol version it knows (2025-06-18)")
check(init["result"]["serverInfo"]["name"] == "aef-workflow-designer", "serverInfo names the server")
check("tools" in init["result"]["capabilities"], "advertises the tools capability")

# unknown version must NOT be echoed back
init2 = rpc("initialize", {"protocolVersion": "1999-01-01", "capabilities": {}})
check(init2["result"]["protocolVersion"] == "2025-03-26",
      "unknown protocol version falls back instead of echoing nonsense")

notify("notifications/initialized")   # must produce NO reply — verified by the next read lining up

# ── AC1: discovery ────────────────────────────────────────────────────────────────────────
tl = rpc("tools/list")
names = [t["name"] for t in tl["result"]["tools"]]
check(names == ["validate_workflow"], "tools/list returns exactly validate_workflow (scope fence)")
check("content" in tl["result"]["tools"][0]["inputSchema"]["properties"], "schema exposes `content`")

# ── AC2: discriminates in BOTH directions, same run ──────────────────────────────────────
valid_doc = open(os.path.join(ROOT, "examples/aef-processes/rendered/tier0-escalation.bpmn"), encoding="utf-8").read()
bad_doc   = open(os.path.join(ROOT, "tests/fixtures/invalid/E-XML-NODE-TYPE.xml"), encoding="utf-8").read()

res, body = call({"content": valid_doc})
check(not res["isError"] and body["verdict"] == "valid", "VALID document -> verdict 'valid'")
check(body["error_count"] == 0, "VALID document reports 0 errors")

res, body = call({"content": bad_doc})
check(not res["isError"] and body["verdict"] == "invalid", "INVALID document -> verdict 'invalid'")
check(body["error_count"] >= 1, "INVALID document reports >=1 error")
check(any(f["rule"] == "E-XML-NODE-TYPE" for f in body["findings"]),
      "the actual rule id is returned, so the caller learns WHY")

# the two verdicts must differ — otherwise the tool is a constant
res_a, body_a = call({"content": valid_doc})
res_b, body_b = call({"content": bad_doc})
check(body_a["verdict"] != body_b["verdict"], "verdicts DIFFER across inputs (not a constant)")

# ── AC4: the scope fence refuses traversal ───────────────────────────────────────────────
res, _ = call({"path": "../../etc/passwd"})
check(res["isError"], "path traversal '../../etc/passwd' is REFUSED")
check("outside the designer repository" in res["content"][0]["text"], "refusal says why")

res, _ = call({"path": "../../../root/.claude/plugins/installed_plugins.json"})
check(res["isError"], "deep traversal out of the repo is REFUSED")

# positive control: an in-repo path DOES work, so the refusals above mean something
res, body = call({"path": "examples/aef-processes/rendered/tier0-escalation.bpmn"})
check(not res["isError"] and body["verdict"] == "valid",
      "control: an in-repo path IS accepted (so the refusals are about location, not breakage)")

# ── argument discipline ──────────────────────────────────────────────────────────────────
res, _ = call({})
check(res["isError"], "neither content nor path -> tool error")
res, _ = call({"content": "x", "path": "y"})
check(res["isError"], "both content and path -> tool error")

# ── protocol faults are JSON-RPC errors, not tool errors ─────────────────────────────────
r = rpc("tools/call", {"name": "no_such_tool", "arguments": {}})
check("error" in r and r["error"]["code"] == -32602, "unknown tool -> JSON-RPC -32602")
r = rpc("no/such/method")
check("error" in r and r["error"]["code"] == -32601, "unknown method -> JSON-RPC -32601")
r = rpc("ping")
check(r.get("result") == {}, "ping answers")

proc.stdin.close(); proc.wait(timeout=10)
print("\nprobe: %d passed, %d failed" % (passed, failed))
sys.exit(1 if failed else 0)
