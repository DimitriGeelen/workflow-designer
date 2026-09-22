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

# THE FENCE, declared once. Every section asserts against this exact list rather than
# keeping its own copy — three copies drifted apart across T-792/795/796 and each one had
# to be chased separately. EXACT, never a subset check: an accidentally added fourth tool
# must fail here rather than pass unnoticed (T-791 scope fence: read-only, pure functions).
EXPECTED_TOOLS = ["validate_workflow", "yaml_to_bpmn", "describe_workflow"]

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
# T-795 widened this from one tool to two. The assertion stays EXACT rather than becoming
# a subset check ("validate_workflow in names"), because an exact list is what makes an
# accidentally-added third tool fail here instead of passing unnoticed.
check(names == EXPECTED_TOOLS, "tools/list matches the declared fence (scope fence)")
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

# ── T-795: yaml_to_bpmn, and the measured failure mode it exists to catch ────────────────
def call_conv(args):
    r = rpc("tools/call", {"name": "yaml_to_bpmn", "arguments": args})
    res = r["result"]
    body = json.loads(res["content"][0]["text"]) if not res.get("isError") else None
    return res, body

tl2 = rpc("tools/list")
check([t["name"] for t in tl2["result"]["tools"]] == EXPECTED_TOOLS,
      "tools/list matches the declared fence (not widened)")
desc = [t for t in tl2["result"]["tools"] if t["name"] == "yaml_to_bpmn"][0]["description"]
check("`edges:`, NOT `flows:`" in desc,
      "the description names the key that gets guessed wrong (T-794)")

GOOD = """workflowMeta: {id: probe, version: 1, schemaVersion: 2, tier_default: 1}
pool: {id: Pool_probe, name: probe}
lanes:
  - {id: agent, name: "Agent \u00b7 Initiative", abbr: agt, authority: initiative, height: 160}
nodes:
  - {uid: n_start, type: startEvent, name: Begin, slug: begin, lane: agent, x: 120, y: 240}
  - {uid: n_do, type: scriptTask, name: Do it, slug: do, lane: agent, x: 300, y: 226}
  - {uid: n_end, type: endEvent, name: Done, slug: done, lane: agent, x: 500, y: 240}
edges:
  - {uid: e1, source: n_start, target: n_do}
  - {uid: e2, source: n_do, target: n_end}
"""
# The SAME document with the one measured mistake: flows: instead of edges:
BAD = GOOD.replace("edges:", "flows:")

res, body = call_conv({"content": GOOD})
check(not res["isError"] and body["verdict"] == "valid", "GOOD yaml -> verdict 'valid'")
check(body["bpmn"].lstrip().startswith("<?xml") or "<bpmn" in body["bpmn"][:400],
      "GOOD yaml returns actual BPMN bytes")
check("hint" not in body, "GOOD yaml carries no unreachable hint")

res, body = call_conv({"content": BAD})
check(not res["isError"], "BAD yaml still returns a response rather than erroring out")
check(body["verdict"] != "valid",
      "BAD yaml (flows: instead of edges:) is NOT reported as valid — the silent path is closed")
check(any(f["rule"] == "W-XML-UNREACHABLE" for f in body["findings"]),
      "BAD yaml names W-XML-UNREACHABLE, the measured symptom")
check("flows:" in body.get("hint", ""), "BAD yaml's hint names the actual cause")
check(body["bpmn"], "BAD yaml still returns the bytes, so the caller can see what it built")

# the two verdicts must differ, or the tool is a constant
res_g, bg = call_conv({"content": GOOD})
res_b, bb = call_conv({"content": BAD})
check(bg["verdict"] != bb["verdict"], "conversion verdicts DIFFER across inputs (not a constant)")

# scope fence applies to the new tool too
res, _ = call_conv({"path": "../../etc/passwd"})
check(res["isError"], "yaml_to_bpmn refuses path traversal as well")
res, _ = call_conv({})
check(res["isError"], "yaml_to_bpmn: neither content nor path -> tool error")

# an in-repo authoring file converts (positive control on the path arm)
res, body = call_conv({"path": "examples/aef-processes/arc-lifecycle.workflow.yaml"})
check(not res["isError"] and body["verdict"] == "valid",
      "control: a real corpus .workflow.yaml converts and validates clean")

# ── T-796: describe_workflow ─────────────────────────────────────────────────────────────
def call_desc(args):
    r = rpc("tools/call", {"name": "describe_workflow", "arguments": args})
    res = r["result"]
    body = json.loads(res["content"][0]["text"]) if not res.get("isError") else None
    return res, body

tl3 = rpc("tools/list")
check([t["name"] for t in tl3["result"]["tools"]] == EXPECTED_TOOLS,
      "tools/list matches the declared fence after the third tool")

CLEAN = "examples/aef-processes/rendered/task-gate.bpmn"
NONE_ = "examples/aef-processes/rendered/context-memory.bpmn"

res, clean = call_desc({"path": CLEAN})
check(not res["isError"], "describe: clean document returns a report")
check(clean["seam_coverage"]["with_aef_uid"] == clean["seam_coverage"]["task_nodes"] > 0,
      "describe: every task node in the clean doc carries aef:uid")
check(all(n["derived_owner"] for n in clean["task_nodes"]),
      "describe: every node in the clean doc has a LANE-DERIVED owner (AEF @1631)")
check(sorted({l["derived_owner"] for l in clean["lanes"]}) == ["agent", "framework", "human"],
      "describe: the three core authorities map to human/framework/agent")
check("authority_values_to_confirm" not in clean, "describe: clean doc raises no dialect flag")

res, noneish = call_desc({"path": NONE_})
check(not res["isError"], "describe: authority=none document returns a report")
check(noneish.get("authority_values_to_confirm", {}).get("values") == ["none"],
      "describe: authority=none IS flagged for confirmation")
check("not judged invalid" in noneish["authority_values_to_confirm"]["note"],
      "describe: the flag is worded as a question, not a verdict (our dialect is unconfirmed)")
check(len(noneish["seam_coverage"]["nodes_with_no_derivable_owner"]) > 0,
      "describe: authority=none yields nodes with NO derivable owner")

# AC4 — the two reports must DIFFER, or the tool is not reading its input
check(clean["seam_coverage"]["nodes_with_no_derivable_owner"]
      != noneish["seam_coverage"]["nodes_with_no_derivable_owner"],
      "describe: the two documents produce DIFFERENT owner-coverage (not a constant)")

# CROSS-CHECK against a wholly independent implementation: the validator's own
# W-LANE-NO-OWNER findings must name exactly the same nodes. Two tools, one truth.
_res, _v = call({"path": NONE_})
_warned = sorted({f["location"].split("'")[1] for f in _v["findings"]
                  if f["rule"] == "W-LANE-NO-OWNER" and "'" in f["location"]})
check(_warned == sorted(noneish["seam_coverage"]["nodes_with_no_derivable_owner"]),
      "describe's ownerless nodes match the validator's W-LANE-NO-OWNER set EXACTLY")

# fence + argument discipline apply to the third tool too
res, _ = call_desc({"path": "../../etc/passwd"})
check(res["isError"], "describe_workflow refuses path traversal")
res, _ = call_desc({})
check(res["isError"], "describe_workflow: neither content nor path -> tool error")
res, _ = call_desc({"content": "not xml at all"})
check(res["isError"], "describe_workflow: unparseable input -> tool error, not a bogus report")

proc.stdin.close(); proc.wait(timeout=10)

# ── T-795 AC4: the missing-PyYAML branch, exercised in-process ───────────────────────────
# The converter needs PyYAML; the SERVER does not. PyYAML is installed here, so the only
# honest way to test the absence branch is to simulate the converter's failure rather than
# uninstall a package the rest of the machine depends on. Imported and monkeypatched, so
# the branch is executed rather than merely read.
import importlib.util as _ilu
_spec = _ilu.spec_from_file_location("designer_mcp", os.path.join(ROOT, "tools", "mcp-designer-server.py"))
_mod = _ilu.module_from_spec(_spec); _spec.loader.exec_module(_mod)

class _FakeProc:
    returncode = 1
    stdout = ""
    stderr = "ModuleNotFoundError: No module named 'yaml'"

_real_run = _mod.subprocess.run
_mod.subprocess.run = lambda *a, **k: _FakeProc()
try:
    _mod.tool_yaml_to_bpmn({"content": "workflowMeta: {id: x}"})
    check(False, "missing PyYAML raises rather than returning silently")
except Exception as _e:
    msg = str(_e)
    check("pip install pyyaml" in msg, "missing PyYAML -> message names the fix, not a traceback")
    check("validate_workflow has no such dependency" in msg,
          "missing PyYAML -> message says the other tool still works")
    check("invalid" not in msg.lower(),
          "missing PyYAML is NOT reported as the document being invalid")
finally:
    _mod.subprocess.run = _real_run
print("\nprobe: %d passed, %d failed" % (passed, failed))
sys.exit(1 if failed else 0)
